# =============================================================================
# 34_extraer_votaciones.R
# -----------------------------------------------------------------------------
# Proposito: Extraer las votaciones nominales del anno de proceso y el sentido
#            del voto de cada diputado por votacion. El boletin del proyecto se
#            extrae del texto de Descripcion (la API no lo trae como campo).
# Insumos:   API Camara: WSLegislativo.asmx/retornarVotacionesXAnno (lista) y
#            WSLegislativo.asmx/retornarVotacionDetalle (voto nominal).
#            Cache: 20_insumos/camara/AAAAMMDD_votos_long_<anio>.rds
# Salidas:   40_salidas/intermedios/votos.rds (formato largo diputado x votacion).
# Autor:     Claude Code (encargo autonomo, sesion 1)
# Creado:    2026-07-06
# =============================================================================

source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
instalar_si_falta(c("httr", "xml2", "dplyr", "here", "fs"))
library(dplyr)

ROOT <- obtener_raiz_proyecto()
source(file.path(ROOT, "10_utils", "10_configuracion.R"))

# ---- Extraer el boletin embebido en la Descripcion --------------------------
# Formato observado: "Boletin N 16851-14" (o "Boletin N° 16851-14"). El boletin
# es NNNNN-NN. Devuelve NA si no aparece.
extraer_boletin <- function(descripcion) {
  m <- regmatches(descripcion, regexpr("[0-9]{3,6}-[0-9]{1,2}", descripcion))
  if (length(m) == 0) NA_character_ else m
}

# ---- Descargar votos en formato largo ---------------------------------------
extraer_votos_long <- function() {
  cache_key <- sprintf("votos_long_%d", ANIO_PROCESO)
  con_cache(cache_key, function() {
    doc <- descargar_xml_camara("WSLegislativo.asmx/retornarVotacionesXAnno",
                                list(prmAnno = ANIO_PROCESO))
    vot <- xml2::xml_find_all(doc, "//Votacion")
    vot_id <- vapply(vot, function(v) texto_nodo(v, "./Id"), character(1))
    vot_id <- vot_id[!is.na(vot_id)]
    log_msg(sprintf("Votaciones %d disponibles: %d", ANIO_PROCESO, length(vot_id)),
            origen = "34_votaciones")

    if (is.finite(MAX_VOTACIONES_DETALLE) && length(vot_id) > MAX_VOTACIONES_DETALLE) {
      log_msg(sprintf("Topando a %d votaciones (MAX_VOTACIONES_DETALLE).",
                      MAX_VOTACIONES_DETALLE), "WARN", "34_votaciones")
      vot_id <- vot_id[seq_len(MAX_VOTACIONES_DETALLE)]
    }

    filas <- list()
    for (vid in vot_id) {
      d <- descargar_xml_camara("WSLegislativo.asmx/retornarVotacionDetalle",
                                list(prmVotacionId = vid))
      root <- xml2::xml_root(d)
      descripcion <- texto_nodo(root, "./Descripcion")
      votos <- xml2::xml_find_all(d, "//Voto")
      if (length(votos) == 0) { Sys.sleep(PAUSA_API_SEG); next }
      filas[[length(filas) + 1L]] <- tibble(
        votacion_id = como_llave(vid),
        boletin     = extraer_boletin(descripcion),
        descripcion = descripcion,
        fecha       = substr(texto_nodo(root, "./Fecha") %||% NA_character_, 1, 10),
        resultado   = texto_nodo(root, "./Resultado"),
        tipo        = texto_nodo(root, "./Tipo"),
        diputado_id = como_llave(vapply(votos, function(v)
          texto_nodo(v, "./Diputado/Id"), character(1))),
        opcion_valor = vapply(votos, function(v)
          attr_nodo(v, "./OpcionVoto", "Valor"), character(1))
      )
      Sys.sleep(PAUSA_API_SEG)
    }
    bind_rows(filas)
  }, tope = MAX_VOTACIONES_DETALLE, origen = "34_votaciones")
}

votos <- extraer_votos_long()
log_msg(sprintf("Registros de voto (largo): %d", nrow(votos)), origen = "34_votaciones")

# ---- Validar dominio de OpcionVoto y traducir a sentido ---------------------
valores_obs <- sort(unique(votos$opcion_valor))
fuera <- setdiff(valores_obs, names(DOMINIO_VOTO))
if (length(fuera) > 0)
  log_msg(sprintf("Aviso: valores de OpcionVoto fuera del dominio conocido: %s",
                  paste(fuera, collapse = ", ")), "WARN", "34_votaciones")

votos <- votos |>
  mutate(sentido = unname(DOMINIO_VOTO[opcion_valor]))

# ---- Validacion de integridad -----------------------------------------------
n_vot <- length(unique(votos$votacion_id))
log_msg(sprintf("Votaciones con detalle: %d ; sentidos observados: %s",
                n_vot, paste(sort(unique(votos$sentido)), collapse = ", ")),
        origen = "34_votaciones")
if (nrow(votos) > 0 && any(is.na(votos$diputado_id)))
  stop("34_votaciones: diputado_id NA en el detalle de voto.")

# ---- Persistir ---------------------------------------------------------------
ruta_out <- ruta_salidas("intermedios", "votos.rds")
escribir_atomico(votos, ruta_out, function(o, r) saveRDS(o, r))
log_msg(sprintf("Escrito: %s (%d filas)", ruta_out, nrow(votos)), origen = "34_votaciones")
