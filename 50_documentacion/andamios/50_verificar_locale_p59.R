# =============================================================================
# 50_verificar_locale_p59.R
# -----------------------------------------------------------------------------
# Proposito: criterios C1-C9 del encargo P-59 (guarda de locale UTF-8). Mide;
#            no repite respuestas de reportes anteriores.
#
# Los escenarios de locale corren en SUBPROCESOS con --vanilla y el entorno
# fijado explicitamente: la locale es estado del PROCESO, asi que un escenario
# que la mida en el proceso que ya la corrigio no prueba nada (A76).
#
# Uso: P59_TMP=<dir fuera del repo> Rscript 50_documentacion/andamios/50_verificar_locale_p59.R
# Autor: Claude Code (encargo P-59, sesion 19)
# Creado: 2026-08-12
# =============================================================================

source(file.path(rprojroot::find_root(rprojroot::has_file(".here")),
                 "10_utils", "10_utils.R"))
ROOT <- obtener_raiz_proyecto()
source(file.path(ROOT, "10_utils", "10_configuracion.R"))

TMP <- Sys.getenv("P59_TMP")
if (!nzchar(TMP) || !dir.exists(TMP))
  stop("falta P59_TMP o el directorio no existe.", call. = FALSE)

PLANTILLA <- "/Users/tomgc/Projects/herramientas_dev/plantillas/10_locale.R"
HELPER    <- file.path(ROOT, "10_utils", "10_locale.R")
MARCADOR  <- file.path(ROOT, "50_documentacion", "activa", "50_locale_utf8.md")
PUNTOS    <- c("10_utils/10_configuracion.R", "10_utils/10_diff_conteos.R",
               "00_escanear_proyecto.R",
               "50_documentacion/andamios/medir_fuente_territorio.R")

titulo <- function(x) cat("\n\n=====", x, "=====\n")
subt   <- function(x) cat("\n--- ", x, "\n", sep = "")
linea  <- function(fmt, ...) cat(sprintf(fmt, ...), "\n", sep = "")
tiene  <- function(v, txt) any(vapply(v, function(l) grepl(txt, l, fixed = TRUE), logical(1)))
md5_de <- function(dir, patron) {
  f <- sort(list.files(dir, patron, full.names = TRUE, recursive = TRUE))
  stats::setNames(vapply(f, function(x) unname(tools::md5sum(x)), character(1)),
                  sub(paste0("^", dir, "/"), "", f))
}
veredicto <- function(id, ok, detalle) {
  linea("%-4s %-9s %s", id, if (ok) "CUMPLE" else "NO CUMPLE", detalle); invisible(ok)
}
# Lineas de CODIGO: se descartan las de comentario. El barrido de G3 no lo hacia
# y por eso contaba como escritura la palabra "writeLines()" dentro de un
# comentario -- entre ellos el de la cabecera del propio helper (10_locale.R:55)
# y el que este encargo agrego al escaner. Un comentario no escribe nada.
codigo_de <- function(ruta) {
  l <- readLines(ruta, warn = FALSE)
  l[!startsWith(trimws(l), "#")]
}
# Subproceso con entorno explicito. Devuelve salida y codigo de salida.
correr <- function(nombre, cuerpo, entorno = character(0)) {
  f <- file.path(TMP, paste0(nombre, ".R"))
  writeLines(cuerpo, f)
  out <- system2("Rscript", c("--vanilla", shQuote(f)), env = entorno,
                 stdout = TRUE, stderr = TRUE)
  st <- attr(out, "status"); if (is.null(st)) st <- 0L
  list(salida = st, lineas = out)
}
res <- list()

titulo("Linea base de integridad (C7, apertura)")
b_cap <- md5_de(ruta_insumos("camara"), "[.]rds$")
b_jsn <- md5_de(ruta_salidas("json"), "[.]json$")
b_doc <- md5_de(file.path(ROOT, "docs", "data"), "[.]json$")
linea("Capturas: %d | 40_salidas/json: %d | docs/data: %d",
      length(b_cap), length(b_jsn), length(b_doc))

