# =============================================================================
# 10_utils.R
# -----------------------------------------------------------------------------
# Funciones genericas compartidas entre multiples scripts del proyecto.
# RESTRICCION: cero dependencias de paquetes cargados (usar pkg::fun() siempre).
# Esto permite cargar este archivo antes de cualquier library() y resolver
# bootstrapping (instalacion condicional de paquetes, logging, etc.).
# =============================================================================

# ---- Bootstrapping: instalacion condicional de paquetes ---------------------
instalar_si_falta <- function(paquetes) {
  faltantes <- paquetes[
    !sapply(paquetes, requireNamespace, quietly = TRUE)
  ]
  if (length(faltantes) > 0) {
    message(sprintf("Instalando paquetes faltantes: %s",
                    paste(faltantes, collapse = ", ")))
    utils::install.packages(faltantes)
  }
  invisible(TRUE)
}

# ---- Logging ---------------------------------------------------------------
log_msg <- function(msg, nivel = "INFO", origen = NA_character_) {
  ts <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  if (is.na(origen)) {
    cat(sprintf("[%s] [%s] %s\n", ts, nivel, msg))
  } else {
    cat(sprintf("[%s] [%s] [%s] %s\n", ts, origen, nivel, msg))
  }
}

# ---- Anclaje de raiz del proyecto ------------------------------------------
obtener_raiz_proyecto <- function() {
  rprojroot::find_root(
    criterion = rprojroot::has_file(".here") |
                rprojroot::is_rstudio_project |
                rprojroot::is_git_root
  )
}

# ---- Escritura atomica de archivos (patron write -> rename) -----------------
# Garantiza que un artefacto que alimenta otros procesos nunca queda
# parcialmente escrito (POLITICA 5.2.4). Generico para cualquier escritor
# que reciba (objeto, ruta_destino).
# SELLO DE PROCEDENCIA (fix sesion 8): si se pasa `hash_origen`, el objeto se
# sella (ver sellar()) antes de escribirse, de modo que el .rds lleva embebido
# el corte al que pertenece. Sin `hash_origen` (default NULL) el comportamiento
# es identico al anterior: por eso la llamada del 39 que escribe TEXTO json NO
# se rompe (no pasa hash_origen -> no se sella el texto).
escribir_atomico <- function(objeto, ruta, escritor, hash_origen = NULL) {
  if (!is.null(hash_origen)) objeto <- sellar(objeto, hash_origen)
  ruta_temp <- paste0(ruta, ".tmp")
  escritor(objeto, ruta_temp)
  fs::file_move(ruta_temp, ruta)
  invisible(ruta)
}

# ---- Sello de procedencia de un intermedio (fix sesion 8) -------------------
# El bug (traspaso v07 §6, Bug 1): los intermedios .rds estan gitignored y no
# declaran a que corte pertenecen, asi que un .rds residuo de otra corrida puede
# consumirse en silencio (39 republica mal). El sello viaja como atributo dentro
# del propio .rds (no requiere archivo lateral). Depende de CORTE_FECHA y
# ANIO_PROCESO (globales de config, disponibles al escribir).
sellar <- function(objeto, hash_origen) {
  if (!exists("CORTE_FECHA", inherits = TRUE) || is.null(CORTE_FECHA) ||
      !nzchar(trimws(as.character(CORTE_FECHA))))
    stop("sellar: CORTE_FECHA no esta fijada; no se puede sellar la procedencia.",
         call. = FALSE)
  attr(objeto, "sello") <- list(
    corte_fecha  = trimws(as.character(CORTE_FECHA)),
    anio_proceso = as.character(if (exists("ANIO_PROCESO", inherits = TRUE)) ANIO_PROCESO else NA),
    hash_origen  = hash_origen,
    escrito_en   = format(Sys.time(), "%Y-%m-%dT%H:%M:%S")
  )
  objeto
}

