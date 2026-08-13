# =============================================================================
# 37_extraer_tramitacion.R
# -----------------------------------------------------------------------------
# Proposito: Extraer la TRAMITACION de cada proyecto desde el SIL
#            (tramitacion.senado.cl/wspublico/tramitacion.php), que es la unica
#            fuente medida del dato que la API de la Camara no expone: en que
#            etapa esta un proyecto, desde cuando, y si llego a ser ley.
#            Cierra el hueco "# REVISAR estado de tramitacion" de CLAUDE.md.
#
#            EL SIL ES BICAMERAL pese a vivir en dominio del Senado: la medicion
#            del acto A (50_documentacion/andamios/50_medicion_p66_acto_a.md §3)
#            lo probo resolviendo 427 de 427 boletines de la Camara.
#
#            FORMA REAL DE LA RESPUESTA, medida y no heredada del arte previo. El
#            sondeo del 2026-08-07 sugeria //tramite/ETAPA y //leynro en la raiz,
#            y esos nodos NO existen: censar con ellos devuelve columnas enteras
#            vacias sin que ningun codigo de estado lo delate. Los reales son
#            //proyecto/descripcion/{etapa, estado, leynro, subetapa} y
#            //proyecto/tramitacion/tramite/{SESION, FECHA, DESCRIPCIONTRAMITE,
#            ETAPDESCRIPCION, CAMARATRAMITE}.
#
#            LA FECHA NO ES ISO: el SIL entrega DD/MM/AAAA. Parsearla como ISO da
#            0 de 4799 fechas validas sin emitir un solo error. Se parsea con
#            formato explicito y se conserva ademas el literal de la fuente.
#
#            CONTENIDO, NO PRESENCIA (A62): el nodo `leynro` viene presente en los
#            427 y vacio en 399. Contar por presencia de nodo da 427 en vez de 28,
#            un error de 15x. Todo conteo de este paso mide contenido no vacio.
#
# Insumos:   40_salidas/intermedios/{proyectos,votos}.rds (universo del corte)
#            SIL: tramitacion.senado.cl/wspublico/tramitacion.php?boletin=<NNNNN>
#            Cache: 20_insumos/senado/AAAAMMDD_tramitacion_sil_<anio>_tope-inf.rds
# Salidas:   40_salidas/intermedios/tramitacion.rds (una fila por boletin:
#            boletin, etapa_actual, estado, ley_numero, subetapa, n_tramites,
#            tramites(list-col de 6 columnas)).
# Autor:     Claude Code (encargo P-66 acto b, sesion 21)
# Creado:    2026-08-13
# =============================================================================

source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
instalar_si_falta(c("httr", "xml2", "dplyr", "here", "fs"))
library(dplyr)

ROOT <- obtener_raiz_proyecto()
source(file.path(ROOT, "10_utils", "10_configuracion.R"))

# ---- Contrato de la fuente ---------------------------------------------------
BASE_SIL  <- "https://tramitacion.senado.cl/wspublico/"
PAUSA_SIL <- 0.35   # cortesia con la fuente; del orden de PAUSA_API_SEG

# Estados de la captura, distinguibles entre si (mismo criterio que el 36): la
# API no reconoce el boletin, o la red fallo. Son causas distintas y exigen
# respuestas distintas, asi que no colapsan en un solo vector.
ESTADO_TRAM_RESUELTO      <- "resuelto"
ESTADO_TRAM_NO_RECONOCIDO <- "no_reconocido"   # respondio 200, pero sin //proyecto
ESTADO_TRAM_ERROR_RED     <- "error_red"       # no hubo respuesta utilizable

# El boletin de la Camara es NNNNN-NN; el SIL consulta por el numero sin sufijo
# de comision. Medido en el acto A sobre 427 de 427.
numero_de_boletin <- function(b) sub("-.*$", "", as.character(b))

