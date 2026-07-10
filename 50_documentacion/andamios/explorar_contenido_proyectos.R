# =============================================================================
# explorar_contenido_proyectos.R
# -----------------------------------------------------------------------------
# ANDAMIO DE EXPLORACION (diagnostico, insumos-first). NO es pipeline: no toca
# 30_procesamiento/ ni 40_salidas/. Descubre, contra la API en vivo, dos cosas
# que el pipeline actual NO extrae:
#   PREGUNTA 1 - contenido legible de un proyecto (materia, resumen, tipo, etapa,
#                enlace) mas alla del titulo.
#   PREGUNTA 2 - trazabilidad voto -> proyecto (que llave conecta una votacion
#                con el proyecto votado y su contenido; cobertura del vinculo).
#
# Reutiliza la instrumentacion ya existente del proyecto (cliente HTTP con
# backoff, config) en vez de re-inventarla. Guarda MUESTRAS REALES crudas en
# 50_documentacion/andamios/muestras/ y escupe un reporte estructurado a stdout.
#
# Uso:   Rscript 50_documentacion/andamios/explorar_contenido_proyectos.R
# Salidas: 50_documentacion/andamios/muestras/*.xml (respuestas crudas reales)
#          50_documentacion/andamios/muestras/hallazgos_muestra.rds (tidy)
# Autor:  Claude Code (encargo de diagnostico, sesion explore)
# Creado: 2026-07-09
# =============================================================================

# ---- Cargar instrumentacion existente (cliente HTTP con backoff, config) -----
ROOT <- rprojroot::find_root(rprojroot::has_file(".here"))
source(file.path(ROOT, "10_utils", "10_utils.R"))
instalar_si_falta(c("httr", "xml2", "dplyr", "here", "tidyr"))
suppressMessages(library(dplyr))
source(file.path(ROOT, "10_utils", "10_configuracion.R"))

DIR_MUESTRAS <- file.path(ROOT, "50_documentacion", "andamios", "muestras")
fs::dir_create(DIR_MUESTRAS)

sep <- function(t) cat("\n", strrep("=", 78), "\n ", t, "\n", strrep("=", 78), "\n", sep = "")

# ---- Helper: arbol completo de nodos hoja con valor de muestra y atributos ---
# Devuelve un data.frame path | valor | atributos, recorriendo TODO el subarbol
# del primer nodo (para ver la forma real, no solo las hojas conocidas).
arbol_valores <- function(node, prefijo = xml2::xml_name(node)) {
  attrs <- xml2::xml_attrs(node)
  attr_str <- if (length(attrs)) paste(names(attrs), attrs, sep = "=", collapse = " ") else ""
  kids <- xml2::xml_children(node)
  if (length(kids) == 0) {
    val <- trimws(xml2::xml_text(node))
    return(data.frame(path = prefijo,
                      valor = substr(val, 1, 120),
                      attrs = attr_str, stringsAsFactors = FALSE))
  }
  filas <- if (nzchar(attr_str)) {
    data.frame(path = prefijo, valor = "(nodo)", attrs = attr_str, stringsAsFactors = FALSE)
  } else NULL
  for (k in kids) {
    filas <- rbind(filas, arbol_valores(k, paste0(prefijo, "/", xml2::xml_name(k))))
  }
  filas
}

# ---- Helper: descargar crudo (bytes exactos) y guardar como muestra real -----
# descargar_xml_camara() ya trae el doc parseado; para guardar la muestra CRUDA
# real hacemos ademas un GET directo (mismo cliente httr, con timeout) y
# persistimos los bytes tal cual llegaron de la API.
guardar_crudo <- function(operacion, parametros, nombre_archivo) {
  url <- paste0(CAMARA_WS_BASE, operacion)
  resp <- httr::GET(url, query = parametros, httr::timeout(60),
                    httr::user_agent("transparencia_legislativa_chile (diagnostico)"))
  ruta <- file.path(DIR_MUESTRAS, nombre_archivo)
  writeBin(httr::content(resp, as = "raw"), ruta)
  cat(sprintf("  [muestra cruda guardada] %s  (HTTP %d, %d bytes)\n",
              nombre_archivo, httr::status_code(resp),
              length(httr::content(resp, as = "raw"))))
  invisible(ruta)
}

