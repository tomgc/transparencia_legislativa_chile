# =============================================================================
# 00_escanear_proyecto.R (v3)
# -----------------------------------------------------------------------------
# Propósito: Generar snapshot de la estructura del proyecto (raíz de código).
#            Output dual: .txt para histórico local, .md para adjuntar a chat.
#            Mantiene solo los 2 snapshots sellados más recientes (poda
#            atómica, ver POLITICA_PROYECTO.md sección 7.4).
# Alcance:   SOLO la raíz de código. Jamás escanea la raíz de datos externa
#            (OneDrive): el snapshot se versiona en Git y mapear el data root
#            filtraría nombres de archivos con información sensible.
# Disparadores:
#   1. Al abrir sesión nueva.
#   2. Después de reorganizar estructura.
#   3. Antes de cerrar sesión.
#   4. Cuando un agente pierde referencia de dónde están los archivos.
# Output (en 50_documentacion/estructura/):
#   - YYYYMMDD_HHMMSS_estructura.txt / .md   (snapshots sellados, retención 2)
#   - estructura_actual.txt / .md            (aliases, nunca se podan)
# =============================================================================

# ---- Auto-instalación -------------------------------------------------------
paquetes_requeridos <- c("fs", "rprojroot")
paquetes_faltantes <- paquetes_requeridos[
  !sapply(paquetes_requeridos, requireNamespace, quietly = TRUE)
]
if (length(paquetes_faltantes) > 0) install.packages(paquetes_faltantes)

library(fs)

# ---- Anclaje del root -------------------------------------------------------
ROOT <- rprojroot::find_root(
  criterion = rprojroot::has_file(".here") |
              rprojroot::is_rstudio_project |
              rprojroot::is_git_root
)

# ---- Configuración ----------------------------------------------------------
EXCLUIR <- c(".git", "renv", ".Rproj.user", ".quarto")
INCLUIR_ARCHIVO <- FALSE      # Cambiar a TRUE para incluir _archivo/ en el escaneo.
RETENCION_SNAPSHOTS <- 2      # Timestamps sellados a conservar (cada uno = par .txt/.md).

# Regex de exclusión con límites de componente de ruta: evita falsos positivos
# (ej. ".git" como subcadena dentro de otros nombres) y escapa los puntos.
REGEX_EXCLUIR <- sprintf(
  "(^|/)(%s)(/|$)",
  paste(gsub("\\.", "\\\\.", EXCLUIR), collapse = "|")
)
REGEX_ARCHIVO <- "(^|/)_archivo(/|$)"
REGEX_SNAPSHOT_SELLADO <- "^\\d{8}_\\d{6}_estructura\\.(txt|md)$"

# ---- Función: formatear tamaño legible -------------------------------------
formato_tamano <- function(bytes) {
  if (is.na(bytes) || bytes == 0) return("0B")
  unidades <- c("B", "K", "M", "G")
  exp <- min(floor(log(bytes, 1024)), length(unidades) - 1)
  sprintf("%.2f%s", bytes / (1024 ^ exp), unidades[exp + 1])
}

# ---- Función: construir árbol recursivo ------------------------------------
construir_arbol <- function(ruta_base, prefijo = "") {
  items <- dir_ls(ruta_base, all = FALSE)
  items <- items[!basename(items) %in% EXCLUIR]
  if (!INCLUIR_ARCHIVO) items <- items[basename(items) != "_archivo"]

  # Ordenar: carpetas primero, luego archivos, alfabéticamente dentro de cada grupo.
  es_dir <- is_dir(items)
  items <- c(sort(items[es_dir]), sort(items[!es_dir]))

  lineas <- character()
  for (item in items) {
    es_carpeta <- is_dir(item)
    nombre <- basename(item)
    if (es_carpeta) nombre <- paste0(nombre, "/")

    if (es_carpeta) {
      lineas <- c(lineas, paste0(prefijo, "├── ", nombre))
      sub_lineas <- construir_arbol(item, paste0(prefijo, "│   "))
      lineas <- c(lineas, sub_lineas)
    } else {
      tamano <- formato_tamano(file_info(item)$size)
      lineas <- c(lineas, sprintf("%s├── %s    [%s]", prefijo, nombre, tamano))
    }
  }
  lineas
}

# ---- Función: conteo por extensión -----------------------------------------
conteo_extensiones <- function(ruta_base) {
  todos <- dir_ls(ruta_base, recurse = TRUE, type = "file", all = FALSE)
  todos <- todos[!grepl(REGEX_EXCLUIR, todos)]
  if (!INCLUIR_ARCHIVO) todos <- todos[!grepl(REGEX_ARCHIVO, todos)]

  exts <- tools::file_ext(todos)
  exts[exts == ""] <- "(sin extensión)"
  sort(table(exts), decreasing = TRUE)
}

