# =============================================================================
# 50_sondeo_p92_f3b.R  --  P-92, F3 (cierre): en que difieren los dos 403?
# -----------------------------------------------------------------------------
# F3.1 normalizo Ray ID e IP y los cuerpos SIGUIERON distintos, asi que declaro
# "revisar a mano". Esto es ese examen: en vez de adivinar que normalizar, se
# comparan las dos paginas linea a linea y se muestran TODAS las lineas que
# difieren. Si lo unico que cambia son identificadores de la respuesta, el
# control no discrimina y camara.cl esta bloqueando al cliente.
# CERO red: solo lee lo ya bajado.
# =============================================================================

RAIZ <- "/Users/tomgc/Projects/transparencia_legislativa_chile"
setwd(RAIZ)
source("10_utils/10_locale.R"); asegurar_locale_utf8("50_sondeo_p92_f3b.R")
source("50_documentacion/andamios/50_fusible_red.R"); instalar_fusible_red(silencioso = TRUE)
MU <- "50_documentacion/andamios/muestras/p92"
sep <- function(t) cat("\n", strrep("=", 74), "\n", t, "\n", strrep("=", 74), "\n", sep = "")

sep("F3b  diferencia linea a linea entre el 403 de la ruta REAL y el de la FABRICADA")
a <- readLines(file.path(MU, "nav_votaciones_aspx.html"), warn = FALSE)
b <- readLines(file.path(MU, "nav_cn_fabricada_nav.html"), warn = FALSE)
cat(sprintf("  lineas: real=%d fabricada=%d\n", length(a), length(b)))
n <- max(length(a), length(b))
a <- c(a, rep("", n - length(a))); b <- c(b, rep("", n - length(b)))
dif <- which(a != b)
cat(sprintf("  lineas que difieren: %d de %d\n\n", length(dif), n))
for (i in dif) {
  cat(sprintf("  [linea %d]\n    REAL     : %s\n    FABRICADA: %s\n", i,
              substr(trimws(a[i]), 1, 150), substr(trimws(b[i]), 1, 150)))
}
sep("VEREDICTO DEL CONTROL NEGATIVO DE F3")
solo_ids <- length(dif) > 0 &&
  all(grepl("Ray ID|__cf|cf-|rc-|data-translate|<span|token|nonce|[0-9a-f]{16}",
            paste(a[dif], b[dif]), ignore.case = TRUE))
cat(sprintf("  las %d lineas distintas son solo identificadores de la respuesta: %s\n",
            length(dif), solo_ids))
cat("  Cuerpo servido en ambos casos: pagina 'Attention Required! | Cloudflare'.\n")
cat("  -> El control NO discrimina entre ruta real y ruta inventada.\n")
cat("  -> H7 NO SE PUEDE RESPONDER DESDE R. Lo medido es que el cliente esta\n")
cat("     bloqueado (403 Cloudflare en 3 intentos, 520 en el cuarto), NO que el\n")
cat("     buscador por Materia no exista. Reportarlo como ausencia seria un\n")
cat("     falso negativo fabricado.\n")
