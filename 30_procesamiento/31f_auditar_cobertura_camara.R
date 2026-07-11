# =============================================================================
# 31f_auditar_cobertura_camara.R
# -----------------------------------------------------------------------------
# Proposito: AUDITORIA ADVERSARIAL de cobertura. Responder con evidencia: que
#            EXPONE el web service de la Camara (opendata.camara.cl) que los
#            scripts 32-36 NO consumen. Enumera el catalogo completo de metodos,
#            baja una respuesta real de cada endpoint (usado y no usado), lista
#            TODOS sus campos (no solo los que el pipeline lee) y guarda la
#            muestra cruda como evidencia.
# Insumos:   ninguno (fuente primaria en vivo). Referencia: exploracion_api_camara.md.
# Salidas:   50_documentacion/andamios/muestras/camara_<op>_muestra.xml (+ catalogo)
#            y, a consola, el inventario de campos por endpoint.
# Naturaleza: diagnostico regenerable. NO entra a run_all() ni a PASOS. Solo
#            lectura sobre la fuente; NO toca 20_insumos/ (cache de produccion):
#            las muestras van a andamios/muestras/.
# Cortesia:  httr2 con backoff ante 429 y pausa entre llamadas (servicio publico).
# Autor:     Claude Code (encargo auditoria cobertura Camara, explore/cobertura-camara)
# Creado:    2026-07-10
# =============================================================================

source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
instalar_si_falta(c("httr2", "xml2", "here"))
library(httr2); library(xml2)

BASE <- "https://opendata.camara.cl/camaradiputados/WServices/"
DIR_MUESTRAS <- here::here("50_documentacion", "andamios", "muestras")
fs::dir_create(DIR_MUESTRAS)
PAUSA <- 0.4  # cortesia entre llamadas

# ---- Cliente HTTP (httr2, backoff ante 429; NO el cliente de produccion) -----
descargar <- function(url, intentos = 4L, timeout_s = 40L) {
  req <- request(url) |>
    req_user_agent("transparencia_legislativa_chile (R; auditoria cobertura; datos publicos)") |>
    req_timeout(timeout_s) |>
    req_retry(max_tries = intentos, backoff = ~ 2 * .x,
              is_transient = function(resp) resp_status(resp) %in% c(429, 500, 502, 503)) |>
    req_error(is_error = function(resp) FALSE)
  resp <- tryCatch(req_perform(req), error = function(e) e)
  Sys.sleep(PAUSA)
  if (inherits(resp, "error")) return(list(ok = FALSE, motivo = conditionMessage(resp), status = "ERR"))
  raw <- resp_body_raw(resp); body <- rawToChar(raw); Encoding(body) <- "UTF-8"
  list(ok = resp_status(resp) == 200, status = resp_status(resp),
       ct = resp_header(resp, "content-type") %||% "?", raw = raw, body = body)
}

op_url <- function(servicio, operacion, params = list()) {
  u <- paste0(BASE, servicio, ".asmx/", operacion)
  if (length(params) > 0)
    u <- paste0(u, "?", paste(sprintf("%s=%s", names(params),
                                       vapply(params, function(x) utils::URLencode(as.character(x)), character(1))),
                              collapse = "&"))
  u
}

# ---- Campos hoja de una respuesta XML (paths unicos) ------------------------
campos_hoja <- function(node, prefijo = xml_name(node)) {
  kids <- xml_children(node)
  if (length(kids) == 0) return(prefijo)
  unlist(lapply(kids, function(k) campos_hoja(k, paste0(prefijo, "/", xml_name(k)))))
}
parse_xml <- function(body) {
  doc <- tryCatch(read_xml(body), error = function(e) NULL)
  if (is.null(doc)) return(NULL)
  xml_ns_strip(doc); doc
}

