# =============================================================================
# 50_verificar_p86.R
# -----------------------------------------------------------------------------
# Arnes de P-86: ¿el mensaje de recuperacion de la guarda de alineamiento nombra
# el paso que hay que correr?
#
# Uso: Rscript 50_documentacion/andamios/50_verificar_p86.R <escenario>
#      escenario: "tramitacion" | "camara"
#
# CERO RED. Cada escenario corre en SU PROPIO PROCESO con el fusible de
# 50_fusible_red.R armado: un stop() no basta como barrera porque el 36 lo atrapa
# y lo degrada a estado = error_red. El fusible usa quit(99), que ningun tryCatch
# intercepta.
#
# INVARIANTE DE LA PRUEBA: ninguna captura cruda ni ningun intermedio queda
# alterado. Todo lo que se toca se respalda antes, se restaura despues y se
# verifica por md5; si la restauracion fallara, el arnes lo dice y no lo tapa.
#
# Autor: Claude Code (encargo P-86/P-90, sesion 22)
# Creado: 2026-08-13
# =============================================================================

suppressWarnings(suppressMessages({
  ROOT <- rprojroot::find_root(rprojroot::has_file(".here"))
  source(file.path(ROOT, "10_utils", "10_locale.R"))
  asegurar_locale_utf8("50_verificar_p86")
}))
options(width = 200)

esc <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(esc)) esc <- "tramitacion"

INT <- file.path(ROOT, "40_salidas", "intermedios")

# Desalinea el sello de un intermedio EN DISCO, tras respaldarlo. Devuelve el
# respaldo y su md5 para que el llamador restaure y verifique.
desalinear <- function(nombre, corte_falso = "2026-08-03") {
  r <- file.path(INT, paste0(nombre, ".rds"))
  if (!file.exists(r)) stop(sprintf("no existe %s", r), call. = FALSE)
  bak <- file.path(tempdir(), paste0(nombre, "_bak.rds"))
  stopifnot(file.copy(r, bak, overwrite = TRUE))
  md5 <- unname(tools::md5sum(r))
  o <- readRDS(r); s <- attr(o, "sello"); s$corte_fecha <- corte_falso
  attr(o, "sello") <- s; saveRDS(o, r)
  list(ruta = r, bak = bak, md5 = md5)
}
restaurar <- function(d, etiqueta) {
  stopifnot(file.copy(d$bak, d$ruta, overwrite = TRUE))
  ok <- identical(unname(tools::md5sum(d$ruta)), d$md5)
  cat(sprintf("  restaurado %-22s md5 identico: %s\n", etiqueta, ok))
  ok
}

# Corre SOLO la guarda, en subproceso y con el fusible armado.
correr_guarda <- function() {
  cod <- '
    ROOT <- rprojroot::find_root(rprojroot::has_file(".here"))
    source(file.path(ROOT, "50_documentacion", "andamios", "50_fusible_red.R"))
    instalar_fusible_red(silencioso = TRUE)
    source(file.path(ROOT, "10_utils", "10_utils.R"))
    suppressWarnings(suppressMessages(library(dplyr)))
    source(file.path(ROOT, "10_utils", "10_configuracion.R"))
    source(file.path(ROOT, "00_run_all.R"), chdir = TRUE)
    r <- tryCatch({ regenerar_intermedios_si_desalineados(PASOS_EXTRACCION, ROOT); "SIN STOP" },
                  error = function(e) paste0("STOP>>>", conditionMessage(e)))
    cat("\n=====RESULTADO=====\n"); cat(r, "\n")'
  f <- tempfile(fileext = ".R"); writeLines(cod, f)
  sal <- suppressWarnings(system2("Rscript", shQuote(f), stdout = TRUE, stderr = TRUE))
  st <- attr(sal, "status")
  list(status = if (is.null(st)) 0L else as.integer(st), salida = sal)
}

# Oculta una captura cruda (mover, nunca borrar) para forzar la rama del stop().
ocultar_captura <- function(ruta) {
  bak <- file.path(tempdir(), basename(ruta))
  md5 <- unname(tools::md5sum(ruta))
  stopifnot(file.copy(ruta, bak, overwrite = TRUE))
  stopifnot(file.remove(ruta))
  list(ruta = ruta, bak = bak, md5 = md5)
}

cat("=============================================================\n")
cat("ESCENARIO:", esc, "\n")
cat("=============================================================\n")

if (identical(esc, "tramitacion")) {
  cap <- file.path(ROOT, "20_insumos", "senado",
                   "20260812_tramitacion_sil_2026_tope-inf.rds")
  d <- desalinear("tramitacion")
  cat("  tramitacion.rds desalineado a 2026-08-03\n")
  h <- ocultar_captura(cap)
  cat("  captura del SIL ocultada (para forzar la rama del stop)\n\n")
  r <- correr_guarda()
  i <- which(r$salida == "=====RESULTADO=====")
  cat("--- SALIDA LITERAL DE LA GUARDA ---\n")
  cat(paste(r$salida[if (length(i)) i:length(r$salida) else seq_along(r$salida)],
            collapse = "\n"), "\n")
  cat("\n--- restauracion ---\n")
  stopifnot(file.copy(h$bak, h$ruta, overwrite = TRUE))
  cat(sprintf("  restaurada captura del SIL   md5 identico: %s\n",
              identical(unname(tools::md5sum(h$ruta)), h$md5)))
  restaurar(d, "tramitacion.rds")

} else if (identical(esc, "camara")) {
  d <- desalinear("proyectos")
  cat("  proyectos.rds desalineado a 2026-08-03 (captura presente)\n\n")
  r <- correr_guarda()
  i <- which(r$salida == "=====RESULTADO=====")
  cat("--- SALIDA LITERAL DE LA GUARDA ---\n")
  cat(paste(utils::tail(r$salida, 14), collapse = "\n"), "\n")
  cat("\n--- restauracion ---\n")
  restaurar(d, "proyectos.rds")

} else stop(sprintf("escenario desconocido: '%s'", esc), call. = FALSE)
