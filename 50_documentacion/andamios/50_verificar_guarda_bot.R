# =============================================================================
# 50_verificar_guarda_bot.R
# -----------------------------------------------------------------------------
# Proposito: compuertas del §3 y criterios del §4 del encargo de reparacion de la
#            guarda circular del bot semanal. Lee los archivos REALES; ninguna
#            respuesta se toma de un reporte anterior.
#
# Invariantes (encargo §2): cero red (contador instrumentado y reportado en cada
# proceso); 20_insumos/camara/ inmutable (md5 al abrir y al cerrar); fallo
# ruidoso; todo conteo con su denominador contado en la corrida; los intermedios
# que se muevan se restauran con mv y se verifican por md5.
#
# Uso:  Rscript 50_documentacion/andamios/50_verificar_guarda_bot.R [fase]
#       fase = "compuertas" (default) | "criterios"
# Autor: Claude Code (encargo reparacion guarda bot, sesion 18)
# Creado: 2026-08-09
# =============================================================================

options(camara.refrescar = FALSE)

source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
instalar_si_falta(c("httr", "xml2", "here", "fs", "jsonlite", "tools"))
ROOT <- obtener_raiz_proyecto()
source(file.path(ROOT, "10_utils", "10_configuracion.R"))

FASE <- if (length(commandArgs(TRUE))) commandArgs(TRUE)[1] else "compuertas"
TMP  <- Sys.getenv("P74_TMP")
if (!nzchar(TMP) || !dir.exists(TMP))
  stop("falta P74_TMP o el directorio no existe.", call. = FALSE)

CONTADOR_HTTP <- new.env(parent = emptyenv()); CONTADOR_HTTP$n <- 0L
for (par in list(c("httr", "GET"), c("httr", "POST"), c("httr", "RETRY"),
                 c("curl", "curl_fetch_memory"))) {
  if (requireNamespace(par[1], quietly = TRUE))
    trace(par[2], where = asNamespace(par[1]), print = FALSE,
          tracer = quote(CONTADOR_HTTP$n <- CONTADOR_HTTP$n + 1L))
}

titulo <- function(x) cat("\n\n=====", x, "=====\n")
subt   <- function(x) cat("\n--- ", x, "\n", sep = "")
linea  <- function(fmt, ...) cat(sprintf(fmt, ...), "\n", sep = "")
mostrar <- function(ruta, desde, hasta) {
  ln <- readLines(ruta, warn = FALSE)
  for (k in seq(desde, min(hasta, length(ln)))) linea("  %4d| %s", k, ln[k])
}
md5_de <- function(dir, patron) {
  f <- sort(list.files(dir, patron, full.names = TRUE, recursive = TRUE))
  stats::setNames(vapply(f, function(x) unname(tools::md5sum(x)), character(1)),
                  sub(paste0("^", dir, "/"), "", f))
}
RUTA_UTILS <- file.path(ROOT, "10_utils", "10_utils.R")
RUTA_RUN   <- file.path(ROOT, "00_run_all.R")
RUTA_WF    <- file.path(ROOT, ".github", "workflows", "refresh-semanal.yml")

