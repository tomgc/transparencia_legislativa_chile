# =============================================================================
# 31d_explorar_asistencia_senado.R
# -----------------------------------------------------------------------------
# Proposito: INSTRUMENTACION (diagnostico insumos-first, H1-bis). Responder con
#            evidencia si el Senado expone asistencia NOMINAL POR SESION (quien
#            asistio / se ausento / justifico en CADA sesion), cruzable por
#            ID_PARLAMENTARIO — o si solo hay el agregado por legislatura que
#            mapeo v02 (31c). Cierra el sub-hueco que v02 dejo sin agotar.
# Insumos:   ninguno (fuente primaria en vivo). Continua 31c (backend senado.cl).
#            Cruza contra el roster ya capturado por 31c
#            (andamios/exploracion_api_senado_v02/senado_backend_parlamentarios_vigentes_muestra.json).
# Salidas:   50_documentacion/andamios/exploracion_asistencia_senado/<fuente>_sesion_<id>_muestra.json
#            + estructura/conteos a consola. Analisis en
#            50_documentacion/activa/exploracion_asistencia_senado.md (a mano).
# Naturaleza: diagnostico regenerable. NO forma parte del pipeline (00_run_all.R)
#            ni de PASOS. Se corre a mano.
# Hallazgo:  el MISMO endpoint web-back.senado.cl/api/sessions/attendance es
#            polimorfico: con ?id_legislatura=<id> da el AGREGADO por senador
#            (v02); con ?id_sesion=<id> da el NOMINAL POR SESION (este script).
# Autor:     Claude Code (encargo H1-bis, explore/api-senado-v02-asistencia)
# Creado:    2026-07-10
# =============================================================================

# ---- Utilidades genericas (NO el cliente de la Camara) ----------------------
source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
instalar_si_falta(c("httr2", "jsonlite", "here"))
library(httr2)
library(jsonlite)

DIR_MUESTRAS <- here::here("50_documentacion", "andamios", "exploracion_asistencia_senado")
fs::dir_create(DIR_MUESTRAS)
RUTA_ROSTER_V02 <- here::here("50_documentacion", "andamios", "exploracion_api_senado_v02",
                             "senado_backend_parlamentarios_vigentes_muestra.json")

BACKEND <- "https://web-back.senado.cl/api/"
# ID_LEGISLATURA del backend (espacio propio; = "legislatura 372" en numeracion
# humana). Descubierto en 31c/v02 desde la XHR de la pagina de asistencia.
ID_LEGISLATURA_BACKEND <- 504L

# ---- Cliente HTTP resiliente (httr2). Devuelve raw + string + status --------
descargar <- function(url, intentos = 3L, timeout_s = 40L) {
  req <- request(url) |>
    req_user_agent("Mozilla/5.0 (transparencia_legislativa_chile; R; datos publicos)") |>
    req_headers(Accept = "application/json") |>
    req_timeout(timeout_s) |>
    req_retry(max_tries = intentos, backoff = ~ 2 * .x) |>
    req_error(is_error = function(resp) FALSE)
  resp <- tryCatch(req_perform(req), error = function(e) e)
  if (inherits(resp, "error"))
    return(list(ok = FALSE, motivo = conditionMessage(resp), url = url))
  raw  <- resp_body_raw(resp)
  body <- rawToChar(raw); Encoding(body) <- "UTF-8"
  ct   <- resp_header(resp, "content-type") %||% "?"
  list(ok = resp_status(resp) == 200 && grepl("json", ct, ignore.case = TRUE),
       status = resp_status(resp), ct = ct, raw = raw, body = body, url = url)
}
guardar <- function(resp, archivo) {
  if (!isTRUE(resp$ok)) {
    log_msg(sprintf("  NO se guarda %s (status %s)", archivo, resp$status %||% resp$motivo),
            "WARN", "31d_senado"); return(invisible(NULL))
  }
  ruta <- file.path(DIR_MUESTRAS, archivo)
  writeBin(resp$raw, ruta)
  log_msg(sprintf("  muestra guardada: %s (%d bytes)", archivo, length(resp$raw)),
          origen = "31d_senado")
  invisible(ruta)
}

# =============================================================================
# FLUJO
# =============================================================================
log_msg("== H1-bis: asistencia nominal por sesion del Senado (backend senado.cl) ==",
        origen = "31d_senado")

# ---- 1. Universo de sesiones de la legislatura (para obtener ID_SESION reales) ----
# El listado da las sesiones de una legislatura; la asistencia por sesion se pide
# con el ID_SESION. Se muestrea UNA sesion RECIENTE (de las votaciones vigentes) y
# UNA HISTORICA (del listado de la legislatura 504 = "372", marzo 2025), para
# mostrar el detalle nominal en dos periodos y el efecto del cambio de roster.
log_msg(sprintf("1. Listar sesiones (api/sessions?id_legislatura=%d)", ID_LEGISLATURA_BACKEND),
        origen = "31d_senado")
