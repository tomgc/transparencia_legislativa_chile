# =============================================================================
# 36_extraer_detalle_proyectos.R
# -----------------------------------------------------------------------------
# Proposito: Bajar el CONTENIDO de cada proyecto (titulo, tipo de iniciativa,
#            materias) para los boletines que el pipeline necesita hacer
#            legibles/trazables: los AUTORADOS (proyectos.rds) y los VOTADOS
#            (boletines no nulos en votos.rds). Un solo intermedio de detalle
#            sirve a los dos bloques del perfil en 39.
#
#            DECISION DE DISENO (ver log 20260709_contenido_legible_log.md):
#            el detalle se obtiene por CADA boletin ya presente en los
#            intermedios CONGELADOS del anno (proyectos.rds / votos.rds), NO
#            re-descargando la lista de mociones (que crece dia a dia). Asi el
#            snapshot queda congelado (n_proyectos/n_votaciones intactos) y el
#            detalle (titulo/tipo/materias, estables entre dias) se puede bajar
#            hoy sin corromper conteos. Esto unifica lo que el encargo planteo
#            como Fase A (enriquecer autorados) y Fase B (detalle de votados).
#
#            CAPTURA CRUDA (P-63, sesion 17): hasta la sesion 16 este paso
#            cacheaba el TIBBLE YA PARSEADO dentro de la carpeta de dato crudo.
#            Eso tenia dos consecuencias: el nodo Votaciones que la API ya
#            entregaba se perdia al parsear, y la guarda de autorregeneracion de
#            P-65 prometia regenerar este paso sin red cuando en realidad solo
#            podia reproducir los campos que el parser de ese dia conservo.
#            Ahora se persiste el XML de respuesta TAL CUAL, bajo clave propia
#            (detalle_proyectos_xml_<anio>), y el tibble se deriva de ahi.
#            Consecuencia buscada: reparsear con otro parser ya no pide red.
#
# Insumos:   40_salidas/intermedios/proyectos.rds (autorados, boletin)
#            40_salidas/intermedios/votos.rds     (votados, boletin no nulo)
#            API Camara: WSLegislativo.asmx/retornarProyectoLey (por boletin).
#            Cache: 20_insumos/camara/AAAAMMDD_detalle_proyectos_xml_<anio>_tope-inf.rds
#            La captura anterior (detalle_proyectos_<anio>) NO se borra ni se
#            reutiliza: es dato crudo inmutable, solo dejo de leerse.
# Salidas:   40_salidas/intermedios/proyectos_detalle.rds
#            (una fila por boletin: boletin, nombre, tipo_iniciativa,
#             n_materias, materias(list-col data.frame id,nombre),
#             n_votaciones, votaciones(list-col data.frame de 20 columnas)).
# Autor:     Claude Code (encargo contenido legible + trazabilidad, sesion explore;
#            captura XML cruda y nodo Votaciones, sesion 17)
# Creado:    2026-07-09
# =============================================================================

# ---- Cargar utilidades y configuracion --------------------------------------
source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
instalar_si_falta(c("httr", "xml2", "dplyr", "here", "fs"))
library(dplyr)

ROOT <- obtener_raiz_proyecto()
source(file.path(ROOT, "10_utils", "10_configuracion.R"))

# ---- Boletines a resolver: union de autorados + votados (congelados) --------
leer_intermedio <- function(nombre) {
  ruta <- ruta_salidas("intermedios", paste0(nombre, ".rds"))
  if (!file.exists(ruta))
    stop(sprintf("36_detalle: falta el intermedio '%s'. Corre el paso previo.", ruta))
  readRDS(ruta)
}
proyectos <- leer_intermedio("proyectos")
votos     <- leer_intermedio("votos")

boletines_autorados <- como_llave(unique(proyectos$boletin))
boletines_votados   <- como_llave(unique(votos$boletin))
boletines_autorados <- boletines_autorados[!is.na(boletines_autorados)]
boletines_votados   <- boletines_votados[!is.na(boletines_votados)]
boletines <- sort(unique(c(boletines_autorados, boletines_votados)))

log_msg(sprintf("Boletines a resolver: %d (autorados %d, votados %d, union %d).",
                length(boletines), length(boletines_autorados),
                length(boletines_votados), length(boletines)),
        origen = "36_detalle")

