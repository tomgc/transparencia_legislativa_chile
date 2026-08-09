# =============================================================================
# 50_verificar_p74_acto_b.R
# -----------------------------------------------------------------------------
# Proposito: compuertas del §3 y verificacion de criterios del §4 del encargo
#            P-74 acto (b). Lee los archivos REALES; ninguna respuesta se toma
#            del log del acto (a) ni del encargo.
#
# Invariantes que hace cumplir (encargo §2):
#   - Cero red: camara.refrescar = FALSE y contador instrumentado, reportado.
#   - 20_insumos/camara/ inmutable: md5 de las 8 capturas al abrir y al cerrar.
#   - Fallo ruidoso: stop() ante supuesto no cumplido; sin try(silent).
#   - Todo conteo con su denominador, contado en la misma corrida.
#   - Escribe SOLO en el scratchpad de la sesion (prueba de G5); nunca en el repo.
#
# Uso:  Rscript 50_documentacion/andamios/50_verificar_p74_acto_b.R [fase]
#       fase = "compuertas" (default) | "criterios"
# Autor: Claude Code (encargo P-74 acto (b), sesion 18)
# Creado: 2026-08-08
# =============================================================================

options(camara.refrescar = FALSE)

source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
instalar_si_falta(c("httr", "xml2", "here", "fs", "jsonlite", "tools"))
ROOT <- obtener_raiz_proyecto()
source(file.path(ROOT, "10_utils", "10_configuracion.R"))

FASE <- if (length(commandArgs(TRUE))) commandArgs(TRUE)[1] else "compuertas"

# ---- Contador de red --------------------------------------------------------
CONTADOR_HTTP <- new.env(parent = emptyenv())
CONTADOR_HTTP$n <- 0L
for (par in list(c("httr", "GET"), c("httr", "POST"), c("httr", "RETRY"),
                 c("curl", "curl_fetch_memory"))) {
  if (requireNamespace(par[1], quietly = TRUE))
    trace(par[2], where = asNamespace(par[1]), print = FALSE,
          tracer = quote(CONTADOR_HTTP$n <- CONTADOR_HTTP$n + 1L))
}

titulo <- function(x) cat("\n\n=====", x, "=====\n")
subt   <- function(x) cat("\n--- ", x, "\n", sep = "")
linea  <- function(fmt, ...) cat(sprintf(fmt, ...), "\n", sep = "")

# Imprime un rango de lineas de un archivo con su numero: asi la "salida literal
# de la lectura" que exige el §3 es reproducible y no una transcripcion.
mostrar <- function(ruta, desde, hasta) {
  ln <- readLines(ruta, warn = FALSE)
  if (hasta > length(ln))
    stop(sprintf("mostrar: %s tiene %d lineas, se pidio hasta %d.",
                 basename(ruta), length(ln), hasta), call. = FALSE)
  for (k in seq(desde, hasta)) linea("  %4d| %s", k, ln[k])
}

# Barrido de los .R del pipeline: la raiz y los dos directorios de codigo, con
# list.files(), nunca nombrados a mano.
archivos_r <- function() {
  a <- c(list.files(ROOT, "[.]R$", full.names = TRUE),
         list.files(file.path(ROOT, "10_utils"), "[.]R$", full.names = TRUE),
         list.files(file.path(ROOT, "30_procesamiento"), "[.]R$", full.names = TRUE))
  sort(unique(a[file.exists(a)]))
}

# Universo del nodo ANTES de cualquier filtro, medido sobre la captura cruda.
# Vive fuera de las fases porque las dos lo necesitan y son procesos R distintos:
# si "criterios" heredara el numero de "compuertas" estaria citando otra corrida.
universo_nodo <- function() {
  ruta <- normalizePath(ruta_cache(sprintf("detalle_proyectos_xml_%d", ANIO_PROCESO), Inf),
                        mustWork = TRUE)
  cap <- readRDS(ruta)
  n_ev <- 0L; n_bol <- 0L; exc <- list()
  for (i in seq_len(nrow(cap))) {
    if (is.na(cap$xml[i])) next
    vs <- xml2::xml_find_all(xml2::xml_root(xml2::read_xml(cap$xml[i])),
                             "./Votaciones/VotacionProyectoLey")
    if (length(vs) == 0) next
    n_bol <- n_bol + 1L; n_ev <- n_ev + length(vs)
    f <- substr(vapply(vs, function(v) texto_nodo(v, "./Fecha") %||% NA_character_,
                       character(1)), 1, 10)
    ids <- vapply(vs, function(v) texto_nodo(v, "./Id") %||% NA_character_, character(1))
    for (j in which(!is.na(f) & f > CORTE_FECHA))
      exc[[length(exc) + 1L]] <- list(boletin = cap$boletin[i], id = ids[j], fecha = f[j])
  }
  list(ruta = ruta, boletines = nrow(cap), eventos = n_ev, bol_con_nodo = n_bol,
       excesos = exc)
}

DIR_CAM <- ruta_insumos("camara")
md5_de_dir <- function(dir, patron) {
  fs <- sort(list.files(dir, patron, full.names = TRUE))
  stats::setNames(vapply(fs, function(f) unname(tools::md5sum(f)), character(1)),
                  basename(fs))
}

