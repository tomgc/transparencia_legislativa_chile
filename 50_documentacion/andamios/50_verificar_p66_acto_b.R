# =============================================================================
# 50_verificar_p66_acto_b.R
# -----------------------------------------------------------------------------
# Arnes de verificacion del encargo P-66 acto b
# (50_documentacion/andamios/50_encargo_p66_acto_b_construccion.md).
#
# Uso: Rscript 50_documentacion/andamios/50_verificar_p66_acto_b.R <fase>
#      fase: "f0bis" (retrocompatibilidad del destino de cache)
#            "f2"    (guardas del extractor de tramitacion, por escenario)
#
# CERO RED. Cada escenario que ejercita el pipeline corre EN SU PROPIO PROCESO
# con el fusible de 50_fusible_red.R instalado: un stop() no basta como barrera
# porque el 36 lo atrapa y lo degrada a estado = error_red (ver el encabezado del
# fusible). El fusible usa quit(99), que ningun tryCatch intercepta.
#
# Autor: Claude Code (encargo P-66 acto b, sesion 21)
# Creado: 2026-08-13
# =============================================================================

suppressWarnings(suppressMessages({
  ROOT <- rprojroot::find_root(rprojroot::has_file(".here"))
  source(file.path(ROOT, "10_utils", "10_locale.R"))
  asegurar_locale_utf8("50_verificar_p66_acto_b")
}))
options(width = 200)

fase <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(fase)) fase <- "f0bis"

titulo <- function(x) cat("\n", strrep("=", 78), "\n", x, "\n", strrep("=", 78), "\n", sep = "")
linea  <- function(...) cat(sprintf(...), "\n", sep = "")

# Ejecuta un script R en SUBPROCESO y devuelve status y salida. Sin esto, un
# quit(99) del fusible mataria el arnes entero en vez del escenario.
correr_aislado <- function(codigo) {
  f <- tempfile(fileext = ".R")
  writeLines(codigo, f)
  salida <- suppressWarnings(system2("Rscript", shQuote(f), stdout = TRUE, stderr = TRUE))
  st <- attr(salida, "status")
  list(status = if (is.null(st)) 0L else as.integer(st),
       salida = paste(salida, collapse = "\n"))
}

