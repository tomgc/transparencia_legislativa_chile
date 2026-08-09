# =============================================================================
# 00_run_all.R
# -----------------------------------------------------------------------------
# Proposito: Orquestador del pipeline de extraccion y consolidacion de la
#            Camara de Diputadas y Diputados. Solo orquesta; cero logica de
#            negocio (POLITICA 4). El paso 31 (exploracion de la API) NO es
#            parte del pipeline: es diagnostico regenerable, se corre a mano.
# Uso:       source("00_run_all.R"); run_all()
#            run_all(from = 33)          # desde asistencia
#            run_all(only = c(34, 39))   # solo votaciones y consolidacion
#            run_all(skip = 34)          # saltar votaciones
# Autor:     Claude Code (encargo autonomo, sesion 1)
# Creado:    2026-07-06
# =============================================================================

# ---- Cargar utilidades primero (bootstrapping) ----
source("10_utils/10_utils.R", chdir = FALSE)

# ---- Auto-instalacion de paquetes base del orquestador ----
instalar_si_falta(c("rprojroot", "fs", "here"))
library(rprojroot)
library(fs)

# ---- Anclaje del root ----
ROOT <- obtener_raiz_proyecto()

# ---- Configuracion del proyecto (valida precondiciones al inicio) ----
source(file.path(ROOT, "10_utils", "10_configuracion.R"))

# ---- Definicion de pasos ----
# El id refleja el numero de sub-etapa en 30_procesamiento/ (POLITICA 1.2).
PASOS <- list(
  list(id = 32L, etiqueta = "Extraer diputados (roster vigente)",
       ruta = "30_procesamiento/32_extraer_diputados.R"),
  list(id = 33L, etiqueta = "Extraer asistencia a sesiones",
       ruta = "30_procesamiento/33_extraer_asistencia.R"),
  list(id = 34L, etiqueta = "Extraer votaciones nominales",
       ruta = "30_procesamiento/34_extraer_votaciones.R"),
  list(id = 35L, etiqueta = "Extraer proyectos (mociones)",
       ruta = "30_procesamiento/35_extraer_proyectos.R"),
  list(id = 36L, etiqueta = "Extraer detalle de proyectos (contenido: tipo, materias)",
       ruta = "30_procesamiento/36_extraer_detalle_proyectos.R"),
  list(id = 39L, etiqueta = "Consolidar JSON estatico",
       ruta = "30_procesamiento/39_consolidar_json.R")
)

# Pasos de EXTRACCION (los que producen los intermedios sellados). Es lo que
# regenera la guarda de alineamiento cuando detecta el desfase de P-62; se deriva
# de PASOS para que no exista una segunda lista de rutas que se desincronice.
PASOS_EXTRACCION <- Filter(function(p) p$id %in% 32:36, PASOS)

# ---- Funcion principal ----
run_all <- function(from = NULL, to = NULL, only = NULL, skip = NULL) {

  # Precondicion: CORTE_FECHA fijado y valido (falla AQUI, no a mitad de
  # pipeline). corte_para_clave() valida formato AAAA-MM-DD y hace stop() claro
  # si falta; se descarta el valor, solo interesa disparar la validacion.
  invisible(corte_para_clave())
  log_msg(sprintf("Corte temporal: %s", CORTE_FECHA), origen = "00_run_all")

  ids <- vapply(PASOS, function(p) p$id, integer(1))

  # Validar que los argumentos referencian IDs existentes.
  for (nm in c("from", "to", "only", "skip")) {
    arg <- get(nm)
    if (!is.null(arg) && !all(arg %in% ids))
      stop(sprintf("Argumento '%s' referencia IDs inexistentes: %s", nm,
                   paste(setdiff(arg, ids), collapse = ", ")))
  }

  # Validar que todas las rutas existen (al inicio, no a mitad de pipeline).
  faltantes <- character()
  for (p in PASOS) if (!file_exists(path(ROOT, p$ruta))) faltantes <- c(faltantes, p$ruta)
  if (length(faltantes) > 0)
    stop("Rutas no encontradas:\n  ", paste(faltantes, collapse = "\n  "))

  # Guarda de alineamiento de intermedios (P-65). PUNTO UNICO: aqui pasan las
  # cuatro formas de invocacion (from/to/only/skip), despues de validar rutas y
  # antes de resolver o correr ningun paso. Si los intermedios no corresponden al
  # corte vigente, los regenera desde la captura cruda ya versionada -- con aviso
  # y sin red -- en vez de que el operador tenga que acordarse (ver P-62). Si no
  # puede regenerarlos sin red, se detiene con el diagnostico. Idempotente: con
  # los sellos alineados no hace nada ni imprime.
  regenerar_intermedios_si_desalineados(PASOS_EXTRACCION, ROOT)

  # Resolver que pasos ejecutar.
  if (!is.null(only)) {
    pasos_a_correr <- ids[ids %in% only]
  } else {
    pasos_a_correr <- ids
    if (!is.null(from)) pasos_a_correr <- pasos_a_correr[pasos_a_correr >= from]
    if (!is.null(to))   pasos_a_correr <- pasos_a_correr[pasos_a_correr <= to]
  }
  if (!is.null(skip)) pasos_a_correr <- setdiff(pasos_a_correr, skip)

  t_inicio <- Sys.time(); ejecutados <- 0L; saltados <- 0L

  for (p in PASOS) {
    if (!(p$id %in% pasos_a_correr)) {
      log_msg(sprintf("Paso %d (%s) saltado.", p$id, p$etiqueta), origen = "00_run_all")
      saltados <- saltados + 1L
      next
    }
    cat("\n", strrep("=", 76), "\n", sep = "")
    cat(sprintf("PASO %d: %s\n", p$id, p$etiqueta))
    cat(sprintf("Ruta:    %s\n", p$ruta))
    cat(strrep("=", 76), "\n", sep = "")

    t0 <- Sys.time()
    tryCatch(
      source(path(ROOT, p$ruta), echo = FALSE, chdir = TRUE),
      error = function(e)
        stop(sprintf("Paso %d (%s) fallo: %s", p$id, p$etiqueta, e$message))
    )
    dur <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    log_msg(sprintf("Paso %d completado en %.1fs.", p$id, dur), origen = "00_run_all")
    ejecutados <- ejecutados + 1L
  }

  dur_total <- as.numeric(difftime(Sys.time(), t_inicio, units = "secs"))
  cat("\n", strrep("=", 76), "\n", sep = "")
  cat(sprintf("RESUMEN: %d pasos ejecutados, %d saltados, %.1fs en total.\n",
              ejecutados, saltados, dur_total))
  cat(strrep("=", 76), "\n", sep = "")

  # C-reporte del contrato temporal (P-74, D31). Al CERRAR, no al abrir: informa
  # sobre lo que la corrida efectivamente uso. Reportar no es detener -- una
  # captura ya existente fuera de corte se reporta ruidosamente y la corrida
  # termina bien; lo que se detiene es la escritura de una captura nueva fuera
  # de corte, y eso ocurre en con_cache() via guarda_captura_en_corte().
  reportar_estado_capturas()
  invisible(TRUE)
}

# ---- Ejemplos de uso ----
# run_all()                    # Pipeline completo (32 -> 39)
# run_all(from = 33)           # Desde asistencia
# run_all(only = c(34, 39))    # Solo votaciones y consolidacion
# run_all(skip = 34)           # Saltar votaciones
