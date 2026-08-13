# =============================================================================
# 39_consolidar_json.R
# -----------------------------------------------------------------------------
# Proposito: Fusionar las tablas intermedias (diputados, asistencia nominal,
#            votos, proyectos) en los JSON estaticos que consume el dashboard:
#              - 40_salidas/json/indice_diputados.json  (selector, con metricas
#                resumen por diputado: tasa_presencia, n_proyectos, n_votaciones;
#                y sexo/partido_nombre para que el cliente no fabrique ni
#                embeba a mano lo que ya viene en la fuente)
#              - 40_salidas/json/perfiles/<id>.json      (uno por diputado)
#            Claves ordenadas, indentacion fija, UTF-8 (POLITICA 2, 5.5).
#            Publica ademas una copia en docs/data/ para GitHub Pages (Fase 2).
# Insumos:   40_salidas/intermedios/{diputados,votos,proyectos,
#            proyectos_detalle,asistencia_nominal,asistencia_ambitos}.rds
#            La asistencia entra SOLO por la Capa 3 (serie nominal + agregados
#            por ambito temporal). El agregado legacy por diputado
#            (asistencia.rds) se retiro en la sesion 15 (P-48): ningun
#            consumidor lo leia desde que el frontend migro en la sesion 14.
# Salidas:   40_salidas/json/ (indice + perfiles/, canonico) y docs/data/
#            (indice + perfiles/, publicacion; copia fiel de 40_salidas/json/).
# Validacion: NAs en llaves, totales pre/post join, rango de tasa, dominio de
#            sentido del voto (POLITICA 5.3.8).
# Autor:     Claude Code (encargo autonomo, sesion 1; metricas resumen +
#            publicacion docs/data, sesion 3; sexo + partido_nombre en el
#            indice, sesion 3 continuacion)
# Creado:    2026-07-06
# =============================================================================

source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
instalar_si_falta(c("dplyr", "jsonlite", "here", "fs"))
library(dplyr)

ROOT <- obtener_raiz_proyecto()
source(file.path(ROOT, "10_utils", "10_configuracion.R"))

# ---- Cargar intermedios CON validacion de procedencia (fix sesion 8) ---------
# Cada intermedio debe traer sello (leer_sellado) y todos deben declarar el
# CORTE_FECHA vigente (validar_corte). Falla ruidosa ANTES de cualquier join o
# escritura si un .rds no corresponde al corte publicado (Bug 1 del traspaso v07):
# evita que un residuo de otra corrida se consolide en silencio.
sellos_intermedios <- list()
leer <- function(nombre) {
  ruta <- ruta_salidas("intermedios", paste0(nombre, ".rds"))
  ls <- leer_sellado(ruta)  # stop() diagnostico si falta el archivo o el sello
  sellos_intermedios[[basename(ruta)]] <<- ls$sello
  ls$objeto
}
diputados  <- leer("diputados")
votos      <- leer("votos")
proyectos  <- leer("proyectos")
# Detalle de contenido por boletin (tipo_iniciativa, materias) del paso 36.
# Habilita: proyectos legibles (materias) y trazabilidad voto->proyecto.
proyectos_detalle <- leer("proyectos_detalle")
# Asistencia, unica granularidad desde la sesion 15: serie nominal por sesion
# (Capa 3) y sus agregados por ambito temporal.
asistencia_nominal <- leer("asistencia_nominal")
asistencia_ambitos <- leer("asistencia_ambitos")
# Tramitacion por boletin (paso 37, P-66 acto b). Entra por leer() y no por
# readRDS() a proposito: asi su sello se suma a sellos_intermedios y validar_corte()
# lo exige del mismo corte que los demas. Un intermedio nuevo que se leyera por
# fuera de esa compuerta podria consolidarse desalineado en silencio, que es
# exactamente el Bug 1 del traspaso v07.
tramitacion <- leer("tramitacion")