if (identical(FASE, "compuertas")) {

# =============================================================================
# G5 primero: la linea base de integridad se toma ANTES de mover nada
# =============================================================================
titulo("G5. Linea base de integridad (antes de tocar nada)")
b_cap <- md5_de(ruta_insumos("camara"), "[.]rds$")
b_int <- md5_de(ruta_salidas("intermedios"), "[.]rds$")
b_jsn <- md5_de(ruta_salidas("json"), "[.]json$")
b_doc <- md5_de(file.path(ROOT, "docs", "data"), "[.]json$")
linea("Capturas crudas 20_insumos/camara/ : %d archivos, %d md5 distintos",
      length(b_cap), length(unique(b_cap)))
linea("Intermedios 40_salidas/intermedios/: %d archivos, %d md5 distintos",
      length(b_int), length(unique(b_int)))
linea("Publicado 40_salidas/json/         : %d archivos, %d md5 distintos",
      length(b_jsn), length(unique(b_jsn)))
linea("Publicado docs/data/               : %d archivos, %d md5 distintos",
      length(b_doc), length(unique(b_doc)))
saveRDS(list(cap = b_cap, int = b_int, jsn = b_jsn, doc = b_doc),
        file.path(TMP, "guarda_linea_base.rds"))
linea("Linea base guardada fuera del repo: %s", file.path(TMP, "guarda_linea_base.rds"))

# =============================================================================
# G1. Anatomia de la guarda
# =============================================================================
titulo("G1. Anatomia de la guarda")
ln_u <- readLines(RUTA_UTILS, warn = FALSE)
ini <- grep("^regenerar_intermedios_si_desalineados <- function", ln_u)
fin <- ini + which(ln_u[(ini + 1):length(ln_u)] == "}")[1]
linea("Archivo    : %s", RUTA_UTILS)
linea("Funcion    : lineas %d-%d (%d lineas)", ini, fin, fin - ini + 1)
linea("Firma      : %s", trimws(ln_u[ini]))
ln_r <- readLines(RUTA_RUN, warn = FALSE)
inv <- grep("regenerar_intermedios_si_desalineados\\(", ln_r)
linea("Invocada en: %s:%s -> %s", basename(RUTA_RUN), paste(inv, collapse = ", "),
      trimws(ln_r[inv[1]]))
# Hay DOS bucles sobre PASOS: el de validacion de rutas y el que ejecuta los pasos.
# El que importa es el segundo (el que abre bloque con '{'), no el primero.
bucles <- grep("for \\(p in PASOS\\)", ln_r)
bucle_pasos <- bucles[grepl("\\{\\s*$", ln_r[bucles])][1]
linea("Bucles sobre PASOS en el orquestador: lineas %s", paste(bucles, collapse = ", "))
linea("  linea %d: validacion de rutas | linea %d: ejecucion de los pasos",
      setdiff(bucles, bucle_pasos)[1], bucle_pasos)
linea("La guarda se invoca en la linea %d: despues de validar rutas y ANTES de ejecutar ningun paso (%d).",
      inv[1], bucle_pasos)

subt("Cada rama que puede terminar en detencion, enumerada")
for (k in grep("stop\\(", ln_u[ini:fin])) {
  abs <- ini + k - 1L
  linea("  stop() en linea %d", abs)
}
linea("Total de stop() dentro de la funcion (contados): %d",
      length(grep("stop\\(", ln_u[ini:fin])))
subt("Cuerpo literal de la funcion")
mostrar(RUTA_UTILS, ini, fin)

subt("Que devuelve corte_declarado_por() cuando el intermedio NO existe (medido)")
inexistente <- "no_existe_este_intermedio_p74"
ruta_inex <- ruta_salidas("intermedios", paste0(inexistente, ".rds"))
linea("  ruta consultada      : %s", ruta_inex)
linea("  file.exists()        : %s", file.exists(ruta_inex))
v <- corte_declarado_por(inexistente)
linea("  valor devuelto       : %s", if (is.na(v)) "NA_character_" else v)
linea("  is.na()              : %s", is.na(v))
linea("  clase                : %s", class(v))
subt("Y como lo clasifica la expresion de desalineamiento de la linea 497")
linea("  is.na(v) | v != corte  ->  %s  (con corte = '%s')",
      is.na(v) | !identical(v, CORTE_FECHA), CORTE_FECHA)
linea("  CONSECUENCIA: 'ausente' y 'presente con otro corte' caen en la MISMA rama.")

# =============================================================================
# G2. Resolucion de corte en capturas_crudas_de_paso()
# =============================================================================
titulo("G2. Resolucion de corte")
ini2 <- grep("^capturas_crudas_de_paso <- function", ln_u)
fin2 <- ini2 + which(ln_u[(ini2 + 1):length(ln_u)] == "}")[1]
linea("capturas_crudas_de_paso(): lineas %d-%d", ini2, fin2)
linea("Firma: %s", trimws(ln_u[ini2]))
linea("Menciona el argumento 'corte' en su cuerpo: %s",
      any(grepl("\\bcorte\\b", ln_u[ini2:fin2])))
linea("Llama a ruta_cache() (que resuelve por la global): %d veces",
      length(grep("ruta_cache\\(", ln_u[ini2:fin2])))
subt("Cuerpo literal")
mostrar(RUTA_UTILS, ini2, fin2)
subt("ruta_cache() y corte_para_clave(): de donde sale realmente la fecha")
mostrar(RUTA_UTILS, grep("^ruta_cache <- function", ln_u),
        grep("^ruta_cache <- function", ln_u) + 3)
linea("corte_para_clave() menciona CORTE_FECHA (global): %s",
      any(grepl("CORTE_FECHA", ln_u[grep("^corte_para_clave <- function", ln_u):(grep("^corte_para_clave <- function", ln_u) + 11)])))

subt("Caso construido donde el argumento y la global DIFIEREN")
CORTE_GLOBAL <- CORTE_FECHA
CORTE_ARG    <- format(as.Date(CORTE_GLOBAL) + 7, "%Y-%m-%d")
linea("  global CORTE_FECHA        : %s", CORTE_GLOBAL)
linea("  argumento 'corte' de la guarda: %s", CORTE_ARG)
linea("  ruta que devuelve capturas_crudas_de_paso(36): %s",
      basename(capturas_crudas_de_paso(36)))
linea("  -> esa ruta lleva el corte %s (la GLOBAL), no %s (el ARGUMENTO)",
      gsub("-", "", CORTE_GLOBAL), gsub("-", "", CORTE_ARG))
linea("  Existe en disco: %s", file.exists(capturas_crudas_de_paso(36)))
linea("  CONSECUENCIA: con corte='%s' la guarda mediria desalineamiento contra %s",
      CORTE_ARG, CORTE_ARG)
linea("  y existencia de capturas contra %s. Dos cortes distintos, sin ruido.",
      CORTE_GLOBAL)

# =============================================================================
# G3. Lo que el workflow escribe y commitea
# =============================================================================
titulo("G3. Lo que el workflow escribe en el repo")
ln_w <- readLines(RUTA_WF, warn = FALSE)
linea("Archivo: %s (%d lineas)", RUTA_WF, length(ln_w))
for (pat in c("git add", "sed -i", "cp -r", "git commit", "git push")) {
  for (k in grep(pat, ln_w, fixed = TRUE))
    linea("  %-11s linea %3d: %s", pat, k, trimws(ln_w[k]))
}
k_add <- grep("git add", ln_w, fixed = TRUE)[1]
rutas <- setdiff(strsplit(trimws(ln_w[k_add]), "\\s+")[[1]], c("git", "add"))
linea("\nRutas del git add (contadas): %d", length(rutas))
for (r in rutas)
  linea("  %-34s existe en el repo: %s", r, file.exists(file.path(ROOT, r)))
linea("Commitea 40_salidas/: %s | commitea docs/: %s",
      any(grepl("^40_salidas", rutas)), any(grepl("^docs", rutas)))

titulo("Contador de red (compuertas)")
linea("Llamadas HTTP: %d", CONTADOR_HTTP$n)

}  # fin compuertas

