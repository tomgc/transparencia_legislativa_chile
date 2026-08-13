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

# =============================================================================
# Cargador de DEFINICIONES, sin efectos de lado
# -----------------------------------------------------------------------------
# Un script de 30_procesamiento/ corre de arriba a abajo: source() lo ejecuta
# entero, incluida la descarga. Para probar su parser sin red hay que evaluar
# SOLO las asignaciones de nivel superior que definen funciones y constantes,
# saltando toda llamada con efecto (source, library, con_cache, saveRDS...).
# Asi la prueba ejercita el codigo REAL del paso, no una copia paralela que
# podria divergir de el sin que nadie lo note.
cargar_definiciones <- function(archivo) {
  exprs <- parse(archivo)
  e <- new.env(parent = globalenv())
  es_asignacion <- function(x) is.call(x) && length(x) == 3L &&
    as.character(x[[1]])[1] %in% c("<-", "=")
  for (ex in exprs) {
    if (!es_asignacion(ex)) next
    rhs <- ex[[3]]
    definible <- (is.call(rhs) && as.character(rhs[[1]])[1] %in% c("function", "c")) ||
                 is.character(rhs) || is.numeric(rhs) || is.logical(rhs)
    if (definible) tryCatch(eval(ex, envir = e), error = function(err) invisible(NULL))
  }
  e
}

