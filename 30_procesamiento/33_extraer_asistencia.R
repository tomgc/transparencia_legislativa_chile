# =============================================================================
# 33_extraer_asistencia.R
# -----------------------------------------------------------------------------
# Proposito: Extraer la asistencia a sesiones de sala del anno de proceso en UNA
#            sola granularidad, la NOMINAL: una fila por (diputado x sesion) con
#            fecha, tipo de sesion y la JUSTIFICACION que la fuente entrega
#            (codigo, glosa y las dos rebajas), mas los agregados por los dos
#            ambitos temporales (periodo_vigente, en_ejercicio).
#            Simetria con 34_extraer_votaciones.R, que persiste el voto nominal
#            por votacion.
#            Hasta la sesion 14 convivia un segundo bloque LEGACY que agregaba
#            por diputado y hacia un barrido propio de la API. Se retiro en la
#            sesion 15 (P-48) una vez que el frontend migro a la Capa 3: era una
#            segunda descarga completa de la asistencia en cada refresh, pagada
#            para alimentar campos que ya no consumia nadie.
# Insumos:   API Camara: WSSala.asmx/retornarSesionesXAnno (lista de sesiones),
#            WSSala.asmx/retornarSesionAsistencia (detalle por sesion) y
#            WSLegislativo.asmx/retornarPeriodoLegislativoActual (fecha de
#            instalacion del periodo vigente; NO se hardcodea).
#            Cache: 20_insumos/camara/AAAAMMDD_asistencia_nominal_<anio>.rds
#                   20_insumos/camara/AAAAMMDD_periodo_legislativo.rds
# Salidas:   40_salidas/intermedios/asistencia_nominal.rds  (diputado x sesion)
#            40_salidas/intermedios/asistencia_ambitos.rds  (diputado x ambito)
# Autor:     Claude Code (encargo autonomo, sesion 1; Capa 3 nominal, sesion 11;
#            retiro del bloque legacy, sesion 15)
# Creado:    2026-07-06
# =============================================================================

source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
instalar_si_falta(c("httr", "xml2", "dplyr", "here", "fs"))
library(dplyr)

ROOT <- obtener_raiz_proyecto()
source(file.path(ROOT, "10_utils", "10_configuracion.R"))

# =============================================================================
# EXTRACCION NOMINAL (Capa 3)
# =============================================================================

