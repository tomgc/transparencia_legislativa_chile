# ---------------------------------------------------------------------------
# ANDAMIO DE MEDICION (no es etapa del pipeline).
# Capa 2 / territorio: mide que entrega la fuente territorial (BCN, SERVEL) y
# que tan cruzable es por nombre contra los 155 diputados del indice publicado.
# NO escribe crosswalk. NO toca 20_insumos/, 40_salidas/ ni docs/ (solo lectura).
# Uso: Rscript 50_documentacion/andamios/medir_fuente_territorio.R <fase>
#   fase 1 = estado local; fase 2 = sondeo BCN; fase 3 = cruzabilidad
# ---------------------------------------------------------------------------

RAIZ <- "/Users/tomgc/Projects/transparencia_legislativa_chile"
DIR_MUESTRAS <- file.path(RAIZ, "50_documentacion", "andamios", "muestras")

suppressPackageStartupMessages({
  library(jsonlite)
  library(httr)
  library(xml2)
  library(stringi)
})

escribir_atomico <- function(contenido, ruta) {
  tmp <- paste0(ruta, ".tmp")
  writeBin(contenido, tmp)
  file.rename(tmp, ruta)
  invisible(ruta)
}

# --- normalizacion SOLO para medir el cruce (no es produccion) --------------
normalizar_nombre <- function(x) {
  y <- stri_trans_general(x, "Latin-ASCII")
  y <- tolower(y)
  y <- gsub("[^a-z ]", " ", y)
  y <- gsub("\\s+", " ", y)
  trimws(y)
}

# clave insensible al orden: tokens ordenados alfabeticamente
clave_tokens <- function(x) {
  vapply(strsplit(normalizar_nombre(x), " "), function(t) {
    t <- t[nchar(t) > 1]                 # descarta iniciales sueltas
    paste(sort(t), collapse = " ")
  }, character(1))
}

# =========================== FASE 1 ========================================
fase_1 <- function() {
  cat("=== FASE 1: estado local ===\n")

  ruta_idx <- file.path(RAIZ, "docs", "data", "indice_diputados.json")
  idx <- fromJSON(ruta_idx, simplifyDataFrame = TRUE)
  cat("indice: n =", nrow(idx), "\n")
  cat("indice: class(id) =", class(idx$id), "\n")
  cat("indice: columnas =", paste(names(idx), collapse = ", "), "\n")
  cat("indice: distrito no-NA =", sum(!is.na(idx$distrito)), "\n")
  cat("indice: region   no-NA =", sum(!is.na(idx$region)), "\n")
  cat("indice: ids unicos =", length(unique(idx$id)), "\n")

  ruta_rds <- file.path(RAIZ, "40_salidas", "intermedios", "diputados.rds")
  dip <- readRDS(ruta_rds)
  cat("\nrds: n =", nrow(dip), "\n")
  cat("rds: columnas =", paste(names(dip), collapse = ", "), "\n")
  cat("rds: class(diputado_id) =", class(dip$diputado_id), "\n")
  cat("rds: distrito no-NA =", sum(!is.na(dip$distrito)), "\n")
  cat("rds: region   no-NA =", sum(!is.na(dip$region)), "\n")

  nombres <- sort(idx$nombre)
  cat("\nprimeros 5 nombres:\n"); print(head(nombres, 5))
  saveRDS(idx, file.path(DIR_MUESTRAS, "medicion_indice_155.rds"))
  cat("\nguardado: medicion_indice_155.rds\n")
}

# =========================== FASE 2 ========================================
# Sondeo BCN. datos.bcn.cl expone un endpoint SPARQL. La ontologia de BCN
# modela al parlamentario y su periodo; el distrito puede venir como literal
# del cargo. Se prueban consultas de descubrimiento antes de asumir predicado.

SPARQL_BCN <- "https://datos.bcn.cl/sparql"

consulta_sparql <- function(query, endpoint = SPARQL_BCN, formato = "application/sparql-results+json") {
  r <- tryCatch(
    GET(endpoint,
        query = list(query = query, output = "json"),
        add_headers(Accept = formato, `User-Agent` = "transparencia-legislativa-chile/medicion"),
        timeout(60)),
    error = function(e) e
  )
  if (inherits(r, "error")) { cat("ERROR de red:", conditionMessage(r), "\n"); return(NULL) }
  cat("HTTP", status_code(r), "| content-type:", headers(r)[["content-type"]], "\n")
  content(r, as = "text", encoding = "UTF-8")
}

