# =============================================================================
# 31b_explorar_api_senado.R
# -----------------------------------------------------------------------------
# Proposito: INSTRUMENTACION (diagnostico insumos-first). Descubrir la firma
#            REAL de los web services publicos del Senado de Chile
#            (tramitacion.senado.cl/wspublico) para las cuatro entidades
#            equivalentes a las que ya extraemos de la Camara: senadores en
#            ejercicio, asistencia, votaciones (con sentido del voto) y
#            proyectos/mociones. NO asume la forma: la consulta en vivo, trae una
#            muestra real de cada entidad y la guarda cruda.
# Insumos:   ninguno (fuente primaria: los web services del Senado en vivo).
#            Para localizar boletines de origen Senado se consulta de paso el
#            endpoint de la Camara (retornarMocionesXAnno), solo lectura.
# Salidas:   50_documentacion/andamios/exploracion_api_senado/<entidad>_muestra.xml
#            (muestras crudas, regenerables) y, a consola, la estructura de nodos
#            hoja + conteos de cada entidad. El documento analitico se mantiene a
#            mano en 50_documentacion/activa/exploracion_api_senado.md.
# Naturaleza: diagnostico regenerable. NO forma parte del pipeline de produccion
#            (00_run_all.R) ni de PASOS: es exploratorio, igual que
#            31_explorar_api_camara.R. Se corre a mano.
# Transporte: httr2 (no el cliente httr de 10_utils/, pensado para el JSON/XML de
#            la Camara). El Senado es XML plano SIN namespace (no requiere strip).
# Autor:     Claude Code (encargo diagnostico API Senado, explore/api-senado)
# Creado:    2026-07-10
# =============================================================================

# ---- Cargar utilidades genericas (NO el cliente HTTP de la Camara) ----------
source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
instalar_si_falta(c("httr2", "xml2", "here"))
library(httr2)
library(xml2)

ROOT       <- obtener_raiz_proyecto()
DIR_MUESTRAS <- here::here("50_documentacion", "andamios", "exploracion_api_senado")
fs::dir_create(DIR_MUESTRAS)

WSPUBLICO  <- "https://tramitacion.senado.cl/wspublico/"
CAMARA_WS  <- "https://opendata.camara.cl/camaradiputados/WServices/"

# ---- Cliente HTTP resiliente para el Senado (httr2) -------------------------
# Reintento con backoff; NO lanza por status (lo evaluamos nosotros). Devuelve el
# cuerpo crudo (raw) + el string, para poder guardar la muestra tal cual llega.
descargar_senado <- function(endpoint, query = list(), base = WSPUBLICO,
                             intentos = 3L, timeout_s = 30L) {
  url <- paste0(base, endpoint)
  req <- request(url) |>
    req_url_query(!!!query) |>
    req_user_agent("transparencia_legislativa_chile (R; datos publicos Senado)") |>
    req_timeout(timeout_s) |>
    req_retry(max_tries = intentos, backoff = ~ 2 * .x) |>
    req_error(is_error = function(resp) FALSE)
  resp <- tryCatch(req_perform(req), error = function(e) e)
  if (inherits(resp, "error"))
    return(list(ok = FALSE, motivo = conditionMessage(resp), url = url))
  raw  <- resp_body_raw(resp)
  body <- tryCatch(rawToChar(raw), error = function(e) "")
  Encoding(body) <- "UTF-8"
  es_xml <- grepl("^\\s*<[a-zA-Z?]", body)
  placeholder <- grepl("No existe|width: 500px", body)  # cajas HTML de "sin datos"
  list(ok = es_xml && !placeholder, status = resp_status(resp),
       raw = raw, body = body, url = url,
       placeholder = placeholder)
}

# ---- Helpers de estructura --------------------------------------------------
paths_hoja <- function(node, prefijo = xml2::xml_name(node)) {
  kids <- xml2::xml_children(node)
  if (length(kids) == 0) return(prefijo)
  unlist(lapply(kids, function(k)
    paths_hoja(k, paste0(prefijo, "/", xml2::xml_name(k)))))
}

