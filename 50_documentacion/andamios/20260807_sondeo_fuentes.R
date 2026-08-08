# =============================================================================
# 20260807_sondeo_fuentes.R
# -----------------------------------------------------------------------------
# Proposito: SCRIPT REPRODUCTOR de la auditoria de fuentes (Camara, Senado y eje
#            tematico) del encargo
#            50_documentacion/andamios/50_encargo_auditoria_fuentes_camara_senado.md
#
#            SOLO LECTURA. No modifica ningun script del pipeline, ningun JSON
#            publicado ni nada bajo docs/. Todo lo que descarga va a
#            20_insumos/exploracion/20260807/ (directorio separado; 20_insumos/camara/
#            es dato crudo inmutable y NO se toca).
#
# Uso:       Rscript 50_documentacion/andamios/20260807_sondeo_fuentes.R [parte]
#            parte: "local" (default, sin red) | "camara" | "senado" | "todo"
#
# Autor:     Claude Code (encargo Ultracode auditoria de fuentes, sesion 16)
# Creado:    2026-08-07
# =============================================================================

suppressWarnings(suppressMessages({
  ROOT <- rprojroot::find_root(rprojroot::has_file(".here"))
  source(file.path(ROOT, "10_utils", "10_utils.R"))
  instalar_si_falta(c("httr", "xml2", "dplyr", "jsonlite", "fs", "tibble"))
  library(dplyr)
  source(file.path(ROOT, "10_utils", "10_configuracion.R"))
}))
options(width = 200)

FECHA_SONDEO <- "20260807"
DIR_EXPLORACION <- file.path(ROOT, "20_insumos", "exploracion", FECHA_SONDEO)
fs::dir_create(DIR_EXPLORACION)

parte <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(parte)) parte <- "local"

# =============================================================================
# PARTE 1 - MEDICION LOCAL DEL EJE TEMATICO (sin red)
# -----------------------------------------------------------------------------
# Define los denominadores reales de la cadena voto -> proyecto -> materia.
# Precede al sondeo de red porque es la que decide que vale la pena sondear.
# =============================================================================

titulo <- function(x) cat("\n", strrep("=", 78), "\n", x, "\n", strrep("=", 78), "\n", sep = "")
linea  <- function(...) cat(sprintf(...), "\n", sep = "")