# =============================================================================
# F0bis - el destino de cache es parametrizable SIN cambiar ninguna ruta previa
# =============================================================================
# La afirmacion a refutar es "esta extension no cambia ninguna ruta existente".
# No se comprueba leyendo el codigo: se computa la bateria completa de rutas
# reales con el 10_utils.R de HEAD y con el del arbol de trabajo, en dos procesos
# distintos, y se comparan cadena por cadena.
verificar_f0bis <- function() {
  titulo("F0bis - retrocompatibilidad del destino de cache")

  # Bateria: TODA llave de cache que el pipeline usa hoy, con su tope real, mas
  # las rutas que capturas_crudas_de_paso() construye para los 5 extractores.
  # Se resuelve con corte implicito (la global) y con corte explicito, porque son
  # dos caminos distintos dentro de corte_para_clave().
  bateria <- '
    ROOT <- rprojroot::find_root(rprojroot::has_file(".here"))
    source(commandArgs(trailingOnly = TRUE)[1])          # el 10_utils.R a probar
    source(file.path(ROOT, "10_utils", "10_configuracion.R"))
    r <- character(0)
    add <- function(etiqueta, valor) r[[etiqueta]] <<- valor
    add("32_diputados",        ruta_cache("diputados"))
    add("33_periodo",          ruta_cache("periodo_legislativo"))
    add("33_asistencia",       ruta_cache(sprintf("asistencia_nominal_%d", ANIO_PROCESO), MAX_SESIONES_DETALLE))
    add("34_votos",            ruta_cache(sprintf("votos_long_%d", ANIO_PROCESO), MAX_VOTACIONES_DETALLE))
    add("35_proyectos",        ruta_cache(sprintf("proyectos_long_%d", ANIO_PROCESO), MAX_PROYECTOS_DETALLE))
    add("36_detalle_xml",      ruta_cache(sprintf("detalle_proyectos_xml_%d", ANIO_PROCESO), Inf))
    add("tope_NULL",           ruta_cache("sintetico"))
    add("tope_Inf",            ruta_cache("sintetico", Inf))
    add("tope_100",            ruta_cache("sintetico", 100))
    add("corte_explicito",     ruta_cache("sintetico", Inf, corte = "2026-07-27"))
    for (id in c("32","33","34","35","36")) {
      add(paste0("paso_", id, "_implicito"), paste(capturas_crudas_de_paso(id), collapse = "|"))
      add(paste0("paso_", id, "_explicito"),
          paste(capturas_crudas_de_paso(id, corte = "2026-07-27"), collapse = "|"))
    }
    saveRDS(r, commandArgs(trailingOnly = TRUE)[2])
  '
  f_bat <- tempfile(fileext = ".R"); writeLines(bateria, f_bat)

  # 10_utils.R de HEAD, extraido a un temporal: la referencia no es mi lectura
  # del diff, es el archivo que estaba antes.
  f_head <- tempfile(fileext = ".R")
  writeLines(system2("git", c("-C", shQuote(ROOT), "show", "HEAD:10_utils/10_utils.R"),
                     stdout = TRUE), f_head)
  f_now <- file.path(ROOT, "10_utils", "10_utils.R")

  out_head <- tempfile(fileext = ".rds"); out_now <- tempfile(fileext = ".rds")
  s1 <- system2("Rscript", c(shQuote(f_bat), shQuote(f_head), shQuote(out_head)),
                stdout = TRUE, stderr = TRUE)
  s2 <- system2("Rscript", c(shQuote(f_bat), shQuote(f_now), shQuote(out_now)),
                stdout = TRUE, stderr = TRUE)
  if (!file.exists(out_head)) stop("F0bis: la bateria fallo con el 10_utils.R de HEAD:\n",
                                   paste(s1, collapse = "\n"), call. = FALSE)
  if (!file.exists(out_now))  stop("F0bis: la bateria fallo con el 10_utils.R actual:\n",
                                   paste(s2, collapse = "\n"), call. = FALSE)

  a <- readRDS(out_head); b <- readRDS(out_now)
  stopifnot(identical(names(a), names(b)))
  iguales <- vapply(names(a), function(k) identical(a[[k]], b[[k]]), logical(1))
  linea("C1 rutas identicas HEAD vs arbol : %d de %d", sum(iguales), length(iguales))
  if (!all(iguales)) {
    for (k in names(a)[!iguales])
      linea("   DIFIERE %-24s HEAD=%s  AHORA=%s", k, a[[k]], b[[k]])
    stop("F0bis: la extension cambio rutas existentes. No es retrocompatible.", call. = FALSE)
  }

  # C2: el parametro nuevo efectivamente enruta a otra carpeta.
  cod <- sprintf('
    ROOT <- rprojroot::find_root(rprojroot::has_file(".here"))
    source(file.path(ROOT, "10_utils", "10_utils.R"))
    source(file.path(ROOT, "10_utils", "10_configuracion.R"))
    cat(ruta_cache("tramitacion_sil_2026", Inf, subdir = "senado"), "\\n")
    cat(ruta_cache("tramitacion_sil_2026", Inf), "\\n")
    cat(paste(DIRECTORIOS_CRUDO, collapse = ","), "\\n")')
  r2 <- correr_aislado(cod)
  linea("C2 destino parametrizado         : status=%d", r2$status)
  cat(r2$salida, "\n")

  # C3: el stop() que hoy provoca un corte sin capturas SIGUE ocurriendo. Se
  # ejercita en subproceso y con el fusible armado, aunque esta funcion no toque
  # la red: el arnes no hace excepciones por conveniencia.
  cod3 <- '
    ROOT <- rprojroot::find_root(rprojroot::has_file(".here"))
    source(file.path(ROOT, "50_documentacion", "andamios", "50_fusible_red.R"))
    instalar_fusible_red(silencioso = TRUE)
    source(file.path(ROOT, "10_utils", "10_utils.R"))
    source(file.path(ROOT, "10_utils", "10_configuracion.R"))
    r <- tryCatch({ reportar_estado_capturas(corte = "1999-01-01"); "NO SE DETUVO" },
                  error = function(e) paste("STOP:", conditionMessage(e)))
    cat(r, "\n")'
  r3 <- correr_aislado(cod3)
  ok3 <- grepl("STOP:", r3$salida, fixed = TRUE)
  linea("C3 stop() con corte sin capturas  : %s", if (ok3) "CUMPLE" else "FALLA")
  cat("   ", sub("\n.*", "", r3$salida), "\n", sep = "")

  # C4: el directorio nuevo tambien esta bajo la guarda. Mientras F1 no lo pueble,
  # este stop() es el estado correcto y esperado, no un defecto.
  cod4 <- '
    ROOT <- rprojroot::find_root(rprojroot::has_file(".here"))
    source(file.path(ROOT, "50_documentacion", "andamios", "50_fusible_red.R"))
    instalar_fusible_red(silencioso = TRUE)
    source(file.path(ROOT, "10_utils", "10_utils.R"))
    source(file.path(ROOT, "10_utils", "10_configuracion.R"))
    r <- tryCatch({ reportar_estado_capturas(subdirs = "senado"); "NO SE DETUVO" },
                  error = function(e) paste("STOP:", conditionMessage(e)))
    cat(r, "\n")'
  r4 <- correr_aislado(cod4)
  ok4 <- grepl("STOP:", r4$salida, fixed = TRUE)
  linea("C4 guarda cubre el directorio nuevo: %s", if (ok4) "CUMPLE" else "FALLA")
  cat("   ", sub("\n.*", "", r4$salida), "\n", sep = "")

  # C5: las tres funciones que el 🔒 protege no tienen una sola linea tocada.
  d <- system2("git", c("-C", shQuote(ROOT), "diff", "--stat", "HEAD", "--",
                        "10_utils/10_utils.R"), stdout = TRUE)
  linea("C5 diff de 10_utils.R             : %s", paste(trimws(d), collapse = " | "))

  # C6: las funciones que el 🔒 protege, comparadas por CUERPO y no por el tamano
  # del diff. `git diff --stat` dice cuanto cambio el archivo, no si cambio una
  # funcion concreta; el criterio del encargo es "sin una sola linea tocada", y
  # eso se prueba deparseando cada funcion en las dos versiones.
  protegidas <- c("sellar", "leer_sellado", "validar_corte", "escribir_atomico",
                  "corte_para_clave", "sufijo_tope")
  cod6 <- sprintf('
    ROOT <- rprojroot::find_root(rprojroot::has_file(".here"))
    source(commandArgs(trailingOnly = TRUE)[1])
    fs <- c(%s)
    r <- vapply(fs, function(f) paste(deparse(get(f)), collapse = "\\n"), character(1))
    saveRDS(r, commandArgs(trailingOnly = TRUE)[2])',
    paste(sprintf('"%s"', protegidas), collapse = ", "))
  f6 <- tempfile(fileext = ".R"); writeLines(cod6, f6)
  o6h <- tempfile(fileext = ".rds"); o6n <- tempfile(fileext = ".rds")
  system2("Rscript", c(shQuote(f6), shQuote(f_head), shQuote(o6h)), stdout = TRUE, stderr = TRUE)
  system2("Rscript", c(shQuote(f6), shQuote(f_now),  shQuote(o6n)), stdout = TRUE, stderr = TRUE)
  p_h <- readRDS(o6h); p_n <- readRDS(o6n)
  ok6 <- vapply(protegidas, function(f) identical(p_h[[f]], p_n[[f]]), logical(1))
  linea("C6 funciones protegidas identicas : %d de %d", sum(ok6), length(ok6))
  for (f in protegidas)
    linea("   %-18s %s", f, if (ok6[[f]]) "IDENTICA" else "CAMBIO")

  linea("\nF0bis: C1 %s, C3 %s, C4 %s, C6 %s",
        if (all(iguales)) "CUMPLE" else "FALLA",
        if (ok3) "CUMPLE" else "FALLA", if (ok4) "CUMPLE" else "FALLA",
        if (all(ok6)) "CUMPLE" else "FALLA")
  invisible(all(iguales) && ok3 && ok4 && all(ok6))
}

if (identical(fase, "f0bis")) verificar_f0bis() else
  stop(sprintf("fase desconocida: '%s'", fase), call. = FALSE)
