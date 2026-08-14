# =============================================================================
# 50_sondeo_p92_f3.R  --  P-92, F3: via 2, el buscador "por Materia" de camara.cl
# -----------------------------------------------------------------------------
# F2c dejo un resultado que hay que corregir antes de seguir: los cuerpos de la
# ruta REAL y de la FABRICADA tenian md5 distinto, y el script lo declaro
# "DISCRIMINA". Es FALSO: ambos son la misma pagina de Cloudflare y el md5
# difiere solo por el Ray ID que Cloudflare incrusta en cada respuesta. Esta
# fase lo comprueba borrando el Ray ID antes de comparar.
#
# Si camara.cl responde 403 a la ruta real y a la fabricada por igual, H7 NO se
# puede responder desde R: no es que el buscador no exista, es que el cliente
# esta bloqueado. Eso se reporta como bloqueo, no como ausencia.
# =============================================================================

RAIZ <- "/Users/tomgc/Projects/transparencia_legislativa_chile"
setwd(RAIZ)
source("10_utils/10_locale.R"); asegurar_locale_utf8("50_sondeo_p92_f3.R")
source("50_documentacion/andamios/50_sondeo_p92_http.R")
suppressPackageStartupMessages({ library(httr) })
MU <- "50_documentacion/andamios/muestras/p92"
sep <- function(t) cat("\n", strrep("=", 74), "\n", t, "\n", strrep("=", 74), "\n", sep = "")

# --- F3.1 correccion del veredicto de F2c -----------------------------------
sep("F3.1  CORRECCION: los dos 403 son la misma pagina (Ray ID aparte)")
a <- readLines(file.path(MU, "nav_votaciones_aspx.html"), warn = FALSE)
b <- readLines(file.path(MU, "nav_cn_fabricada_nav.html"), warn = FALSE)
limpiar <- function(v) {
  v <- paste(v, collapse = "\n")
  v <- gsub("[0-9a-f]{16}", "<RAYID>", v)          # Ray ID de Cloudflare
  v <- gsub("Ray ID:[^<]*", "Ray ID: <RAYID>", v)
  v <- gsub("[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}", "<IP>", v)
  v
}
la <- limpiar(a); lb <- limpiar(b)
cat(sprintf("  bytes crudos: real=%d fabricada=%d\n", sum(nchar(a)), sum(nchar(b))))
cat(sprintf("  tras normalizar Ray ID e IP -> identicos: %s\n", identical(la, lb)))
cat(sprintf("  VEREDICTO: %s\n", ifelse(identical(la, lb),
  "el control NO discrimina. camara.cl bloquea al cliente, no a la ruta.",
  "los cuerpos difieren en algo mas que el Ray ID; revisar a mano.")))
cat("  Titulo servido: ",
    regmatches(la, regexpr("<title>[^<]*</title>", la, ignore.case = TRUE)), "\n")

# --- F3.2 intentos adicionales, declarados -----------------------------------
sep("F3.2  intentos adicionales de alcanzar votaciones.aspx desde R")
cat("  Declarado antes: 4 intentos como maximo. Si los 4 devuelven el desafio de\n",
    "  Cloudflare, H7 queda SIN RESPONDER desde R y se reporta como bloqueo.\n", sep = "")
NAV <- list(
  `User-Agent` = paste("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
                       "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"),
  Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
  `Accept-Language` = "es-CL,es;q=0.9,en;q=0.8",
  `Sec-Fetch-Dest` = "document", `Sec-Fetch-Mode` = "navigate",
  `Sec-Fetch-Site` = "none", `Sec-Fetch-User` = "?1",
  `Upgrade-Insecure-Requests` = "1", `Cache-Control` = "max-age=0")
URL_VOT <- "https://www.camara.cl/legislacion/sala_sesiones/votaciones.aspx"

intentos <- list(
  list(u = "https://www.camara.cl/", e = "portada camara.cl (para cookie)", h = NAV),
  list(u = URL_VOT, e = "votaciones.aspx con cookie de portada", h = c(NAV, list(Referer = "https://www.camara.cl/"))),
  list(u = "http://www.camara.cl/legislacion/sala_sesiones/votaciones.aspx", e = "votaciones.aspx por http", h = NAV),
  list(u = "https://www.camara.cl/legislacion/sala_sesiones/votacion_detalle.aspx?prmIdVotacion=89693",
       e = "votacion_detalle.aspx (R7)", h = NAV)
)
estados <- integer(0)
for (i in seq_along(intentos)) {
  it <- intentos[[i]]
  r <- p92_http(it$u, paste0("F3 intento ", i, ": ", it$e), headers = it$h,
                guardar = file.path(MU, sprintf("f3_intento_%d.html", i)))
  estados <- c(estados, ifelse(is.na(r$status), -1L, r$status))
  if (!is.na(r$status) && !is.na(r$texto)) {
    tit <- regmatches(r$texto, regexpr("<title>[^<]*</title>", r$texto, ignore.case = TRUE))
    cat(sprintf("        -> %s\n", ifelse(length(tit), tit, "(sin title)")))
    if (r$status == 200) {
      vs <- grepl("__VIEWSTATE", r$texto, fixed = TRUE)
      ev <- grepl("__EVENTVALIDATION", r$texto, fixed = TRUE)
      pm <- grepl("link_PorMateria", r$texto, fixed = TRUE)
      cat(sprintf("           __VIEWSTATE=%s __EVENTVALIDATION=%s link_PorMateria=%s\n", vs, ev, pm))
    }
  }
}
cat(sprintf("\n  estados de los %d intentos: %s\n", length(estados), paste(estados, collapse = ", ")))
cat(sprintf("  VEREDICTO F3: %s\n", ifelse(all(estados == 403),
  "H7 SIN RESPONDER desde R. camara.cl responde 403 (Cloudflare) en 4 de 4, y el control fabricado recibe la MISMA pagina. No es evidencia de que el buscador no exista: es un bloqueo de cliente.",
  "alguna via respondio: revisar arriba y ejecutar el postback.")))
p92_reporte_presupuesto()