medicion_local <- function() {
  titulo("PARTE 1 - MEDICION LOCAL DEL EJE TEMATICO")

  leer_int <- function(n) readRDS(file.path(ROOT, "40_salidas", "intermedios", paste0(n, ".rds")))
  proyectos <- leer_int("proyectos")
  detalle   <- leer_int("proyectos_detalle")
  votos     <- leer_int("votos")
  diputados <- leer_int("diputados")

  # --- 1.0 Procedencia: de que corte son los intermedios que sirven de universo
  sello_de <- function(o) { s <- attr(o, "sello"); if (is.null(s)) NA_character_ else s$corte_fecha }
  cortes <- c(proyectos = sello_de(proyectos), proyectos_detalle = sello_de(detalle),
              votos = sello_de(votos), diputados = sello_de(diputados))
  linea("1.0 CORTE_FECHA de 10_utils/10_configuracion.R : %s", CORTE_FECHA)
  linea("1.0 corte sellado en los intermedios locales   : %s",
        paste(sprintf("%s=%s", names(cortes), cortes), collapse = " | "))
  linea("1.0 ADVERTENCIA: si difieren, el universo local NO es el del corte publicado.")

  # --- 1.1 Universo de votos y el eslabon voto -> proyecto
  n_votos      <- nrow(votos)
  n_votaciones <- length(unique(votos$votacion_id))
  con_boletin  <- sum(!is.na(votos$boletin))
  sin_boletin  <- sum(is.na(votos$boletin))
  vot_con_bol  <- length(unique(votos$votacion_id[!is.na(votos$boletin)]))
  vot_sin_bol  <- length(unique(votos$votacion_id[is.na(votos$boletin)]))
  titulo("1.1 Eslabon voto -> proyecto (intermedio votos.rds)")
  linea("filas de voto (diputado x votacion)      : %d", n_votos)
  linea("votaciones distintas                     : %d", n_votaciones)
  linea("filas CON boletin                        : %d de %d (%.2f%%)", con_boletin, n_votos, 100*con_boletin/n_votos)
  linea("filas SIN boletin                        : %d de %d (%.2f%%)", sin_boletin, n_votos, 100*sin_boletin/n_votos)
  linea("votaciones CON boletin                   : %d de %d (%.2f%%)", vot_con_bol, n_votaciones, 100*vot_con_bol/n_votaciones)
  linea("votaciones SIN boletin                   : %d de %d (%.2f%%)", vot_sin_bol, n_votaciones, 100*vot_sin_bol/n_votaciones)

  # Que aspecto tienen las descripciones de las votaciones SIN boletin: la
  # hipotesis es que el boletin se extrae por regex del texto de Descripcion
  # (exploracion_api_camara.md, hallazgo 5) y que las que no lo traen en el texto
  # quedan sin proyecto. Se mide, no se supone.
  desc_sin <- unique(votos[is.na(votos$boletin), c("votacion_id", "descripcion", "tipo")])
  desc_con <- unique(votos[!is.na(votos$boletin), c("votacion_id", "descripcion", "tipo")])
  titulo("1.1b Descripcion y tipo de las votaciones SIN boletin")
  linea("votaciones distintas sin boletin: %d", nrow(desc_sin))
  cat("--- tabla de 'tipo' en votaciones SIN boletin ---\n"); print(sort(table(desc_sin$tipo), decreasing = TRUE))
  cat("--- tabla de 'tipo' en votaciones CON boletin ---\n"); print(sort(table(desc_con$tipo), decreasing = TRUE))
  cat("--- 25 descripciones distintas de votaciones SIN boletin (muestra ordenada por frecuencia) ---\n")
  print(utils::head(sort(table(desc_sin$descripcion), decreasing = TRUE), 25))
  # Cuantas de esas descripciones contienen la palabra 'olet' (Boletin) pese a
  # haber quedado sin boletin -> mediria un fallo del regex, no de la fuente.
  menciona_boletin <- sum(grepl("olet", desc_sin$descripcion, fixed = TRUE))
  linea("votaciones sin boletin cuya Descripcion menciona 'olet': %d de %d",
        menciona_boletin, nrow(desc_sin))

  # --- 1.2 Eslabon proyecto -> materia
  titulo("1.2 Eslabon proyecto -> materia (intermedio proyectos_detalle.rds)")
  bol_autorados <- unique(como_llave(proyectos$boletin)); bol_autorados <- bol_autorados[!is.na(bol_autorados)]
  bol_votados   <- unique(como_llave(votos$boletin));     bol_votados   <- bol_votados[!is.na(bol_votados)]
  bol_union     <- sort(unique(c(bol_autorados, bol_votados)))
  linea("boletines autorados (proyectos.rds)      : %d", length(bol_autorados))
  linea("boletines votados (votos.rds)            : %d", length(bol_votados))
  linea("union de boletines                       : %d", length(bol_union))
  linea("boletines con detalle resuelto           : %d de %d (%.2f%%)",
        nrow(detalle), length(bol_union), 100*nrow(detalle)/length(bol_union))
  con_mat <- sum(detalle$n_materias > 0)
  linea("boletines con >= 1 materia               : %d de %d resueltos (%.2f%%)",
        con_mat, nrow(detalle), 100*con_mat/nrow(detalle))
  linea("boletines con >= 1 materia               : %d de %d de la union (%.2f%%)",
        con_mat, length(bol_union), 100*con_mat/length(bol_union))

  # --- 1.3 Catalogo de materias derivado del universo persistido
  titulo("1.3 Catalogo de materias derivado (no de la muestra de andamios/)")
  mats <- dplyr::bind_rows(detalle$materias)
  if (nrow(mats) > 0) {
    linea("pares (boletin, materia) totales         : %d", nrow(mats))
    linea("materias distintas por Id                : %d", length(unique(mats$id)))
    linea("materias distintas por Nombre            : %d", length(unique(mats$nombre)))
    cat("--- 20 materias mas frecuentes ---\n")
    print(utils::head(sort(table(mats$nombre), decreasing = TRUE), 20))
    # Estabilidad del identificador: un Id que apunte a dos nombres distintos
    # rompe la llave. Se mide.
    dup <- mats |> dplyr::distinct(id, nombre) |> dplyr::count(id) |> dplyr::filter(n > 1)
    linea("ids de materia con MAS DE UN nombre      : %d (0 = identificador estable)", nrow(dup))
    if (nrow(dup) > 0) print(dup)
  } else {
    linea("SIN materias en el universo persistido.")
  }

  # --- 1.4 Cadena completa: voto -> proyecto -> materia
  titulo("1.4 CADENA COMPLETA voto -> proyecto -> materia")
  bol_con_materia <- detalle$boletin[detalle$n_materias > 0]
  votos_cadena <- sum(!is.na(votos$boletin) & votos$boletin %in% bol_con_materia)
  linea("filas de voto que cierran la cadena      : %d de %d (%.2f%%)",
        votos_cadena, n_votos, 100*votos_cadena/n_votos)
  vot_cadena <- length(unique(votos$votacion_id[!is.na(votos$boletin) & votos$boletin %in% bol_con_materia]))
  linea("votaciones que cierran la cadena         : %d de %d (%.2f%%)",
        vot_cadena, n_votaciones, 100*vot_cadena/n_votaciones)

  # --- 1.5 Eslabon autor -> padron de parlamentarios
  titulo("1.5 Eslabon autor -> padron (proyectos.rds vs diputados.rds)")
  autores <- unique(como_llave(proyectos$diputado_id)); autores <- autores[!is.na(autores)]
  padron  <- unique(como_llave(diputados$diputado_id))
  empalman <- sum(autores %in% padron)
  linea("autores distintos en proyectos.rds       : %d", length(autores))
  linea("padron de diputados.rds                  : %d", length(padron))
  linea("autores que empalman con el padron       : %d de %d (%.2f%%)",
        empalman, length(autores), 100*empalman/length(autores))
  if (empalman < length(autores))
    linea("autores SIN empalme                      : %s", paste(setdiff(autores, padron), collapse = ", "))
  linea("filas autor-proyecto                     : %d", nrow(proyectos))
  linea("rol declarado (dominio observado)        : %s", paste(unique(proyectos$rol), collapse = ", "))
  linea("orden declarado (dominio observado)      : %s", paste(sort(unique(proyectos$orden)), collapse = ", "))

  # --- 1.6 Tramitacion / estado en el universo persistido
  titulo("1.6 Eslabon proyecto -> tramitacion / estado")
  linea("columnas de proyectos.rds                : %s", paste(names(proyectos), collapse = ", "))
  linea("columnas de proyectos_detalle.rds        : %s", paste(names(detalle), collapse = ", "))
  linea("unica senal de estado disponible         : 'admisible' (dominio: %s)",
        paste(names(table(proyectos$admisible)), collapse = ", "))
  print(table(proyectos$admisible, useNA = "ifany"))

  # --- 1.7 Recuento de las cifras del PR del bot sobre el JSON PUBLICADO
  titulo("1.7 Recuento de 65478 / 30919 sobre el JSON publicado (no heredado)")
  pdir <- file.path(ROOT, "40_salidas", "json", "perfiles")
  files <- list.files(pdir, pattern = "[.]json$", full.names = TRUE)
  tot_vot <- 0L; tot_moc <- 0L; con_proy <- 0L; sin_proy <- 0L
  for (f in files) {
    p <- jsonlite::fromJSON(f, simplifyVector = FALSE)
    tot_vot <- tot_vot + as.integer(p$votaciones$n_votaciones %||% 0L)
    tot_moc <- tot_moc + as.integer(p$proyectos$n_proyectos %||% 0L)
    for (v in p$votaciones$votos) if (is.null(v$proyecto)) sin_proy <- sin_proy + 1L else con_proy <- con_proy + 1L
  }
  linea("perfiles                                 : %d", length(files))
  linea("votaciones (suma de n_votaciones)        : %d", tot_vot)
  linea("mociones (suma de n_proyectos)           : %d", tot_moc)
  linea("votos_con_proyecto                       : %d de %d (%.2f%%)", con_proy, con_proy+sin_proy, 100*con_proy/(con_proy+sin_proy))
  linea("votos_sin_proyecto                       : %d de %d (%.2f%%)", sin_proy, con_proy+sin_proy, 100*sin_proy/(con_proy+sin_proy))
  linea("NOTA: el JSON publicado es del corte %s; los intermedios locales, del corte sellado de 1.0.",
        CORTE_FECHA)

  invisible(TRUE)
}

