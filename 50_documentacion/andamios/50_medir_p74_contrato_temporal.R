# =============================================================================
# 50_medir_p74_contrato_temporal.R
# -----------------------------------------------------------------------------
# Proposito: medicion READ-ONLY del acto (a) de P-74. Responde las seis
#            compuertas del §2 del encargo y los seis objetivos del §3 leyendo
#            los artefactos REALES (intermedios .rds, captura XML cruda, JSON
#            publicado y los .R del pipeline). No implementa ningun filtro, no
#            edita el paso 36 y no toca sellar/leer_sellado/validar_corte.
#
# Invariantes que este script hace cumplir (encargo §1):
#   - Cero escrituras: solo imprime a stdout. Ni un saveRDS, ni un writeLines.
#   - Cero red: camara.refrescar = FALSE y contador instrumentado sobre
#     httr::GET/POST/RETRY y curl::curl_fetch_memory, reportado al cierre.
#   - Fallo ruidoso: stop() ante supuesto no cumplido; sin try(silent), sin
#     suppressWarnings, sin defaults silenciosos.
#   - Todo conteo declara su denominador, contado en esta misma corrida.
#
# Uso:  Rscript 50_documentacion/andamios/50_medir_p74_contrato_temporal.R
# Autor: Claude Code (encargo P-74 acto (a), sesion 18)
# Creado: 2026-08-08
# =============================================================================

# ---- Cero red: se fija ANTES de cargar la config (REFRESCAR_API la lee) -----
options(camara.refrescar = FALSE)

source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
instalar_si_falta(c("httr", "xml2", "here", "fs", "jsonlite"))
ROOT <- obtener_raiz_proyecto()
source(file.path(ROOT, "10_utils", "10_configuracion.R"))

# ---- Instrumentacion del contador de red (criterio C8) ----------------------
# El conteo tiene que existir para poder reportar cero; un cero no instrumentado
# es indistinguible de "no medido" (encargo §1.6).
CONTADOR_HTTP <- new.env(parent = emptyenv())
CONTADOR_HTTP$n <- 0L
for (par in list(c("httr", "GET"), c("httr", "POST"), c("httr", "RETRY"),
                 c("curl", "curl_fetch_memory"))) {
  if (requireNamespace(par[1], quietly = TRUE))
    trace(par[2], where = asNamespace(par[1]), print = FALSE,
          tracer = quote(CONTADOR_HTTP$n <- CONTADOR_HTTP$n + 1L))
}

# ---- Utilidades locales de reporte ------------------------------------------
titulo <- function(x) cat("\n\n=====", x, "=====\n")
subt   <- function(x) cat("\n--- ", x, "\n", sep = "")
linea  <- function(fmt, ...) cat(sprintf(fmt, ...), "\n", sep = "")

# Prefijo AAAA-MM-DD de un texto de fecha de la fuente. Devuelve NA si el valor
# no empieza por una fecha ISO; NUNCA adivina ni completa.
prefijo_fecha <- function(x) {
  x <- as.character(x)
  ok <- !is.na(x) & grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}", x)
  out <- rep(NA_character_, length(x))
  out[ok] <- substr(x[ok], 1, 10)
  out
}
# Un vector es "candidato a fecha" si al menos un valor no-NA trae prefijo ISO.
tiene_fecha <- function(x) any(!is.na(prefijo_fecha(x)))

CORTE <- trimws(as.character(CORTE_FECHA))

# =============================================================================
# COMPUERTA G6 (primero: fija el corte con el que se mide todo lo demas)
# =============================================================================
titulo("G6. Fecha de corte efectiva (leida en la corrida)")
linea("Archivo leido : %s", file.path(ROOT, "10_utils", "10_configuracion.R"))
linea("CORTE_FECHA   : %s", CORTE)
linea("ANIO_PROCESO  : %s", as.character(ANIO_PROCESO))
linea("REFRESCAR_API : %s (getOption camara.refrescar = %s)",
      as.character(REFRESCAR_API), as.character(getOption("camara.refrescar")))