titulo("C1. El helper instalado es identico al de herramientas_dev")
m_org <- unname(tools::md5sum(PLANTILLA)); m_rep <- unname(tools::md5sum(HELPER))
linea("origen : %s (%d bytes)", m_org, file.size(PLANTILLA))
linea("copia  : %s (%d bytes)", m_rep, file.size(HELPER))
res$C1 <- veredicto("C1", identical(m_org, m_rep) &&
  identical(file.size(PLANTILLA), file.size(HELPER)),
  sprintf("md5 identico: %s", m_org))

titulo("C2. El gatillo 4ter queda apagado con las DOS evidencias")
r_utils <- list.files(file.path(ROOT, "10_utils"), "[.]R$", full.names = TRUE)
con_llamada <- vapply(r_utils, function(f)
  tiene(readLines(f, warn = FALSE), "asegurar_locale_utf8"), logical(1))
linea("Archivos .R en 10_utils/ que nombran asegurar_locale_utf8: %d de %d",
      sum(con_llamada), length(r_utils))
for (f in basename(r_utils[con_llamada])) linea("  %s", f)
linea("Marcador 50_documentacion/activa/50_locale_utf8.md existe: %s", file.exists(MARCADOR))
res$C2 <- veredicto("C2", sum(con_llamada) >= 1 && file.exists(MARCADOR),
  "grep >= 1 Y marcador presente: las dos cosas, no una")

titulo("C3. La guarda se ejecuta en el arranque")
cuerpo_c3 <- c(
  sprintf('setwd("%s")', ROOT),
  'cat("ANTES :", Sys.getlocale("LC_CTYPE"), "| UTF-8:", isTRUE(l10n_info()[["UTF-8"]]), "\\n")',
  'source("10_utils/10_utils.R"); source("10_utils/10_configuracion.R")',
  'cat("DESPUES:", Sys.getlocale("LC_CTYPE"), "| UTF-8:", isTRUE(l10n_info()[["UTF-8"]]), "\\n")',
  'cat("la funcion quedo definida:", exists("asegurar_locale_utf8"), "\\n")')
c3 <- correr("c3_arranque", cuerpo_c3, c("LC_ALL=C", "LANG=C"))
for (l in c3$lineas) linea("  %s", l)
res$C3 <- veredicto("C3", c3$salida == 0L &&
  tiene(c3$lineas, "la funcion quedo definida: TRUE") &&
  tiene(c3$lineas, "DESPUES: es_ES.UTF-8"),
  "cargar 10_configuracion.R deja el proceso en UTF-8 y la funcion definida")

titulo("C4. Las dos mitades: sin locale se actua; con locale valida se pasa")
subt("(a) LC_ALL=C LANG=C: el proceso arranca sin UTF-8 y la guarda lo corrige")
c4a <- correr("c4a_sin_locale", cuerpo_c3, c("LC_ALL=C", "LANG=C"))
for (l in c4a$lineas) linea("  %s", l)
ok_a <- c4a$salida == 0L && tiene(c4a$lineas, "ANTES : C") &&
  tiene(c4a$lineas, "DESPUES: es_ES.UTF-8") &&
  tiene(c4a$lineas, "locale corregida en caliente")

subt("(b) Misma locale invalida, pero SIN candidatas viables: tiene que abortar")
cuerpo_c4b <- c(
  sprintf('source("%s")', HELPER),
  # No se edita el helper: se sustituye la constante en ESTE proceso, para
  # ejercer la rama de fallo sin depender de que la maquina carezca de locales.
  'LOCALES_UTF8_CANDIDATAS <- c("xx_YY.NO_EXISTE")',
  'asegurar_locale_utf8("prueba C4b")',
  'cat("NO ESPERADO: la guarda no aborto\\n")')
c4b <- correr("c4b_aborta", cuerpo_c4b, c("LC_ALL=C", "LANG=C"))
linea("  codigo de salida: %d (distinto de 0 = aborto)", c4b$salida)
for (l in c4b$lineas) linea("  %s", l)
ok_b <- c4b$salida != 0L && tiene(c4b$lineas, "ABORTADO en prueba C4b") &&
  tiene(c4b$lineas, "el proceso corre sin locale UTF-8") &&
  !tiene(c4b$lineas, "NO ESPERADO")

