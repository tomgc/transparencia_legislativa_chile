# =============================================================================
# 39_consolidar_json.R
# -----------------------------------------------------------------------------
# Proposito: Fusionar las tablas intermedias (diputados, asistencia, votos,
#            proyectos) en los JSON estaticos que consume el dashboard:
#              - 40_salidas/json/indice_diputados.json  (selector, con metricas
#                resumen por diputado: tasa_asistencia, n_proyectos, n_votaciones;
#                y sexo/partido_nombre para que el cliente no fabrique ni
#                embeba a mano lo que ya viene en la fuente)
#              - 40_salidas/json/perfiles/<id>.json      (uno por diputado)
#            Claves ordenadas, indentacion fija, UTF-8 (POLITICA 2, 5.5).
#            Publica ademas una copia en docs/data/ para GitHub Pages (Fase 2).
# Insumos:   40_salidas/intermedios/{diputados,asistencia,votos,proyectos,
#            proyectos_detalle,asistencia_nominal,asistencia_ambitos}.rds
#            (los dos ultimos, Capa 3: serie nominal de asistencia y agregados
#            por ambito temporal; se AGREGAN al bloque de asistencia sin tocar
#            los campos legacy que el portal consume hoy)
# Salidas:   40_salidas/json/ (indice + perfiles/, canonico) y docs/data/
#            (indice + perfiles/, publicacion; copia fiel de 40_salidas/json/).
# Validacion: NAs en llaves, totales pre/post join, rango de tasa, dominio de
#            sentido del voto (POLITICA 5.3.8).
# Autor:     Claude Code (encargo autonomo, sesion 1; metricas resumen +
#            publicacion docs/data, sesion 3; sexo + partido_nombre en el
#            indice, sesion 3 continuacion)
# Creado:    2026-07-06
# =============================================================================

source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
instalar_si_falta(c("dplyr", "jsonlite", "here", "fs"))
library(dplyr)

ROOT <- obtener_raiz_proyecto()
source(file.path(ROOT, "10_utils", "10_configuracion.R"))

# ---- Cargar intermedios CON validacion de procedencia (fix sesion 8) ---------
# Cada intermedio debe traer sello (leer_sellado) y todos deben declarar el
# CORTE_FECHA vigente (validar_corte). Falla ruidosa ANTES de cualquier join o
# escritura si un .rds no corresponde al corte publicado (Bug 1 del traspaso v07):
# evita que un residuo de otra corrida se consolide en silencio.
sellos_intermedios <- list()
leer <- function(nombre) {
  ruta <- ruta_salidas("intermedios", paste0(nombre, ".rds"))
  ls <- leer_sellado(ruta)  # stop() diagnostico si falta el archivo o el sello
  sellos_intermedios[[basename(ruta)]] <<- ls$sello
  ls$objeto
}
diputados  <- leer("diputados")
asistencia <- leer("asistencia")
votos      <- leer("votos")
proyectos  <- leer("proyectos")
# Detalle de contenido por boletin (tipo_iniciativa, materias) del paso 36.
# Habilita: proyectos legibles (materias) y trazabilidad voto->proyecto.
proyectos_detalle <- leer("proyectos_detalle")
# Capa 3 (sesion 11): serie nominal de asistencia y agregados por ambito. No
# reemplazan a `asistencia` (el agregado legacy sigue alimentando los campos
# que el portal consume hoy); se AGREGAN.
asistencia_nominal <- leer("asistencia_nominal")
asistencia_ambitos <- leer("asistencia_ambitos")

# Compuerta de procedencia: los cinco intermedios deben pertenecer al corte
# vigente y ser coherentes entre si. stop() diagnostico si no. Va ANTES del
# stopifnot de character y de todo join/escritura.
validar_corte(sellos_intermedios, CORTE_FECHA)
log_msg(sprintf("Procedencia validada: %d intermedios al corte %s.",
                length(sellos_intermedios), CORTE_FECHA),
        origen = "39_consolidar")

# La llave es character en todas las tablas (invariante POLITICA 5.3.6).
stopifnot(is.character(diputados$diputado_id),
          is.character(asistencia$diputado_id),
          is.character(votos$diputado_id),
          is.character(proyectos$diputado_id),
          is.character(proyectos_detalle$boletin),
          is.character(asistencia_nominal$diputado_id),
          is.character(asistencia_nominal$sesion_id),
          is.character(asistencia_ambitos$diputado_id))