# Compuerta de procedencia: todos los intermedios leidos deben pertenecer al
# corte vigente y ser coherentes entre si. stop() diagnostico si no. Va ANTES
# del stopifnot de character y de todo join/escritura. validar_corte() recorre
# la lista de sellos que reciba: no espera un numero fijo ni un nombre concreto,
# por eso leer un intermedio menos no la afecta.
validar_corte(sellos_intermedios, CORTE_FECHA)
log_msg(sprintf("Procedencia validada: %d intermedios al corte %s.",
                length(sellos_intermedios), CORTE_FECHA),
        origen = "39_consolidar")

# La llave es character en todas las tablas (invariante POLITICA 5.3.6).
stopifnot(is.character(diputados$diputado_id),
          is.character(votos$diputado_id),
          is.character(proyectos$diputado_id),
          is.character(proyectos_detalle$boletin),
          is.character(asistencia_nominal$diputado_id),
          is.character(asistencia_nominal$sesion_id),
          is.character(asistencia_ambitos$diputado_id),
          is.character(tramitacion$boletin))

# ---- Lookup de contenido por boletin (O(1) por llave) -----------------------
# det_map[[boletin]] -> list(boletin, nombre, tipo_iniciativa, materias(df)).
# NULL si el boletin no tiene detalle resuelto o es NA (voto sin boletin).
det_map <- lapply(seq_len(nrow(proyectos_detalle)), function(i) list(
  boletin         = proyectos_detalle$boletin[i],
  nombre          = proyectos_detalle$nombre[i],
  tipo_iniciativa = proyectos_detalle$tipo_iniciativa[i],
  materias        = proyectos_detalle$materias[[i]]
))
names(det_map) <- proyectos_detalle$boletin
detalle_de <- function(bol) if (is.na(bol)) NULL else det_map[[bol]]
MATERIAS_VACIO <- data.frame(id = character(0), nombre = character(0),
                             stringsAsFactors = FALSE)

# ---- Capa 3: lookups de asistencia nominal (O(1) por diputado) --------------
# El alcance temporal viaja como atributo del intermedio (lo fija el 33 con la
# fecha de instalacion que publica la API), no se re-deriva aqui.
ALCANCE <- attr(asistencia_ambitos, "alcance")
if (is.null(ALCANCE))
  stop("39_consolidar: asistencia_ambitos.rds no trae el atributo 'alcance'. Regenera el paso 33.",
       call. = FALSE)

# Nota legible: impide leer el acumulado como carrera completa. Es texto, no
# dato derivado; se construye con los valores reales del alcance.
NOTA_ALCANCE <- sprintf(
  paste0("Cobertura parcial: solo sesiones de sala del anno %d hasta el %s ",
         "(%d sesiones, de %s a %s). NO es la trayectoria completa del ",
         "parlamentario. El ambito 'periodo_vigente' cuenta las %d sesiones ",
         "desde la instalacion del periodo %s (%s) y usa el mismo denominador ",
         "para todos, por lo que es el comparable entre diputados; ",
         "'en_ejercicio' cuenta solo las sesiones del alcance posteriores a la ",
         "asuncion de cada diputado."),
  ALCANCE$anio_proceso, ALCANCE$corte_fecha, ALCANCE$sesiones_alcance,
  ALCANCE$fecha_primera, ALCANCE$fecha_ultima, ALCANCE$sesiones_periodo_vigente,
  ALCANCE$periodo_nombre, ALCANCE$periodo_inicio)

BLOQUE_ALCANCE <- list(
  anio_proceso             = ALCANCE$anio_proceso,
  corte_fecha              = ALCANCE$corte_fecha,
  sesiones_alcance         = ALCANCE$sesiones_alcance,
  fecha_primera            = ALCANCE$fecha_primera,
  fecha_ultima             = ALCANCE$fecha_ultima,
  periodo_id               = ALCANCE$periodo_id,
  periodo_nombre           = ALCANCE$periodo_nombre,
  periodo_inicio           = ALCANCE$periodo_inicio,
  sesiones_periodo_vigente = ALCANCE$sesiones_periodo_vigente,
  nota                     = NOTA_ALCANCE
)

