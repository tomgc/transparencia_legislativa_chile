# =============================================================================
# 50_verificar_localizador_p100.R - Arnes del localizador de switch (P-100)
# -----------------------------------------------------------------------------
# POR QUE EXISTE. localizar_switch() y verificar_registro_pasos() son la guarda
# que corre PRIMERO en run_all(): si se equivoca, no degrada un chequeo, detiene
# el pipeline y con el, el cron. Hasta hoy nunca tuvieron un arnes versionado.
# Las pruebas de P-100 vivieron en scratchpads de sesion y murieron con ellas,
# y por eso una correccion de la sesion 24 pudo introducir un falso negativo que
# solo encontro un panel adversarial. Este archivo existe para que la proxima no
# dependa de que alguien mire.
#
# QUE PRUEBA, en cuatro bloques:
#   ast       - las 19 formas de arbol sintactico que la guarda debe reconocer o
#               rechazar, con su resultado esperado declarado aqui mismo.
#   real      - la funcion REAL del pipeline, capturas_crudas_de_paso(), con dos
#               formas insertadas en su texto: el fall-through `"38" = ,` y el
#               indexado con argumento vacio de 37_extraer_tramitacion.R:190.
#   contorno  - cero llamadas, mas de una, y switch solo dentro de una `function`
#               anidada (que cuenta como cero y falla ruidosamente).
#   regresion - los siete casos que el panel de la sesion 24 uso para medir una
#               correccion de do.call que despues se revirtio. Su comportamiento
#               esperado es el del estado revertido. SIN ESTOS CASOS, la proxima
#               correccion de esa clase vuelve a romper lo mismo en silencio.
#
# COMO SE CORRE, desde la raiz del proyecto:
#   Rscript 50_documentacion/andamios/50_verificar_localizador_p100.R          # todo
#   Rscript 50_documentacion/andamios/50_verificar_localizador_p100.R ast real # bloques
#
# SALE CON ESTADO 1 si algun caso no da lo esperado, nombrandolo. Un arnes que
# informa y sale en cero no es un arnes.
#
# NO TOCA NADA. Solo lee, y construye funciones en memoria.
# =============================================================================

source("10_utils/10_configuracion.R")
source("10_utils/10_utils.R")

bloques <- commandArgs(trailingOnly = TRUE)
if (length(bloques) == 0L) bloques <- c("ast", "real", "contorno", "regresion")

fallos <- character(0)

# Devuelve "RESUELVE[ramas]" o "DETIENE", nunca el mensaje completo: lo que se
# contrasta es el comportamiento, no la redaccion.
observar <- function(fn) tryCatch({
  nm <- names(localizar_switch(fn, "fn_de_prueba")); nm <- nm[nzchar(nm)]
  paste0("RESUELVE[", paste(nm, collapse = ","), "]")
}, error = function(e) "DETIENE")

comprobar <- function(bloque, rotulo, obtenido, esperado, nota = "") {
  ok <- identical(obtenido, esperado)
  if (!ok) fallos <<- c(fallos, sprintf("%s / %s: esperado %s, obtenido %s",
                                        bloque, rotulo, esperado, obtenido))
  cat(sprintf("  [%s] %-46s %-28s %s\n", if (ok) "ok  " else "FALLA", rotulo, obtenido,
              if (nzchar(nota)) nota else ""))
}