fase_2 <- function() {
  cat("=== FASE 2: sondeo BCN ===\n")

  # 2.1 - vida del endpoint
  cat("\n-- 2.1 endpoint vivo --\n")
  q0 <- "SELECT ?s WHERE { ?s ?p ?o } LIMIT 1"
  print(substr(consulta_sparql(q0), 1, 400))

  # 2.2 - un scan sin cota revienta (Virtuoso, timeout 60s). Se acota por grafo.
  cat("\n-- 2.2 grafos nombrados --\n")
  q1 <- "SELECT DISTINCT ?g WHERE { GRAPH ?g { ?s ?p ?o } } LIMIT 50"
  txt <- consulta_sparql(q1)
  cat(substr(txt, 1, 4000), "\n")
  if (!is.null(txt)) escribir_atomico(charToRaw(txt),
    file.path(DIR_MUESTRAS, "bcn_grafos.json"))

  # 2.3 - buscar el recurso de un diputado conocido por su label
  cat("\n-- 2.3 recurso por label (Alvaro Carter) --\n")
  q2 <- paste0(
    "SELECT ?s ?l WHERE { ?s <http://www.w3.org/2000/01/rdf-schema#label> ?l . ",
    "FILTER(CONTAINS(STR(?l), 'Carter')) } LIMIT 20")
  txt2 <- consulta_sparql(q2)
  cat(substr(txt2, 1, 4000), "\n")
  if (!is.null(txt2)) escribir_atomico(charToRaw(txt2),
    file.path(DIR_MUESTRAS, "bcn_label_carter.json"))
}

# 2.4 - volcar todas las tripletas de un recurso (descubrir el esquema real)
fase_2_recurso <- function(uri) {
  cat("=== FASE 2b: tripletas de", uri, "===\n")
  q <- paste0("SELECT ?p ?o WHERE { <", uri, "> ?p ?o } LIMIT 200")
  txt <- consulta_sparql(q)
  cat(txt, "\n")
}

# 2.5 - consulta libre desde linea de comandos
fase_q <- function(q) cat(consulta_sparql(q), "\n")

# --- parseo de sparql-results+json a data.frame (todo character) ------------
sparql_df <- function(txt) {
  if (is.null(txt)) return(NULL)
  j <- fromJSON(txt, simplifyVector = FALSE)
  b <- j$results$bindings
  if (!length(b)) return(data.frame())
  vars <- unlist(j$head$vars)
  out <- lapply(vars, function(v)
    vapply(b, function(x) if (is.null(x[[v]])) NA_character_ else as.character(x[[v]]$value),
           character(1)))
  names(out) <- vars
  as.data.frame(out, stringsAsFactors = FALSE)
}

BIO <- "http://datos.bcn.cl/ontologies/bcn-biographies#"

