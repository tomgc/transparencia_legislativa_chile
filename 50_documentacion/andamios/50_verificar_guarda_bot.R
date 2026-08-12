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