# ---- Captura cruda: el XML de respuesta, tal cual (P-63) --------------------
# tope = Inf: 36 NO aplica un cap propio a su descarga; procesa TODOS los
# boletines de la union congelada (autorados + votados) sin truncar. Inf
# codifica en la clave que este detalle es completo, consistente con el esquema
# _tope-inf de 33/34/35 en produccion (fix de la clave de cache). No se pasa
# MAX_PROYECTOS_DETALLE: 36 no lo aplica (procesa mas que los autorados), asi
# que decirlo en la clave seria mentir. # REVISAR: el CONJUNTO de boletines de
# 36 depende de los topes de 34/35 (via proyectos.rds/votos.rds); esa dependencia
# aguas-arriba ya queda codificada en LOS snapshots de 34/35, no en el de 36.
#
# CLAVE NUEVA, no reutilizada: el contenido cambio de forma (XML crudo en vez de
# tibble parseado) y la doctrina de la clave de cache (10_utils.R:173-179) exige
# que todo lo que altere el contenido cacheado entre en la clave. Reutilizar
# detalle_proyectos_<anio> haria que un cache viejo se leyera como nuevo en
# silencio, que es exactamente el fallo que esa doctrina existe para impedir.
#
# El XML se persiste como CHARACTER, nunca como xml_document: xml2::read_xml()
# devuelve un puntero externo y saveRDS() de ese objeto escribe sin error un .rds
# que al releerse da un puntero invalido (falso verde silencioso).
#
# Tres estados distinguibles, donde antes ambos fallos colapsaban en un solo
# vector `no_resueltos`: la API no reconoce el boletin, o la red fallo. Son
# causas distintas y exigen respuestas distintas, asi que se registran distinto.
ESTADO_RESUELTO      <- "resuelto"
ESTADO_NO_RECONOCIDO <- "no_reconocido"   # respondio, pero sin Nombre
ESTADO_ERROR_RED     <- "error_red"       # no hubo respuesta utilizable

capturar_xml_detalle <- function() {
  con_cache(sprintf("detalle_proyectos_xml_%d", ANIO_PROCESO), function() {
    filas <- vector("list", length(boletines))
    for (k in seq_along(boletines)) {
      bol <- boletines[k]
      d <- tryCatch(
        descargar_xml_camara("WSLegislativo.asmx/retornarProyectoLey",
                             list(prmNumeroBoletin = bol)),
        error = function(e) e)
      if (inherits(d, "error")) {
        filas[[k]] <- tibble(boletin = como_llave(bol), xml = NA_character_,
                             estado = ESTADO_ERROR_RED,
                             estado_detalle = conditionMessage(d))
        Sys.sleep(PAUSA_API_SEG); next
      }
      # Un boletin que la API no reconoce devuelve un ProyectoLey sin Nombre. El
      # XML se guarda igual: es la respuesta real y sirve para auditar el estado.
      sin_nombre <- is.na(texto_nodo(xml2::xml_root(d), "./Nombre"))
      filas[[k]] <- tibble(
        boletin        = como_llave(bol),
        xml            = as.character(d),
        estado         = if (sin_nombre) ESTADO_NO_RECONOCIDO else ESTADO_RESUELTO,
        estado_detalle = NA_character_)
      Sys.sleep(PAUSA_API_SEG)
    }
    bind_rows(filas)
  }, tope = Inf, origen = "36_detalle")
}

captura <- capturar_xml_detalle()

# ---- Validacion de la captura (fallo ruidoso, nunca default silencioso) -----
if (nrow(captura) != length(boletines))
  stop(sprintf(paste0("36_detalle: la captura trae %d filas y el universo es de %d ",
                      "boletines. La captura no cubre el universo; regenerala con ",
                      "options(camara.refrescar = TRUE)."),
               nrow(captura), length(boletines)), call. = FALSE)
if (!setequal(captura$boletin, boletines))
  stop("36_detalle: los boletines de la captura no coinciden con el universo.", call. = FALSE)
if (!is.character(captura$xml))
  stop("36_detalle: la columna xml no es character (se serializo un xml_document?).",
       call. = FALSE)

por_estado <- table(factor(captura$estado,
                           levels = c(ESTADO_RESUELTO, ESTADO_NO_RECONOCIDO, ESTADO_ERROR_RED)))
log_msg(sprintf("Captura XML: %d entradas (%s).", nrow(captura),
                paste(sprintf("%s=%d", names(por_estado), as.integer(por_estado)),
                      collapse = ", ")), origen = "36_detalle")
if (por_estado[[ESTADO_ERROR_RED]] > 0)
  log_msg(sprintf("Aviso: %d boletines sin respuesta por error de red: %s",
                  por_estado[[ESTADO_ERROR_RED]],
                  paste(captura$boletin[captura$estado == ESTADO_ERROR_RED], collapse = ", ")),
          "WARN", "36_detalle")
if (por_estado[[ESTADO_NO_RECONOCIDO]] > 0)
  log_msg(sprintf("Aviso: %d boletines que la API no reconoce (quedaran con proyecto=null en 39): %s",
                  por_estado[[ESTADO_NO_RECONOCIDO]],
                  paste(captura$boletin[captura$estado == ESTADO_NO_RECONOCIDO], collapse = ", ")),
          "WARN", "36_detalle")

