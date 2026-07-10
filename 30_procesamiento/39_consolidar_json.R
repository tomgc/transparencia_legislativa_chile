# =============================================================================
# 39_consolidar_json.R
# -----------------------------------------------------------------------------
# Proposito: Fusionar las tablas intermedias (diputados, asistencia, votos,
#            proyectos) en los JSON estaticos que consume el dashboard:
#              - 40_salidas/json/indice_diputados.json  (selector, con metricas
#                resumen por diputado: tasa_asistencia, n_proyectos, n_votaciones;
#                y sexo/partido_nombre para que el cliente no fabrique ni
#                embeba a mano lo que ya viene en la fuente)
#              - 40_salidas/json/perfiles/<id>.json      (uno por diputado)
#            Claves ordenadas, indentacion fija, UTF-8 (POLITICA 2, 5.5).
#            Publica ademas una copia en docs/data/ para GitHub Pages (Fase 2).
# Insumos:   40_salidas/intermedios/{diputados,asistencia,votos,proyectos}.rds
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

# ---- Cargar intermedios ------------------------------------------------------
leer <- function(nombre) {
  ruta <- ruta_salidas("intermedios", paste0(nombre, ".rds"))
  if (!file.exists(ruta))
    stop(sprintf("39_consolidar: falta el intermedio '%s'. Corre el paso previo.",
                 ruta))
  readRDS(ruta)
}
diputados  <- leer("diputados")
asistencia <- leer("asistencia")
votos      <- leer("votos")
proyectos  <- leer("proyectos")
# Detalle de contenido por boletin (tipo_iniciativa, materias) del paso 36.
# Habilita: proyectos legibles (materias) y trazabilidad voto->proyecto.
proyectos_detalle <- leer("proyectos_detalle")

# La llave es character en todas las tablas (invariante POLITICA 5.3.6).
stopifnot(is.character(diputados$diputado_id),
          is.character(asistencia$diputado_id),
          is.character(votos$diputado_id),
          is.character(proyectos$diputado_id),
          is.character(proyectos_detalle$boletin))

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
cobertura(asistencia, "Asistencia")
cobertura(votos,      "Votaciones")
cobertura(proyectos,  "Proyectos")

# ---- Metricas resumen por diputado (para el indice) --------------------------
# left_join sobre el roster (nunca inner_join): un diputado sin votos/proyectos
# debe quedar con 0, no desaparecer del indice. tasa_asistencia queda NA si el
# diputado no tiene fila en asistencia (mismo criterio que el bloque de perfil).
resumen_asistencia <- asistencia |>
  select(diputado_id, tasa_asistencia)

resumen_votos <- votos |>
  summarise(n_votaciones = n(), .by = diputado_id)

resumen_proyectos <- proyectos |>
  summarise(n_proyectos = n(), .by = diputado_id)

# ---- indice_diputados.json (lista minima para el selector, con metricas) ----
indice <- diputados |>
  left_join(resumen_asistencia, by = "diputado_id") |>
  left_join(resumen_votos,      by = "diputado_id") |>
  left_join(resumen_proyectos,  by = "diputado_id") |>
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
    tasa_asistencia = tasa_asistencia,
    n_proyectos     = n_proyectos,
    n_votaciones    = n_votaciones
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
  a <- asistencia[asistencia$diputado_id == did, ]
  bloque_asistencia <- if (nrow(a) == 1) {
    list(anio = ANIO_PROCESO,
         n_sesiones      = a$n_sesiones,
         n_asiste        = a$n_asiste,
         n_no_asiste     = a$n_no_asiste,
         tasa_asistencia = a$tasa_asistencia)
  } else {
    list(anio = ANIO_PROCESO, n_sesiones = 0L, n_asiste = 0L,
         n_no_asiste = 0L, tasa_asistencia = NA_real_)
  }

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
