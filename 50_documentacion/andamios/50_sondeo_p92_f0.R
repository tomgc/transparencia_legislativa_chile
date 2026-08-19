# =============================================================================
# 50_sondeo_p92_f0.R  --  P-92, F0: arranque y universo real
# -----------------------------------------------------------------------------
# Proposito: verificar H1, H2, H4 y H5 del encargo con recuento propio y
#            denominador declarado, sobre los intermedios sellados. CERO red:
#            el fusible se arma antes de leer nada.
#
# Uso: Rscript 50_documentacion/andamios/50_sondeo_p92_f0.R
# =============================================================================

RAIZ <- "/Users/tomgc/Projects/transparencia_legislativa_chile"
setwd(RAIZ)

source("50_documentacion/andamios/50_fusible_red.R")
instalar_fusible_red(silencioso = TRUE)

suppressPackageStartupMessages(library(dplyr))

sep <- function(t) cat("\n", strrep("=", 74), "\n", t, "\n", strrep("=", 74), "\n", sep = "")
frac <- function(n, d, etq) cat(sprintf("  %-52s %6d / %-6d  (%6.2f %%)\n", etq, n, d, 100 * n / d))

RES <- new.env()  # acumulador de cifras para las fases siguientes

# --- Sellos ------------------------------------------------------------------
sep("F0.1  SELLOS DE PROCEDENCIA DE LOS INTERMEDIOS")
archivos <- c("diputados.rds", "proyectos.rds", "proyectos_detalle.rds",
              "tramitacion.rds", "votos.rds")
for (a in archivos) {
  o <- readRDS(file.path("40_salidas/intermedios", a))
  s <- attr(o, "sello")
  cat(sprintf("  %-24s filas=%6d cols=%3d  corte=%s  anio=%s  escrito=%s\n",
              a, nrow(o), ncol(o),
              if (is.null(s)) "SIN SELLO" else s$corte_fecha,
              if (is.null(s)) "-" else s$anio_proceso,
              if (is.null(s)) "-" else s$escrito_en))
}

pd <- readRDS("40_salidas/intermedios/proyectos_detalle.rds")
pr <- readRDS("40_salidas/intermedios/proyectos.rds")
vo <- readRDS("40_salidas/intermedios/votos.rds")
di <- readRDS("40_salidas/intermedios/diputados.rds")
tr <- readRDS("40_salidas/intermedios/tramitacion.rds")

# --- H1 ----------------------------------------------------------------------
sep("F0.2  H1  universo de boletines y de votaciones")
n_bol <- n_distinct(pd$boletin)
n_vot <- n_distinct(vo$votacion_id)
cat(sprintf("  boletines distintos en proyectos_detalle.rds : %d  (filas %d)\n", n_bol, nrow(pd)))
cat(sprintf("  votaciones distintas en votos.rds            : %d  (filas de voto %d)\n", n_vot, nrow(vo)))
cat(sprintf("  H1 declara 427 boletines y 842 votaciones -> boletines %s / votaciones %s\n",
            ifelse(n_bol == 427, "CUMPLE", paste0("DIFIERE (", n_bol, ")")),
            ifelse(n_vot == 842, "CUMPLE", paste0("DIFIERE (", n_vot, ")"))))
RES$n_bol <- n_bol; RES$n_vot <- n_vot

# tipos de votacion (R4)
sep("F0.3  tipos de votacion (una fila por votacion)")
v_uni <- vo |> distinct(votacion_id, .keep_all = TRUE)
print(as.data.frame(v_uni |> count(tipo, sort = TRUE) |>
                      mutate(pct = round(100 * n / n_vot, 2))))
cat(sprintf("\n  votaciones CON boletin no vacio : %d / %d\n",
            sum(!is.na(v_uni$boletin) & nzchar(trimws(v_uni$boletin))), n_vot))
cat(sprintf("  votaciones SIN boletin          : %d / %d\n",
            sum(is.na(v_uni$boletin) | !nzchar(trimws(v_uni$boletin))), n_vot))

# --- H2 ----------------------------------------------------------------------
sep("F0.4  H2  forma NNNNN-NN del boletin y sufijo extraible")
patron <- "^[0-9]{4,6}-[0-9]{1,2}$"
ok <- grepl(patron, pd$boletin)
frac(sum(ok), n_bol, "boletines que matchean ^[0-9]{4,6}-[0-9]{1,2}$")
if (any(!ok)) {
  cat("  NO matchean (listados uno por uno):\n")
  for (b in pd$boletin[!ok]) cat("    ", b, "\n")
} else cat("  NO matchean: 0 casos.\n")
# forma estricta NNNNN-NN
ok5 <- grepl("^[0-9]{5}-[0-9]{2}$", pd$boletin)
frac(sum(ok5), n_bol, "forma estricta NNNNN-NN (5 digitos - 2 digitos)")
if (any(!ok5)) { cat("  fuera de la forma estricta:\n"); for (b in pd$boletin[!ok5]) cat("    ", b, "\n") }

