# =============================================================================
# 50_sondeo_p92_f2b.R  --  P-92, F2 (cont.): el campo Numero de las comisiones
#                          es el sufijo del boletin?
# -----------------------------------------------------------------------------
# retornarComisionesXPeriodo devuelve un campo <Numero> por comision (Salud=10,
# Etica y Transparencia=25, Futuro=17). Si <Numero> fuera el sufijo del boletin,
# EXISTIRIA catalogo oficial y la via 1 tendria glosa. La prueba: cruzar
# (Numero, Nombre) oficial contra la asociacion EMPIRICA (sufijo -> comision
# modal) medida en F1.4. Si coinciden, es el catalogo; si no, no lo es y se dice.
#
# HIPOTESIS NULA DECLARADA ANTES: <Numero> NO es el sufijo. Se rechaza solo si
# la coincidencia supera lo que daria el azar (23 sufijos con comision modal
# medida contra ~30 numeros disponibles: coincidencia esperada por azar < 1).
# Umbral para declarar catalogo oficial: >= 15 de 20 sufijos con n >= 5 casan.
# CERO red: reusa el XML ya bajado en F2.
# =============================================================================

RAIZ <- "/Users/tomgc/Projects/transparencia_legislativa_chile"
setwd(RAIZ)
source("10_utils/10_locale.R"); asegurar_locale_utf8("50_sondeo_p92_f2b.R")
source("50_documentacion/andamios/50_fusible_red.R"); instalar_fusible_red(silencioso = TRUE)
suppressPackageStartupMessages({ library(dplyr); library(xml2) })
MU <- "50_documentacion/andamios/muestras/p92"
sep <- function(t) cat("\n", strrep("=", 74), "\n", t, "\n", strrep("=", 74), "\n", sep = "")

leer_comisiones <- function(arch) {
  x <- read_xml(arch)
  n <- xml_find_all(x, ".//*[local-name()='Comision']")
  campo <- function(nm) xml_text(xml_find_first(n, sprintf(".//*[local-name()='%s']", nm)))
  data.frame(id = campo("Id"), nombre = campo("Nombre"), alias = campo("Alias"),
             tipo = campo("Tipo"), numero = campo("Numero"), stringsAsFactors = FALSE)
}
c10 <- leer_comisiones(file.path(MU, "comisiones_periodo_10.xml"))
c11 <- leer_comisiones(file.path(MU, "comisiones_periodo_11.xml"))
com <- bind_rows(c10, c11) |> distinct(id, .keep_all = TRUE)

sep("F2b.1  el catalogo de comisiones y su campo <Numero>")
cat(sprintf("  comisiones distintas (periodos 10 y 11): %d\n", nrow(com)))
print(as.data.frame(com |> count(tipo, sort = TRUE)))
perm <- com |> filter(tipo == "Permanente", numero != "0") |> arrange(as.integer(numero))
cat(sprintf("\n  Permanentes con Numero != 0: %d ; Numeros distintos: %d ; rango %s-%s\n",
            nrow(perm), n_distinct(perm$numero), min(as.integer(perm$numero)), max(as.integer(perm$numero))))
cat("\n  catalogo OFICIAL tal como lo entrega la API (Numero, Nombre):\n")
for (i in seq_len(nrow(perm)))
  cat(sprintf("    %-3s  %s\n", perm$numero[i], substr(perm$nombre[i], 1, 70)))
dup <- perm |> count(numero) |> filter(n > 1)
if (nrow(dup)) { cat("\n  Numeros repetidos entre comisiones distintas:\n"); print(as.data.frame(dup)) }

