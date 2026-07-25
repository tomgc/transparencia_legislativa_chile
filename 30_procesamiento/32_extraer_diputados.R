# =============================================================================
# 32_extraer_diputados.R
# -----------------------------------------------------------------------------
# Proposito: Extraer el roster de diputados del periodo vigente desde
#            opendata.camara.cl y construir la tabla base (una fila por
#            diputado): id, nombre, sexo, partido vigente, tendencia derivada,
#            distrito y region.
#            La API de la Camara NO expone territorio (verificado: la union de
#            campos sobre los 155 items es Id, Nombre, Nombre2, ApellidoPaterno,
#            ApellidoMaterno, FechaNacimiento, RUT, RUTDV, Sexo, Militancias).
#            El territorio entra por join contra un insumo estatico auditado
#            (decision D5), no por scraping en cada refresh.
# Insumos:   API Camara (WSDiputado.asmx/retornarDiputadosPeriodoActual).
#            Cache crudo: 20_insumos/camara/AAAAMMDD_diputados.rds
#            20_insumos/territorio/20260724_crosswalk_distrito_diputado.csv
#            20_insumos/territorio/catalogo_distrito_region.csv
# Salidas:   40_salidas/intermedios/diputados.rds (tibble, id como character).
# Autor:     Claude Code (encargo autonomo, sesion 1; territorio sesion 10)
# Creado:    2026-07-06
# =============================================================================

# ---- Cargar utilidades y configuracion ----
source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
instalar_si_falta(c("httr", "xml2", "dplyr", "here", "fs"))
library(dplyr)

ROOT <- obtener_raiz_proyecto()
source(file.path(ROOT, "10_utils", "10_configuracion.R"))

# ---- Insumo territorial estatico (decision D5) ------------------------------
# El territorio NO se consulta a la fuente en cada refresh: la ficha de BCN es
# HTML sin contrato de datos y un cambio de plantilla romperia el pipeline
# semanal en silencio. Se lee de dos CSV versionados y auditados:
#   - crosswalk diputado_id -> distrito, generado UNA VEZ por el andamio
#     50_documentacion/andamios/medir_fuente_territorio.R (fase gen), que NO es
#     etapa de este pipeline y se corre a mano cuando cambia el roster;
#   - catalogo distrito -> region, dato de referencia estable contra la ley
#     electoral (28 distritos), que solo cambia si cambia la norma.
# Veredicto de la medicion que sustenta la fuente y la llave:
#   50_documentacion/andamios/logs/20260724_medicion_fuente_territorio.md
ARCHIVO_CROSSWALK <- "20260724_crosswalk_distrito_diputado.csv"
ARCHIVO_CATALOGO  <- "catalogo_distrito_region.csv"

# Lee un CSV del insumo territorial. Marca las columnas de texto como UTF-8:
# bajo un locale C, read.csv devuelve los bytes correctos pero sin marcar, y
# entonces el enc2utf8() del 39 los reinterpretaria y romperia los nombres de
# region con tilde o ñ. Marcarlo aqui es no-op bajo un locale UTF-8.
leer_csv_territorio <- function(archivo, clases) {
  ruta <- ruta_insumos("territorio", archivo)
  if (!file.exists(ruta))
    stop(sprintf(paste0("32_diputados: falta el insumo territorial '%s'. ",
                        "Regeneralo con la fase 'gen' de ",
                        "50_documentacion/andamios/medir_fuente_territorio.R."),
                 ruta), call. = FALSE)
  d <- utils::read.csv(ruta, comment.char = "#", colClasses = clases,
                       stringsAsFactors = FALSE)
  for (col in names(d)[vapply(d, is.character, logical(1))])
    Encoding(d[[col]]) <- "UTF-8"
  d
}

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
      partido_alias    = partido_alias
    )
  })
  bind_rows(filas)
}

diputados <- extraer_diputados()

# ---- Territorio: join contra el insumo estatico ------------------------------
# diputado_id es character a ambos lados (🔒 invariante de llave); distrito es
# integer 1-28 y es la llave del catalogo de region.
crosswalk <- leer_csv_territorio(
  ARCHIVO_CROSSWALK,
  c(diputado_id = "character", distrito = "integer", bcn_persona_id = "character",
    capturado_el = "character", fuente = "character"))
catalogo <- leer_csv_territorio(
  ARCHIVO_CATALOGO, c(distrito = "integer", region = "character"))

if (!is.character(crosswalk$diputado_id))
  stop("32_diputados: crosswalk con diputado_id no character (invariante de llave).")
if (anyDuplicated(crosswalk$diputado_id) > 0)
  stop("32_diputados: el crosswalk trae diputado_id duplicados.")
if (anyDuplicated(catalogo$distrito) > 0)
  stop("32_diputados: el catalogo distrito->region trae distritos duplicados.")

diputados <- diputados |>
  left_join(crosswalk |> select(diputado_id, distrito), by = "diputado_id") |>
  left_join(catalogo, by = "distrito")

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

# El territorio no puede quedar NA en silencio (C.8): si el roster incorpora un
# reemplazo que el crosswalk no conoce, el paso falla ruidosamente nombrando al
# culpable, y la correccion es regenerar el insumo, nunca fabricar el dato.
sin_distrito <- diputados$diputado_id[is.na(diputados$distrito)]
if (length(sin_distrito) > 0)
  stop(sprintf(paste0("32_diputados: %d diputado(s) sin distrito tras el join: %s. ",
                      "El crosswalk '%s' no los cubre (probable cambio de roster). ",
                      "Regeneralo con la fase 'gen' del andamio ",
                      "medir_fuente_territorio.R y revisa el diff antes de commitear."),
               length(sin_distrito), paste(sin_distrito, collapse = ", "),
               ARCHIVO_CROSSWALK), call. = FALSE)

fuera_rango <- diputados$diputado_id[diputados$distrito < 1 | diputados$distrito > 28]
if (length(fuera_rango) > 0)
  stop(sprintf("32_diputados: distrito fuera del rango legal 1-28 en: %s.",
               paste(fuera_rango, collapse = ", ")), call. = FALSE)

sin_region <- diputados$diputado_id[is.na(diputados$region)]
if (length(sin_region) > 0)
  stop(sprintf(paste0("32_diputados: %d diputado(s) con distrito pero sin region: %s. ",
                      "El catalogo '%s' no cubre esos distritos."),
               length(sin_region), paste(sin_region, collapse = ", "),
               ARCHIVO_CATALOGO), call. = FALSE)

log_msg(sprintf("Territorio: %d/%d con distrito y region; %d distritos distintos.",
                sum(!is.na(diputados$distrito)), n,
                length(unique(diputados$distrito))), origen = "32_diputados")

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
