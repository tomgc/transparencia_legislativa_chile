# =============================================================================
# 10_diff_conteos.R
# -----------------------------------------------------------------------------
# Proposito: Comparar DOS versiones del output JSON (indice + perfiles) y
#            reportar diferencias en los conteos clave, como compuerta de
#            sanidad ANTES de publicar un refresh (ver
#            50_documentacion/activa/procedimiento_actualizacion.md, paso 4).
#            Utilidad de verificacion, NO un paso del pipeline (no va en
#            00_run_all). Reusable: se sourcea (define diff_conteos_json) o se
#            corre standalone con dos rutas.
# Uso (sourced):
#   source(here::here("10_utils", "10_diff_conteos.R"))
#   diff_conteos_json("40_salidas/_json_previo", "40_salidas/json")
# Uso (standalone):
#   Rscript 10_utils/10_diff_conteos.R <dir_json_A> <dir_json_B>
# Cada <dir_json_*> es un directorio de salida con perfiles/<id>.json (y,
# opcionalmente, indice_diputados.json).
# Autor:     Claude Code (encargo corte temporal, sesion 4)
# Creado:    2026-07-10
# =============================================================================

# ---- Cargar utilidades (para instalar_si_falta y %||%) ----------------------
source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
instalar_si_falta(c("jsonlite"))

# ---- Contar los conteos clave de un directorio de salida JSON ---------------
# Devuelve un vector nombrado (integer) con: total de perfiles, total de
# votaciones, total de mociones/proyectos, y el split de votos con/sin proyecto
# (trazabilidad voto->proyecto). Llaves de conteo estables (para el diff).
contar_conteos_json <- function(dir_json) {
  pdir <- file.path(dir_json, "perfiles")
  if (!dir.exists(pdir))
    stop(sprintf("10_diff_conteos: no existe el directorio de perfiles '%s'.", pdir),
         call. = FALSE)
  files <- list.files(pdir, pattern = "[.]json$", full.names = TRUE)
  tot_vot <- 0L; tot_moc <- 0L; con_proy <- 0L; sin_proy <- 0L
  for (f in files) {
    p <- jsonlite::fromJSON(f, simplifyVector = FALSE)
    tot_vot <- tot_vot + as.integer(p$votaciones$n_votaciones %||% 0L)
    tot_moc <- tot_moc + as.integer(p$proyectos$n_proyectos %||% 0L)
    for (v in p$votaciones$votos) {
      if (is.null(v$proyecto)) sin_proy <- sin_proy + 1L else con_proy <- con_proy + 1L
    }
  }
  c(perfiles           = length(files),
    votaciones         = tot_vot,
    mociones           = tot_moc,
    votos_con_proyecto = con_proy,
    votos_sin_proyecto = sin_proy)
}

# ---- Diff de conteos entre dos versiones (A = previo, B = nuevo) -------------
# Imprime una tabla a consola y devuelve (invisible) un data.frame con el diff.
diff_conteos_json <- function(dir_a, dir_b) {
  a <- contar_conteos_json(dir_a)
  b <- contar_conteos_json(dir_b)
  metricas <- names(a)
  cat(sprintf("Comparacion de conteos JSON\n  A (previo): %s\n  B (nuevo):  %s\n\n",
              dir_a, dir_b))
  cat(sprintf("%-22s %12s %12s %11s\n", "conteo", "A (previo)", "B (nuevo)", "diff (B-A)"))
  cat(strrep("-", 60), "\n", sep = "")
  hay_diff <- FALSE
  for (m in metricas) {
    d <- b[[m]] - a[[m]]
    if (d != 0L) hay_diff <- TRUE
    cat(sprintf("%-22s %12d %12d %+11d\n", m, a[[m]], b[[m]], d))
  }
  cat(strrep("-", 60), "\n", sep = "")
  cat(if (hay_diff)
        "HAY diferencias de conteo -> revisar antes de publicar (crecimiento moderado es esperable; caidas o saltos anomalos, no).\n"
      else
        "Sin diferencias de conteo (JSON equivalentes en totales clave).\n")
  invisible(data.frame(conteo = metricas,
                       A = as.integer(a), B = as.integer(b),
                       diff = as.integer(b - a), row.names = NULL,
                       stringsAsFactors = FALSE))
}

# ---- Punto de entrada standalone --------------------------------------------
if (sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 2)
    stop("Uso: Rscript 10_utils/10_diff_conteos.R <dir_json_A> <dir_json_B>",
         call. = FALSE)
  diff_conteos_json(args[1], args[2])
}
