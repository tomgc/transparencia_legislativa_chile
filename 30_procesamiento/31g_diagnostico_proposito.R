# =============================================================================
# 31g_diagnostico_proposito.R
# -----------------------------------------------------------------------------
# Proposito: DIAGNOSTICO (solo lectura). Mide la brecha entre lo que el portal
#            PROMETE (objetivo del proyecto) y lo que ENTREGA. Cuantifica, no
#            corrige. Tres bloques:
#   FASE 1: join AUTORITATIVO votacion->boletin (retornarProyectoLey ->
#           Votaciones/VotacionProyectoLey/Id) contra el boletin-por-regex de 34.
#           Clasifica las 672 votaciones en 4 casos que suman 672:
#             (d) con boletin regex confirmado por el join
#             (c) con boletin regex NO confirmado (asignacion erronea)
#             (a) sin boletin regex pero el join SI resuelve (dato perdido)
#             (b) sin boletin y sin proyecto (estructural)
#   FASE 2: estado real de lo publicado en docs/data (roster, trazabilidad,
#           asistencia, proyectos, consistencia indice<->perfiles).
#   FASE 3: que consume/promete docs/index.html y como degrada ante null.
# Insumos:   40_salidas/intermedios/*.rds (lectura), docs/data/*.json,
#            docs/index.html, y la API de la Camara (solo FASE 1).
# Salidas:   50_documentacion/andamios/muestras/f1_mapa_votacion_boletin.rds
#            (mapa autoritativo, evidencia) + cifras a consola.
# Naturaleza: diagnostico regenerable. NO entra a run_all() ni a PASOS. SOLO
#            LECTURA sobre produccion; muestras a andamios/, nunca a 20_insumos/.
# Cortesia:  httr2 con backoff 429/500 + Sys.sleep entre llamadas.
# Autor:     Claude Code (encargo diagnostico proposito, explore/diagnostico-proposito)
# Creado:    2026-07-11
# =============================================================================

source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
instalar_si_falta(c("httr2", "xml2", "jsonlite", "here"))
library(httr2); library(xml2)

BASE <- "https://opendata.camara.cl/camaradiputados/WServices/"
DIR_MUESTRAS <- here::here("50_documentacion", "andamios", "muestras")
fs::dir_create(DIR_MUESTRAS)
PAUSA <- 0.35

descargar <- function(url, intentos = 5L, timeout_s = 40L) {
  req <- request(url) |>
    req_user_agent("transparencia_legislativa_chile (R; diagnostico; datos publicos)") |>
    req_timeout(timeout_s) |>
    req_retry(max_tries = intentos, backoff = ~ 2 * .x,
              is_transient = function(resp) resp_status(resp) %in% c(429, 500, 502, 503)) |>
    req_error(is_error = function(resp) FALSE)
  resp <- tryCatch(req_perform(req), error = function(e) e)
  Sys.sleep(PAUSA)
  if (inherits(resp, "error")) return(list(ok = FALSE, status = "ERR"))
  body <- tryCatch(resp_body_string(resp), error = function(e) "")
  list(ok = resp_status(resp) == 200, status = resp_status(resp), body = body)
}
px <- function(b) { d <- tryCatch(read_xml(b), error = function(e) NULL)
  if (!is.null(d)) xml_ns_strip(d); d }
como_llave <- function(x) { x <- trimws(as.character(x)); x[x == ""] <- NA_character_; x }

# =============================================================================
# FASE 1 — JOIN AUTORITATIVO votacion -> boletin
# =============================================================================
log_msg("== FASE 1: join autoritativo votacion<->boletin ==", origen = "31g")
v <- readRDS(here::here("40_salidas", "intermedios", "votos.rds"))
vv <- unique(v[, c("votacion_id", "boletin", "descripcion", "tipo")])
vv$votacion_id <- como_llave(vv$votacion_id); vv$boletin <- como_llave(vv$boletin)
N <- nrow(vv)
log_msg(sprintf("votaciones distintas: %d (con boletin regex: %d, sin: %d)",
                N, sum(!is.na(vv$boletin)), sum(is.na(vv$boletin))), origen = "31g")

# Universo de boletines a consultar (union). Incluye los 104 del regex.
reg_bol <- como_llave(unique(vv$boletin[!is.na(vv$boletin)]))
det <- readRDS(here::here("40_salidas", "intermedios", "proyectos_detalle.rds"))
pro <- readRDS(here::here("40_salidas", "intermedios", "proyectos.rds"))
lista_bol <- function(op) {
  d <- px(descargar(paste0(BASE, "WSLegislativo.asmx/", op, "?prmAnno=2026"))$body)
  if (is.null(d)) character(0) else como_llave(xml_text(xml_find_all(d, "//ProyectoLey/NumeroBoletin")))
}
universo <- sort(unique(c(reg_bol, como_llave(unique(det$boletin)), como_llave(unique(pro$boletin)),
                          lista_bol("retornarMocionesXAnno"), lista_bol("retornarMensajesXAnno"))))