# Hash (md5) de uno o mas archivos de cache crudo que alimentaron un intermedio.
# Devuelve un vector nombrado (basename -> md5); NA si el archivo no existe.
hash_origen_de <- function(rutas) {
  rutas <- as.character(rutas)
  h <- vapply(rutas, function(r)
    if (file.exists(r)) unname(tools::md5sum(r)) else NA_character_, character(1))
  stats::setNames(h, basename(rutas))
}

# Lee un intermedio .rds y exige que traiga sello. stop() diagnostico si falta.
leer_sellado <- function(ruta) {
  if (!file.exists(ruta))
    stop(sprintf("leer_sellado: no existe el intermedio '%s'.", ruta), call. = FALSE)
  obj <- readRDS(ruta)
  sello <- attr(obj, "sello")
  if (is.null(sello))
    stop(sprintf(paste0("leer_sellado: '%s' NO trae sello de procedencia. Fue escrito ",
                        "por una version previa del pipeline o esta adulterado. ",
                        "Regenera los pasos 32-36."), basename(ruta)), call. = FALSE)
  list(objeto = obj, sello = sello)
}

# Valida una lista nombrada de sellos contra el corte vigente. stop() diagnostico
# si algun intermedio: (a) no declara corte, (b) declara un corte != CORTE_FECHA,
# o (c) declara un corte distinto al de sus hermanos.
validar_corte <- function(sellos, corte) {
  corte <- trimws(as.character(corte))
  for (nm in names(sellos)) {
    cd <- sellos[[nm]]$corte_fecha
    if (is.null(cd) || is.na(cd) || !nzchar(trimws(as.character(cd))))
      stop(sprintf(paste0("validar_corte: '%s' no declara corte_fecha en su sello. ",
                          "Regenera los pasos 32-36."), nm), call. = FALSE)
    if (!identical(trimws(as.character(cd)), corte))
      stop(sprintf(paste0("validar_corte: '%s' declara corte %s, pero el corte vigente ",
                          "(CORTE_FECHA) es %s. El intermedio NO corresponde al corte ",
                          "publicado; regenera los pasos 32-36 con CORTE_FECHA=%s."),
                   nm, cd, corte, corte), call. = FALSE)
  }
  cortes <- vapply(sellos, function(s) trimws(as.character(s$corte_fecha)), character(1))
  if (length(unique(cortes)) > 1)
    stop(sprintf(paste0("validar_corte: intermedios con cortes distintos entre si (%s). ",
                        "Regenera los pasos 32-36."),
                 paste(sprintf("%s=%s", names(sellos), cortes), collapse = "; ")),
         call. = FALSE)
  invisible(TRUE)
}

# ---- Cliente HTTP para la API de la Camara ----------------------------------
# Toda extraccion de opendata.camara.cl pasa por aqui: un solo punto con
# reintentos con backoff, timeout y User-Agent. Devuelve el documento XML ya
# parseado y con el namespace removido (POLITICA 5.3.9, resiliencia ante
# fuentes externas). NO decide nada de negocio: solo trae el XML crudo.
#
# La firma de los endpoints se documenta en
# 50_documentacion/activa/exploracion_api_camara.md (hallazgo de Fase 1.B).
descargar_xml_camara <- function(operacion,
                                 parametros = list(),
                                 base_url   = getOption("camara.base_url",
                                   "https://opendata.camara.cl/camaradiputados/WServices/"),
                                 intentos   = 4L,
                                 pausa_base = 1.5,
                                 timeout_s  = 60L) {
  url <- paste0(base_url, operacion)
  ultimo_error <- NULL
  for (i in seq_len(intentos)) {
    resp <- tryCatch(
      httr::GET(url,
                query = parametros,
                httr::timeout(timeout_s),
                httr::user_agent(
                  "transparencia_legislativa_chile (R; datos publicos Camara)")),
      error = function(e) e
    )
    if (!inherits(resp, "error") && httr::status_code(resp) == 200) {
      raw <- httr::content(resp, as = "raw")
      doc <- tryCatch(xml2::read_xml(raw), error = function(e) e)
      if (!inherits(doc, "error")) {
        xml2::xml_ns_strip(doc)
        return(doc)
      }
      ultimo_error <- doc
    } else {
      ultimo_error <- if (inherits(resp, "error")) resp else
        simpleError(sprintf("HTTP %s", httr::status_code(resp)))
    }
    # Backoff exponencial con jitter acotado (POLITICA 5.3.9)
    Sys.sleep(pausa_base * (2 ^ (i - 1)))
  }
  stop(sprintf("descargar_xml_camara(): fallo tras %d intentos en '%s' (%s)",
               intentos, operacion,
               if (!is.null(ultimo_error)) conditionMessage(ultimo_error) else "?"),
       call. = FALSE)
}

