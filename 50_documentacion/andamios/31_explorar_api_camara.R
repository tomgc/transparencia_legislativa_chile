# =============================================================================
# 31_explorar_api_camara.R
# -----------------------------------------------------------------------------
# Proposito: INSTRUMENTACION (Fase 1.B). Descubrir la firma REAL de los
#            servicios de opendata.camara.cl (no asumirla). Consulta los
#            endpoints candidatos, imprime la estructura XML cruda y registra
#            el hallazgo en 50_documentacion/activa/exploracion_api_camara.md.
# Insumos:   ninguno (fuente primaria: la API en vivo).
# Salidas:   50_documentacion/activa/exploracion_api_camara.md (evidencia).
# Naturaleza: diagnostico regenerable. NO forma parte del pipeline de
#            produccion (00_run_all.R): re-golpear todos los endpoints en cada
#            corrida es inutil y descortes. Se corre a mano cuando se sospecha
#            que la API cambio de forma (regla de deteccion 1.B del encargo).
# Autor:     Claude Code (encargo autonomo, sesion 1)
# Creado:    2026-07-06
# =============================================================================

# ---- Cargar utilidades ----
source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
instalar_si_falta(c("httr", "xml2", "here"))
library(httr)
library(xml2)

ROOT <- obtener_raiz_proyecto()
source(file.path(ROOT, "10_utils", "10_configuracion.R"))

# ---- Helper: arbol de paths hoja de un nodo ---------------------------------
paths_hoja <- function(node, prefijo = xml2::xml_name(node)) {
  kids <- xml2::xml_children(node)
  if (length(kids) == 0) return(prefijo)
  unlist(lapply(kids, function(k)
    paths_hoja(k, paste0(prefijo, "/", xml2::xml_name(k)))))
}

# ---- Helper: registrar un endpoint (imprime y acumula lineas markdown) ------
.reporte <- character()
add <- function(...) .reporte[[length(.reporte) + 1L]] <<- paste0(...)

explorar <- function(titulo, operacion, parametros = list(),
                     xpath_item = NULL, mostrar_valores = NULL) {
  log_msg(sprintf("Explorando: %s (%s)", titulo, operacion), origen = "31_explorar")
  add("### ", titulo)
  add("")
  add("- **Operacion:** `", operacion, "`")
  if (length(parametros) > 0) {
    add("- **Parametros:** ", paste(sprintf("`%s=%s`", names(parametros),
                                            unlist(parametros)), collapse = ", "))
  }
  doc <- tryCatch(descargar_xml_camara(operacion, parametros),
                  error = function(e) e)
  if (inherits(doc, "error")) {
    add("- **ESTADO: FALLO** -> ", conditionMessage(doc))
    add("")
    log_msg(sprintf("  FALLO: %s", conditionMessage(doc)), "ERROR", "31_explorar")
    return(invisible(FALSE))
  }
  root <- xml2::xml_root(doc)
  add("- **Raiz XML:** `", xml2::xml_name(root), "`")
  add("- **Namespace declarado:** `http://opendata.camara.cl/camaradiputados/v1` (removido al parsear)")

  nodo_muestra <- if (!is.null(xpath_item)) {
    n <- xml2::xml_find_first(doc, xpath_item)
    if (inherits(n, "xml_missing")) root else n
  } else root
  n_items <- if (!is.null(xpath_item)) length(xml2::xml_find_all(doc, xpath_item)) else 1L
  add("- **N de items (", if (is.null(xpath_item)) "raiz" else xpath_item, "):** ", n_items)
  add("")
  add("Estructura de nodos hoja (primer item):")
  add("")
  add("```")
  ph <- unique(paths_hoja(nodo_muestra))
  for (p in ph) add(p)
  add("```")

  if (!is.null(mostrar_valores)) {
    for (mv in mostrar_valores) {
      nn <- xml2::xml_find_all(doc, mv$xpath)
      if (length(nn) == 0) next
      vals <- if (isTRUE(mv$attr_valor)) {
        paste0(sapply(nn, function(n) xml2::xml_attr(n, "Valor")), " | ",
               sapply(nn, xml2::xml_text))
      } else sapply(nn, xml2::xml_text)
      add("")
      add("Dominio observado de **", mv$label, "**:")
      add("")
      tb <- sort(table(vals), decreasing = TRUE)
      add("```")
      for (i in seq_along(tb)) add(sprintf("  %-30s %d", names(tb)[i], tb[i]))
      add("```")
    }
  }
  add("")
  Sys.sleep(PAUSA_API_SEG)
  invisible(TRUE)
}

