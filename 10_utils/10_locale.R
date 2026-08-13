# =============================================================================
# 10_locale.R - Guarda de locale UTF-8 (generico, copiado desde herramientas_dev)
# =============================================================================
# Proposito : garantizar que ningun proceso de R corra con una locale de
#             caracteres no UTF-8, NI LANCE HIJOS QUE LO HAGAN. Un proceso
#             lanzado desde un shell sin locale (LC_CTYPE=C: cron, CI, shells
#             no interactivos) escribe TODO texto acentuado escapado como
#             <c3><a1>, sin emitir error alguno (evidencia: 4 xlsx del gemelo
#             con 5.665 escapes y cero tildes, sesion v108 de
#             slep_aprendizajes_ep).
# Contrato  : POLITICA_PROYECTO.md 6.2: este archivo se copia IDENTICO a
#             10_utils/10_locale.R de cada proyecto y NUNCA se edita por
#             proyecto. Si un proyecto necesita algo distinto, el helper esta
#             mal disenado y se corrige en herramientas_dev/plantillas/.
# Uso       : source(here::here("10_utils", "10_locale.R"))
#             asegurar_locale_utf8("<script que llama>")
# Diseno    : el assert ABORTA; nunca repara en silencio. Prohibido envolver
#             la llamada en try(..., silent = TRUE) o suppressWarnings():
#             una configuracion ausente tiene que producir un aborto ruidoso,
#             no una corrida que escribe tildes escapadas.
# Cero dependencias de paquetes. Solo ASCII: este archivo debe ser inmune a la
# condicion que verifica.
#
# --- Por que el helper EXPORTA y no solo FIJA (R36 de slep_reportes v48) -----
# Sys.setlocale() cambia la locale del proceso R en curso y deja LANG y LC_ALL
# tal como estaban en el entorno. Los procesos hijos heredan el ENTORNO, no la
# locale del padre: system(), system2(), quarto::quarto_render(), y el R que
# quarto levanta para ejecutar los chunks de un .qmd arrancan todos en C si el
# entorno venia vacio, y ahi la correccion del padre nunca se ejecuto. Sintoma
# medido en slep_reportes_modelo_resguardo_asistencia: 73/73 PDF con la locale
# exportada en el shell y 0/73 sin ella, con el mismo codigo y la misma
# autocorreccion de este helper activa en el proceso padre. Por eso la guarda
# fija Y exporta.
#
# Se exportan LANG y LC_CTYPE, NO LC_ALL. LC_ALL es un martillo: sobreescribe
# todas las categorias en cualquier hijo, incluida LC_NUMERIC, y arrastra la
# configuracion de un proyecto a procesos ajenos. LC_CTYPE es la unica
# categoria que gobierna la codificacion de caracteres, que es el problema que
# este archivo existe para resolver; LANG acompana como default de las demas
# categorias sin pisar lo que el usuario haya fijado explicitamente.
#
# --- El mensaje declara lo que ocurrio, no lo que se pretendia --------------
# La exportacion puede no ocurrir por dos motivos legitimos: LC_ALL viene
# fijado (gana sobre LANG y LC_CTYPE en cualquier hijo, asi que rellenarlos
# seria ruido sin efecto) o LANG y LC_CTYPE ya traen valor (manda el usuario).
# En esos casos el proceso queda corregido y los hijos NO. Un aviso que afirme
# la exportacion sin haberla hecho declara una cobertura que no existe, que es
# exactamente el defecto que este archivo persigue en el resto del sistema.
#
# --- Que cubre esta guarda y que NO (H1, H2 y H4 de la ola de locale) --------
# Tres hechos MEDIDOS en las sesiones del 2026-08-02 y 2026-08-03 acotan el
# alcance de esta guarda. Hay que leerlos antes de escribir cualquier criterio
# de aceptacion sobre locale, porque dos de ellos invalidan el criterio obvio.
#
# H1. writeLines() NO escapa. Pasa los bytes UTF-8 del literal tal cual aunque
#     el proceso corra en C, y el archivo sale UTF-8 valido (verificado con
#     xxd). El escape a <c3><a1> ocurre en OTRAS rutas de escritura (openxlsx,
#     quarto), que son de donde viene la evidencia que justifica POLITICA
#     5.2bis. Consecuencia: la guarda sigue siendo necesaria, pero su
#     justificacion NO es uniforme por ruta de escritura, y un criterio de
#     aceptacion que busque escapes en la salida es CIEGO en 16 de 17
#     escaneres de la cartera: su "0 coincidencias" no distingue una guarda
#     que sirve de una que no.
#
# H2. El efecto colateral medible es el ORDEN DE COLACION. En locale C se
#     ordena por bytes; con locale UTF-8, alfabeticamente. Eso es lo que
#     separo clase A de clase B en 12 de los 13 repos donde no habia ningun
#     escape que buscar. Un snapshot cuyo orden depende del shell que lo lance
#     no es reproducible, y eso solo ya justifica la guarda ahi donde H1 la
#     deja sin sintoma visible.
#
# H4. La guarda NO cubre la LECTURA, y la lectura falla en silencio. Con
#     LC_CTYPE=C, read.csv(ruta, fileEncoding = "UTF-8") devolvio 1 fila de
#     21, con dos warnings y sin error. El archivo era ASCII puro, sin BOM y
#     sin comillas (verificado con file, xxd y awk): el truncamiento era del
#     lector, no del dato. Sin el argumento fileEncoding lee las 21.
#     Consecuencia: un proceso con esta guarda instalada puede leer mal y
#     concluir bien con evidencia falsa. La sonda que destapo esto habria
#     reportado "0 coincidencias" sobre 1 de 21 filas, que es la conclusion
#     correcta sostenida en una medicion que no era.
#
#     Contramedida, tras TODA lectura de csv:
#         stopifnot(nrow(x) == length(readLines(ruta)) - 1L)
#     Vale para csv con cabecera y sin saltos de linea dentro de los campos.
#     Si los hay, el conteo de lineas no es el conteo de filas y hay que
#     comparar contra un lector de referencia, no contra readLines().
#
# Los rotulos H1, H2 y H4 son los de logs/20260802_sesion_locale_e3_validacion_
# y_cierre.md y logs/20260803_sesion_merge_locale_e4.md, y no se renumeran. H3
# y H5 de esos logs faltan aqui a proposito: son patrones de conducta del
# asistente y viven en gobernanza/catalogo_patrones_errores_v4.md (PAT-13).
# =============================================================================