if (parte %in% c("local", "todo")) medicion_local()

# =============================================================================
# CLIENTE HTTP CON CACHE PARA EL SONDEO (amabilidad con las APIs publicas)
# -----------------------------------------------------------------------------
# El pipeline usa descargar_xml_camara() de 10_utils, que reintenta y parsea pero
# NO persiste el crudo. Aqui hace falta persistir para que el catalogo sea
# re-derivable, y ademas hay que hablar con un backend JSON (el del Senado) que
# ese cliente no cubre. Un solo punto de salida a la red, con cache en disco:
# si el archivo ya existe, NO se vuelve a descargar.
# =============================================================================

PAUSA_SONDEO <- 0.3

# Un status != 200 NO se persiste: cachear una pagina de error como si fuera la
# respuesta convierte un fallo transitorio del servicio en un dato falso que
# sobrevive a todas las corridas siguientes. Se registra en el manifiesto y se
# devuelve NA, para que quien lea distinga "no existe" de "no respondio hoy".
MANIFIESTO <- file.path(DIR_EXPLORACION, "_sf_manifiesto_llamadas.csv")

bajar <- function(url, destino, query = list()) {
  ruta <- file.path(DIR_EXPLORACION, destino)
  if (file.exists(ruta)) return(invisible(ruta))
  r <- tryCatch(
    httr::GET(url, query = query, httr::timeout(60),
              httr::user_agent("transparencia_legislativa_chile (R; auditoria de fuentes, datos publicos)")),
    error = function(e) e)
  registrar <- function(status, nota) {
    fila <- data.frame(url = url, destino = destino, status = status, nota = nota,
                       stringsAsFactors = FALSE)
    utils::write.table(fila, MANIFIESTO, sep = ",", row.names = FALSE,
                       col.names = !file.exists(MANIFIESTO), append = file.exists(MANIFIESTO))
  }
  if (inherits(r, "error")) {
    registrar(NA_integer_, conditionMessage(r))
    log_msg(sprintf("FALLO de red en %s (%s)", destino, conditionMessage(r)), "WARN", "sondeo")
    return(invisible(NA_character_))
  }
  st <- httr::status_code(r)
  registrar(st, if (st == 200L) "ok" else "no persistido")
  Sys.sleep(PAUSA_SONDEO)
  if (st != 200L) {
    log_msg(sprintf("HTTP %s en %s: NO se persiste la respuesta.", st, destino), "WARN", "sondeo")
    return(invisible(NA_character_))
  }
  writeBin(httr::content(r, as = "raw"), ruta)
  invisible(ruta)
}