# =========================== FASE 3 ========================================
# Medicion decisiva: cobertura de distrito por diputado, cruzando por el id de
# la Camara que BCN expone (idCamaraDeDiputados), NO por nombre.
fase_3 <- function() {
  cat("=== FASE 3: cobertura y cruzabilidad ===\n")

  idx <- fromJSON(file.path(RAIZ, "docs", "data", "indice_diputados.json"),
                  simplifyDataFrame = TRUE)
  idx$id <- as.character(idx$id)

  # 3.1 - universo BCN con id de Camara
  cat("\n-- 3.1 personas BCN con idCamaraDeDiputados --\n")
  q_ids <- paste0(
    "SELECT ?persona ?idcam ?label WHERE { ",
    "?persona <", BIO, "idCamaraDeDiputados> ?idcam . ",
    "OPTIONAL { ?persona <http://www.w3.org/2004/02/skos/core#prefLabel> ?label } }")
  txt_ids <- consulta_sparql(q_ids)
  d_ids <- sparql_df(txt_ids)
  cat("filas:", nrow(d_ids), "| ids unicos:", length(unique(d_ids$idcam)), "\n")
  if (!is.null(txt_ids)) escribir_atomico(charToRaw(txt_ids),
    file.path(DIR_MUESTRAS, "bcn_id_camara.json"))

  # 3.2 - cargos con territorio (representing) por persona con id de Camara
  cat("\n-- 3.2 cargos con 'representing' --\n")
  q_terr <- paste0(
    "SELECT ?persona ?idcam ?cargo ?terr ?ini ?fin WHERE { ",
    "?persona <", BIO, "idCamaraDeDiputados> ?idcam . ",
    "?persona <", BIO, "hasParliamentaryAppointment> ?cargo . ",
    "?cargo <", BIO, "representing> ?terr . ",
    "OPTIONAL { ?cargo <", BIO, "hasBeginning> ?bi . ?bi <", BIO, "date> ?ini } ",
    "OPTIONAL { ?cargo <", BIO, "hasEnd> ?be . ?be <", BIO, "date> ?fin } }")
  txt_t <- consulta_sparql(q_terr)
  d_t <- sparql_df(txt_t)
  cat("filas:", nrow(d_t), "\n")
  if (!is.null(txt_t)) escribir_atomico(charToRaw(txt_t),
    file.path(DIR_MUESTRAS, "bcn_territorio_por_cargo.json"))

  if (nrow(d_t)) {
    d_t$idcam <- as.character(d_t$idcam)
    d_t$distrito <- sub(".*/[Dd]istrito", "", d_t$terr)
    es_dist <- grepl("distrito", d_t$terr, ignore.case = TRUE)
    cat("cargos de distrito:", sum(es_dist),
        "| de circunscripcion (senado):", sum(!es_dist), "\n")

    en_idx <- d_t$idcam %in% idx$id
    cat("\nCOBERTURA: ids del indice (155) con al menos un cargo territorial en BCN:",
        length(unique(d_t$idcam[en_idx & es_dist])), "de 155\n")
    faltan <- setdiff(idx$id, unique(d_t$idcam[en_idx & es_dist]))
    cat("sin territorio:", length(faltan), "\n")
    if (length(faltan)) print(idx[idx$id %in% faltan, c("id", "nombre", "partido")])

    # multiplicidad: mas de un distrito por id => ambiguedad de periodo
    por_id <- tapply(d_t$distrito[en_idx & es_dist], d_t$idcam[en_idx & es_dist],
                     function(x) length(unique(x)))
    cat("\nids con >1 distrito distinto (exigen desambiguar periodo):",
        sum(por_id > 1), "\n")
    if (any(por_id > 1)) {
      amb <- names(por_id)[por_id > 1]
      for (a in amb) {
        sub <- d_t[d_t$idcam == a & es_dist, ]
        cat("  id", a, "-", idx$nombre[match(a, idx$id)], ":",
            paste(sprintf("d%s[%s..%s]", sub$distrito, substr(sub$ini,1,10),
                          substr(sub$fin,1,10)), collapse = " "), "\n")
      }
    }
    saveRDS(d_t, file.path(DIR_MUESTRAS, "medicion_bcn_territorio.rds"))
  }

  # 3.3 - contraste de la llave alternativa (nombre), por si el id fallara
  cat("\n-- 3.3 cruzabilidad por nombre (llave de respaldo) --\n")
  if (nrow(d_ids)) {
    d_ids$k <- clave_tokens(d_ids$label)
    idx$k <- clave_tokens(idx$nombre)
    cat("match exacto de clave-tokens:", sum(idx$k %in% d_ids$k), "de 155\n")
    dup <- d_ids$k[duplicated(d_ids$k) & d_ids$k %in% idx$k]
    cat("claves ambiguas (mismo nombre normalizado, >1 persona BCN):",
        length(unique(dup)), "\n")
    if (length(dup)) print(unique(dup))
    sinm <- idx[!(idx$k %in% d_ids$k), c("id", "nombre")]
    cat("sin match por nombre:", nrow(sinm), "\n")
    if (nrow(sinm)) print(sinm)
  }
}

