# =============================================================================
# 50_fusible_red.R
# -----------------------------------------------------------------------------
# Proposito: impedir, por construccion, que una prueba del pipeline llegue a la
#            red. No cuenta llamadas para avisar al final: MATA el proceso en la
#            primera invocacion.
#
# POR QUE UN FUSIBLE Y NO UN CONTADOR. Un contador es un instrumento de medicion,
# no una barrera: reporta despues de que el dano ocurrio. En la sesion 18 una
# prueba de la guarda del bot corrio con contador y descargo el anno completo
# (3230 llamadas, 6 capturas nuevas) antes de que nadie se enterara; el invariante
# que lo prohibia era una regla de juicio, y el juicio fallo. Esto lo reemplaza
# por algo que no depende de acordarse.
#
# POR QUE quit() Y NO stop(). Un stop() dentro del tracer es una condicion de
# clase "error", y el pipeline la atrapa: descargar_xml_camara() la reintenta 4
# veces y capturar_xml_detalle() (36) la convierte en una fila con
# estado = error_red y SIGUE. Es decir, un fusible que usa stop() no detiene la
# corrida: la degrada en silencio, que es peor que no tenerlo. quit() no es una
# condicion y no hay tryCatch que lo intercepte.
#
# El tracer corre al ENTRAR a la funcion, antes de cualquier E/S: la llamada que
# lo dispara nunca llega a salir a la red.
#
# Uso:
#   source("50_documentacion/andamios/50_fusible_red.R")
#   instalar_fusible_red()          # a partir de aqui, cualquier HTTP mata el proceso
# Codigo de salida al disparar: 99.
#
# Autor: Claude Code (encargo reparacion guarda bot, sesion 18)
# Creado: 2026-08-09
# =============================================================================

FUSIBLE_RED_STATUS <- 99L

FUSIBLE_RED_FUNCIONES <- list(
  c("httr", "GET"), c("httr", "POST"), c("httr", "RETRY"),
  c("curl", "curl_fetch_memory"))

instalar_fusible_red <- function(silencioso = FALSE) {
  instaladas <- character(0)
  for (par in FUSIBLE_RED_FUNCIONES) {
    if (!requireNamespace(par[1], quietly = TRUE)) next
    trace(par[2], where = asNamespace(par[1]), print = FALSE,
          tracer = quote({
            cat("\n*** FUSIBLE DE RED DISPARADO ***\n")
            cat("Una llamada HTTP intento salir durante una prueba que declara cero red.\n")
            cat("El proceso se mata AQUI, antes de que la llamada salga: la prueba no\n")
            cat("puede completarse y avisar despues, que es como se cuela un refresh.\n")
            cat(sprintf("Pila de llamadas (%d marcos):\n", sys.nframe()))
            for (.f in seq_len(sys.nframe() - 1L))
              cat(sprintf("  [%02d] %s\n", .f,
                          paste(deparse(sys.call(.f)), collapse = " ")[1]))
            quit(save = "no", status = 99L, runLast = FALSE)
          }))
    instaladas <- c(instaladas, paste0(par[1], "::", par[2]))
  }
  if (length(instaladas) == 0)
    stop("instalar_fusible_red: no se pudo trazar ninguna funcion de red.", call. = FALSE)
  if (!silencioso)
    cat(sprintf("Fusible de red ARMADO sobre %d funciones: %s\n",
                length(instaladas), paste(instaladas, collapse = ", ")))
  invisible(instaladas)
}