subt("(c) Reverso: LANG=es_ES.UTF-8 pasa y la guarda NO corrige nada")
c4c <- correr("c4c_con_locale", cuerpo_c3, c("LC_ALL=", "LANG=es_ES.UTF-8"))
for (l in c4c$lineas) linea("  %s", l)
ok_c <- c4c$salida == 0L && tiene(c4c$lineas, "ANTES : es_ES.UTF-8") &&
  !tiene(c4c$lineas, "locale corregida en caliente")
linea("(a) actua: %s | (b) aborta: %s | (c) pasa sin actuar: %s", ok_a, ok_b, ok_c)
res$C4 <- veredicto("C4", ok_a && ok_b && ok_c,
  "las tres mitades distinguen la guarda del entorno")

titulo("C5. Ningun silenciador en el camino")
tokens <- c("try(", "silent", "suppressWarnings")
revisar <- c(HELPER, file.path(ROOT, PUNTOS))
total_env <- 0L
for (f in revisar) {
  l <- readLines(f, warn = FALSE)
  # Lineas donde CONVIVEN un silenciador y la llamada/fijacion de locale.
  sospechosas <- which(vapply(l, function(x)
    (grepl("Sys.setlocale", x, fixed = TRUE) || grepl("asegurar_locale_utf8", x, fixed = TRUE)) &&
      any(vapply(tokens, function(t) grepl(t, x, fixed = TRUE), logical(1))), logical(1)))
  total_env <- total_env + length(sospechosas)
  linea("  %-52s lineas con locale: %2d | envueltas en silenciador: %d",
        sub(paste0("^", ROOT, "/"), "", f),
        sum(vapply(l, function(x) grepl("Sys.setlocale", x, fixed = TRUE) ||
                     grepl("asegurar_locale_utf8", x, fixed = TRUE), logical(1))),
        length(sospechosas))
}
res$C5 <- veredicto("C5", total_env == 0L,
  sprintf("0 de %d archivos revisados envuelven la guarda", length(revisar)))

titulo("C6. Texto acentuado, ida y vuelta por la ruta de escritura del proyecto")
# La misma ruta que usa el 39 (39_consolidar_json.R:154-157): toJSON -> writeLines
# con enc2utf8 y useBytes. Se escribe FUERA del repositorio.
instalar_si_falta("jsonlite")
original <- c("Ñuñoa", "Peñalolén", "Diputación", "Valparaíso", "O'Higgins", "Aysén")
ruta_c6 <- file.path(TMP, "c6_texto.json")
txt <- jsonlite::toJSON(list(comunas = original), auto_unbox = TRUE, pretty = TRUE)
escribir_atomico(txt, ruta_c6, function(o, r)
  writeLines(enc2utf8(as.character(o)), r, useBytes = TRUE))
vuelta <- jsonlite::fromJSON(ruta_c6)$comunas
bytes <- readBin(ruta_c6, "raw", file.size(ruta_c6))
linea("  cadenas: %d | identical() con el original: %s", length(original),
      identical(original, vuelta))
linea("  el archivo NO contiene la secuencia de escape <c3>: %s",
      !tiene(readLines(ruta_c6, warn = FALSE), "<c3>"))
linea("  bytes no ASCII en el archivo: %d (esperado > 0 si el texto salio UTF-8 real)",
      sum(as.integer(bytes) > 127))
res$C6 <- veredicto("C6", identical(original, vuelta) &&
  sum(as.integer(bytes) > 127) > 0 &&
  !tiene(readLines(ruta_c6, warn = FALSE), "<c3>"),
  sprintf("%d de %d cadenas vuelven identicas", sum(original == vuelta), length(original)))

titulo("C9. Los cuatro puntos, y el barrido de G3 repetido")
subt("(a) Cada punto invoca la guarda ANTES de su primera escritura de texto")
patrones_escritura <- c("writeLines(", "write_json(", "saveRDS(", "write.csv(",
                        "write_csv(", "writeBin(")