universo <- universo[!is.na(universo)]
log_msg(sprintf("universo de boletines a consultar: %d", length(universo)), origen = "31g")

# Consulta cada boletin -> sus VotacionProyectoLey/Id (mapa autoritativo).
mapa <- list(); ok_bol <- character(); fallo_bol <- character()
for (i in seq_along(universo)) {
  b <- universo[i]
  r <- descargar(paste0(BASE, "WSLegislativo.asmx/retornarProyectoLey?prmNumeroBoletin=", utils::URLencode(b)))
  if (!isTRUE(r$ok)) { fallo_bol <- c(fallo_bol, b); next }
  d <- px(r$body)
  if (is.null(d)) { fallo_bol <- c(fallo_bol, b); next }
  # boletin no reconocido -> ProyectoLey sin Nombre; lo tratamos como fallo de resolucion
  if (is.na(texto_nodo(xml_root(d), "./Nombre"))) { fallo_bol <- c(fallo_bol, b); next }
  ok_bol <- c(ok_bol, b)
  vids <- como_llave(xml_text(xml_find_all(d, ".//Votaciones/VotacionProyectoLey/Id")))
  vids <- vids[!is.na(vids)]
  if (length(vids) > 0) mapa[[b]] <- vids
  if (i %% 50 == 0) log_msg(sprintf("  progreso: %d/%d boletines (ok=%d, fallo=%d)",
                                    i, length(universo), length(ok_bol), length(fallo_bol)), origen = "31g")
}
# Invariante de cortesia: si la fuente falla masivamente, parar.
if (length(fallo_bol) > length(universo) * 0.5)
  stop(sprintf("31g: la fuente fallo en %d/%d boletines (>50%%). Se detiene (cortesia).",
               length(fallo_bol), length(universo)))

# Mapa votacion_id -> vector de boletines que la reclaman (refundidos: puede ser >1).
auth <- list()
for (b in names(mapa)) for (vid in mapa[[b]]) auth[[vid]] <- unique(c(auth[[vid]], b))
n_multi <- sum(vapply(auth, length, integer(1)) > 1)
log_msg(sprintf("boletines resueltos OK: %d | fallidos: %d | votacion_ids en el mapa: %d (con >1 boletin: %d)",
                length(ok_bol), length(fallo_bol), length(auth), n_multi), origen = "31g")

# Clasificacion de las 672. Solo verificable si el boletin-regex fue consultado OK.
reg_ok <- reg_bol %in% ok_bol
no_verificable <- vv$boletin[!is.na(vv$boletin) & !(vv$boletin %in% ok_bol)]
clasif <- character(N)
for (k in seq_len(N)) {
  vid <- vv$votacion_id[k]; rb <- vv$boletin[k]
  a <- auth[[vid]]
  has_reg <- !is.na(rb); has_auth <- !is.null(a) && length(a) > 0
  if (has_reg && !(rb %in% ok_bol)) { clasif[k] <- "no_verificable"; next }
  if (has_reg && has_auth) clasif[k] <- if (rb %in% a) "d_confirmado" else "c_incorrecto"
  else if (has_reg && !has_auth) clasif[k] <- "c_incorrecto"   # su proyecto no la lista
  else if (!has_reg && has_auth) clasif[k] <- "a_recuperado"
  else clasif[k] <- "b_sin_proyecto"
}
tab <- table(factor(clasif, levels = c("d_confirmado","c_incorrecto","a_recuperado","b_sin_proyecto","no_verificable")))
cat("\n================ FASE 1 — CUATRO CIFRAS ================\n")
cat(sprintf("(d) con boletin, join CONFIRMA:        %d\n", tab["d_confirmado"]))
cat(sprintf("(c) con boletin, join NO confirma:     %d   <- dato ERRONEO si >0\n", tab["c_incorrecto"]))
cat(sprintf("(a) sin boletin, join SI resuelve:     %d   <- dato INCOMPLETO si >0\n", tab["a_recuperado"]))
cat(sprintf("(b) sin boletin y sin proyecto:        %d\n", tab["b_sin_proyecto"]))
cat(sprintf("    no verificable (boletin no resuelto): %d\n", tab["no_verificable"]))
cat(sprintf("    SUMA: %d (debe ser %d)\n", sum(tab), N))
if (tab["c_incorrecto"] > 0) {
  cat("\nEjemplos (c) — boletin regex vs autoritativo:\n")
  idx <- which(clasif == "c_incorrecto")
  for (k in head(idx, 8)) {
    a <- auth[[vv$votacion_id[k]]]
    cat(sprintf("  votacion %s: regex=%s | autoritativo=%s | desc=%s\n",
                vv$votacion_id[k], vv$boletin[k],
                if (is.null(a)) "(ninguno lista esta votacion)" else paste(a, collapse=","),
                substr(vv$descripcion[k], 1, 60)))
  }
}
if (length(no_verificable) > 0)
  cat("\nboletines regex NO resueltos por la API:", paste(unique(no_verificable), collapse=", "), "\n")
