# =============================================================================
# 33_extraer_asistencia.R
# -----------------------------------------------------------------------------
# Proposito: Extraer la asistencia a sesiones de sala del anno de proceso y
#            agregarla por diputado (n sesiones, asiste, no asiste, tasa
#            efectiva como decimal). La tasa NO se redondea (POLITICA 5.3.6).
# Insumos:   API Camara: WSSala.asmx/retornarSesionesXAnno (lista de sesiones)
#            y WSSala.asmx/retornarSesionAsistencia (detalle por sesion).
#            Cache: 20_insumos/camara/AAAAMMDD_asistencia_long_<anio>.rds
# Salidas:   40_salidas/intermedios/asistencia.rds (una fila por diputado).
# Autor:     Claude Code (encargo autonomo, sesion 1)
# Creado:    2026-07-06
# =============================================================================

source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
instalar_si_falta(c("httr", "xml2", "dplyr", "here", "fs"))
library(dplyr)

ROOT <- obtener_raiz_proyecto()
source(file.path(ROOT, "10_utils", "10_configuracion.R"))

# ---- Descargar asistencia en formato largo (diputado x sesion) --------------
extraer_asistencia_long <- function() {
  cache_key <- sprintf("asistencia_long_%d", ANIO_PROCESO)
  con_cache(cache_key, function() {
    doc_ses <- descargar_xml_camara("WSSala.asmx/retornarSesionesXAnno",
                                    list(prmAnno = ANIO_PROCESO))
    ses <- xml2::xml_find_all(doc_ses, "//Sesion")
    ses_id     <- vapply(ses, function(s) texto_nodo(s, "./Id"), character(1))
    ses_estado <- vapply(ses, function(s) texto_nodo(s, "./Estado"), character(1))
    # Solo sesiones celebradas tienen asistencia (las demas devuelven vacio).
    celebradas <- ses_id[!is.na(ses_id) &
                           grepl("celebrad", ses_estado, ignore.case = TRUE)]
    log_msg(sprintf("Sesiones %d: %d totales, %d celebradas.",
                    ANIO_PROCESO, length(ses_id), length(celebradas)),
            origen = "33_asistencia")

    if (is.finite(MAX_SESIONES_DETALLE) && length(celebradas) > MAX_SESIONES_DETALLE) {
      log_msg(sprintf("Topando a %d sesiones (MAX_SESIONES_DETALLE).",
                      MAX_SESIONES_DETALLE), "WARN", "33_asistencia")
      celebradas <- celebradas[seq_len(MAX_SESIONES_DETALLE)]
    }

    filas <- list()
    for (sid in celebradas) {
      d <- descargar_xml_camara("WSSala.asmx/retornarSesionAsistencia",
                                list(prmSesionId = sid))
      asis <- xml2::xml_find_all(d, "//Asistencia")
      if (length(asis) == 0) { Sys.sleep(PAUSA_API_SEG); next }
      filas[[length(filas) + 1L]] <- tibble(
        sesion_id   = sid,
        diputado_id = como_llave(vapply(asis, function(a)
          texto_nodo(a, "./Diputado/Id"), character(1))),
        tipo_valor  = vapply(asis, function(a)
          attr_nodo(a, "./TipoAsistencia", "Valor"), character(1))
      )
      Sys.sleep(PAUSA_API_SEG)
    }
    bind_rows(filas)
  }, tope = MAX_SESIONES_DETALLE, origen = "33_asistencia")
}

asis_long <- extraer_asistencia_long()
log_msg(sprintf("Registros de asistencia (largo): %d", nrow(asis_long)),
        origen = "33_asistencia")

# ---- Validar dominio de TipoAsistencia (POLITICA 5.3.8) ---------------------
valores_obs <- sort(unique(asis_long$tipo_valor))
fuera <- setdiff(valores_obs, names(DOMINIO_ASISTENCIA))
if (length(fuera) > 0)
  log_msg(sprintf("Aviso: valores de TipoAsistencia fuera del dominio conocido: %s",
                  paste(fuera, collapse = ", ")), "WARN", "33_asistencia")

# ---- Agregar por diputado ----------------------------------------------------
asistencia <- asis_long |>
  mutate(etiqueta = unname(DOMINIO_ASISTENCIA[tipo_valor])) |>
  summarise(
    n_sesiones  = n(),
    n_asiste    = sum(etiqueta == "asiste",   na.rm = TRUE),
    n_no_asiste = sum(etiqueta == "no_asiste", na.rm = TRUE),
    .by = diputado_id
  ) |>
  mutate(
    # Tasa efectiva como decimal, sin redondear (POLITICA 5.3.6).
    tasa_asistencia = ifelse(n_sesiones > 0, n_asiste / n_sesiones, NA_real_)
  )

# ---- Validacion de integridad -----------------------------------------------
n <- nrow(asistencia)
log_msg(sprintf("Diputados con asistencia agregada: %d", n), origen = "33_asistencia")
if (n > 0) {
  rng <- range(asistencia$tasa_asistencia, na.rm = TRUE)
  log_msg(sprintf("Rango tasa_asistencia: [%.4f, %.4f]", rng[1], rng[2]),
          origen = "33_asistencia")
  if (any(asistencia$tasa_asistencia < 0 | asistencia$tasa_asistencia > 1, na.rm = TRUE))
    stop("33_asistencia: tasa_asistencia fuera de [0,1] (invariante de rango).")
  if (any(is.na(asistencia$diputado_id)))
    stop("33_asistencia: diputado_id NA en el agregado.")
}

# ---- Persistir ---------------------------------------------------------------
ruta_out <- ruta_salidas("intermedios", "asistencia.rds")
escribir_atomico(asistencia, ruta_out, function(o, r) saveRDS(o, r))
log_msg(sprintf("Escrito: %s (%d filas)", ruta_out, n), origen = "33_asistencia")