# Esquema fijo del list-col, tambien en el caso vacio: un data.frame de 0 filas
# con las 6 columnas, nunca NULL y nunca fabricado (mismo patron que
# VOTACIONES_COLUMNAS en el 36).
TRAMITES_COLUMNAS <- c("fecha", "fecha_fuente", "camara", "etapa", "descripcion", "sesion")

tramites_vacio <- function() {
  as.data.frame(stats::setNames(rep(list(character(0)), length(TRAMITES_COLUMNAS)),
                                TRAMITES_COLUMNAS), stringsAsFactors = FALSE)
}

# ---- Parser -----------------------------------------------------------------
# Recibe el XML como TEXTO (asi es como se persiste el crudo) y devuelve los
# campos del proyecto mas su tabla de tramites. No decide nada temporal: acotar
# es responsabilidad de acotar_tramites_al_corte(), que se aplica despues y
# cuenta lo que descarta.
# `estado` y `etapa` pasan por trimws(): la fuente los entrega con espacio final
# en el 100 % de las respuestas medidas, y sin normalizar el conteo de valores
# distintos es correcto solo mientras el defecto sea universal.
parsear_tramitacion_sil <- function(xml_texto) {
  doc  <- xml2::read_xml(xml_texto)
  proy <- xml2::xml_find_first(doc, "//proyecto")
  if (inherits(proy, "xml_missing"))
    return(list(reconocido = FALSE, boletin_devuelto = NA_character_,
                etapa_actual = NA_character_, estado = NA_character_,
                ley_numero = NA_character_, subetapa = NA_character_,
                titulo = NA_character_, tramites = tramites_vacio()))

  txt <- function(nodo, xp) {
    n <- xml2::xml_find_first(nodo, xp)
    if (inherits(n, "xml_missing")) return(NA_character_)
    v <- trimws(xml2::xml_text(n))
    if (!nzchar(v)) NA_character_ else v          # vacio -> NA, nunca "" (A62)
  }

  vs <- xml2::xml_find_all(proy, "./tramitacion/tramite")
  tram <- if (length(vs) == 0) tramites_vacio() else {
    campo <- function(xp) vapply(vs, function(v) {
      n <- xml2::xml_find_first(v, xp)
      if (inherits(n, "xml_missing")) NA_character_ else trimws(xml2::xml_text(n))
    }, character(1))
    f_fuente <- campo("./FECHA")
    data.frame(
      # ISO derivada, que es la que compara el acotamiento y la que publica el
      # resto del proyecto; el literal de la fuente se conserva al lado para que
      # la transformacion sea auditable y no haya que volver al crudo.
      fecha        = format(as.Date(f_fuente, format = "%d/%m/%Y"), "%Y-%m-%d"),
      fecha_fuente = f_fuente,
      camara       = campo("./CAMARATRAMITE"),
      etapa        = campo("./ETAPDESCRIPCION"),
      descripcion  = campo("./DESCRIPCIONTRAMITE"),
      sesion       = campo("./SESION"),
      stringsAsFactors = FALSE)
  }

  # `camara_origen` y `fecha_ingreso` salen de AQUI y no de la captura de la
  # Camara por una razon declarada, no por conveniencia: el contrato de la
  # entidad `proyecto` los pide para los 427 boletines, y
  # parsear_contenido_proyecto() (10_utils.R) NO los extrae -- solo devuelve
  # nombre, tipo_iniciativa, materias y votaciones. Extender ese parser esta
  # explicitamente fuera del alcance autorizado de este encargo (la enmienda 1
  # habilita tres helpers y ninguno es ese), asi que el helper insuficiente se
  # REPORTA y se usa la fuente que si los expone sin tocar nada. Es el mismo
  # boletin: el acto A verifico devuelto == pedido en 427 de 427.
  # fecha_ingreso llega en DD/MM/AAAA como el resto del SIL: se normaliza a ISO
  # y se conserva el literal, igual que en los tramites.
  fi_fuente <- txt(proy, "./descripcion/fecha_ingreso")
  list(
    reconocido        = TRUE,
    boletin_devuelto  = txt(proy, "./descripcion/boletin"),
    etapa_actual      = txt(proy, "./descripcion/etapa"),
    estado            = txt(proy, "./descripcion/estado"),
    ley_numero        = txt(proy, "./descripcion/leynro"),
    subetapa          = txt(proy, "./descripcion/subetapa"),
    titulo            = txt(proy, "./descripcion/titulo"),
    camara_origen     = txt(proy, "./descripcion/camara_origen"),
    fecha_ingreso     = if (is.na(fi_fuente)) NA_character_ else
                          format(as.Date(fi_fuente, format = "%d/%m/%Y"), "%Y-%m-%d"),
    fecha_ingreso_fuente = fi_fuente,
    tramites          = tram)
}