leer_xml  <- function(destino) {
  ruta <- file.path(DIR_EXPLORACION, destino)
  if (!file.exists(ruta)) return(NULL)
  tryCatch(xml2::read_xml(ruta), error = function(e) NULL)
}
leer_json <- function(destino) {
  ruta <- file.path(DIR_EXPLORACION, destino)
  if (!file.exists(ruta)) return(NULL)
  tryCatch(jsonlite::fromJSON(ruta, simplifyVector = FALSE), error = function(e) NULL)
}

# =============================================================================
# PARTE 2 - SONDEO DE LA CAMARA
# -----------------------------------------------------------------------------
# El universo de operaciones sale del DESCRIPTOR de cada servicio, no de los
# scripts del proyecto ni de una lista recordada.
# NOTA OPERATIVA medida el 2026-08-07: el sufijo "?WSDL" en MAYUSCULAS devuelve
# HTTP 500; "?wsdl" en minusculas devuelve 200. No se dedujo, se observo.
# =============================================================================

BASE_WS     <- "https://opendata.camara.cl/camaradiputados/WServices/"
BASE_LEGADO <- "https://opendata.camara.cl/"

SERVICIOS <- c("WSSala", "WSDiputado", "WSLegislativo", "WSComision")

sondeo_camara <- function(anios_cohorte = c(2016, 2018, 2020, 2021, 2022, 2024, 2026),
                          n_por_cohorte = 5L) {
  titulo("PARTE 2 - SONDEO DE LA CAMARA")

  # --- 2.1 Universo de operaciones desde los descriptores --------------------
  for (s in SERVICIOS) {
    bajar(paste0(BASE_WS, s, ".asmx?wsdl"), sprintf("sf_wsdl_%s.xml", s))
    bajar(paste0(BASE_WS, s, ".asmx"),      sprintf("sf_ops_%s.html", s))
  }
  bajar(paste0(BASE_LEGADO, "wscamaradiputados.asmx?wsdl"), "sf_wsdl_wscamaradiputados.xml")
  bajar(paste0(BASE_LEGADO, "wscamaradiputados.asmx"),      "sf_ops_wscamaradiputados.html")
  # Control negativo: un nombre de servicio FABRICADO. Si su respuesta es identica
  # a la de un servicio "real", ese servicio no existe (catch-all del servidor).
  bajar(paste0(BASE_WS, "WSComunes.asmx"),          "sf_ops_WSComunes.html")
  bajar(paste0(BASE_WS, "WSNoExisteControl.asmx"),  "sf_ops_CONTROL_inexistente.html")

  # El universo sale del descriptor WSDL cuando el servicio lo entrega. Medido el
  # 2026-08-07: ?WSDL en MAYUSCULAS devuelve HTTP 500 y ?wsdl en minusculas
  # respondio 200 por la manana y 500 por la tarde, o sea el descriptor es
  # INTERMITENTE. Por eso hay una segunda via, la pagina .asmx del propio
  # servicio, que lista sus operaciones como enlaces ?op=. Se declara SIEMPRE de
  # cual de las dos salio cada fila: no son la misma autoridad.
  ops_de_wsdl <- function(archivo, servicio) {
    d <- leer_xml(archivo)
    if (is.null(d)) return(NULL)
    xml2::xml_ns_strip(d)
    nm <- unique(xml2::xml_attr(xml2::xml_find_all(d, "//portType/operation"), "name"))
    nm <- sort(nm[!is.na(nm)])
    if (length(nm) == 0) return(NULL)
    data.frame(servicio = servicio, operacion = nm, fuente = "WSDL", stringsAsFactors = FALSE)
  }
  ops_de_listado <- function(archivo, servicio) {
    ruta <- file.path(DIR_EXPLORACION, archivo)
    if (!file.exists(ruta)) return(NULL)
    h <- tryCatch(xml2::read_html(ruta), error = function(e) NULL)
    if (is.null(h)) return(NULL)
    href <- xml2::xml_attr(xml2::xml_find_all(h, "//a"), "href")
    href <- href[!is.na(href) & grepl("?op=", href, fixed = TRUE)]
    nm <- sort(unique(sub("^.*[?]op=", "", href)))
    if (length(nm) == 0) return(NULL)
    data.frame(servicio = servicio, operacion = nm, fuente = "listado .asmx",
               stringsAsFactors = FALSE)
  }
  por_servicio <- function(s, arch_wsdl, arch_ops) {
    w <- ops_de_wsdl(arch_wsdl, s)
    if (!is.null(w)) return(w)
    ops_de_listado(arch_ops, s)
  }
  universo <- dplyr::bind_rows(
    lapply(SERVICIOS, function(s)
      por_servicio(s, sprintf("sf_wsdl_%s.xml", s), sprintf("sf_ops_%s.html", s))),
    por_servicio("wscamaradiputados (legado)", "sf_wsdl_wscamaradiputados.xml",
                 "sf_ops_wscamaradiputados.html"))

  if (is.null(universo) || nrow(universo) == 0) {
    linea("2.1 NI el WSDL NI el listado .asmx respondieron: el universo NO se pudo derivar hoy.")
    linea("    Eso es 'el descriptor no respondio', NO 'el servicio no expone operaciones'.")
    universo <- data.frame(servicio = character(0), operacion = character(0), fuente = character(0))
  } else {
    linea("2.1 servicios con descriptor legible     : %d", length(unique(universo$servicio)))
    linea("2.1 OPERACIONES DEL DESCRIPTOR (universo): %d", nrow(universo))
    cat("--- reparto por servicio y fuente del dato ---\n")
    print(table(universo$servicio, universo$fuente))
  }

  # Semantica declarada por la fuente: la clave del veredicto sobre P2.
  meta <- lapply(c(sprintf("sf_wsdl_%s.xml", SERVICIOS), "sf_wsdl_wscamaradiputados.xml"), function(a) {
    d <- leer_xml(a); if (is.null(d)) return(NULL); xml2::xml_ns_strip(d)
    data.frame(archivo = a,
               documentation = length(xml2::xml_find_all(d, "//documentation")),
               simpleType    = length(xml2::xml_find_all(d, "//simpleType")),
               enumeration   = length(xml2::xml_find_all(d, "//enumeration")),
               complexType   = length(xml2::xml_find_all(d, "//complexType")),
               stringsAsFactors = FALSE)
  })
  meta <- dplyr::bind_rows(meta)
  cat("\n--- semantica declarada por los descriptores (insumo del veredicto P2) ---\n")
  if (nrow(meta) == 0) {
    linea("Ningun WSDL disponible en esta corrida (el servicio devolvio HTTP 500).")
    linea("NO se puede recontar aqui la semantica declarada. La medicion del 2026-08-07,")
    linea("con los 5 WSDL en mano, dio 0 documentation, 0 simpleType y 0 enumeration en los 5;")
    linea("re-correr este bloque cuando el descriptor vuelva a responder es lo que lo confirma.")
  } else {
    print(meta, row.names = FALSE)
    linea("Lectura para P2: 0 documentation + 0 simpleType + 0 enumeration significa que la")
    linea("fuente no declara NI UN dominio de codigos ni una sola glosa semantica.")
  }

  # Control negativo de existencia de servicio.
  md5_comunes <- unname(tools::md5sum(file.path(DIR_EXPLORACION, "sf_ops_WSComunes.html")))
  md5_control <- unname(tools::md5sum(file.path(DIR_EXPLORACION, "sf_ops_CONTROL_inexistente.html")))
  linea("\n2.1 WSComunes vs nombre fabricado de control: md5 %s -> WSComunes %s",
        if (identical(md5_comunes, md5_control)) "IDENTICO" else "distinto",
        if (identical(md5_comunes, md5_control)) "NO EXISTE (catch-all del servidor)" else "existe")

  # --- 2.2 Operaciones EN USO, extraidas de los scripts del pipeline ---------
  scripts <- list.files(file.path(ROOT, "30_procesamiento"), pattern = "[.]R$", full.names = TRUE)
  en_uso <- dplyr::bind_rows(lapply(scripts, function(f) {
    l <- readLines(f, warn = FALSE)
    i <- grep("descargar_xml_camara", l, fixed = TRUE)
    if (length(i) == 0) return(NULL)
    m <- regmatches(l[i], regexpr('"[A-Za-z]+\\.asmx/[A-Za-z]+"', l[i]))
    j <- i[nzchar(m)]; m <- m[nzchar(m)]
    if (length(m) == 0) return(NULL)
    data.frame(script = basename(f), linea = j, operacion = gsub('"', "", m),
               stringsAsFactors = FALSE)
  }))
  linea("\n2.2 OPERACIONES EN USO por el pipeline    : %d distintas, en %d lineas de %d scripts",
        length(unique(en_uso$operacion)), nrow(en_uso), length(unique(en_uso$script)))
  print(en_uso, row.names = FALSE)
  if (nrow(universo) > 0) {
    nombres_en_uso <- unique(sub("^.*/", "", en_uso$operacion))
    linea("2.2 EN USO presentes en el descriptor     : %d de %d",
          sum(nombres_en_uso %in% universo$operacion), length(nombres_en_uso))
    linea("2.2 NO USADAS                             : %d de %d del descriptor",
          sum(!universo$operacion %in% nombres_en_uso), nrow(universo))
  }

  # --- 2.3 Catalogo de materias ---------------------------------------------
  bajar(paste0(BASE_WS, "WSLegislativo.asmx/retornarMaterias"), "sf_retornarMaterias.xml")
  dm <- leer_xml("sf_retornarMaterias.xml")
  if (!is.null(dm)) {
    xml2::xml_ns_strip(dm)
    ms <- xml2::xml_find_all(dm, "//Materia")
    ids <- trimws(xml2::xml_text(xml2::xml_find_all(dm, "//Materia/Id")))
    nom <- trimws(xml2::xml_text(xml2::xml_find_all(dm, "//Materia/Nombre")))
    titulo("2.3 Catalogo de materias de la Camara (retornarMaterias)")
    linea("nodos Materia                            : %d", length(ms))
    linea("Id distintos                             : %d de %d", length(unique(ids)), length(ids))
    linea("Id que son enteros                       : %d de %d", sum(grepl("^[0-9]+$", ids)), length(ids))
    linea("rango de Id                              : %s - %s", min(as.integer(ids)), max(as.integer(ids)))
    linea("jerarquia (hijos distintos de Id/Nombre) : %d (0 = catalogo plano)",
          sum(!xml2::xml_name(xml2::xml_children(ms)) %in% c("Id", "Nombre")))
    linea("nombres vacios                           : %d de %d", sum(!nzchar(nom)), length(nom))
  }

  # --- 2.4 Cobertura de materias por cohorte anual ---------------------------
  # MUESTRA, no censo: n_por_cohorte boletines por anno, muestreados con semilla
  # fija sobre el universo REAL que devuelve retornarMocionesXAnno. El tamano y
  # el metodo se declaran porque la cifra es una estimacion, no un conteo.
  titulo(sprintf("2.4 Cobertura proyecto -> materia por cohorte (muestra de %d por anno)", n_por_cohorte))
  set.seed(20260807)
  filas <- list()
  for (a in anios_cohorte) {
    bajar(paste0(BASE_WS, "WSLegislativo.asmx/retornarMocionesXAnno"),
          sprintf("sf_mociones_%d.xml", a), list(prmAnno = a))
    d <- leer_xml(sprintf("sf_mociones_%d.xml", a))
    if (is.null(d)) next
    xml2::xml_ns_strip(d)
    bol <- trimws(xml2::xml_text(xml2::xml_find_all(d, "//ProyectoLey/NumeroBoletin")))
    bol <- bol[nzchar(bol)]
    if (length(bol) == 0) next
    muestra <- sample(bol, min(n_por_cohorte, length(bol)))
    con_mat <- 0L
    for (b in muestra) {
      nom <- sprintf("sf_pl_%s.xml", gsub("[^0-9A-Za-z]", "_", b))
      bajar(paste0(BASE_WS, "WSLegislativo.asmx/retornarProyectoLey"), nom,
            list(prmNumeroBoletin = b))
      dp <- leer_xml(nom)
      if (is.null(dp)) next
      xml2::xml_ns_strip(dp)
      if (length(xml2::xml_find_all(dp, "//Materias/Materia")) > 0) con_mat <- con_mat + 1L
    }
    filas[[length(filas) + 1L]] <- data.frame(
      anno = a, universo = length(bol), muestreados = length(muestra),
      con_materia = con_mat, pct = round(100 * con_mat / length(muestra), 1),
      stringsAsFactors = FALSE)
  }
  if (length(filas)) {
    coh <- dplyr::bind_rows(filas)
    print(coh, row.names = FALSE)
    linea("Lectura: si la cobertura cae a 0 en las cohortes recientes, el hueco de materias")
    linea("es una FRONTERA TEMPORAL DE INDEXACION de la fuente, no un fallo del pipeline.")
  }

  # --- 2.5 El eslabon voto -> proyecto, con el denominador correcto ----------
  titulo("2.5 Eslabon voto -> proyecto: el denominador manda")
  votos <- readRDS(file.path(ROOT, "40_salidas", "intermedios", "votos.rds"))
  vt <- unique(votos[, c("votacion_id", "tipo", "boletin")])
  tab <- table(tipo = vt$tipo, tiene_boletin = !is.na(vt$boletin))
  print(tab)
  pl <- vt[vt$tipo == "Proyecto de Ley", ]
  linea("\nvotaciones tipo 'Proyecto de Ley' CON boletin : %d de %d (%.2f%%)",
        sum(!is.na(pl$boletin)), nrow(pl), 100 * sum(!is.na(pl$boletin)) / nrow(pl))
  linea("votaciones NO 'Proyecto de Ley' CON boletin   : %d de %d",
        sum(!is.na(vt$boletin[vt$tipo != "Proyecto de Ley"])), sum(vt$tipo != "Proyecto de Ley"))
  linea("Lectura: si la primera es 100%% y la segunda 0, el regex del 34 no falla:")
  linea("las votaciones sin boletin son instrumentos sin boletin posible.")

  invisible(TRUE)
}