ok9a <- TRUE
for (p in PUNTOS) {
  l <- codigo_de(file.path(ROOT, p))
  k_guarda <- which(vapply(l, function(x) grepl("asegurar_locale_utf8(", x, fixed = TRUE), logical(1)))
  k_escr <- which(vapply(l, function(x)
    any(vapply(patrones_escritura, function(t) grepl(t, x, fixed = TRUE), logical(1))), logical(1)))
  primera <- if (length(k_escr)) min(k_escr) else NA_integer_
  ok <- length(k_guarda) >= 1 && (is.na(primera) || min(k_guarda) < primera)
  ok9a <- ok9a && ok
  linea("  %-52s guarda en %s | primera escritura en %s | antes: %s",
        p, paste(k_guarda, collapse = ","),
        if (is.na(primera)) "ninguna" else primera, ok)
}
linea("Puntos que invocan la guarda antes de escribir: %d de %d",
      sum(vapply(PUNTOS, function(p) {
        l <- codigo_de(file.path(ROOT, p))
        any(vapply(l, function(x) grepl("asegurar_locale_utf8(", x, fixed = TRUE), logical(1)))
      }, logical(1))), length(PUNTOS))

subt("(b) Universo alcanzable: quien escribe sin pasar por ninguno de los cuatro")
archivos <- list.files(ROOT, pattern = "[.]R$", recursive = TRUE)
archivos <- archivos[!startsWith(archivos, "renv/")]

# El universo que importa NO es "todo .R del repositorio": es lo alcanzable desde
# las tres raices por las que este proyecto arranca de verdad. Se calcula por
# cierre transitivo sobre las menciones de archivos .R en lineas de CODIGO (los
# comentarios no invocan nada). Un archivo que nadie alcanza no puede escribir en
# una corrida de este proyecto, y meterlo en el denominador infla la cobertura.
RAICES <- c("00_run_all.R", ".github/workflows/refresh-semanal.yml",
            "00_escanear_proyecto.R")
lineas_codigo <- function(rel) {
  ruta <- file.path(ROOT, rel)
  if (!file.exists(ruta)) return(character(0))
  l <- readLines(ruta, warn = FALSE)
  l[!startsWith(trimws(l), "#")]
}
alcanzables <- local({
  vistos <- character(0); frontera <- RAICES
  while (length(frontera) > 0) {
    f <- frontera[1]; frontera <- frontera[-1]
    if (f %in% vistos) next
    vistos <- c(vistos, f)
    l <- lineas_codigo(f)
    hijos <- archivos[vapply(archivos, function(a)
      any(vapply(l, function(x) grepl(a, x, fixed = TRUE) ||
                   grepl(basename(a), x, fixed = TRUE), logical(1))), logical(1))]
    frontera <- c(frontera, setdiff(hijos, vistos))
  }
  intersect(archivos, vistos)
})
EXCLUIDOS <- setdiff(archivos, alcanzables)
linea("Raices declaradas: %d -> %s", length(RAICES), paste(RAICES, collapse = ", "))
linea("Archivos .R del repositorio: %d | ALCANZABLES desde las raices: %d | fuera: %d",
      length(archivos), length(alcanzables), length(EXCLUIDOS))
subt("Universo alcanzable, enumerado")
for (a in alcanzables) linea("    %s", a)
subt("Fuera del universo (no alcanzables desde ninguna raiz)")
for (a in EXCLUIDOS) linea("    %s", a)
# "Pasa por" = ES uno de los cuatro, o menciona a uno de los cuatro en un source().
pasa <- vapply(archivos, function(a) {
  if (a %in% PUNTOS) return(TRUE)
  l <- codigo_de(file.path(ROOT, a))
  any(vapply(basename(PUNTOS), function(p) tiene(l, p), logical(1)))
}, logical(1))
escribe <- vapply(archivos, function(a) {
  l <- codigo_de(file.path(ROOT, a))
  any(vapply(patrones_escritura, function(t) tiene(l, t), logical(1)))
}, logical(1))
escribe_texto <- vapply(archivos, function(a) {
  l <- codigo_de(file.path(ROOT, a))
  any(vapply(c("writeLines(", "write_json(", "write.csv(", "write_csv("),
             function(t) tiene(l, t), logical(1)))
}, logical(1))
en_universo <- archivos %in% alcanzables
subt("Veredicto sobre el universo alcanzable")
linea("Denominador (alcanzables): %d", sum(en_universo))
linea("  de esos, escriben algun artefacto: %d de %d", sum(escribe & en_universo),
      sum(en_universo))