# Guardar mapa autoritativo como evidencia.
saveRDS(list(auth = auth, clasif = data.frame(votacion_id = vv$votacion_id, boletin_regex = vv$boletin,
             tipo = vv$tipo, clase = clasif, stringsAsFactors = FALSE),
             ok_bol = ok_bol, fallo_bol = fallo_bol),
        file.path(DIR_MUESTRAS, "f1_mapa_votacion_boletin.rds"))
log_msg("mapa autoritativo guardado: f1_mapa_votacion_boletin.rds", origen = "31g")

# =============================================================================
# FASE 2 — ESTADO REAL DE LO PUBLICADO (sin red)
# =============================================================================
log_msg("== FASE 2: estado de lo publicado en docs/data ==", origen = "31g")
DD <- here::here("docs", "data")
indice <- jsonlite::fromJSON(file.path(DD, "indice_diputados.json"), simplifyVector = FALSE)
perf_files <- list.files(file.path(DD, "perfiles"), pattern = "[.]json$", full.names = TRUE)
cat("\n================ FASE 2 — PUBLICADO ================\n")
cat(sprintf("indice: %d entradas | perfiles: %d archivos\n", length(indice), length(perf_files)))

# ROSTER: nulos por campo del indice
campos_idx <- unique(unlist(lapply(indice, names)))
nul <- sapply(campos_idx, function(c) sum(vapply(indice, function(x) is.null(x[[c]]), logical(1))))
cat("\nROSTER — nulos por campo del indice (de", length(indice), "):\n")
for (c in campos_idx) cat(sprintf("   %-16s nulos=%d%s\n", c, nul[c], if (nul[c]==length(indice)) "  <- CAMPO 100% NULO" else ""))

# Perfiles: cargar todos
perfiles <- lapply(perf_files, function(f) jsonlite::fromJSON(f, simplifyVector = FALSE))
names(perfiles) <- sub("[.]json$", "", basename(perf_files))

# TRAZABILIDAD DEL VOTO
frac_ileg <- numeric(0); tot_votos <- 0L; tot_null <- 0L
for (p in perfiles) {
  votos <- p$votaciones$votos
  if (is.null(votos) || length(votos) == 0) { frac_ileg <- c(frac_ileg, NA_real_); next }
  nulls <- sum(vapply(votos, function(x) is.null(x$proyecto), logical(1)))
  tot_votos <- tot_votos + length(votos); tot_null <- tot_null + nulls
  frac_ileg <- c(frac_ileg, nulls / length(votos))
}
cat(sprintf("\nTRAZABILIDAD DEL VOTO: %d votos totales en perfiles; %d con proyecto=null (%.1f%%)\n",
            tot_votos, tot_null, 100 * tot_null / tot_votos))
fr <- frac_ileg[!is.na(frac_ileg)]
cat(sprintf("   fraccion ilegible por diputado: min=%.3f mediana=%.3f max=%.3f\n",
            min(fr), median(fr), max(fr)))

# ASISTENCIA: sesiones que declara la fuente vs sobre las que calcula el pipeline
d_ses <- px(descargar(paste0(BASE, "WSSala.asmx/retornarSesionesXAnno?prmAnno=2026"))$body)
ses_tot <- if (is.null(d_ses)) NA else length(xml_find_all(d_ses, "//Sesion"))
ses_cel <- if (is.null(d_ses)) NA else {
  est <- xml_text(xml_find_all(d_ses, "//Sesion/Estado")); sum(grepl("celebrad", est, ignore.case = TRUE))
}
asis_int <- readRDS(here::here("40_salidas", "intermedios", "asistencia.rds"))
suma_ok <- with(asis_int, sum((n_asiste + n_no_asiste) == n_sesiones))
rng_ns <- range(asis_int$n_sesiones)
cat(sprintf("\nASISTENCIA: la fuente declara %s sesiones (%s celebradas); el pipeline usa n_sesiones por diputado en [%d, %d]\n",
            ses_tot, ses_cel, rng_ns[1], rng_ns[2]))
cat(sprintf("   n_asiste+n_no_asiste==n_sesiones en %d/%d filas del intermedio\n",
            suma_ok, nrow(asis_int)))