# ---- Sufijo de tope para la clave de cache ----------------------------------
# La clave de cache debe codificar TODO parametro que altere el contenido
# cacheado; si no, cambiar ese parametro reutiliza en silencio un snapshot con
# el valor viejo (POLITICA 5.3.6; aprendizaje del traspaso v02 §7, deuda de la
# clave de cache sin tope). El tope de extraccion (MAX_*_DETALLE) es uno de esos
# parametros: acota cuantos detalles se bajan, asi que dos corridas del mismo
# dia con topes distintos producen contenidos distintos y deben cachearse aparte.
#   tope = NULL   -> ""            (sin sufijo; retrocompatible para llaves sin tope)
#   tope = Inf    -> "_tope-inf"   (produccion, anno completo)
#   tope = n      -> "_tope-<n>"   (n entero)
sufijo_tope <- function(tope) {
  if (is.null(tope)) return("")
  if (is.infinite(tope)) return("_tope-inf")
  sprintf("_tope-%s", format(as.integer(tope), scientific = FALSE))
}

# ---- Corte temporal explicito para la clave de cache ------------------------
# Valida CORTE_FECHA (definida en 10_configuracion.R) y devuelve su forma
# compacta AAAAMMDD para la clave de cache. Reemplaza Sys.Date(): un snapshot de
# un CORTE dado da cache-hit en cualquier dia con el mismo corte (reproducible,
# sin re-descarga ni drift). SIN default silencioso: si CORTE_FECHA no esta
# fijada o es invalida, stop() claro (nunca a mitad de pipeline; ver 00_run_all).
# Depende de CORTE_FECHA (global de config, disponible en tiempo de ejecucion).
corte_para_clave <- function() {
  if (!exists("CORTE_FECHA", inherits = TRUE) || is.null(CORTE_FECHA) ||
      !nzchar(trimws(as.character(CORTE_FECHA))))
    stop(paste0("CORTE_FECHA no esta fijada. Definela como AAAA-MM-DD en ",
                "10_utils/10_configuracion.R (corte temporal del refresh)."),
         call. = FALSE)
  cf <- trimws(as.character(CORTE_FECHA))
  if (!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", cf))
    stop(sprintf("CORTE_FECHA invalida: '%s'. Formato esperado AAAA-MM-DD.", cf),
         call. = FALSE)
  gsub("-", "", cf)
}

# ---- Cache de captura cruda de la API ---------------------------------------
# Idempotencia y cortesia con la fuente (POLITICA 5.2.3): si ya existe el
# snapshot del dia y no se pidio refrescar, se reutiliza en vez de re-golpear
# la API. La captura se guarda date-stamped en 20_insumos/camara/ (esa es la
# forma "cruda" de nuestro insumo: la fuente es un servicio, no un archivo).
# La clave codifica el CORTE temporal (CORTE_FECHA, ver corte_para_clave) y el
# tope de extraccion (ver sufijo_tope): un cambio de cualquiera genera una clave
# distinta, no reutiliza el snapshot viejo. NO usa Sys.Date(): el corte es
# explicito para que el refresh sea reproducible entre dias, sin drift.
# Depende de ruta_insumos(), REFRESCAR_API y CORTE_FECHA (de 10_configuracion.R,
# disponibles en tiempo de ejecucion, ya que config se carga antes de extraer).
# Ruta del cache crudo para (nombre_cache, tope) al corte vigente. Un solo lugar
# construye la clave, reusado por con_cache (para leer/escribir) y por los 3x
# (para hashear su procedencia con hash_origen_de).
ruta_cache <- function(nombre_cache, tope = NULL) {
  ruta_insumos("camara",
               sprintf("%s_%s%s.rds", corte_para_clave(), nombre_cache, sufijo_tope(tope)))
}

con_cache <- function(nombre_cache, fn_descarga, tope = NULL, origen = "cache") {
  ruta <- ruta_cache(nombre_cache, tope)
  refrescar <- isTRUE(getOption("camara.refrescar", REFRESCAR_API))
  if (file.exists(ruta) && !refrescar) {
    log_msg(sprintf("cache hit: %s", basename(ruta)), origen = origen)
    return(readRDS(ruta))
  }
  obj <- fn_descarga()
  fs::dir_create(dirname(ruta))
  escribir_atomico(obj, ruta, function(o, r) saveRDS(o, r))
  log_msg(sprintf("captura guardada: %s", basename(ruta)), origen = origen)
  obj
}

# ---- Coalesce nulo/NA (helper generico) -------------------------------------
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || is.na(a)) b else a