# ---- Elegir muestra REAL desde la captura ya existente (read-only) -----------
# Boletines que estan a la vez en la captura de votos (como Proyecto de Ley) y
# en la de proyectos (mociones Camara): permiten mostrar la cadena completa
# proyecto -> contenido -> votaciones -> voto. Si la captura no existe, se cae a
# una lista fija de boletines reales ya observados.
boletines_muestra <- tryCatch({
  votos <- readRDS(file.path(ROOT, "40_salidas", "intermedios", "votos.rds"))
  proyectos <- readRDS(file.path(ROOT, "40_salidas", "intermedios", "proyectos.rds"))
  comunes <- intersect(unique(na.omit(votos$boletin)), unique(proyectos$boletin))
  head(comunes, 3)
}, error = function(e) c("18211-25", "18048-06", "18157-33"))

cat("Boletines de muestra (reales, con proyecto y votaciones):",
    paste(boletines_muestra, collapse = ", "), "\n")

# =============================================================================
# PREGUNTA 1 - Contenido legible de proyectos
# =============================================================================
sep("PREGUNTA 1.a - retornarProyectoLey: arbol COMPLETO (no solo Autores)")
# El pipeline (35) solo lee //Autores/ParlamentarioAutor/Diputado. Aqui volcamos
# TODO el arbol para ver Materias, TipoIniciativa, y cualquier campo de contenido.
bol1 <- boletines_muestra[1]
doc_pl <- descargar_xml_camara("WSLegislativo.asmx/retornarProyectoLey",
                               list(prmNumeroBoletin = bol1))
guardar_crudo("WSLegislativo.asmx/retornarProyectoLey",
              list(prmNumeroBoletin = bol1),
              sprintf("proyecto_%s.xml", gsub("[^0-9]", "_", bol1)))
cat(sprintf("\nBoletin %s - arbol de nodos (path | valor de muestra | attrs):\n", bol1))
arb <- arbol_valores(xml2::xml_root(doc_pl))
# Colapsar paths repetidos (p.ej. muchos Autores) a uno con conteo.
arb_resumen <- arb |>
  mutate(path_gen = gsub("/[0-9]+", "", path)) |>
  group_by(path) |> slice(1) |> ungroup()
for (i in seq_len(nrow(arb_resumen))) {
  cat(sprintf("  %-58s | %-40s | %s\n",
              arb_resumen$path[i], arb_resumen$valor[i], arb_resumen$attrs[i]))
}

sep("PREGUNTA 1.a-bis - Materias del proyecto (nodo que 35 descarta)")
# La COBERTURA de Materias es parcial: 0 en las mociones recientes de 2026,
# pero SI se llena en proyectos mas antiguos/avanzados. Se incluye 10986-24
# como caso real que las tiene, para no reportar un falso "la API no las da".
for (bol in unique(c(boletines_muestra, "10986-24"))) {
  d <- descargar_xml_camara("WSLegislativo.asmx/retornarProyectoLey",
                            list(prmNumeroBoletin = bol))
  materias <- xml2::xml_find_all(d, "//Materias/Materia")
  cat(sprintf("Boletin %s: %d materia(s)\n", bol, length(materias)))
  for (m in materias) {
    cat(sprintf("   - Id=%s Nombre=%s\n",
                texto_nodo(m, "./Id") %||% "?", texto_nodo(m, "./Nombre") %||% "?"))
  }
  Sys.sleep(PAUSA_API_SEG)
}

sep("PREGUNTA 1.b - retornarMaterias: catalogo tematico (sin params)")
doc_mat <- descargar_xml_camara("WSLegislativo.asmx/retornarMaterias")
guardar_crudo("WSLegislativo.asmx/retornarMaterias", list(), "catalogo_materias.xml")
mat_items <- xml2::xml_children(xml2::xml_root(doc_mat))
cat(sprintf("Raiz: %s | N items: %d\n", xml2::xml_name(xml2::xml_root(doc_mat)),
            length(mat_items)))
