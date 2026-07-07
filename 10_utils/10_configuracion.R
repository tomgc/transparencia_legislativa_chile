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

# ---- Topes de extraccion para la corrida de validacion (Fase 1) -------------
# La corrida completa de un anno implica cientos de llamadas de detalle
# (una por votacion, una por mocion). Para PROBAR LA ARQUITECTURA extremo a
# extremo en tiempo acotado, se topa el numero de detalles procesados. Poner
# en Inf para procesar el anno COMPLETO (produccion). Decision metodologica
# declarada como constante (POLITICA 5.3.10), reportada en el traspaso.
MAX_SESIONES_DETALLE   <- Inf   # asistencia por sesion (calls baratas: ~61/anno)
MAX_VOTACIONES_DETALLE <- 120L  # detalle de voto nominal por votacion
MAX_PROYECTOS_DETALLE  <- 150L  # detalle de autores por mocion (origen Camara)

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

# ---- Mapeo partido -> tendencia (izquierda / derecha) -----------------------
# DECISION METODOLOGICA DEL TITULAR, NO DEL ASISTENTE.
# El eje izquierda/derecha NO viene en la API. Se enumeran aqui los 18 partidos
# con militancia vigente en el roster real del periodo 2026-2030 (extraidos de
# retornarDiputadosPeriodoActual). Todos quedan en NA_character_: la
# clasificacion politica de cada partido es una decision del titular, no del
# asistente (el encargo lo instruye explicitamente: "no inventes la
# clasificacion de un partido: NA y reportalo").
#
# # REVISAR: el titular debe reemplazar NA_character_ por "izquierda" /
# "derecha" / "centro" (u otra taxonomia que decida) en cada partido que
# corresponda. Los partidos que queden en NA se reportaran como tendencia
# desconocida en el JSON. La llave es el Id de partido de la API (character).
MAPA_PARTIDO_TENDENCIA <- c(
  "PREP" = NA_character_,  # Partido Republicano                  (28 diputados)
  "IND"  = NA_character_,  # Independientes                       (25)
  "FA"   = NA_character_,  # Frente Amplio                        (16)
  "PDG"  = NA_character_,  # Partido de la Gente                  (14)
  "UDI"  = NA_character_,  # Union Democrata Independiente        (13)
  "RN"   = NA_character_,  # Renovacion Nacional                  (11)
  "PS"   = NA_character_,  # Partido Socialista                   (10)
  "PC"   = NA_character_,  # Partido Comunista                     (8)
  "PNL"  = NA_character_,  # Partido Nacional Libertario           (8)
  "DC"   = NA_character_,  # Partido Democrata Cristiano           (7)
  "PPD"  = NA_character_,  # Partido Por la Democracia             (4)
  "PSC"  = NA_character_,  # Partido Social Cristiano              (3)
  "EVOP" = NA_character_,  # Evolucion Politica                    (2)
  "PL"   = NA_character_,  # Partido Liberal de Chile              (2)
  "DEM"  = NA_character_,  # Partido Democratas Chile              (1)
  "FRVS" = NA_character_,  # Federacion Regionalista Verde Social  (1)
  "PAH"  = NA_character_,  # Partido Accion Humanista              (1)
  "PR"   = NA_character_   # Partido Radical de Chile              (1)
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