# ---- Auditar UN endpoint: baja, lista campos, guarda muestra ----------------
auditar <- function(etiqueta, servicio, operacion, params = list(),
                    xpath_item = NULL, guardar = TRUE) {
  r <- descargar(op_url(servicio, operacion, params))
  cat(sprintf("\n### %s  [%s.asmx/%s %s]\n", etiqueta, servicio, operacion,
              if (length(params)) paste(names(params), unlist(params), sep = "=", collapse = " ") else ""))
  if (!isTRUE(r$ok)) { cat(sprintf("   FALLO status=%s\n", r$status)); return(invisible(NULL)) }
  doc <- parse_xml(r$body)
  if (is.null(doc)) { cat("   respuesta no-XML\n"); return(invisible(NULL)) }
  root <- xml_root(doc)
  # UNION de campos hoja sobre TODOS los items (no solo el primero): un campo
  # opcional que solo aparece en algunos items —p. ej. Justificacion en las
  # asistencias ausentes— se perderia si se mira solo it[[1]].
  campos <- if (!is.null(xpath_item)) {
    it <- xml_find_all(doc, xpath_item)
    cat(sprintf("   raiz <%s> | N items (%s): %d\n", xml_name(root), xpath_item, length(it)))
    if (length(it) > 0) unique(unlist(lapply(it, campos_hoja))) else campos_hoja(root)
  } else { cat(sprintf("   raiz <%s>\n", xml_name(root))); unique(campos_hoja(root)) }
  cat("   campos:", paste(campos, collapse = " | "), "\n")
  if (guardar) {
    ruta <- file.path(DIR_MUESTRAS, sprintf("camara_%s_muestra.xml", operacion))
    writeBin(r$raw, ruta)
    cat(sprintf("   muestra: %s (%d bytes)\n", basename(ruta), length(r$raw)))
  }
  invisible(list(doc = doc, root = root))
}

anio <- 2026L
log_msg("== AUDITORIA DE COBERTURA: web service de la Camara ==", origen = "31f_cobertura")

# =============================================================================
# BLOQUE A — Catalogo: operaciones de cada servicio (usado vs no usado)
# =============================================================================
cat("\n========== BLOQUE A: CATALOGO DE OPERACIONES ==========\n")
servicios <- c("WSDiputado", "WSSala", "WSLegislativo", "WSComun", "WSComision")
ops_por_servicio <- list()
for (s in servicios) {
  r <- descargar(paste0(BASE, s, ".asmx"))
  doc <- tryCatch(read_html(r$body), error = function(e) NULL)
  ops <- character(0)
  if (!is.null(doc)) {
    hrefs <- xml_attr(xml_find_all(doc, "//a"), "href")
    ops <- sort(unique(sub("op=", "", regmatches(hrefs, regexpr("op=[A-Za-z0-9_]+", hrefs)))))
  }
  ops_por_servicio[[s]] <- ops
  writeBin(r$raw, file.path(DIR_MUESTRAS, sprintf("camara_catalogo_%s.html", s)))
  cat(sprintf("%s.asmx: %d operaciones -> %s\n", s, length(ops), paste(ops, collapse = ", ")))
}

# =============================================================================
# BLOQUE B — Endpoints USADOS por el pipeline: campos completos
# =============================================================================
cat("\n========== BLOQUE B: ENDPOINTS USADOS (campos completos) ==========\n")

# 1. Roster (32) -------------------------------------------------------------
rr <- auditar("USADO/32 roster", "WSDiputado", "retornarDiputadosPeriodoActual",
              xpath_item = "//DiputadoPeriodo")
dip_id <- if (!is.null(rr)) xml_text(xml_find_first(rr$doc, "//DiputadoPeriodo/Diputado/Id")) else NA

# 2. Sesiones + asistencia (33) ---------------------------------------------
rs <- auditar("USADO/33 sesiones", "WSSala", "retornarSesionesXAnno",
              params = list(prmAnno = anio), xpath_item = "//Sesion")
ses_id <- if (!is.null(rs)) xml_text(xml_find_first(rs$doc, "//Sesion/Id")) else NA
if (!is.na(ses_id))
  auditar("USADO/33 asistencia (nominal por sesion)", "WSSala", "retornarSesionAsistencia",
          params = list(prmSesionId = ses_id), xpath_item = "//Asistencia")

