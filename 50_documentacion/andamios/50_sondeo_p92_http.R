# =============================================================================
# 50_sondeo_p92_http.R  --  P-92: contador y libro mayor de llamadas HTTP
# -----------------------------------------------------------------------------
# El presupuesto del encargo es de 300 llamadas, con detencion a las 250. Un
# contador en memoria no sirve: cada fase corre en su propio proceso Rscript, y
# un contador que se reinicia con el proceso reporta una cifra falsa. El libro
# mayor es un CSV en disco, y el tope se evalua contra el CSV, no contra la
# sesion.
#
# Cada fila: n, momento, metodo, url, status, bytes, md5, etiqueta.
# El md5 del cuerpo permite el control negativo del catalogo (§1.1 del catalogo
# de fuentes: el servidor devuelve 200 con una pagina catch-all identica para
# cualquier ruta inexistente, asi que el status no prueba existencia).
# =============================================================================

P92_LEDGER <- "50_documentacion/andamios/muestras/p92_llamadas_http.csv"
P92_TOPE_DURO   <- 300L
P92_TOPE_AVISO  <- 250L

p92_gastadas <- function() {
  if (!file.exists(P92_LEDGER)) return(0L)
  nrow(utils::read.csv(P92_LEDGER, stringsAsFactors = FALSE))
}

p92_http <- function(url, etiqueta, metodo = "GET", cuerpo = NULL,
                     headers = NULL, guardar = NULL, timeout_s = 45) {
  gastadas <- p92_gastadas()
  if (gastadas >= P92_TOPE_AVISO) {
    stop(sprintf(paste0("PRESUPUESTO DE RED: %d de %d llamadas gastadas. El encargo ordena ",
                        "detenerse a las %d. No se emite la llamada '%s'."),
                 gastadas, P92_TOPE_DURO, P92_TOPE_AVISO, etiqueta), call. = FALSE)
  }
  n <- gastadas + 1L
  t0 <- Sys.time()
  cfg <- list(httr::timeout(timeout_s),
              httr::user_agent("transparencia_legislativa_chile/sondeo-p92 (R; contacto en el repo)"))
  if (!is.null(headers)) cfg <- c(cfg, list(do.call(httr::add_headers, headers)))
  r <- tryCatch({
    if (identical(metodo, "POST"))
      do.call(httr::POST, c(list(url, body = cuerpo, encode = "form"), cfg))
    else
      do.call(httr::GET, c(list(url), cfg))
  }, error = function(e) structure(list(error = conditionMessage(e)), class = "p92_error"))

  if (inherits(r, "p92_error")) {
    status <- NA_integer_; bytes <- NA_integer_; md5 <- NA_character_; txt <- NA_character_
    cat(sprintf("  [%03d] ERROR DE RED  %-38s  %s\n", n, etiqueta, r$error))
  } else {
    raw_body <- httr::content(r, as = "raw")
    status <- httr::status_code(r); bytes <- length(raw_body)
    tf <- tempfile(); writeBin(raw_body, tf); md5 <- unname(tools::md5sum(tf)); unlink(tf)
    txt <- tryCatch(httr::content(r, as = "text", encoding = "UTF-8"), error = function(e) NA_character_)
    cat(sprintf("  [%03d] %s %-38s  status=%s bytes=%d md5=%s\n",
                n, metodo, etiqueta, status, bytes, substr(md5, 1, 8)))
    if (!is.null(guardar)) {
      dir.create(dirname(guardar), showWarnings = FALSE, recursive = TRUE)
      writeBin(raw_body, guardar)
    }
  }
  fila <- data.frame(n = n, momento = format(t0, "%Y-%m-%dT%H:%M:%S"), metodo = metodo,
                     url = substr(url, 1, 300), status = status, bytes = bytes,
                     md5 = md5, etiqueta = etiqueta, stringsAsFactors = FALSE)
  dir.create(dirname(P92_LEDGER), showWarnings = FALSE, recursive = TRUE)
  utils::write.table(fila, P92_LEDGER, sep = ",", row.names = FALSE, qmethod = "double",
                     col.names = !file.exists(P92_LEDGER), append = file.exists(P92_LEDGER))
  invisible(list(n = n, status = status, bytes = bytes, md5 = md5, texto = txt,
                 respuesta = if (inherits(r, "p92_error")) NULL else r))
}

p92_reporte_presupuesto <- function() {
  g <- p92_gastadas()
  cat(sprintf("\n  >> PRESUPUESTO DE RED: %d de %d llamadas gastadas (aviso a %d).\n",
              g, P92_TOPE_DURO, P92_TOPE_AVISO))
  invisible(g)
}
