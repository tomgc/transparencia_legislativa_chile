# =============================================================================
# 32_extraer_diputados.R
# -----------------------------------------------------------------------------
# Proposito: Extraer el roster de diputados del periodo vigente desde
#            opendata.camara.cl y construir la tabla base (una fila por
#            diputado): id, nombre, sexo, partido vigente, tendencia derivada.
#            Distrito y region NO los expone la API (ver exploracion) -> NA.
# Insumos:   API Camara (WSDiputado.asmx/retornarDiputadosPeriodoActual).
#            Cache crudo: 20_insumos/camara/AAAAMMDD_diputados.rds
# Salidas:   40_salidas/intermedios/diputados.rds (tibble, id como character).
# Autor:     Claude Code (encargo autonomo, sesion 1)
# Creado:    2026-07-06
# =============================================================================

# ---- Cargar utilidades y configuracion ----
source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
instalar_si_falta(c("httr", "xml2", "dplyr", "here", "fs"))
library(dplyr)

ROOT <- obtener_raiz_proyecto()
source(file.path(ROOT, "10_utils", "10_configuracion.R"))

# ---- Extraer roster ----------------------------------------------------------
extraer_diputados <- function() {
  doc <- con_cache("diputados", function() {
    d <- descargar_xml_camara("WSDiputado.asmx/retornarDiputadosPeriodoActual")
    as.character(d)  # se cachea como texto XML crudo
  }, origen = "32_diputados")
  doc <- xml2::read_xml(doc); xml2::xml_ns_strip(doc)

  dps <- xml2::xml_find_all(doc, "//DiputadoPeriodo")
  log_msg(sprintf("DiputadoPeriodo recibidos: %d", length(dps)), origen = "32_diputados")

  filas <- lapply(dps, function(dp) {
    dip <- xml2::xml_find_first(dp, "./Diputado")
    nombres <- c(texto_nodo(dip, "./Nombre"), texto_nodo(dip, "./Nombre2"))
    apellidos <- c(texto_nodo(dip, "./ApellidoPaterno"), texto_nodo(dip, "./ApellidoMaterno"))
    nombre_completo <- paste(na.omit(c(nombres, apellidos)), collapse = " ")

    # Militancia vigente: la de mayor FechaInicio (POLITICA de la exploracion).
    mils <- xml2::xml_find_all(dp, ".//Militancia")
    partido_id <- NA_character_; partido_nombre <- NA_character_; partido_alias <- NA_character_
    if (length(mils) > 0) {
      fi <- as.Date(substr(vapply(mils, function(m)
        texto_nodo(m, "./FechaInicio") %||% NA_character_, character(1)), 1, 10))
      sel <- which.max(fi)
      if (length(sel) == 1) {
        partido_id     <- como_llave(texto_nodo(mils[[sel]], ".//Partido/Id"))
        partido_nombre <- texto_nodo(mils[[sel]], ".//Partido/Nombre")
        partido_alias  <- texto_nodo(mils[[sel]], ".//Partido/Alias")
      }
    }

    tibble(
      diputado_id      = como_llave(texto_nodo(dip, "./Id")),
      nombre           = nombre_completo,
      sexo             = texto_nodo(dip, "./Sexo"),
      fecha_nacimiento = substr(texto_nodo(dip, "./FechaNacimiento") %||% NA_character_, 1, 10),
      partido_id       = partido_id,
      partido_nombre   = partido_nombre,
      partido_alias    = partido_alias,
      # Distrito y region NO expuestos por la API (ver exploracion). # REVISAR.
      distrito         = NA_character_,
      region           = NA_character_
    )
  })
  bind_rows(filas)
}

diputados <- extraer_diputados()

# ---- Derivar tendencia (constante nombrada; NA si partido no mapeado) --------
diputados <- diputados |>
  mutate(tendencia = tendencia_de_partido(partido_id))

# ---- Validacion de integridad (POLITICA 5.3.8) ------------------------------
n <- nrow(diputados)
log_msg(sprintf("Diputados extraidos: %d", n), origen = "32_diputados")

if (n == 0) stop("32_diputados: roster vacio.")
if (any(is.na(diputados$diputado_id)))
  stop("32_diputados: hay diputado_id NA (llave critica).")
if (anyDuplicated(diputados$diputado_id) > 0)
  stop("32_diputados: hay diputado_id duplicados.")
if (!is.character(diputados$diputado_id))
  stop("32_diputados: diputado_id no es character (invariante de llave).")

sin_partido <- sum(is.na(diputados$partido_id))
if (sin_partido > 0)
  log_msg(sprintf("Aviso: %d diputados sin partido vigente.", sin_partido),
          "WARN", "32_diputados")

sin_tendencia <- sort(unique(diputados$partido_id[is.na(diputados$tendencia) &
                                                    !is.na(diputados$partido_id)]))
if (length(sin_tendencia) > 0)
  log_msg(sprintf("Partidos sin tendencia mapeada (NA): %s",
                  paste(sin_tendencia, collapse = ", ")), "WARN", "32_diputados")

# ---- Persistir ---------------------------------------------------------------
ruta_out <- ruta_salidas("intermedios", "diputados.rds")
# Sello de procedencia: hash del cache crudo del roster (fix sesion 8).
escribir_atomico(diputados, ruta_out, function(o, r) saveRDS(o, r),
                 hash_origen = hash_origen_de(ruta_cache("diputados")))
log_msg(sprintf("Escrito: %s (%d filas)", ruta_out, n), origen = "32_diputados")