# PROYECTOS
n_cero_proy <- sum(vapply(perfiles, function(p) (p$proyectos$n_proyectos %||% 0) == 0, logical(1)))
estado_false <- sum(vapply(perfiles, function(p) isFALSE(p$proyectos$estado_tramitacion_disponible), logical(1)))
cat(sprintf("\nPROYECTOS: diputados con 0 proyectos: %d/%d | estado_tramitacion_disponible==false: %d/%d\n",
            n_cero_proy, length(perfiles), estado_false, length(perfiles)))

# CONSISTENCIA INDICE <-> PERFILES
idx_by_id <- setNames(indice, vapply(indice, function(x) as.character(x$id), character(1)))
disc <- 0L; ejemplos <- character()
for (p in perfiles) {
  id <- as.character(p$perfil$id); ix <- idx_by_id[[id]]
  if (is.null(ix)) { disc <- disc + 1L; next }
  nv_p <- p$votaciones$n_votaciones %||% 0; nv_i <- ix$n_votaciones %||% 0
  np_p <- p$proyectos$n_proyectos %||% 0;  np_i <- ix$n_proyectos %||% 0
  ta_p <- p$asistencia$tasa_asistencia;    ta_i <- ix$tasa_asistencia
  ok <- (nv_p == nv_i) && (np_p == np_i) &&
        (identical(is.null(ta_p), is.null(ta_i)) &&
         (is.null(ta_p) || isTRUE(abs(unlist(ta_p) - unlist(ta_i)) < 1e-9)))
  if (!ok) { disc <- disc + 1L; if (length(ejemplos) < 5) ejemplos <- c(ejemplos, id) }
}
cat(sprintf("\nCONSISTENCIA indice<->perfiles: %d discrepancias de %d\n", disc, length(perfiles)))
if (disc > 0) cat("   ejemplos:", paste(ejemplos, collapse=", "), "\n")

# INTEGRIDAD 39: indice sin perfil / perfil sin indice
ids_idx <- vapply(indice, function(x) as.character(x$id), character(1))
ids_perf <- vapply(perfiles, function(p) as.character(p$perfil$id), character(1))
cat(sprintf("\nINTEGRIDAD: en indice sin perfil: %d | en perfil sin indice: %d\n",
            length(setdiff(ids_idx, ids_perf)), length(setdiff(ids_perf, ids_idx))))

# =============================================================================
# FASE 3 — FRONTEND (docs/index.html), analisis de texto EN R
# =============================================================================
log_msg("== FASE 3: frontend docs/index.html ==", origen = "31g")
html <- readLines(here::here("docs", "index.html"), warn = FALSE)
htmltxt <- paste(html, collapse = "\n")
cat("\n================ FASE 3 — FRONTEND ================\n")
cat(sprintf("docs/index.html: %d lineas, %d caracteres\n", length(html), nchar(htmltxt)))
# campos del JSON referenciados por el frontend (busqueda de tokens en R)
campos_json <- c("id","nombre","sexo","partido","partido_nombre","distrito","region","tendencia",
                 "tasa_asistencia","n_proyectos","n_votaciones","fecha_nacimiento","alias",
                 "n_sesiones","n_asiste","n_no_asiste","resumen_por_sentido","votos","votacion_id",
                 "boletin","resultado","sentido","descripcion","proyecto","materias","tipo_iniciativa",
                 "fecha_ingreso","admisible","rol","estado_tramitacion_disponible","justificacion",
                 "quorum","circunscripcion")
cat("\ncampos referenciados en el HTML/JS del frontend:\n")
for (c in campos_json) {
  n <- lengths(regmatches(htmltxt, gregexpr(paste0("\\b", c, "\\b"), htmltxt)))
  cat(sprintf("   %-28s %s (%d)\n", c, if (n>0) "USA" else "no", n))
}
# manejo de null: buscar patrones
cat("\nmanejo de null (fragmentos):\n")
for (pat in c("null","N/A","sin datos","Sin datos","No disponible","—","??","undefined")) {
  n <- lengths(regmatches(htmltxt, gregexpr(pat, htmltxt, fixed = TRUE)))
  if (n > 0) cat(sprintf("   patron '%s': %d apariciones\n", pat, n))
}
# filtros: por region/distrito/partido/tendencia/camara
cat("\nfiltros/segmentacion detectados:\n")
for (f in c("distrito","region","circunscripcion","partido","tendencia","camara","filtro","filter","select")) {
  n <- lengths(regmatches(htmltxt, gregexpr(f, htmltxt, ignore.case = TRUE)))
  if (n > 0) cat(sprintf("   '%s': %d\n", f, n))
}

log_msg("== 31g terminado ==", origen = "31g")