# ---- Lookup de contenido por boletin (O(1) por llave) -----------------------
# det_map[[boletin]] -> list(boletin, nombre, tipo_iniciativa, materias(df)).
# NULL si el boletin no tiene detalle resuelto o es NA (voto sin boletin).
det_map <- lapply(seq_len(nrow(proyectos_detalle)), function(i) list(
  boletin         = proyectos_detalle$boletin[i],
  nombre          = proyectos_detalle$nombre[i],
  tipo_iniciativa = proyectos_detalle$tipo_iniciativa[i],
  materias        = proyectos_detalle$materias[[i]]
))
names(det_map) <- proyectos_detalle$boletin
detalle_de <- function(bol) if (is.na(bol)) NULL else det_map[[bol]]
MATERIAS_VACIO <- data.frame(id = character(0), nombre = character(0),
                             stringsAsFactors = FALSE)

# ---- Capa 3: lookups de asistencia nominal (O(1) por diputado) --------------
# El alcance temporal viaja como atributo del intermedio (lo fija el 33 con la
# fecha de instalacion que publica la API), no se re-deriva aqui.
ALCANCE <- attr(asistencia_ambitos, "alcance")
if (is.null(ALCANCE))
  stop("39_consolidar: asistencia_ambitos.rds no trae el atributo 'alcance'. Regenera el paso 33.",
       call. = FALSE)

# Nota legible: impide leer el acumulado como carrera completa. Es texto, no
# dato derivado; se construye con los valores reales del alcance.
NOTA_ALCANCE <- sprintf(
  paste0("Cobertura parcial: solo sesiones de sala del anno %d hasta el %s ",
         "(%d sesiones, de %s a %s). NO es la trayectoria completa del ",
         "parlamentario. El ambito 'periodo_vigente' cuenta las %d sesiones ",
         "desde la instalacion del periodo %s (%s) y usa el mismo denominador ",
         "para todos, por lo que es el comparable entre diputados; ",
         "'en_ejercicio' cuenta solo las sesiones del alcance posteriores a la ",
         "asuncion de cada diputado."),
  ALCANCE$anio_proceso, ALCANCE$corte_fecha, ALCANCE$sesiones_alcance,
  ALCANCE$fecha_primera, ALCANCE$fecha_ultima, ALCANCE$sesiones_periodo_vigente,
  ALCANCE$periodo_nombre, ALCANCE$periodo_inicio)

BLOQUE_ALCANCE <- list(
  anio_proceso             = ALCANCE$anio_proceso,
  corte_fecha              = ALCANCE$corte_fecha,
  sesiones_alcance         = ALCANCE$sesiones_alcance,
  fecha_primera            = ALCANCE$fecha_primera,
  fecha_ultima             = ALCANCE$fecha_ultima,
  periodo_id               = ALCANCE$periodo_id,
  periodo_nombre           = ALCANCE$periodo_nombre,
  periodo_inicio           = ALCANCE$periodo_inicio,
  sesiones_periodo_vigente = ALCANCE$sesiones_periodo_vigente,
  nota                     = NOTA_ALCANCE
)

# Conteos + tasas de un ambito, en el orden fijo del contrato.
bloque_ambito <- function(fila) {
  if (nrow(fila) != 1) return(NULL)
  list(
    n_sesiones       = fila$n_sesiones,
    n_asiste         = fila$n_asiste,
    n_no_asiste      = fila$n_no_asiste,
    # Sesiones del ambito en que la fuente no registra fila para el diputado.
    # No se imputa asistencia ni inasistencia (POLITICA: nunca fabricar dato).
    n_sin_registro   = fila$n_sin_registro,
    n_justificadas   = fila$n_justificadas,
    n_injustificadas = fila$n_injustificadas,
    # Ambas tasas comparten denominador (n_sesiones). Ninguna usa las rebajas.
    tasa_presencia               = fila$tasa_presencia,
    tasa_presencia_o_justificada = fila$tasa_presencia_o_justificada
  )
}
amb_map <- split(asistencia_ambitos, asistencia_ambitos$diputado_id)
serie_map <- split(asistencia_nominal, asistencia_nominal$diputado_id)

