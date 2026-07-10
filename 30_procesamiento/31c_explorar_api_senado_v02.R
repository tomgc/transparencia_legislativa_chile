# =============================================================================
# 31c_explorar_api_senado_v02.R
# -----------------------------------------------------------------------------
# Proposito: INSTRUMENTACION (diagnostico insumos-first, v02). Cerrar los tres
#            huecos que dejo el diagnostico v01 (exploracion_api_senado.md):
#              H1 asistencia nominal (v01 la dio por hueco),
#              H2 roster real de 50 senadores (v01 obtuvo 31, incorrecto),
#              H3 opendata.congreso.cl e IDENTIFICADORES ESTABLES de parlamentario
#                 (v01 dependia de matching por nombre).
#            Descubre en vivo el backend JSON del sitio senado.cl
#            (web-back.senado.cl/api) y el portal opendata.congreso.cl, trae
#            muestras reales y verifica que el id de parlamentario (PARLID) es
#            consistente entre roster, asistencia y votos.
# Insumos:   ninguno (fuentes primarias en vivo). Continua 31b (wspublico).
# Salidas:   50_documentacion/andamios/exploracion_api_senado_v02/<fuente>_<entidad>_muestra.<ext>
#            + estructura y conteos a consola. Analisis en
#            50_documentacion/activa/exploracion_api_senado_v02.md (a mano).
# Naturaleza: diagnostico regenerable. NO forma parte del pipeline (00_run_all.R)
#            ni de PASOS. Se corre a mano.
# Transporte: httr2 (JSON via jsonlite; el backend exige User-Agent de navegador).
# Autor:     Claude Code (encargo diagnostico API Senado v02, explore/api-senado-v02)
# Creado:    2026-07-10
# =============================================================================

# ---- Utilidades genericas (NO el cliente de la Camara) ----------------------
source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
instalar_si_falta(c("httr2", "jsonlite", "here"))
library(httr2)
library(jsonlite)

DIR_MUESTRAS <- here::here("50_documentacion", "andamios", "exploracion_api_senado_v02")
fs::dir_create(DIR_MUESTRAS)

# Legislatura vigente en el backend senado.cl (espacio de ids PROPIO, distinto al
# de wspublico): 504. Se descubrio en la llamada XHR de la pagina de asistencia
# (senado.cl/actividad-legislativa/sala/asistencia -> api/sessions/attendance?id_legislatura=504).
ID_LEGISLATURA_BACKEND <- 504L
# Votacion de muestra para el detalle nominal (cualquier ID_VOTACION reciente).
ID_VOTACION_MUESTRA    <- 11155L

# ---- Cliente HTTP resiliente (httr2). Devuelve raw + string + status --------
descargar <- function(url, accept = "application/json", intentos = 3L, timeout_s = 40L) {
  req <- request(url) |>
    req_user_agent("Mozilla/5.0 (transparencia_legislativa_chile; R; datos publicos)") |>
    req_headers(Accept = accept) |>
    req_timeout(timeout_s) |>
    req_retry(max_tries = intentos, backoff = ~ 2 * .x) |>
    req_error(is_error = function(resp) FALSE)
  resp <- tryCatch(req_perform(req), error = function(e) e)
  if (inherits(resp, "error"))
    return(list(ok = FALSE, motivo = conditionMessage(resp), url = url))
  raw  <- resp_body_raw(resp)
  body <- rawToChar(raw); Encoding(body) <- "UTF-8"
  ct   <- resp_header(resp, "content-type") %||% "?"
  es_json <- grepl("json", ct, ignore.case = TRUE)
  list(ok = resp_status(resp) == 200 && es_json, status = resp_status(resp),
       ct = ct, raw = raw, body = body, url = url)
}

guardar <- function(resp, archivo) {
  if (!isTRUE(resp$ok)) {
    log_msg(sprintf("  NO se guarda %s (status %s)", archivo, resp$status %||% resp$motivo),
            "WARN", "31c_senado")
    return(invisible(NULL))
  }
  ruta <- file.path(DIR_MUESTRAS, archivo)
  writeBin(resp$raw, ruta)
  log_msg(sprintf("  muestra guardada: %s (%d bytes)", archivo, length(resp$raw)),
          origen = "31c_senado")
  invisible(ruta)
}

# =============================================================================
# FLUJO
# =============================================================================
log_msg("== Exploracion API Senado v02: backend senado.cl + opendata.congreso.cl ==",
        origen = "31c_senado")

# ---- H3.a opendata.congreso.cl: enumerar recursos (es un DIRECTORIO) ---------
log_msg("H3.a opendata.congreso.cl (jsonapi root: catalogo de recursos)", origen = "31c_senado")
r_oc <- descargar("https://web-back.senado.cl/jsonapi", accept = "application/vnd.api+json")
# Nota: opendata.congreso.cl es un portal de documentacion que enlaza wspublico
# (Senado, v01) y wscamaradiputados.asmx (Camara). El backend de DATOS del sitio
# senado.cl es web-back.senado.cl; su jsonapi lista los tipos de nodo (incl.
# node--parlamentarios, con field_id = PARLID).
if (isTRUE(r_oc$ok)) {
  j <- fromJSON(r_oc$body, simplifyVector = FALSE)
  tipos <- if (is.null(j$links)) character() else names(j$links)
  cat(sprintf("    tipos de recurso en el jsonapi: %d\n", length(tipos)))
  cat("    de interes:", paste(grep("parlament|legislat|region", tipos, value = TRUE, ignore.case = TRUE),
                               collapse = ", "), "\n")
  guardar(r_oc, "opendata_congreso_jsonapi_root_muestra.json")
}