# =============================================================================
# F1 - el parser del 37, ejercitado sin red contra los 427 XML del acto A
# =============================================================================
verificar_f1 <- function() {
  titulo("F1 - parser de tramitacion contra los XML ya descargados (cero red)")

  DIR_EXP <- file.path(ROOT, "20_insumos", "exploracion", "20260813")
  pedidos <- readRDS(file.path(DIR_EXP, "p66_g4_pedidos.rds"))
  rutas   <- file.path(DIR_EXP, paste0("p66_g4_", sub("-.*$", "", pedidos), ".xml"))
  linea("XML de la exploracion disponibles : %d de %d pedidos",
        sum(file.exists(rutas)), length(pedidos))
  stopifnot(all(file.exists(rutas)))

  e <- cargar_definiciones(file.path(ROOT, "30_procesamiento", "37_extraer_tramitacion.R"))
  faltan <- setdiff(c("parsear_tramitacion_sil", "acotar_tramites_al_corte",
                      "tramites_vacio", "TRAMITES_COLUMNAS", "numero_de_boletin"),
                    ls(e))
  if (length(faltan) > 0)
    stop(sprintf("F1: el cargador no obtuvo %s del 37.", paste(faltan, collapse = ", ")),
         call. = FALSE)
  linea("definiciones cargadas del 37       : %s", paste(sort(ls(e)), collapse = ", "))

  CORTE <- "2026-08-12"
  res <- lapply(seq_along(pedidos), function(k) {
    p <- e$parsear_tramitacion_sil(readLines(rutas[k], warn = FALSE) |> paste(collapse = "\n"))
    crudos <- p$tramites
    tr <- e$acotar_tramites_al_corte(crudos, CORTE)
    list(boletin = pedidos[k], reconocido = p$reconocido,
         devuelto = p$boletin_devuelto, etapa = p$etapa_actual, estado = p$estado,
         ley = p$ley_numero, subetapa = p$subetapa,
         n_crudos = nrow(crudos), n_acotado = nrow(tr),
         esquema_ok = identical(names(tr), e$TRAMITES_COLUMNAS))
  })

  lleno <- function(v) !is.na(v) & nzchar(trimws(v))
  g <- function(campo) vapply(res, function(x) as.character(x[[campo]] %||% NA_character_), character(1))
  N <- length(res)
  reconocidos <- sum(vapply(res, function(x) isTRUE(x$reconocido), logical(1)))
  n_crudos    <- sum(vapply(res, function(x) as.integer(x$n_crudos), integer(1)))
  n_acotado   <- sum(vapply(res, function(x) as.integer(x$n_acotado), integer(1)))
  coincide    <- sum(vapply(res, function(x)
    identical(sub("-.*$", "", as.character(x$devuelto)), sub("-.*$", "", x$boletin)), logical(1)))
  esquema     <- sum(vapply(res, function(x) isTRUE(x$esquema_ok), logical(1)))

  linea("")
  linea("boletines pedidos                  : %d", N)
  linea("reconocidos por el parser          : %d de %d", reconocidos, N)
  linea("boletin devuelto == pedido         : %d de %d", coincide, N)
  linea("esquema de tramites canonico       : %d de %d", esquema, N)
  linea("tramites ANTES del acotamiento     : %d", n_crudos)
  linea("tramites DESPUES del acotamiento   : %d", n_acotado)
  linea("descartados por corte > %s   : %d", CORTE, n_crudos - n_acotado)
  linea("etapa no vacia                     : %d de %d", sum(lleno(g("etapa"))), N)
  linea("estado no vacio                    : %d de %d", sum(lleno(g("estado"))), N)
  linea("ley_numero no vacio                : %d de %d", sum(lleno(g("ley"))), N)
  linea("subetapa no vacia                  : %d de %d", sum(lleno(g("subetapa"))), N)
  linea("valores distintos de etapa         : %d", length(unique(trimws(g("etapa")[lleno(g("etapa"))]))))
  linea("valores distintos de estado        : %d", length(unique(trimws(g("estado")[lleno(g("estado"))]))))

  # Comparacion contra la ficha del acto A. Una diferencia es un resultado a
  # explicar, no un error a ocultar: por eso se imprimen las dos cifras.
  linea("")
  linea("--- contraste con la ficha del acto A (medicion del mismo corte) ---")
  cmp <- function(et, medido, ficha) linea("  %-34s medido=%-6s ficha=%-6s %s", et, medido, ficha,
                                           if (identical(as.integer(medido), as.integer(ficha)))
                                             "COINCIDE" else "DIFIERE")
  cmp("boletines resueltos", reconocidos, 427L)
  cmp("tramites totales (sin acotar)", n_crudos, 4799L)
  cmp("etapa no vacia", sum(lleno(g("etapa"))), 427L)
  cmp("estado no vacio", sum(lleno(g("estado"))), 427L)
  cmp("ley_numero no vacio", sum(lleno(g("ley"))), 28L)
  cmp("valores distintos de etapa", length(unique(trimws(g("etapa")[lleno(g("etapa"))]))), 12L)
  cmp("valores distintos de estado", length(unique(trimws(g("estado")[lleno(g("estado"))]))), 4L)

  # El acotamiento tiene que morder exactamente donde el acto A dijo: el boletin
  # 18507-04 con un tramite del 13/08/2026.
  afectados <- vapply(res, function(x) x$n_crudos > x$n_acotado, logical(1))
  linea("")
  linea("boletines con tramites descartados : %d -> %s", sum(afectados),
        paste(vapply(res[afectados], function(x) x$boletin, character(1)), collapse = ", "))
  invisible(TRUE)
}