# ---- Utilidades de texto/tipo para las llaves de identificacion -------------
# Las llaves (id de parlamentario, boletin, etc.) SIEMPRE como character
# (POLITICA 5.3.6): un join con tipos mezclados falla en silencio.
como_llave <- function(x) {
  x <- trimws(as.character(x))
  x[x == ""] <- NA_character_
  x
}

# Texto limpio de un nodo XML (recorta espacios; "" -> NA).
texto_nodo <- function(nodo, xpath) {
  v <- xml2::xml_text(xml2::xml_find_first(nodo, xpath))
  v <- trimws(v)
  if (length(v) == 0 || is.na(v) || v == "") NA_character_ else v
}

# Atributo de un nodo XML ("" -> NA).
attr_nodo <- function(nodo, xpath, attr) {
  n <- xml2::xml_find_first(nodo, xpath)
  if (length(n) == 0 || inherits(n, "xml_missing")) return(NA_character_)
  v <- xml2::xml_attr(n, attr)
  if (is.na(v) || v == "") NA_character_ else v
}

# ---- Parser de contenido de un proyecto (retornarProyectoLey) ---------------
# Extrae del response de retornarProyectoLey los campos de CONTENIDO que el
# pipeline no usaba: titulo, tipo de iniciativa (texto legible, no el atributo
# Valor) y las materias (categoria tematica). La cobertura de materias es
# PARCIAL: la mayoria de las mociones recientes vienen sin materias (0), y solo
# algunos proyectos mas avanzados las traen (ver diagnostico
# 50_documentacion/andamios/logs/20260709_diagnostico_contenido_legible.md).
# Cuando no hay materias se devuelve un data.frame de 0 filas, NUNCA se fabrica.
# Compartido por 35 (proyectos autorados) y 36 (proyectos votados) -> DRY.
# El id de materia se conserva como character (invariante de llave, POLITICA 5.3.6).
parsear_contenido_proyecto <- function(doc) {
  root <- xml2::xml_root(doc)
  ms <- xml2::xml_find_all(root, ".//Materias/Materia")
  materias <- data.frame(
    id     = vapply(ms, function(m) como_llave(texto_nodo(m, "./Id")), character(1)),
    nombre = vapply(ms, function(m) texto_nodo(m, "./Nombre") %||% NA_character_, character(1)),
    stringsAsFactors = FALSE
  )
  list(
    nombre          = texto_nodo(root, "./Nombre"),
    tipo_iniciativa = texto_nodo(root, "./TipoIniciativa"),  # texto legible ("Mocion"/"Mensaje")
    materias        = materias
  )
}