if (identical(FASE, "criterios")) {

# =============================================================================
# C7. capturas_crudas_de_paso() resuelve el corte de UNA sola forma
# =============================================================================
titulo("C7. Resolucion de corte, despues del arreglo")
CG <- CORTE_FECHA
CA <- format(as.Date(CG) + 7, "%Y-%m-%d")
linea("global CORTE_FECHA: %s | corte pasado como argumento: %s", CG, CA)
subt("Mismo caso que G2 construyo, ahora con el argumento propagado")
for (id in c(32, 33, 34, 35, 36)) {
  sin_arg <- basename(capturas_crudas_de_paso(id))
  con_arg <- basename(capturas_crudas_de_paso(id, corte = CA))
  linea("  paso %d | sin argumento -> %s", id, paste(sin_arg, collapse = ", "))
  linea("         | corte='%s' -> %s", CA, paste(con_arg, collapse = ", "))
}
todas_g <- unlist(lapply(c(32, 33, 34, 35, 36), capturas_crudas_de_paso))
todas_a <- unlist(lapply(c(32, 33, 34, 35, 36), capturas_crudas_de_paso, corte = CA))
pref_g <- gsub("-", "", CG); pref_a <- gsub("-", "", CA)
linea("\nCon el default: %d de %d rutas llevan el prefijo de la global (%s)",
      sum(startsWith(basename(todas_g), pref_g)), length(todas_g), pref_g)
linea("Con el argumento: %d de %d rutas llevan el prefijo del ARGUMENTO (%s)",
      sum(startsWith(basename(todas_a), pref_a)), length(todas_a), pref_a)
linea("Rutas que siguen resolviendo por la global pese al argumento: %d de %d",
      sum(startsWith(basename(todas_a), pref_g)), length(todas_a))
C7_OK <- all(startsWith(basename(todas_a), pref_a)) &&
         all(startsWith(basename(todas_g), pref_g))
linea("C7: %s", if (C7_OK) "CUMPLE" else "NO CUMPLE")

# =============================================================================
# C11. Funciones protegidas identicas a HEAD
# =============================================================================
titulo("C11. Funciones protegidas contra HEAD")
RUTA_HEAD <- file.path(TMP, "utils_head_main.R")
if (!file.exists(RUTA_HEAD))
  stop("C11: falta la copia de HEAD; generala con git show antes de esta fase.", call. = FALSE)
cuerpo_de <- function(lineas, nombre) {
  ini <- grep(sprintf("^%s <- function", nombre), lineas)
  if (length(ini) != 1)
    stop(sprintf("C11: %s aparece %d veces.", nombre, length(ini)), call. = FALSE)
  fin <- ini + which(lineas[(ini + 1):length(lineas)] == "}")[1]
  bloque <- lineas[ini:fin]
  txt <- paste(bloque, collapse = "\n")
  if (lengths(regmatches(txt, gregexpr("\\{", txt))) !=
      lengths(regmatches(txt, gregexpr("\\}", txt))))
    stop(sprintf("C11: el bloque de %s quedo desbalanceado.", nombre), call. = FALSE)
  bloque
}
ln_head <- readLines(RUTA_HEAD, warn = FALSE)
ln_now  <- readLines(RUTA_UTILS, warn = FALSE)
PROTEGIDAS <- c("sellar", "leer_sellado", "validar_corte",
                "guarda_captura_en_corte", "verificar_cierre_de_descarga",
                "registrar_captura", "estado_temporal_captura",
                "reportar_estado_capturas", "con_cache")
C11_OK <- TRUE
for (fn in PROTEGIDAS) {
  a <- cuerpo_de(ln_head, fn); b <- cuerpo_de(ln_now, fn)
  ok <- identical(a, b); C11_OK <- C11_OK && ok
  linea("  %-30s HEAD %2d lineas | ahora %2d | identicas: %s", fn, length(a), length(b), ok)
}
linea("C11 (%d de %d funciones protegidas identicas): %s",
      sum(vapply(PROTEGIDAS, function(fn)
        identical(cuerpo_de(ln_head, fn), cuerpo_de(ln_now, fn)), logical(1))),
      length(PROTEGIDAS), if (C11_OK) "CUMPLE" else "NO CUMPLE")

subt("Funciones que SI cambiaron en este PR (declaradas, no protegidas)")
for (fn in c("corte_para_clave", "ruta_cache", "capturas_crudas_de_paso",
             "regenerar_intermedios_si_desalineados")) {
  a <- cuerpo_de(ln_head, fn); b <- cuerpo_de(ln_now, fn)
  linea("  %-38s HEAD %2d lineas -> ahora %2d | identicas: %s",
        fn, length(a), length(b), identical(a, b))
}

}  # fin criterios

