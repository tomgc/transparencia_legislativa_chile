# =============================================================================
# 50_medicion_p48_p52_p56.R
# -----------------------------------------------------------------------------
# Proposito: PASE DE MEDICION, sin escritura sobre el proyecto. Responde por
#            lectura tres preguntas que hoy solo estan respondidas por
#            procedencia, antes de tocar el 33 y el 39:
#            (A) P-48: quien consume todavia los seis nombres del contrato
#                legacy de asistencia, en todo archivo de codigo o
#                documentacion del repo (los JSON de salida se excluyen a
#                proposito: son el producto, no un consumidor).
#            (B) P-56: si el +0 de todos los conteos entre el corte del 25 y
#                el del 27 es real o es una anomalia de captura, comparando
#                los caches crudos de ambos cortes, que ya estan en disco.
#            (C) P-52: si cada script declara paquetes, rutas y constantes al
#                inicio (auditoria de apertura #3, POLITICA 5.6).
# Insumos:   solo lectura. 20_insumos/camara/*.rds (caches de los dos cortes),
#            los .R del proyecto, docs/, CLAUDE.md, .github/workflows/.
# Salidas:   ninguna. Todo va a consola.
# Uso:       Rscript 50_documentacion/andamios/50_medicion_p48_p52_p56.R
#            (o source() desde Positron con el proyecto abierto)
# Autor:     Claude (sesion 15)
# Creado:    2026-08-03
# =============================================================================

# La raiz se deriva de la RUTA DE ESTE ARCHIVO, no del directorio de trabajo:
# `Rscript` no cambia el cwd, asi que buscar `.here` desde getwd() falla cuando
# el script se invoca desde el home. Se sube por el arbol desde la ubicacion
# real del script hasta encontrar `.here`, con fallback a getwd().
raiz_desde <- function(inicio) {
  d <- normalizePath(inicio, mustWork = FALSE)
  repeat {
    if (file.exists(file.path(d, ".here"))) return(d)
    padre <- dirname(d)
    if (identical(padre, d)) return(NA_character_)
    d <- padre
  }
}
args <- commandArgs(trailingOnly = FALSE)
this <- sub("^--file=", "", grep("^--file=", args, value = TRUE))
ROOT <- raiz_desde(if (length(this) == 1) dirname(this) else getwd())
if (is.na(ROOT)) ROOT <- raiz_desde(getwd())
if (is.na(ROOT))
  stop("No se encontro el ancla `.here` ni desde el script ni desde el cwd.",
       call. = FALSE)
cat("Raiz del proyecto:", ROOT, "\n")
ruta <- function(...) file.path(ROOT, ...)

linea <- function(t) cat("\n", strrep("=", 78), "\n", t, "\n",
                         strrep("=", 78), "\n", sep = "")

# =============================================================================
# (A) P-48 - Consumidores vivos del contrato legacy de asistencia
# =============================================================================
# Los seis nombres del contrato a retirar. `anio` NO se busca: es un nombre
# demasiado generico y ademas vive tambien en los bloques votaciones y
# proyectos, que no se tocan; su retiro del bloque asistencia se decide por
# lectura del 39, no por conteo de ocurrencias.
NOMBRES_LEGACY <- c("tasa_asistencia", "n_sesiones", "n_asiste", "n_no_asiste",
                    "asistencia.rds", "asistencia_long")

# Universo de archivos inspeccionados: codigo y documentacion, NUNCA los JSON
# publicados (son la salida que se quiere cambiar, no un consumidor de ella).
# Se declara el denominador para que el resultado sea interpretable.
patrones_archivo <- c("\\.R$", "\\.Rmd$", "\\.html$", "\\.js$", "\\.css$",
                      "\\.md$", "\\.yml$", "\\.yaml$")
todos <- list.files(ROOT, recursive = TRUE, all.files = TRUE,
                    full.names = TRUE, no.. = TRUE)
excluir <- grepl("/(\\.git|\\.Rproj\\.user|node_modules|renv)/", todos) |
           grepl("/40_salidas/json/", todos) |
           grepl("/docs/data/", todos) |
           grepl("/20_insumos/", todos) |
           grepl("50_medicion_p48_p52_p56\\.R$", todos)
archivos <- todos[!excluir &
                    Reduce(`|`, lapply(patrones_archivo, grepl, x = todos))]

linea(sprintf("(A) P-48 | Consumidores legacy en %d archivos de codigo/doc",
              length(archivos)))
cat("Denominador declarado: se excluyen 40_salidas/json/, docs/data/,",
    "20_insumos/ y este mismo script.\n\n")

hallazgos <- list()
for (f in archivos) {
  txt <- tryCatch(readLines(f, warn = FALSE, encoding = "UTF-8"),
                  error = function(e) character(0))
  if (length(txt) == 0) next
  for (nm in NOMBRES_LEGACY) {
    hit <- which(grepl(nm, txt, fixed = TRUE))
    if (length(hit) > 0)
      hallazgos[[length(hallazgos) + 1L]] <- data.frame(
        archivo = sub(paste0("^", ROOT, "/"), "", f),
        nombre  = nm,
        n       = length(hit),
        lineas  = paste(utils::head(hit, 12), collapse = ","),
        stringsAsFactors = FALSE)
  }
}
if (length(hallazgos) == 0) {
  cat("Sin ocurrencias. El contrato legacy no tiene consumidores en codigo.\n")
} else {
  res <- do.call(rbind, hallazgos)
  res <- res[order(res$archivo, res$nombre), ]
  print(res, row.names = FALSE)
  cat("\nTotal de ocurrencias:", sum(res$n),
      "en", length(unique(res$archivo)), "archivos.\n")
}