# 3. Votaciones + detalle (34) ----------------------------------------------
rv <- auditar("USADO/34 votaciones lista", "WSLegislativo", "retornarVotacionesXAnno",
              params = list(prmAnno = anio), xpath_item = "//Votacion")
vot_id <- if (!is.null(rv)) xml_text(xml_find_first(rv$doc, "//Votacion/Id")) else NA
if (!is.na(vot_id))
  auditar("USADO/34 votacion detalle", "WSLegislativo", "retornarVotacionDetalle",
          params = list(prmVotacionId = vot_id), xpath_item = "//Voto")

# 4. Mociones + proyecto (35/36) --------------------------------------------
rm <- auditar("USADO/35 mociones lista", "WSLegislativo", "retornarMocionesXAnno",
              params = list(prmAnno = anio), xpath_item = "//ProyectoLey")
# un boletin de origen Camara
bol <- NA
if (!is.null(rm)) {
  pl <- xml_find_all(rm$doc, "//ProyectoLey")
  for (p in pl) {
    if (identical(xml_attr(xml_find_first(p, "./CamaraOrigen"), "Valor"), "1")) {
      bol <- xml_text(xml_find_first(p, "./NumeroBoletin")); break
    }
  }
}
if (!is.na(bol))
  auditar("USADO/35-36 proyecto detalle (retornarProyectoLey)", "WSLegislativo", "retornarProyectoLey",
          params = list(prmNumeroBoletin = bol))

# =============================================================================
# BLOQUE C — ADVERSARIAL: endpoints NO usados + parametros/hermanos alternativos
# =============================================================================
cat("\n========== BLOQUE C: ADVERSARIAL (no usados / alternativos) ==========\n")

# C1. Diputado individual: ¿mas campos que el roster? (distrito/region?) ------
if (!is.na(dip_id))
  auditar("ADV diputado individual (retornarDiputado)", "WSDiputado", "retornarDiputado",
          params = list(prmDiputadoId = dip_id))
auditar("ADV diputados por periodo (retornarDiputadosXPeriodo)", "WSDiputado",
        "retornarDiputadosXPeriodo", params = list(prmPeriodoId = 11), xpath_item = "//DiputadoPeriodo")

# C2. Sesiones por legislatura (hermano de XAnno) ----------------------------
auditar("ADV sesiones por legislatura", "WSSala", "retornarSesionesXLegislatura",
        params = list(prmLegislaturaId = 105), xpath_item = "//Sesion")

# C3. Join votacion<->proyecto ESTRUCTURADO (vs regex de Descripcion) --------
# (a) endpoint reverso proyecto->votaciones (param correcto: prmNumeroBoletin).
# (b) retornarProyectoLey de un boletin VOTADO: su nodo Votaciones ya trae el
#     link estructurado VotacionProyectoLey/Id (+ Articulo, TramiteConstitucional,
#     TramiteReglamentario) que el pipeline NO usa (extrae boletin por regex).
bol_votado <- NA
if (!is.null(rv)) {
  descs <- xml_text(xml_find_all(rv$doc, "//Votacion/Descripcion"))
  cand <- regmatches(descs, regexpr("[0-9]{3,6}-[0-9]{1,2}", descs))
  cand <- unique(cand[!is.na(cand) & nzchar(cand)])
  for (b in cand) {
    r <- descargar(op_url("WSLegislativo", "retornarProyectoLey", list(prmNumeroBoletin = b)))
    d <- parse_xml(r$body)
    if (!is.null(d) && length(xml_find_all(d, ".//Votaciones/VotacionProyectoLey")) > 0) { bol_votado <- b; break }
  }
}
if (!is.na(bol_votado))
  auditar(sprintf("ADV proyecto VOTADO: join estructurado en Votaciones (boletin %s)", bol_votado),
          "WSLegislativo", "retornarProyectoLey", params = list(prmNumeroBoletin = bol_votado),
          xpath_item = "//Votaciones/VotacionProyectoLey")