# Conteos + tasas de un ambito, en el orden fijo del contrato.
bloque_ambito <- function(fila) {
  if (nrow(fila) != 1) return(NULL)
  list(
    n_sesiones       = fila$n_sesiones,
    n_asiste         = fila$n_asiste,
    n_no_asiste      = fila$n_no_asiste,
    # Sesiones del ambito en que la fuente no registra fila para el diputado.
    # No se imputa asistencia ni inasistencia (POLITICA: nunca fabricar dato).
    n_sin_registro   = fila$n_sin_registro,
    n_justificadas   = fila$n_justificadas,
    n_injustificadas = fila$n_injustificadas,
    # Ambas tasas comparten denominador (n_sesiones). Ninguna usa las rebajas.
    tasa_presencia               = fila$tasa_presencia,
    tasa_presencia_o_justificada = fila$tasa_presencia_o_justificada
  )
}
amb_map <- split(asistencia_ambitos, asistencia_ambitos$diputado_id)
serie_map <- split(asistencia_nominal, asistencia_nominal$diputado_id)

roster_ids <- diputados$diputado_id
log_msg(sprintf("Roster vigente: %d diputados.", length(roster_ids)),
        origen = "39_consolidar")

# ---- Escritor JSON canonico (claves ordenadas, indentacion fija, UTF-8) -----
escribir_json <- function(objeto, ruta) {
  txt <- jsonlite::toJSON(objeto, auto_unbox = TRUE, pretty = TRUE,
                          na = "null", null = "null", digits = NA)
  escribir_atomico(txt, ruta, function(o, r)
    writeLines(enc2utf8(as.character(o)), r, useBytes = TRUE))
}

# ---- Validacion de cobertura de cada fuente sobre el roster -----------------
cobertura <- function(tabla, etiqueta) {
  ids <- intersect(unique(tabla$diputado_id), roster_ids)
  huerfanos <- setdiff(unique(tabla$diputado_id), roster_ids)
  log_msg(sprintf("%s: %d/%d del roster con datos; %d ids fuera del roster (periodo previo/reemplazos).",
                  etiqueta, length(ids), length(roster_ids), length(huerfanos)),
          origen = "39_consolidar")
  invisible(NULL)
}
cobertura(asistencia_nominal, "Asistencia nominal")
cobertura(votos,      "Votaciones")
cobertura(proyectos,  "Proyectos")

# ---- Metricas resumen por diputado (para el indice) --------------------------
# left_join sobre el roster (nunca inner_join): un diputado sin votos/proyectos
# debe quedar con 0, no desaparecer del indice.

# Tasa de presencia del PERIODO VIGENTE (denominador comun a los 155, por eso
# comparable entre diputados). Unico indicador de asistencia del indice desde el
# retiro del contrato legacy (P-48).
resumen_presencia <- asistencia_ambitos |>
  filter(ambito == "periodo_vigente") |>
  select(diputado_id, tasa_presencia)

resumen_votos <- votos |>
  summarise(n_votaciones = n(), .by = diputado_id)

resumen_proyectos <- proyectos |>
  summarise(n_proyectos = n(), .by = diputado_id)