cat("\n--- Contexto literal en docs/index.html (el consumidor que importa) ---\n")
idx <- ruta("docs", "index.html")
if (file.exists(idx)) {
  t_idx <- readLines(idx, warn = FALSE, encoding = "UTF-8")
  hit <- which(grepl("tasa_asistencia|n_no_asiste|n_asiste|n_sesiones",
                     t_idx, fixed = FALSE))
  if (length(hit) == 0) {
    cat("docs/index.html: 0 ocurrencias de los cuatro nombres.",
        "Precondicion de P-48 confirmada POR LECTURA.\n")
  } else {
    for (k in hit) cat(sprintf("L%d: %s\n", k, trimws(t_idx[k])))
  }
} else {
  cat("docs/index.html NO EXISTE en la ruta esperada. Detener P-48.\n")
}

# =============================================================================
# (B) P-56 - El +0 entre el corte del 25 y el del 27
# =============================================================================
linea("(B) P-56 | Corte 2026-07-25 vs 2026-07-27 sobre los caches en disco")

CACHE <- ruta("20_insumos", "camara")
pares <- c("asistencia_long_2026_tope-inf", "asistencia_nominal_2026_tope-inf",
           "detalle_proyectos_2026_tope-inf", "proyectos_long_2026_tope-inf",
           "votos_long_2026_tope-inf", "diputados", "periodo_legislativo")

desenvolver <- function(x) {
  # El cache puede venir crudo o envuelto con sello; ambos casos se resuelven
  # aqui en vez de asumir uno (la forma se comprueba, no se supone).
  if (is.data.frame(x)) return(x)
  if (is.list(x) && !is.null(x$objeto)) return(x$objeto)
  x
}

filas <- list()
for (p in pares) {
  f25 <- file.path(CACHE, paste0("20260725_", p, ".rds"))
  f27 <- file.path(CACHE, paste0("20260727_", p, ".rds"))
  if (!file.exists(f25) || !file.exists(f27)) {
    filas[[length(filas) + 1L]] <- data.frame(
      cache = p, filas_25 = NA_integer_, filas_27 = NA_integer_,
      md5_igual = NA, stringsAsFactors = FALSE)
    next
  }
  o25 <- desenvolver(readRDS(f25)); o27 <- desenvolver(readRDS(f27))
  n25 <- if (is.data.frame(o25)) nrow(o25) else length(o25)
  n27 <- if (is.data.frame(o27)) nrow(o27) else length(o27)
  filas[[length(filas) + 1L]] <- data.frame(
    cache = p, filas_25 = n25, filas_27 = n27,
    md5_igual = unname(tools::md5sum(f25) == tools::md5sum(f27)),
    stringsAsFactors = FALSE)
}
print(do.call(rbind, filas), row.names = FALSE)

cat("\n--- Universo de sesiones en el nominal de cada corte ---\n")
for (d in c("20260725", "20260727")) {
  f <- file.path(CACHE, paste0(d, "_asistencia_nominal_2026_tope-inf.rds"))
  if (!file.exists(f)) { cat(d, ": cache ausente.\n", sep = ""); next }
  o <- desenvolver(readRDS(f))
  if (!is.data.frame(o) || !all(c("sesion_id", "fecha") %in% names(o))) {
    cat(d, ": el cache no tiene la forma esperada; columnas: ",
        paste(names(o), collapse = ", "), "\n", sep = "")
    next
  }
  cat(sprintf("%s | sesiones=%d | fecha_ultima=%s | filas=%d | ids=%d\n",
              d, length(unique(o$sesion_id)), max(o$fecha, na.rm = TRUE),
              nrow(o), length(unique(o$diputado_id))))
}
cat("\nLectura: si las dos lineas coinciden en sesiones y fecha_ultima,",
    "el +0 es real\n(la Camara no celebro sesiones nuevas entre el 25 y el",
    "27). Si difieren, hay\nanomalia de captura y P-56 escala.\n")

# =============================================================================
# (C) P-52 - Paquetes, rutas y constantes al inicio de cada script
# =============================================================================
linea("(C) P-52 | Auditoria de apertura #3 sobre los scripts del proyecto")

scripts <- todos[!excluir & grepl("\\.R$", todos) &
                   !grepl("/50_documentacion/", todos)]
diag <- list()
for (f in scripts) {
  txt <- readLines(f, warn = FALSE, encoding = "UTF-8")
  codigo <- txt[!grepl("^\\s*#", txt)]
  diag[[length(diag) + 1L]] <- data.frame(
    archivo   = sub(paste0("^", ROOT, "/"), "", f),
    utils     = any(grepl("10_utils\\.R", codigo)),
    config    = any(grepl("10_configuracion\\.R", codigo)),
    library_n = sum(grepl("^\\s*library\\(", codigo)),
    # Ruta absoluta escrita a mano: el sintoma que la auditoria #3 busca.
    ruta_dura = sum(grepl("\"/Users/|\"/home/|\"C:", codigo)),
    # Constante candidata a vivir en 10_configuracion.R: ASIGNACION en
    # MAYUSCULAS fuera del propio archivo de configuracion.
    const_loc = sum(grepl("^[A-Z_]{3,}\\s*<-", codigo)),
    stringsAsFactors = FALSE)
}
d <- do.call(rbind, diag)
print(d[order(d$archivo), ], row.names = FALSE)
cat("\nLectura: `utils`/`config` FALSE en un script de pipeline es hallazgo;",
    "`ruta_dura`>0\nes hallazgo siempre; `const_loc`>0 fuera de",
    "10_configuracion.R exige mirar la linea.\n")

linea("FIN DE LA MEDICION - no se escribio nada")