roster_ids <- diputados$diputado_id
log_msg(sprintf("Roster vigente: %d diputados.", length(roster_ids)),
        origen = "39_consolidar")

# ---- Escritor JSON canonico (claves ordenadas, indentacion fija, UTF-8) -----
escribir_json <- function(objeto, ruta) {
  txt <- jsonlite::toJSON(objeto, auto_unbox = TRUE, pretty = TRUE,
                          na = "null", null = "null", digits = NA)
  escribir_atomico(txt, ruta, function(o, r)
    writeLines(enc2utf8(as.character(o)), r, useBytes = TRUE))
}

# ---- Validacion de cobertura de cada fuente sobre el roster -----------------
cobertura <- function(tabla, etiqueta) {
  ids <- intersect(unique(tabla$diputado_id), roster_ids)
  huerfanos <- setdiff(unique(tabla$diputado_id), roster_ids)
  log_msg(sprintf("%s: %d/%d del roster con datos; %d ids fuera del roster (periodo previo/reemplazos).",
                  etiqueta, length(ids), length(roster_ids), length(huerfanos)),
          origen = "39_consolidar")
  invisible(NULL)
}
cobertura(asistencia, "Asistencia")
cobertura(asistencia_nominal, "Asistencia nominal")
cobertura(votos,      "Votaciones")
cobertura(proyectos,  "Proyectos")

# ---- Metricas resumen por diputado (para el indice) --------------------------
# left_join sobre el roster (nunca inner_join): un diputado sin votos/proyectos
# debe quedar con 0, no desaparecer del indice. tasa_asistencia queda NA si el
# diputado no tiene fila en asistencia (mismo criterio que el bloque de perfil).
resumen_asistencia <- asistencia |>
  select(diputado_id, tasa_asistencia)

# Capa 3: tasa de presencia del PERIODO VIGENTE (denominador comun a los 155,
# por eso comparable entre diputados). Se AGREGA al indice; no reemplaza a
# tasa_asistencia, cuyo denominador es el historico del propio diputado.
resumen_presencia <- asistencia_ambitos |>
  filter(ambito == "periodo_vigente") |>
  select(diputado_id, tasa_presencia)

resumen_votos <- votos |>
  summarise(n_votaciones = n(), .by = diputado_id)

resumen_proyectos <- proyectos |>
  summarise(n_proyectos = n(), .by = diputado_id)

# ---- indice_diputados.json (lista minima para el selector, con metricas) ----
indice <- diputados |>
  left_join(resumen_asistencia, by = "diputado_id") |>
  left_join(resumen_votos,      by = "diputado_id") |>
  left_join(resumen_proyectos,  by = "diputado_id") |>
  left_join(resumen_presencia,  by = "diputado_id") |>
  mutate(
    n_votaciones = coalesce(n_votaciones, 0L),
    n_proyectos  = coalesce(n_proyectos, 0L)
  ) |>
  arrange(nombre) |>
  transmute(
    id              = diputado_id,
    nombre          = nombre,
    sexo            = sexo,
    partido         = partido_id,
    partido_nombre  = partido_nombre,
    distrito        = distrito,
    region          = region,
    tendencia       = tendencia,
    tasa_asistencia = tasa_asistencia,
    n_proyectos     = n_proyectos,
    n_votaciones    = n_votaciones,
    # Capa 3, campo NUEVO al final: no altera el orden que el cliente ya usa.
    tasa_presencia  = tasa_presencia
  )

fs::dir_create(ruta_json())
escribir_json(indice, ruta_json("indice_diputados.json"))
log_msg(sprintf("Escrito indice con %d diputados.", nrow(indice)),
        origen = "39_consolidar")

# ---- Perfiles por diputado (4 bloques) --------------------------------------
fs::dir_create(ruta_json_perfiles())
# Limpiar perfiles previos para que el conteo sea idempotente (POLITICA 5.2.3).
antiguos <- fs::dir_ls(ruta_json_perfiles(), glob = "*.json", fail = FALSE)
if (length(antiguos) > 0) fs::file_delete(antiguos)