# =============================================================================
# FASE p76p77 (encargo P-76/P-77 v2, sesion 19)
# -----------------------------------------------------------------------------
# Los escenarios que ejercitan la guarda corren en SUBPROCESOS, invocando este
# mismo archivo con la fase "esc" y el nombre del escenario. Motivo (A76): el
# fusible certifica el proceso donde vive, asi que tiene que estar armado en el
# proceso que corre el pipeline, no en el que mira. De paso, cada escenario
# arranca con las opciones limpias y ninguno contamina al siguiente.
# =============================================================================

RUTA_ESTE   <- file.path(ROOT, "50_documentacion", "andamios", "50_verificar_guarda_bot.R")
RUTA_FUSIBLE <- file.path(ROOT, "50_documentacion", "andamios", "50_fusible_red.R")
DIR_INT     <- ruta_salidas("intermedios")
GUARDADO    <- file.path(TMP, "intermedios_guardados")

# Estado de disco que cada escenario exige. Mover, nunca borrar (invariante 7).
apartar_intermedios <- function() {
  if (!dir.exists(GUARDADO)) dir.create(GUARDADO, recursive = TRUE)
  n <- 0L
  for (nm in INTERMEDIOS_PIPELINE) {
    r <- file.path(DIR_INT, paste0(nm, ".rds"))
    if (file.exists(r)) { file.rename(r, file.path(GUARDADO, paste0(nm, ".rds"))); n <- n + 1L }
  }
  n
}
restaurar_intermedios <- function() {
  n <- 0L
  for (nm in INTERMEDIOS_PIPELINE) {
    g <- file.path(GUARDADO, paste0(nm, ".rds"))
    r <- file.path(DIR_INT, paste0(nm, ".rds"))
    if (file.exists(r)) unlink(r)          # el generado por un escenario
    if (file.exists(g)) { file.rename(g, r); n <- n + 1L }
  }
  n
}
poner_rastro <- function(presente) {
  r <- file.path(DIR_INT, RASTRO_ARRANQUE)
  if (presente && !file.exists(r)) escribir_rastro_arranque(CORTE_FECHA, "escenario de prueba")
  if (!presente && file.exists(r)) unlink(r)
  file.exists(r)
}
correr_escenario <- function(nombre) {
  out <- system2("Rscript", c(shQuote(RUTA_ESTE), "esc", nombre),
                 stdout = TRUE, stderr = TRUE)
  list(salida = attr(out, "status") %||% 0L, lineas = out)
}
tiene <- function(lineas, texto) any(vapply(lineas, function(l) grepl(texto, l, fixed = TRUE),
                                            logical(1)))
