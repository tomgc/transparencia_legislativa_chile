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
# El parametro `corte` existe para que quien ya tiene un corte en la mano pueda
# resolver la clave con ESE y no con la global. Default = la global, asi que todo
# llamador previo se comporta igual. Sin el, capturas_crudas_de_paso() media
# desalineamiento contra un corte y existencia de capturas contra otro.
corte_para_clave <- function(corte = NULL) {
  if (is.null(corte)) {
    if (!exists("CORTE_FECHA", inherits = TRUE) || is.null(CORTE_FECHA) ||
        !nzchar(trimws(as.character(CORTE_FECHA))))
      stop(paste0("CORTE_FECHA no esta fijada. Definela como AAAA-MM-DD en ",
                  "10_utils/10_configuracion.R (corte temporal del refresh)."),
           call. = FALSE)
    corte <- CORTE_FECHA
  }
  cf <- trimws(as.character(corte))
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
# ---- Subdirectorios de crudo, nombrados una sola vez (P-102) ----------------
# Cada fuente de crudo escribe en su propia carpeta (una por host, enmienda 1 de
# P-66). El nombre de esa carpeta se escribia a mano en seis sitios; ahora se
# nombra aqui y los seis lo leen. Por NOMBRE y no por posicion:
# `DIRECTORIOS_CRUDO[1]` habria sido tan fragil como el literal que reemplaza,
# porque reordenar el vector cambiaria en silencio a que carpeta apunta cada
# llamada. Renombrar un directorio pasa a ser una linea en vez de un grep.
CRUDO_CAMARA <- "camara"
CRUDO_SENADO <- "senado"

# Depende de ruta_insumos(), REFRESCAR_API y CORTE_FECHA (de 10_configuracion.R,
# disponibles en tiempo de ejecucion, ya que config se carga antes de extraer).
# Ruta del cache crudo para (nombre_cache, tope) al corte vigente. Un solo lugar
# construye la clave, reusado por con_cache (para leer/escribir) y por los 3x
# (para hashear su procedencia con hash_origen_de).
# `subdir` (P-66 acto b, enmienda 1) fija la CARPETA de origen del crudo, que
# hasta ahora estaba escrita a mano aqui. Motivo: el pipeline incorpora una
# segunda fuente (el SIL, tramitacion.senado.cl) y mezclarla con las capturas de
# opendata.camara.cl en el mismo directorio borraria la unica senal de que son
# origenes distintos. Una carpeta por host, igual que `camara/` es la Camara.
# Default "camara": toda llamada existente conserva su ruta byte a byte, lo que
# se comprueba programaticamente contra la salida de HEAD, no por inspeccion.
# El resto de la clave (corte y tope) NO cambia: la doctrina de que la clave
# codifica todo lo que altera el contenido sigue viviendo en un solo sitio.
ruta_cache <- function(nombre_cache, tope = NULL, corte = NULL, subdir = CRUDO_CAMARA) {
  ruta_insumos(subdir,
               sprintf("%s_%s%s.rds", corte_para_clave(corte), nombre_cache, sufijo_tope(tope)))
}

# Directorios de crudo que el contrato temporal de P-74 tiene que vigilar. Vive
# aqui, junto a ruta_cache(), porque son las dos caras de lo mismo: donde se
# escribe el crudo y donde se audita. Agregar una fuente y olvidarse de sumarla a
# esta lista dejaria su captura fuera del reporte, que es justo el punto ciego
# que la enmienda 1 existe para no abrir.
DIRECTORIOS_CRUDO <- c(CRUDO_CAMARA, CRUDO_SENADO)

# Traduce la declaracion de arriba a las rutas que el bot del refresh versiona.
# El paso "Commit en rama" de .github/workflows/refresh-semanal.yml depende de
# esta funcion: ampliar DIRECTORIOS_CRUDO amplia lo que el bot commitea (P-99).
rutas_versionables_crudo <- function() {
  file.path("20_insumos", DIRECTORIOS_CRUDO)
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

# Consumo generico de un escape declarado (P-76). Todo escape del proyecto es de
# UN SOLO USO: al consumirse se apaga. Sin esto queda pegajoso en la sesion, y
# como run_all() corre los 6 pasos con source() en la MISMA sesion, encenderlo
# una vez para un caso puntual dejaria pasar sin detencion todo lo que sigue en
# esa corrida. Consumir obliga a declararlo por caso.
# `nota` es una plantilla de sprintf con UN solo %s: ahi se interpola el nombre
# de la opcion, para que el log siempre diga cual se apago. Se pasa como
# plantilla (y no compuesta por el llamador) porque el texto que hoy emite
# consumir_escape_captura() tiene que salir identico, byte a byte, al de HEAD.
consumir_escape <- function(opcion, nota, origen) {
  options(stats::setNames(list(FALSE), opcion))
  log_msg(sprintf(nota, opcion), "WARN", origen)
  invisible(TRUE)
}

# Escape del contrato temporal de captura (P-74). Envoltorio del generico: su
# nombre, su firma y el texto de su log NO cambian.
consumir_escape_captura <- function(origen = "contrato") {
  consumir_escape(
    OPCION_ESCAPE_CAPTURA,
    paste0("Escape de captura CONSUMIDO (%s vuelve a FALSE). Es de un solo uso: ",
           "otra captura fuera de corte en esta misma sesion se detendra."),
    origen)
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
# P-66 acto b, enmienda 1: barre TODOS los directorios de crudo, no solo el de la
# Camara. Sin esto, el crudo del SIL quedaria fuera del contrato temporal justo
# en la fuente que la medicion del acto A demostro que entrega eventos
# posteriores al corte, y la compuerta de D-h se quedaria sin instrumento.
# El stop() NO se afloja: cada directorio declarado debe existir y debe tener al
# menos una captura del corte, exactamente como se exigia antes para `camara`.
# Un directorio que aparece en DIRECTORIOS_CRUDO y esta vacio es un fallo, no un
# caso tolerado: significa que una fuente declarada no capturo nada en este corte.
reportar_estado_capturas <- function(corte = CORTE_FECHA, origen = "contrato",
                                     subdirs = DIRECTORIOS_CRUDO) {
  prefijo <- paste0(gsub("-", "", trimws(as.character(corte))), "_")
  acumulado <- character(0)
  for (sd in subdirs) {
    dir_c <- ruta_insumos(sd)
    if (!dir.exists(dir_c))
      stop(sprintf("reportar_estado_capturas: no existe '%s'.", dir_c), call. = FALSE)
    todas <- sort(list.files(dir_c, "[.]rds$", full.names = TRUE))
    del_corte <- todas[startsWith(basename(todas), prefijo)]
    if (length(del_corte) == 0)
      stop(sprintf("reportar_estado_capturas: ninguna captura con prefijo '%s' en %s.",
                   prefijo, dir_c), call. = FALSE)
    est <- lapply(del_corte, estado_temporal_captura)
    clases <- vapply(est, function(e) e$estado, character(1))
    log_msg(sprintf("Contrato temporal [%s]: %d capturas del corte %s (de %d .rds en el directorio).",
                    sd, length(del_corte), corte, length(todas)), origen = origen)
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
    acumulado <- c(acumulado, stats::setNames(clases, basename(del_corte)))
  }
  invisible(acumulado)
}

# `subdir` va AL FINAL de la firma y con default (P-66 acto b, enmienda 1): las 6
# llamadas existentes pasan sus argumentos por nombre a partir del tercero, asi
# que ninguna cambia de comportamiento. con_cache() sigue siendo agnostica al
# ORIGEN del dato (fn_descarga es un closure arbitrario) y ahora tambien al
# DESTINO, que era lo unico que la ataba a la Camara.
con_cache <- function(nombre_cache, fn_descarga, tope = NULL, origen = "cache",
                      subdir = CRUDO_CAMARA) {
  ruta <- ruta_cache(nombre_cache, tope, subdir = subdir)
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

# Los 7 intermedios que consume el 39 (39_consolidar_json.R:49-64).
# P-86: `tramitacion` entra aqui. Sin el, la guarda no MIRA ese intermedio, asi
# que un tramitacion.rds desalineado no se detectaba en el punto donde hay
# captura cruda para arreglarlo sin red, y el fallo aparecia mas tarde, en
# validar_corte() dentro del 39, con un mensaje que manda a regenerar 32-36.
# Medido en F0bis: el 37 regenera desde su captura versionada sin una sola
# llamada de red y con contenido identico, igual que 32-36, asi que entra en pie
# de igualdad con ellos y no como caso aparte.
INTERMEDIOS_PIPELINE <- c("diputados", "asistencia_nominal", "asistencia_ambitos",
                          "votos", "proyectos", "proyectos_detalle", "tramitacion")

# P-77: rastro de arranque. Vive DENTRO de 40_salidas/intermedios/ y esta
# gitignorado (.gitignore, junto a la linea de los .rds). Su unica funcion es
# distinguir dos estados que hasta ahora colapsaban en "0 intermedios en disco":
# "esta copia nunca corrio" (checkout fresco: el runner) y "esta copia corrio y
# alguien borro los intermedios" (donde descargar el anno completo es justo lo
# que no se quiere). El directorio NO sirve de rastro: existe en todo checkout
# porque .gitkeep esta trackeado, y destrackearlo rompe la ruta de recuperacion
# que la propia guarda imprime (extractores sueltos, que no crean directorios).
RASTRO_ARRANQUE <- "arranque_registrado.txt"

# Se escribe con el corte vigente y el instante. Nadie lo parsea: la guarda solo
# mira file.exists(). El contenido es para el operador que lo encuentre.
escribir_rastro_arranque <- function(corte, motivo) {
  ruta <- ruta_salidas("intermedios", RASTRO_ARRANQUE)
  # Si alguien borro el directorio entero, se recrea aqui: sin el, ni el rastro ni
  # los intermedios que vienen despues tienen donde escribirse (escribir_atomico()
  # no crea directorios, A12). Mismo criterio que con_cache() con el suyo.
  fs::dir_create(dirname(ruta))
  writeLines(c(
    "# Rastro de arranque del pipeline (P-77). Archivo gitignorado, regenerable.",
    "# Su PRESENCIA le dice a la guarda de 00_run_all.R que esta copia del repo ya",
    "# tuvo intermedios: con 0 intermedios en disco, el estado es 'los borraron',",
    "# no 'primera corrida'. Borrarlo hace que la proxima corrida sin intermedios",
    "# se lea como un clon fresco y pueda descargar el anno completo.",
    sprintf("corte_fecha: %s", corte),
    sprintf("escrito: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
    sprintf("motivo: %s", motivo)), ruta)
  invisible(ruta)
}

# Autorizacion EXPLICITA para arrancar un corte descargando cuando ya hay
# intermedios en disco pero desalineados y faltan sus capturas. Opcion nombrada,
# default FALSE, jamas inferida del entorno: no se lee de Sys.getenv() ni se
# deduce de estar corriendo en CI, porque eso convertiria "estoy en un servidor"
# en "puedo bajar un anno entero", que no es la misma afirmacion. El caso del bot
# NO necesita esta opcion: alli no hay ningun intermedio y entra por la rama de
# primera corrida.
OPCION_DESCARGA_INICIAL <- "camara.permitir_descarga_inicial"

descarga_inicial_autorizada <- function() {
  isTRUE(getOption(OPCION_DESCARGA_INICIAL, FALSE))
}

# P-76: este escape tambien es de UN SOLO USO. Hasta el PR #9 quedaba encendido
# despues de usarse, asi que autorizarlo para un caso lo dejaba encendido para
# todo lo que siguiera en la misma sesion de run_all(). Misma asimetria que el
# PR #8 cerro para el escape de captura, y se cierra con el mismo helper.
consumir_descarga_inicial <- function(origen = "guarda_intermedios") {
  consumir_escape(
    OPCION_DESCARGA_INICIAL,
    paste0("Escape de descarga inicial CONSUMIDO (%s vuelve a FALSE). Es de un solo uso: ",
           "si esta corrida vuelve a pasar por este estado, o lo hace la siguiente, la guarda ",
           "se detiene otra vez y hay que declararlo de nuevo."),
    origen)
}

# Capturas crudas que cada extractor necesita para dar cache hit. Las claves
# replican las que arma cada script (32:65; 33:47 y 33:76; 34:33; 35:26; 36:70);
# la RUTA la construye ruta_cache(), que sigue siendo el unico lugar que conoce
# la forma de la clave. Depende de las globales de config (ANIO_PROCESO, MAX_*),
# disponibles en tiempo de ejecucion igual que en con_cache().
# `corte` se propaga a ruta_cache(): antes esta funcion recibia solo el id y
# resolvia SIEMPRE por la global, de modo que la guarda medi­a desalineamiento
# contra su argumento `corte` y existencia de capturas contra CORTE_FECHA.
# Mientras coincidieran nadie lo notaba; cuando no, comparaba dos cortes sin ruido.
capturas_crudas_de_paso <- function(id, corte = NULL) {
  switch(as.character(id),
    "32" = ruta_cache("diputados", corte = corte),
    "33" = c(ruta_cache("periodo_legislativo", corte = corte),
             ruta_cache(sprintf("asistencia_nominal_%d", ANIO_PROCESO),
                        MAX_SESIONES_DETALLE, corte = corte)),
    "34" = ruta_cache(sprintf("votos_long_%d", ANIO_PROCESO), MAX_VOTACIONES_DETALLE,
                      corte = corte),
    "35" = ruta_cache(sprintf("proyectos_long_%d", ANIO_PROCESO), MAX_PROYECTOS_DETALLE,
                      corte = corte),
    # P-63: la captura del 36 es ahora el XML crudo bajo clave PROPIA. La anterior
    # (detalle_proyectos_<anio>) guardaba el derivado del parser, asi que solo
    # permitia reproducir los campos que el parser de ese dia conservo: con ella
    # la guarda prometia regenerar sin red algo que no podia. Sus .rds siguen en
    # 20_insumos/camara/ y no se borran (dato crudo inmutable), solo dejaron de
    # leerse; mismo criterio que los de asistencia_long tras el retiro del legacy.
    "36" = ruta_cache(sprintf("detalle_proyectos_xml_%d", ANIO_PROCESO), Inf,
                      corte = corte),
    # P-86: el 37 captura del SIL, que vive en otro host y por eso en otro
    # subdirectorio (enmienda 1 de P-66). La clave replica la del propio paso
    # (37:capturar_tramitacion); el tope es Inf porque el 37 no aplica cap propio.
    "37" = ruta_cache(sprintf("tramitacion_sil_%d", ANIO_PROCESO), Inf,
                      corte = corte, subdir = CRUDO_SENADO),
    stop(sprintf("capturas_crudas_de_paso: el paso %s no declara captura cruda.", id),
         call. = FALSE))
}

# ---- Guarda estructural del registro de pasos (P-93) ------------------------
# Un paso del pipeline queda registrado en cuatro sitios: PASOS y su campo
# `intermedios` (00_run_all.R), PASOS_EXTRACCION (derivada de PASOS, mismo
# archivo), INTERMEDIOS_PIPELINE y las ramas de capturas_crudas_de_paso()
# (ambas aqui). Nada obligaba a sincronizarlos: P-66 agrego el paso 37 tocando
# solo el primero, el sintoma tardo dos sesiones en aparecer y costo P-86.
# Esta guarda cierra la clase entera del defecto, no el caso: compara las cuatro
# estructuras y se detiene nombrando al paso huerfano y la estructura que le
# falta.
#
# Es ESTRUCTURAL y ESTATICA: solo lee objetos de R ya cargados en memoria. No
# toca el filesystem, no lee sellos, no llama a la red y no depende del corte.
# Por eso corre antes que cualquier otra guarda en run_all(): un pipeline mal
# registrado no debe llegar siquiera a mirar los sellos.
#
# Las ramas de capturas_crudas_de_paso() se enumeran desde `body()`, que expone
# los nombres de rama del switch en el arbol de sintaxis ya cargado. Es la unica
# forma de comprobar el sentido inverso (una rama que no corresponda a ningun
# paso) sin leer el archivo, que violaria el caracter estatico de la guarda.
#
# P-100: la llamada al switch se BUSCA en el cuerpo, no se toma por posicion.
# `body(...)[[2]]` asumia que el switch es la segunda expresion del cuerpo, cosa
# que deja de ser cierta en cuanto alguien antepone una linea (un log, una
# validacion de argumento, un `stopifnot`). Entonces `names()` sobre lo que no es
# el switch devuelve NULL o los nombres equivocados, `ids_cap` queda vacio y la
# guarda declara huerfanos a los 6 pasos que si estaban registrados: falso
# positivo que detiene run_all() en su entrada, y con el, el cron. Buscar la
# llamada es robusto a la forma del cuerpo y no cuesta nada, porque el AST ya
# esta en memoria.
# A2: la version de P-100 moria ante entradas que no sabia interpretar. Tres
# defectos medidos por el panel, con sus dos correcciones y una decision:
#  (D1) un simbolo vacio en el AST -- el fall-through `"32" = ,` del propio switch
#       de capturas, o cualquier `x[!f, , drop = FALSE]` -- reventaba al BINDEARLO
#       a una variable. El `tryCatch` no protegia nada porque la extraccion no
#       falla: falla la evaluacion del binding. Ahora se detecta por IDENTIDAD
#       contra `quote(expr = )`, sin binding intermedio, y se salta.
#  (D2) `base::switch(...)` no se reconocia y el mensaje afirmaba que la funcion
#       habia dejado de declarar sus capturas con un switch, que era falso. Ahora
#       se reconocen las TRES formas escribibles y ningun mensaje afirma una causa
#       que no se midio: se nombra lo que se encontro y lo que no se pudo decidir.
#  (decision) un `switch` dentro del cuerpo de una `function` anidada NO es la
#       declaracion de capturas, es codigo auxiliar de esa funcion. El recorrido
#       NO entra en cuerpos de `function`. Si el unico switch del cuerpo vive ahi,
#       eso cuenta como cero llamadas y falla ruidosamente.
#
# NINGUNA rama termina en silencio. Las cuatro salidas posibles son: la llamada
# encontrada; cero llamadas; mas de una; y al menos una construccion irresoluble
# (do.call con funcion no literal, o `switch` calificado con un namespace que no
# es base). Las tres ultimas son stop().

# Un argumento vacio del AST se detecta por identidad y SIN bindearlo: bindearlo
# es lo que dispara "el argumento X esta ausente" (D1).
argumento_vacio <- function(nodo, k) identical(nodo[[k]], quote(expr = ))

# Localiza la llamada que PORTA las ramas de despacho dentro del cuerpo de una
# funcion, recorriendo el AST en vez de indexar por posicion (P-100). Devuelve
# esa llamada: el llamador toma `names()` sobre ella. Para `do.call("switch",
# list(...))` devuelve el `list(...)`, cuyo `names()` tiene la misma forma que el
# de un `switch(...)` directo.
localizar_switch <- function(fn, nombre_fn) {
  hallazgos    <- list()
  irresolubles <- character(0)

  # Cabecera de una llamada: TRUE si es el simbolo `nm` pelado.
  es_simbolo <- function(x, nm) is.symbol(x) && identical(x, as.name(nm))

  recorrer <- function(nodo) {
    if (!is.call(nodo)) return(invisible(NULL))
    cab <- nodo[[1L]]

    # (0) Cuerpo de una `function` anidada: no se entra. Decision del encargo A2.
    if (es_simbolo(cab, "function")) return(invisible(NULL))

    # (1) switch(...) pelado.
    if (es_simbolo(cab, "switch")) {
      hallazgos[[length(hallazgos) + 1L]] <<- nodo

    # (2) base::switch(...) / base:::switch(...).
    } else if (is.call(cab) &&
               (es_simbolo(cab[[1L]], "::") || es_simbolo(cab[[1L]], ":::")) &&
               length(cab) == 3L && es_simbolo(cab[[3L]], "switch")) {
      if (es_simbolo(cab[[2L]], "base")) {
        hallazgos[[length(hallazgos) + 1L]] <<- nodo
      } else {
        irresolubles <<- c(irresolubles, sprintf(
          "switch calificado con un namespace que no es base: %s",
          paste(deparse(cab), collapse = "")))
      }

    # (3) do.call("switch", list(...)) con literales.
    } else if (es_simbolo(cab, "do.call")) {
      que  <- if ("what" %in% names(nodo)) nodo[["what"]] else if (length(nodo) >= 2L) nodo[[2L]] else NULL
      args <- if ("args" %in% names(nodo)) nodo[["args"]] else if (length(nodo) >= 3L) nodo[[3L]] else NULL
      es_switch <- (is.character(que) && length(que) == 1L && identical(que, "switch")) ||
                   es_simbolo(que, "switch")
      no_decidible <- !(is.character(que) && length(que) == 1L) && !is.symbol(que)
      if (es_switch) {
        if (!is.null(args) && is.call(args) && es_simbolo(args[[1L]], "list")) {
          hallazgos[[length(hallazgos) + 1L]] <<- args
        } else {
          irresolubles <<- c(irresolubles, sprintf(
            "do.call(\"switch\", ...) cuyos argumentos no son un list() literal: %s",
            paste(deparse(nodo), collapse = "")))
        }
      } else if (no_decidible || (is.symbol(que) && !es_simbolo(que, "switch"))) {
        irresolubles <<- c(irresolubles, sprintf(
          "do.call con funcion no literal, imposible decidir si despacha: %s",
          paste(deparse(nodo), collapse = "")))
      }
    }

    # Recorrido de los hijos. El argumento vacio se salta ANTES de tocarlo.
    for (k in seq_along(nodo)) {
      if (argumento_vacio(nodo, k)) next
      recorrer(nodo[[k]])
    }
    invisible(NULL)
  }

  recorrer(body(fn))

  encabezado <- sprintf("localizar_switch: la guarda del registro de pasos audita %s()", nombre_fn)
  if (length(irresolubles) > 0L)
    stop(sprintf(paste0(
      "%s y encontro %d construccion(es) que NO puede interpretar:\n%s\n",
      "  Ademas encontro %d llamada(s) de despacho reconocible(s). No se elige entre ",
      "lo reconocido y lo no interpretado: se detiene. Reescribe esa construccion en ",
      "una de las tres formas que la guarda reconoce (switch, base::switch, o ",
      "do.call(\"switch\", list(...))), o amplia la guarda."),
      encabezado, length(irresolubles),
      paste0("    - ", irresolubles, collapse = "\n"), length(hallazgos)), call. = FALSE)
  if (length(hallazgos) == 0L)
    stop(sprintf(paste0(
      "%s y NO encontro ninguna llamada de despacho en su cuerpo. Se buscaron las ",
      "tres formas reconocidas: switch(...), base::switch(...) y ",
      "do.call(\"switch\", list(...)); los cuerpos de `function` anidadas no se ",
      "inspeccionan, porque un switch ahi dentro no es la declaracion de capturas. ",
      "La guarda no puede auditar las ramas y no degrada a silencio."),
      encabezado), call. = FALSE)
  if (length(hallazgos) > 1L)
    stop(sprintf(paste0(
      "%s y encontro %d llamadas de despacho en su cuerpo; se esperaba exactamente ",
      "una. Elegir cual auditar seria adivinar: deja una sola, o cambia la guarda ",
      "para que sepa cual es la de las capturas."),
      encabezado, length(hallazgos)), call. = FALSE)
  hallazgos[[1L]]
}

verificar_registro_pasos <- function(pasos,
                                     excepciones = PASOS_SIN_INTERMEDIO,
                                     extraccion  = PASOS_EXTRACCION,
                                     intermedios = INTERMEDIOS_PIPELINE) {
  ids_pasos <- vapply(pasos, function(p) p$id, integer(1))
  ids_ext   <- vapply(extraccion, function(p) p$id, integer(1))
  esperados <- setdiff(ids_pasos, excepciones)

  # Ramas declaradas en el switch de capturas_crudas_de_paso(), desde el AST.
  ramas   <- names(localizar_switch(capturas_crudas_de_paso, "capturas_crudas_de_paso"))
  ids_cap <- suppressWarnings(as.integer(ramas[nzchar(ramas)]))
  ids_cap <- ids_cap[!is.na(ids_cap)]

  # Intermedios que cada paso declara producir (campo `intermedios` de PASOS).
  declarados <- lapply(pasos, function(p)
    if (is.null(p$intermedios)) character(0) else as.character(p$intermedios))
  names(declarados) <- as.character(ids_pasos)
  nombres_de <- function(id) {
    v <- declarados[[as.character(id)]]
    if (is.null(v)) character(0) else v
  }

  fallas <- character(0)

  # 1) Sentido directo: todo paso esperado, en las tres estructuras.
  for (id in esperados) {
    nom <- nombres_de(id)
    chk <- c(PASOS_EXTRACCION        = id %in% ids_ext,
             INTERMEDIOS_PIPELINE    = length(nom) > 0 && all(nom %in% intermedios),
             capturas_crudas_de_paso = id %in% ids_cap)
    if (all(chk)) next
    detalle <- if (length(nom) == 0)
      "su entrada de PASOS no declara el campo `intermedios`"
    else if (!all(nom %in% intermedios))
      sprintf("declara %s, que no esta en INTERMEDIOS_PIPELINE",
              paste(setdiff(nom, intermedios), collapse = ", "))
    else ""
    fallas <- c(fallas, sprintf(
      "  paso %d: NO registrado en %s. %s.%s",
      id, paste(names(chk)[!chk], collapse = ", "),
      if (any(chk)) paste("Si lo esta en", paste(names(chk)[chk], collapse = ", "))
      else "No lo esta en ninguna de las tres",
      if (nzchar(detalle)) paste0(" ", detalle, ".") else ""))
  }

  # 2) Sentido inverso: registrado en alguna estructura, ausente de PASOS.
  for (id in setdiff(ids_ext, ids_pasos))
    fallas <- c(fallas, sprintf(
      "  paso %d: esta en PASOS_EXTRACCION pero no existe en PASOS.", id))
  for (id in setdiff(ids_cap, ids_pasos))
    fallas <- c(fallas, sprintf(
      "  paso %d: tiene rama en capturas_crudas_de_paso() pero no existe en PASOS.", id))
  for (nm in setdiff(intermedios, unique(unlist(declarados))))
    fallas <- c(fallas, sprintf(
      "  intermedio '%s': esta en INTERMEDIOS_PIPELINE y ningun paso de PASOS lo declara.", nm))

  # 3) Coherencia de las excepciones: no existen, o estan registradas igual.
  for (id in setdiff(excepciones, ids_pasos))
    fallas <- c(fallas, sprintf(
      "  paso %d: figura en PASOS_SIN_INTERMEDIO pero no existe en PASOS.", id))
  for (id in intersect(excepciones, ids_pasos)) {
    donde <- c("PASOS_EXTRACCION", "capturas_crudas_de_paso",
               "el campo `intermedios` de PASOS")[
      c(id %in% ids_ext, id %in% ids_cap, length(nombres_de(id)) > 0)]
    if (length(donde) > 0)
      fallas <- c(fallas, sprintf(
        "  paso %d: declarado SIN intermedio, pero esta registrado en %s.",
        id, paste(donde, collapse = ", ")))
  }

  if (length(fallas) > 0)
    stop(sprintf(paste0(
      "verificar_registro_pasos: %d incoherencia(s) en el registro de pasos.\n%s\n",
      "  El registro es obligatorio por defecto: un paso nuevo debe entrar en\n",
      "  PASOS (con su campo `intermedios`) y en PASOS_EXTRACCION, ambos en\n",
      "  00_run_all.R, y en INTERMEDIOS_PIPELINE y capturas_crudas_de_paso(),\n",
      "  ambos en 10_utils/10_utils.R. Si el paso no produce intermedio sellado,\n",
      "  la exclusion es explicita: sumalo a PASOS_SIN_INTERMEDIO (00_run_all.R)."),
      length(fallas), paste(fallas, collapse = "\n")), call. = FALSE)

  invisible(TRUE)
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

  # 0) PRIMERA CORRIDA: no existe NINGUN archivo de intermedio en disco.
  # La condicion se mide con file.exists() sobre los 6 archivos, NO con
  # all(is.na(declarados)): `corte_declarado_por()` devuelve NA por tres causas
  # distintas -- ausente, presente sin sello, y presente corrupto -- y solo la
  # primera es "primera corrida". Usar el sello como proxy dejaria que un
  # intermedio ilegible entrara por esta rama y terminara descargando, que es
  # aflojar la guarda mas alla de lo que este arreglo necesita. Un intermedio
  # presente pero ilegible cae en la logica normal de desalineado, donde el
  # stop() sigue siendo correcto.
  # Este es el estado del runner: en un checkout fresco los intermedios estan
  # gitignorados, asi que no hay ninguno, y las capturas que la guarda exigia son
  # justamente las que esa corrida iba a crear.
  # P-77: el conteo NO alcanza para decidir. "Nunca hubo" y "habia y se borraron"
  # producen los dos n_en_disco == 0, y el segundo terminaba descargando el anno
  # completo por esta rama. El discriminante es un rastro en disco, medido con
  # file.exists() y no con ningun proxy: el directorio no sirve (existe en todo
  # checkout por .gitkeep) y el sello tampoco (no hay sello que leer si no hay
  # archivo).
  rutas_intermedios <- ruta_salidas("intermedios",
                                    paste0(INTERMEDIOS_PIPELINE, ".rds"))
  n_en_disco  <- sum(file.exists(rutas_intermedios))
  ruta_rastro <- ruta_salidas("intermedios", RASTRO_ARRANQUE)
  hay_rastro  <- file.exists(ruta_rastro)
  if (n_en_disco == 0 && !hay_rastro) {
    log_msg(sprintf(paste0("Primera corrida del corte %s: 0 de %d archivos de intermedio en ",
                           "disco y sin rastro de arranque previo. No hay nada que regenerar ni ",
                           "con que comparar; los pasos %s los crearan. El contrato temporal de ",
                           "la captura (P-74) sigue validando que la fecha de descarga honre el ",
                           "corte declarado."),
                    corte, length(INTERMEDIOS_PIPELINE),
                    paste(vapply(pasos, function(p) p$id, integer(1)), collapse = ", ")),
            origen = "guarda_intermedios")
    escribir_rastro_arranque(corte, "primera corrida: 0 intermedios en disco y sin rastro previo")
    log_msg(sprintf(paste0("Rastro de arranque escrito en %s. Desde ahora, 0 intermedios en esta ",
                           "copia significa 'los borraron', no 'primera corrida'."),
                    file.path("40_salidas/intermedios", RASTRO_ARRANQUE)),
            origen = "guarda_intermedios")
    return(invisible(FALSE))
  }
  # Copia que ya tenia intermedios cuando llego este arreglo: se adopta el rastro
  # retroactivamente. Sin esto el rastro solo existiria en copias nacidas despues
  # del fix, y en toda instalacion previa (incluida la del titular) un borrado de
  # los .rds seguiria leyendose como arranque: P-77 quedaria abierto justo donde
  # se reporto. Ocurre una sola vez por copia y no cambia ninguna decision de esta
  # corrida.
  if (n_en_disco > 0 && !hay_rastro) {
    escribir_rastro_arranque(corte, sprintf(
      "adopcion retroactiva: %d de %d intermedios ya estaban en disco",
      n_en_disco, length(INTERMEDIOS_PIPELINE)))
    log_msg(sprintf(paste0("Rastro de arranque ausente pero hay %d de %d intermedios en disco: ",
                           "esta copia ya corrio. Rastro escrito en %s (una sola vez)."),
                    n_en_disco, length(INTERMEDIOS_PIPELINE),
                    file.path("40_salidas/intermedios", RASTRO_ARRANQUE)),
            origen = "guarda_intermedios")
    hay_rastro <- TRUE
  }
  # Presentes pero ilegibles: se nombran, para que "desalineado" no tape "roto".
  ilegibles <- INTERMEDIOS_PIPELINE[file.exists(rutas_intermedios) & is.na(declarados)]
  if (length(ilegibles) > 0)
    log_msg(sprintf(paste0("%d de %d intermedios estan en disco pero no declaran corte ",
                           "(sin sello o ilegibles): %s. No entran por la rama de primera ",
                           "corrida; se tratan como desalineados."),
                    length(ilegibles), length(INTERMEDIOS_PIPELINE),
                    paste(ilegibles, collapse = ", ")),
            "WARN", "guarda_intermedios")

  # 1) Los 6 declaran el corte vigente: no hace nada y no imprime ruido.
  if (length(desalineados) == 0) return(invisible(FALSE))

  # 2) Solo se regenera desde la captura cruda ya versionada, jamas desde la red.
  # El corte se propaga a capturas_crudas_de_paso(): esta guarda mide
  # desalineamiento contra `corte`, asi que la existencia de capturas tiene que
  # medirse contra el MISMO corte y no contra la global.
  faltantes <- lapply(pasos, function(p) {
    cs <- capturas_crudas_de_paso(p$id, corte = corte); cs[!file.exists(cs)]
  })
  names(faltantes) <- vapply(pasos, function(p) p$ruta, character(1))
  faltantes <- faltantes[lengths(faltantes) > 0]
  if (length(faltantes) > 0) {
    # 2b) Hay intermedios en disco pero desalineados, y faltan las capturas del
    # corte. Es un estado ambiguo: puede ser una copia local atrasada (donde el
    # stop() es correcto y util) o el arranque de un corte nuevo con restos de
    # otro (donde descargar es lo esperado). No se adivina: se detiene, salvo que
    # la corrida lo haya autorizado EXPLICITAMENTE con una opcion nombrada.
    if (descarga_inicial_autorizada()) {
      log_msg(sprintf(paste0("Intermedios desalineados (%d de %d) y faltan %d captura(s) del ",
                             "corte %s, pero la descarga inicial esta AUTORIZADA (%s = TRUE): ",
                             "se deja seguir y los extractores las crearan."),
                      length(desalineados), length(INTERMEDIOS_PIPELINE),
                      length(unlist(faltantes, use.names = FALSE)), corte,
                      OPCION_DESCARGA_INICIAL),
              "WARN", "guarda_intermedios")
      # P-76: se consume ANTES de devolver, en el mismo sitio donde se registra la
      # autorizacion. Si quedara encendida, autorizar un caso autorizaria todo lo
      # que siguiera en esta misma sesion de run_all().
      consumir_descarga_inicial()
      return(invisible(FALSE))
    }
    # P-77: la primera linea cuenta el HECHO, no una suma de dos cosas distintas.
    # `desalineados` agrega dos estados -- el intermedio existe y declara otro
    # corte, y el intermedio no existe -- y decir "6 de 6 no corresponden al corte
    # vigente" cuando no hay ninguno en disco afirma un conteo mayor que el numero
    # de archivos que existen. Con los 6 presentes la cifra es la de siempre.
    presentes       <- INTERMEDIOS_PIPELINE[file.exists(rutas_intermedios)]
    desal_presentes <- intersect(desalineados, presentes)
    ausentes        <- setdiff(INTERMEDIOS_PIPELINE, presentes)
    linea_estado <- if (length(ausentes) == 0)
      sprintf("run_all: %d de %d intermedios NO corresponden al corte vigente (%s): %s.\n",
              length(desal_presentes), length(INTERMEDIOS_PIPELINE), corte,
              paste(desal_presentes, collapse = ", "))
    else if (length(desal_presentes) == 0)
      sprintf(paste0("run_all: no hay ningun intermedio en disco: faltan los %d de %d (%s). ",
                     "El corte vigente es %s.\n"),
              length(ausentes), length(INTERMEDIOS_PIPELINE),
              paste(ausentes, collapse = ", "), corte)
    else
      sprintf(paste0("run_all: %d de %d intermedios estan en disco y NO corresponden al corte ",
                     "vigente (%s): %s. Otros %d no existen: %s.\n"),
              length(desal_presentes), length(INTERMEDIOS_PIPELINE), corte,
              paste(desal_presentes, collapse = ", "),
              length(ausentes), paste(ausentes, collapse = ", "))
    # La linea que distingue "los borraron" de "primera corrida".
    nota_borrados <- if (n_en_disco == 0)
      sprintf(paste0("  Esto NO es un arranque: hay 0 de %d intermedios en disco, pero el rastro ",
                     "de arranque (%s) esta presente, asi que esta copia ya corrio y los ",
                     "intermedios se borraron. En un clon fresco no habria rastro y la corrida ",
                     "habria seguido sin detenerse.\n"),
              length(INTERMEDIOS_PIPELINE),
              file.path("40_salidas/intermedios", RASTRO_ARRANQUE))
    else ""
    # P-93: el directorio se DERIVA de las rutas que devolvio
    # capturas_crudas_de_paso(), no se escribe a mano. Estaba fijo en
    # "20_insumos/camara/" y mentia desde que existe el paso 37, cuya captura
    # vive en 20_insumos/senado/ (el SIL esta en otro host). El nombre del
    # archivo y el source() de recuperacion siempre fueron correctos; lo que
    # mandaba a mirar la carpeta equivocada era esta linea.
    dirs_faltantes <- unique(dirname(unlist(faltantes, use.names = FALSE)))
    dirs_faltantes <- sub("^.*/(20_insumos/[^/]+)$", "\\1", dirs_faltantes)
    etiqueta_dirs  <- paste0(paste(sort(dirs_faltantes), collapse = "/ y "), "/")
    stop(sprintf(paste0(
      "%s",
      "%s",
      "  No se pueden regenerar: falta la captura cruda de ese corte en ",
      "%s (%d archivo(s)): %s.\n",
      "  La regeneracion automatica no descarga nada de la red (invariante del ",
      "proyecto), asi que este paso no puede resolverse solo.\n",
      "  Corre CON RED, desde la raiz del proyecto y en este orden:\n%s\n",
      "  y despues reintenta: source(\"00_run_all.R\"); run_all()\n",
      "  O, si lo que quieres es empezar este corte desde cero descargando, ",
      "declara options(%s = TRUE) antes de la corrida."),
      linea_estado,
      nota_borrados,
      etiqueta_dirs,
      length(unlist(faltantes, use.names = FALSE)),
      paste(basename(unlist(faltantes, use.names = FALSE)), collapse = ", "),
      paste(sprintf("    source(\"%s\")", names(faltantes)), collapse = "\n"),
      OPCION_DESCARGA_INICIAL),
      call. = FALSE)
  }

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
    # P-101: el subdirectorio NO se nombra aqui. La rama de arriba puede derivarlo
    # de las rutas que faltan; esta no, porque lo que reporta son nombres de
    # intermedio y el vector de capturas esta vacio por construccion. Decia
    # "20_insumos/camara/" y mentia para toda captura del paso 37, que vive en
    # 20_insumos/senado/. Se generaliza a 20_insumos/, que es cierto para todos los
    # casos: el mensaje de una guarda es parte de su contrato, y vale mas ser menos
    # especifico que ser especificamente falso.
    stop(sprintf(paste0("guarda_intermedios: tras regenerar, %d de %d intermedios siguen ",
                        "desalineados con el corte %s (%s). No se continua; revisa la ",
                        "captura cruda de 20_insumos/."),
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
