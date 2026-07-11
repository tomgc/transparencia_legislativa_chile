# =============================================================================
# 35_extraer_proyectos.R
# -----------------------------------------------------------------------------
# Proposito: Extraer los proyectos presentados por diputados (mociones de
#            origen Camara) del anno de proceso, con el rol de cada firmante
#            (autor principal / coautor). El estado de tramitacion NO lo expone
#            la API (ver exploracion) -> se conserva Admisible como proxy.
# Insumos:   API Camara: WSLegislativo.asmx/retornarMocionesXAnno (lista) y
#            WSLegislativo.asmx/retornarProyectoLey (detalle con Autores).
#            Cache: 20_insumos/camara/AAAAMMDD_proyectos_long_<anio>.rds
# Salidas:   40_salidas/intermedios/proyectos.rds (una fila por autor x boletin).
# Autor:     Claude Code (encargo autonomo, sesion 1)
# Creado:    2026-07-06
# =============================================================================

source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
instalar_si_falta(c("httr", "xml2", "dplyr", "here", "fs"))
library(dplyr)

ROOT <- obtener_raiz_proyecto()
source(file.path(ROOT, "10_utils", "10_configuracion.R"))

# ---- Descargar proyectos (autores) en formato largo -------------------------
extraer_proyectos_long <- function() {
  cache_key <- sprintf("proyectos_long_%d", ANIO_PROCESO)
  con_cache(cache_key, function() {
    doc <- descargar_xml_camara("WSLegislativo.asmx/retornarMocionesXAnno",
                                list(prmAnno = ANIO_PROCESO))
    pl <- xml2::xml_find_all(doc, "//ProyectoLey")
    # Metadatos de la lista (para no depender del detalle).
    meta <- tibble(
      boletin       = vapply(pl, function(p) texto_nodo(p, "./NumeroBoletin") %||% NA_character_, character(1)),
      nombre        = vapply(pl, function(p) texto_nodo(p, "./Nombre") %||% NA_character_, character(1)),
      fecha_ingreso = substr(vapply(pl, function(p) texto_nodo(p, "./FechaIngreso") %||% NA_character_, character(1)), 1, 10),
      camara_valor  = vapply(pl, function(p) attr_nodo(p, "./CamaraOrigen", "Valor"), character(1)),
      admisible     = vapply(pl, function(p) texto_nodo(p, "./Admisible") %||% NA_character_, character(1))
    )
    meta$boletin <- como_llave(meta$boletin)
    # Solo mociones de origen Camara traen autores Diputado (POLITICA de la
    # exploracion): las de origen Senado traen autores Senador, fuera de alcance.
    origen_camara <- meta[meta$camara_valor == "1" & !is.na(meta$boletin), ]
    log_msg(sprintf("Mociones %d: %d totales, %d de origen Camara.",
                    ANIO_PROCESO, nrow(meta), nrow(origen_camara)),
            origen = "35_proyectos")

    boletines <- origen_camara$boletin
    if (is.finite(MAX_PROYECTOS_DETALLE) && length(boletines) > MAX_PROYECTOS_DETALLE) {
      log_msg(sprintf("Topando a %d proyectos (MAX_PROYECTOS_DETALLE).",
                      MAX_PROYECTOS_DETALLE), "WARN", "35_proyectos")
      boletines <- boletines[seq_len(MAX_PROYECTOS_DETALLE)]
    }

    filas <- list()
    for (bol in boletines) {
      d <- descargar_xml_camara("WSLegislativo.asmx/retornarProyectoLey",
                                list(prmNumeroBoletin = bol))
      autores <- xml2::xml_find_all(d, "//Autores/ParlamentarioAutor")
      if (length(autores) == 0) { Sys.sleep(PAUSA_API_SEG); next }
      for (a in autores) {
        dip <- xml2::xml_find_first(a, "./Diputado")
        if (inherits(dip, "xml_missing")) next  # autor Senador: se ignora
        filas[[length(filas) + 1L]] <- tibble(
          boletin     = como_llave(bol),
          diputado_id = como_llave(texto_nodo(dip, "./Id")),
          orden       = texto_nodo(a, "./Orden")  # crudo; ver nota de rol abajo
        )
      }
      Sys.sleep(PAUSA_API_SEG)
    }
    autores_long <- bind_rows(filas)
    # Adjuntar metadatos del proyecto a cada fila de autoria.
    if (nrow(autores_long) > 0) {
      autores_long <- dplyr::left_join(
        autores_long,
        origen_camara[, c("boletin", "nombre", "fecha_ingreso", "admisible")],
        by = "boletin")
    }
    autores_long
  }, tope = MAX_PROYECTOS_DETALLE, origen = "35_proyectos")
}

proyectos <- extraer_proyectos_long()

# ---- Rol de autoria ----------------------------------------------------------
# HALLAZGO (Fase 1.C): el campo Orden llega SIEMPRE en 0 para todos los
# firmantes; la API NO distingue autor principal de coautor. No se fabrica esa
# jerarquia: todo firmante se marca "firmante". # REVISAR si una segunda fuente
# permitiera recuperar el orden real de firma.
if (nrow(proyectos) > 0) proyectos <- dplyr::mutate(proyectos, rol = "firmante")
log_msg(sprintf("Registros de autoria (largo): %d", nrow(proyectos)),
        origen = "35_proyectos")

# ---- Validacion de integridad -----------------------------------------------
if (nrow(proyectos) > 0) {
  if (any(is.na(proyectos$diputado_id)))
    stop("35_proyectos: diputado_id NA en autoria.")
  if (any(is.na(proyectos$boletin)))
    stop("35_proyectos: boletin NA en autoria.")
  log_msg(sprintf("Boletines distintos: %d ; roles: %s",
                  length(unique(proyectos$boletin)),
                  paste(sort(unique(proyectos$rol)), collapse = ", ")),
          origen = "35_proyectos")
}

# ---- Persistir ---------------------------------------------------------------
ruta_out <- ruta_salidas("intermedios", "proyectos.rds")
# Sello de procedencia: hash del cache crudo de proyectos (fix sesion 8).
escribir_atomico(proyectos, ruta_out, function(o, r) saveRDS(o, r),
                 hash_origen = hash_origen_de(
                   ruta_cache(sprintf("proyectos_long_%d", ANIO_PROCESO), MAX_PROYECTOS_DETALLE)))
log_msg(sprintf("Escrito: %s (%d filas)", ruta_out, nrow(proyectos)),
        origen = "35_proyectos")
