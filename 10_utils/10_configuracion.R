# =============================================================================
# 10_configuracion.R - Configuracion del proyecto
# -----------------------------------------------------------------------------
# Proyecto de datos PUBLICOS (Rama A, POLITICA 8.2): raiz unificada. Las
# carpetas de datos viven en el repo y se resuelven con here::here().
# Aqui viven TODAS las rutas, constantes y parametros del proyecto; ningun
# script aguas abajo hardcodea rutas ni numeros magicos (POLITICA 5.3.10, 5.4).
# =============================================================================

# ---- Rutas de datos (raiz unificada) ----------------------------------------
ruta_insumos <- function(...) here::here("20_insumos", ...)
ruta_salidas <- function(...) here::here("40_salidas", ...)

# ---- Fuente de datos: API de la Camara de Diputadas y Diputados -------------
# opendata.camara.cl. Servicios SOAP/REST que devuelven XML. La firma real de
# cada operacion se documento en Fase 1.B:
#   50_documentacion/activa/exploracion_api_camara.md
# IMPORTANTE: la API responde SOLO por HTTPS; el esquema HTTP hace timeout.
CAMARA_WS_BASE <- "https://opendata.camara.cl/camaradiputados/WServices/"
options(camara.base_url = CAMARA_WS_BASE)

# ---- Periodo y anno de proceso ----------------------------------------------
# El roster se toma del periodo legislativo VIGENTE (retornarDiputadosPeriodoActual,
# sin parametros). ANIO_PROCESO acota las sesiones, votaciones y mociones que se
# extraen (los endpoints de esas fuentes son por anno). Constante nombrada, no
# numero magico embebido.
ANIO_PROCESO <- 2026L

# ---- Topes de extraccion --------------------------------------------------
# VALORES DE PRODUCCION: anno COMPLETO (todos los detalles del anno de proceso).
# Los topes existen para acotar la corrida de validacion de arquitectura; en
# produccion se ponen en Inf para no truncar cobertura. Decision metodologica
# declarada como constante (POLITICA 5.3.10).
# NOTA (# REVISAR): la clave del cache (con_cache) NO codifica el tope; si se
# cambia un tope, hay que forzar el refresco (options(camara.refrescar = TRUE))
# para que el snapshot del dia se regenere en vez de reutilizar uno con tope
# distinto.
MAX_SESIONES_DETALLE   <- Inf   # asistencia por sesion (todas las celebradas)
MAX_VOTACIONES_DETALLE <- Inf   # detalle de voto nominal por votacion (todas)
MAX_PROYECTOS_DETALLE  <- Inf   # detalle de autores por mocion (todas, origen Camara)

# Pausa cortesia entre llamadas de detalle a la API (segundos).
PAUSA_API_SEG <- 0.12

# Si TRUE, re-descarga aunque exista el snapshot crudo en 20_insumos/camara/.
# Si FALSE (default), reutiliza el snapshot del dia -> idempotencia y cortesia
# con la API (POLITICA 5.2.3). Se puede sobreescribir por corrida:
#   options(camara.refrescar = TRUE)
REFRESCAR_API <- getOption("camara.refrescar", FALSE)

# ---- Dominios canonicos observados en la API (Fase 1.B) ---------------------
# Se declaran para validar contra ellos en la extraccion (POLITICA 5.3.8) y
# para traducir el atributo Valor a etiqueta estable. Si aparece un Valor
# fuera de estos dominios, la extraccion debe alertar (no fallar en silencio).
DOMINIO_ASISTENCIA <- c(
  "0" = "no_asiste",
  "1" = "asiste"
)
DOMINIO_VOTO <- c(
  "0" = "en_contra",
  "1" = "a_favor",
  "2" = "abstencion",
  "3" = "dispensado",  # descubierto en Fase 1.C (concuerda con TotalDispensado)
  "4" = "no_vota"
)
DOMINIO_CAMARA_ORIGEN <- c(
  "1" = "camara_diputados",
  "2" = "senado"
)

# ---- Mapeo partido -> tendencia --------------------------------------------
# DECISION METODOLOGICA DEL TITULAR, NO DEL ASISTENTE.
# El eje de tendencia NO viene en la API: es una columna derivada. La
# clasificacion de cada partido la fijo el titular en la sesion 2 (2026-07-06)
# con una TAXONOMIA DE 5 NIVELES:
#   izquierda / centroizquierda / centro / centroderecha / derecha.
# Llaves = Id de partido de la API (character), los 18 con militancia vigente en
# el roster del periodo 2026-2030. IND (Independientes) queda deliberadamente en
# NA_character_: no es un partido y sus militantes no son clasificables por este
# eje. El asistente NO altera estos valores por criterio propio (invariante 🔒).
MAPA_PARTIDO_TENDENCIA <- c(
  "PREP" = "derecha",          # Partido Republicano                  (28 diputados)
  "IND"  = NA_character_,       # Independientes: sin militancia, no clasificable (25)
  "FA"   = "izquierda",        # Frente Amplio                        (16)
  "PDG"  = "centro",           # Partido de la Gente                  (14)
  "UDI"  = "derecha",          # Union Democrata Independiente        (13)
  "RN"   = "centroderecha",    # Renovacion Nacional                  (11)
  "PS"   = "centroizquierda",  # Partido Socialista                   (10)
  "PC"   = "izquierda",        # Partido Comunista                     (8)
  "PNL"  = "derecha",          # Partido Nacional Libertario           (8)
  "DC"   = "centro",           # Partido Democrata Cristiano           (7)
  "PPD"  = "centroizquierda",  # Partido Por la Democracia             (4)
  "PSC"  = "derecha",          # Partido Social Cristiano              (3)
  "EVOP" = "centroderecha",    # Evolucion Politica                    (2)
  "PL"   = "centroizquierda",  # Partido Liberal de Chile              (2)
  "DEM"  = "centro",           # Partido Democratas Chile              (1)
  "FRVS" = "izquierda",        # Federacion Regionalista Verde Social  (1)
  "PAH"  = "izquierda",        # Partido Accion Humanista              (1)
  "PR"   = "centroizquierda"   # Partido Radical de Chile              (1)
)

# Helper: traduce un Id de partido a su tendencia declarada (NA si no mapeado).
tendencia_de_partido <- function(partido_id) {
  partido_id <- as.character(partido_id)
  res <- unname(MAPA_PARTIDO_TENDENCIA[partido_id])
  res[is.na(match(partido_id, names(MAPA_PARTIDO_TENDENCIA)))] <- NA_character_
  res
}

# ---- Rutas de salida JSON (lo que consume el dashboard estatico) ------------
ruta_json          <- function(...) ruta_salidas("json", ...)
ruta_json_perfiles <- function(...) ruta_salidas("json", "perfiles", ...)