# ---- Función: generar contenido en formato dado ---------------------------
generar_contenido <- function(ruta_base, formato = "txt") {
  fecha <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  arbol <- construir_arbol(ruta_base)
  extensiones <- conteo_extensiones(ruta_base)

  todos_archivos <- dir_ls(ruta_base, recurse = TRUE, type = "file", all = FALSE)
  todas_carpetas <- dir_ls(ruta_base, recurse = TRUE, type = "directory", all = FALSE)
  todos_archivos <- todos_archivos[!grepl(REGEX_EXCLUIR, todos_archivos)]
  todas_carpetas <- todas_carpetas[!grepl(REGEX_EXCLUIR, todas_carpetas)]
  if (!INCLUIR_ARCHIVO) {
    todos_archivos <- todos_archivos[!grepl(REGEX_ARCHIVO, todos_archivos)]
    todas_carpetas <- todas_carpetas[!grepl(REGEX_ARCHIVO, todas_carpetas)]
  }

  if (formato == "md") {
    # Versión Markdown — optimizada para adjuntar a chat.
    out <- c(
      "# Estructura del proyecto",
      "",
      paste0("- **Raíz:** `", ruta_base, "`"),
      paste0("- **Fecha:** ", fecha),
      paste0("- **Total:** ", length(todas_carpetas), " carpetas, ",
             length(todos_archivos), " archivos"),
      "",
      "## Árbol",
      "",
      "```",
      arbol,
      "```",
      "",
      "## Conteo por extensión",
      "",
      "| Extensión | Cantidad |",
      "|-----------|----------|"
    )
    for (i in seq_along(extensiones)) {
      out <- c(out, sprintf("| `.%s` | %d |", names(extensiones)[i], extensiones[i]))
    }
  } else {
    # Versión TXT — histórico local.
    out <- c(
      strrep("=", 60),
      " ESTRUCTURA DEL PROYECTO",
      paste0(" Raíz: ", ruta_base),
      paste0(" Fecha: ", fecha),
      paste0(" Total: ", length(todas_carpetas), " carpetas, ",
             length(todos_archivos), " archivos"),
      strrep("=", 60),
      "",
      arbol,
      "",
      strrep("=", 60),
      " CONTEO POR EXTENSIÓN",
      strrep("=", 60),
      ""
    )
    for (i in seq_along(extensiones)) {
      out <- c(out, sprintf("  .%-15s %3d", names(extensiones)[i], extensiones[i]))
    }
  }
  out
}

# ---- Función: poda atómica de snapshots sellados ---------------------------
# Conserva solo los RETENCION_SNAPSHOTS timestamps más recientes (cada uno con
# su par .txt/.md). Los aliases estructura_actual.* no calzan con el patrón y
# por lo tanto nunca se podan. Cualquier archivo fuera del patrón no se toca.
podar_snapshots <- function(carpeta_destino) {
  archivos <- dir_ls(carpeta_destino, type = "file")
  sellados <- archivos[grepl(REGEX_SNAPSHOT_SELLADO, basename(archivos))]
  if (length(sellados) == 0) return(invisible(0L))

  ts_de_cada <- substr(basename(sellados), 1, 15)       # "YYYYMMDD_HHMMSS"
  ts_unicos <- sort(unique(ts_de_cada), decreasing = TRUE)
  if (length(ts_unicos) <= RETENCION_SNAPSHOTS) return(invisible(0L))

  ts_a_borrar <- ts_unicos[(RETENCION_SNAPSHOTS + 1):length(ts_unicos)]
  a_borrar <- sellados[ts_de_cada %in% ts_a_borrar]
  file_delete(a_borrar)
  for (f in a_borrar) cat(sprintf("  Podado:   %s\n", f))
  invisible(length(a_borrar))
}

# ---- Ejecución principal ----------------------------------------------------
ejecutar_escaneo <- function() {
  carpeta_destino <- path(ROOT, "50_documentacion", "estructura")
  dir_create(carpeta_destino)

  ts <- format(Sys.time(), "%Y%m%d_%H%M%S")

  # 1) Escribir snapshots sellados y 2) actualizar aliases.
  #    Si cualquier escritura falla, el error aborta ANTES de la poda:
  #    una corrida fallida nunca destruye el histórico existente.
  for (fmt in c("txt", "md")) {
    contenido <- generar_contenido(ROOT, formato = fmt)

    archivo_snapshot <- path(carpeta_destino,
                             sprintf("%s_estructura.%s", ts, fmt))
    writeLines(contenido, archivo_snapshot)

    archivo_actual <- path(carpeta_destino, sprintf("estructura_actual.%s", fmt))
    writeLines(contenido, archivo_actual)

    cat(sprintf("  Generado: %s\n", archivo_snapshot))
    cat(sprintf("  Generado: %s\n", archivo_actual))
  }

  # 3) Solo después de escritura exitosa: podar el excedente.
  podar_snapshots(carpeta_destino)

  invisible(TRUE)
}

# Ejecutar al hacer source().
ejecutar_escaneo()