cuantas <- function(lineas, texto) sum(vapply(lineas, function(l) grepl(texto, l, fixed = TRUE),
                                              logical(1)))
veredicto <- function(id, ok, detalle) {
  linea("%-4s %-9s %s", id, if (ok) "CUMPLE" else "NO CUMPLE", detalle)
  invisible(ok)
}

if (identical(FASE, "esc")) {

  ESC <- commandArgs(TRUE)[2]
  source(RUTA_FUSIBLE)
  instalar_fusible_red()                       # ANTES de tocar 00_run_all.R
  source(file.path(ROOT, "00_run_all.R"))
  RUTA_RASTRO <- ruta_salidas("intermedios", RASTRO_ARRANQUE)
  CORTE_SIN_CAPTURAS <- format(as.Date(CORTE_FECHA) + 21, "%Y-%m-%d")

  if (identical(ESC, "arranque")) {
    # C4. Estado tipo runner: 0 intermedios, sin rastro, .gitkeep presente. Se
    # fuerza refrescar=TRUE para que el primer extractor SALGA a la red: asi el
    # escenario distingue "la guarda no detuvo" de "no habia nada que descargar".
    cat("ESC arranque | rastro antes:", file.exists(RUTA_RASTRO), "\n")
    options(camara.refrescar = TRUE)
    run_all()
    cat("ESC arranque | NO ESPERADO: run_all() retorno sin disparar el fusible\n")
  }

  if (identical(ESC, "borrados_regenera")) {
    # C5. 0 intermedios + rastro presente + capturas del corte presentes.
    cat("ESC borrados_regenera | rastro:", file.exists(RUTA_RASTRO), "\n")
    r <- regenerar_intermedios_si_desalineados(PASOS_EXTRACCION, ROOT)
    cat("ESC borrados_regenera | la guarda regenero:", isTRUE(r), "\n")
    d <- vapply(INTERMEDIOS_PIPELINE, corte_declarado_por, character(1))
    cat("ESC borrados_regenera | intermedios al corte vigente:",
        sum(!is.na(d) & d == CORTE_FECHA), "de", length(INTERMEDIOS_PIPELINE), "\n")
  }

  if (identical(ESC, "borrados_stop")) {
    # C6. Mismo estado, pero contra un corte cuyas capturas no existen. Se elige
    # asi y no moviendo capturas: 20_insumos/camara/ no se toca (invariante 2).
    cat("ESC borrados_stop | rastro:", file.exists(RUTA_RASTRO),
        "| corte sin capturas:", CORTE_SIN_CAPTURAS, "\n")
    e <- tryCatch({
      regenerar_intermedios_si_desalineados(PASOS_EXTRACCION, ROOT,
                                            corte = CORTE_SIN_CAPTURAS)
      NULL
    }, error = function(e) conditionMessage(e))
    cat("ESC borrados_stop | hubo stop():", !is.null(e), "\n")
    if (!is.null(e)) cat("--- mensaje del stop() ---\n", e, "\n--- fin ---\n", sep = "")
  }

  if (identical(ESC, "borrados_autorizado")) {
    # C7 + C1 + C2. La opcion se enciende UNA vez y se pasa DOS veces por el
    # mismo estado, en el mismo proceso.
    options(camara.permitir_descarga_inicial = TRUE)
    cat("ESC autorizado | opcion antes:", descarga_inicial_autorizada(), "\n")
    p <- tryCatch({
      regenerar_intermedios_si_desalineados(PASOS_EXTRACCION, ROOT,
                                            corte = CORTE_SIN_CAPTURAS)
      "paso"
    }, error = function(e) "stop")
    cat("ESC autorizado | primera pasada:", p, "\n")
    cat("ESC autorizado | opcion despues:", descarga_inicial_autorizada(), "\n")
    s <- tryCatch({
      regenerar_intermedios_si_desalineados(PASOS_EXTRACCION, ROOT,
                                            corte = CORTE_SIN_CAPTURAS)
      "paso"
    }, error = function(e) "stop")
    cat("ESC autorizado | segunda pasada:", s, "\n")
  }

  if (identical(ESC, "escape_captura")) {
    # C3. La linea de log del escape de captura, emitida por el codigo de AHORA y
    # por el de HEAD, comparadas sin el sello de tiempo.
    env_head <- new.env(parent = globalenv())
    sys.source(file.path(TMP, "utils_head_main.R"), envir = env_head)
    options(camara.permitir_captura_fuera_de_corte = TRUE)
    l_head <- capture.output(env_head$consumir_escape_captura("contrato"))
    options(camara.permitir_captura_fuera_de_corte = TRUE)
    l_ahora <- capture.output(consumir_escape_captura("contrato"))
    cat("ESC escape_captura | opcion tras consumir:",
        isTRUE(getOption("camara.permitir_captura_fuera_de_corte", FALSE)), "\n")
    cat("ESC escape_captura | identicas:",
        identical(substring(l_head, 23), substring(l_ahora, 23)), "\n")
    cat("HEAD :", substring(l_head, 23), "\n")
    cat("AHORA:", substring(l_ahora, 23), "\n")
  }

  cat("ESC", ESC, "| fin sin disparar el fusible\n")
}

