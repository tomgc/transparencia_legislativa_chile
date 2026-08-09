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

# ---- Contrato temporal de la captura (P-74 acto (b), D31) -------------------
# EL PROBLEMA (medido en el acto (a)): corte_para_clave() construye la clave del
# archivo desde CORTE_FECHA y deliberadamente NO desde Sys.Date() (ver el
# comentario de esa funcion), pero nada comprobaba que la descarga ocurriera
# dentro del corte que la clave declara. Una captura del paso 36 quedo escrita
# bajo la clave de un corte anterior al dia en que se bajo, y trajo una votacion
# posterior a ese corte: contenido que el archivo no deberia representar. Las
# fechas exactas no se fijan aqui -- las cuenta la compuerta G4b de
# 50_documentacion/andamios/50_verificar_p74_acto_b.R sobre la captura real.
# LO QUE ESTO AGREGA: una captura nueva debe poder demostrar que se tomo dentro
# de su corte. Tres piezas -- guarda de escritura (detiene), registro (persiste
# la fecha real de descarga) y reporte (clasifica en tres estados).
# LO QUE NO TOCA: sellar(), leer_sellado() y validar_corte() quedan intactas. La
# via de validar el CONTENIDO contra el corte quedo descartada por el titular.
# EL LIMITE: esto rige la captura NUEVA. Las capturas ya escritas no se
# reescriben (20_insumos/camara/ es crudo inmutable) y por eso quedan en
# `sin_registro`, que NO es cumplimiento: es un tercer estado.

ATRIBUTO_CAPTURA      <- "captura_temporal"
OPCION_ESCAPE_CAPTURA <- "camara.permitir_captura_fuera_de_corte"
ESTADOS_CAPTURA       <- c("dentro_de_corte", "fuera_de_corte", "sin_registro")

# Escape DECLARADO, nunca inferido: una opcion nombrada con default FALSE. No se
# lee de Sys.getenv() a proposito -- una variable de entorno heredada del shell
# encenderia la excepcion sin que nadie la escribiera en la corrida.
escape_captura_declarado <- function() {
  isTRUE(getOption(OPCION_ESCAPE_CAPTURA, FALSE))
}

# El escape es de UN SOLO USO: al consumirse se apaga. Sin esto queda pegajoso en
# la sesion, y como run_all() corre los 6 pasos con source() en la MISMA sesion,
# encenderlo una vez para un caso puntual dejaria pasar sin detencion todas las
# capturas siguientes de esa corrida -- justo el olvido de avanzar CORTE_FECHA
# que el contrato existe para atrapar. Consumir obliga a declararlo por captura.
consumir_escape_captura <- function(origen = "contrato") {
  options(stats::setNames(list(FALSE), OPCION_ESCAPE_CAPTURA))
  log_msg(sprintf(paste0("Escape de captura CONSUMIDO (%s vuelve a FALSE). Es de un solo uso: ",
                         "otra captura fuera de corte en esta misma sesion se detendra."),
                  OPCION_ESCAPE_CAPTURA), "WARN", origen)
  invisible(TRUE)
}