# =========================== FASE 4 ========================================
# Medicion de la via determinista completa:
#   id de Camara --(SPARQL idCamaraDeDiputados)--> persona BCN --(bcnPage)-->
#   ficha "Trayectoria Parlamentaria" --> distrito del periodo 2026-2030.
# Sin matching por nombre en ningun tramo.
fase_4 <- function() {
  cat("=== FASE 4: via determinista id -> persona -> ficha -> distrito ===\n")

  idx <- fromJSON(file.path(RAIZ, "docs", "data", "indice_diputados.json"),
                  simplifyDataFrame = TRUE)
  idx$id <- as.character(idx$id)

  q <- paste0(
    "SELECT ?idcam ?persona ?page WHERE { ",
    "?persona <", BIO, "idCamaraDeDiputados> ?idcam . ",
    "?persona <", BIO, "bcnPage> ?page }")
  d <- sparql_df(consulta_sparql(q))
  d$idcam <- as.character(d$idcam)
  d <- d[d$idcam %in% idx$id, ]
  # BCN reusa el mismo idCamaraDeDiputados en personas distintas (un historico y
  # uno vigente). NO se descarta el duplicado: se prueban todos los candidatos y
  # gana el que tenga fila del periodo vigente. Desambiguacion determinista.
  cat("de los 155, filas persona-ficha:", nrow(d),
      "| ids con >1 persona en BCN:", sum(table(d$idcam) > 1), "\n")

  # periodo vigente segun la propia Camara (Militancias del roster): 2026-2030
  PERIODO <- "2026-2030"

  res <- data.frame(id = idx$id, nombre = idx$nombre, distrito = NA_character_,
                    estado = "sin_ficha", stringsAsFactors = FALSE)
  for (k in seq_len(nrow(d))) {
    i <- match(d$idcam[k], res$id)
    if (!is.na(res$distrito[i])) next          # ya resuelto por otro candidato
    r <- tryCatch(GET(URLencode(d$page[k]), timeout(45),
                      user_agent("transparencia-legislativa-chile/medicion")),
                  error = function(e) e)
    if (inherits(r, "error")) { res$estado[i] <- "error_red"; next }
    if (status_code(r) != 200) { res$estado[i] <- paste0("http_", status_code(r)); next }
    x <- read_html(content(r, "text", encoding = "UTF-8"))
    filas <- xml_find_all(x, "//table//tr")
    hit <- NA_character_
    for (f in filas) {
      # el grado (°) rompe la regex bajo locale C: se normaliza a ASCII antes
      t <- iconv(xml_text(f), to = "ASCII", sub = " ")
      # BCN escribe el ordinal de dos formas: "12  Distrito" (grado, ya a espacio)
      # y "3er Distrito" / "1er" / "2do". Ambas deben caer en el mismo patron.
      if (grepl(PERIODO, t, fixed = TRUE) && grepl("Distrito", t)) {
        m <- regmatches(t, regexpr("[0-9]{1,2}[a-z ]{0,4}Distrito", t))
        if (length(m)) {
          n <- as.integer(gsub("[^0-9]", "", m))
          if (!is.na(n) && n >= 1 && n <= 28) { hit <- as.character(n); break }
        }
      }
    }
    res$distrito[i] <- hit
    res$estado[i] <- if (is.na(hit)) "ficha_sin_distrito_periodo" else "ok"
    Sys.sleep(0.3)
  }

  cat("\n--- COBERTURA ---\n")
  print(table(res$estado))
  cat("\ncon distrito del periodo", PERIODO, ":", sum(!is.na(res$distrito)), "de 155\n")
  malos <- res[is.na(res$distrito), ]
  if (nrow(malos)) {
    cat("\nCASOS SIN DISTRITO:\n")
    malos$nombre <- iconv(malos$nombre, to = "ASCII//TRANSLIT")
    print(malos[, c("id", "nombre", "estado")], row.names = FALSE)
  }
  cat("\ndistritos distintos observados:", length(unique(na.omit(res$distrito))),
      "(el pais tiene 28)\n")
  print(sort(as.integer(unique(na.omit(res$distrito)))))

  saveRDS(res, file.path(DIR_MUESTRAS, "medicion_territorio_155.rds"))
  cat("\nguardado: medicion_territorio_155.rds\n")
}

if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  fase <- if (length(args)) args[1] else "1"
  if (fase == "1") fase_1()
  if (fase == "2") fase_2()
  if (fase == "2b") fase_2_recurso(args[2])
  if (fase == "3") fase_3()
  if (fase == "4") fase_4()
  if (fase == "q") fase_q(paste(args[-1], collapse = " "))
}
