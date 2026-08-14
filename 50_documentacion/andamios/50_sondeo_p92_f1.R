# =============================================================================
# 50_sondeo_p92_f1.R  --  P-92, F1: via 1, el sufijo del boletin
# -----------------------------------------------------------------------------
# 1. Cobertura estructural, distribucion, categorias, tamano de la mayor.
# 2. Control positivo sobre los 5 boletines con materia oficial (umbral 4/5).
# 3. Control de discriminacion: vocabulario del titulo dentro vs entre sufijos,
#    con test de permutacion (estadistico declarado antes de correrlo).
# 4. Estabilidad semantica: comision empirica del sufijo vs comision que tramita.
#
# D42: NO se inventa glosa para ningun sufijo. La asociacion sufijo -> comision
# que se reporta aqui es EMPIRICA (derivada de la tramitacion), y se rotula como
# tal en todas partes. La glosa oficial la sondea F2.
# CERO red.
# =============================================================================

RAIZ <- "/Users/tomgc/Projects/transparencia_legislativa_chile"
setwd(RAIZ)
source("10_utils/10_locale.R"); asegurar_locale_utf8("50_sondeo_p92_f1.R")
source("50_documentacion/andamios/50_fusible_red.R"); instalar_fusible_red(silencioso = TRUE)
suppressPackageStartupMessages(library(dplyr))
set.seed(92)

sep <- function(t) cat("\n", strrep("=", 74), "\n", t, "\n", strrep("=", 74), "\n", sep = "")
frac <- function(n, d, etq) cat(sprintf("  %-52s %6d / %-6d  (%6.2f %%)\n", etq, n, d, 100 * n / d))

pd <- readRDS("40_salidas/intermedios/proyectos_detalle.rds")
tr <- readRDS("40_salidas/intermedios/tramitacion.rds")
N  <- nrow(pd)

# --- F1.1 cobertura estructural ---------------------------------------------
sep("F1.1  cobertura estructural del sufijo")
pd$sufijo <- sub("^[0-9]+-", "", pd$boletin)
frac(sum(grepl("^[0-9]{1,2}$", pd$sufijo)), N, "boletines con sufijo numerico extraible")
tabla <- pd |> count(sufijo, sort = TRUE) |> mutate(pct = round(100 * n / N, 2))
cat(sprintf("\n  categorias distintas de sufijo: %d\n", nrow(tabla)))
cat(sprintf("  categoria mas grande: '%s' con %d de %d (%.2f %%)\n",
            tabla$sufijo[1], tabla$n[1], N, 100 * tabla$n[1] / N))
cat(sprintf("  categorias con n >= 5: %d ; con n == 1: %d\n",
            sum(tabla$n >= 5), sum(tabla$n == 1)))
cat("\n  distribucion completa (sin glosa: no existe catalogo verificado; ver F2):\n")
print(as.data.frame(tabla))
# indice de concentracion
p <- tabla$n / N
cat(sprintf("\n  Herfindahl (suma p^2) = %.4f   entropia de Shannon = %.3f bits (max %.3f)\n",
            sum(p^2), -sum(p * log2(p)), log2(nrow(tabla))))

# --- F1.2 control positivo ---------------------------------------------------
sep("F1.2  CONTROL POSITIVO  (umbral declarado ANTES: coherente en >= 4 de 5)")
n_mat <- vapply(pd$materias, function(m) if (is.data.frame(m)) nrow(m) else 0L, integer(1))
oro <- pd[n_mat > 0, ]
cat(sprintf("  patron de oro: %d boletines con materia oficial (de %d)\n", nrow(oro), N))
for (i in seq_len(nrow(oro))) {
  cat(sprintf("\n  --- %s  (sufijo %s) ---\n", oro$boletin[i], oro$sufijo[i]))
  cat("    titulo   : ", substr(oro$nombre[i], 1, 190), "\n", sep = "")
  m <- oro$materias[[i]]
  cat("    materias oficiales: ", paste(sprintf("%s (id %s)", m$nombre, m$id), collapse = " ; "), "\n", sep = "")
  # que otros boletines comparten ese sufijo (para juzgar coherencia SIN glosa)
  hermanos <- pd$nombre[pd$sufijo == oro$sufijo[i] & pd$boletin != oro$boletin[i]]
  cat(sprintf("    otros boletines con sufijo %s: %d. Tres titulos:\n", oro$sufijo[i], length(hermanos)))
  for (h in utils::head(hermanos, 3)) cat("      * ", substr(h, 1, 150), "\n", sep = "")
}