if (!grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", CORTE))
  stop("G6: CORTE_FECHA no tiene formato AAAA-MM-DD.", call. = FALSE)

# =============================================================================
# COMPUERTA G1. Forma real del intermedio del paso 36
# =============================================================================
titulo("G1. Forma real del intermedio del paso 36")
RUTA_DETALLE <- normalizePath(ruta_salidas("intermedios", "proyectos_detalle.rds"),
                              mustWork = TRUE)
det <- readRDS(RUTA_DETALLE)
linea("Ruta absoluta : %s", RUTA_DETALLE)
linea("class()       : %s", paste(class(det), collapse = ", "))
linea("nrow()        : %d", nrow(det))
linea("ncol()        : %d", ncol(det))
linea("names()       : %s", paste(names(det), collapse = ", "))

subt("Clase de cada columna del intermedio")
for (nm in names(det))
  linea("  %-18s %s", nm, paste(class(det[[nm]]), collapse = "/"))

# Descubrimiento (no supuesto) de las list-cols que contienen data.frames.
es_listcol_df <- vapply(names(det), function(nm) {
  col <- det[[nm]]
  is.list(col) && length(col) > 0 && all(vapply(col, is.data.frame, logical(1)))
}, logical(1))
LISTCOLS <- names(det)[es_listcol_df]
linea("\nList-cols de data.frame descubiertas: %d de %d columnas -> %s",
      length(LISTCOLS), ncol(det), paste(LISTCOLS, collapse = ", "))

# Cual de esas list-cols contiene las votaciones: la que trae el esquema con el
# id de votacion. Se decide por contenido, no por nombre.
subt("Esquema de cada list-col (medido sobre TODOS los elementos, no sobre uno)")
for (nm in LISTCOLS) {
  esquemas <- unique(lapply(det[[nm]], names))
  linea("  %s: %d esquema(s) distinto(s) en %d elementos; ncol = %s",
        nm, length(esquemas), nrow(det),
        paste(unique(vapply(det[[nm]], ncol, integer(1))), collapse = "/"))
  linea("    names() = %s", paste(esquemas[[1]], collapse = ", "))
  if (length(esquemas) > 1)
    stop(sprintf("G1: la list-col '%s' tiene esquemas heterogeneos.", nm), call. = FALSE)
}

COL_VOT <- LISTCOLS[vapply(LISTCOLS, function(nm)
  any(grepl("votacion", names(det[[nm]][[1]]), fixed = TRUE)), logical(1))]
if (length(COL_VOT) != 1)
  stop(sprintf("G1: no se identifico una unica list-col de votaciones (%d candidatas).",
               length(COL_VOT)), call. = FALSE)
linea("\nList-col de votaciones identificada por contenido: '%s'", COL_VOT)

VOT <- do.call(rbind, det[[COL_VOT]])   # formato largo, solo en memoria
CAMPOS_VOT <- names(VOT)
linea("Campos del nodo (contados): %d", length(CAMPOS_VOT))
subt("Estructura de un elemento del list-col: name, class y no-NA de cada campo")
linea("  %-30s %-10s %8s %8s", "campo", "class", "no_NA", "n_unicos")
for (nm in CAMPOS_VOT)
  linea("  %-30s %-10s %8d %8d", nm, paste(class(VOT[[nm]]), collapse = "/"),
        sum(!is.na(VOT[[nm]])), length(unique(VOT[[nm]][!is.na(VOT[[nm]])])))

# =============================================================================
# COMPUERTA G2. Campos de fecha del nodo
# =============================================================================
titulo("G2. Campos de fecha del nodo (de los campos contados en G1)")
CAMPOS_FECHA <- CAMPOS_VOT[vapply(CAMPOS_VOT, function(nm) tiene_fecha(VOT[[nm]]),
                                  logical(1))]
linea("Campos evaluados: %d de %d (todos los del nodo, ninguno excluido a priori)",
      length(CAMPOS_VOT), length(CAMPOS_VOT))
linea("Campos con al menos un valor con prefijo ISO AAAA-MM-DD: %d de %d -> %s",
      length(CAMPOS_FECHA), length(CAMPOS_VOT),
      if (length(CAMPOS_FECHA)) paste(CAMPOS_FECHA, collapse = ", ") else "(ninguno)")

subt("Detalle por campo candidato")
for (nm in CAMPOS_FECHA) {
  v <- VOT[[nm]]
  pf <- prefijo_fecha(v)
  linea("  campo            : %s", nm)
  linea("  class()          : %s", paste(class(v), collapse = "/"))
  linea("  no-NA            : %d de %d valores", sum(!is.na(v)), length(v))
  linea("  con prefijo ISO  : %d de %d valores no-NA", sum(!is.na(pf)), sum(!is.na(v)))
  linea("  anchos distintos : %s", paste(sort(unique(nchar(v[!is.na(v)]))), collapse = ", "))
  linea("  5 valores reales : %s", paste(utils::head(v[!is.na(v)], 5), collapse = " | "))
}

subt("Campos NO clasificados como fecha (se listan para que el descarte sea auditable)")
linea("  %s", paste(setdiff(CAMPOS_VOT, CAMPOS_FECHA), collapse = ", "))

# =============================================================================
# COMPUERTA G3. Inventario de intermedios (barrido del directorio)
# =============================================================================
titulo("G3. Inventario de intermedios (resultado de barrer el directorio)")
DIR_INT <- normalizePath(ruta_salidas("intermedios"), mustWork = TRUE)
ARCH_INT <- sort(list.files(DIR_INT, pattern = "[.]rds$", full.names = TRUE))
linea("Directorio barrido : %s", DIR_INT)
linea("Archivos .rds encontrados (contados): %d", length(ARCH_INT))

INTERMEDIOS <- lapply(ARCH_INT, function(r) {
  obj <- readRDS(r)
  # Lectura directa del atributo: leer_sellado() hace stop() si falta sello, y
  # aqui "sin sello" es un estado que hay que poder REPORTAR, no un fallo.
  list(ruta = normalizePath(r), nombre = tools::file_path_sans_ext(basename(r)),
       objeto = obj, sello = attr(obj, "sello"))
})
names(INTERMEDIOS) <- vapply(INTERMEDIOS, function(x) x$nombre, character(1))

for (it in INTERMEDIOS) {
  subt(it$nombre)
  linea("  ruta        : %s", it$ruta)
  linea("  nrow()      : %d", nrow(it$objeto))
  linea("  ncol()      : %d", ncol(it$objeto))
  linea("  names()     : %s", paste(names(it$objeto), collapse = ", "))
  if (is.null(it$sello)) {
    linea("  sello       : AUSENTE")
  } else {
    linea("  sello.corte : %s", it$sello$corte_fecha)
    linea("  sello.anio  : %s", it$sello$anio_proceso)
    linea("  sello.hash  : %s", paste(names(it$sello$hash_origen), collapse = ", "))
    linea("  sello.escrito_en : %s", it$sello$escrito_en)
  }
}
n_sellados <- sum(vapply(INTERMEDIOS, function(x) !is.null(x$sello), logical(1)))
n_al_corte <- sum(vapply(INTERMEDIOS, function(x)
  !is.null(x$sello) && identical(trimws(as.character(x$sello$corte_fecha)), CORTE),
  logical(1)))
linea("\nSellados: %d de %d archivos .rds barridos", n_sellados, length(INTERMEDIOS))
linea("Con corte == CORTE_FECHA (%s): %d de %d sellados", CORTE, n_al_corte, n_sellados)

# =============================================================================
# COMPUERTA G4. Universo y denominadores
# =============================================================================
titulo("G4. Universo y denominadores (contados en esta corrida)")
N_BOLETINES <- nrow(det)
N_EVENTOS   <- nrow(VOT)
N_BOL_CON   <- sum(vapply(det[[COL_VOT]], nrow, integer(1)) > 0)
linea("Boletines en el intermedio del 36        : %d (denominador: filas de %s)",
      N_BOLETINES, basename(RUTA_DETALLE))
linea("Eventos de votacion en el nodo (total)   : %d (denominador: suma de filas de las %d list-cols '%s')",
      N_EVENTOS, N_BOLETINES, COL_VOT)
linea("Boletines con nodo NO vacio              : %d de %d boletines", N_BOL_CON, N_BOLETINES)
linea("Boletines con nodo vacio                 : %d de %d boletines",
      N_BOLETINES - N_BOL_CON, N_BOLETINES)
# Control cruzado con el escalar que persiste el 36, si existe.
COL_N_VOT <- names(det)[vapply(names(det), function(nm)
  is.numeric(det[[nm]]) && identical(as.integer(det[[nm]]),
                                     vapply(det[[COL_VOT]], nrow, integer(1))),
  logical(1))]
linea("Columna escalar que replica el conteo    : %s",
      if (length(COL_N_VOT)) paste(COL_N_VOT, collapse = ", ") else "(ninguna)")
if (length(COL_N_VOT) && sum(det[[COL_N_VOT[1]]]) != N_EVENTOS)
  stop("G4: el escalar de conteo no cuadra con las filas del list-col.", call. = FALSE)
linea("Cuadratura escalar vs list-col           : %d == %d",
      if (length(COL_N_VOT)) sum(det[[COL_N_VOT[1]]]) else NA_integer_, N_EVENTOS)

# Denominador independiente: los boletines VOTADOS segun el intermedio de votos.
if (!is.null(INTERMEDIOS[["votos"]])) {
  votos_obj <- INTERMEDIOS[["votos"]]$objeto
  bol_votados <- unique(as.character(votos_obj$boletin))
  bol_votados <- bol_votados[!is.na(bol_votados)]
  linea("Boletines votados (denominador propio, de votos.rds): %d", length(bol_votados))
  linea("  de ellos, presentes en el detalle del 36 : %d de %d",
        sum(bol_votados %in% det$boletin), length(bol_votados))
}

# =============================================================================
# COMPUERTA G5. Alcance temporal del crudo
# =============================================================================
titulo("G5. Alcance temporal del XML crudo capturado por el paso 36")
RUTA_XML <- normalizePath(ruta_cache(sprintf("detalle_proyectos_xml_%d", ANIO_PROCESO), Inf),
                          mustWork = TRUE)
cap <- readRDS(RUTA_XML)
linea("Ruta absoluta (construida con ruta_cache): %s", RUTA_XML)
linea("nrow()  : %d", nrow(cap))
linea("names() : %s", paste(names(cap), collapse = ", "))
linea("estados : %s",
      paste(sprintf("%s=%d", names(table(cap$estado)), as.integer(table(cap$estado))),
            collapse = ", "))

# Barrido de TODOS los elementos con texto de fecha en el XML crudo, por ruta de
# nodo. Asi se distingue lo que la captura trae de lo que el parser conserva.
# La ruta de cada nodo se toma de xml2::xml_path() (vectorizada sobre el nodeset)
# y se le quitan los indices posicionales, para agrupar por ruta y no por posicion.
ruta_nodo <- function(nodos) gsub("\\[[0-9]+\\]", "", xml2::xml_path(nodos))

resueltos <- cap[!is.na(cap$xml), ]
linea("Documentos XML con contenido (denominador del barrido): %d de %d filas de la captura",
      nrow(resueltos), nrow(cap))

acum <- new.env(parent = emptyenv())
acum$reg <- list()
for (i in seq_len(nrow(resueltos))) {
  doc <- xml2::read_xml(resueltos$xml[i])
  nodos <- xml2::xml_find_all(xml2::xml_root(doc), ".//*")
  txt <- xml2::xml_text(nodos)
  pf <- prefijo_fecha(txt)
  hit <- which(!is.na(pf))
  if (length(hit) == 0) next
  rutas <- ruta_nodo(nodos)
  for (k in hit) {
    rp <- rutas[k]
    prev <- acum$reg[[rp]]
    if (is.null(prev)) prev <- list(n = 0L, n_post = 0L, max = NA_character_,
                                    ej = character(0), bol_post = character(0))
    prev$n <- prev$n + 1L
    if (pf[k] > CORTE) {
      prev$n_post <- prev$n_post + 1L
      prev$bol_post <- unique(c(prev$bol_post, resueltos$boletin[i]))
    }
    prev$max <- if (is.na(prev$max)) pf[k] else max(prev$max, pf[k])
    if (length(prev$ej) < 3) prev$ej <- c(prev$ej, txt[k])
    acum$reg[[rp]] <- prev
  }
}
subt("Rutas de nodo del XML crudo con texto de fecha (todas, no una muestra)")
linea("  %-62s %7s %8s %12s", "ruta_nodo", "n", "n_post", "fecha_max")
for (rp in sort(names(acum$reg))) {
  r <- acum$reg[[rp]]
  linea("  %-62s %7d %8d %12s", rp, r$n, r$n_post, r$max)
}
linea("\nRutas con fecha distintas (contadas): %d", length(acum$reg))
linea("Ejemplos de valor por ruta:")
for (rp in sort(names(acum$reg)))
  linea("  %-62s %s", rp, paste(r <- acum$reg[[rp]]$ej, collapse = " | "))

# =============================================================================
# M1. Exceso temporal en el nodo
# =============================================================================
titulo("M1. Exceso temporal en el nodo del paso 36")
n_vot_por_bol <- vapply(det[[COL_VOT]], nrow, integer(1))
bol_por_evento <- rep(det$boletin, n_vot_por_bol)
if (length(bol_por_evento) != N_EVENTOS)
  stop("M1: la expansion boletin-por-evento no cuadra con el total de eventos.", call. = FALSE)

for (nm in CAMPOS_FECHA) {
  pf <- prefijo_fecha(VOT[[nm]])
  if (any(is.na(pf)))
    stop(sprintf("M1: el campo '%s' tiene %d valores sin fecha parseable; no se puede medir el exceso.",
                 nm, sum(is.na(pf))), call. = FALSE)
  post <- pf > CORTE
  bol_post <- unique(bol_por_evento[post])
  subt(sprintf("campo de fecha: %s", nm))
  linea("  eventos posteriores a %s : %d de %d eventos del nodo", CORTE, sum(post), N_EVENTOS)
  # max() sobre character compara lexicograficamente, que para AAAA-MM-DD es el
  # orden cronologico. which.max() NO sirve aqui: coerce a numeric y da NA.
  linea("  fecha maxima observada    : %s (valor crudo: %s)",
        max(pf), VOT[[nm]][which(pf == max(pf))[1]])
  linea("  fecha minima observada    : %s", min(pf))
  linea("  boletines afectados       : %d de %d boletines con nodo no vacio (%d de %d boletines del intermedio)",
        length(bol_post), N_BOL_CON, length(bol_post), N_BOLETINES)
  if (sum(post) > 0) {
    linea("  detalle de los eventos en exceso:")
    idx <- which(post)
    for (k in idx)
      linea("    boletin %s | %s = %s | id = %s | descripcion = %s",
            bol_por_evento[k], nm, VOT[[nm]][k], VOT$votacion_id[k],
            substr(VOT$descripcion[k], 1, 60))
  }
  # Borde INFERIOR, no pedido por M1 pero medido porque la corrida lo dejo a la
  # vista: el corte superior no es el unico limite que el nodo no respeta.
  # ANIO_PROCESO acota los otros extractores; se mide si acota tambien a este.
  ini_anio <- sprintf("%d-01-01", ANIO_PROCESO)
  prev <- pf < ini_anio
  linea("  [lateral] eventos anteriores a %s : %d de %d eventos del nodo",
        ini_anio, sum(prev), N_EVENTOS)
  linea("  [lateral] boletines afectados por el borde inferior: %d de %d con nodo no vacio",
        length(unique(bol_por_evento[prev])), N_BOL_CON)
  linea("  [lateral] anios distintos presentes en el nodo: %s",
        paste(sort(unique(substr(pf, 1, 4))), collapse = ", "))
}

# =============================================================================
# M2. Barrido de los seis intermedios (tres estados, sin colapsar)
# =============================================================================
titulo("M2. Barrido temporal de los intermedios de G3")
# Fechas AAAA-MM-DD de una columna, o NULL si la columna no es de fecha.
# Cubre Date/POSIXct (por clase) y character (por prefijo ISO): el descarte de
# una columna queda registrado con su clase, para que sea auditable.
fechas_de <- function(x) {
  if (inherits(x, "Date") || inherits(x, "POSIXt")) return(format(x, "%Y-%m-%d"))
  if (is.character(x)) { p <- prefijo_fecha(x); if (any(!is.na(p))) return(p) }
  NULL
}

resumen_m2 <- list()
for (it in INTERMEDIOS) {
  obj <- it$objeto
  subt(sprintf("%s (nrow = %d)", it$nombre, nrow(obj)))
  # Columnas planas + columnas anidadas dentro de list-cols de data.frame.
  campos <- list()
  for (nm in names(obj)) {
    col <- obj[[nm]]
    if (is.list(col) && length(col) > 0 && all(vapply(col, is.data.frame, logical(1)))) {
      hijo <- do.call(rbind, col)
      for (nm2 in names(hijo)) campos[[paste0(nm, "$", nm2)]] <- hijo[[nm2]]
    } else {
      campos[[nm]] <- col
    }
  }
  linea("  columnas evaluadas (planas + anidadas): %d", length(campos))
  linea("  %-34s %-10s %s", "campo", "class", "clasificacion")
  con_fecha <- character(0)
  for (nm in names(campos)) {
    f <- fechas_de(campos[[nm]])
    linea("  %-34s %-10s %s", nm, paste(class(campos[[nm]]), collapse = "/"),
          if (is.null(f)) "no es fecha" else "FECHA")
    if (!is.null(f)) con_fecha <- c(con_fecha, nm)
  }
  if (length(con_fecha) == 0) {
    estado <- "(i) SIN NINGUN CAMPO DE FECHA"
    linea("  -> estado %s", estado)
    resumen_m2[[it$nombre]] <- list(estado = estado, campos = 0L, post = 0L, total = 0L)
  } else {
    total_post <- 0L; total_ev <- 0L
    for (nm in con_fecha) {
      f <- fechas_de(campos[[nm]])
      f_ok <- f[!is.na(f)]
      post <- sum(f_ok > CORTE)
      total_post <- total_post + post; total_ev <- total_ev + length(f_ok)
      linea("  campo '%s': %d de %d valores con fecha posteriores a %s; max = %s; min = %s",
            nm, post, length(f_ok), CORTE, max(f_ok), min(f_ok))
    }
    estado <- if (total_post > 0) "(iii) CON EVENTOS POSTERIORES AL CORTE"
              else "(ii) CON CAMPO DE FECHA Y CERO EVENTOS POSTERIORES"
    linea("  -> estado %s (%d de %d valores con fecha)", estado, total_post, total_ev)
    resumen_m2[[it$nombre]] <- list(estado = estado, campos = length(con_fecha),
                                    post = total_post, total = total_ev)
  }
}

subt("Resumen M2")
linea("  %-22s %-52s %10s %10s", "intermedio", "estado", "post", "total")
for (nm in names(resumen_m2)) {
  r <- resumen_m2[[nm]]
  linea("  %-22s %-52s %10d %10d", nm, r$estado, r$post, r$total)
}

# =============================================================================
# M3. Veredicto de generalidad
# =============================================================================
titulo("M3. Generalidad del defecto (contrastable en ambos sentidos)")
con_exceso <- names(resumen_m2)[vapply(resumen_m2, function(r) r$post > 0, logical(1))]
sin_campo  <- names(resumen_m2)[vapply(resumen_m2, function(r) r$campos == 0L, logical(1))]
con_campo_sin_exceso <- setdiff(names(resumen_m2), c(con_exceso, sin_campo))
linea("Intermedios con exceso (iii)                 : %d de %d -> %s",
      length(con_exceso), length(resumen_m2),
      if (length(con_exceso)) paste(con_exceso, collapse = ", ") else "(ninguno)")
linea("Intermedios con campo de fecha y sin exceso (ii): %d de %d -> %s",
      length(con_campo_sin_exceso), length(resumen_m2),
      if (length(con_campo_sin_exceso)) paste(con_campo_sin_exceso, collapse = ", ") else "(ninguno)")
linea("Intermedios sin campo de fecha (i)           : %d de %d -> %s",
      length(sin_campo), length(resumen_m2),
      if (length(sin_campo)) paste(sin_campo, collapse = ", ") else "(ninguno)")
linea("Evidencia a favor de 'defecto general' : %d intermedios distintos con exceso",
      length(con_exceso))
linea("Evidencia en contra de 'defecto general': %d intermedios con campo de fecha que NO exceden",
      length(con_campo_sin_exceso))

# =============================================================================
# M4. Costo de la via "filtrar al derivar"
# =============================================================================
titulo("M4. Costo de acotar el nodo a CORTE_FECHA en el paso 36")
for (nm in CAMPOS_FECHA) {
  pf_por_bol <- lapply(det[[COL_VOT]], function(d) prefijo_fecha(d[[nm]]))
  n_hoy   <- vapply(pf_por_bol, length, integer(1))
  n_filt  <- vapply(pf_por_bol, function(p) sum(p <= CORTE), integer(1))
  subt(sprintf("filtrando por %s <= %s", nm, CORTE))
  linea("  eventos que quedarian fuera   : %d de %d eventos del nodo",
        sum(n_hoy) - sum(n_filt), sum(n_hoy))
  linea("  eventos que quedarian dentro  : %d de %d eventos del nodo", sum(n_filt), sum(n_hoy))
  linea("  boletines con conteo alterado : %d de %d boletines con nodo no vacio",
        sum(n_hoy != n_filt), N_BOL_CON)
  vaciados <- det$boletin[n_hoy > 0 & n_filt == 0]
  linea("  boletines que quedarian VACIOS y hoy no lo estan (efecto secundario): %d de %d boletines con nodo no vacio",
        length(vaciados), N_BOL_CON)
  if (length(vaciados) > 0) linea("    boletines: %s", paste(vaciados, collapse = ", "))
  linea("  boletines con nodo no vacio despues del filtro: %d de %d",
        sum(n_filt > 0), N_BOL_CON)
}

# =============================================================================
# M5. Superficie de consumo actual
# =============================================================================
titulo("M5. Superficie de consumo de los campos del nodo")
# El barrido NO nombra archivos a mano: lista la raiz y los dos directorios de
# codigo. Nombrarlos a mano dejaria fuera cualquier .R nuevo de la raiz (hallazgo
# del agente 2 del panel: 00_escanear_proyecto.R quedaba sin barrer).
ARCH_R <- c(list.files(ROOT, "[.]R$", full.names = TRUE),
            list.files(file.path(ROOT, "10_utils"), "[.]R$", full.names = TRUE),
            list.files(file.path(ROOT, "30_procesamiento"), "[.]R$", full.names = TRUE))
ARCH_R <- sort(unique(ARCH_R[file.exists(ARCH_R)]))
linea("Archivos .R del pipeline barridos (contados): %d", length(ARCH_R))
linea("  %s", paste(basename(ARCH_R), collapse = ", "))

LINEAS_R <- lapply(ARCH_R, function(f) readLines(f, warn = FALSE))
names(LINEAS_R) <- basename(ARCH_R)
# El comentario no es evidencia de consumo (A70): se separa del codigo siempre.
escanear <- function(patron) {
  filas <- list()
  for (nm in names(LINEAS_R)) {
    ln <- LINEAS_R[[nm]]
    for (k in grep(patron, ln))
      filas[[length(filas) + 1]] <- list(archivo = nm, linea = k,
        comentario = grepl("^\\s*#", ln[k]), texto = trimws(substr(ln[k], 1, 88)))
  }
  filas
}
imprimir <- function(filas) {
  if (length(filas) == 0) { linea("  (sin coincidencias)"); return(invisible(NULL)) }
  for (r in filas)
    linea("  %-34s :%-4d %-9s %s", r$archivo, r$linea,
          if (r$comentario) "[coment]" else "[CODIGO]", r$texto)
}
n_codigo <- function(filas) sum(vapply(filas, function(r) !r$comentario, logical(1)))

# Probe 1: que nombres del nodo son AMBIGUOS porque tambien son columnas de otro
# intermedio. Sin esta medicion, un token como 'fecha' o 'descripcion' contaria
# como consumo del nodo cuando en realidad viene de votos.rds.
subt("Ambiguedad de los nombres del nodo (medida contra las columnas de los otros intermedios)")
otras_columnas <- unique(unlist(lapply(names(INTERMEDIOS), function(nm) {
  if (identical(nm, "proyectos_detalle")) return(character(0))
  names(INTERMEDIOS[[nm]]$objeto)
}), use.names = FALSE))
AMBIGUOS <- CAMPOS_VOT[CAMPOS_VOT %in% otras_columnas]
SOLO_NODO <- setdiff(CAMPOS_VOT, AMBIGUOS)
linea("  columnas de los otros 5 intermedios (contadas): %d", length(otras_columnas))
linea("  campos del nodo ambiguos  : %d de %d -> %s", length(AMBIGUOS), length(CAMPOS_VOT),
      paste(AMBIGUOS, collapse = ", "))
linea("  campos exclusivos del nodo: %d de %d -> %s", length(SOLO_NODO), length(CAMPOS_VOT),
      paste(SOLO_NODO, collapse = ", "))

# Probe 2: los campos EXCLUSIVOS del nodo. Un consumo real del nodo tiene que
# tocar alguno; si ninguno aparece en codigo, no hay consumidor.
subt("Probe 2: campos exclusivos del nodo, buscados como token en los .R del pipeline")
total_codigo_solo_nodo <- 0L
tally <- new.env(parent = emptyenv())   # apariciones en codigo POR ARCHIVO
for (nm in SOLO_NODO) {
  filas <- escanear(sprintf("\\b%s\\b", nm))
  nc <- n_codigo(filas)
  total_codigo_solo_nodo <- total_codigo_solo_nodo + nc
  linea("  %-30s %d en codigo, %d en comentario", nm, nc, length(filas) - nc)
  if (nc > 0) imprimir(Filter(function(r) !r$comentario, filas))
  for (r in filas) if (!r$comentario)
    assign(r$archivo, (if (exists(r$archivo, envir = tally)) get(r$archivo, envir = tally) else 0L) + 1L,
           envir = tally)
}
linea("  TOTAL en codigo sobre los %d campos exclusivos: %d",
      length(SOLO_NODO), total_codigo_solo_nodo)
# Desglose por archivo: la cifra que separa "productor" de "consumidor" no se
# deriva a mano (encargo §1.5), se cuenta aqui.
subt("Probe 2b: desglose por archivo de esas apariciones en codigo")
suma <- 0L
for (a in sort(ls(tally))) {
  n <- get(a, envir = tally); suma <- suma + n
  linea("  %-34s %d de %d", a, n, total_codigo_solo_nodo)
}
if (suma != total_codigo_solo_nodo)
  stop("Probe 2b: el desglose por archivo no suma el total.", call. = FALSE)

# Probe 3: acceso a la list-col por nombre ($votaciones / [["votaciones"]]).
subt(sprintf("Probe 3: accesos a la columna '%s' por nombre", COL_VOT))
filas3 <- escanear(sprintf("\\$%s\\b|\\[\\[\"%s\"\\]\\]", COL_VOT, COL_VOT))
imprimir(filas3)
linea("  accesos en codigo: %d (de ellos, en el paso productor 36 y en 10_utils: %d)",
      n_codigo(filas3),
      sum(vapply(filas3, function(r) !r$comentario &&
        grepl("^(36_|10_utils)", r$archivo), logical(1))))

# Probe 4: quien lee el intermedio del 36 (nombre inequivoco del artefacto).
subt("Probe 4: referencias al intermedio 'proyectos_detalle'")
imprimir(escanear("proyectos_detalle"))

subt("Claves reales del JSON publicado (inventario recursivo, no lectura de comentarios)")
claves_de <- function(x, prefijo = "") {
  if (is.list(x)) {
    if (!is.null(names(x)) && any(nzchar(names(x)))) {
      unlist(lapply(names(x), function(nm)
        c(paste0(prefijo, nm), claves_de(x[[nm]], paste0(prefijo, nm, ".")))),
        use.names = FALSE)
    } else {
      unlist(lapply(x, function(e) claves_de(e, prefijo)), use.names = FALSE)
    }
  } else character(0)
}
ARCH_JSON <- c(list.files(ruta_json(), "[.]json$", full.names = TRUE),
               list.files(ruta_json_perfiles(), "[.]json$", full.names = TRUE))
linea("Archivos JSON barridos (contados): %d", length(ARCH_JSON))
claves <- unique(unlist(lapply(ARCH_JSON, function(f)
  claves_de(jsonlite::fromJSON(f, simplifyVector = FALSE))), use.names = FALSE))
linea("Claves distintas en el JSON publicado (contadas): %d", length(claves))
hoja <- unique(sub("^.*\\.", "", claves))
presentes <- CAMPOS_VOT[CAMPOS_VOT %in% hoja]
linea("Campos del nodo que aparecen como clave del JSON: %d de %d -> %s",
      length(presentes), length(CAMPOS_VOT),
      if (length(presentes)) paste(presentes, collapse = ", ") else "(ninguno)")
# La cifra que decide M5: los campos AMBIGUOS pueden llegar al JSON desde otro
# intermedio, asi que no prueban consumo del nodo. Los exclusivos si lo probarian.
pres_excl <- SOLO_NODO[SOLO_NODO %in% hoja]
pres_amb  <- AMBIGUOS[AMBIGUOS %in% hoja]
linea("  de ellos, EXCLUSIVOS del nodo : %d de %d -> %s", length(pres_excl), length(SOLO_NODO),
      if (length(pres_excl)) paste(pres_excl, collapse = ", ") else "(ninguno)")
linea("  de ellos, AMBIGUOS            : %d de %d -> %s", length(pres_amb), length(AMBIGUOS),
      if (length(pres_amb)) paste(pres_amb, collapse = ", ") else "(ninguno)")
subt("Todas las claves del JSON, para que el contraste sea auditable")
linea("  %s", paste(sort(claves), collapse = ", "))

# =============================================================================
# M6. Comportamiento del sello ante el exceso (sin modificar nada)
# =============================================================================
titulo("M6. Que compara hoy validar_corte() frente a un intermedio en exceso")
sellos <- lapply(INTERMEDIOS, function(x) x$sello)
linea("Sellos pasados a validar_corte(): %d de %d intermedios", length(sellos), length(INTERMEDIOS))
res <- validar_corte(sellos, CORTE)
linea("validar_corte(sellos, '%s') devuelve: %s  (SIN error, con el exceso de M1 presente)",
      CORTE, as.character(res))
subt("Campos del sello que validar_corte() lee (del cuerpo real de la funcion)")
cuerpo <- deparse(validar_corte)
campos_leidos <- unique(regmatches(cuerpo, gregexpr("\\$[a-z_]+", cuerpo)))
linea("  campos referenciados con $ en el cuerpo: %s",
      paste(unique(unlist(campos_leidos)), collapse = ", "))
linea("  lineas del cuerpo que referencian el objeto de datos: %d",
      length(grep("objeto|nrow|fecha[^_]", cuerpo)))
subt("Estructura del sello que se escribe (del cuerpo real de sellar())")
linea("  %s", paste(grep("corte_fecha|anio_proceso|hash_origen|escrito_en",
                         deparse(sellar), value = TRUE), collapse = " | "))

# =============================================================================
# AUTOAUDITORIA DE ESCRITURA (criterio C7)
# =============================================================================
# git status --porcelain es CIEGO a los intermedios, que estan gitignorados
# (.gitignore:42). Por eso la evidencia de "cero escrituras" no puede ser solo
# git: se audita el propio texto de este script buscando toda funcion capaz de
# escribir, y se reporta el mtime de los seis intermedios y de la captura cruda.
titulo("Autoauditoria de escritura (C7)")
YO <- file.path(ROOT, "50_documentacion", "andamios", "50_medir_p74_contrato_temporal.R")
mis_lineas <- readLines(YO, warn = FALSE)
# El bloque auditor se nombra a si mismo (define los patrones que busca), asi que
# se audita SOLO lo que corre antes de el; si no, se contaria a si mismo.
FIN <- grep("Autoauditoria de escritura", mis_lineas)[1]
if (is.na(FIN)) stop("C7: no se encontro el limite del bloque auditor.", call. = FALSE)
auditables <- mis_lineas[seq_len(FIN - 1L)]
ESCRITORAS <- c("saveRDS", "writeLines", "write\\.csv", "write\\.table", "cat\\(file",
                "file\\.create", "file\\.remove", "unlink", "fs::file_", "fs::dir_create",
                "escribir_atomico", "sink\\(", "png\\(", "pdf\\(")
total_escritoras <- 0L
for (p in ESCRITORAS) {
  hits <- grep(p, auditables)
  hits <- hits[!grepl("^\\s*#", auditables[hits])]   # los comentarios no escriben
  total_escritoras <- total_escritoras + length(hits)
  if (length(hits) > 0)
    for (k in hits) linea("  %s -> linea %d: %s", p, k, trimws(auditables[k]))
}
linea("Lineas auditadas: %d de %d del script (el bloque auditor queda fuera)",
      length(auditables), length(mis_lineas))
linea("Llamadas capaces de escribir en disco (contadas sobre %d patrones): %d",
      length(ESCRITORAS), total_escritoras)
# Las tres funciones que el invariante 4 protege: se declara COMO se las toca.
for (fn in c("sellar", "leer_sellado", "validar_corte")) {
  hits <- grep(sprintf("\\b%s\\b", fn), auditables)
  hits <- hits[!grepl("^\\s*#", auditables[hits])]
  linea("  mencion de %-14s: %d en codigo -> %s", fn, length(hits),
        if (length(hits)) paste(sprintf("L%d", hits), collapse = ", ") else "(ninguna)")
}

subt("mtime de los artefactos que este script solo debe LEER")
for (r in c(ARCH_INT, RUTA_XML))
  linea("  %-58s %s", basename(r),
        format(file.info(r)$mtime, "%Y-%m-%d %H:%M:%S"))

# =============================================================================
# CONTADOR DE RED (criterio C8)
# =============================================================================
titulo("Contador de red")
linea("Llamadas HTTP interceptadas en toda la corrida: %d", CONTADOR_HTTP$n)
linea("(instrumentado sobre httr::GET, httr::POST, httr::RETRY, curl::curl_fetch_memory)")
# Limite declarado del contador (hallazgo del agente 2 del panel): instalar_si_falta()
# corre en la linea 28, ANTES del trace, y su install.packages() no pasa por httr
# ni curl. Se reporta el estado de los paquetes para que el cero sea interpretable.
faltantes <- c("httr", "xml2", "here", "fs", "jsonlite", "rprojroot", "dplyr")
faltantes <- faltantes[!vapply(faltantes, requireNamespace, logical(1), quietly = TRUE)]
linea("Paquetes requeridos ausentes al inicio (unica via de red no trazada): %d -> %s",
      length(faltantes), if (length(faltantes)) paste(faltantes, collapse = ", ") else "(ninguno)")