# boletines que aparecen en votos
bol_vo <- unique(trimws(v_uni$boletin[!is.na(v_uni$boletin) & nzchar(trimws(v_uni$boletin))]))
cat(sprintf("\n  boletines distintos citados en votaciones : %d\n", length(bol_vo)))
ok_v <- grepl(patron, bol_vo)
frac(sum(ok_v), length(bol_vo), "de esos, con forma NNNNN-NN")
if (any(!ok_v)) { cat("  NO matchean (en votos):\n"); for (b in bol_vo[!ok_v]) cat("    ", b, "\n") }
cat(sprintf("  boletines de votaciones presentes en proyectos_detalle : %d / %d\n",
            sum(bol_vo %in% pd$boletin), length(bol_vo)))

# --- H4 ----------------------------------------------------------------------
sep("F0.5  H4  texto descriptivo por votacion en votos.rds")
tiene_txt <- !is.na(v_uni$descripcion) & nzchar(trimws(v_uni$descripcion))
frac(sum(tiene_txt), n_vot, "votaciones con 'descripcion' no vacia")
con_bol <- !is.na(v_uni$boletin) & nzchar(trimws(v_uni$boletin))
frac(sum(tiene_txt &  con_bol), sum(con_bol),  "  ... entre las que TIENEN boletin")
frac(sum(tiene_txt & !con_bol), sum(!con_bol), "  ... entre las que NO tienen boletin")
cat("\n  Muestra de 12 descripciones de votaciones SIN boletin:\n")
for (s in utils::head(unique(v_uni$descripcion[!con_bol]), 12)) cat("    | ", substr(s, 1, 100), "\n")
cat("\n  Muestra de 8 descripciones de votaciones CON boletin:\n")
for (s in utils::head(unique(v_uni$descripcion[con_bol]), 8)) cat("    | ", substr(s, 1, 100), "\n")
cat("\n  Largo de la descripcion (caracteres), por presencia de boletin:\n")
print(v_uni |> mutate(g = ifelse(con_bol, "con_boletin", "sin_boletin"), L = nchar(descripcion)) |>
        summarise(n = n(), min = min(L), mediana = median(L), media = round(mean(L), 1),
                  max = max(L), .by = g) |> as.data.frame())

# --- H5 ----------------------------------------------------------------------
sep("F0.6  H5  votante -> partido -> tendencia")
votantes <- unique(vo$diputado_id)
cat(sprintf("  diputados distintos que aparecen en votos.rds : %d\n", length(votantes)))
cat(sprintf("  padron diputados.rds                          : %d\n", nrow(di)))
frac(sum(votantes %in% di$diputado_id), length(votantes), "votantes presentes en el padron")
fuera <- setdiff(votantes, di$diputado_id)
if (length(fuera)) { cat("  votantes FUERA del padron (id):\n"); cat("    ", paste(fuera, collapse = ", "), "\n") }
frac(sum(!is.na(di$tendencia)), nrow(di), "padron con tendencia no NA")
cat("  partidos sin tendencia en el padron:\n")
print(as.data.frame(di |> filter(is.na(tendencia)) |> count(partido_id, partido_nombre)))
cat("\n  distribucion de tendencia en el padron:\n")
print(as.data.frame(di |> count(tendencia, sort = TRUE)))
# cobertura sobre FILAS de voto
vt <- vo |> left_join(di |> select(diputado_id, partido_id, tendencia), by = "diputado_id")
frac(sum(!is.na(vt$tendencia)), nrow(vt), "FILAS de voto con tendencia asignada")
cat("\n  sentido del voto (todas las filas):\n")
print(as.data.frame(vo |> count(sentido, opcion_valor, sort = TRUE)))

# --- R2: materias oficiales --------------------------------------------------
sep("F0.7  R2  eslabon proyecto -> materia oficial")
n_mat <- vapply(pd$materias, function(m) {
  if (is.null(m)) return(0L)
  if (is.data.frame(m)) return(nrow(m))
  length(m)
}, integer(1))
frac(sum(n_mat > 0), n_bol, "boletines con al menos una materia oficial")
cat(sprintf("  suma de n_materias (columna del intermedio): %d ; recuento propio: %d\n",
            sum(pd$n_materias, na.rm = TRUE), sum(n_mat)))
idx <- which(n_mat > 0)
cat(sprintf("\n  Los %d boletines con materia, uno por uno:\n", length(idx)))
for (i in idx) {
  cat(sprintf("\n    boletin %s\n      titulo : %s\n", pd$boletin[i], substr(pd$nombre[i], 1, 200)))
  m <- pd$materias[[i]]
  cat("      materias:\n")
  if (is.data.frame(m)) { print(as.data.frame(m)) } else print(m)
}

# --- tramitacion: comisiones (insumo de F1.4) --------------------------------
sep("F0.8  tramitacion.rds  estructura del list-col 'tramites'")
t1 <- tr$tramites[[1]]
cat("  clase del elemento 1: ", paste(class(t1), collapse = "/"), "\n")
if (is.data.frame(t1)) { cat("  columnas: ", paste(names(t1), collapse = ", "), "\n"); print(utils::head(as.data.frame(t1), 3)) }
tiene_tr <- vapply(tr$tramites, function(x) is.data.frame(x) && nrow(x) > 0, logical(1))
frac(sum(tiene_tr), nrow(tr), "boletines con tramites no vacios")

saveRDS(list(n_bol = n_bol, n_vot = n_vot), "50_documentacion/andamios/muestras/p92_f0_cifras.rds")
cat("\nF0 terminada sin red.\n")