# --- F1.3 control de discriminacion -----------------------------------------
sep("F1.3  CONTROL DE DISCRIMINACION  (estadistico declarado antes de correrlo)")
cat("  ESTADISTICO: Jaccard medio de los conjuntos de tokens del titulo entre\n",
    "  pares del MISMO sufijo menos el de pares de sufijo DISTINTO (delta).\n",
    "  Por que Jaccard y no coseno tf-idf: los titulos son cortos (mediana ~15\n",
    "  tokens utiles) y el conteo de repeticiones no aporta; Jaccard depende solo\n",
    "  de presencia, que es lo que un token de tema aporta. Nulo por permutacion\n",
    "  de las etiquetas de sufijo (999 permutaciones, semilla 92): si el sufijo no\n",
    "  informa del vocabulario, delta cae dentro del nulo.\n", sep = "")
STOP_ES <- c("a","al","ante","como","con","contra","cual","cuales","de","del","desde","donde",
             "e","el","ella","ellas","ellos","en","entre","era","es","esa","ese","eso","esta",
             "estas","este","estos","fue","ha","han","hasta","la","las","le","les","lo","los",
             "mas","me","mi","muy","ni","no","nos","o","otra","otro","para","pero","por","porque",
             "que","se","segun","ser","si","sin","sobre","son","su","sus","tambien","te","tiene",
             "todo","todos","tras","tu","un","una","uno","unos","y","ya",
             # ruido legal comun a todo titulo, no informativo de tema
             "n","ley","leyes","numero","proyecto","codigo","decreto","dfl","dl","supremo",
             "articulo","articulos","inciso","texto","refundido","materia","materias")
norm <- function(x) {
  x <- tolower(x)
  x <- iconv(x, "UTF-8", "ASCII//TRANSLIT")
  x <- gsub("[^a-z0-9 ]", " ", x)
  x <- gsub("\\s+", " ", trimws(x))
  x
}
tok <- lapply(strsplit(norm(pd$nombre), " "), function(v) unique(v[nchar(v) > 2 & !(v %in% STOP_ES)]))
cat(sprintf("\n  tokens utiles por titulo: mediana %.0f, min %d, max %d\n",
            median(lengths(tok)), min(lengths(tok)), max(lengths(tok))))
# matriz binaria termino x documento
vocab <- sort(unique(unlist(tok)))
M <- matrix(0L, nrow = N, ncol = length(vocab), dimnames = list(pd$boletin, vocab))
for (i in seq_len(N)) M[i, tok[[i]]] <- 1L
INT <- M %*% t(M)                       # interseccion
SZ  <- rowSums(M)
UNI <- outer(SZ, SZ, "+") - INT          # union
J   <- ifelse(UNI > 0, INT / UNI, 0)
diag(J) <- NA
mismo <- outer(pd$sufijo, pd$sufijo, "==")
diag(mismo) <- NA
estad <- function(lab) {
  m <- outer(lab, lab, "=="); diag(m) <- NA
  mean(J[m %in% TRUE], na.rm = TRUE) - mean(J[m %in% FALSE], na.rm = TRUE)
}
obs <- estad(pd$sufijo)
nulo <- replicate(999, estad(sample(pd$sufijo)))
cat(sprintf("\n  Jaccard medio MISMO sufijo    : %.5f  (%d pares)\n",
            mean(J[mismo %in% TRUE], na.rm = TRUE), sum(mismo %in% TRUE) / 2))
cat(sprintf("  Jaccard medio DISTINTO sufijo : %.5f  (%d pares)\n",
            mean(J[mismo %in% FALSE], na.rm = TRUE), sum(mismo %in% FALSE) / 2))
cat(sprintf("  delta observado = %.5f\n", obs))
cat(sprintf("  nulo por permutacion: media %.5f, sd %.5f, max %.5f\n", mean(nulo), sd(nulo), max(nulo)))
cat(sprintf("  p (una cola, (1+#{nulo >= obs})/1000) = %.4f   z = %.2f\n",
            (1 + sum(nulo >= obs)) / 1000, (obs - mean(nulo)) / sd(nulo)))