# ---- Cabecera del reporte ---------------------------------------------------
add("# Exploracion de la API de la Camara de Diputadas y Diputados")
add("")
add("> Generado por `30_procesamiento/31_explorar_api_camara.R` ",
    "(Fase 1.B, instrumentacion). Evidencia regenerable: re-correr el script ",
    "actualiza este archivo con la forma REAL de la API en el momento de la corrida.")
add("")
add("- **Fecha de exploracion:** ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
add("- **Base:** `", CAMARA_WS_BASE, "`")
add("- **Transporte:** SOLO HTTPS (el esquema HTTP hace timeout).")
add("- **Formato:** XML con namespace `http://opendata.camara.cl/camaradiputados/v1`.")
add("")
add("## Endpoints explorados")
add("")

# ---- Descubrir el periodo legislativo vigente (para parametrizar) -----------
doc_per <- descargar_xml_camara("WSLegislativo.asmx/retornarPeriodoLegislativoActual")
periodo_id     <- texto_nodo(xml2::xml_root(doc_per), ".//Id")
periodo_nombre <- texto_nodo(xml2::xml_root(doc_per), ".//Nombre")
add("**Periodo legislativo vigente:** Id `", periodo_id, "` (", periodo_nombre, ").")
add("")

anio <- ANIO_PROCESO

# ---- 1. Roster de diputados vigentes ----
explorar("Roster de diputados del periodo vigente",
         "WSDiputado.asmx/retornarDiputadosPeriodoActual",
         xpath_item = "//DiputadoPeriodo",
         mostrar_valores = list(
           list(xpath = "//DiputadoPeriodo/Diputado/Militancias/Militancia/Partido/Id",
                label = "Partido/Id (todas las militancias, historico)",
                attr_valor = FALSE)))

# ---- 2. Sesiones y asistencia ----
explorar(sprintf("Sesiones de sala del anno %d", anio),
         "WSSala.asmx/retornarSesionesXAnno",
         parametros = list(prmAnno = anio),
         xpath_item = "//Sesion")

doc_ses <- descargar_xml_camara("WSSala.asmx/retornarSesionesXAnno",
                                list(prmAnno = anio))
ses_ids <- xml2::xml_text(xml2::xml_find_all(doc_ses, "//Sesion/Id"))
if (length(ses_ids) > 0) {
  explorar(sprintf("Asistencia de una sesion (Id %s)", ses_ids[1]),
           "WSSala.asmx/retornarSesionAsistencia",
           parametros = list(prmSesionId = ses_ids[1]),
           xpath_item = "//Asistencia",
           mostrar_valores = list(
             list(xpath = "//Asistencia/TipoAsistencia",
                  label = "TipoAsistencia (Valor | etiqueta)", attr_valor = TRUE)))
}

# ---- 3. Votaciones y detalle de voto ----
explorar(sprintf("Votaciones nominales del anno %d", anio),
         "WSLegislativo.asmx/retornarVotacionesXAnno",
         parametros = list(prmAnno = anio),
         xpath_item = "//Votacion")

doc_vot <- descargar_xml_camara("WSLegislativo.asmx/retornarVotacionesXAnno",
                                list(prmAnno = anio))
vot_ids <- xml2::xml_text(xml2::xml_find_all(doc_vot, "//Votacion/Id"))
if (length(vot_ids) > 0) {
  explorar(sprintf("Detalle de una votacion (Id %s)", vot_ids[1]),
           "WSLegislativo.asmx/retornarVotacionDetalle",
           parametros = list(prmVotacionId = vot_ids[1]),
           xpath_item = "//Voto",
           mostrar_valores = list(
             list(xpath = "//Voto/OpcionVoto",
                  label = "OpcionVoto (Valor | etiqueta)", attr_valor = TRUE)))
}

# ---- 4. Proyectos (mociones de diputados) ----
explorar(sprintf("Mociones (proyectos de iniciativa parlamentaria) del anno %d", anio),
         "WSLegislativo.asmx/retornarMocionesXAnno",
         parametros = list(prmAnno = anio),
         xpath_item = "//ProyectoLey",
         mostrar_valores = list(
           list(xpath = "//ProyectoLey/CamaraOrigen",
                label = "CamaraOrigen (Valor | etiqueta)", attr_valor = TRUE)))

doc_moc <- descargar_xml_camara("WSLegislativo.asmx/retornarMocionesXAnno",
                                list(prmAnno = anio))
pl <- xml2::xml_find_all(doc_moc, "//ProyectoLey")
# Buscar una mocion de origen Camara (CamaraOrigen Valor=1) para ver Autores/Diputado.
cam <- sapply(pl, function(n) attr_nodo(n, "./CamaraOrigen", "Valor"))
idx <- which(cam == "1")
if (length(idx) > 0) {
  bol <- texto_nodo(pl[[idx[1]]], "./NumeroBoletin")
  explorar(sprintf("Detalle de un proyecto de origen Camara (boletin %s)", bol),
           "WSLegislativo.asmx/retornarProyectoLey",
           parametros = list(prmNumeroBoletin = bol),
           xpath_item = "//Autores/ParlamentarioAutor")
}

# ---- Hallazgos y decisiones ----
add("## Hallazgos que condicionan el pipeline")
add("")
add("1. **La API responde solo por HTTPS.** El esquema `http://` hace timeout.")
add("2. **Distrito y region NO se exponen** en ningun endpoint de diputados ",
    "(`retornarDiputadosPeriodoActual`, `retornarDiputado`, `retornarDiputadosXPeriodo` ",
    "tienen estructura de nodos identica y sin distrito/region). Quedan como ",
    "`NA_character_` en el JSON, documentado como hueco de la fuente. # REVISAR: ",
    "requeriria una segunda fuente (BCN/SERVEL), fuera del alcance de Fase 1.")
add("3. **Estado de tramitacion de un proyecto NO se expone** en ",
    "`retornarProyectoLey` (solo Id, NumeroBoletin, Nombre, FechaIngreso, ",
    "TipoIniciativa, CamaraOrigen, Autores, Votaciones, Materias, Admisible). ",
    "Se conserva `Admisible` como proxy parcial; el estado de tramitacion queda ",
    "`NA`. # REVISAR.")
add("4. **La militancia vigente** de un diputado es la de mayor `FechaInicio` ",
    "(ninguna militancia trae `FechaTermino` vacia; todas cierran en el fin de ",
    "periodo). El partido actual = esa militancia.")
add("5. **El boletin de una votacion** viene embebido en el texto de ",
    "`Descripcion` (p.ej. \"Boletin N 16851-14\"); se extrae por expresion regular.")
add("6. **Tendencia (izquierda/derecha) no viene en la API**: es una columna ",
    "derivada del mapeo `MAPA_PARTIDO_TENDENCIA` en `10_utils/10_configuracion.R`, ",
    "decision metodologica del titular.")
add("")

# ---- Escribir el reporte ----
ruta_doc <- file.path(ROOT, "50_documentacion", "activa", "exploracion_api_camara.md")
writeLines(.reporte, ruta_doc, useBytes = TRUE)
log_msg(sprintf("Exploracion registrada en %s", ruta_doc), origen = "31_explorar")