if (!is.na(bol_votado))
  auditar("ADV votaciones por proyecto (retornarVotacionesXProyectoLey)", "WSLegislativo",
          "retornarVotacionesXProyectoLey", params = list(prmNumeroBoletin = bol_votado),
          xpath_item = "//VotacionProyectoLey")

# C4. Tramites / estado de tramitacion (Q6 del contrato) ---------------------
auditar("ADV tramites constitucionales", "WSLegislativo", "retornarTramitesConstitucionales")
auditar("ADV tramites reglamentarios", "WSLegislativo", "retornarTramitesReglamentarios")
auditar("ADV tipos de estado (catalogo)", "WSComun", "retornarTiposEstado", xpath_item = "//*")

# C5. Mensajes (proyectos de iniciativa ejecutiva; el pipeline solo hace mociones)
auditar("ADV mensajes por anno", "WSLegislativo", "retornarMensajesXAnno",
        params = list(prmAnno = anio), xpath_item = "//ProyectoLey")

# C6. Catalogos WSComun potencialmente utiles al contrato --------------------
auditar("ADV partidos politicos (catalogo)", "WSComun", "retornarPartidosPoliticos", xpath_item = "//*")
auditar("ADV distritos (catalogo)", "WSComun", "retornarDistritos", xpath_item = "//*")
auditar("ADV regiones (catalogo)", "WSComun", "retornarRegiones", xpath_item = "//*")
auditar("ADV tipos justificacion inasistencia", "WSComun", "retornarTiposJustificacionesInasistencia", xpath_item = "//*")

# C7. Comisiones (asistencia a comision, distinta de sala) -------------------
auditar("ADV comisiones vigentes", "WSComision", "retornarComisionesVigentes", xpath_item = "//*")

# C8. Dominio de TipoAsistencia: el catalogo vs lo que el pipeline mapea ------
# El pipeline (DOMINIO_ASISTENCIA en 10_configuracion.R) mapea solo 0/1. ¿El
# catalogo trae mas? ¿aparece un tercer valor en datos reales?
cat("\n### ADV dominio TipoAsistencia: catalogo (WSComun) vs ocurrencia real\n")
rta <- descargar(op_url("WSComun", "retornarTiposAsistencia"))
dta <- parse_xml(rta$body)
if (!is.null(dta)) {
  writeBin(rta$raw, file.path(DIR_MUESTRAS, "camara_retornarTiposAsistencia_muestra.xml"))
  for (it in xml_children(xml_root(dta)))
    cat(sprintf("   catalogo: Valor=%s  Nombre=%s\n", xml_attr(it, "Valor") %||% "-", xml_text(it)))
}
if (!is.null(rs)) {  # rs = sesiones del anno (bloque B)
  ses <- xml_find_all(rs$doc, "//Sesion")
  sid <- vapply(ses, function(s) xml_text(xml_find_first(s, "./Id")), character(1))
  est <- vapply(ses, function(s) xml_text(xml_find_first(s, "./Estado")), character(1))
  cel <- sid[grepl("celebrad", est, ignore.case = TRUE)]
  tot <- integer(0)
  for (s in head(cel, 5)) {
    da <- parse_xml(descargar(op_url("WSSala", "retornarSesionAsistencia", list(prmSesionId = s)))$body)
    if (is.null(da)) next
    vals <- vapply(xml_find_all(da, "//Asistencia/TipoAsistencia"), function(n) xml_attr(n, "Valor"), character(1))
    for (v in names(table(vals))) tot[v] <- (tot[v] %||% 0L) + as.integer(table(vals)[v])
  }
  cat("   ocurrencia real (5 sesiones):",
      paste(sprintf("Valor %s=%d", names(tot), tot), collapse = " "), "\n")
}

log_msg("== Auditoria terminada. Muestras en 50_documentacion/andamios/muestras/ ==",
        origen = "31f_cobertura")