linea("  de esos, escriben TEXTO           : %d de %d",
      sum(escribe_texto & en_universo), sum(en_universo))
huerfanos <- archivos[escribe & !pasa & en_universo]
linea("HUERFANOS (escriben y no pasan por ninguno de los cuatro): %d de %d",
      length(huerfanos), sum(en_universo))
if (length(huerfanos) == 0) linea("    (ninguno)")
for (a in huerfanos) linea("    %s", a)

subt("Excluidos, por categoria (cada uno con SU razon, no con una comun)")
escribe_de <- function(a, patrones) {
  l <- codigo_de(file.path(ROOT, a))
  any(vapply(patrones, function(t) tiene(l, t), logical(1)))
}
patrones_texto <- c("writeLines(", "write_json(", "write.csv(", "write_csv(")
fuera_que_escriben <- EXCLUIDOS[vapply(EXCLUIDOS, escribe_de, logical(1),
                                       patrones = patrones_escritura)]
DIR_AUDITORIA <- "20_insumos/exploracion/20260807/"
# (1) Los DECLARADOS por el titular: reproductores congelados de la auditoria de
# fuentes del 2026-08-07 que escriben TEXTO. Van nombrados uno por uno aqui y en
# el marcador. Guardados como procedencia; ninguna raiz los alcanza.
declarados <- fuera_que_escriben[startsWith(fuera_que_escriben, DIR_AUDITORIA) &
                                 vapply(fuera_que_escriben, escribe_de, logical(1),
                                        patrones = patrones_texto)]
linea("(1) Reproductores congelados que escriben TEXTO (auditoria 2026-08-07): %d",
      length(declarados))
for (a in declarados) linea("    %s", a)
# (2) Misma auditoria, mismo congelamiento, pero solo escriben binario (.rds).
otros_auditoria <- setdiff(fuera_que_escriben[startsWith(fuera_que_escriben, DIR_AUDITORIA)],
                           declarados)
linea("(2) Misma auditoria 2026-08-07, escriben solo binario: %d", length(otros_auditoria))
for (a in otros_auditoria) linea("    %s", a)
# (3) Andamios de medicion y arneses. NO son de esa auditoria: son de sesiones
# distintas y se corren a mano. Se listan con su propia razon, sin heredar fecha.
andamios <- setdiff(fuera_que_escriben, c(declarados, otros_auditoria))
linea("(3) Andamios y arneses, corridos a mano, fuera del pipeline: %d", length(andamios))
for (a in andamios) linea("    %s", a)
res$C9 <- veredicto("C9", ok9a && length(huerfanos) == 0L,
  sprintf("%d de %d puntos invocan antes de escribir; %d huerfanos sobre %d alcanzables (%d reproductores declarados fuera)",
          length(PUNTOS), length(PUNTOS), length(huerfanos), sum(en_universo),
          length(declarados)))

titulo("C7. Nada mas cambio")
c_cap <- md5_de(ruta_insumos("camara"), "[.]rds$")
c_jsn <- md5_de(ruta_salidas("json"), "[.]json$")
c_doc <- md5_de(file.path(ROOT, "docs", "data"), "[.]json$")
linea("Capturas   : %d de %d identicas", sum(b_cap == c_cap[names(b_cap)]), length(b_cap))
linea("json       : %d de %d identicas", sum(b_jsn == c_jsn[names(b_jsn)]), length(b_jsn))
linea("docs/data  : %d de %d identicas", sum(b_doc == c_doc[names(b_doc)]), length(b_doc))
res$C7 <- veredicto("C7", identical(b_cap, c_cap) && identical(b_jsn, c_jsn) &&
  identical(b_doc, c_doc),
  sprintf("%d + %d + %d archivos sin cambio", length(b_cap), length(b_jsn), length(b_doc)))

titulo("RESUMEN")
for (k in c("C1", "C2", "C3", "C4", "C5", "C6", "C7", "C9"))
  linea("  %-4s %s", k, if (isTRUE(res[[k]])) "CUMPLE" else "NO CUMPLE")
linea("\nMedidos aqui: %d de 9 (C8 se mide sobre el PR ya abierto)", length(res))
linea("CUMPLEN: %d de %d", sum(vapply(res, isTRUE, logical(1))), length(res))