# ---- Fecha de instalacion del periodo vigente (de la fuente, no hardcodeada) -
# La API publica el periodo legislativo vigente con su FechaInicio; se consulta
# una vez por corte y se cachea. NO se deriva de un supuesto ni se escribe a
# mano: el ambito "periodo vigente" depende de este dato y un valor inventado
# contaminaria el denominador comun de los 155.
obtener_inicio_periodo <- function() {
  pl <- con_cache("periodo_legislativo", function() {
    d <- descargar_xml_camara("WSLegislativo.asmx/retornarPeriodoLegislativoActual")
    raiz <- xml2::xml_root(d)
    list(id      = como_llave(texto_nodo(raiz, "./Id")),
         nombre  = texto_nodo(raiz, "./Nombre"),
         inicio  = substr(texto_nodo(raiz, "./FechaInicio") %||% NA_character_, 1, 10),
         termino = substr(texto_nodo(raiz, "./FechaTermino") %||% NA_character_, 1, 10))
  }, origen = "33_asistencia")
  if (is.na(pl$inicio) || !grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", pl$inicio))
    stop("33_asistencia: la API no entrego una FechaInicio valida del periodo vigente.",
         call. = FALSE)
  log_msg(sprintf("Periodo legislativo vigente: %s (id %s), instalado el %s.",
                  pl$nombre, pl$id, pl$inicio), origen = "33_asistencia")
  pl
}
periodo <- obtener_inicio_periodo()
PERIODO_INICIO <- periodo$inicio

# ---- Descargar la serie nominal (diputado x sesion, con justificacion) -------
# Clave de cache asistencia_nominal_<anio>: distinta de la del extractor legacy
# retirado en la sesion 15 (asistencia_long_<anio>), porque el esquema es otro.
# Los .rds de aquella clave siguen en 20_insumos/camara/ y no se borran: son
# captura cruda y la gobernanza del proyecto los trata como inmutables; solo
# dejaron de leerse.
# Universo DETERMINISTA: sesiones celebradas con FechaInicio <= CORTE_FECHA, de
# modo que el contenido es funcion pura del corte. El extractor legacy filtraba
# solo por Estado en el instante de la descarga y por eso no lo era (P6 de la
# medicion de la sesion 11).
extraer_asistencia_nominal <- function() {
  cache_key <- sprintf("asistencia_nominal_%d", ANIO_PROCESO)
  con_cache(cache_key, function() {
    doc_ses <- descargar_xml_camara("WSSala.asmx/retornarSesionesXAnno",
                                    list(prmAnno = ANIO_PROCESO))
    ses <- xml2::xml_find_all(doc_ses, "//Sesion")
    campo <- function(xp) vapply(ses, function(s) texto_nodo(s, xp), character(1))
    cat_ses <- tibble(
      sesion_id   = como_llave(campo("./Id")),
      numero      = campo("./Numero"),
      fecha       = substr(campo("./FechaInicio"), 1, 10),
      tipo_sesion = campo("./Tipo"),
      estado      = campo("./Estado")
    )
    universo <- cat_ses |>
      filter(!is.na(sesion_id), grepl("celebrad", estado, ignore.case = TRUE),
             !is.na(fecha), fecha <= CORTE_FECHA) |>
      arrange(fecha, sesion_id)
    log_msg(sprintf("Nominal: %d sesiones %d publicadas, %d celebradas con FechaInicio <= %s.",
                    nrow(cat_ses), ANIO_PROCESO, nrow(universo), CORTE_FECHA),
            origen = "33_asistencia")

    if (is.finite(MAX_SESIONES_DETALLE) && nrow(universo) > MAX_SESIONES_DETALLE) {
      log_msg(sprintf("Topando a %d sesiones (MAX_SESIONES_DETALLE).",
                      MAX_SESIONES_DETALLE), "WARN", "33_asistencia")
      universo <- universo[seq_len(MAX_SESIONES_DETALLE), ]
    }

    filas <- list()
    for (k in seq_len(nrow(universo))) {
      d <- descargar_xml_camara("WSSala.asmx/retornarSesionAsistencia",
                                list(prmSesionId = universo$sesion_id[k]))
      asis <- xml2::xml_find_all(d, "//Asistencia")
      if (length(asis) == 0) { Sys.sleep(PAUSA_API_SEG); next }
      filas[[length(filas) + 1L]] <- tibble(
        sesion_id   = universo$sesion_id[k],
        sesion_numero = universo$numero[k],
        fecha       = universo$fecha[k],
        tipo_sesion = universo$tipo_sesion[k],
        diputado_id = como_llave(vapply(asis, function(a)
          texto_nodo(a, "./Diputado/Id"), character(1))),
        tipo_valor  = vapply(asis, function(a)
          attr_nodo(a, "./TipoAsistencia", "Valor"), character(1)),
        tipo_glosa  = vapply(asis, function(a)
          texto_nodo(a, "./TipoAsistencia"), character(1)),
        # Justificacion: nodo OPCIONAL. Se conserva codigo Y glosa; la glosa
        # viene en el propio nodo, asi que no se depende de un catalogo que la
        # fuente no publica (P1 de la medicion).
        justificacion_codigo = como_llave(vapply(asis, function(a)
          attr_nodo(a, "./Justificacion", "Valor"), character(1))),
        justificacion_glosa  = vapply(asis, function(a)
          texto_nodo(a, "./Justificacion/Nombre"), character(1)),
        # Se PERSISTEN como dato, pero NO entran en ninguna formula: la fuente
        # no documenta su semantica reglamentaria (P2 de la medicion).
        rebaja_asistencia = vapply(asis, function(a)
          texto_nodo(a, "./Justificacion/RebajaAsistencia"), character(1)),
        rebaja_quorum     = vapply(asis, function(a)
          texto_nodo(a, "./Justificacion/RebajaQuorum"), character(1))
      )
      Sys.sleep(PAUSA_API_SEG)
    }
    bind_rows(filas)
  }, tope = MAX_SESIONES_DETALLE, origen = "33_asistencia")
}

nominal <- extraer_asistencia_nominal()
# Las glosas vienen con tildes: bajo un locale C los bytes llegan bien pero sin
# marcar, y el enc2utf8() del 39 los reinterpretaria (A36). Marcarlo aqui es
# no-op bajo un locale UTF-8. La comprobacion que discrimina es nchar() vs
# bytes, no validUTF8() (que devuelve TRUE para bytes latin1 mal marcados).
for (col in c("tipo_glosa", "justificacion_glosa", "tipo_sesion"))
  Encoding(nominal[[col]]) <- "UTF-8"

log_msg(sprintf("Nominal: %d filas, %d sesiones, %d ids distintos.",
                nrow(nominal), length(unique(nominal$sesion_id)),
                length(unique(nominal$diputado_id))), origen = "33_asistencia")

# ---- Validaciones de dominio -------------------------------------------------
fuera <- setdiff(sort(unique(nominal$tipo_valor)), names(DOMINIO_ASISTENCIA))
if (length(fuera) > 0)
  log_msg(sprintf("Aviso: TipoAsistencia fuera del dominio conocido: %s",
                  paste(fuera, collapse = ", ")), "WARN", "33_asistencia")

# NO hay DOMINIO_JUSTIFICACION cerrado: la fuente no publica catalogo y los
# codigos observados tienen huecos (P1). Se avisa con warning() informativo si
# aparece un codigo fuera del conjunto observado en la medicion del 2026-07-25,
# y se CONTINUA: un codigo nuevo es informacion, no un fallo del pipeline.
CODIGOS_JUSTIFICACION_OBSERVADOS <- c("12","13","14","15","16","17","18","19",
                                      "21","23","25","28","29")
nuevos <- setdiff(sort(unique(na.omit(nominal$justificacion_codigo))),
                  CODIGOS_JUSTIFICACION_OBSERVADOS)
if (length(nuevos) > 0) {
  glosas <- vapply(nuevos, function(cc)
    nominal$justificacion_glosa[match(cc, nominal$justificacion_codigo)], character(1))
  warning(sprintf(paste0("33_asistencia: codigos de justificacion no vistos en la ",
                         "medicion del 2026-07-25 (no es un error; la fuente no ",
                         "publica catalogo): %s"),
                  paste(sprintf("%s='%s'", nuevos, glosas), collapse = "; ")),
          call. = FALSE)
  log_msg(sprintf("Codigos de justificacion nuevos: %s", paste(nuevos, collapse = ", ")),
          "WARN", "33_asistencia")
}

# ---- Universos temporales ----------------------------------------------------
# Dos ambitos, ambos acotados por el alcance del pipeline (ANIO_PROCESO y
# CORTE_FECHA):
#   periodo_vigente: sesiones desde la instalacion del periodo hasta el corte.
#                    Denominador COMUN a los 155 -> comparable entre diputados.
#   en_ejercicio:    por diputado, las sesiones del alcance desde su primer
#                    registro (los que entran en marzo o reemplazan a otro no
#                    cargan con sesiones anteriores a su asuncion).
sesiones <- nominal |>
  distinct(sesion_id, fecha, tipo_sesion, sesion_numero) |>
  arrange(fecha, sesion_id) |>
  mutate(en_periodo_vigente = fecha >= PERIODO_INICIO)
log_msg(sprintf("Universos: alcance %d sesiones (%s .. %s); periodo vigente %d sesiones (desde %s).",
                nrow(sesiones), min(sesiones$fecha), max(sesiones$fecha),
                sum(sesiones$en_periodo_vigente), PERIODO_INICIO),
        origen = "33_asistencia")

# El roster viene del paso 32 (run_all lo corre antes). leer_sellado da un
# stop() diagnostico si falta o no trae sello, en vez de un error cripitico.
roster <- leer_sellado(ruta_salidas("intermedios", "diputados.rds"))$objeto
roster_ids <- roster$diputado_id
stopifnot(is.character(roster_ids))

# Serie completa por diputado del roster: una entrada por sesion de SU universo
# en_ejercicio, incluidas aquellas en que la fuente no registra fila. Ese caso
# existe (medicion: hay diputados sin fila en alguna sesion en que ya estaban en
# el cargo) y se marca "sin_registro"; NUNCA se imputa asistencia ni inasistencia.
serie_por_diputado <- function(did) {
  propio <- nominal[nominal$diputado_id == did, ]
  if (nrow(propio) == 0) return(NULL)
  primera <- min(propio$fecha)
  univ <- sesiones[sesiones$fecha >= primera, ]
  m <- match(univ$sesion_id, propio$sesion_id)
  tibble(
    diputado_id        = did,
    sesion_id          = univ$sesion_id,
    sesion_numero      = univ$sesion_numero,
    fecha              = univ$fecha,
    tipo_sesion        = univ$tipo_sesion,
    en_periodo_vigente = univ$en_periodo_vigente,
    asistencia = ifelse(is.na(m), "sin_registro",
                        unname(DOMINIO_ASISTENCIA[propio$tipo_valor[m]])),
    justificacion_codigo = propio$justificacion_codigo[m],
    justificacion_glosa  = propio$justificacion_glosa[m],
    rebaja_asistencia    = propio$rebaja_asistencia[m],
    rebaja_quorum        = propio$rebaja_quorum[m]
  )
}
serie <- bind_rows(lapply(roster_ids, serie_por_diputado))
for (col in c("tipo_sesion", "justificacion_glosa")) Encoding(serie[[col]]) <- "UTF-8"

# ---- Agregados por ambito ----------------------------------------------------
# Las dos tasas COMPARTEN denominador (n_sesiones del ambito). No se construye
# ninguna tasa con denominador reducido: descontar sesiones del denominador
# exigiria la regla reglamentaria que la fuente no documenta (P2).
# rebaja_asistencia / rebaja_quorum NO participan de ninguna formula.
agregar_ambito <- function(df, etiqueta) {
  df |>
    summarise(
      n_sesiones      = n(),
      n_asiste        = sum(asistencia == "asiste"),
      n_no_asiste     = sum(asistencia == "no_asiste"),
      n_sin_registro  = sum(asistencia == "sin_registro"),
      n_justificadas   = sum(asistencia == "no_asiste" & !is.na(justificacion_codigo)),
      n_injustificadas = sum(asistencia == "no_asiste" &  is.na(justificacion_codigo)),
      .by = diputado_id
    ) |>
    mutate(
      ambito = etiqueta,
      tasa_presencia = ifelse(n_sesiones > 0, n_asiste / n_sesiones, NA_real_),
      tasa_presencia_o_justificada = ifelse(n_sesiones > 0,
                                            (n_asiste + n_justificadas) / n_sesiones,
                                            NA_real_)
    ) |>
    select(diputado_id, ambito, n_sesiones, n_asiste, n_no_asiste, n_sin_registro,
           n_justificadas, n_injustificadas, tasa_presencia,
           tasa_presencia_o_justificada)
}

# periodo_vigente: universo COMUN. Se arma sobre el catalogo de sesiones del
# periodo para los 155, no sobre las filas presentes: asi el denominador es
# identico para todos (una sesion sin fila cuenta como sin_registro, no se cae).
serie_pv <- expand.grid(diputado_id = roster_ids,
                        sesion_id = sesiones$sesion_id[sesiones$en_periodo_vigente],
                        stringsAsFactors = FALSE) |>
  as_tibble() |>
  left_join(serie |> select(diputado_id, sesion_id, asistencia, justificacion_codigo),
            by = c("diputado_id", "sesion_id")) |>
  mutate(asistencia = coalesce(asistencia, "sin_registro"))

ambitos <- bind_rows(
  agregar_ambito(serie_pv, "periodo_vigente"),
  agregar_ambito(serie,    "en_ejercicio")
)

# ---- Validacion de integridad -----------------------------------------------
falla <- function(cond, msg) if (isTRUE(cond)) stop(paste("33_asistencia:", msg), call. = FALSE)
falla(nrow(ambitos) != 2L * length(roster_ids),
      sprintf("se esperaban %d filas de ambito (155 x 2), hay %d.",
              2L * length(roster_ids), nrow(ambitos)))
falla(any(with(ambitos, n_asiste + n_no_asiste + n_sin_registro != n_sesiones)),
      "n_asiste + n_no_asiste + n_sin_registro != n_sesiones en algun ambito.")
falla(any(with(ambitos, n_justificadas + n_injustificadas != n_no_asiste)),
      "n_justificadas + n_injustificadas != n_no_asiste en algun ambito.")
falla(any(is.na(ambitos$tasa_presencia)) || any(is.na(ambitos$tasa_presencia_o_justificada)),
      "hay tasas NA.")
falla(any(ambitos$tasa_presencia < 0 | ambitos$tasa_presencia > 1) ||
      any(ambitos$tasa_presencia_o_justificada < 0 | ambitos$tasa_presencia_o_justificada > 1),
      "hay tasas fuera de [0,1].")
den_pv <- unique(ambitos$n_sesiones[ambitos$ambito == "periodo_vigente"])
falla(length(den_pv) != 1L,
      sprintf("el denominador del periodo vigente NO es comun a los 155: %s.",
              paste(den_pv, collapse = ", ")))
falla(den_pv != sum(sesiones$en_periodo_vigente),
      "el denominador del periodo vigente no coincide con el catalogo de sesiones.")
log_msg(sprintf("Ambitos OK: denominador comun del periodo vigente = %d; en_ejercicio entre %d y %d.",
                den_pv, min(ambitos$n_sesiones[ambitos$ambito == "en_ejercicio"]),
                max(ambitos$n_sesiones[ambitos$ambito == "en_ejercicio"])),
        origen = "33_asistencia")

# ---- Persistir ---------------------------------------------------------------
hash_nominal <- hash_origen_de(
  ruta_cache(sprintf("asistencia_nominal_%d", ANIO_PROCESO), MAX_SESIONES_DETALLE))
ruta_serie <- ruta_salidas("intermedios", "asistencia_nominal.rds")
escribir_atomico(serie, ruta_serie, function(o, r) saveRDS(o, r), hash_origen = hash_nominal)
log_msg(sprintf("Escrito: %s (%d filas)", ruta_serie, nrow(serie)), origen = "33_asistencia")

# El 39 necesita describir el alcance temporal sin re-consultar la fuente ni
# re-derivarlo: viaja como atributo del intermedio, junto al sello.
attr(ambitos, "alcance") <- list(
  anio_proceso     = ANIO_PROCESO,
  corte_fecha      = CORTE_FECHA,
  periodo_id       = periodo$id,
  periodo_nombre   = periodo$nombre,
  periodo_inicio   = periodo$inicio,
  periodo_termino  = periodo$termino,
  sesiones_alcance = nrow(sesiones),
  sesiones_periodo_vigente = sum(sesiones$en_periodo_vigente),
  fecha_primera    = min(sesiones$fecha),
  fecha_ultima     = max(sesiones$fecha)
)
ruta_amb <- ruta_salidas("intermedios", "asistencia_ambitos.rds")
escribir_atomico(ambitos, ruta_amb, function(o, r) saveRDS(o, r), hash_origen = hash_nominal)
log_msg(sprintf("Escrito: %s (%d filas)", ruta_amb, nrow(ambitos)), origen = "33_asistencia")