# ---- indice_diputados.json (lista minima para el selector, con metricas) ----
indice <- diputados |>
  left_join(resumen_votos,      by = "diputado_id") |>
  left_join(resumen_proyectos,  by = "diputado_id") |>
  left_join(resumen_presencia,  by = "diputado_id") |>
  mutate(
    n_votaciones = coalesce(n_votaciones, 0L),
    n_proyectos  = coalesce(n_proyectos, 0L)
  ) |>
  arrange(nombre) |>
  transmute(
    id              = diputado_id,
    nombre          = nombre,
    sexo            = sexo,
    partido         = partido_id,
    partido_nombre  = partido_nombre,
    distrito        = distrito,
    region          = region,
    tendencia       = tendencia,
    n_proyectos     = n_proyectos,
    n_votaciones    = n_votaciones,
    # Unico indicador de asistencia del indice: es el del ambito periodo_vigente,
    # de denominador comun a los 155 (P-48 retiro tasa_asistencia, que usaba el
    # historico propio de cada diputado y no era comparable entre ellos).
    tasa_presencia  = tasa_presencia
  )

fs::dir_create(ruta_json())
escribir_json(indice, ruta_json("indice_diputados.json"))
log_msg(sprintf("Escrito indice con %d diputados.", nrow(indice)),
        origen = "39_consolidar")

# ---- Perfiles por diputado (4 bloques) --------------------------------------
fs::dir_create(ruta_json_perfiles())
# Limpiar perfiles previos para que el conteo sea idempotente (POLITICA 5.2.3).
antiguos <- fs::dir_ls(ruta_json_perfiles(), glob = "*.json", fail = FALSE)
if (length(antiguos) > 0) fs::file_delete(antiguos)