if (identical(FASE, "compuertas")) {

# =============================================================================
# G1. Anatomia de con_cache()
# =============================================================================
titulo("G1. Anatomia de con_cache()")
RUTA_UTILS <- file.path(ROOT, "10_utils", "10_utils.R")
linea("Archivo: %s", RUTA_UTILS)
ln_utils <- readLines(RUTA_UTILS, warn = FALSE)
ini_cc <- grep("^con_cache <- function", ln_utils)
if (length(ini_cc) != 1)
  stop(sprintf("G1: se esperaba 1 definicion de con_cache, hay %d.", length(ini_cc)),
       call. = FALSE)
# El cierre de la funcion es la primera linea que es exactamente "}" despues.
fin_cc <- ini_cc + which(ln_utils[(ini_cc + 1):length(ln_utils)] == "}")[1]
linea("Definicion de con_cache(): lineas %d-%d (%d lineas)", ini_cc, fin_cc,
      fin_cc - ini_cc + 1)
linea("Firma exacta: %s", trimws(ln_utils[ini_cc]))
subt("Cuerpo literal")
mostrar(RUTA_UTILS, ini_cc, fin_cc)

l_desc <- ini_cc - 1 + grep("fn_descarga\\(\\)", ln_utils[ini_cc:fin_cc])
l_escr <- ini_cc - 1 + grep("escribir_atomico", ln_utils[ini_cc:fin_cc])
linea("\nPunto de DESCARGA : linea %s -> %s",
      paste(l_desc, collapse = ", "), trimws(ln_utils[l_desc[1]]))
linea("Punto de ESCRITURA: linea %s -> %s",
      paste(l_escr, collapse = ", "), trimws(ln_utils[l_escr[1]]))
linea("Ambos dentro de con_cache(): %s (rango %d-%d)",
      all(c(l_desc, l_escr) >= ini_cc & c(l_desc, l_escr) <= fin_cc), ini_cc, fin_cc)
linea("Lineas entre descarga y escritura: %d", l_escr[1] - l_desc[1] - 1L)

subt("corte_para_clave(): de donde sale la clave")
ini_cpc <- grep("^corte_para_clave <- function", ln_utils)
fin_cpc <- ini_cpc + which(ln_utils[(ini_cpc + 1):length(ln_utils)] == "}")[1]
mostrar(RUTA_UTILS, ini_cpc, fin_cpc)
linea("Menciona Sys.Date() en su cuerpo: %s",
      any(grepl("Sys.Date", ln_utils[ini_cpc:fin_cpc], fixed = TRUE)))
linea("Menciona CORTE_FECHA en su cuerpo: %s",
      any(grepl("CORTE_FECHA", ln_utils[ini_cpc:fin_cpc], fixed = TRUE)))

# =============================================================================
# G2. Todos los llamadores de con_cache()
# =============================================================================
titulo("G2. Invocaciones de con_cache() en el pipeline")
ARCH_R <- archivos_r()
linea("Archivos .R barridos con list.files() (contados): %d", length(ARCH_R))
linea("  %s", paste(basename(ARCH_R), collapse = ", "))
subt("Toda linea que menciona con_cache, con archivo, linea y rol")
n_def <- 0L; n_inv <- 0L; n_com <- 0L
for (f in ARCH_R) {
  ln <- readLines(f, warn = FALSE)
  for (k in grep("con_cache", ln)) {
    es_com <- grepl("^\\s*#", ln[k])
    es_def <- grepl("^con_cache <- function", ln[k])
    rol <- if (es_com) "[coment]" else if (es_def) "[DEFINE]" else "[INVOCA]"
    if (es_com) n_com <- n_com + 1L else if (es_def) n_def <- n_def + 1L else n_inv <- n_inv + 1L
    linea("  %-34s :%-4d %-9s %s", basename(f), k, rol, trimws(substr(ln[k], 1, 84)))
  }
}
linea("\nDefiniciones: %d | Invocaciones en codigo: %d | Menciones en comentario: %d",
      n_def, n_inv, n_com)

# =============================================================================
# G3. Estado de las capturas existentes
# =============================================================================
titulo("G3. Estado de las capturas de 20_insumos/camara/")
linea("Directorio: %s", normalizePath(DIR_CAM, mustWork = TRUE))
CAPTURAS <- sort(list.files(DIR_CAM, "[.]rds$", full.names = TRUE))
linea("Capturas .rds encontradas (contadas): %d", length(CAPTURAS))
CLAVES_REGISTRO <- c("descarga_fecha", "descargado_en", "captura_fecha",
                     "fecha_descarga", "registro_captura")
con_registro <- 0L
for (f in CAPTURAS) {
  obj <- readRDS(f)
  at <- attributes(obj)
  subt(basename(f))
  linea("  md5       : %s", unname(tools::md5sum(f)))
  linea("  class     : %s", paste(class(obj), collapse = ", "))
  linea("  nrow      : %s", if (is.data.frame(obj)) nrow(obj) else NA_integer_)
  linea("  names()   : %s", paste(names(obj), collapse = ", "))
  linea("  attributes(): %s", paste(names(at), collapse = ", "))
  hay <- intersect(names(at), CLAVES_REGISTRO)
  # Tambien se busca en los nombres de columna: el registro podria venir como
  # columna y no como atributo. Se busca en AMBOS sitios, no en uno.
  hay_col <- intersect(names(obj), CLAVES_REGISTRO)
  linea("  registro de fecha de descarga: atributo=%s columna=%s",
        if (length(hay)) paste(hay, collapse = ",") else "NO",
        if (length(hay_col)) paste(hay_col, collapse = ",") else "NO")
  if (length(hay) || length(hay_col)) con_registro <- con_registro + 1L
}
linea("\nCapturas con registro de fecha de descarga: %d de %d",
      con_registro, length(CAPTURAS))
if (con_registro > 0)
  stop("G3: alguna captura ya trae registro; el diseno de (C) cambia. Reportar antes de seguir.",
       call. = FALSE)

# =============================================================================
# G4. Punto de derivacion del nodo en el paso 36
# =============================================================================
titulo("G4. Donde el 36 construye el list-col y donde calcula n_votaciones")
RUTA_36 <- file.path(ROOT, "30_procesamiento", "36_extraer_detalle_proyectos.R")
linea("Archivo: %s", RUTA_36)
ln36 <- readLines(RUTA_36, warn = FALSE)
ini_dd <- grep("^derivar_detalle <- function", ln36)
fin_dd <- ini_dd + which(ln36[(ini_dd + 1):length(ln36)] == "}")[1]
linea("derivar_detalle(): lineas %d-%d", ini_dd, fin_dd)
subt("Cuerpo literal")
mostrar(RUTA_36, ini_dd, fin_dd)
l_parse <- grep("parsear_contenido_proyecto", ln36)
l_nvot  <- grep("n_votaciones\\s*=\\s*nrow", ln36)
l_lcol  <- grep("votaciones\\s*=\\s*list\\(", ln36)
linea("\nParseo del contenido       : linea(s) %s", paste(l_parse, collapse = ", "))
linea("Calculo de n_votaciones    : linea(s) %s -> %s",
      paste(l_nvot, collapse = ", "), trimws(ln36[l_nvot[1]]))
linea("Construccion del list-col  : linea(s) %s -> %s",
      paste(l_lcol, collapse = ", "), trimws(ln36[l_lcol[1]]))
linea("n_votaciones se calcula ANTES del list-col: %s (%d < %d)",
      l_nvot[1] < l_lcol[1], l_nvot[1], l_lcol[1])
linea("Ambos dentro de la MISMA llamada a tibble(): %s",
      length(grep("^\\s*tibble\\(", ln36[ini_dd:l_nvot[1]])) > 0 &&
      l_nvot[1] < fin_dd && l_lcol[1] < fin_dd)
linea("Ambos derivan de la misma expresion 'cont$votaciones': %s",
      grepl("cont\\$votaciones", ln36[l_nvot[1]]) && grepl("cont\\$votaciones", ln36[l_lcol[1]]))

subt("Validacion existente que ata n_votaciones al list-col")
l_val <- grep("identical\\(detalle\\$n_votaciones", ln36)
if (length(l_val)) mostrar(RUTA_36, l_val[1], l_val[1] + 2)

# G4b. El evento en exceso, medido sobre la captura de ESTA corrida. Los
# comentarios del codigo nuevo citan una fecha de evento y una de descarga; sin
# esto se estarian heredando del log del acto (a), que el §0 prohibe citar.
subt("G4b: eventos posteriores al corte en la captura cruda, medidos ahora")
RUTA_XML <- normalizePath(ruta_cache(sprintf("detalle_proyectos_xml_%d", ANIO_PROCESO), Inf),
                          mustWork = TRUE)
cap <- readRDS(RUTA_XML)
linea("Captura leida: %s (%d filas)", basename(RUTA_XML), nrow(cap))
n_ev <- 0L; excesos <- list()
for (i in seq_len(nrow(cap))) {
  if (is.na(cap$xml[i])) next
  vs <- xml2::xml_find_all(xml2::xml_root(xml2::read_xml(cap$xml[i])),
                           "./Votaciones/VotacionProyectoLey")
  if (length(vs) == 0) next
  f <- substr(vapply(vs, function(v) texto_nodo(v, "./Fecha") %||% NA_character_,
                     character(1)), 1, 10)
  ids <- vapply(vs, function(v) texto_nodo(v, "./Id") %||% NA_character_, character(1))
  n_ev <- n_ev + length(vs)
  k <- which(!is.na(f) & f > CORTE_FECHA)
  for (j in k) excesos[[length(excesos) + 1L]] <-
    list(boletin = cap$boletin[i], id = ids[j], fecha = f[j])
}
linea("Eventos del nodo en la captura cruda (contados): %d", n_ev)
linea("Eventos con fecha > %s (contados): %d de %d", CORTE_FECHA, length(excesos), n_ev)
for (e in excesos)
  linea("  boletin %s | votacion_id %s | fecha %s", e$boletin, e$id, e$fecha)

# =============================================================================
# G5. Persistencia de atributos (empirica, no por expectativa)
# =============================================================================
titulo("G5. escribir_atomico() + readRDS: conservan atributos de R?")
TMP <- Sys.getenv("P74_TMP")
if (!nzchar(TMP)) stop("G5: falta la variable de entorno P74_TMP (directorio de prueba).",
                       call. = FALSE)
if (!dir.exists(TMP)) stop(sprintf("G5: el directorio de prueba '%s' no existe.", TMP),
                           call. = FALSE)
linea("Directorio de prueba (fuera del repo): %s", TMP)

# La prueba cubre TODOS los tipos de objeto que hay hoy en 20_insumos/camara/,
# no solo data.frame: el 32 devuelve character y el 33 devuelve list, y sobre
# esos objetos tambien se va a colgar el registro en produccion.
TIPOS_EN_CAMARA <- sort(unique(vapply(CAPTURAS, function(f) class(readRDS(f))[1], character(1))))
linea("Tipos de objeto presentes en 20_insumos/camara/ (contados sobre %d capturas): %s",
      length(CAPTURAS), paste(TIPOS_EN_CAMARA, collapse = ", "))
MUESTRAS <- list(
  data.frame = data.frame(a = 1:3, b = letters[1:3], stringsAsFactors = FALSE),
  character  = c("<xml>uno</xml>", "<xml>dos</xml>"),
  list       = list(id = "42", nombre = "periodo", inicio = "2026-03-11"))
linea("Tipos probados en G5 (contados): %d -> %s",
      length(MUESTRAS), paste(names(MUESTRAS), collapse = ", "))
faltan <- setdiff(TIPOS_EN_CAMARA, c(names(MUESTRAS), "tbl_df"))
if (length(faltan) > 0)
  stop(sprintf("G5: hay tipos en 20_insumos/camara/ sin probar: %s.",
               paste(faltan, collapse = ", ")), call. = FALSE)
todos_ok <- TRUE
for (nm in names(MUESTRAS)) {
  prueba <- MUESTRAS[[nm]]
  attr(prueba, "captura") <- list(descarga_fecha = "2026-08-08",
                                  corte_fecha = CORTE_FECHA, escape = FALSE)
  ruta_p <- file.path(TMP, sprintf("g5_prueba_%s.rds", nm))
  escribir_atomico(prueba, ruta_p, function(o, r) saveRDS(o, r))
  releido <- readRDS(ruta_p)
  at <- attr(releido, "captura")
  ok <- !is.null(at) && identical(attr(prueba, "captura"), at) && identical(prueba, releido)
  todos_ok <- todos_ok && ok
  linea("  %-11s class=%-10s atributo releido: %-28s identical: %s",
        nm, class(MUESTRAS[[nm]])[1],
        if (is.null(at)) "NULL (NO SE CONSERVA)" else paste(names(at), collapse = ","), ok)
}
linea("Los %d tipos conservan el atributo identico: %s", length(MUESTRAS), todos_ok)
if (!todos_ok)
  stop("G5: escribir_atomico/readRDS NO conservan atributos en algun tipo; el registro no puede ser atributo.",
       call. = FALSE)

subt("Contraprueba: el atributo sobrevive tambien dentro de con_cache()?")
# con_cache escribe con el MISMO escritor (10_utils.R:237), asi que la prueba de
# arriba cubre su camino de escritura. Se verifica que sea el mismo escritor.
linea("con_cache usa escribir_atomico con saveRDS: %s",
      any(grepl("escribir_atomico\\(obj, ruta, function\\(o, r\\) saveRDS", ln_utils)))

# =============================================================================
# G6. Linea base de neutralidad (md5 de los JSON publicados)
# =============================================================================
titulo("G6. Linea base de los artefactos publicados")
ARCH_JSON <- c(list.files(ruta_json(), "[.]json$", full.names = TRUE),
               list.files(ruta_json_perfiles(), "[.]json$", full.names = TRUE))
linea("Directorios: %s y %s", ruta_json(), ruta_json_perfiles())
linea("Artefactos JSON encontrados (contados): %d", length(ARCH_JSON))
md5_json <- stats::setNames(
  vapply(ARCH_JSON, function(f) unname(tools::md5sum(f)), character(1)),
  vapply(ARCH_JSON, function(f) sub(paste0("^", ruta_salidas("json"), "/"), "", f), character(1)))
ruta_base <- file.path(TMP, "g6_linea_base_json.rds")
saveRDS(md5_json, ruta_base)
linea("Linea base guardada FUERA del repo: %s", ruta_base)
# La copia contra la que compara C10 la produce ESTE script, no una mano fuera de
# banda: si la copiara alguien mas, C10 podria estar comparando contra un estado
# ya contaminado y no habria forma de notarlo (hallazgo del agente 2 del panel).
BASE_DIR <- file.path(TMP, "base_json")
unlink(BASE_DIR, recursive = TRUE); dir.create(file.path(BASE_DIR, "perfiles"), recursive = TRUE)
for (f in ARCH_JSON)
  file.copy(f, file.path(BASE_DIR, sub(paste0("^", ruta_salidas("json"), "/"), "", f)),
            overwrite = TRUE)
linea("Copia de la linea base escrita por el script: %d de %d artefactos",
      length(list.files(BASE_DIR, "[.]json$", recursive = TRUE)), length(ARCH_JSON))
# docs/data es lo que GitHub Pages publica realmente; el 39 copia ahi. C10 tiene
# que mirarlo tambien, o un desajuste de esa copia pasaria invisible.
DOCS <- file.path(ROOT, "docs", "data")
ARCH_DOCS <- list.files(DOCS, "[.]json$", recursive = TRUE, full.names = TRUE)
BASE_DOCS <- file.path(TMP, "base_docs")
unlink(BASE_DOCS, recursive = TRUE); dir.create(file.path(BASE_DOCS, "perfiles"), recursive = TRUE)
for (f in ARCH_DOCS)
  file.copy(f, file.path(BASE_DOCS, sub(paste0("^", DOCS, "/"), "", f)), overwrite = TRUE)
linea("Linea base de docs/data (lo publicado): %d artefactos", length(ARCH_DOCS))
linea("md5 distintos en la linea base: %d de %d artefactos",
      length(unique(md5_json)), length(md5_json))
linea("Ejemplos:")
for (k in seq_len(min(3, length(md5_json))))
  linea("  %-46s %s", names(md5_json)[k], md5_json[[k]])

# Linea base de las capturas crudas (invariante 2: md5 al abrir y al cerrar).
md5_cap <- md5_de_dir(DIR_CAM, "[.]rds$")
saveRDS(md5_cap, file.path(TMP, "g3_linea_base_capturas.rds"))
linea("\nLinea base de capturas crudas guardada: %d archivos", length(md5_cap))

titulo("Contador de red")
linea("Llamadas HTTP interceptadas: %d", CONTADOR_HTTP$n)

}  # fin fase compuertas