if (parte %in% c("camara", "todo")) sondeo_camara()

# =============================================================================
# PARTE 3 - SONDEO DEL SENADO
# -----------------------------------------------------------------------------
# El backend del Senado NO tiene descriptor (openapi.json / swagger.json / docs
# devuelven 404), asi que su universo de operaciones NO es enumerable: toda ruta
# que no responde se registra como "probada y no existe con ese nombre", nunca
# como "el servicio no lo expone".
# =============================================================================

BASE_SENADO <- "https://web-back.senado.cl/api/"
BASE_SIL    <- "https://tramitacion.senado.cl/wspublico/"

# El %||% de 10_utils/10_utils.R evalua is.na(a), que falla sobre una lista de
# mas de un elemento. Las respuestas del backend del Senado vienen anidadas en
# un sobre {data:{total,data}}, asi que aqui hace falta una version que solo
# mire nulidad y largo. No se toca el helper del pipeline (invariante de solo
# lectura): se define uno local.
`%|%` <- function(a, b) if (is.null(a) || length(a) == 0) b else a
# El sobre NO es uniforme entre rutas del mismo backend: /parlamentarios,
# /legislatures y /sessions anidan las filas en data$data, mientras
# /sessions/attendance las anida en data$DATA y sube al nivel de data los
# metadatos de la sesion (TOTAL_SENADORES, ID_SESION, FECHA_HORA_INICIO...).
# Medido el 2026-08-07; no se dedujo de la forma de una sola respuesta.
filas_de <- function(o) o$data$DATA %|% o$data$data %|% o$data %|% list()