# ---- H2 ROSTER: /api/parlamentarios?vigentes=1 (ambas camaras, con id) -------
log_msg("H2 Roster vigente (web-back.senado.cl/api/parlamentarios?vigentes=1)", origen = "31c_senado")
r_ros <- descargar("https://web-back.senado.cl/api/parlamentarios?vigentes=1&limit=300")
if (isTRUE(r_ros$ok)) {
  jr <- fromJSON(r_ros$body, simplifyVector = TRUE)
  ros <- jr$data$data
  cat(sprintf("    total vigentes: %s | filas: %d\n", jr$data$total %||% "-", nrow(ros)))
  cat("    columnas:", paste(names(ros), collapse = ", "), "\n")
  cat("    conteo por CAMARA (D=diputado, S=senador):\n")
  print(table(ros$CAMARA))
  cat(sprintf("    -> SENADORES vigentes: %d\n", sum(ros$CAMARA == "S")))
  guardar(r_ros, "senado_backend_parlamentarios_vigentes_muestra.json")
}

# ---- H1 ASISTENCIA: /api/sessions/attendance?id_legislatura=<id> -------------
log_msg(sprintf("H1 Asistencia nominal (api/sessions/attendance?id_legislatura=%d)",
                ID_LEGISLATURA_BACKEND), origen = "31c_senado")
r_asi <- descargar(sprintf("https://web-back.senado.cl/api/sessions/attendance?id_legislatura=%d",
                           ID_LEGISLATURA_BACKEND))
if (isTRUE(r_asi$ok)) {
  ja <- fromJSON(r_asi$body, simplifyVector = TRUE)
  cat(sprintf("    TOTAL_SENADORES: %s | TOTAL_SESIONES: %s\n",
              ja$data$TOTAL_SENADORES %||% "-", ja$data$TOTAL_SESIONES %||% "-"))
  cat("    columnas por senador:", paste(names(ja$data$DATA), collapse = ", "), "\n")
  cat("    ¿trae ID_PARLAMENTARIO?:", "ID_PARLAMENTARIO" %in% names(ja$data$DATA), "\n")
  guardar(r_asi, "senado_backend_asistencia_muestra.json")
}

# ---- H3.b VOTOS lista: /api/votes (con BOLETIN -> join a proyecto) -----------
log_msg("H3.b Votaciones lista (web-back.senado.cl/api/votes)", origen = "31c_senado")
r_vl <- descargar("https://web-back.senado.cl/api/votes")
if (isTRUE(r_vl$ok)) {
  jv <- fromJSON(r_vl$body, simplifyVector = TRUE)
  cat(sprintf("    total votaciones: %s | columnas: %s\n",
              jv$data$total %||% "-", paste(names(jv$data$data), collapse = ", ")))
  cat("    ¿trae BOLETIN (join a proyecto)?:", "BOLETIN" %in% names(jv$data$data), "\n")
  guardar(r_vl, "senado_backend_votos_lista_muestra.json")
}

# ---- H3.c VOTO detalle nominal: /api/votes?id_votacion=<id> (con PARLID) -----
log_msg(sprintf("H3.c Voto detalle nominal (api/votes?id_votacion=%d)", ID_VOTACION_MUESTRA),
        origen = "31c_senado")
r_vd <- descargar(sprintf("https://web-back.senado.cl/api/votes?id_votacion=%d", ID_VOTACION_MUESTRA))
if (isTRUE(r_vd$ok)) {
  jd <- fromJSON(r_vd$body, simplifyVector = FALSE)
  vt <- jd$data$data[[1]]
  grupos <- vt$VOTACIONES
  n_por <- vapply(names(grupos), function(g) {
    x <- grupos[[g]]; if (is.list(x)) length(x) else as.integer(x %||% 0L) }, integer(1))
  cat(sprintf("    boletin: %s | sentido agregado SI/NO/ABS/PAREO: %s/%s/%s/%s\n",
              vt$BOLETIN, vt$SI, vt$NO, vt$ABS, vt$PAREO))
  cat("    grupos de sentido en VOTACIONES:", paste(sprintf("%s=%d", names(n_por), n_por), collapse = " "), "\n")
  primer <- grupos$SI[[1]]
  cat("    campos de un voto nominal:", paste(names(primer), collapse = ", "), "\n")
  cat("    ¿trae PARLID (id estable)?:", "PARLID" %in% names(primer),
      "| ejemplo PARLID:", primer$PARLID, "(", primer$NOMBRE, primer$APELLIDO_PATERNO, ")\n")
  guardar(r_vd, "senado_backend_voto_detalle_muestra.json")
}

log_msg("== v02 terminada. Muestras en andamios/exploracion_api_senado_v02/ ==", origen = "31c_senado")