# ---- Derivar el tibble DESDE la captura (cero red) --------------------------
# Este es el criterio con el que se juzga si la captura quedo bien hecha: el
# parser corre sobre el XML persistido, no sobre el vuelo de la descarga.
derivar_detalle <- function(captura) {
  ok <- captura[captura$estado == ESTADO_RESUELTO, ]
  if (nrow(ok) == 0) stop("36_detalle: ningun boletin resuelto en la captura.", call. = FALSE)
  bind_rows(lapply(seq_len(nrow(ok)), function(i) {
    cont <- parsear_contenido_proyecto(xml2::read_xml(ok$xml[i]))
    tibble(
      boletin         = ok$boletin[i],
      nombre          = cont$nombre,
      tipo_iniciativa = cont$tipo_iniciativa,
      n_materias      = nrow(cont$materias),
      materias        = list(cont$materias),    # list-col: data.frame(id, nombre)
      # Una fila por boletin (el 39 indexa por boletin): las N votaciones viajan
      # como list-col, mismo patron que materias, no en formato largo.
      n_votaciones    = nrow(cont$votaciones),
      votaciones      = list(cont$votaciones)   # list-col: data.frame de 20 columnas
    )
  }))
}

detalle <- derivar_detalle(captura)

# ---- Validacion de integridad (POLITICA 5.3.8) ------------------------------
if (nrow(detalle) > 0) {
  if (any(is.na(detalle$boletin)))
    stop("36_detalle: boletin NA en el detalle.")
  if (anyDuplicated(detalle$boletin) > 0)
    stop("36_detalle: boletin duplicado en el detalle.")
  if (!is.character(detalle$boletin))
    stop("36_detalle: boletin no es character (invariante de llave).")
  # Una fila por boletin: el 39 indexa det_map por boletin (39:88) y una expansion
  # a formato largo lo romperia en silencio.
  if (nrow(detalle) != length(unique(detalle$boletin)))
    stop("36_detalle: el detalle no tiene exactamente una fila por boletin.")
  # El list-col debe traer SIEMPRE el esquema completo, tambien en el caso vacio.
  esquema_malo <- which(!vapply(detalle$votaciones, function(d)
    identical(names(d), VOTACIONES_COLUMNAS), logical(1)))
  if (length(esquema_malo) > 0)
    stop(sprintf("36_detalle: %d boletines con esquema de votaciones distinto del canonico (%s).",
                 length(esquema_malo), paste(detalle$boletin[esquema_malo], collapse = ", ")),
         call. = FALSE)
  if (!identical(detalle$n_votaciones,
                 vapply(detalle$votaciones, nrow, integer(1))))
    stop("36_detalle: n_votaciones no coincide con las filas del list-col.", call. = FALSE)
  ids_vot <- unlist(lapply(detalle$votaciones, function(d) d$votacion_id), use.names = FALSE)
  if (length(ids_vot) > 0 && !is.character(ids_vot))
    stop("36_detalle: votacion_id no es character (invariante de llave).", call. = FALSE)
}

# Cobertura sobre los votados (lo critico para la trazabilidad voto->proyecto).
resueltos_votados <- sum(boletines_votados %in% detalle$boletin)
resueltos_autorados <- sum(boletines_autorados %in% detalle$boletin)
con_materias <- sum(detalle$n_materias > 0)
log_msg(sprintf("Detalle resuelto: %d/%d boletines (autorados %d/%d, votados %d/%d).",
                nrow(detalle), length(boletines),
                resueltos_autorados, length(boletines_autorados),
                resueltos_votados, length(boletines_votados)),
        origen = "36_detalle")
log_msg(sprintf("Con >=1 materia: %d ; sin materias: %d (hueco de la fuente, no fabricado).",
                con_materias, nrow(detalle) - con_materias),
        origen = "36_detalle")
if (resueltos_votados < length(boletines_votados))
  log_msg(sprintf("Aviso: %d boletines votados sin detalle (quedaran con proyecto=null en 39).",
                  length(boletines_votados) - resueltos_votados), "WARN", "36_detalle")

# Cobertura del nodo Votaciones, con sus dos denominadores CONTADOS (P-63, C6).
# A62: cuenta boletines con al menos un elemento, no la presencia del contenedor,
# que viene siempre. El denominador que importa es el de VOTADOS: un boletin solo
# autorado no tiene por que traer votaciones todavia.
con_votaciones <- sum(detalle$n_votaciones > 0)
votados_con_votaciones <- sum(
  detalle$n_votaciones[match(boletines_votados, detalle$boletin)] > 0, na.rm = TRUE)
log_msg(sprintf("Nodo Votaciones: %d/%d boletines votados con >=1 votacion; %d/%d sobre la union; %d elementos en total.",
                votados_con_votaciones, length(boletines_votados),
                con_votaciones, nrow(detalle), sum(detalle$n_votaciones)),
        origen = "36_detalle")

# ---- Persistir (escritura atomica) ------------------------------------------
ruta_out <- ruta_salidas("intermedios", "proyectos_detalle.rds")
# Sello de procedencia: hash de la captura CRUDA que alimento este intermedio.
# Desde P-63 esa captura es el XML (detalle_proyectos_xml_<anio>), no el derivado
# del parser: el sello debe apuntar a lo que efectivamente permite reproducirlo.
escribir_atomico(detalle, ruta_out, function(o, r) saveRDS(o, r),
                 hash_origen = hash_origen_de(
                   ruta_cache(sprintf("detalle_proyectos_xml_%d", ANIO_PROCESO), Inf)))
log_msg(sprintf("Escrito: %s (%d boletines)", ruta_out, nrow(detalle)),
        origen = "36_detalle")