n_perfiles <- 0L
for (i in seq_len(nrow(diputados))) {
  d   <- diputados[i, ]
  did <- d$diputado_id

  # Bloque 1: perfil ----------------------------------------------------------
  perfil <- list(
    id               = did,
    nombre           = d$nombre,
    sexo             = d$sexo,
    fecha_nacimiento = d$fecha_nacimiento,
    partido = list(
      id     = d$partido_id,
      nombre = d$partido_nombre,
      alias  = d$partido_alias
    ),
    distrito  = d$distrito,
    region    = d$region,
    tendencia = d$tendencia
  )

  # Bloque 2: asistencia ------------------------------------------------------
  # Una sola granularidad desde P-48 (sesion 15): el alcance temporal declarado,
  # los dos ambitos con sus conteos y tasas, y la serie nominal por sesion. El
  # anno de proceso viaja dentro de alcance_temporal$anio_proceso, con su ambito
  # declarado; por eso el campo suelto `anio` tampoco sobrevive.
  # La serie es el espejo de votaciones.votos[]: una entrada por sesion,
  # ordenada por fecha.
  bloque_asistencia <- list()
  amb_d <- amb_map[[did]]
  bloque_asistencia$alcance_temporal <- BLOQUE_ALCANCE
  bloque_asistencia$periodo_vigente <- if (!is.null(amb_d))
    bloque_ambito(amb_d[amb_d$ambito == "periodo_vigente", ]) else NULL
  bloque_asistencia$en_ejercicio <- if (!is.null(amb_d))
    bloque_ambito(amb_d[amb_d$ambito == "en_ejercicio", ]) else NULL

  s <- serie_map[[did]]
  bloque_asistencia$sesiones <- if (!is.null(s) && nrow(s) > 0) {
    s_ord <- s |> arrange(fecha, sesion_id)
    lapply(seq_len(nrow(s_ord)), function(k) {
      cod <- s_ord$justificacion_codigo[k]
      # justificacion anidada solo si la fuente la trae; null si no (el ausente
      # sin justificar es un caso real y distinguible, no se fabrica glosa).
      just <- if (!is.na(cod)) list(
        codigo = cod,
        glosa  = s_ord$justificacion_glosa[k],
        # Dato de la fuente, sin uso en ninguna formula: su semantica
        # reglamentaria no esta documentada (P2 de la medicion). # REVISAR.
        rebaja_asistencia = identical(s_ord$rebaja_asistencia[k], "true"),
        rebaja_quorum     = identical(s_ord$rebaja_quorum[k], "true")
      ) else NULL
      list(
        sesion_id          = s_ord$sesion_id[k],
        sesion_numero      = s_ord$sesion_numero[k],
        fecha              = s_ord$fecha[k],
        tipo_sesion        = s_ord$tipo_sesion[k],
        en_periodo_vigente = s_ord$en_periodo_vigente[k],
        asistencia         = s_ord$asistencia[k],
        justificacion      = just
      )
    })
  } else NULL

  # Bloque 3: votaciones ------------------------------------------------------
  v <- votos[votos$diputado_id == did, ]
  resumen_voto <- as.list(table(factor(v$sentido, levels = unname(DOMINIO_VOTO))))
  detalle_voto <- if (nrow(v) > 0) {
    v_ord <- v |> arrange(fecha, votacion_id)
    lapply(seq_len(nrow(v_ord)), function(k) {
      bol <- v_ord$boletin[k]
      det <- detalle_de(bol)
      # proyecto anidado si el voto tiene boletin resuelto; null si no (los ~31%
      # estructurales: acuerdos/resoluciones/otros sin boletin, o no resuelto).
      proyecto <- if (!is.null(det)) list(
        boletin         = det$boletin,
        nombre          = det$nombre,
        tipo_iniciativa = det$tipo_iniciativa,
        materias        = det$materias
      ) else NULL
      list(
        votacion_id = v_ord$votacion_id[k],
        boletin     = bol,
        # tipo de la votacion (ya venia en votos.rds; hace legible por que un
        # voto no tiene proyecto: "Proyecto de Acuerdo"/"Otros" no tienen boletin).
        tipo        = v_ord$tipo[k],
        fecha       = v_ord$fecha[k],
        resultado   = v_ord$resultado[k],
        sentido     = v_ord$sentido[k],
        descripcion = v_ord$descripcion[k],
        proyecto    = proyecto
      )
    })
  } else NULL
  bloque_votaciones <- list(
    anio               = ANIO_PROCESO,
    n_votaciones       = nrow(v),
    resumen_por_sentido = resumen_voto,
    votos              = detalle_voto
  )

  # Bloque 4: proyectos -------------------------------------------------------
  p <- proyectos[proyectos$diputado_id == did, ]
  detalle_proy <- if (nrow(p) > 0) {
    p_ord <- p |> arrange(desc(fecha_ingreso), boletin)
    lapply(seq_len(nrow(p_ord)), function(k) {
      det <- detalle_de(p_ord$boletin[k])
      list(
        boletin         = p_ord$boletin[k],
        nombre          = p_ord$nombre[k],
        fecha_ingreso   = p_ord$fecha_ingreso[k],
        admisible       = p_ord$admisible[k],
        rol             = p_ord$rol[k],
        # Contenido del paso 36: tipo (Mocion/Mensaje) y materias (categoria
        # tematica). materias vacio -> [] explicito, nunca fabricado.
        tipo_iniciativa = if (!is.null(det)) det$tipo_iniciativa else NA_character_,
        materias        = if (!is.null(det)) det$materias else MATERIAS_VACIO
      )
    })
  } else NULL
  bloque_proyectos <- list(
    anio          = ANIO_PROCESO,
    n_proyectos   = nrow(p),
    # La API no expone estado de tramitacion (ver exploracion); Admisible es el
    # unico proxy disponible. # REVISAR.
    estado_tramitacion_disponible = FALSE,
    proyectos     = detalle_proy
  )

  perfil_json <- list(
    perfil      = perfil,
    asistencia  = bloque_asistencia,
    votaciones  = bloque_votaciones,
    proyectos   = bloque_proyectos,
    metadatos   = list(
      fuente          = "opendata.camara.cl",
      periodo         = "2026-2030",
      anio_proceso    = ANIO_PROCESO,
      generado        = format(Sys.time(), "%Y-%m-%dT%H:%M:%S")
    )
  )

  escribir_json(perfil_json, ruta_json_perfiles(paste0(did, ".json")))
  n_perfiles <- n_perfiles + 1L
}