# Locales UTF-8 aceptables, en orden de preferencia. Pobladas con lo que existe
# realmente en las maquinas de la cartera (macOS: verificado con `locale -a` el
# 2026-07-29) y en los runners de CI (ubuntu trae C.UTF-8 siempre).
# es_CL.UTF-8 NO existe en macOS: no agregarla (ocho bootstraps del piloto la
# intentaban primero y caian al fallback en silencio).
LOCALES_UTF8_CANDIDATAS <- c("es_ES.UTF-8", "en_US.UTF-8", "C.UTF-8")

#' Exportar la locale vigente al entorno, para que la hereden los hijos
#'
#' Solo rellena lo que falta: si LANG o LC_CTYPE ya traen un valor, no lo pisa
#' (el usuario o el .Renviron mandan sobre el helper). Si LC_ALL viene fijado,
#' tampoco hace nada: LC_ALL gana sobre LANG y LC_CTYPE en cualquier hijo, asi
#' que rellenarlos seria ruido sin efecto.
#'
#' @param valor string de locale a exportar (p. ej. "es_ES.UTF-8").
#' @return TRUE si escribio alguna variable, FALSE si no hizo falta.
#' @keywords internal
.exportar_locale_al_entorno <- function(valor) {
  if (!nzchar(valor)) return(FALSE)
  if (nzchar(Sys.getenv("LC_ALL"))) return(FALSE)

  faltantes <- character(0)
  if (!nzchar(Sys.getenv("LC_CTYPE"))) faltantes <- c(faltantes, "LC_CTYPE")
  if (!nzchar(Sys.getenv("LANG")))     faltantes <- c(faltantes, "LANG")
  if (length(faltantes) == 0L) return(FALSE)

  args        <- as.list(rep(valor, length(faltantes)))
  names(args) <- faltantes
  do.call(Sys.setenv, args)
  TRUE
}

#' Explicar por que la exportacion no ocurrio
#'
#' Se llama solo cuando .exportar_locale_al_entorno() devolvio FALSE tras una
#' correccion exitosa del proceso. Nombra la causa concreta en vez de callar.
#'
#' @return string listo para concatenar al message().
#' @keywords internal
.motivo_sin_exportar <- function() {
  if (nzchar(Sys.getenv("LC_ALL"))) {
    return(paste0(
      "\n  El entorno NO se modifico: LC_ALL viene fijado en '",
      Sys.getenv("LC_ALL"), "' y gana sobre LANG y LC_CTYPE en cualquier hijo.",
      "\n  Los procesos hijos (quarto, typst, system2) arrancaran con esa",
      "\n  locale y NO con la correccion de este proceso."
    ))
  }
  paste0(
    "\n  El entorno NO se modifico: LANG y LC_CTYPE ya venian declarados",
    " (LANG='", Sys.getenv("LANG"), "', LC_CTYPE='", Sys.getenv("LC_CTYPE"), "').",
    "\n  Manda lo que declaro el usuario; los hijos heredaran eso."
  )
}