# --- F1.4 estabilidad semantica ---------------------------------------------
sep("F1.4  ESTABILIDAD SEMANTICA  sufijo vs comision que tramita")
cat("  Se extrae de tramitacion.rds$tramites toda mencion 'Comision de X' /\n",
    "  'Comision X'. NO se compara contra una glosa oficial (no existe verificada;\n",
    "  ver F2): se mide (a) cuantas comisiones DISTINTAS ve un mismo sufijo, y\n",
    "  (b) si la comision MODAL de un sufijo cubre a sus boletines. Un sufijo\n",
    "  estable manda casi todos sus boletines a una sola comision.\n", sep = "")
extraer_com <- function(df) {
  if (!is.data.frame(df) || !nrow(df)) return(character(0))
  # una descripcion a la vez: pegarlas con un separador hace que el regex lo
  # cruce y capture texto de dos tramites como si fuera un nombre de comision.
  m <- unlist(regmatches(df$descripcion,
        gregexpr("Comisi[oó]n(es)? de [^.,;:()|]+", df$descripcion, perl = TRUE)))
  m <- trimws(gsub("\\s+", " ", m))
  m <- sub("^Comisiones de ", "Comision de ", m)
  m <- sub("^Comisi[oó]n de ", "", m)
  m <- sub("( y a la| y| a la| de la Camara| del Senado)$", "", m)
  m <- trimws(m)
  m[nchar(m) > 2 & nchar(m) < 80]
}
coms <- lapply(tr$tramites, extraer_com)
tr$com_primera <- vapply(coms, function(v) if (length(v)) v[1] else NA_character_, character(1))
tr$n_com       <- vapply(coms, function(v) length(unique(v)), integer(1))
tr$sufijo      <- sub("^[0-9]+-", "", tr$boletin)
frac(sum(!is.na(tr$com_primera)), nrow(tr), "boletines con al menos una comision nombrada")
cat(sprintf("  comisiones distintas nombradas en todo el corpus: %d\n",
            length(unique(unlist(coms)))))
res <- tr |> filter(!is.na(com_primera)) |>
  summarise(n = n(), n_com_dist = n_distinct(com_primera),
            modal = names(sort(table(com_primera), decreasing = TRUE))[1],
            n_modal = max(table(com_primera)), .by = sufijo) |>
  mutate(pct_modal = round(100 * n_modal / n, 1)) |> arrange(desc(n))
cat("\n  por sufijo (comision PRIMERA de la tramitacion, asociacion EMPIRICA,\n  no glosa oficial):\n")
print(as.data.frame(res))
con <- res |> filter(n >= 5)
cat(sprintf("\n  sufijos con n >= 5: %d ; cobertura media de su comision modal: %.1f %%\n",
            nrow(con), mean(con$pct_modal)))
cat(sprintf("  boletines cuya comision primera NO es la modal de su sufijo: "))
tr2 <- tr |> filter(!is.na(com_primera)) |> left_join(res |> select(sufijo, modal), by = "sufijo")
cat(sprintf("%d / %d  (%.2f %%)\n", sum(tr2$com_primera != tr2$modal), nrow(tr2),
            100 * mean(tr2$com_primera != tr2$modal)))
cat(sprintf("  boletines que pasan por MAS de una comision distinta: %d / %d (%.2f %%)\n",
            sum(tr$n_com > 1), nrow(tr), 100 * mean(tr$n_com > 1)))
cat("\n  ejemplos de boletines con comision primera != modal de su sufijo:\n")
ej <- tr2 |> filter(com_primera != modal) |> utils::head(10)
for (i in seq_len(nrow(ej)))
  cat(sprintf("    %s (suf %s): primera='%s' | modal del sufijo='%s'\n",
              ej$boletin[i], ej$sufijo[i], ej$com_primera[i], ej$modal[i]))

saveRDS(list(tabla = tabla, res_com = res, obs = obs, nulo = nulo),
        "50_documentacion/andamios/muestras/p92_f1.rds")
cat("\nF1 terminada sin red.\n")