r_ses <- descargar(sprintf("%ssessions?id_legislatura=%d", BACKEND, ID_LEGISLATURA_BACKEND))
sesion_historica <- "9884"  # respaldo conocido (marzo 2025)
if (isTRUE(r_ses$ok)) {
  js <- fromJSON(r_ses$body, simplifyVector = TRUE)
  ds <- js$data$data
  cat(sprintf("    sesiones en la pagina: %d (total declarado: %s)\n", nrow(ds), js$data$total %||% "-"))
  cat("    columnas:", paste(names(ds), collapse = ", "), "\n")
  sesion_historica <- as.character(ds$ID_SESION[1])
  guardar(r_ses, sprintf("senado_backend_sesiones_legislatura_%d_muestra.json", ID_LEGISLATURA_BACKEND))
}
# Sesion reciente = mayor ID_SESION con votacion registrada (via /api/votes).
r_vot <- descargar(sprintf("%svotes", BACKEND))
sesion_reciente <- "10221"  # respaldo conocido (julio 2026)
if (isTRUE(r_vot$ok)) {
  ids_v <- fromJSON(r_vot$body, simplifyVector = TRUE)$data$data$ID_SESION
  if (length(ids_v) > 0) sesion_reciente <- as.character(max(ids_v))
}
sesiones_muestra <- c(reciente = sesion_reciente, historica = sesion_historica)
cat(sprintf("    sesion RECIENTE=%s | sesion HISTORICA=%s\n", sesion_reciente, sesion_historica))

# ---- 2/3. Asistencia NOMINAL por sesion + cruce por id contra el roster v02 --
# El MISMO endpoint attendance, con id_sesion en vez de id_legislatura, devuelve
# el detalle nominal {ASISTENCIA, JUSTIFICACION} por senador con ID_PARLAMENTARIO.
ids_senadores <- character(0)
if (file.exists(RUTA_ROSTER_V02)) {
  ros <- fromJSON(RUTA_ROSTER_V02, simplifyVector = TRUE)$data$data
  ids_senadores <- as.character(ros$ID_PARLAMENTARIO[ros$CAMARA == "S"])
}
for (etq in names(sesiones_muestra)) {
  sid <- sesiones_muestra[[etq]]
  log_msg(sprintf("2. Asistencia nominal, sesion %s (%s) via attendance?id_sesion=%s", sid, etq, sid),
          origen = "31d_senado")
  r <- descargar(sprintf("%ssessions/attendance?id_sesion=%s", BACKEND, sid))
  if (!isTRUE(r$ok)) { log_msg("   sesion sin datos", "WARN", "31d_senado"); next }
  j <- fromJSON(r$body, simplifyVector = TRUE)
  d <- j$data$DATA
  cat(sprintf("    sesion N %s (%s) | senadores: %s\n",
              j$data$NUMERO_SESION %||% "-", j$data$FECHA_HORA_INICIO %||% "-",
              j$data$TOTAL_SENADORES %||% nrow(d)))
  cat("    columnas por senador:", paste(names(d), collapse = ", "), "\n")
  cat("    ¿ID_PARLAMENTARIO?:", "ID_PARLAMENTARIO" %in% names(d),
      "| ¿id 1110 (Araya) presente?:", 1110 %in% d$ID_PARLAMENTARIO, "\n")
  cat("    dominio ASISTENCIA:", paste(sprintf("%s=%d", names(table(d$ASISTENCIA)), table(d$ASISTENCIA)),
                                       collapse = " "), "\n")
  jc <- d$JUSTIFICACION[!is.na(d$JUSTIFICACION) & nzchar(d$JUSTIFICACION)]
  cat("    dominio JUSTIFICACION:", if (length(jc)) paste(sprintf("%s=%d", names(table(jc)), table(jc)),
                                                          collapse = " ") else "(ninguna)", "\n")
  # Cruce determinista por id contra el roster VIGENTE (v02).
  if (length(ids_senadores) > 0) {
    ids_asis <- as.character(d$ID_PARLAMENTARIO)
    cat(sprintf("    cruce por id vs roster VIGENTE: %d/%d senadores (%s: el roster cambia en el tiempo)\n",
                sum(ids_asis %in% ids_senadores), length(ids_asis),
                if (etq == "historica") "esperado <50" else "esperado 50/50"))
  }
  guardar(r, sprintf("senado_backend_sesion_%s_muestra.json", sid))
}

log_msg("== H1-bis terminada. Muestras en andamios/exploracion_asistencia_senado/ ==",
        origen = "31d_senado")