# ---- Validacion final: indice vs perfiles (POLITICA 5.3.8, verificacion) ----
archivos_perfil <- fs::dir_ls(ruta_json_perfiles(), glob = "*.json")
log_msg(sprintf("Perfiles escritos: %d ; entradas en indice: %d",
                length(archivos_perfil), nrow(indice)), origen = "39_consolidar")
if (length(archivos_perfil) != nrow(indice))
  stop(sprintf("39_consolidar: DESAJUSTE indice (%d) vs perfiles (%d).",
               nrow(indice), length(archivos_perfil)))

log_msg("Consolidacion JSON completada.", origen = "39_consolidar")

# =============================================================================
# Entidad `proyecto` (P-66 acto b) - 40_salidas/json/proyectos/<boletin>.json
# -----------------------------------------------------------------------------
# Segunda entidad del portal, con llave `boletin` y una fila por proyecto. No
# toca nada de la entidad parlamentario: los perfiles ya se escribieron arriba y
# este bloque solo agrega. El contrato es el del encargo P-66 acto b §5-F3, que
# revisa el §5.2 del veredicto del eje tematico con las diez decisiones del
# titular aplicadas.
# =============================================================================

# Universo: los boletines del corte, que son los que el 36 resolvio. El 37 cubre
# exactamente los mismos (su cuadre D38 lo prueba contra la lista pedida); si no
# coincidieran, publicar seria mezclar dos universos.
if (!setequal(proyectos_detalle$boletin, tramitacion$boletin))
  stop(sprintf(paste0("39_consolidar: el universo de proyectos_detalle (%d) y el de tramitacion ",
                      "(%d) no coinciden. No se publica una entidad con dos universos."),
               nrow(proyectos_detalle), nrow(tramitacion)), call. = FALSE)

tram_map <- lapply(seq_len(nrow(tramitacion)), function(i) tramitacion[i, ])
names(tram_map) <- tramitacion$boletin

# Roster vigente por id, para resolver el nombre del autor y marcar quien no esta.
# D-f: los autores fuera del padron se MARCAN, no se resuelven (el padron
# historico quedo fuera de alcance). Su nombre queda null, que es "no lo sabemos",
# distinguible de un nombre vacio.
nombre_de_diputado <- stats::setNames(diputados$nombre, diputados$diputado_id)

# D-j: un evento de votacion tiene detalle nominal solo si hay filas suyas en
# votos.rds. Los eventos anteriores a ANIO_PROCESO no las tienen y NO se borran
# ni se imputan: se publican con detalle_nominal = false.
VOTACIONES_CON_NOMINAL <- unique(votos$votacion_id)

# Texto fijo que declara que universo se publica y cual no (D-i). Va en cada
# proyecto y no solo en el indice: quien abre un JSON suelto tiene que poder
# saberlo sin ir a buscar otro archivo.
TEXTO_UNIVERSO <- paste0(
  "Los ", nrow(proyectos_detalle), " boletines de este corpus son los TOCADOS POR UN DIPUTADO ",
  "DEL ROSTER VIGENTE: la union de los autorados (mociones con al menos un firmante ",
  "del roster) y los votados (boletines con al menos una votacion nominal del anno ",
  "de proceso). NO son los proyectos ingresados en el anno: un boletin antiguo ",
  "votado este anno entra, y uno ingresado este anno sin firmante del roster y sin ",
  "votar no entra.")
TEXTO_AUTORIA <- paste0(
  "La autoria cubre SOLO diputados: la fuente entrega los firmantes senadores en un ",
  "nodo que este pipeline no consume, asi que un proyecto de origen Senado puede ",
  "aparecer sin autores sin que eso signifique que no los tiene.")

fs::dir_create(ruta_json("proyectos"))
antiguos_proy <- fs::dir_ls(ruta_json("proyectos"), glob = "*.json", fail = FALSE)
if (length(antiguos_proy) > 0) fs::file_delete(antiguos_proy)

