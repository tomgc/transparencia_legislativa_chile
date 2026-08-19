# =============================================================================
# 50_sondeo_p92_f2c.R  --  P-92, F2 (cont.): la web, con cabeceras de navegador
# -----------------------------------------------------------------------------
# F2.4 recibio 403 con un cuerpo de 5483 bytes en 3 de 3 rutas de camara.cl,
# incluida la ruta FABRICADA del control negativo. Un 403 identico para lo real
# y lo inventado no es evidencia de ausencia: es un WAF que rechaza al cliente,
# no a la ruta. Antes de concluir nada sobre la web hay que descartar esa causa.
#
# CONTROL DECLARADO ANTES: si con cabeceras de navegador la ruta REAL responde
# 200 y la FABRICADA sigue fallando, el sondeo discrimina y sus resultados valen.
# Si ambas responden 200 con el mismo cuerpo, no discrimina y se anula la fase.
# =============================================================================

RAIZ <- "/Users/tomgc/Projects/transparencia_legislativa_chile"
setwd(RAIZ)
source("10_utils/10_locale.R"); asegurar_locale_utf8("50_sondeo_p92_f2c.R")
source("50_documentacion/andamios/50_sondeo_p92_http.R")
suppressPackageStartupMessages({ library(httr); library(xml2) })
MU <- "50_documentacion/andamios/muestras/p92"
sep <- function(t) cat("\n", strrep("=", 74), "\n", t, "\n", strrep("=", 74), "\n", sep = "")

NAV <- list(
  `User-Agent` = paste("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
                       "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"),
  Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
  `Accept-Language` = "es-CL,es;q=0.9",
  # SIN Accept-Encoding propio: declarar 'br' hace que el servidor responda
  # brotli y libcurl aborte con "Unrecognized content encoding" ANTES de
  # entregar cuerpo. httr negocia gzip/deflate solo y descomprime.
  `Upgrade-Insecure-Requests` = "1")

sep("F2c.1  el 403 de camara.cl es del WAF o de la ruta?")
objetivos <- list(
  c("https://www.camara.cl/legislacion/sala_sesiones/votaciones.aspx", "REAL votaciones.aspx", "votaciones_aspx"),
  c("https://www.camara.cl/legislacion/catalogo_sufijos_boletin_inventado.aspx", "FABRICADA (control)", "cn_fabricada_nav"),
  c("https://www.camara.cl/camara/comisiones.aspx", "REAL comisiones.aspx", "comisiones_aspx")
)
out <- list()
for (o in objetivos) {
  r <- p92_http(o[1], paste("nav:", o[2]), headers = NAV,
                guardar = file.path(MU, paste0("nav_", o[3], ".html")))
  out[[o[2]]] <- r
  if (!is.na(r$status) && !is.na(r$texto)) {
    tit <- regmatches(r$texto, regexpr("<title>[^<]*</title>", r$texto, ignore.case = TRUE))
    cat(sprintf("        -> %s | %s\n", ifelse(length(tit), substr(tit, 1, 90), "(sin <title>)"),
                substr(gsub("\\s+", " ", substr(r$texto, 1, 0)), 1, 1)))
  }
}
cat("\n  Veredicto del control:\n")
r_real <- out[["REAL votaciones.aspx"]]; r_fab <- out[["FABRICADA (control)"]]
cat(sprintf("    REAL      : status=%s bytes=%s md5=%s\n", r_real$status, r_real$bytes, substr(r_real$md5, 1, 8)))
cat(sprintf("    FABRICADA : status=%s bytes=%s md5=%s\n", r_fab$status, r_fab$bytes, substr(r_fab$md5, 1, 8)))
cat(sprintf("    -> %s\n", ifelse(!identical(r_real$md5, r_fab$md5),
        "DISCRIMINA: cuerpos distintos entre ruta real y fabricada",
        "NO DISCRIMINA: mismo cuerpo; la fase se anula")))

sep("F2c.2  BCN y SIL: paginas candidatas a documentar la numeracion del boletin")
webs <- list(
  c("https://www.bcn.cl/formacioncivica/detalle_guia?h=10221.3/45685", "bcn formacion civica tramitacion", "bcn_fc"),
  c("https://www.senado.cl/appsenado/index.php?mo=tramitacion&ac=avanzada", "sil busqueda avanzada", "sil_avanzada"),
  c("https://www.bcn.cl/leychile", "bcn leychile portada", "bcn_leychile"),
  c("https://tramitacion.senado.cl/appsenado/index.php?mo=tramitacion&ac=avanzada", "tramitacion.senado avanzada", "tram_senado")
)
for (w in webs) {
  r <- p92_http(w[1], w[2], headers = NAV, guardar = file.path(MU, paste0("web2_", w[3], ".html")))
  if (!is.na(r$status) && r$status == 200 && !is.na(r$texto)) {
    txt <- r$texto
    cat(sprintf("        -> %d caracteres.\n", nchar(txt)))
    for (pat in c("bolet", "comisi")) {
      h <- unlist(regmatches(txt, gregexpr(paste0("[^<>]{0,70}", pat, "[^<>]{0,70}"), txt, ignore.case = TRUE)))
      cat(sprintf("           '%s': %d fragmentos", pat, length(h)))
      if (length(h)) cat(" | ej: ", substr(trimws(h[1]), 1, 90))
      cat("\n")
    }
    # un select con opciones de comision seria el catalogo
    sel <- unlist(regmatches(txt, gregexpr("<select[^>]*>.*?</select>", txt, perl = TRUE, ignore.case = TRUE)))
    cat(sprintf("           <select> encontrados: %d\n", length(sel)))
    if (length(sel)) for (s in utils::head(sel, 3)) {
      nm <- regmatches(s, regexpr("(?<=name=\")[^\"]+", s, perl = TRUE))
      op <- unlist(regmatches(s, gregexpr("<option[^>]*>[^<]*</option>", s, ignore.case = TRUE)))
      cat(sprintf("             select name=%s con %d <option>. Primeras 4: %s\n",
                  ifelse(length(nm), nm, "?"), length(op),
                  paste(substr(gsub("<[^>]*>", "", utils::head(op, 4)), 1, 30), collapse = " / ")))
    }
  }
}
p92_reporte_presupuesto()