sondeo_senado <- function(n_boletines_sil = 20L) {
  titulo("PARTE 3 - SONDEO DEL SENADO")

  # --- 3.1 Padron ------------------------------------------------------------
  bajar(paste0(BASE_SENADO, "parlamentarios"), "sf_senado_padron_vigente.json",
        list(vigentes = 1, limit = 300))
  p <- leer_json("sf_senado_padron_vigente.json")
  if (is.null(p)) { linea("3.1 sin respuesta del padron; se detiene la rama del Senado."); return(invisible(FALSE)) }
  filas <- filas_de(p)
  camara <- vapply(filas, function(x) as.character(x$CAMARA %|% NA), character(1))
  ids    <- vapply(filas, function(x) as.character(x$ID_PARLAMENTARIO %|% NA), character(1))
  circ   <- vapply(filas, function(x) as.character(x$CIRCUNSCRIPCION_ID %|% NA), character(1))
  titulo("3.1 Padron del Senado (fuente confiable del periodo vigente)")
  linea("filas devueltas (ambas camaras)          : %d", length(filas))
  linea("senadores (CAMARA == 'S')                : %d", sum(camara == "S", na.rm = TRUE))
  linea("ids distintos entre los senadores        : %d de %d",
        length(unique(ids[camara == "S"])), sum(camara == "S", na.rm = TRUE))
  linea("circunscripciones distintas              : %d (deben sumar 50 escanos)",
        length(unique(circ[camara == "S"])))
  linea("NOTA: senadores_vigentes.php NO se usa como padron (invariante del encargo):")
  bajar(paste0(BASE_SIL, "senadores_vigentes.php"), "sf_senado_wspublico_vigentes.xml")
  dsv <- leer_xml("sf_senado_wspublico_vigentes.xml")
  if (!is.null(dsv))
    linea("      senadores_vigentes.php devuelve %d nodos //senador (padron congelado, no vigente)",
          length(xml2::xml_find_all(dsv, "//senador")))

  # --- 3.2 Legislatura vigente, DERIVADA por fecha, no hardcodeada ------------
  bajar(paste0(BASE_SENADO, "legislatures"), "sf_senado_legislaturas.json", list(limit = 100))
  L <- leer_json("sf_senado_legislaturas.json")
  legs <- filas_de(L)
  parse_fecha <- function(x) as.Date(substr(as.character(x), 1, 10),
                                     tryFormats = c("%d/%m/%Y", "%Y-%m-%d"))
  hoy <- Sys.Date()
  vig <- NULL
  for (l in legs) {
    ini <- suppressWarnings(parse_fecha(l$INICIO)); fin <- suppressWarnings(parse_fecha(l$TERMINO))
    if (!is.na(ini) && !is.na(fin) && hoy >= ini && hoy <= fin) { vig <- l; break }
  }
  titulo("3.2 Legislatura vigente (derivada por fecha)")
  linea("legislaturas en el catalogo              : %d", length(legs))
  if (is.null(vig)) { linea("NO se pudo derivar la legislatura vigente; se detiene."); return(invisible(FALSE)) }
  id_leg <- as.character(vig$ID_LEGISLATURA)
  linea("legislatura vigente                      : ID %s, NUMERO %s, %s a %s",
        id_leg, vig$NUMERO, vig$INICIO, vig$TERMINO)

  # --- 3.3 Catalogo de sesiones y panel nominal de asistencia (D2) -----------
  bajar(paste0(BASE_SENADO, "sessions"), sprintf("sf_senado_sesiones_%s.json", id_leg),
        list(id_legislatura = id_leg, limit = 500))
  S <- leer_json(sprintf("sf_senado_sesiones_%s.json", id_leg))
  ses <- filas_de(S)
  ids_ses <- vapply(ses, function(x) as.character(x$ID_SESION %|% NA), character(1))
  titulo("3.3 Asistencia NOMINAL por sesion: la prueba de D2")
  linea("sesiones de la legislatura vigente       : %d", length(ids_ses))

  panel <- list()
  for (s in ids_ses) {
    nom <- sprintf("sf_senado_asistencia_sesion_%s.json", s)
    bajar(paste0(BASE_SENADO, "sessions/attendance"), nom, list(id_sesion = s))
    A <- leer_json(nom)
    fa <- filas_de(A)
    if (is.null(fa) || length(fa) == 0) next
    panel[[length(panel) + 1L]] <- data.frame(
      id_sesion = s,
      id_parlamentario = vapply(fa, function(x) as.character(x$ID_PARLAMENTARIO %|% NA), character(1)),
      asistencia = vapply(fa, function(x) as.character(x$ASISTENCIA %|% NA), character(1)),
      justificacion = vapply(fa, function(x) as.character(x$JUSTIFICACION %|% NA), character(1)),
      stringsAsFactors = FALSE)
  }
  if (length(panel)) {
    P <- dplyr::bind_rows(panel)
    linea("filas nominales del panel                : %d", nrow(P))
    linea("pares (sesion, parlamentario) distintos  : %d de %d (llave compuesta unica si coinciden)",
          nrow(unique(P[, c("id_sesion", "id_parlamentario")])), nrow(P))
    linea("filas por sesion (valores observados)    : %s",
          paste(sort(unique(table(P$id_sesion))), collapse = ", "))
    cat("--- dominio de ASISTENCIA ---\n"); print(table(P$asistencia, useNA = "ifany"))
    linea("filas con justificacion no vacia         : %d de %d",
          sum(nzchar(P$justificacion) & !is.na(P$justificacion)), nrow(P))
    # Sesiones centinela: 0 asistentes. "Sin dato" es indistinguible de
    # "inasistencia universal" salvo por esta regla de deteccion.
    cero <- names(which(tapply(P$asistencia, P$id_sesion, function(x) sum(x == "Asiste") == 0)))
    linea("sesiones con CERO asistentes (centinela) : %d de %d -> %s",
          length(cero), length(unique(P$id_sesion)), paste(cero, collapse = ", "))
    # Compuerta de verificacion: el agregado oficial debe declarar
    # TOTAL_SESIONES == sesiones del catalogo - sesiones centinela.
    bajar(paste0(BASE_SENADO, "sessions/attendance"),
          sprintf("sf_senado_asistencia_agregado_%s.json", id_leg), list(id_legislatura = id_leg))
    G <- leer_json(sprintf("sf_senado_asistencia_agregado_%s.json", id_leg))
    ga <- filas_de(G)
    if (!is.null(ga) && length(ga) > 0) {
      tot <- unique(vapply(ga, function(x) as.character(x$TOTAL_SESIONES %|% NA), character(1)))
      linea("TOTAL_SESIONES del agregado oficial      : %s", paste(tot, collapse = ", "))
      linea("catalogo (%d) - centinelas (%d) = %d  -> %s el agregado",
            length(ids_ses), length(cero), length(ids_ses) - length(cero),
            if (any(tot == as.character(length(ids_ses) - length(cero)))) "CUADRA con" else "NO cuadra con")
    }
  }

  # --- 3.4 El SIL: la via bicameral del eje tematico -------------------------
  # tramitacion.senado.cl esta alojado en dominio del Senado pero es BICAMERAL:
  # resuelve boletines de la Camara. Es la unica fuente medida de tramitacion
  # fechada, que la API de la Camara no expone.
  titulo(sprintf("3.4 SIL bicameral (muestra de %d boletines reales de la Camara)", n_boletines_sil))
  det <- readRDS(file.path(ROOT, "40_salidas", "intermedios", "proyectos_detalle.rds"))
  set.seed(20260807)
  bols <- sample(det$boletin, min(n_boletines_sil, nrow(det)))
  ok <- 0L; con_tramites <- 0L; con_materia <- 0L; n_tram <- integer(0)
  for (b in bols) {
    num <- sub("-.*$", "", b)  # el SIL toma el boletin SIN el sufijo de comision
    nom <- sprintf("sf_sil_tram_%s.xml", num)
    bajar(paste0(BASE_SIL, "tramitacion.php"), nom, list(boletin = num))
    d <- leer_xml(nom)
    if (is.null(d)) next
    if (length(xml2::xml_find_all(d, "//boletin")) == 0) next
    ok <- ok + 1L
    t <- length(xml2::xml_find_all(d, "//tramite"))
    n_tram <- c(n_tram, t)
    if (t > 0) con_tramites <- con_tramites + 1L
    if (length(xml2::xml_find_all(d, "//materias/materia")) > 0) con_materia <- con_materia + 1L
  }
  linea("boletines de la CAMARA que el SIL resuelve : %d de %d", ok, length(bols))
  linea("con al menos un tramite fechado            : %d de %d", con_tramites, ok)
  if (length(n_tram)) linea("tramites por proyecto (mediana / maximo)   : %d / %d",
                            as.integer(stats::median(n_tram)), max(n_tram))
  linea("con al menos una materia                   : %d de %d", con_materia, ok)
  linea("Lectura: si el SIL resuelve boletines de la Camara, el eje tematico puede")
  linea("ser bicameral sobre la llave boletin, aunque cada backend por separado no lo sea.")

  invisible(TRUE)
}

if (parte %in% c("senado", "todo")) sondeo_senado()