n_perfiles <- 0L
for (i in seq_len(nrow(diputados))) {
  d   <- diputados[i, ]
  did <- d$diputado_id

  # Bloque 1: perfil ----------------------------------------------------------
  perfil <- list(
    id               = did,
    nombre           = d$nombre,
    sexo             = d$sexo,
    fecha_nacimiento = d$fecha_nacimiento,
    partido = list(
      id     = d$partido_id,
      nombre = d$partido_nombre,
      alias  = d$partido_alias
    ),
    distrito  = d$distrito,
    region    = d$region,
    tendencia = d$tendencia
  )

  # Bloque 2: asistencia ------------------------------------------------------
  a <- asistencia[asistencia$diputado_id == did, ]
  bloque_asistencia <- if (nrow(a) == 1) {
    list(anio = ANIO_PROCESO,
         n_sesiones      = a$n_sesiones,
         n_asiste        = a$n_asiste,
         n_no_asiste     = a$n_no_asiste,
         tasa_asistencia = a$tasa_asistencia)
  } else {
    list(anio = ANIO_PROCESO, n_sesiones = 0L, n_asiste = 0L,
         n_no_asiste = 0L, tasa_asistencia = NA_real_)
  }

  # Capa 3: se AGREGA al bloque de asistencia, despues de los campos legacy
  # (que no cambian de nombre, formula ni valor). La serie es el espejo de
  # votaciones.votos[]: una entrada por sesion, ordenada por fecha.
  amb_d <- amb_map[[did]]
  bloque_asistencia$alcance_temporal <- BLOQUE_ALCANCE
  bloque_asistencia$periodo_vigente <- if (!is.null(amb_d))
    bloque_ambito(amb_d[amb_d$ambito == "periodo_vigente", ]) else NULL
  bloque_asistencia$en_ejercicio <- if (!is.null(amb_d))
    bloque_ambito(amb_d[amb_d$ambito == "en_ejercicio", ]) else NULL

  s <- serie_map[[did]]
  bloque_asistencia$sesiones <- if (!is.null(s) && nrow(s) > 0) {
    s_ord <- s |> arrange(fecha, sesion_id)
    lapply(seq_len(nrow(s_ord)), function(k) {
      cod <- s_ord$justificacion_codigo[k]
      # justificacion anidada solo si la fuente la trae; null si no (el ausente
      # sin justificar es un caso real y distinguible, no se fabrica glosa).
      just <- if (!is.na(cod)) list(
        codigo = cod,
        glosa  = s_ord$justificacion_glosa[k],
        # Dato de la fuente, sin uso en ninguna formula: su semantica
        # reglamentaria no esta documentada (P2 de la medicion). # REVISAR.
        rebaja_asistencia = identical(s_ord$rebaja_asistencia[k], "true"),
        rebaja_quorum     = identical(s_ord$rebaja_quorum[k], "true")
      ) else NULL
      list(
        sesion_id          = s_ord$sesion_id[k],
        sesion_numero      = s_ord$sesion_numero[k],
        fecha              = s_ord$fecha[k],
        tipo_sesion        = s_ord$tipo_sesion[k],
        en_periodo_vigente = s_ord$en_periodo_vigente[k],
        asistencia         = s_ord$asistencia[k],
        justificacion      = just
      )
    })
  } else NULL

  # Bloque 3: votaciones ------------------------------------------------------
  v <- votos[votos$diputado_id == did, ]
  resumen_voto <- as.list(table(factor(v$sentido, levels = unname(DOMINIO_VOTO))))
  detalle_voto <- if (nrow(v) > 0) {
    v_ord <- v |> arrange(fecha, votacion_id)
    lapply(seq_len(nrow(v_ord)), function(k) {
      bol <- v_ord$boletin[k]
      det <- detalle_de(bol)
      # proyecto anidado si el voto tiene boletin resuelto; null si no (los ~31%
      # estructurales: acuerdos/resoluciones/otros sin boletin, o no resuelto).
      proyecto <- if (!is.null(det)) list(
        boletin         = det$boletin,
        nombre          = det$nombre,
        tipo_iniciativa = det$tipo_iniciativa,
        materias        = det$materias
      ) else NULL
      list(
        votacion_id = v_ord$votacion_id[k],
        boletin     = bol,
        # tipo de la votacion (ya venia en votos.rds; hace legible por que un
        # voto no tiene proyecto: "Proyecto de Acuerdo"/"Otros" no tienen boletin).
        tipo        = v_ord$tipo[k],
        fecha       = v_ord$fecha[k],
        resultado   = v_ord$resultado[k],
        sentido     = v_ord$sentido[k],
        descripcion = v_ord$descripcion[k],
        proyecto    = proyecto
      )
    })
  } else NULL
  bloque_votaciones <- list(
    anio               = ANIO_PROCESO,
    n_votaciones       = nrow(v),
    resumen_por_sentido = resumen_voto,
    votos              = detalle_voto
  )

  # Bloque 4: proyectos -------------------------------------------------------
  p <- proyectos[proyectos$diputado_id == did, ]
  detalle_proy <- if (nrow(p) > 0) {
    p_ord <- p |> arrange(desc(fecha_ingreso), boletin)
    lapply(seq_len(nrow(p_ord)), function(k) {
      det <- detalle_de(p_ord$boletin[k])
      list(
        boletin         = p_ord$boletin[k],
        nombre          = p_ord$nombre[k],
        fecha_ingreso   = p_ord$fecha_ingreso[k],
        admisible       = p_ord$admisible[k],
        rol             = p_ord$rol[k],
        # Contenido del paso 36: tipo (Mocion/Mensaje) y materias (categoria
        # tematica). materias vacio -> [] explicito, nunca fabricado.
        tipo_iniciativa = if (!is.null(det)) det$tipo_iniciativa else NA_character_,
        materias        = if (!is.null(det)) det$materias else MATERIAS_VACIO
      )
    })
  } else NULL
  bloque_proyectos <- list(
    anio          = ANIO_PROCESO,
    n_proyectos   = nrow(p),
    # La API no expone estado de tramitacion (ver exploracion); Admisible es el
    # unico proxy disponible. # REVISAR.
    estado_tramitacion_disponible = FALSE,
    proyectos     = detalle_proy
  )

  perfil_json <- list(
    perfil      = perfil,
    asistencia  = bloque_asistencia,
    votaciones  = bloque_votaciones,
    proyectos   = bloque_proyectos,
    metadatos   = list(
      fuente          = "opendata.camara.cl",
      periodo         = "2026-2030",
      anio_proceso    = ANIO_PROCESO,
      generado        = format(Sys.time(), "%Y-%m-%dT%H:%M:%S")
    )
  )

  escribir_json(perfil_json, ruta_json_perfiles(paste0(did, ".json")))
  n_perfiles <- n_perfiles + 1L
}

