# =============================================================================
# 31e_extraer_partidos_senado.R
# -----------------------------------------------------------------------------
# Proposito: INSTRUMENTACION (insumo del crosswalk de partidos, FASE 3 del
#            encargo de contrato de datos). Trae en vivo el roster del Senado
#            (web-back.senado.cl/api/parlamentarios?vigentes=1), filtra los 50
#            senadores (CAMARA=="S") y extrae los pares UNICOS (PARTIDO_ID,
#            PARTIDO texto) con su conteo. NO decide la tendencia: solo entrega
#            la lista de pares reales para que el titular defina el crosswalk.
# Insumos:   ninguno (fuente en vivo). Mismo backend mapeado en 31c/31d.
# Salidas:   50_documentacion/andamios/contrato_datos/senado_partidos_muestra.json
#            (muestra cruda del roster) + la tabla de pares a consola.
# Naturaleza: diagnostico regenerable. NO entra a run_all() ni a PASOS.
# Autor:     Claude Code (encargo contrato de datos, design/contrato-datos)
# Creado:    2026-07-10
# =============================================================================

source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
instalar_si_falta(c("httr2", "jsonlite", "here"))
library(httr2); library(jsonlite)

DIR_MUESTRAS <- here::here("50_documentacion", "andamios", "contrato_datos")
fs::dir_create(DIR_MUESTRAS)

descargar <- function(url, intentos = 3L, timeout_s = 40L) {
  req <- request(url) |>
    req_user_agent("Mozilla/5.0 (transparencia_legislativa_chile; R; datos publicos)") |>
    req_headers(Accept = "application/json") |>
    req_timeout(timeout_s) |>
    req_retry(max_tries = intentos, backoff = ~ 2 * .x) |>
    req_error(is_error = function(resp) FALSE)
  resp <- tryCatch(req_perform(req), error = function(e) e)
  if (inherits(resp, "error")) return(list(ok = FALSE, motivo = conditionMessage(resp)))
  raw <- resp_body_raw(resp); body <- rawToChar(raw); Encoding(body) <- "UTF-8"
  list(ok = resp_status(resp) == 200, raw = raw, body = body)
}

log_msg("Roster del Senado en vivo (api/parlamentarios?vigentes=1)", origen = "31e_partidos")
r <- descargar("https://web-back.senado.cl/api/parlamentarios?vigentes=1&limit=300")
if (!isTRUE(r$ok)) stop("31e: el backend del Senado no respondio (caso de detencion #1).")

ros <- fromJSON(r$body, simplifyVector = TRUE)$data$data
sen <- ros[ros$CAMARA == "S", ]
log_msg(sprintf("Senadores (CAMARA==S): %d", nrow(sen)), origen = "31e_partidos")

# Guardar la muestra cruda (roster completo tal cual llega del backend).
writeBin(r$raw, file.path(DIR_MUESTRAS, "senado_partidos_muestra.json"))
log_msg(sprintf("muestra guardada: senado_partidos_muestra.json (%d bytes)", length(r$raw)),
        origen = "31e_partidos")

# Pares unicos (PARTIDO_ID, PARTIDO) con conteo de senadores.
pares <- as.data.frame(table(PARTIDO_ID = sen$PARTIDO_ID,
                             PARTIDO = ifelse(is.na(sen$PARTIDO), "(NA)", sen$PARTIDO)),
                       stringsAsFactors = FALSE)
pares <- pares[pares$Freq > 0, ]
pares <- pares[order(-pares$Freq), ]
names(pares)[names(pares) == "Freq"] <- "n_senadores"
cat("\n== Pares (PARTIDO_ID, PARTIDO, n_senadores) del Senado vigente ==\n")
print(pares, row.names = FALSE)
cat(sprintf("\nTotal senadores: %d | partidos distintos: %d\n", nrow(sen), nrow(pares)))