# Guarda de escritura. Devuelve FALSE si la descarga cae dentro del corte, TRUE
# si cae fuera PERO el escape esta declarado (y lo deja en el log), y hace
# stop() accionable si cae fuera sin escape. No devuelve nada silencioso.
guarda_captura_en_corte <- function(nombre_cache, corte = CORTE_FECHA,
                                    hoy = Sys.Date(), origen = "contrato") {
  corte <- trimws(as.character(corte))
  if (!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", corte))
    stop(sprintf("guarda_captura_en_corte: CORTE_FECHA invalida ('%s').", corte),
         call. = FALSE)
  hoy <- format(as.Date(hoy), "%Y-%m-%d")
  if (hoy <= corte) return(FALSE)
  if (escape_captura_declarado()) {
    log_msg(sprintf(paste0("Captura '%s' FUERA DE CORTE por escape declarado: se descarga ",
                           "el %s y el corte es %s. Queda marcada como escape en su registro."),
                    nombre_cache, hoy, corte), "WARN", origen)
    consumir_escape_captura(origen)
    return(TRUE)
  }
  stop(sprintf(paste0(
    "guarda_captura_en_corte: la captura '%s' se descargaria HOY (%s), posterior al corte ",
    "declarado (CORTE_FECHA = %s).\n",
    "  El archivo se llamaria %s_* y su contenido seria del %s: la clave diria una fecha y el ",
    "dato tendria otra. Eso es exactamente lo que P-74 corrige.\n",
    "  Opcion 1 (lo normal): avanza CORTE_FECHA a \"%s\" en 10_utils/10_configuracion.R y vuelve ",
    "a correr.\n",
    "  Opcion 2 (excepcion declarada): options(%s = TRUE) antes de la corrida. La captura queda ",
    "marcada como escape y sale 'fuera_de_corte' en el reporte de run_all()."),
    nombre_cache, hoy, corte, gsub("-", "", corte), hoy, hoy, OPCION_ESCAPE_CAPTURA),
    call. = FALSE)
}

# C-registro: la fecha REAL de descarga viaja con el dato, como atributo. La
# compuerta G5 del acto (b) lo probo empiricamente sobre los tres tipos de objeto
# que 20_insumos/camara/ contiene hoy (data.frame, character y list, contados en
# la propia compuerta G3), porque el 32 y el 33 devuelven character y list y esa
# ruta hay que ejercerla, no suponerla.
# Cierre de la descarga. La guarda valida el dia en que la descarga EMPIEZA, pero
# fn_descarga() no es una llamada: el 36 recorre un boletin por vez y el 34 una
# votacion por vez, con pausa entre cada una. Una corrida larga puede cruzar la
# medianoche y terminar pidiendo datos de un dia posterior al validado. Por eso
# se vuelve a mirar el reloj DESPUES de descargar, antes de escribir: la fecha
# que se registra es la del cierre (la mas tardia), no la del inicio.
verificar_cierre_de_descarga <- function(nombre_cache, corte, ini, fin,
                                         escape, origen = "contrato") {
  corte <- trimws(as.character(corte))
  ini_c <- format(as.Date(ini), "%Y-%m-%d"); fin_c <- format(as.Date(fin), "%Y-%m-%d")
  if (identical(ini_c, fin_c)) return(escape)
  log_msg(sprintf("La descarga de '%s' cruzo la medianoche: empezo el %s y termino el %s.",
                  nombre_cache, ini_c, fin_c), "WARN", origen)
  if (fin_c <= corte) return(escape)
  if (isTRUE(escape) || escape_captura_declarado()) {
    if (!isTRUE(escape)) consumir_escape_captura(origen)
    return(TRUE)
  }
  stop(sprintf(paste0(
    "verificar_cierre_de_descarga: la captura '%s' empezo dentro del corte (%s) pero termino ",
    "el %s, posterior a CORTE_FECHA = %s. No se escribe: su contenido ya no corresponde al ",
    "corte que la clave declara.\n",
    "  Avanza CORTE_FECHA a \"%s\" y vuelve a correr, o declara la excepcion con options(%s = TRUE)."),
    nombre_cache, ini_c, fin_c, corte, fin_c, OPCION_ESCAPE_CAPTURA), call. = FALSE)
}

registrar_captura <- function(objeto, corte = CORTE_FECHA, ini = Sys.Date(),
                              fin = ini, escape = FALSE) {
  ini_c <- format(as.Date(ini), "%Y-%m-%d"); fin_c <- format(as.Date(fin), "%Y-%m-%d")
  attr(objeto, ATRIBUTO_CAPTURA) <- list(
    # descarga_fecha es la del CIERRE: si la corrida cruzo la medianoche, la
    # fecha conservadora es la ultima llamada, no la primera.
    descarga_fecha  = fin_c,
    descarga_inicio = ini_c,
    descarga_fin    = fin_c,
    corte_fecha     = trimws(as.character(corte)),
    escape          = isTRUE(escape),
    registrado_por  = "con_cache")
  objeto
}

# Estado temporal de una captura EN DISCO. `sin_registro` no se imputa ni se
# interpreta como cumplimiento (invariante 6 del encargo): es un tercer estado.
# Un registro presente pero ilegible (campo vacio, NA, o fecha con formato que no
# es AAAA-MM-DD) tampoco es conformidad: cae en sin_registro, nunca en
# dentro_de_corte. Comparar "" <= "" daria TRUE y clasificaria un registro vacio
# como conforme, que es exactamente el falso verde que hay que impedir.
fecha_registro_valida <- function(x) {
  !is.null(x) && length(x) == 1L && !is.na(x) && nzchar(trimws(as.character(x))) &&
    grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", trimws(as.character(x)))
}

estado_temporal_captura <- function(ruta) {
  if (!file.exists(ruta))
    stop(sprintf("estado_temporal_captura: no existe '%s'.", ruta), call. = FALSE)
  reg <- attr(readRDS(ruta), ATRIBUTO_CAPTURA)
  sin_registro <- list(estado = "sin_registro", descarga_fecha = NA_character_,
                       corte_fecha = NA_character_, escape = NA)
  if (is.null(reg)) return(sin_registro)
  if (!fecha_registro_valida(reg$descarga_fecha) || !fecha_registro_valida(reg$corte_fecha))
    return(sin_registro)
  list(estado = if (trimws(reg$descarga_fecha) <= trimws(reg$corte_fecha)) "dentro_de_corte"
                else "fuera_de_corte",
       descarga_fecha = trimws(reg$descarga_fecha),
       corte_fecha    = trimws(reg$corte_fecha),
       escape         = isTRUE(reg$escape))
}

# C-reporte: al cerrar run_all(), el estado temporal de las capturas del corte
# vigente, con denominador. Reportar no es detener: una captura ya existente
# fuera de corte se reporta ruidosamente, pero no aborta la corrida (solo la
# escritura nueva se detiene, en guarda_captura_en_corte).
reportar_estado_capturas <- function(corte = CORTE_FECHA, origen = "contrato") {
  dir_cam <- ruta_insumos("camara")
  if (!dir.exists(dir_cam))
    stop(sprintf("reportar_estado_capturas: no existe '%s'.", dir_cam), call. = FALSE)
  todas <- sort(list.files(dir_cam, "[.]rds$", full.names = TRUE))
  prefijo <- paste0(gsub("-", "", trimws(as.character(corte))), "_")
  del_corte <- todas[startsWith(basename(todas), prefijo)]
  if (length(del_corte) == 0)
    stop(sprintf("reportar_estado_capturas: ninguna captura con prefijo '%s' en %s.",
                 prefijo, dir_cam), call. = FALSE)
  est <- lapply(del_corte, estado_temporal_captura)
  clases <- vapply(est, function(e) e$estado, character(1))
  log_msg(sprintf("Contrato temporal: %d capturas del corte %s (de %d .rds en el directorio).",
                  length(del_corte), corte, length(todas)), origen = origen)
  for (s in ESTADOS_CAPTURA)
    log_msg(sprintf("  %-16s: %d de %d capturas del corte", s, sum(clases == s),
                    length(del_corte)),
            if (identical(s, "fuera_de_corte") && sum(clases == s) > 0) "WARN" else "INFO",
            origen)
  for (k in seq_along(del_corte))
    log_msg(sprintf("  %-52s %-16s (descarga %s, escape %s)",
                    basename(del_corte[k]), est[[k]]$estado,
                    est[[k]]$descarga_fecha %||% "NA",
                    as.character(est[[k]]$escape)), origen = origen)
  if (sum(clases == "sin_registro") > 0)
    log_msg(sprintf(paste0("  %d de %d capturas del corte son ANTERIORES al contrato (P-74) y no ",
                           "llevan fecha de descarga. 'sin_registro' NO es conformidad."),
                    sum(clases == "sin_registro"), length(del_corte)), "WARN", origen)
  invisible(stats::setNames(clases, basename(del_corte)))
}

con_cache <- function(nombre_cache, fn_descarga, tope = NULL, origen = "cache") {
  ruta <- ruta_cache(nombre_cache, tope)
  refrescar <- isTRUE(getOption("camara.refrescar", REFRESCAR_API))
  if (file.exists(ruta) && !refrescar) {
    log_msg(sprintf("cache hit: %s", basename(ruta)), origen = origen)
    return(readRDS(ruta))
  }
  # P-74 (C): la guarda va ANTES de fn_descarga(), no entre la descarga y la
  # escritura. Detener despues de golpear la API gastaria justamente la llamada
  # que la guarda existe para evitar. Y se vuelve a mirar el reloj DESPUES, por
  # si la descarga (un loop de cientos de llamadas) cruzo la medianoche.
  ini    <- Sys.Date()
  escape <- guarda_captura_en_corte(nombre_cache, CORTE_FECHA, ini, origen)
  obj    <- fn_descarga()
  fin    <- Sys.Date()
  escape <- verificar_cierre_de_descarga(nombre_cache, CORTE_FECHA, ini, fin, escape, origen)
  fs::dir_create(dirname(ruta))
  obj    <- registrar_captura(obj, CORTE_FECHA, ini, fin, escape)
  escribir_atomico(obj, ruta, function(o, r) saveRDS(o, r))
  log_msg(sprintf("captura guardada: %s (descarga %s%s, corte %s%s)", basename(ruta),
                  format(fin, "%Y-%m-%d"),
                  if (!identical(ini, fin)) sprintf(" [inicio %s]", format(ini, "%Y-%m-%d")) else "",
                  trimws(as.character(CORTE_FECHA)),
                  if (escape) ", ESCAPE DECLARADO" else ""), origen = origen)
  obj
}

# ---- Guarda de alineamiento de los intermedios (fix sesion 16, P-65) --------
# EL PROBLEMA (diagnosticado en P-62): los intermedios .rds estan gitignored y el
# workflow semanal NO los commitea, pero SI commitea el avance de CORTE_FECHA.
# Por eso toda copia local queda desalineada despues de cada merge del bot y el
# 39 se detiene en su compuerta de procedencia (validar_corte).
# LA CORRECCION NO ES DEBILITAR ESA COMPUERTA -- queda intacta y sigue haciendo
# stop(). Esto actua AGUAS ARRIBA: el orquestador detecta la condicion y hace,
# con aviso y automaticamente, lo que hasta ahora tenia que recordar el operador
# (correr 32-36 antes del 39).
# INVARIANTE: la regeneracion automatica NO baja nada de la red. Procede solo si
# la captura cruda del corte vigente ya esta en 20_insumos/camara/ (esa si la
# commitea el workflow). Si falta, stop() con el diagnostico y el comando exacto.
# Alcance: vive en el orquestador, no dentro del 39. Invocar el 39 suelto con
# intermedios desalineados sigue fallando, y eso es correcto.

# Los 6 intermedios que consume el 39 (39_consolidar_json.R:49-58).
INTERMEDIOS_PIPELINE <- c("diputados", "asistencia_nominal", "asistencia_ambitos",
                          "votos", "proyectos", "proyectos_detalle")

# Capturas crudas que cada extractor necesita para dar cache hit. Las claves
# replican las que arma cada script (32:65; 33:47 y 33:76; 34:33; 35:26; 36:70);
# la RUTA la construye ruta_cache(), que sigue siendo el unico lugar que conoce
# la forma de la clave. Depende de las globales de config (ANIO_PROCESO, MAX_*),
# disponibles en tiempo de ejecucion igual que en con_cache().
capturas_crudas_de_paso <- function(id) {
  switch(as.character(id),
    "32" = ruta_cache("diputados"),
    "33" = c(ruta_cache("periodo_legislativo"),
             ruta_cache(sprintf("asistencia_nominal_%d", ANIO_PROCESO),
                        MAX_SESIONES_DETALLE)),
    "34" = ruta_cache(sprintf("votos_long_%d", ANIO_PROCESO), MAX_VOTACIONES_DETALLE),
    "35" = ruta_cache(sprintf("proyectos_long_%d", ANIO_PROCESO), MAX_PROYECTOS_DETALLE),
    # P-63: la captura del 36 es ahora el XML crudo bajo clave PROPIA. La anterior
    # (detalle_proyectos_<anio>) guardaba el derivado del parser, asi que solo
    # permitia reproducir los campos que el parser de ese dia conservo: con ella
    # la guarda prometia regenerar sin red algo que no podia. Sus .rds siguen en
    # 20_insumos/camara/ y no se borran (dato crudo inmutable), solo dejaron de
    # leerse; mismo criterio que los de asistencia_long tras el retiro del legacy.
    "36" = ruta_cache(sprintf("detalle_proyectos_xml_%d", ANIO_PROCESO), Inf),
    stop(sprintf("capturas_crudas_de_paso: el paso %s no declara captura cruda.", id),
         call. = FALSE))
}

# Corte que declara un intermedio, SIN abortar: NA si falta el archivo o no trae
# sello. Reusa leer_sellado() (no se escribe un segundo lector de sello); su
# stop() se captura porque aqui "no legible" ES una de las condiciones que hay
# que diagnosticar, no un fallo.
corte_declarado_por <- function(nombre) {
  s <- tryCatch(leer_sellado(ruta_salidas("intermedios", paste0(nombre, ".rds")))$sello,
                error = function(e) NULL)
  if (is.null(s) || is.null(s$corte_fecha)) NA_character_
  else trimws(as.character(s$corte_fecha))
}

# Guarda propiamente tal. `pasos` es la sublista de PASOS con los extractores
# (id + ruta), en orden: 32 escribe el roster que lee el 33, y 36 lee lo que
# escriben 34 y 35. `root` es la raiz del proyecto (las rutas de PASOS son
# relativas a ella). Devuelve TRUE si regenero, FALSE si no hizo falta.
regenerar_intermedios_si_desalineados <- function(pasos, root, corte = CORTE_FECHA) {
  corte <- trimws(as.character(corte))
  declarados   <- vapply(INTERMEDIOS_PIPELINE, corte_declarado_por, character(1))
  desalineados <- names(declarados)[is.na(declarados) | declarados != corte]

  # 1) Los 6 declaran el corte vigente: no hace nada y no imprime ruido.
  if (length(desalineados) == 0) return(invisible(FALSE))

  # 2) Solo se regenera desde la captura cruda ya versionada, jamas desde la red.
  faltantes <- lapply(pasos, function(p) {
    cs <- capturas_crudas_de_paso(p$id); cs[!file.exists(cs)]
  })
  names(faltantes) <- vapply(pasos, function(p) p$ruta, character(1))
  faltantes <- faltantes[lengths(faltantes) > 0]
  if (length(faltantes) > 0)
    stop(sprintf(paste0(
      "run_all: %d de %d intermedios NO corresponden al corte vigente (%s): %s.\n",
      "  No se pueden regenerar: falta la captura cruda de ese corte en ",
      "20_insumos/camara/ (%d archivo(s)): %s.\n",
      "  La regeneracion automatica no descarga nada de la red (invariante del ",
      "proyecto), asi que este paso no puede resolverse solo.\n",
      "  Corre CON RED, desde la raiz del proyecto y en este orden:\n%s\n",
      "  y despues reintenta: source(\"00_run_all.R\"); run_all()"),
      length(desalineados), length(INTERMEDIOS_PIPELINE), corte,
      paste(desalineados, collapse = ", "),
      length(unlist(faltantes, use.names = FALSE)),
      paste(basename(unlist(faltantes, use.names = FALSE)), collapse = ", "),
      paste(sprintf("    source(\"%s\")", names(faltantes)), collapse = "\n")),
      call. = FALSE)

  # 3) Anuncio: que se detecto, que se va a hacer y por que. Nada silencioso.
  log_msg(sprintf("Intermedios desalineados con el corte vigente (%s): %d de %d.",
                  corte, length(desalineados), length(INTERMEDIOS_PIPELINE)),
          "WARN", "guarda_intermedios")
  log_msg(sprintf("Sello declarado por artefacto: %s.",
                  paste(sprintf("%s=%s", names(declarados),
                                ifelse(is.na(declarados), "ausente o sin sello", declarados)),
                        collapse = "; ")),
          "WARN", "guarda_intermedios")
  log_msg(paste0("Causa conocida (P-62): los intermedios no se versionan y el corte si, ",
                 "asi que toda copia local queda atrasada tras un refresh del bot."),
          "WARN", "guarda_intermedios")
  log_msg(sprintf(paste0("Regenerando los pasos %s desde la captura cruda del corte %s ",
                         "(cache hit, sin red). CORTE_FECHA no se toca."),
                  paste(vapply(pasos, function(p) p$id, integer(1)), collapse = ", "), corte),
          "WARN", "guarda_intermedios")

  # 4) Regeneracion con cache forzado: aunque el operador tenga camara.refrescar
  #    o REFRESCAR_API en TRUE, esta corrida automatica no golpea la API.
  opciones_previas <- options(camara.refrescar = FALSE)
  on.exit(options(opciones_previas), add = TRUE)
  for (p in pasos) {
    tryCatch(
      source(file.path(root, p$ruta), echo = FALSE, chdir = TRUE),
      error = function(e)
        stop(sprintf("guarda_intermedios: la regeneracion del paso %d (%s) fallo: %s",
                     p$id, p$ruta, conditionMessage(e)), call. = FALSE))
  }

  # 5) Se vuelve a verificar: si sigue desalineado, no se continua.
  declarados <- vapply(INTERMEDIOS_PIPELINE, corte_declarado_por, character(1))
  malos <- names(declarados)[is.na(declarados) | declarados != corte]
  if (length(malos) > 0)
    stop(sprintf(paste0("guarda_intermedios: tras regenerar, %d de %d intermedios siguen ",
                        "desalineados con el corte %s (%s). No se continua; revisa la ",
                        "captura cruda de 20_insumos/camara/."),
                 length(malos), length(INTERMEDIOS_PIPELINE), corte,
                 paste(malos, collapse = ", ")), call. = FALSE)
  log_msg(sprintf("Intermedios regenerados: %d de %d al corte %s. Sigue el pipeline.",
                  length(INTERMEDIOS_PIPELINE), length(INTERMEDIOS_PIPELINE), corte),
          origen = "guarda_intermedios")
  invisible(TRUE)
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
# Consumidor UNICO: 36_extraer_detalle_proyectos.R:82. El 35 NO la invoca: parsea
# ./Autores/ParlamentarioAutor por su cuenta (35:58-61). El comentario anterior la
# declaraba "compartida por 35 y 36 -> DRY", lo que era falso; medido en P-63 (G1)
# con un barrido de los 24 archivos .R del repositorio: 1 definicion, 1 invocacion.
# El id de materia se conserva como character (invariante de llave, POLITICA 5.3.6).
#
# NODO Votaciones (P-63): hasta la sesion 17 esta funcion lo descartaba, y como el
# 36 cacheaba SU RETORNO en vez del XML, el nodo no quedaba en disco y rescatarlo
# exigia volver a la red. Ahora se conserva. Forma real medida sobre 44 elementos
# (G6), no supuesta: el contenedor ./Votaciones viene SIEMPRE presente y sus hijos
# son <VotacionProyectoLey> con 14 campos. Presencia de contenedor NO es presencia
# de dato (A62): en los boletines no votados viene presente y vacio, y por eso se
# cuentan elementos, no nodos.
# De los 14 campos, 6 traen el codigo de dominio en un atributo (Valor en cuatro,
# Id en dos) y la glosa en el texto: se conservan AMBOS, con el patron
# attr_nodo() + texto_nodo() que ya usan el 33 (tipo_valor/tipo_glosa) y el 34.
# Los valores se extraen SIN transformar (character tal cual la fuente, "" -> NA);
# la unica excepcion es el id de votacion, que pasa por como_llave() por ser llave.
# No se convierte a entero ni se trunca la fecha: cualquier coercion es una
# decision del consumidor, no del extractor.
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
    materias        = materias,
    votaciones      = parsear_votaciones_proyecto(root)
  )
}

