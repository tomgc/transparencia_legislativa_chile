# =============================================================================
# 36_extraer_detalle_proyectos.R
# -----------------------------------------------------------------------------
# Proposito: Bajar el CONTENIDO de cada proyecto (titulo, tipo de iniciativa,
#            materias) para los boletines que el pipeline necesita hacer
#            legibles/trazables: los AUTORADOS (proyectos.rds) y los VOTADOS
#            (boletines no nulos en votos.rds). Un solo intermedio de detalle
#            sirve a los dos bloques del perfil en 39.
#
#            DECISION DE DISENO (ver log 20260709_contenido_legible_log.md):
#            el detalle se obtiene por CADA boletin ya presente en los
#            intermedios CONGELADOS del anno (proyectos.rds / votos.rds), NO
#            re-descargando la lista de mociones (que crece dia a dia). Asi el
#            snapshot queda congelado (n_proyectos/n_votaciones intactos) y el
#            detalle (titulo/tipo/materias, estables entre dias) se puede bajar
#            hoy sin corromper conteos. Esto unifica lo que el encargo planteo
#            como Fase A (enriquecer autorados) y Fase B (detalle de votados).
#
# Insumos:   40_salidas/intermedios/proyectos.rds (autorados, boletin)
#            40_salidas/intermedios/votos.rds     (votados, boletin no nulo)
#            API Camara: WSLegislativo.asmx/retornarProyectoLey (por boletin).
#            Cache: 20_insumos/camara/AAAAMMDD_detalle_proyectos_<anio>.rds
# Salidas:   40_salidas/intermedios/proyectos_detalle.rds
#            (una fila por boletin: boletin, nombre, tipo_iniciativa,
#             n_materias, materias(list-col data.frame id,nombre)).
# Autor:     Claude Code (encargo contenido legible + trazabilidad, sesion explore)
# Creado:    2026-07-09
# =============================================================================

# ---- Cargar utilidades y configuracion --------------------------------------
source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
instalar_si_falta(c("httr", "xml2", "dplyr", "here", "fs"))
library(dplyr)

ROOT <- obtener_raiz_proyecto()
source(file.path(ROOT, "10_utils", "10_configuracion.R"))

# ---- Boletines a resolver: union de autorados + votados (congelados) --------
leer_intermedio <- function(nombre) {
  ruta <- ruta_salidas("intermedios", paste0(nombre, ".rds"))
  if (!file.exists(ruta))
    stop(sprintf("36_detalle: falta el intermedio '%s'. Corre el paso previo.", ruta))
  readRDS(ruta)
}
proyectos <- leer_intermedio("proyectos")
votos     <- leer_intermedio("votos")

boletines_autorados <- como_llave(unique(proyectos$boletin))
boletines_votados   <- como_llave(unique(votos$boletin))
boletines_autorados <- boletines_autorados[!is.na(boletines_autorados)]
boletines_votados   <- boletines_votados[!is.na(boletines_votados)]
boletines <- sort(unique(c(boletines_autorados, boletines_votados)))

log_msg(sprintf("Boletines a resolver: %d (autorados %d, votados %d, union %d).",
                length(boletines), length(boletines_autorados),
                length(boletines_votados), length(boletines)),
        origen = "36_detalle")