#' Asegurar que el proceso corre con locale de caracteres UTF-8
#'
#' Si la locale ya es UTF-8, no la toca. Si no lo es, intenta UNA vez
#' corregirla recorriendo LOCALES_UTF8_CANDIDATAS; si lo logra avisa por
#' message() (una locale corregida en caliente es un sintoma de entorno mal
#' configurado, no una victoria); si no lo logra, stop() con el remedio.
#'
#' En ambos casos de exito exporta la locale al entorno si venia vacio, para
#' que los procesos hijos no arranquen en C (ver cabecera, R36). Cuando la
#' exportacion no ocurre, el mensaje lo dice y nombra la causa.
#'
#' @param contexto string con el nombre del script que llama (para el mensaje).
#' @return invisible(TRUE) si la locale queda UTF-8; stop() si no se pudo.
asegurar_locale_utf8 <- function(contexto = "pipeline") {

  # Rama 1: la locale del proceso ya es UTF-8. Aun asi el entorno puede estar
  # vacio (macOS lanzado desde un shell no interactivo, o un padre que ya
  # corrigio con Sys.setlocale sin exportar), y entonces los hijos arrancarian
  # en C. Rellenar el entorno es la unica accion pendiente.
  if (isTRUE(l10n_info()[["UTF-8"]])) {
    if (.exportar_locale_al_entorno(Sys.getlocale("LC_CTYPE"))) {
      message(
        "[ locale ] ", contexto, ": la locale del proceso era UTF-8 pero el\n",
        "  entorno no la declaraba. Se exportaron LANG y LC_CTYPE para que los\n",
        "  procesos hijos (quarto, typst, system2) no arranquen en C."
      )
    }
    return(invisible(TRUE))
  }

  desde <- Sys.getlocale("LC_CTYPE")

  # Sin try() ni suppressWarnings() a proposito: una candidata inexistente
  # avisa por warning del propio R y se prueba la siguiente. El exito se
  # comprueba contra l10n_info(), no contra el valor de retorno: en algunos
  # sistemas Sys.setlocale() devuelve string no vacio aunque no haya quedado
  # UTF-8.
  for (candidata in LOCALES_UTF8_CANDIDATAS) {
    Sys.setlocale("LC_ALL", candidata)
    if (isTRUE(l10n_info()[["UTF-8"]])) {
      # Exportar ANTES del message, para que el aviso pueda declarar el efecto
      # completo en una sola lectura. El valor de retorno se captura: sin el,
      # el aviso afirmaria una exportacion que puede no haber ocurrido.
      exporto <- .exportar_locale_al_entorno(candidata)
      message(
        "[ locale ] ", contexto, ": locale corregida en caliente a ", candidata,
        " (el proceso arranco con ", desde, ")",
        if (isTRUE(exporto)) {
          "\n  y exportada al entorno (LANG, LC_CTYPE) para los procesos hijos."
        } else {
          .motivo_sin_exportar()
        },
        "\n  Es un sintoma de entorno mal configurado, no una victoria: otro\n",
        "  proceso R de esta maquina puede arrancar igual y escribir texto\n",
        "  acentuado escapado. Remedio permanente: agregar la linea LANG de\n",
        "  .Renviron.example a ~/.Renviron y reiniciar R."
      )
      return(invisible(TRUE))
    }
  }

  stop(
    "[ locale ] ABORTADO en ", contexto, ": el proceso corre sin locale UTF-8 ",
    "y no se pudo corregir.\n",
    "  LC_CTYPE actual    : ", Sys.getlocale("LC_CTYPE"), "\n",
    "  Candidatas probadas: ", paste(LOCALES_UTF8_CANDIDATAS, collapse = ", "), "\n",
    "  Consecuencia: todo texto acentuado que este proceso escriba quedara\n",
    "  escapado como <c3><a1> (xlsx, json, html), sin error visible.\n",
    "  Remedio: agregar LANG (ver .Renviron.example) a ~/.Renviron y reiniciar R.",
    call. = FALSE
  )
}