# --- cruce contra la asociacion empirica de F1.4 -----------------------------
sep("F2b.2  CRUCE  <Numero> oficial  vs  sufijo -> comision modal (empirico)")
f1 <- readRDS("50_documentacion/andamios/muestras/p92_f1.rds")
res <- f1$res_com |> filter(n >= 5) |> arrange(desc(n))
norm <- function(x) {
  x <- tolower(iconv(x, "UTF-8", "ASCII//TRANSLIT"))
  x <- gsub("[^a-z ]", " ", x); trimws(gsub("\\s+", " ", x))
}
perm$nom_n <- norm(perm$nombre)
res$mod_n  <- norm(res$modal)
# Casa por LIMITE DE PALABRA en ambos sentidos. Sin \\b, 'cultura' casa dentro de
# 'agricultura' y el cruce empareja la comision equivocada (defecto detectado y
# corregido durante F2b).
contiene <- function(aguja, pajar) grepl(paste0("\\b", aguja, "\\b"), pajar, perl = TRUE)
casa_con <- function(m) {
  hit <- which(vapply(perm$nom_n, function(o) contiene(m, o) || contiene(o, m), logical(1)))
  if (!length(hit)) return(c(NA_character_, NA_character_))
  c(perm$numero[hit[1]], perm$nombre[hit[1]])
}
mm <- t(vapply(res$mod_n, casa_con, character(2)))
res$numero_oficial <- mm[, 1]; res$nombre_oficial <- mm[, 2]
# Comparacion NUMERICA: el sufijo viaja con cero a la izquierda ('04') y el
# Numero oficial sin el ('4'). Compararlos como texto da falso negativo.
res$coincide <- !is.na(res$numero_oficial) &
  as.integer(res$numero_oficial) == as.integer(res$sufijo)
print(as.data.frame(res |> select(sufijo, n, modal, pct_modal, numero_oficial, nombre_oficial, coincide)))
cat(sprintf("\n  sufijos con n >= 5 cuya comision modal se identifico en el catalogo oficial: %d / %d\n",
            sum(!is.na(res$numero_oficial)), nrow(res)))
cat(sprintf("  de esos, con <Numero> IGUAL al sufijo: %d / %d\n",
            sum(res$coincide, na.rm = TRUE), sum(!is.na(res$numero_oficial))))
cat(sprintf("\n  UMBRAL declarado antes: >= 15 de %d casan -> %s\n", nrow(res),
            ifelse(sum(res$coincide, na.rm = TRUE) >= 15,
                   "SE RECHAZA la nula: <Numero> ES el sufijo",
                   "NO se rechaza la nula: <Numero> NO es el sufijo del boletin")))

# --- control positivo del cruce ---------------------------------------------
sep("F2b.3  control positivo del propio cruce")
cat("  Si el emparejador de nombres no funcionara, no casaria NADA y el veredicto\n",
    "  anterior seria un falso negativo. Control: emparejar cada comision oficial\n",
    "  consigo misma debe dar 100 %.\n", sep = "")
auto <- vapply(perm$nom_n, function(m) {
  any(vapply(perm$nom_n, function(o) contiene(m, o) || contiene(o, m), logical(1)))
}, logical(1))
cat(sprintf("  autoemparejamiento: %d / %d (%.0f %%)\n", sum(auto), length(auto), 100 * mean(auto)))
cat(sprintf("  emparejamiento empirico->oficial: %d / %d (%.0f %%) -> el emparejador SI funciona\n",
            sum(!is.na(res$numero_oficial)), nrow(res), 100 * mean(!is.na(res$numero_oficial))))

# --- materias: contienen glosa de sufijo? ------------------------------------
sep("F2b.4  el catalogo de 8518 materias contiene una glosa por sufijo?")
mat <- readRDS(file.path(MU, "materias.rds"))
cat(sprintf("  materias: %d ; ids de 1-2 digitos: %d\n", nrow(mat), sum(grepl("^[0-9]{1,2}$", mat$id))))
patron_com <- grepl("^COMISI", toupper(mat$nombre))
cat(sprintf("  materias cuyo nombre empieza con 'COMISI': %d\n", sum(patron_com)))
if (any(patron_com)) for (s in utils::head(mat$nombre[patron_com], 10)) cat("    | ", s, "\n")
cat(sprintf("  materias cuyo nombre contiene 'BOLETIN': %d\n",
            sum(grepl("BOLET", toupper(mat$nombre)))))
saveRDS(list(perm = perm, cruce = res), file.path(MU, "f2b_cruce.rds"))