# ---- Descargar detalle por boletin (resiliente: warn, no stop) --------------
# tope = Inf: 36 NO aplica un cap propio a su descarga; procesa TODOS los
# boletines de la union congelada (autorados + votados) sin truncar. Inf
# codifica en la clave que este detalle es completo, consistente con el esquema
# _tope-inf de 33/34/35 en produccion (fix de la clave de cache). No se pasa
# MAX_PROYECTOS_DETALLE: 36 no lo aplica (procesa mas que los autorados), asi
# que decirlo en la clave seria mentir. # REVISAR: el CONJUNTO de boletines de
# 36 depende de los topes de 34/35 (via proyectos.rds/votos.rds); esa dependencia
# aguas-arriba ya queda codificada en LOS snapshots de 34/35, no en el de 36.
extraer_detalle <- function() {
  con_cache(sprintf("detalle_proyectos_%d", ANIO_PROCESO), function() {
    filas <- list()
    no_resueltos <- character()
    for (bol in boletines) {
      d <- tryCatch(
        descargar_xml_camara("WSLegislativo.asmx/retornarProyectoLey",
                             list(prmNumeroBoletin = bol)),
        error = function(e) e)
      if (inherits(d, "error")) {
        no_resueltos <- c(no_resueltos, bol)
        Sys.sleep(PAUSA_API_SEG); next
      }
      cont <- parsear_contenido_proyecto(d)
      # Un boletin que la API no reconoce devuelve un ProyectoLey sin Nombre:
      # se trata como no resuelto (no se fabrica contenido).
      if (is.na(cont$nombre)) {
        no_resueltos <- c(no_resueltos, bol)
        Sys.sleep(PAUSA_API_SEG); next
      }
      filas[[length(filas) + 1L]] <- tibble(
        boletin         = como_llave(bol),
        nombre          = cont$nombre,
        tipo_iniciativa = cont$tipo_iniciativa,
        n_materias      = nrow(cont$materias),
        materias        = list(cont$materias)  # list-col: data.frame(id, nombre)
      )
      Sys.sleep(PAUSA_API_SEG)
    }
    if (length(no_resueltos) > 0)
      log_msg(sprintf("Boletines NO resueltos por la API (%d): %s",
                      length(no_resueltos), paste(no_resueltos, collapse = ", ")),
              "WARN", "36_detalle")
    bind_rows(filas)
  }, tope = Inf, origen = "36_detalle")
}

detalle <- extraer_detalle()

# ---- Validacion de integridad (POLITICA 5.3.8) ------------------------------
if (nrow(detalle) > 0) {
  if (any(is.na(detalle$boletin)))
    stop("36_detalle: boletin NA en el detalle.")
  if (anyDuplicated(detalle$boletin) > 0)
    stop("36_detalle: boletin duplicado en el detalle.")
  if (!is.character(detalle$boletin))
    stop("36_detalle: boletin no es character (invariante de llave).")
}

# Cobertura sobre los votados (lo critico para la trazabilidad voto->proyecto).
resueltos_votados <- sum(boletines_votados %in% detalle$boletin)
resueltos_autorados <- sum(boletines_autorados %in% detalle$boletin)
con_materias <- sum(detalle$n_materias > 0)
log_msg(sprintf("Detalle resuelto: %d/%d boletines (autorados %d/%d, votados %d/%d).",
                nrow(detalle), length(boletines),
                resueltos_autorados, length(boletines_autorados),
                resueltos_votados, length(boletines_votados)),
        origen = "36_detalle")
log_msg(sprintf("Con >=1 materia: %d ; sin materias: %d (hueco de la fuente, no fabricado).",
                con_materias, nrow(detalle) - con_materias),
        origen = "36_detalle")
if (resueltos_votados < length(boletines_votados))
  log_msg(sprintf("Aviso: %d boletines votados sin detalle (quedaran con proyecto=null en 39).",
                  length(boletines_votados) - resueltos_votados), "WARN", "36_detalle")

# ---- Persistir (escritura atomica) ------------------------------------------
ruta_out <- ruta_salidas("intermedios", "proyectos_detalle.rds")
# Sello de procedencia: hash del cache crudo de detalle (fix sesion 8). El cache
# de 36 usa tope = Inf (procesa TODOS los boletines de la union, sin cap propio).
escribir_atomico(detalle, ruta_out, function(o, r) saveRDS(o, r),
                 hash_origen = hash_origen_de(
                   ruta_cache(sprintf("detalle_proyectos_%d", ANIO_PROCESO), Inf)))
log_msg(sprintf("Escrito: %s (%d boletines)", ruta_out, nrow(detalle)),
        origen = "36_detalle")