reportar_estructura <- function(titulo, resp, xpath_item = NULL) {
  log_msg(titulo, origen = "31b_senado")
  if (!isTRUE(resp$ok)) {
    log_msg(sprintf("  SIN DATOS/FALLO en %s (%s)", resp$url,
                    resp$motivo %||% (if (isTRUE(resp$placeholder)) "placeholder 'sin datos'"
                                      else paste("status", resp$status))),
            "WARN", "31b_senado")
    return(invisible(FALSE))
  }
  doc <- tryCatch(xml2::read_xml(resp$body), error = function(e) e)
  if (inherits(doc, "error")) {
    log_msg(sprintf("  NO parsea como XML: %s", conditionMessage(doc)), "WARN", "31b_senado")
    return(invisible(FALSE))
  }
  root <- xml2::xml_root(doc)
  cat(sprintf("    raiz XML: <%s>\n", xml2::xml_name(root)))
  if (!is.null(xpath_item)) {
    items <- xml2::xml_find_all(doc, xpath_item)
    cat(sprintf("    N items (%s): %d\n", xpath_item, length(items)))
    nodo <- if (length(items) > 0) items[[1]] else root
  } else nodo <- root
  cat("    nodos hoja:\n")
  for (p in unique(paths_hoja(nodo))) cat("      ", p, "\n", sep = "")
  invisible(TRUE)
}

guardar_muestra <- function(resp, archivo) {
  if (!isTRUE(resp$ok)) {
    log_msg(sprintf("  NO se guarda %s (sin datos)", archivo), "WARN", "31b_senado")
    return(invisible(NULL))
  }
  ruta <- file.path(DIR_MUESTRAS, archivo)
  writeBin(resp$raw, ruta)  # bytes crudos, tal cual los envio el servidor
  log_msg(sprintf("  muestra guardada: %s (%d bytes)", archivo, length(resp$raw)),
          origen = "31b_senado")
  invisible(ruta)
}

# ---- Localizar boletines de origen Senado (via Camara, solo lectura) --------
# El Senado NO expone un listado global de boletines; tramitacion.php es por
# boletin. Para muestrear proyectos/votaciones reales tomamos boletines de origen
# Senado desde la lista de mociones de la Camara (CamaraOrigen Valor=2).
boletines_origen_senado <- function(anno) {
  resp <- descargar_senado("WSLegislativo.asmx/retornarMocionesXAnno",
                           query = list(prmAnno = anno), base = CAMARA_WS)
  if (!isTRUE(resp$ok)) return(character(0))
  doc <- xml2::read_xml(resp$body); xml2::xml_ns_strip(doc)
  pl <- xml2::xml_find_all(doc, "//ProyectoLey")
  orig <- vapply(pl, function(n) xml2::xml_attr(xml2::xml_find_first(n, "./CamaraOrigen"), "Valor"),
                 character(1))
  bol <- vapply(pl, function(n) xml2::xml_text(xml2::xml_find_first(n, "./NumeroBoletin")),
                character(1))
  # tramitacion.php espera el numero ANTES del guion (sin el sufijo de materia)
  unique(sub("-.*", "", bol[orig == "2"]))
}

# ---- Legislatura vigente: no hay endpoint de listado; se sondea el rango -----
# Los ids de legislatura son enteros crecientes; los futuros aun vacios. Se busca
# el mayor id con sesiones (de arriba hacia abajo) en un rango acotado.
legislatura_vigente <- function(rango = 380:365) {
  for (leg in rango) {
    resp <- descargar_senado("sesiones.php", query = list(legislatura = leg))
    if (isTRUE(resp$ok)) {
      n <- length(xml2::xml_find_all(xml2::read_xml(resp$body), "//sesion"))
      if (n > 0) return(list(id = as.character(leg), n = n, resp = resp))
    }
  }
  NULL
}

# =============================================================================
# FLUJO
# =============================================================================
log_msg("== Exploracion de los web services del Senado (wspublico) ==", origen = "31b_senado")