# ---- Validacion final: indice vs perfiles (POLITICA 5.3.8, verificacion) ----
archivos_perfil <- fs::dir_ls(ruta_json_perfiles(), glob = "*.json")
log_msg(sprintf("Perfiles escritos: %d ; entradas en indice: %d",
                length(archivos_perfil), nrow(indice)), origen = "39_consolidar")
if (length(archivos_perfil) != nrow(indice))
  stop(sprintf("39_consolidar: DESAJUSTE indice (%d) vs perfiles (%d).",
               nrow(indice), length(archivos_perfil)))

log_msg("Consolidacion JSON completada.", origen = "39_consolidar")

# ---- Publicar copia en docs/data/ (GitHub Pages sirve desde /docs) ----------
# 40_salidas/json/ sigue siendo el output canonico; docs/data/ es su
# publicacion (copia fiel, hecha en R, nunca a mano). Idempotente: limpia
# docs/data/perfiles/ antes de copiar, igual que ya se hace con los perfiles
# canonicos.
ruta_docs_data <- function(...) file.path(ROOT, "docs", "data", ...)
fs::dir_create(ruta_docs_data("perfiles"))

antiguos_docs <- fs::dir_ls(ruta_docs_data("perfiles"), glob = "*.json", fail = FALSE)
if (length(antiguos_docs) > 0) fs::file_delete(antiguos_docs)

fs::file_copy(ruta_json("indice_diputados.json"),
              ruta_docs_data("indice_diputados.json"), overwrite = TRUE)
fs::file_copy(archivos_perfil, ruta_docs_data("perfiles"), overwrite = TRUE)

archivos_perfil_docs <- fs::dir_ls(ruta_docs_data("perfiles"), glob = "*.json")
log_msg(sprintf("Publicado en docs/data/: indice + %d perfiles.",
                length(archivos_perfil_docs)), origen = "39_consolidar")
if (length(archivos_perfil_docs) != nrow(indice))
  stop(sprintf("39_consolidar: DESAJUSTE docs/data perfiles (%d) vs indice (%d).",
               length(archivos_perfil_docs), nrow(indice)))
