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

# ---- Guarda de locale UTF-8 (P-59, POLITICA 5.2bis) -------------------------
# Punto de arranque PROPIO: este archivo NO carga 10_configuracion.R y el
# workflow lo invoca suelto (refresh-semanal.yml:88). Su salida de texto termina
# en resumen_diff.txt, que el workflow concatena en commit_msg.txt y usa como
# mensaje de commit y como cuerpo del PR: sin esta guarda, una corrida con
# LC_CTYPE=C podria escribir ese texto escapado en el historial del repositorio.
# La ruta se resuelve como ya lo hace este archivo, con rprojroot.
source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_locale.R"))
asegurar_locale_utf8("10_diff_conteos")

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
  # ---- Entidad `proyecto` (P-66 acto b) --------------------------------------
  # Segundo directorio de salida. Se cuenta por CONTENIDO (>=1 tramite), no por
  # presencia del bloque: `tramitacion` viene siempre y contar su existencia daria
  # el total del universo en vez de la cobertura real. Es la misma trampa que el
  # acto A midio en el nodo `leynro` (presente en 427, con dato en 28).
  # NA_integer_ y no 0 cuando el directorio no existe: son dos estados distintos.
  # "no hay entidad proyecto en esta version" no es "hay 0 proyectos con
  # tramitacion", y colapsarlos haria que la primera corrida se leyera como una
  # caida catastrofica de la metrica.
  pdir <- file.path(dir_json, "proyectos")
  proy_con_tram <- NA_integer_
  if (dir.exists(pdir)) {
    pfiles <- list.files(pdir, pattern = "[.]json$", full.names = TRUE)
    n <- 0L
    for (f in pfiles) {
      p <- jsonlite::fromJSON(f, simplifyVector = FALSE)
      # Sin %||%: ese helper del proyecto hace is.na(a) sobre el objeto entero y
      # no esta vectorizado, asi que con una lista de N tramites aborta la
      # corrida. La comprobacion explicita es equivalente y no depende de eso.
      tr <- p$tramitacion$tramites
      if (!is.null(tr) && length(tr) > 0) n <- n + 1L
    }
    proy_con_tram <- n
  }

  c(perfiles           = length(files),
    votaciones         = tot_vot,
    mociones           = tot_moc,
    votos_con_proyecto = con_proy,
    votos_sin_proyecto = sin_proy,
    proyectos_con_tramitacion = proy_con_tram)
}

# Metricas acumulativas / de calidad que NUNCA deben CAER en un refresh sano (el
# corpus de la API solo crece): una caida indica perdida de datos o regresion
# del join voto->proyecto. votos_sin_proyecto se REPORTA pero no gatea (una caida
# ahi es mejora -> mas votos trazados a su proyecto, no perdida).
METRICAS_GATE <- c("perfiles", "votaciones", "mociones", "votos_con_proyecto")

# Metricas que gatean SOLO cuando hay con que comparar (P-66 acto b, D-g).
# `proyectos_con_tramitacion` nace con este encargo: en la primera corrida el
# lado A (previo) no tiene directorio de proyectos y su conteo es NA. Gatear ahi
# seria comparar contra nada. La condicion se resuelve EN CODIGO, mirando si
# ambos lados traen valor, y no confiando en que alguien recuerde desactivarla:
# en cuanto exista un segundo corte con la entidad publicada, gatea sola y sin
# tocar este archivo.
METRICAS_GATE_CONDICIONALES <- c("proyectos_con_tramitacion")

# Un conteo es comparable si los dos lados lo traen. NA en cualquiera de los dos
# significa "esta version no publica esa entidad", no "cayo a cero".
comparable <- function(a, b, m) {
  !is.null(a[[m]]) && !is.null(b[[m]]) && !is.na(a[[m]]) && !is.na(b[[m]])
}