# ---- 1. SENADORES (roster en ejercicio) ----
resp_sen <- descargar_senado("senadores_vigentes.php")
reportar_estructura("1. Senadores vigentes (senadores_vigentes.php)",
                    resp_sen, xpath_item = "//senador")
guardar_muestra(resp_sen, "senadores_muestra.xml")

# ---- 2. PROYECTOS (mocion/mensaje via tramitacion.php por boletin) ----
# Boletin sin votaciones: muestra limpia de descripcion/autores/tramite/materias.
BOLETIN_PROYECTO <- "16972"
resp_proy <- descargar_senado("tramitacion.php", query = list(boletin = BOLETIN_PROYECTO))
reportar_estructura(sprintf("2. Proyecto (tramitacion.php?boletin=%s)", BOLETIN_PROYECTO),
                    resp_proy, xpath_item = "//proyecto")
guardar_muestra(resp_proy, "proyectos_muestra.xml")

# ---- 3. VOTACIONES (anidadas en un boletin con votacion nominal) ----
# El Senado no tiene endpoint global de votaciones (votaciones.php responde vacio).
# Las votaciones viven dentro de tramitacion.php del boletin -> join voto->proyecto
# inherente. Se muestrea un boletin con votacion nominal conocida.
BOLETIN_VOTACION <- "15776"
resp_vot <- descargar_senado("tramitacion.php", query = list(boletin = BOLETIN_VOTACION))
reportar_estructura(sprintf("3. Votaciones (tramitacion.php?boletin=%s, nodo //votaciones)",
                            BOLETIN_VOTACION),
                    resp_vot, xpath_item = "//votaciones/votacion")
if (isTRUE(resp_vot$ok)) {
  doc_v <- xml2::read_xml(resp_vot$body)
  votos <- xml2::xml_find_all(doc_v, "//DETALLE_VOTACION/VOTO")
  cat(sprintf("    votos nominales en la 1a votacion del boletin: %d\n",
              length(xml2::xml_find_all(xml2::xml_find_first(doc_v, "//votacion"),
                                        ".//DETALLE_VOTACION/VOTO"))))
  sel <- unique(vapply(xml2::xml_find_all(doc_v, "//VOTO/SELECCION"), xml2::xml_text, character(1)))
  cat("    dominio de SELECCION observado:", paste(sel, collapse = ", "), "\n")
}
guardar_muestra(resp_vot, "votaciones_muestra.xml")

# ---- 4. ASISTENCIA (busqueda exhaustiva; se espera HUECO) ----
log_msg("4. Asistencia nominal: sondeo de endpoints candidatos", origen = "31b_senado")
cand_asistencia <- c("asistencia.php", "asistencias.php", "asistencia_sala.php",
                     "asistenciaSala.php", "asistencia_senador.php")
hallado_asist <- FALSE
for (e in cand_asistencia) {
  r <- descargar_senado(e, query = list(legislatura = 374))
  cat(sprintf("    %-24s -> %s\n", e,
              if (isTRUE(r$ok)) paste("XML!", nchar(r$body), "bytes")
              else paste("sin datos (status", r$status %||% "err", ")")))
  if (isTRUE(r$ok)) hallado_asist <- TRUE
}
if (!hallado_asist)
  log_msg("  HUECO: ningun endpoint de asistencia nominal responde (ver doc).",
          "WARN", "31b_senado")

# ---- 5. SESIONES (soporte: existen, pero SIN asistencia nominal) ----
leg <- legislatura_vigente()
if (!is.null(leg)) {
  log_msg(sprintf("5. Sesiones (legislatura vigente %s: %d sesiones)", leg$id, leg$n),
          origen = "31b_senado")
  reportar_estructura("   estructura de sesiones.php", leg$resp, xpath_item = "//sesion")
  guardar_muestra(leg$resp, "sesiones_muestra.xml")
} else {
  log_msg("5. Sesiones: no se hallo legislatura vigente en el rango sondeado", "WARN", "31b_senado")
}

log_msg("== Exploracion terminada. Muestras en 50_documentacion/andamios/exploracion_api_senado/ ==",
        origen = "31b_senado")