filas_indice <- vector("list", nrow(proyectos_detalle))
n_proyectos_json <- 0L

for (i in seq_len(nrow(proyectos_detalle))) {
  bol <- proyectos_detalle$boletin[i]
  tr  <- tram_map[[bol]]

  # ---- Bloque tramitacion --------------------------------------------------
  # Los tramites ya vienen acotados al corte por el 37 (D-h); aqui no se filtra
  # nada mas. `sesion` entra en el contrato porque la fuente la trae y permite
  # citar el trámite en su sesion.
  tl <- tr$tramites[[1]]
  bloque_tramitacion <- list(
    etapa_actual = tr$etapa_actual,
    estado       = tr$estado,
    ley_numero   = tr$ley_numero,
    tramites     = if (nrow(tl) > 0) lapply(seq_len(nrow(tl)), function(k) list(
      fecha       = tl$fecha[k],
      camara      = tl$camara[k],
      etapa       = tl$etapa[k],
      descripcion = tl$descripcion[k],
      sesion      = tl$sesion[k])) else list()
  )

  # ---- Bloque autores ------------------------------------------------------
  # D-e: `camara` NO existe en el contrato. En su lugar, metadatos.autoria_cubre.
  a <- proyectos[proyectos$boletin == bol, ]
  ids_autor <- unique(a$diputado_id)
  bloque_autores <- if (length(ids_autor) > 0) lapply(ids_autor, function(id) list(
    parlamentario_id  = id,
    nombre            = unname(nombre_de_diputado[id]),   # NA -> null si no esta
    en_padron_vigente = id %in% diputados$diputado_id)) else list()

  # ---- Bloque votaciones ---------------------------------------------------
  vv <- proyectos_detalle$votaciones[[i]]
  bloque_votaciones <- if (nrow(vv) > 0) lapply(seq_len(nrow(vv)), function(k) list(
    votacion_id           = vv$votacion_id[k],
    fecha                 = vv$fecha[k],
    tipo                  = vv$tipo_glosa[k],
    tramite_constitucional = vv$tramite_constitucional_glosa[k],
    articulo              = vv$articulo[k],
    resultado             = vv$resultado_glosa[k],
    # D-j: se declara por evento, no se imputa ni se borra.
    detalle_nominal       = vv$votacion_id[k] %in% VOTACIONES_CON_NOMINAL)) else list()

  # ---- Bloque materias -----------------------------------------------------
  mm <- proyectos_detalle$materias[[i]]
  bloque_materias <- if (nrow(mm) > 0) lapply(seq_len(nrow(mm)), function(k) list(
    id = mm$id[k], nombre = mm$nombre[k])) else list()

  # ---- Metadatos: cada flag distingue "no tiene" de "no lo sabemos" --------
  metadatos <- list(
    corte                          = CORTE_FECHA,
    universo                       = TEXTO_UNIVERSO,
    autoria_cubre                  = TEXTO_AUTORIA,
    cobertura_materias             = nrow(mm) > 0,
    # D-d: sin este flag, un proyecto que no es ley y uno cuyo numero de ley no
    # conocemos se leerian igual.
    cobertura_ley                  = !is.na(tr$ley_numero) && nzchar(tr$ley_numero),
    cobertura_autoria              = length(ids_autor) > 0,
    tramites_descartados_por_corte = as.integer(tr$n_tramites_descartados),
    generado                       = format(Sys.time(), "%Y-%m-%dT%H:%M:%S")
  )

  proyecto_json <- list(
    boletin         = bol,
    nombre          = proyectos_detalle$nombre[i],
    tipo_iniciativa = proyectos_detalle$tipo_iniciativa[i],
    # camara_origen y fecha_ingreso vienen del SIL (paso 37): el parser de
    # contenido de la Camara no los extrae y extenderlo esta fuera del alcance
    # autorizado de este encargo. Procedencia declarada, no disimulada.
    camara_origen   = tr$camara_origen,
    fecha_ingreso   = tr$fecha_ingreso,
    tramitacion     = bloque_tramitacion,
    autores         = bloque_autores,
    votaciones      = bloque_votaciones,
    materias        = bloque_materias,
    metadatos       = metadatos
  )

  escribir_json(proyecto_json, ruta_json("proyectos", paste0(bol, ".json")))
  n_proyectos_json <- n_proyectos_json + 1L

  filas_indice[[i]] <- list(
    boletin        = bol,
    nombre         = proyectos_detalle$nombre[i],
    camara_origen  = tr$camara_origen,
    fecha_ingreso  = tr$fecha_ingreso,
    etapa_actual   = tr$etapa_actual,
    estado         = tr$estado,
    ley_numero     = tr$ley_numero,
    n_tramites     = as.integer(tr$n_tramites),
    n_autores      = length(ids_autor),
    n_votaciones   = nrow(vv),
    n_materias     = nrow(mm)
  )
}