# =============================================================================
# F2 - guardas del extractor, escenario por escenario
# =============================================================================
# Cada escenario declara su resultado ESPERADO antes de correrse y se compara
# con el observado. Todos corren en subproceso con el fusible de red armado: si
# alguno intentara salir a la red, el proceso muere con 99 y el escenario cuenta
# como fallo, no como exito silencioso.
verificar_f2 <- function() {
  titulo("F2 - guardas del extractor de tramitacion, por escenario")

  # Preambulo comun de cada subproceso: fusible primero, definiciones despues.
  pre <- '
    ROOT <- rprojroot::find_root(rprojroot::has_file(".here"))
    source(file.path(ROOT, "50_documentacion", "andamios", "50_fusible_red.R"))
    instalar_fusible_red(silencioso = TRUE)
    source(file.path(ROOT, "10_utils", "10_utils.R"))
    suppressWarnings(suppressMessages(library(dplyr)))   # derivar_tramitacion() usa tibble()/bind_rows()
    source(file.path(ROOT, "10_utils", "10_configuracion.R"))
    src <- parse(file.path(ROOT, "30_procesamiento", "37_extraer_tramitacion.R"))
    e <- new.env(parent = globalenv())
    for (ex in src) {
      if (is.call(ex) && length(ex) == 3L && as.character(ex[[1]])[1] %in% c("<-", "=")) {
        rhs <- ex[[3]]
        if ((is.call(rhs) && as.character(rhs[[1]])[1] %in% c("function", "c")) ||
            is.character(rhs) || is.numeric(rhs) || is.logical(rhs))
          try(eval(ex, envir = e), silent = TRUE)
      }
    }
    prueba <- function(expr) tryCatch({ v <- expr; paste("SIN STOP ->", paste(utils::capture.output(str(v))[1], collapse=" ")) },
                                      error = function(err) paste("STOP:", conditionMessage(err)))
  '
  esc <- list(
    list(id = "E1 corte ausente (CORTE_FECHA vacia)",
         esperado = "STOP",
         cod = 'CORTE_FECHA <- ""; cat(prueba(corte_para_clave()), "\n")'),
    list(id = "E2 corte con formato invalido",
         esperado = "STOP",
         cod = 'tr <- data.frame(fecha="2026-08-01", fecha_fuente="01/08/2026", camara="x",
                                 etapa="x", descripcion="x", sesion="x", stringsAsFactors=FALSE)
                cat(prueba(e$acotar_tramites_al_corte(tr, "12-08-2026")), "\n")'),
    list(id = "E3 respuesta no 200 -> no se persiste crudo",
         esperado = "xml NA y estado error_red, sin stop",
         cod = 'cap <- data.frame(boletin="1-1", xml=NA_character_, estado="error_red",
                                  estado_detalle="HTTP 503", stringsAsFactors=FALSE)
                r <- e$derivar_tramitacion(cap, "2026-08-12")
                cat(sprintf("resuelto=%s n_tramites=%d etapa_NA=%s xml_persistido=%s\n",
                            r$resuelto[1], r$n_tramites[1], is.na(r$etapa_actual[1]), !is.na(cap$xml[1])))'),
    list(id = "E4 XML malformado",
         esperado = "STOP",
         cod = 'cat(prueba(e$parsear_tramitacion_sil("<proyectos><proyecto>")), "\n")'),
    list(id = "E5 boletin que el SIL no resuelve",
         esperado = "reconocido=FALSE, 0 tramites, sin fabricar campos",
         cod = 'p <- e$parsear_tramitacion_sil("<proyectos></proyectos>")
                cat(sprintf("reconocido=%s n_tramites=%d etapa_NA=%s esquema_ok=%s\n",
                            p$reconocido, nrow(p$tramites), is.na(p$etapa_actual),
                            identical(names(p$tramites), e$TRAMITES_COLUMNAS)))'),
    list(id = "E6 tramite posterior al corte",
         esperado = "descartado y contado (1 de 2)",
         cod = 'tr <- data.frame(fecha=c("2026-08-11","2026-08-13"),
                                 fecha_fuente=c("11/08/2026","13/08/2026"),
                                 camara=c("a","b"), etapa=c("a","b"),
                                 descripcion=c("a","b"), sesion=c("a","b"), stringsAsFactors=FALSE)
                o <- e$acotar_tramites_al_corte(tr, "2026-08-12")
                cat(sprintf("antes=%d despues=%d descartados=%d\n", nrow(tr), nrow(o), nrow(tr)-nrow(o)))'),
    list(id = "E7 fecha ilegible en un tramite",
         esperado = "STOP",
         cod = 'tr <- data.frame(fecha=c("2026-08-11", NA), fecha_fuente=c("11/08/2026","32/13/2026"),
                                 camara=c("a","b"), etapa=c("a","b"),
                                 descripcion=c("a","b"), sesion=c("a","b"), stringsAsFactors=FALSE)
                cat(prueba(e$acotar_tramites_al_corte(tr, "2026-08-12")), "\n")'),
    list(id = "E8 tabla de tramites sin columna fecha",
         esperado = "STOP",
         cod = 'tr <- data.frame(camara="a", etapa="b", stringsAsFactors=FALSE)
                cat(prueba(e$acotar_tramites_al_corte(tr, "2026-08-12")), "\n")')
  )

  linea("%-42s %-46s %s", "escenario", "esperado", "observado")
  linea("%s", strrep("-", 150))
  ok <- logical(length(esc))
  for (k in seq_along(esc)) {
    r <- correr_aislado(paste(pre, esc[[k]]$cod, sep = "\n"))
    obs <- trimws(paste(utils::tail(strsplit(r$salida, "\n")[[1]], 1), collapse = " "))
    if (r$status == 99L) obs <- "FUSIBLE DISPARADO (intento de red)"
    # Un escenario que NO espera stop() solo es conforme si ademas termino bien.
    # La primera version aceptaba "cualquier salida no vacia", y con eso un
    # "Ejecucion interrumpida" pasaba por conforme: un falso verde en el propio
    # arnes, que es exactamente lo que un arnes no puede permitirse.
    ok[k] <- if (identical(esc[[k]]$esperado, "STOP")) grepl("^STOP:", obs) else
             r$status == 0L && nzchar(obs) &&
             !grepl("FUSIBLE|Error|Ejecuci", obs)
    linea("%-42s %-46s %s", esc[[k]]$id, esc[[k]]$esperado, substr(obs, 1, 96))
  }
  linea("\nEscenarios conformes: %d de %d", sum(ok), length(ok))

  # E9: el cuadre D38 sobre la captura REAL. Se ejercita moviendo la captura a un
  # respaldo, poniendo una truncada, corriendo el paso y restaurando. El md5 se
  # comprueba antes y despues: si la restauracion fallara, la prueba lo dice.
  cache <- file.path(ROOT, "20_insumos", "senado",
                     "20260812_tramitacion_sil_2026_tope-inf.rds")
  md5_antes <- unname(tools::md5sum(cache))
  bak <- tempfile(fileext = ".rds"); file.copy(cache, bak, overwrite = TRUE)
  obj <- readRDS(cache); truncada <- obj[seq_len(nrow(obj) - 3L), ]
  attributes(truncada) <- utils::modifyList(attributes(truncada),
                                            attributes(obj)[c("captura_temporal")])
  saveRDS(truncada, cache)
  r9 <- correr_aislado(paste0(
    'ROOT <- rprojroot::find_root(rprojroot::has_file(".here"))\n',
    'source(file.path(ROOT, "50_documentacion", "andamios", "50_fusible_red.R"))\n',
    'instalar_fusible_red(silencioso = TRUE)\n',
    'r <- tryCatch({ source(file.path(ROOT, "30_procesamiento", "37_extraer_tramitacion.R"),\n',
    '                       chdir = TRUE); "NO SE DETUVO" },\n',
    '              error = function(e) paste("STOP:", conditionMessage(e)))\n',
    'cat("RESULTADO:", r, "\\n")'))
  file.copy(bak, cache, overwrite = TRUE)
  md5_despues <- unname(tools::md5sum(cache))
  detuvo <- grepl("RESULTADO: STOP", r9$salida, fixed = TRUE) || r9$status != 0L
  linea("\nE9 cuadre D38 con captura truncada  esperado=STOP  observado=%s",
        if (detuvo) "STOP" else "NO SE DETUVO")
  linea("   captura restaurada intacta        : %s (md5 %s)",
        if (identical(md5_antes, md5_despues)) "SI" else "NO", md5_antes)
  invisible(all(ok) && detuvo && identical(md5_antes, md5_despues))
}

if (identical(fase, "f0bis")) verificar_f0bis() else
if (identical(fase, "f1"))    verificar_f1() else
if (identical(fase, "f2"))    verificar_f2() else
  stop(sprintf("fase desconocida: '%s'", fase), call. = FALSE)