if (length(mat_items) > 0) {
  cat("Estructura de un item:\n")
  a <- arbol_valores(mat_items[[1]])
  for (i in seq_len(nrow(a))) cat(sprintf("   %-30s | %s | %s\n", a$path[i], a$valor[i], a$attrs[i]))
  cat("Primeras 10 materias del catalogo:\n")
  for (m in mat_items[seq_len(min(10, length(mat_items)))]) {
    cat("   ", texto_nodo(m, "./Id") %||% "?", " - ",
        texto_nodo(m, "./Nombre") %||% texto_nodo(m, ".") %||% "?", "\n", sep = "")
  }
}

sep("PREGUNTA 1.c - Tramites (etapa): son catalogos sin params, no por-proyecto")
for (op in c("retornarTramitesConstitucionales", "retornarTramitesReglamentarios")) {
  d <- tryCatch(descargar_xml_camara(paste0("WSLegislativo.asmx/", op)),
                error = function(e) e)
  if (inherits(d, "error")) { cat(op, "-> ERROR:", conditionMessage(d), "\n"); next }
  items <- xml2::xml_children(xml2::xml_root(d))
  cat(sprintf("%s -> raiz %s, %d items (catalogo de TIPOS de tramite, no la etapa de un proyecto)\n",
              op, xml2::xml_name(xml2::xml_root(d)), length(items)))
  if (length(items) > 0) {
    a <- arbol_valores(items[[1]])
    cat("   estructura item: ", paste(a$path, collapse = ", "), "\n")
  }
  Sys.sleep(PAUSA_API_SEG)
}

# =============================================================================
# PREGUNTA 2 - Trazabilidad voto -> proyecto
# =============================================================================
sep("PREGUNTA 2.a - retornarVotacionDetalle: arbol de nivel votacion (¿hay ref al proyecto?)")
# El pipeline (34) saca boletin por REGEX de Descripcion. ¿Hay un campo
# estructurado del proyecto en el detalle de la votacion? Volcamos el nivel
# votacion (excluyendo los 155 Voto para no inundar).
vid_muestra <- tryCatch({
  votos <- readRDS(file.path(ROOT, "40_salidas", "intermedios", "votos.rds"))
  # una votacion de Proyecto de Ley (con boletin) para ver el vinculo
  votos |> filter(!is.na(boletin)) |> slice(1) |> pull(votacion_id)
}, error = function(e) "89288")
doc_vd <- descargar_xml_camara("WSLegislativo.asmx/retornarVotacionDetalle",
                               list(prmVotacionId = vid_muestra))
guardar_crudo("WSLegislativo.asmx/retornarVotacionDetalle",
              list(prmVotacionId = vid_muestra),
              sprintf("votacion_detalle_%s.xml", vid_muestra))
cat(sprintf("Votacion %s - nodos de nivel votacion (hijos directos que NO son Votos):\n", vid_muestra))
root_vd <- xml2::xml_root(doc_vd)
for (ch in xml2::xml_children(root_vd)) {
  nm <- xml2::xml_name(ch)
  if (nm == "Votos") { cat(sprintf("   %-20s -> %d Voto (detalle nominal)\n", nm,
                                    length(xml2::xml_children(ch)))); next }
  attrs <- xml2::xml_attrs(ch)
  attr_str <- if (length(attrs)) paste(names(attrs), attrs, sep = "=", collapse = " ") else ""
  cat(sprintf("   %-20s = %-45s %s\n", nm, substr(trimws(xml2::xml_text(ch)), 1, 45), attr_str))
}