# Votaciones de un ProyectoLey, en el orden en que la fuente las entrega.
# Devuelve SIEMPRE las 20 columnas: un data.frame de 0 filas cuando el contenedor
# viene vacio, nunca NULL y nunca fabricado. Separado de parsear_contenido_proyecto()
# para que el esquema de columnas viva en un solo sitio y el caso vacio no lo duplique.
VOTACIONES_COLUMNAS <- c(
  "votacion_id", "descripcion", "fecha",
  "total_si", "total_no", "total_abstencion", "total_dispensado", "articulo",
  "quorum_valor", "quorum_glosa", "resultado_valor", "resultado_glosa",
  "tipo_valor", "tipo_glosa", "tipo_votacion_valor", "tipo_votacion_glosa",
  "tramite_constitucional_id", "tramite_constitucional_glosa",
  "tramite_reglamentario_id", "tramite_reglamentario_glosa")

parsear_votaciones_proyecto <- function(root) {
  vs <- xml2::xml_find_all(root, "./Votaciones/VotacionProyectoLey")
  if (length(vs) == 0) {
    vacio <- as.data.frame(
      stats::setNames(rep(list(character(0)), length(VOTACIONES_COLUMNAS)),
                      VOTACIONES_COLUMNAS),
      stringsAsFactors = FALSE)
    return(vacio)
  }
  txt <- function(xp) vapply(vs, function(v) texto_nodo(v, xp) %||% NA_character_, character(1))
  att <- function(xp, a) vapply(vs, function(v) attr_nodo(v, xp, a), character(1))
  data.frame(
    votacion_id       = como_llave(txt("./Id")),   # llave -> character (POLITICA 5.3.6)
    descripcion       = txt("./Descripcion"),
    fecha             = txt("./Fecha"),            # sin truncar: la fuente da fecha y hora
    total_si          = txt("./TotalSi"),
    total_no          = txt("./TotalNo"),
    total_abstencion  = txt("./TotalAbstencion"),
    total_dispensado  = txt("./TotalDispensado"),
    articulo          = txt("./Articulo"),
    quorum_valor      = att("./Quorum", "Valor"),
    quorum_glosa      = txt("./Quorum"),
    resultado_valor   = att("./Resultado", "Valor"),
    resultado_glosa   = txt("./Resultado"),
    tipo_valor        = att("./Tipo", "Valor"),
    tipo_glosa        = txt("./Tipo"),
    tipo_votacion_valor = att("./TipoVotacionProyectoLey", "Valor"),
    tipo_votacion_glosa = txt("./TipoVotacionProyectoLey"),
    tramite_constitucional_id    = att("./TramiteConstitucional", "Id"),
    tramite_constitucional_glosa = txt("./TramiteConstitucional"),
    tramite_reglamentario_id     = att("./TramiteReglamentario", "Id"),
    tramite_reglamentario_glosa  = txt("./TramiteReglamentario"),
    stringsAsFactors = FALSE
  )
}