if (identical(FASE, "p76p77")) {

titulo("Linea base de apertura")
a_cap <- md5_de(ruta_insumos("camara"), "[.]rds$")
a_jsn <- md5_de(ruta_salidas("json"), "[.]json$")
a_doc <- md5_de(file.path(ROOT, "docs", "data"), "[.]json$")
base <- readRDS(file.path(TMP, "guarda_linea_base.rds"))
linea("Capturas: %d archivos | json: %d | docs/data: %d", length(a_cap), length(a_jsn), length(a_doc))
n_apartados <- apartar_intermedios()
linea("Intermedios apartados a %s: %d de %d", GUARDADO, n_apartados, length(INTERMEDIOS_PIPELINE))
resultados <- list()

titulo("C4. Arranque legitimo (estado tipo runner): la guarda no se detiene")
poner_rastro(FALSE)
linea("Estado: %d de %d intermedios en disco | rastro presente: %s | .gitkeep presente: %s",
      sum(file.exists(file.path(DIR_INT, paste0(INTERMEDIOS_PIPELINE, ".rds")))),
      length(INTERMEDIOS_PIPELINE), file.exists(file.path(DIR_INT, RASTRO_ARRANQUE)),
      file.exists(file.path(DIR_INT, ".gitkeep")))
r4 <- correr_escenario("arranque")
rastro_tras_c4 <- file.exists(file.path(DIR_INT, RASTRO_ARRANQUE))
linea("Codigo de salida: %d (99 = fusible) | rastro escrito por la guarda: %s",
      r4$salida, rastro_tras_c4)
linea("La guarda anuncio primera corrida: %s | fusible disparado: %s",
      tiene(r4$lineas, "Primera corrida del corte"),
      tiene(r4$lineas, "FUSIBLE DE RED DISPARADO"))
resultados$C4 <- veredicto("C4", r4$salida == 99L && rastro_tras_c4 &&
  tiene(r4$lineas, "Primera corrida del corte") &&
  tiene(r4$lineas, "FUSIBLE DE RED DISPARADO") &&
  !tiene(r4$lineas, "run_all: "),
  "la corrida murio en el fusible, no en la guarda, y el rastro quedo escrito")
restaurar_intermedios(); apartar_intermedios()

titulo("C5. Intermedios borrados con capturas del corte: regenera sin red")
poner_rastro(TRUE)
r5 <- correr_escenario("borrados_regenera")
n_hits <- cuantas(r5$lineas, "cache hit:")
linea("Codigo de salida: %d | 'cache hit' contados: %d | fusible disparado: %s",
      r5$salida, n_hits, tiene(r5$lineas, "FUSIBLE DE RED DISPARADO"))
linea("La guarda regenero: %s | %s", tiene(r5$lineas, "la guarda regenero: TRUE"),
      r5$lineas[vapply(r5$lineas, function(l)
        grepl("intermedios al corte vigente", l, fixed = TRUE), logical(1))][1])
resultados$C5 <- veredicto("C5", r5$salida == 0L && n_hits == 6L &&
  !tiene(r5$lineas, "FUSIBLE DE RED DISPARADO") &&
  tiene(r5$lineas, "intermedios al corte vigente: 6 de 6"),
  "6 de 6 cache hit, exit 0, fusible sin disparar")
restaurar_intermedios(); apartar_intermedios()

titulo("C6. Intermedios borrados sin capturas del corte: se detiene")
poner_rastro(TRUE)
r6 <- correr_escenario("borrados_stop")
linea("Codigo de salida: %d | hubo stop(): %s | fusible disparado: %s",
      r6$salida, tiene(r6$lineas, "hubo stop(): TRUE"),
      tiene(r6$lineas, "FUSIBLE DE RED DISPARADO"))
linea("El mensaje nombra el caso y lo distingue del arranque: %s",
      tiene(r6$lineas, "Esto NO es un arranque"))
linea("El mensaje da el comando exacto: %s", tiene(r6$lineas, "source(\"30_procesamiento/"))
resultados$C6 <- veredicto("C6", r6$salida == 0L && tiene(r6$lineas, "hubo stop(): TRUE") &&
  tiene(r6$lineas, "Esto NO es un arranque") &&
  tiene(r6$lineas, "source(\"30_procesamiento/") &&
  !tiene(r6$lineas, "FUSIBLE DE RED DISPARADO"),
  "stop() con el caso nombrado y el comando exacto, cero red")
subt("Mensaje literal del stop()")
for (l in r6$lineas) linea("  %s", l)

titulo("C7 + C1 + C2. El escape autorizado pasa una vez y solo una")
r7 <- correr_escenario("borrados_autorizado")
for (l in r7$lineas) if (tiene(l, "ESC autorizado")) linea("  %s", l)
resultados$C7 <- veredicto("C7", r7$salida == 0L && tiene(r7$lineas, "primera pasada: paso"),
  "con la autorizacion declarada, la guarda deja seguir")
resultados$C1 <- veredicto("C1", tiene(r7$lineas, "opcion antes: TRUE") &&
  tiene(r7$lineas, "opcion despues: FALSE"),
  "descarga_inicial_autorizada() devuelve FALSE despues de usarse")
resultados$C2 <- veredicto("C2", tiene(r7$lineas, "segunda pasada: stop"),
  "la segunda pasada en la misma sesion se detiene")

titulo("C3. El escape de captura no cambio de comportamiento")
r3 <- correr_escenario("escape_captura")
for (l in r3$lineas) if (tiene(l, "ESC escape_captura") || tiene(l, "HEAD :") ||
                         tiene(l, "AHORA:")) linea("  %s", l)
resultados$C3 <- veredicto("C3", tiene(r3$lineas, "identicas: TRUE") &&
  tiene(r3$lineas, "opcion tras consumir: FALSE"),
  "linea de log identica a la de HEAD y sigue siendo de un solo uso")

titulo("Restauracion del estado de disco")
n_rest <- restaurar_intermedios()
if (file.exists(file.path(DIR_INT, RASTRO_ARRANQUE))) unlink(file.path(DIR_INT, RASTRO_ARRANQUE))
if (dir.exists(GUARDADO)) unlink(GUARDADO, recursive = TRUE)
linea("Intermedios restaurados: %d de %d | rastro de prueba retirado: %s",
      n_rest, length(INTERMEDIOS_PIPELINE), !file.exists(file.path(DIR_INT, RASTRO_ARRANQUE)))

titulo("C11. Intermedios restaurados, md5 contra la linea base de G5")
c_int <- md5_de(DIR_INT, "[.]rds$")
iguales <- vapply(names(base$int), function(k)
  identical(unname(base$int[k]), unname(c_int[k])), logical(1))
for (k in names(base$int)) linea("  %-26s md5 igual: %s", k, identical(unname(base$int[k]), unname(c_int[k])))
resultados$C11 <- veredicto("C11", all(iguales) && length(c_int) == length(base$int),
  sprintf("%d de %d intermedios identicos a la linea base", sum(iguales), length(base$int)))

titulo("C10. 20_insumos/camara/ intacto")
c_cap <- md5_de(ruta_insumos("camara"), "[.]rds$")
ok_cap <- identical(base$cap, c_cap)
linea("Apertura: %d archivos | cierre: %d | identicos archivo por archivo: %s",
      length(base$cap), length(c_cap), ok_cap)
resultados$C10 <- veredicto("C10", ok_cap && length(c_cap) == length(base$cap),
  sprintf("%d de %d capturas con md5 identico", sum(names(base$cap) %in% names(c_cap) &
    base$cap[names(base$cap)] == c_cap[names(base$cap)]), length(base$cap)))

titulo("Publicado intacto (json y docs/data)")
c_jsn <- md5_de(ruta_salidas("json"), "[.]json$"); c_doc <- md5_de(file.path(ROOT, "docs", "data"), "[.]json$")
linea("40_salidas/json: %d de %d identicos | docs/data: %d de %d identicos",
      sum(base$jsn == c_jsn[names(base$jsn)]), length(base$jsn),
      sum(base$doc == c_doc[names(base$doc)]), length(base$doc))

titulo("C8. Las 9 funciones protegidas, identicas a HEAD")
RUTA_HEAD <- file.path(TMP, "utils_head_main.R")
cuerpo_de <- function(lineas, nombre) {
  ini <- grep(sprintf("^%s <- function", nombre), lineas)
  if (length(ini) != 1) stop(sprintf("C8: %s aparece %d veces.", nombre, length(ini)), call. = FALSE)
  fin <- ini + which(lineas[(ini + 1):length(lineas)] == "}")[1]
  lineas[ini:fin]
}
ln_head <- readLines(RUTA_HEAD, warn = FALSE); ln_now <- readLines(RUTA_UTILS, warn = FALSE)
PROTEGIDAS <- c("sellar", "leer_sellado", "validar_corte",
                "guarda_captura_en_corte", "verificar_cierre_de_descarga",
                "registrar_captura", "estado_temporal_captura",
                "reportar_estado_capturas", "con_cache")
ok8 <- vapply(PROTEGIDAS, function(fn)
  identical(cuerpo_de(ln_head, fn), cuerpo_de(ln_now, fn)), logical(1))
for (fn in PROTEGIDAS)
  linea("  %-30s HEAD %2d lineas | ahora %2d | identicas: %s", fn,
        length(cuerpo_de(ln_head, fn)), length(cuerpo_de(ln_now, fn)), ok8[[fn]])
resultados$C8 <- veredicto("C8", all(ok8),
  sprintf("%d de %d funciones protegidas identicas", sum(ok8), length(PROTEGIDAS)))
subt("Funciones que SI cambian en este PR (declaradas, no protegidas)")
for (fn in c("consumir_escape_captura", "regenerar_intermedios_si_desalineados"))
  linea("  %-38s HEAD %2d lineas -> ahora %2d | identicas: %s", fn,
        length(cuerpo_de(ln_head, fn)), length(cuerpo_de(ln_now, fn)),
        identical(cuerpo_de(ln_head, fn), cuerpo_de(ln_now, fn)))

titulo("C13. .gitkeep sigue trackeado y sin cambios")
tracked <- system2("git", c("-C", shQuote(ROOT), "ls-files", "40_salidas/intermedios"),
                   stdout = TRUE)
blob_head <- system2("git", c("-C", shQuote(ROOT), "rev-parse",
                              "origin/main:40_salidas/intermedios/.gitkeep"), stdout = TRUE)
blob_now <- system2("git", c("-C", shQuote(ROOT), "hash-object",
                             file.path(DIR_INT, ".gitkeep")), stdout = TRUE)
linea("git ls-files 40_salidas/intermedios: %d entrada(s) -> %s",
      length(tracked), paste(tracked, collapse = ", "))
linea("blob en origin/main: %s | blob ahora: %s", blob_head, blob_now)
ignorado <- system2("git", c("-C", shQuote(ROOT), "check-ignore",
                             file.path("40_salidas", "intermedios", RASTRO_ARRANQUE)),
                    stdout = TRUE, stderr = FALSE)
linea("El rastro esta gitignorado: %s (%s)", length(ignorado) > 0, paste(ignorado, collapse = ""))
resultados$C13 <- veredicto("C13",
  identical(tracked, "40_salidas/intermedios/.gitkeep") && identical(blob_head, blob_now) &&
  length(ignorado) > 0,
  ".gitkeep trackeado, mismo blob que origin/main, y el rastro ignorado")

titulo("C9. Cero llamadas HTTP en todos los escenarios")
disparos <- vapply(list(r3, r4, r5, r6, r7), function(r)
  tiene(r$lineas, "FUSIBLE DE RED DISPARADO"), logical(1))
linea("Escenarios corridos: %d | con fusible armado: %d | que salieron a la red: %d",
      length(disparos), sum(vapply(list(r3, r4, r5, r6, r7), function(r)
        tiene(r$lineas, "Fusible de red ARMADO"), logical(1))), sum(disparos))
linea("El unico disparo esperado es el de C4 (arranque, que DEBE llegar a la red): %s",
      identical(unname(disparos), c(FALSE, TRUE, FALSE, FALSE, FALSE)))
resultados$C9 <- veredicto("C9", identical(unname(disparos), c(FALSE, TRUE, FALSE, FALSE, FALSE)),
  "ninguna llamada HTTP salio: la unica que lo intento murio en el fusible")

titulo("RESUMEN")
for (k in c("C1","C2","C3","C4","C5","C6","C7","C8","C9","C10","C11","C13"))
  linea("  %-4s %s", k, if (isTRUE(resultados[[k]])) "CUMPLE" else "NO CUMPLE")
linea("\nCriterios medidos aqui: %d de 13 (C12 se mide sobre el PR ya abierto)",
      length(resultados))
linea("CUMPLEN: %d de %d", sum(vapply(resultados, isTRUE, logical(1))), length(resultados))

}  # fin p76p77