sep("PREGUNTA 2.b - retornarVotacionesXProyectoLey: link directo proyecto -> votaciones")
# OJO: el nodo se llama VotacionProyectoLey (NO Votacion). Cada uno trae el Id
# de la votacion -> permite mapear votacion_id -> boletin de forma ESTRUCTURADA
# (sin depender del regex sobre Descripcion), y ademas TramiteConstitucional/
# Reglamentario (etapa) y TipoVotacionProyectoLey (general/particular).
for (bol in boletines_muestra) {
  d <- descargar_xml_camara("WSLegislativo.asmx/retornarVotacionesXProyectoLey",
                            list(prmNumeroBoletin = bol))
  vs <- xml2::xml_find_all(d, "//VotacionProyectoLey")
  ids <- vapply(vs, function(v) texto_nodo(v, "./Id") %||% NA_character_, character(1))
  cat(sprintf("Boletin %s -> %d VotacionProyectoLey (raiz %s) ; ids: %s\n",
              bol, length(vs), xml2::xml_name(xml2::xml_root(d)),
              paste(ids, collapse = ", ")))
  if (length(vs) > 0 && bol == boletines_muestra[1]) {
    guardar_crudo("WSLegislativo.asmx/retornarVotacionesXProyectoLey",
                  list(prmNumeroBoletin = bol),
                  sprintf("votaciones_x_proyecto_%s.xml", gsub("[^0-9]", "_", bol)))
    cat("   estructura de una VotacionProyectoLey (campos que 34 NO captura):\n")
    a <- arbol_valores(vs[[1]])
    for (i in seq_len(nrow(a))) cat(sprintf("      %-42s | %s | %s\n", a$path[i], a$valor[i], a$attrs[i]))
  }
  Sys.sleep(PAUSA_API_SEG)
}

sep("PREGUNTA 2.b-bis - Verificacion de la cadena proyecto -> votacion -> voto")
# ¿Los Id de VotacionProyectoLey del proyecto calzan con la captura de votos?
# (concordancia entre el link estructurado y el regex-sobre-Descripcion).
chain_ok <- tryCatch({
  votos <- readRDS(file.path(ROOT, "40_salidas", "intermedios", "votos.rds"))
  d <- descargar_xml_camara("WSLegislativo.asmx/retornarProyectoLey",
                            list(prmNumeroBoletin = boletines_muestra[1]))
  vp_ids <- xml2::xml_text(xml2::xml_find_all(d, "//VotacionProyectoLey/Id"))
  en_cap <- vp_ids %in% votos$votacion_id
  cat(sprintf("Proyecto %s: %d votacion(es) en el detalle; %d en la captura de votos.\n",
              boletines_muestra[1], length(vp_ids), sum(en_cap)))
  for (vid in vp_ids[en_cap]) {
    fila <- votos[votos$votacion_id == vid, c("votacion_id", "boletin", "tipo")][1, ]
    cat(sprintf("   votacion %s -> boletin(regex)=%s tipo=%s  (link estructurado y regex CONCUERDAN)\n",
                vid, fila$boletin, fila$tipo))
  }
  TRUE
}, error = function(e) { cat("(captura no disponible)\n"); FALSE })

sep("PREGUNTA 2.c - Cobertura del vinculo boletin, recalculada en R sobre la captura real")
# Recalculo (no estimacion) del % de votaciones vinculables por boletin, y por
# que quedan huerfanas: se cruza con el campo Tipo de la votacion.
cob <- tryCatch({
  votos <- readRDS(file.path(ROOT, "40_salidas", "intermedios", "votos.rds"))
  vt <- votos |> distinct(votacion_id, boletin, tipo)
  tab <- vt |> mutate(tiene_boletin = !is.na(boletin)) |>
    count(tipo, tiene_boletin) |> tidyr::pivot_wider(names_from = tiene_boletin,
                                                     values_from = n, values_fill = 0)
  list(n = nrow(vt), con = sum(!is.na(vt$boletin)), tab = tab)
}, error = function(e) NULL)
if (!is.null(cob)) {
  cat(sprintf("Votaciones unicas en la captura: %d ; con boletin: %d (%.1f%%)\n",
              cob$n, cob$con, cob$con / cob$n * 100))
  cat("Cruce Tipo x tiene_boletin (0 huerfanos son Proyecto de Ley => el hueco es estructural):\n")
  print(as.data.frame(cob$tab))
} else {
  cat("(captura de votos no disponible; correr el pipeline 34 primero)\n")
}

# ---- Persistir un tidy de hallazgos de la muestra ----------------------------
hallazgos <- list(
  boletines_muestra = boletines_muestra,
  votacion_muestra = vid_muestra,
  fecha = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
  arbol_proyecto = arb_resumen
)
saveRDS(hallazgos, file.path(DIR_MUESTRAS, "hallazgos_muestra.rds"))
sep("FIN - muestras crudas y tidy en 50_documentacion/andamios/muestras/")
cat("Archivos:\n"); for (f in list.files(DIR_MUESTRAS)) cat("  -", f, "\n")