escribir_json(filas_indice, ruta_json("indice_proyectos.json"))

archivos_proy <- fs::dir_ls(ruta_json("proyectos"), glob = "*.json")
log_msg(sprintf("Entidad proyecto: %d JSON escritos; indice con %d entradas.",
                length(archivos_proy), length(filas_indice)), origen = "39_consolidar")
if (length(archivos_proy) != nrow(proyectos_detalle))
  stop(sprintf("39_consolidar: DESAJUSTE proyectos (%d) vs universo (%d).",
               length(archivos_proy), nrow(proyectos_detalle)), call. = FALSE)

# Cobertura publicada, contada aqui y no heredada del paso 37.
con_tram <- sum(vapply(filas_indice, function(x) x$n_tramites > 0, logical(1)))
con_ley  <- sum(vapply(filas_indice, function(x)
  !is.na(x$ley_numero) && nzchar(x$ley_numero), logical(1)))
con_aut  <- sum(vapply(filas_indice, function(x) x$n_autores > 0, logical(1)))
con_mat  <- sum(vapply(filas_indice, function(x) x$n_materias > 0, logical(1)))
log_msg(sprintf(paste0("Cobertura publicada sobre %d proyectos: con tramitacion %d; con ",
                       "ley_numero %d; con autoria %d; con materias %d."),
                nrow(proyectos_detalle), con_tram, con_ley, con_aut, con_mat),
        origen = "39_consolidar")

# ---- Publicar copia en docs/data/ (GitHub Pages sirve desde /docs) ----------
# 40_salidas/json/ sigue siendo el output canonico; docs/data/ es su
# publicacion (copia fiel, hecha en R, nunca a mano). Idempotente: limpia
# docs/data/perfiles/ antes de copiar, igual que ya se hace con los perfiles
# canonicos.
ruta_docs_data <- function(...) file.path(ROOT, "docs", "data", ...)
fs::dir_create(ruta_docs_data("perfiles"))

antiguos_docs <- fs::dir_ls(ruta_docs_data("perfiles"), glob = "*.json", fail = FALSE)
if (length(antiguos_docs) > 0) fs::file_delete(antiguos_docs)

fs::file_copy(ruta_json("indice_diputados.json"),
              ruta_docs_data("indice_diputados.json"), overwrite = TRUE)
fs::file_copy(archivos_perfil, ruta_docs_data("perfiles"), overwrite = TRUE)

archivos_perfil_docs <- fs::dir_ls(ruta_docs_data("perfiles"), glob = "*.json")
log_msg(sprintf("Publicado en docs/data/: indice + %d perfiles.",
                length(archivos_perfil_docs)), origen = "39_consolidar")
if (length(archivos_perfil_docs) != nrow(indice))
  stop(sprintf("39_consolidar: DESAJUSTE docs/data perfiles (%d) vs indice (%d).",
               length(archivos_perfil_docs), nrow(indice)))