# ---- ast --------------------------------------------------------------------
if ("ast" %in% bloques) {
  cat("\n== ast: las 19 formas ==\n")
  cs <- list(
    list("switch(...) pelado", function(id) switch(as.character(id), "32"="a","37"="b"), "RESUELVE[32,37]"),
    list("base::switch(...)", function(id) { base::switch(as.character(id), "32"="a","37"="b") }, "RESUELVE[32,37]"),
    list("base:::switch(...)", function(id) { base:::switch(as.character(id), "32"="a","37"="b") }, "RESUELVE[32,37]"),
    list('do.call("switch", list(...))', function(id) { do.call("switch", list(as.character(id), "32"="a","37"="b")) }, "RESUELVE[32,37]"),
    list("do.call(switch, list(...))", function(id) { do.call(switch, list(as.character(id), "32"="a","37"="b")) }, "RESUELVE[32,37]"),
    list("precedido por sentencias", function(id) { stopifnot(length(id)==1L); x <- 1; switch(as.character(id), "32"="a") }, "RESUELVE[32]"),
    list("anidado en if + local", function(id) { if (TRUE) local({ switch(as.character(id), "32"="a") }) }, "RESUELVE[32]"),
    list("envuelto en invisible()", function(id) invisible(switch(as.character(id), "32"="a")), "RESUELVE[32]"),
    list('con fall-through "32" = ,', function(id) switch(as.character(id), "32"=,"33"="a","37"="b"), "RESUELVE[32,33,37]"),
    list("con indexado de argumento vacio", function(id) { m <- matrix(1:4,2)[!c(TRUE,FALSE), ,drop=FALSE]; switch(as.character(id),"32"="a") }, "RESUELVE[32]"),
    list("cero llamadas (cadena if/else)", function(id) { if (id == 32) "a" else "b" }, "DETIENE"),
    list("mas de una (dos hermanas)", function(id) { x <- switch(as.character(id),"32"="a"); y <- switch(as.character(id),"37"="b"); paste(x,y) }, "DETIENE"),
    list("do.call con variable local", function(id) { g <- "switch"; do.call(g, list(as.character(id),"32"="a")) }, "DETIENE"),
    list('do.call("switch", args no literal)', function(id) { L <- list(as.character(id),"32"="a"); do.call("switch", L) }, "DETIENE"),
    list("otro::switch (namespace != base)", function(id) { utils::switch(as.character(id), "32"="a") }, "DETIENE"),
    list("declaracion + anonima con switch", function(id) { aux <- function(k) switch(as.character(k),"a"=1); switch(as.character(id),"32"="x","37"="y") }, "RESUELVE[32,37]"),
    list("SOLO una anonima con switch", function(id) { aux <- function(k) switch(as.character(k),"a"=1,"b"=2); aux(id) }, "DETIENE"),
    list("anonima lambda + declaracion", function(id) { f <- \(k) switch(as.character(k),"a"=1); switch(as.character(id),"32"="x") }, "RESUELVE[32]"),
    list("'switch(' dentro de un string", function(id) { msg <- "llama a switch(x, a=1)"; switch(as.character(id),"32"="a") }, "RESUELVE[32]"))
  for (c1 in cs) comprobar("ast", c1[[1]], observar(c1[[2]]), c1[[3]])
}

# ---- real -------------------------------------------------------------------
# Las dos formas se insertan en el TEXTO de la funcion real leido del archivo, y
# se evalua el resultado. Asi la prueba mide la funcion que hay hoy, no una copia
# escrita a mano que se desincroniza en cuanto alguien toque el pipeline.
if ("real" %in% bloques) {
  cat("\n== real: capturas_crudas_de_paso() del archivo, con formas insertadas ==\n")
  ln  <- readLines("10_utils/10_utils.R", warn = FALSE, encoding = "UTF-8")
  ini <- grep("^capturas_crudas_de_paso <- function", ln)
  stopifnot(length(ini) == 1L)
  fin <- ini + which(ln[(ini + 1L):length(ln)] == "}")[1]
  cuerpo <- ln[ini:fin]

  variante <- function(texto) eval(parse(text = paste(sub("^capturas_crudas_de_paso <- ", "", texto), collapse = "\n")))
  base_ok <- variante(cuerpo)
  comprobar("real", "sin tocar (control)", observar(base_ok), "RESUELVE[32,33,34,35,36,37]")

  i32 <- grep('^    "32" = ', cuerpo)
  stopifnot(length(i32) == 1L)
  ft <- append(cuerpo, '    "38" = ,', after = i32 - 1L)
  comprobar("real", 'fall-through "38" = , antes de la 32', observar(variante(ft)),
            "RESUELVE[38,32,33,34,35,36,37]")

  ix <- append(cuerpo, "  aux <- matrix(1:4, 2)[!c(TRUE, FALSE), , drop = FALSE]", after = 1L)
  comprobar("real", "indexado con arg vacio (37:190)", observar(variante(ix)),
            "RESUELVE[32,33,34,35,36,37]")
}

