# =============================================================================
# 50_sondeo_p92_f0b.R  --  P-92, F0 (addendum): donde vive el texto de votacion
# -----------------------------------------------------------------------------
# Dispara dos preguntas que F0 abrio:
#  (a) H4 pasa la letra (100 % no vacio) pero la 'descripcion' de votos.rds es una
#      etiqueta ("Boletin N 16300-07"), no texto tematico. Hay texto en otra parte?
#      Candidato: list-col 'votaciones' de proyectos_detalle.rds (P-63, 20 cols).
#  (b) H5 falla: 84 de 239 votantes fuera del padron. Es un efecto de periodo?
# CERO red.
# =============================================================================

RAIZ <- "/Users/tomgc/Projects/transparencia_legislativa_chile"
setwd(RAIZ)
source("50_documentacion/andamios/50_fusible_red.R"); instalar_fusible_red(silencioso = TRUE)
suppressPackageStartupMessages(library(dplyr))
sep <- function(t) cat("\n", strrep("=", 74), "\n", t, "\n", strrep("=", 74), "\n", sep = "")
frac <- function(n, d, etq) cat(sprintf("  %-52s %6d / %-6d  (%6.2f %%)\n", etq, n, d, 100 * n / d))

pd <- readRDS("40_salidas/intermedios/proyectos_detalle.rds")
vo <- readRDS("40_salidas/intermedios/votos.rds")
di <- readRDS("40_salidas/intermedios/diputados.rds")

# --- (a) list-col votaciones -------------------------------------------------
sep("F0.9  list-col 'votaciones' de proyectos_detalle.rds")
tiene <- vapply(pd$votaciones, function(x) is.data.frame(x) && nrow(x) > 0, logical(1))
frac(sum(tiene), nrow(pd), "boletines con nodo Votaciones no vacio")
v1 <- pd$votaciones[[which(tiene)[1]]]
cat("  columnas (", ncol(v1), "): ", paste(names(v1), collapse = ", "), "\n", sep = "")
VOTX <- bind_rows(lapply(which(tiene), function(i) {
  d <- pd$votaciones[[i]]; d$boletin <- pd$boletin[i]; d }))
cat(sprintf("\n  filas totales del nodo Votaciones: %d ; boletines aportantes: %d\n",
            nrow(VOTX), n_distinct(VOTX$boletin)))
cat("\n  cobertura no vacia por columna:\n")
for (cn in names(VOTX)) {
  v <- VOTX[[cn]]
  if (is.list(v)) { cat(sprintf("    %-24s <list-col>\n", cn)); next }
  nv <- sum(!is.na(v) & nzchar(trimws(as.character(v))))
  cat(sprintf("    %-24s %5d / %-5d  (%6.2f %%)  ej: %s\n", cn, nv, nrow(VOTX),
              100 * nv / nrow(VOTX),
              substr(paste(utils::head(unique(as.character(v[!is.na(v) & nzchar(trimws(as.character(v)))])), 2),
                           collapse = " | "), 1, 60)))
}
# el id de votacion de este nodo, cruzado con votos.rds
idcol <- grep("^id$|votacion", names(VOTX), ignore.case = TRUE, value = TRUE)
cat("\n  columnas candidatas a id de votacion: ", paste(idcol, collapse = ", "), "\n", sep = "")
for (ic in idcol) {
  ids <- unique(as.character(VOTX[[ic]]))
  cat(sprintf("    %-18s distintos=%5d  interseccion con votos.rds$votacion_id = %d\n",
              ic, length(ids), sum(ids %in% unique(vo$votacion_id))))
}
cat("\n  Muestra de 10 filas de 'articulo' (texto candidato de la via 4):\n")
if ("articulo" %in% names(VOTX))
  for (s in utils::head(unique(VOTX$articulo[!is.na(VOTX$articulo) & nzchar(trimws(VOTX$articulo))]), 10))
    cat("    | ", substr(s, 1, 110), "\n")

# --- (b) H5 por periodo ------------------------------------------------------
sep("F0.10  H5  los 84 votantes fuera del padron: efecto de periodo?")
vu <- vo |> distinct(votacion_id, .keep_all = TRUE)
cat(sprintf("  rango de fechas de votacion: %s .. %s\n", min(vu$fecha), max(vu$fecha)))
vo2 <- vo |> mutate(en_padron = diputado_id %in% di$diputado_id,
                    mes = substr(fecha, 1, 7))
cat("\n  filas de voto por mes y presencia en el padron:\n")
print(as.data.frame(vo2 |> count(mes, en_padron) |> tidyr::pivot_wider(names_from = en_padron,
      values_from = n, values_fill = 0L)))
cat("\n  votaciones cuyos votantes estan TODOS en el padron, por mes:\n")
agg <- vo2 |> summarise(n_fila = n(), n_fuera = sum(!en_padron), .by = c(votacion_id, mes, fecha))
print(as.data.frame(agg |> summarise(votaciones = n(), sin_extranos = sum(n_fuera == 0),
                                     .by = mes) |> arrange(mes)))
INSTALACION <- "2026-03-11"
vo3 <- vo2 |> filter(fecha >= INSTALACION)
cat(sprintf("\n  Restringido a fecha >= %s (instalacion del periodo vigente):\n", INSTALACION))
frac(nrow(vo3), nrow(vo), "filas de voto retenidas")
frac(sum(vo3$en_padron), nrow(vo3), "  ... con diputado en el padron")
frac(n_distinct(vo3$votacion_id), n_distinct(vo$votacion_id), "votaciones retenidas")
fuera3 <- unique(vo3$diputado_id[!vo3$en_padron])
cat(sprintf("  votantes fuera del padron tras restringir: %d -> %s\n", length(fuera3),
            paste(utils::head(fuera3, 30), collapse = ", ")))
# con tendencia
vt3 <- vo3 |> left_join(di |> select(diputado_id, tendencia), by = "diputado_id")
frac(sum(!is.na(vt3$tendencia)), nrow(vt3), "  ... y con tendencia no NA")