if (identical(FASE, "pipeline")) {
# El contador de red tiene que vivir EN EL PROCESO que corre el pipeline. Correr
# run_all() en otro Rscript y contar aqui certificaria la sesion equivocada: el
# "0" seria del verificador, no de la corrida (hallazgo del agente 2 del panel).
titulo("run_all() completo, instrumentado en este mismo proceso")
source(file.path(ROOT, "00_run_all.R"), chdir = TRUE)
run_all()
titulo("Contador de red del pipeline")
linea("Llamadas HTTP durante run_all() (mismo proceso, trace instalado antes): %d",
      CONTADOR_HTTP$n)
}

if (identical(FASE, "criterios")) {

TMP <- Sys.getenv("P74_TMP")
if (!nzchar(TMP) || !dir.exists(TMP))
  stop("criterios: falta P74_TMP o el directorio no existe.", call. = FALSE)

# =============================================================================
# C2/C3/C4. La guarda de escritura, en sus tres caminos
# =============================================================================
# Se ejercita el camino REAL: con_cache() -> guarda_captura_en_corte() ->
# fn_descarga() -> registrar_captura() -> escribir_atomico(). Lo unico que se
# redirige es ruta_insumos(), para no escribir capturas de prueba dentro de
# 20_insumos/camara/ (invariante 2). La guarda, el registro y el escritor son
# los de produccion, sin mock.
titulo("C2/C3/C4. Guarda de escritura: los tres caminos")
ruta_insumos_real <- ruta_insumos
CORTE_REAL <- CORTE_FECHA
ruta_insumos <<- function(...) file.path(TMP, ...)
# El directorio que se limpia tiene que ser EXACTAMENTE el que con_cache va a
# usar (ruta_insumos("camara")). Limpiar otro deja los .rds de la corrida
# anterior, con_cache toma la rama de cache hit y la guarda no se ejerce: la
# prueba pasaria sin haber probado nada. Ocurrio en la corrida previa.
DIR_CACHE_PRUEBA <- ruta_insumos("camara")
unlink(DIR_CACHE_PRUEBA, recursive = TRUE)
dir.create(DIR_CACHE_PRUEBA, showWarnings = TRUE, recursive = TRUE)
linea("ruta_insumos() redirigido a: %s", DIR_CACHE_PRUEBA)
linea("Directorio de cache de prueba vaciado: %d .rds presentes al empezar",
      length(list.files(DIR_CACHE_PRUEBA, "[.]rds$")))

descargas <- new.env(parent = emptyenv()); descargas$n <- 0L
fn_falsa <- function() {
  descargas$n <- descargas$n + 1L
  data.frame(x = 1:2, y = c("a", "b"), stringsAsFactors = FALSE)
}
archivos_prueba <- function() list.files(DIR_CACHE_PRUEBA, "[.]rds$")

# ---- C2: corte retrocedido -> la guarda DEBE detener -------------------------
subt("C2: CORTE_FECHA retrocedido (descarga posterior al corte), sin escape")
CORTE_FECHA <<- format(Sys.Date() - 5, "%Y-%m-%d")
options(camara.permitir_captura_fuera_de_corte = NULL)
descargas$n <- 0L
antes <- archivos_prueba()
res_c2 <- tryCatch({ con_cache("prueba_c2", fn_falsa, tope = Inf, origen = "prueba"); "SIN STOP" },
                   error = function(e) conditionMessage(e))
linea("CORTE_FECHA de prueba: %s | hoy: %s", CORTE_FECHA, format(Sys.Date(), "%Y-%m-%d"))
linea("Resultado: %s", if (identical(res_c2, "SIN STOP")) "NO se detuvo (FALLA)" else "stop() disparado")
linea("Llamadas a fn_descarga: %d (debe ser 0: la guarda va ANTES de la descarga)", descargas$n)
linea("Archivos creados: %d de %d antes -> %d despues",
      length(archivos_prueba()) - length(antes), length(antes), length(archivos_prueba()))
subt("Mensaje literal del stop()")
cat(res_c2, "\n")
C2_OK <- !identical(res_c2, "SIN STOP") && descargas$n == 0L &&
         length(archivos_prueba()) == length(antes) &&
         grepl("CORTE_FECHA", res_c2) && grepl("Opcion 1", res_c2)

# ---- C3: descarga dentro del corte -> la guarda NO debe detener --------------
subt("C3: corte en el futuro (descarga dentro del corte)")
CORTE_FECHA <<- format(Sys.Date() + 5, "%Y-%m-%d")
descargas$n <- 0L
obj_c3 <- con_cache("prueba_c3", fn_falsa, tope = Inf, origen = "prueba")
ruta_c3 <- file.path(DIR_CACHE_PRUEBA,
                     sprintf("%s_prueba_c3_tope-inf.rds", gsub("-", "", CORTE_FECHA)))
linea("CORTE_FECHA de prueba: %s | hoy: %s", CORTE_FECHA, format(Sys.Date(), "%Y-%m-%d"))
linea("Llamadas a fn_descarga: %d (debe ser 1)", descargas$n)
linea("Archivo escrito: %s (existe: %s)", basename(ruta_c3), file.exists(ruta_c3))
est_c3 <- estado_temporal_captura(ruta_c3)
linea("Registro en disco: estado=%s descarga=%s corte=%s escape=%s",
      est_c3$estado, est_c3$descarga_fecha, est_c3$corte_fecha, est_c3$escape)
C3_OK <- descargas$n == 1L && file.exists(ruta_c3) &&
         identical(est_c3$estado, "dentro_de_corte") && identical(est_c3$escape, FALSE)

# ---- C4: escape declarado -> escribe, pero marcado ---------------------------
subt("C4: escape explicito")
linea("Default de la opcion sin fijarla: %s (debe ser FALSE)",
      as.character(escape_captura_declarado()))
C4_default <- identical(escape_captura_declarado(), FALSE)
CORTE_FECHA <<- format(Sys.Date() - 5, "%Y-%m-%d")
options(camara.permitir_captura_fuera_de_corte = TRUE)
descargas$n <- 0L
obj_c4 <- con_cache("prueba_c4", fn_falsa, tope = Inf, origen = "prueba")
ruta_c4 <- file.path(DIR_CACHE_PRUEBA,
                     sprintf("%s_prueba_c4_tope-inf.rds", gsub("-", "", CORTE_FECHA)))
est_c4 <- estado_temporal_captura(ruta_c4)
linea("Con escape ON y corte retrocedido: fn_descarga llamada %d vez; archivo existe: %s",
      descargas$n, file.exists(ruta_c4))
linea("Registro en disco: estado=%s descarga=%s corte=%s escape=%s",
      est_c4$estado, est_c4$descarga_fecha, est_c4$corte_fecha, est_c4$escape)
linea("El escape deja marca distinguible en el registro: %s", identical(est_c4$escape, TRUE))

# El escape es de UN SOLO USO: tras consumirse, una segunda captura fuera de
# corte en la MISMA sesion debe volver a detenerse. Sin esto quedaria pegajoso y
# dejaria pasar todas las capturas siguientes de un run_all() (hallazgo del
# agente 3 del panel).
subt("C4b: el escape se consumio y no queda pegajoso")
escape_tras_uso <- escape_captura_declarado()
linea("Estado de la opcion inmediatamente despues de usarla: %s (debe ser FALSE)",
      as.character(escape_tras_uso))
descargas$n <- 0L
res_c4b <- tryCatch({ con_cache("prueba_c4b", fn_falsa, tope = Inf, origen = "prueba"); "SIN STOP" },
                    error = function(e) conditionMessage(e))
linea("Segunda captura fuera de corte sin volver a declarar el escape: %s",
      if (identical(res_c4b, "SIN STOP")) "NO se detuvo (FALLA)" else "stop() disparado")
linea("Llamadas a fn_descarga en el segundo intento: %d (debe ser 0)", descargas$n)
C4b_OK <- !identical(res_c4b, "SIN STOP") && descargas$n == 0L &&
          identical(escape_tras_uso, FALSE) &&
          identical(escape_captura_declarado(), FALSE)
C4_OK <- C4_default && identical(est_c4$escape, TRUE) &&
         identical(est_c4$estado, "fuera_de_corte") && C4b_OK

# ---- C4c: la rama de medianoche, que ningun otro criterio ejercita ----------
# verificar_cierre_de_descarga() solo actua cuando la descarga empieza un dia y
# termina otro. En una prueba sincrona ini == fin siempre, asi que esa mitad de
# la guarda quedaba sin cubrir (hallazgo del agente 2 del panel). Se la invoca
# directamente con ini != fin, en sus tres desenlaces.
subt("C4c: descarga que cruza la medianoche")
CORTE_FECHA <<- format(Sys.Date() - 1, "%Y-%m-%d")
options(camara.permitir_captura_fuera_de_corte = NULL)
r1 <- tryCatch({ verificar_cierre_de_descarga("prueba_noche", CORTE_FECHA,
                                              Sys.Date() - 1, Sys.Date(), FALSE, "prueba")
                 "SIN STOP" }, error = function(e) conditionMessage(e))
linea("  empieza dentro (%s), termina fuera (%s), sin escape -> %s",
      format(Sys.Date() - 1, "%Y-%m-%d"), format(Sys.Date(), "%Y-%m-%d"),
      if (identical(r1, "SIN STOP")) "NO se detuvo (FALLA)" else "stop() disparado")
r2 <- verificar_cierre_de_descarga("prueba_noche", format(Sys.Date() + 1, "%Y-%m-%d"),
                                   Sys.Date() - 1, Sys.Date(), FALSE, "prueba")
linea("  cruza la medianoche pero termina DENTRO del corte -> escape=%s (no detiene)",
      as.character(r2))
options(camara.permitir_captura_fuera_de_corte = TRUE)
r3 <- verificar_cierre_de_descarga("prueba_noche", CORTE_FECHA,
                                   Sys.Date() - 1, Sys.Date(), FALSE, "prueba")
linea("  termina fuera CON escape declarado -> escape=%s; opcion tras consumir: %s",
      as.character(r3), as.character(escape_captura_declarado()))
C4c_OK <- !identical(r1, "SIN STOP") && identical(r2, FALSE) && identical(r3, TRUE) &&
          identical(escape_captura_declarado(), FALSE)
linea("  C4c: %s", if (C4c_OK) "CUMPLE" else "NO CUMPLE")

# ---- Restaurar el entorno real ----------------------------------------------
options(camara.permitir_captura_fuera_de_corte = NULL)
CORTE_FECHA <<- CORTE_REAL
ruta_insumos <<- ruta_insumos_real
linea("\nEntorno restaurado: CORTE_FECHA=%s ; ruta_insumos -> %s",
      CORTE_FECHA, ruta_insumos("camara"))
linea("Escape tras restaurar (debe ser FALSE): %s", as.character(escape_captura_declarado()))

# =============================================================================
# C5. Inmutabilidad de las capturas existentes
# =============================================================================
titulo("C5. md5 de las capturas de 20_insumos/camara/")
base_cap <- readRDS(file.path(TMP, "g3_linea_base_capturas.rds"))
ahora_cap <- md5_de_dir(DIR_CAM, "[.]rds$")
linea("Capturas en la linea base: %d | ahora: %d", length(base_cap), length(ahora_cap))
iguales <- sum(names(base_cap) %in% names(ahora_cap) &
               base_cap[names(base_cap)] == ahora_cap[names(base_cap)])
linea("md5 identicos: %d de %d capturas de la linea base", iguales, length(base_cap))
prefijo_corte <- paste0(gsub("-", "", CORTE_FECHA), "_")
del_corte <- names(base_cap)[startsWith(names(base_cap), prefijo_corte)]
linea("De ellas, del corte vigente %s: %d de %d; md5 identicos: %d de %d",
      CORTE_FECHA, length(del_corte), length(base_cap),
      sum(base_cap[del_corte] == ahora_cap[del_corte]), length(del_corte))
C5_OK <- identical(base_cap, ahora_cap)
linea("identical(linea base, ahora): %s", C5_OK)

# =============================================================================
# C6. Reporte de estado de las capturas
# =============================================================================
titulo("C6. reportar_estado_capturas() sobre el corte vigente")
clases <- reportar_estado_capturas()
linea("\nClasificacion devuelta: %d capturas", length(clases))
for (s in ESTADOS_CAPTURA)
  linea("  %-16s: %d de %d", s, sum(clases == s), length(clases))
C6_OK <- length(clases) > 0 && all(clases == "sin_registro")
linea("Las capturas previas al contrato salen sin_registro y no dentro_de_corte: %s", C6_OK)

# =============================================================================
# C7/C8/C9. El filtro de (A) sobre el intermedio ya regenerado
# =============================================================================
titulo("C7/C8/C9. Efecto del filtro en proyectos_detalle.rds")
det <- readRDS(ruta_salidas("intermedios", "proyectos_detalle.rds"))
n_por_bol <- vapply(det$votaciones, nrow, integer(1))
# El denominador se MIDE sobre la captura cruda en esta misma corrida; heredarlo
# del acto (a) seria citar otro documento (hallazgo del agente 1 del panel).
U <- universo_nodo()
linea("Universo medido en esta corrida sobre %s:", basename(U$ruta))
linea("  eventos del nodo antes del filtro : %d", U$eventos)
linea("  boletines con nodo no vacio antes : %d de %d de la captura", U$bol_con_nodo, U$boletines)
linea("  eventos con fecha > %s (excesos)  : %d de %d", CORTE_FECHA, length(U$excesos), U$eventos)
for (e in U$excesos)
  linea("    boletin %s | votacion_id %s | fecha %s", e$boletin, e$id, e$fecha)
linea("Boletines en el intermedio      : %d", nrow(det))
linea("Eventos del nodo tras el filtro : %d de %d medidos en la captura", sum(n_por_bol), U$eventos)
linea("Eventos descartados             : %d de %d medidos en la captura",
      U$eventos - sum(n_por_bol), U$eventos)
linea("n_votaciones cuadra con el list-col: %s (suma n_votaciones = %d de %d)",
      identical(as.integer(det$n_votaciones), n_por_bol), sum(det$n_votaciones), U$eventos)
linea("Boletines con nodo no vacio     : %d de %d del intermedio (%d de %d antes del filtro)",
      sum(n_por_bol > 0), nrow(det), U$bol_con_nodo, U$bol_con_nodo)
linea("Boletines VACIADOS por el filtro: %d de %d con nodo antes del filtro",
      U$bol_con_nodo - sum(n_por_bol > 0), U$bol_con_nodo)
linea("Boletines sin nodo (nunca lo tuvieron): %d de %d del intermedio",
      sum(n_por_bol == 0), nrow(det))
# Contraste directo contra el corte: no debe quedar NINGUN evento posterior.
f_todas <- unlist(lapply(det$votaciones, function(d) substr(as.character(d$fecha), 1, 10)),
                  use.names = FALSE)
linea("Eventos con fecha > %s tras el filtro: %d de %d (debe ser 0)",
      CORTE_FECHA, sum(f_todas > CORTE_FECHA), length(f_todas))
linea("Fecha maxima del nodo tras el filtro : %s", max(f_todas))
C7_OK <- (U$eventos - sum(n_por_bol)) == length(U$excesos) &&
         sum(n_por_bol) == (U$eventos - length(U$excesos))
C8_OK <- identical(as.integer(det$n_votaciones), n_por_bol) &&
         sum(det$n_votaciones) == (U$eventos - length(U$excesos))
C9_OK <- (U$bol_con_nodo - sum(n_por_bol > 0)) == 0L && sum(f_todas > CORTE_FECHA) == 0L

# =============================================================================
# C10. Neutralidad del artefacto publicado
# =============================================================================
titulo("C10. Los 156 JSON contra la linea base de G6")
BASE <- file.path(TMP, "base_json")
sin_generado <- function(x) { if (!is.null(x$metadatos)) x$metadatos$generado <- NULL; x }
claves_de <- function(x, pre = "") {
  if (is.list(x)) {
    if (!is.null(names(x)) && any(nzchar(names(x))))
      unlist(lapply(names(x), function(nm)
        c(paste0(pre, nm), claves_de(x[[nm]], paste0(pre, nm, ".")))), use.names = FALSE)
    else unlist(lapply(x, function(e) claves_de(e, pre)), use.names = FALSE)
  } else character(0)
}
rel <- sub(paste0("^", ruta_salidas("json"), "/"), "",
           c(list.files(ruta_json(), "[.]json$", full.names = TRUE),
             list.files(ruta_json_perfiles(), "[.]json$", full.names = TRUE)))
linea("Artefactos comparados (contados): %d", length(rel))
iguales <- 0L; distintos <- character(0); claves_nuevas <- character(0); solo_generado <- 0L
for (r in rel) {
  f_new <- file.path(ruta_salidas("json"), r); f_old <- file.path(BASE, r)
  if (!file.exists(f_old)) { distintos <- c(distintos, paste0(r, " (nuevo)")); next }
  a <- jsonlite::fromJSON(f_old, simplifyVector = FALSE)
  b <- jsonlite::fromJSON(f_new, simplifyVector = FALSE)
  if (identical(a, b)) iguales <- iguales + 1L
  else if (identical(sin_generado(a), sin_generado(b))) { iguales <- iguales + 1L
    solo_generado <- solo_generado + 1L }
  else distintos <- c(distintos, r)
  claves_nuevas <- unique(c(claves_nuevas, setdiff(claves_de(b), claves_de(a))))
}
linea("Identicos excluido metadatos.generado: %d de %d", iguales, length(rel))
linea("  de ellos, que solo difieren en metadatos.generado: %d de %d", solo_generado, length(rel))
linea("Distintos: %d de %d %s", length(distintos), length(rel),
      if (length(distintos)) paste0("-> ", paste(utils::head(distintos, 10), collapse = ", ")) else "")
linea("Claves nuevas en el JSON: %d", length(claves_nuevas))
# La linea base tiene que ser la que G6 registro, no una copia de procedencia
# desconocida: se contrasta contra el md5 que G6 guardo.
md5_base_g6 <- readRDS(file.path(TMP, "g6_linea_base_json.rds"))
md5_base_ahora <- vapply(names(md5_base_g6), function(r)
  unname(tools::md5sum(file.path(BASE, r))), character(1))
coincide_base <- sum(md5_base_g6 == md5_base_ahora)
linea("La copia base coincide con el md5 que registro G6: %d de %d artefactos",
      coincide_base, length(md5_base_g6))

subt("docs/data (lo que GitHub Pages publica) contra su linea base")
BASE_D <- file.path(TMP, "base_docs")
DOCS_D <- file.path(ROOT, "docs", "data")
rel_d <- sub(paste0("^", DOCS_D, "/"), "",
             list.files(DOCS_D, "[.]json$", recursive = TRUE, full.names = TRUE))
ig_d <- 0L; dif_d <- character(0)
for (r in rel_d) {
  a <- jsonlite::fromJSON(file.path(BASE_D, r), simplifyVector = FALSE)
  b <- jsonlite::fromJSON(file.path(DOCS_D, r), simplifyVector = FALSE)
  if (identical(sin_generado(a), sin_generado(b))) ig_d <- ig_d + 1L else dif_d <- c(dif_d, r)
}
linea("Artefactos de docs/data comparados: %d", length(rel_d))
linea("Identicos excluido metadatos.generado: %d de %d", ig_d, length(rel_d))
linea("Distintos: %d de %d", length(dif_d), length(rel_d))
C10_OK <- iguales == length(rel) && length(claves_nuevas) == 0L &&
          coincide_base == length(md5_base_g6) && ig_d == length(rel_d)

# =============================================================================
# C11. validar_corte() y contador de red
# =============================================================================
titulo("C11. Sellos y red")
sellos <- lapply(INTERMEDIOS_PIPELINE, function(nm)
  leer_sellado(ruta_salidas("intermedios", paste0(nm, ".rds")))$sello)
names(sellos) <- INTERMEDIOS_PIPELINE
linea("Intermedios leidos con sello: %d de %d", length(sellos), length(INTERMEDIOS_PIPELINE))
linea("validar_corte(sellos, '%s'): %s", CORTE_FECHA,
      as.character(validar_corte(sellos, CORTE_FECHA)))
cortes <- vapply(sellos, function(s) s$corte_fecha, character(1))
linea("Sellos con corte == CORTE_FECHA: %d de %d", sum(cortes == CORTE_FECHA), length(cortes))
C11_sellos <- sum(cortes == CORTE_FECHA) == length(INTERMEDIOS_PIPELINE)
linea("Llamadas HTTP en esta corrida de verificacion: %d", CONTADOR_HTTP$n)

# =============================================================================
# C12. Las tres funciones protegidas, contra HEAD
# =============================================================================
titulo("C12. sellar/leer_sellado/validar_corte contra HEAD")
RUTA_HEAD <- file.path(TMP, "utils_head.R")
if (!file.exists(RUTA_HEAD))
  stop("C12: falta la copia de HEAD; generala con git show antes de esta fase.", call. = FALSE)
cuerpo_de <- function(lineas, nombre) {
  ini <- grep(sprintf("^%s <- function", nombre), lineas)
  if (length(ini) != 1) stop(sprintf("C12: %s aparece %d veces.", nombre, length(ini)), call. = FALSE)
  fin <- ini + which(lineas[(ini + 1):length(lineas)] == "}")[1]
  bloque <- lineas[ini:fin]
  # La heuristica "primera linea igual a }" depende de la indentacion. Se verifica
  # que el bloque extraido tenga las llaves balanceadas: si no, se trunco y la
  # comparacion siguiente no probaria lo que dice probar.
  txt <- paste(bloque, collapse = "\n")
  abre <- lengths(regmatches(txt, gregexpr("\\{", txt)))
  cierra <- lengths(regmatches(txt, gregexpr("\\}", txt)))
  if (abre != cierra)
    stop(sprintf("C12: el bloque de %s quedo desbalanceado (%d '{' y %d '}'); la extraccion se trunco.",
                 nombre, abre, cierra), call. = FALSE)
  bloque
}
ln_head <- readLines(RUTA_HEAD, warn = FALSE)
ln_now  <- readLines(file.path(ROOT, "10_utils", "10_utils.R"), warn = FALSE)
C12_OK <- TRUE
for (fn in c("sellar", "leer_sellado", "validar_corte")) {
  a <- cuerpo_de(ln_head, fn); b <- cuerpo_de(ln_now, fn)
  ok <- identical(a, b)
  C12_OK <- C12_OK && ok
  linea("  %-14s HEAD %d lineas | ahora %d lineas | identicas: %s",
        fn, length(a), length(b), ok)
}

# =============================================================================
# Resumen de criterios verificables en R
# =============================================================================
titulo("Resumen")
for (p in list(c("C2", C2_OK), c("C3", C3_OK), c("C4", C4_OK), c("C4c", C4c_OK), c("C5", C5_OK),
               c("C6", C6_OK), c("C7", C7_OK), c("C8", C8_OK), c("C9", C9_OK),
               c("C10", C10_OK), c("C11", C11_sellos), c("C12", C12_OK)))
  linea("  %-4s %s", p[1], if (isTRUE(as.logical(p[2]))) "CUMPLE" else "NO CUMPLE")
linea("Llamadas HTTP totales en esta corrida: %d", CONTADOR_HTTP$n)

}  # fin fase criterios