# ---- contorno ---------------------------------------------------------------
if ("contorno" %in% bloques) {
  cat("\n== contorno: las tres condiciones que deben fallar ruidosamente ==\n")
  comprobar("contorno", "cuerpo sin ningun switch", observar(function(id) { if (id == 1) "a" else "b" }), "DETIENE")
  comprobar("contorno", "cuerpo con dos switch", observar(function(id, k) {
    x <- switch(as.character(id), "32"="a"); y <- switch(as.character(k), "1"="p"); paste(x, y) }), "DETIENE")
  comprobar("contorno", "switch solo en una function anidada", observar(function(id) {
    aux <- function(k) switch(as.character(k), "a"=1, "b"=2); aux(id) }), "DETIENE")
}

# ---- regresion --------------------------------------------------------------
# Los siete casos del panel. El esperado es el comportamiento del estado
# revertido. Seis de los siete son casos en que la guarda SE DETIENE ante codigo
# sano (falsos positivos) y el septimo es un FALSO NEGATIVO conocido: se declaran aqui como
# comportamiento vigente para que un cambio no pase inadvertido, NO como
# comportamiento deseable. Estan registrados como pendientes en el log.
if ("regresion" %in% bloques) {
  cat("\n== regresion: los siete casos del panel de la sesion 24 ==\n")
  disp <- switch   # ligadura de nivel de archivo, deliberada
  cs <- list(
    list("simbolo libre ligado a switch", function(id) {
      s <- switch("x","32"=1,"33"=1,"34"=1,"35"=1,"36"=1,"37"=1)
      do.call(disp, list(as.character(id),"32"="a","33"="b","34"="c","35"="d","36"="e")) },
      "DETIENE", "contrato: sin esto vuelve el falso negativo"),
    list("simbolo asignado solo en una anonima", function(id) {
      aux <- function() { k <- 1; k }; z <- do.call(k, list(1)); switch(as.character(id),"32"="a") },
      "DETIENE", "falso positivo vigente"),
    list("do.call(base::rbind, ...)", function(id) {
      z <- do.call(base::rbind, list(1)); switch(as.character(id),"32"="a") },
      "DETIENE", "falso positivo vigente"),
    list('do.call(quote=TRUE, "switch", ...)', function(id) do.call(quote = TRUE, "switch", list(as.character(id),"32"="a")),
      "DETIENE", "falso positivo vigente"),
    list('assign("h",...) ; do.call(h, ...)', function(id) {
      assign("h", rbind); z <- do.call(h, list(1)); switch(as.character(id),"32"="a") },
      "DETIENE", "contrato: sin esto vuelve el falso negativo"),
    list("quote(switch(...)) + el switch real", function(id) {
      doc <- quote(switch(x,"97"="a")); switch(as.character(id),"32"="a") },
      "DETIENE", "falso positivo vigente"),
    list("quote(...) y despacho por if/else", function(id) {
      doc <- quote(switch(id,"97"="a","98"="b","99"="c"))
      if (id == "32") "r32" else if (id == "33") "r33" else stop("no") },
      "RESUELVE[97,98,99]", "FALSO NEGATIVO conocido, documentado"))
  for (c1 in cs) comprobar("regresion", c1[[1]], observar(c1[[2]]), c1[[3]], c1[[4]])
}

# ---- veredicto --------------------------------------------------------------
cat("\n", strrep("-", 76), "\n", sep = "")
if (length(fallos) > 0L) {
  cat(sprintf("ARNES DEL LOCALIZADOR: %d caso(s) NO dieron lo esperado.\n", length(fallos)))
  cat(paste0("  - ", fallos), sep = "\n")
  quit(status = 1)
}
cat("ARNES DEL LOCALIZADOR: todos los casos dieron lo esperado.\n")