# ---- Diff de conteos entre dos versiones (A = previo, B = nuevo) -------------
# Imprime una tabla a consola (comportamiento standalone sin cambios) y devuelve
# (invisible) una LISTA con los conteos de ambos lados, el diff, y un veredicto
# de GATE programatico (para la compuerta de CI):
#   gate = "OK"    -> se puede publicar
#   gate = "FAIL"  -> abortar; $motivos explica que cayo y de cuanto a cuanto
# El gate falla si perfiles_B < piso_perfiles (piso absoluto) o si alguna
# METRICAS_GATE cayo (B < A). Un crecimiento es aceptable; una caida no.
diff_conteos_json <- function(dir_a, dir_b, piso_perfiles = 155L) {
  a <- contar_conteos_json(dir_a)
  b <- contar_conteos_json(dir_b)
  metricas <- names(a)
  cat(sprintf("Comparacion de conteos JSON\n  A (previo): %s\n  B (nuevo):  %s\n\n",
              dir_a, dir_b))
  cat(sprintf("%-22s %12s %12s %11s\n", "conteo", "A (previo)", "B (nuevo)", "diff (B-A)"))
  cat(strrep("-", 60), "\n", sep = "")
  hay_diff <- FALSE
  fmt <- function(x) if (is.na(x)) "        n/d" else sprintf("%11d", x)
  for (m in metricas) {
    if (!comparable(a, b, m)) {
      # No se imprime un diff inventado para algo que no se puede restar.
      cat(sprintf("%-26s %12s %12s %11s\n", m, fmt(a[[m]]), fmt(b[[m]]), "n/d"))
      next
    }
    d <- b[[m]] - a[[m]]
    if (d != 0L) hay_diff <- TRUE
    cat(sprintf("%-26s %12d %12d %+11d\n", m, a[[m]], b[[m]], d))
  }
  cat(strrep("-", 60), "\n", sep = "")
  cat(if (hay_diff)
        "HAY diferencias de conteo -> revisar antes de publicar (crecimiento moderado es esperable; caidas o saltos anomalos, no).\n"
      else
        "Sin diferencias de conteo (JSON equivalentes en totales clave).\n")

  # ---- Veredicto del GATE (para la compuerta de CI) ----
  motivos <- character()
  if (b[["perfiles"]] < piso_perfiles)
    motivos <- c(motivos, sprintf("perfiles %d < piso %d", b[["perfiles"]], piso_perfiles))
  for (m in METRICAS_GATE) {
    if (b[[m]] < a[[m]])
      motivos <- c(motivos, sprintf("%s cayo: %d -> %d (%+d)", m, a[[m]], b[[m]], b[[m]] - a[[m]]))
  }
  # Condicionales: gatean igual que las demas, pero solo cuando hay dos lados que
  # comparar. Si no lo hay, se dice por que no gateo -- el silencio pareceria
  # conformidad y aqui no la hay: simplemente no habia con que medir.
  no_gatearon <- character()
  for (m in METRICAS_GATE_CONDICIONALES) {
    if (!comparable(a, b, m)) {
      no_gatearon <- c(no_gatearon, m)
      next
    }
    if (b[[m]] < a[[m]])
      motivos <- c(motivos, sprintf("%s cayo: %d -> %d (%+d)", m, a[[m]], b[[m]], b[[m]] - a[[m]]))
  }
  if (length(no_gatearon) > 0)
    cat(sprintf(paste0("NOTA: %s no gateo en esta corrida porque una de las dos versiones no ",
                       "publica esa entidad (conteo n/d). Gatea sola en cuanto existan dos ",
                       "cortes con ella.\n"), paste(no_gatearon, collapse = ", ")))
  gate <- if (length(motivos) > 0) "FAIL" else "OK"

  invisible(list(
    conteos = data.frame(conteo = metricas,
                         A = as.integer(a), B = as.integer(b),
                         diff = as.integer(b) - as.integer(a), row.names = NULL,
                         stringsAsFactors = FALSE),
    gate         = gate,
    motivos      = motivos,
    no_gatearon  = no_gatearon
  ))
}

# ---- Punto de entrada standalone --------------------------------------------
if (sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 2)
    stop("Uso: Rscript 10_utils/10_diff_conteos.R <dir_json_A> <dir_json_B>",
         call. = FALSE)
  diff_conteos_json(args[1], args[2])
}