# ---- Acotamiento temporal (D-h) ---------------------------------------------
# El SIL entrega el estado del proyecto AL MOMENTO DE LA LLAMADA, no al corte que
# la clave de cache declara: la medicion del acto A encontro el boletin 18507-04
# con un tramite del 13/08/2026 contra CORTE_FECHA 2026-08-12. Es la misma
# asimetria que P-74 (A) cerro para el nodo Votaciones de la Camara, en otra
# fuente. Se resuelve igual y con las mismas guardas: se descarta lo posterior al
# corte, se cuenta, y se emite por log. Nunca en silencio.
acotar_tramites_al_corte <- function(tramites, corte = CORTE_FECHA) {
  if (nrow(tramites) == 0) return(tramites)
  corte <- trimws(as.character(corte))
  # Se valida el corte y no solo las fechas: la comparacion es lexicografica y
  # solo es cronologica si AMBOS lados vienen en AAAA-MM-DD. Validar un operando
  # y no el otro deja el descarte a merced del que no se mira.
  if (!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", corte))
    stop(sprintf(paste0("37_tramitacion: corte '%s' no tiene formato AAAA-MM-DD. La comparacion ",
                        "lexicografica no seria cronologica y el descarte seria arbitrario."),
                 corte), call. = FALSE)
  if (!"fecha" %in% names(tramites))
    stop(sprintf(paste0("37_tramitacion: la tabla de tramites no trae columna 'fecha' ",
                        "(columnas: %s). Sin ella el filtro descartaria sus %d filas sin aviso."),
                 paste(names(tramites), collapse = ", "), nrow(tramites)), call. = FALSE)
  f <- tramites$fecha
  # Una fecha que no se pudo parsear queda NA aqui. NO se descarta en silencio ni
  # se deja pasar: se detiene. Filtrar por una fecha ilegible es decidir sin dato.
  malas <- which(is.na(f) | !grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", f))
  if (length(malas) > 0)
    stop(sprintf(paste0("37_tramitacion: %d de %d tramites traen fecha no interpretable ",
                        "(literal de la fuente: '%s'). No se acota por una fecha que no se pudo leer."),
                 length(malas), nrow(tramites),
                 as.character(tramites$fecha_fuente[malas[1]])), call. = FALSE)
  # DOS CAUSAS, NO UNA (hallazgo del panel adversarial, F6/P2). Un tramite queda
  # fuera del corte por dos motivos que no son el mismo hecho:
  #   (1) es realmente posterior al corte -- el caso que D-h existe para contener;
  #   (2) la FUENTE trae un anno absurdo -- medido: el boletin 18232-25 declara
  #       25/05/2626 para su "Oficio de ley al Ejecutivo", y ese proyecto ya
  #       figura como Publicado con su numero de ley, asi que el evento
  #       demostrablemente ocurrio ANTES del corte.
  # El descarte es correcto en los dos casos (publicar una fecha de 2626 seria
  # peor), pero llamarlos igual esconde que en (2) el artefacto pierde un tramite
  # real y el proyecto se publica sin su hito terminal. Se descartan igual y se
  # CUENTAN por separado, con el mismo criterio que el 36 usa para no colapsar
  # `no_reconocido` con `error_red`.
  anio <- suppressWarnings(as.integer(substr(f, 1, 4)))
  tope_plausible <- if (exists("ANIO_PROCESO", inherits = TRUE)) ANIO_PROCESO + 1L else 9999L
  fuera        <- f > corte
  implausible  <- fuera & !is.na(anio) & anio > tope_plausible
  out <- tramites[!fuera, , drop = FALSE]
  attr(out, "descarte_causas") <- list(
    posterior_al_corte = sum(fuera & !implausible),
    anio_implausible   = sum(implausible),
    fechas_implausibles = as.character(tramites$fecha_fuente[implausible]))
  out
}

# ---- Descarga ----------------------------------------------------------------
# Un status distinto de 200 NO se persiste como crudo: cachear una pagina de
# error la convierte en dato falso que sobrevive a todas las corridas siguientes.
# Se registra el estado, que es lo que permite distinguir "no existe" de "no
# respondio hoy".
descargar_tramitacion_sil <- function(num, timeout_s = 60L) {
  r <- tryCatch(
    httr::GET(paste0(BASE_SIL, "tramitacion.php"),
              query = list(boletin = num), httr::timeout(timeout_s),
              httr::user_agent("transparencia_legislativa_chile (R; datos publicos)")),
    error = function(e) e)
  if (inherits(r, "error"))
    return(list(ok = FALSE, xml = NA_character_, detalle = conditionMessage(r)))
  if (httr::status_code(r) != 200L)
    return(list(ok = FALSE, xml = NA_character_,
                detalle = sprintf("HTTP %s", httr::status_code(r))))
  list(ok = TRUE, xml = httr::content(r, as = "text", encoding = "UTF-8"),
       detalle = NA_character_)
}

# ---- Universo del corte ------------------------------------------------------
# Mismo criterio que el 36: la union de autorados y votados, tomada de los
# intermedios CONGELADOS del corte. No se re-descarga la lista de mociones (que
# crece dia a dia): el universo tiene que ser el mismo que el del resto del corte.
leer_intermedio <- function(nombre) {
  ruta <- ruta_salidas("intermedios", paste0(nombre, ".rds"))
  if (!file.exists(ruta))
    stop(sprintf("37_tramitacion: falta el intermedio '%s'. Corre el paso previo.", ruta),
         call. = FALSE)
  readRDS(ruta)
}
proyectos <- leer_intermedio("proyectos")
votos     <- leer_intermedio("votos")

bol_autorados <- como_llave(unique(proyectos$boletin))
bol_votados   <- como_llave(unique(votos$boletin))
bol_autorados <- bol_autorados[!is.na(bol_autorados)]
bol_votados   <- bol_votados[!is.na(bol_votados)]
boletines <- sort(unique(c(bol_autorados, bol_votados)))

log_moldes <- sprintf("Universo del corte %s: %d boletines (autorados %d, votados %d).",
                      CORTE_FECHA, length(boletines), length(bol_autorados), length(bol_votados))
log_msg(log_moldes, origen = "37_tramitacion")

# La lista PEDIDA se persiste ANTES de llamar (D38). Es texto plano y no .rds a
# proposito: reportar_estado_capturas() barre los .rds del directorio y un
# archivo sin atributo de captura entraria como `sin_registro`, ensuciando el
# reporte del contrato temporal con algo que no es una captura.
ruta_pedidos <- ruta_insumos("senado", sprintf("%s_tramitacion_pedidos.txt",
                                               corte_para_clave()))
fs::dir_create(dirname(ruta_pedidos))
writeLines(boletines, ruta_pedidos, useBytes = TRUE)
log_msg(sprintf("Lista pedida persistida ANTES de llamar: %s (%d boletines).",
                basename(ruta_pedidos), length(boletines)), origen = "37_tramitacion")

# ---- Captura cruda: el XML de respuesta, tal cual ---------------------------
# subdir = "senado": el crudo de esta fuente NO se mezcla con el de
# opendata.camara.cl. Una carpeta por host (enmienda 1 del encargo).
# tope = Inf: este paso no aplica cap propio; procesa todo el universo congelado.
capturar_tramitacion <- function() {
  con_cache(sprintf("tramitacion_sil_%d", ANIO_PROCESO), function() {
    filas <- vector("list", length(boletines))
    for (k in seq_along(boletines)) {
      bol <- boletines[k]
      d <- descargar_tramitacion_sil(numero_de_boletin(bol))
      if (!isTRUE(d$ok)) {
        filas[[k]] <- tibble(boletin = bol, xml = NA_character_,
                             estado = ESTADO_TRAM_ERROR_RED, estado_detalle = d$detalle)
        Sys.sleep(PAUSA_SIL); next
      }
      # Un boletin que el SIL no reconoce responde 200 con <proyectos></proyectos>
      # y cero nodos //proyecto. El 200 NO alcanza para decidir (A82): lo que
      # discrimina es la forma. Medido en el acto A con 5 controles negativos.
      reconocido <- length(xml2::xml_find_all(xml2::read_xml(d$xml), "//proyecto")) > 0
      filas[[k]] <- tibble(
        boletin        = bol,
        xml            = d$xml,
        estado         = if (reconocido) ESTADO_TRAM_RESUELTO else ESTADO_TRAM_NO_RECONOCIDO,
        estado_detalle = NA_character_)
      Sys.sleep(PAUSA_SIL)
    }
    bind_rows(filas)
  }, tope = Inf, origen = "37_tramitacion", subdir = "senado")
}

captura <- capturar_tramitacion()

# ---- Cuadre contra la lista PEDIDA (D38) ------------------------------------
# La reconciliacion es siempre contra lo pedido, jamas contra lo devuelto: un
# servicio que responde de menos encogeria el denominador y la cobertura saldria
# perfecta por construccion.
pedidos_en_disco <- readLines(ruta_pedidos)
stopifnot(identical(pedidos_en_disco, boletines))
stopifnot(nrow(captura) == length(boletines))
stopifnot(identical(captura$boletin, boletines))
log_msg(sprintf("Cuadre (D38): %d pedidos == %d filas de captura. PASA.",
                length(boletines), nrow(captura)), origen = "37_tramitacion")

por_estado <- table(factor(captura$estado,
                           levels = c(ESTADO_TRAM_RESUELTO, ESTADO_TRAM_NO_RECONOCIDO,
                                      ESTADO_TRAM_ERROR_RED)))
log_msg(sprintf("Captura SIL: %d entradas (%s).", nrow(captura),
                paste(sprintf("%s=%d", names(por_estado), as.integer(por_estado)),
                      collapse = ", ")), origen = "37_tramitacion")
if (por_estado[[ESTADO_TRAM_ERROR_RED]] > 0)
  log_msg(sprintf("Aviso: %d boletines sin respuesta por error de red: %s",
                  por_estado[[ESTADO_TRAM_ERROR_RED]],
                  paste(captura$boletin[captura$estado == ESTADO_TRAM_ERROR_RED],
                        collapse = ", ")), "WARN", "37_tramitacion")
if (por_estado[[ESTADO_TRAM_NO_RECONOCIDO]] > 0)
  log_msg(sprintf("Aviso: %d boletines que el SIL no reconoce: %s",
                  por_estado[[ESTADO_TRAM_NO_RECONOCIDO]],
                  paste(captura$boletin[captura$estado == ESTADO_TRAM_NO_RECONOCIDO],
                        collapse = ", ")), "WARN", "37_tramitacion")

# ---- Derivar el intermedio DESDE la captura (cero red) ----------------------
derivar_tramitacion <- function(captura, corte = CORTE_FECHA) {
  acc <- new.env(parent = emptyenv())
  acc$eventos_totales <- 0L; acc$eventos_fuera <- 0L
  acc$bol_afectados <- character(0); acc$bol_vaciados <- character(0)
  acc$por_corte <- 0L; acc$por_anio <- 0L; acc$bol_anio <- character(0)
  acc$fechas_anio <- character(0)
  # Denominador de afectados: los que traian tramites ANTES del filtro. Usar el
  # conteo posterior dejaria fuera justo a los que el filtro vacia.
  acc$bol_con_tramites_pre <- 0L

  filas <- lapply(seq_len(nrow(captura)), function(i) {
    if (!identical(captura$estado[i], ESTADO_TRAM_RESUELTO))
      return(tibble(boletin = captura$boletin[i], etapa_actual = NA_character_,
                    estado = NA_character_, ley_numero = NA_character_,
                    subetapa = NA_character_, titulo = NA_character_,
                    camara_origen = NA_character_, fecha_ingreso = NA_character_,
                    resuelto = FALSE, n_tramites = 0L,
                    n_tramites_descartados = 0L, tramites = list(tramites_vacio())))
    p <- parsear_tramitacion_sil(captura$xml[i])
    crudos <- p$tramites
    tr     <- acotar_tramites_al_corte(crudos, corte)
    fuera  <- nrow(crudos) - nrow(tr)
    acc$eventos_totales <- acc$eventos_totales + nrow(crudos)
    acc$eventos_fuera   <- acc$eventos_fuera + fuera
    if (nrow(crudos) > 0) acc$bol_con_tramites_pre <- acc$bol_con_tramites_pre + 1L
    if (fuera > 0) acc$bol_afectados <- c(acc$bol_afectados, captura$boletin[i])
    causas <- attr(tr, "descarte_causas")
    if (!is.null(causas)) {
      acc$por_corte <- acc$por_corte + causas$posterior_al_corte
      acc$por_anio  <- acc$por_anio  + causas$anio_implausible
      if (causas$anio_implausible > 0) {
        acc$bol_anio    <- c(acc$bol_anio, captura$boletin[i])
        acc$fechas_anio <- c(acc$fechas_anio, causas$fechas_implausibles)
      }
    }
    if (nrow(crudos) > 0 && nrow(tr) == 0)
      acc$bol_vaciados <- c(acc$bol_vaciados, captura$boletin[i])
    tibble(
      boletin       = captura$boletin[i],
      etapa_actual  = p$etapa_actual,
      estado        = p$estado,
      ley_numero    = p$ley_numero,
      subetapa      = p$subetapa,
      titulo        = p$titulo,
      camara_origen = p$camara_origen,
      fecha_ingreso = p$fecha_ingreso,
      resuelto      = TRUE,
      n_tramites    = nrow(tr),
      # Por boletin y no solo agregado: el contrato de la entidad `proyecto`
      # publica este conteo dentro de los metadatos de CADA proyecto, para que el
      # lector de un boletin concreto sepa si a EL se le descarto algo.
      n_tramites_descartados = as.integer(fuera),
      tramites      = list(tr))
  })
  tram <- bind_rows(filas)

  con_tramites <- sum(tram$n_tramites > 0)
  log_msg(sprintf(paste0("Acotamiento al corte (D-h): %d de %d tramites descartados por fecha > %s; ",
                         "quedan %d. Boletines afectados: %d de %d con tramites antes del filtro ",
                         "(%d los conservan despues)."),
                  acc$eventos_fuera, acc$eventos_totales, corte,
                  acc$eventos_totales - acc$eventos_fuera,
                  length(acc$bol_afectados), acc$bol_con_tramites_pre, con_tramites),
          if (acc$eventos_fuera > 0) "WARN" else "INFO", "37_tramitacion")
  if (length(acc$bol_afectados) > 0)
    log_msg(sprintf("Acotamiento (D-h): boletines con tramites descartados: %s",
                    paste(acc$bol_afectados, collapse = ", ")), "WARN", "37_tramitacion")
  # Las dos causas, separadas. Un descarte por anno absurdo NO es un evento del
  # futuro: es un dato real que la fuente fecho mal y que el artefacto pierde.
  # Colapsarlo con el otro caso hace que el contador diga "2 posteriores al
  # corte" cuando uno de los dos ocurrio antes y esta probado por el propio JSON
  # (proyecto Publicado, con numero de ley). Hallazgo del panel adversarial.
  log_msg(sprintf(paste0("Acotamiento (D-h), por causa: %d posteriores al corte; %d con anno ",
                         "implausible (> %d). Los segundos NO son eventos futuros: son fechas ",
                         "erroneas de la fuente y el proyecto se publica sin ese tramite%s."),
                  acc$por_corte, acc$por_anio, ANIO_PROCESO + 1L,
                  if (length(acc$bol_anio))
                    sprintf(" -> %s (fechas: %s)", paste(acc$bol_anio, collapse = ", "),
                            paste(acc$fechas_anio, collapse = ", ")) else ""),
          if (acc$por_anio > 0) "WARN" else "INFO", "37_tramitacion")
  log_msg(sprintf("Acotamiento (D-h): %d de %d boletines con tramites quedaron vacios y no lo estaban%s.",
                  length(acc$bol_vaciados), acc$bol_con_tramites_pre,
                  if (length(acc$bol_vaciados)) paste0(": ", paste(acc$bol_vaciados, collapse = ", ")) else ""),
          if (length(acc$bol_vaciados) > 0) "WARN" else "INFO", "37_tramitacion")
  attr(tram, "descarte_corte") <- list(
    eventos_totales = acc$eventos_totales, eventos_fuera = acc$eventos_fuera,
    boletines_afectados = acc$bol_afectados, boletines_vaciados = acc$bol_vaciados)
  tram
}

tramitacion <- derivar_tramitacion(captura)

# ---- Validacion de integridad ------------------------------------------------
if (nrow(tramitacion) != length(boletines))
  stop(sprintf("37_tramitacion: %d filas para %d boletines pedidos.",
               nrow(tramitacion), length(boletines)), call. = FALSE)
if (anyDuplicated(tramitacion$boletin) > 0)
  stop("37_tramitacion: boletin duplicado en el intermedio.", call. = FALSE)
if (!is.character(tramitacion$boletin))
  stop("37_tramitacion: boletin no es character (invariante de llave).", call. = FALSE)
esquema_malo <- which(!vapply(tramitacion$tramites, function(d)
  identical(names(d), TRAMITES_COLUMNAS), logical(1)))
if (length(esquema_malo) > 0)
  stop(sprintf("37_tramitacion: %d boletines con esquema de tramites distinto del canonico (%s).",
               length(esquema_malo),
               paste(tramitacion$boletin[esquema_malo], collapse = ", ")), call. = FALSE)
if (!identical(tramitacion$n_tramites, vapply(tramitacion$tramites, nrow, integer(1))))
  stop("37_tramitacion: n_tramites no coincide con las filas del list-col.", call. = FALSE)

# Cobertura, SIEMPRE por contenido no vacio y nunca por presencia de nodo (A62).
lleno <- function(v) !is.na(v) & nzchar(trimws(v))
n <- nrow(tramitacion)
n_res <- sum(tramitacion$resuelto)
log_msg(sprintf("Cobertura sobre %d pedidos: resueltos %d; etapa %d; estado %d; ley_numero %d; subetapa %d.",
                n, n_res, sum(lleno(tramitacion$etapa_actual)),
                sum(lleno(tramitacion$estado)), sum(lleno(tramitacion$ley_numero)),
                sum(lleno(tramitacion$subetapa))), origen = "37_tramitacion")
log_msg(sprintf("Tramites totales (ya acotados): %d; boletines con >=1 tramite: %d de %d.",
                sum(tramitacion$n_tramites), sum(tramitacion$n_tramites > 0), n),
        origen = "37_tramitacion")

# ---- Persistir ---------------------------------------------------------------
ruta_out <- ruta_salidas("intermedios", "tramitacion.rds")
escribir_atomico(tramitacion, ruta_out, function(o, r) saveRDS(o, r),
                 hash_origen = hash_origen_de(
                   ruta_cache(sprintf("tramitacion_sil_%d", ANIO_PROCESO), Inf,
                              subdir = "senado")))
log_msg(sprintf("Escrito: %s (%d boletines)", ruta_out, nrow(tramitacion)),
        origen = "37_tramitacion")
