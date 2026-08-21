# =============================================================================
# 50_verificar_barrido_p105.R - Arnes de calibracion del barrido de dato personal
# -----------------------------------------------------------------------------
# POR QUE EXISTE ESTE ARCHIVO. La auditoria de gobernanza de P-99 calibro cinco
# detectores y publico su resultado ("0 hallazgos sobre 3 271 894 caracteres,
# 5/5 senuelos detectados") en
# 50_documentacion/andamios/logs/20260819_auditoria_gobernanza_p99_log.md §4.
# El arnes que produjo esa cifra vivio en /tmp y NUNCA se commiteo: sobrevivio
# entre sesiones por casualidad. El encargo A tuvo que salir a buscarlo al disco
# para no reconstruir los patrones de memoria, y su propia regla decia que si no
# lo encontraba debia detenerse. Una cifra de gobernanza no puede depender de que
# nadie limpie /tmp. Desde A2 el arnes vive aqui.
#
# QUE HACE. Tres fases, en este orden:
#   calib  - cinco senuelos sinteticos, uno por detector, cada uno con la forma
#            propia de su patron. Comprueba que ningun detector queda ciego.
#   copia  - inyecta los cinco senuelos en una COPIA DESECHABLE de un .rds real
#            de crudo y comprueba que los cinco disparan. El original NO se toca:
#            se compara su md5 antes y despues, y la copia se borra.
#   estado - ejercita los TRES estados del barrido (limpio / hallazgos /
#            ilegible) y comprueba que los archivos por estado suman el total.
#   corpus - barre el corpus vigente completo y declara VOLUMEN en caracteres
#            junto a la cifra de hallazgos. Un cero sin volumen no es un cero.
#
# COMO SE CORRE, desde la raiz del proyecto:
#   Rscript 50_documentacion/andamios/50_verificar_barrido_p105.R          # todo
#   Rscript 50_documentacion/andamios/50_verificar_barrido_p105.R calib    # una fase
#
# NO TOCA NADA. Solo lee. Las escrituras ocurren en tempdir().
# =============================================================================

source("10_utils/10_configuracion.R")
source("10_utils/10_utils.R")

fases <- commandArgs(trailingOnly = TRUE)
if (length(fases) == 0L) fases <- c("calib", "copia", "estado", "corpus")

titulo <- function(x) cat("\n== ", x, " ==\n", sep = "")
linea  <- function(...) cat(sprintf(...), "\n", sep = "")

# Los cinco senuelos, cada uno con la forma que ejercita SU detector. El de RUT
# con puntos lleva los puntos obligatorios: sin ellos el arnes de P-99 dejaba un
# detector ciego y lo declaraba sano (defecto corregido en aquella sesion).
SENUELOS <- c(
  correo         = "contacto: correo.prueba@ejemplo.cl",
  rut_con_puntos = "cedula 11.111.111-1",
  rut_sin_puntos = "rut 12345678-9",
  telefono_cl    = "fono +56911111111",
  digitos_9mas   = "serie 123456789012"
)

# ---- calib ------------------------------------------------------------------
if ("calib" %in% fases) {
  titulo("calib: cinco senuelos sinteticos, uno por detector")
  d <- file.path(tempdir(), "p105_calib"); unlink(d, recursive = TRUE); dir.create(d)
  for (n in names(SENUELOS)) writeLines(SENUELOS[[n]], file.path(d, paste0(n, ".txt")))
  b <- barrido_datos_personales(list.files(d, full.names = TRUE))
  h <- hallazgos_del_barrido(b)
  ciegos <- 0L
  for (n in names(SENUELOS)) {
    propio <- any(h$patron == n & basename(h$archivo) == paste0(n, ".txt"))
    todos  <- h$patron[basename(h$archivo) == paste0(n, ".txt")]
    if (!propio) ciegos <- ciegos + 1L
    linea("  %-14s detectado por su patron: %-5s | lo marcan: %s",
          n, propio, paste(todos, collapse = ", "))
  }
  linea("  detectores ciegos: %d de %d", ciegos, length(SENUELOS))
  linea("  volumen: %d caracteres en %d archivos", attr(b, "caracteres"), attr(b, "archivos"))
  unlink(d, recursive = TRUE)
  if (ciegos > 0L) stop("calib: hay detectores ciegos.", call. = FALSE)
}

# ---- copia ------------------------------------------------------------------
if ("copia" %in% fases) {
  titulo("copia: los cinco senuelos en una copia desechable de un .rds real")
  orig <- ruta_cache(sprintf("tramitacion_sil_%d", ANIO_PROCESO), Inf,
                     corte = CORTE_FECHA, subdir = CRUDO_SENADO)
  if (!file.exists(orig)) {
    linea("  (omitida: no existe %s)", basename(orig))
  } else {
    md5_antes <- unname(tools::md5sum(orig))
    b0 <- barrido_datos_personales(orig)
    linea("  el ORIGINAL, sin tocar: estado=%s | %d caracteres",
          b0$estado[1], attr(b0, "caracteres"))
    x <- readRDS(orig)
    x$xml[1] <- paste0(x$xml[1], " ", paste(SENUELOS, collapse = " "))
    copia <- file.path(tempdir(), "p105_copia_desechable.rds")
    saveRDS(x, copia)
    b1 <- barrido_datos_personales(copia)
    h1 <- hallazgos_del_barrido(b1)
    linea("  la COPIA con senuelo: %d patron(es) disparan: %s",
          nrow(h1), paste(h1$patron, collapse = ", "))
    linea("  los cinco disparan: %s", setequal(h1$patron, names(PATRONES_DATO_PERSONAL)))
    unlink(copia)
    linea("  copia borrada: %s | md5 del original intacto: %s",
          !file.exists(copia), identical(unname(tools::md5sum(orig)), md5_antes))
  }
}

# ---- estado -----------------------------------------------------------------
if ("estado" %in% fases) {
  titulo("estado: los tres estados, y que los archivos por estado sumen el total")
  d <- file.path(tempdir(), "p105_estado"); unlink(d, recursive = TRUE); dir.create(d)
  saveRDS(data.frame(x = "boletin 18232-25", stringsAsFactors = FALSE), file.path(d, "limpio.rds"))
  saveRDS(data.frame(x = SENUELOS[["correo"]], stringsAsFactors = FALSE), file.path(d, "sucio.rds"))
  writeLines("basura no serializada", file.path(d, "corrupto.rds"))
  saveRDS(data.frame(x = rawToChar(as.raw(c(0x61, 0xff, 0x62))), stringsAsFactors = FALSE),
          file.path(d, "utf8_malo.rds"))
  rutas <- c(list.files(d, full.names = TRUE), file.path(d, "no_existe.rds"))
  b <- barrido_datos_personales(rutas)
  pe <- attr(b, "por_estado")
  for (i in seq_len(nrow(b)))
    linea("  %-16s %-10s %s", basename(b$archivo[i]), b$estado[i],
          if (is.na(b$motivo[i])) paste0("patron=", b$patron[i]) else b$motivo[i])
  linea("  limpio=%d hallazgos=%d ilegible=%d | suman=%d | entrada=%d | CUADRAN=%s",
        pe[["limpio"]], pe[["hallazgos"]], pe[["ilegible"]], sum(pe), attr(b, "archivos"),
        identical(as.integer(sum(pe)), as.integer(attr(b, "archivos"))))
  unlink(d, recursive = TRUE)
  if (!identical(as.integer(sum(pe)), as.integer(attr(b, "archivos"))))
    stop("estado: los archivos por estado no suman el total de entrada.", call. = FALSE)
}

# ---- corpus -----------------------------------------------------------------
if ("corpus" %in% fases) {
  titulo("corpus: el corpus vigente completo, con volumen")
  # Se miden DOS conjuntos, y la distincion importa: el barrido local alcanza todo
  # 20_insumos/, y ahi dentro vive 20_insumos/exploracion/, que .gitignore:57
  # excluye a proposito porque son respuestas de sondeo con padron nominal del
  # Senado (R5 de P-99). Que el barrido las marque es la PRUEBA de que funciona,
  # no una brecha: nada de eso esta trackeado. Mezclar los dos conjuntos en una
  # sola cifra entrenaria al lector a ignorar la salida.
  medir <- function(rotulo, rutas) {
    t0 <- proc.time()[["elapsed"]]
    b  <- barrido_datos_personales(rutas)
    t1 <- proc.time()[["elapsed"]]
    pe <- attr(b, "por_estado")
    linea("  [%s] %d archivo(s) | limpio=%d hallazgos=%d ilegible=%d | suman=%d | CUADRAN=%s",
          rotulo, attr(b, "archivos"), pe[["limpio"]], pe[["hallazgos"]], pe[["ilegible"]],
          sum(pe), identical(as.integer(sum(pe)), as.integer(attr(b, "archivos"))))
    linea("  [%s] VOLUMEN: %d caracteres en %d valores | TIEMPO: %.2f s",
          rotulo, attr(b, "caracteres"), attr(b, "valores"), t1 - t0)
    b
  }
  trackeados <- system2("git", c("ls-files", "20_insumos"), stdout = TRUE)
  b_track <- medir("trackeado", trackeados)
  h <- hallazgos_del_barrido(b_track); il <- ilegibles_del_barrido(b_track)
  if (nrow(h) > 0L) { linea("  HALLAZGOS en lo trackeado:"); print(h[, c("archivo","patron","coincidencias")]) }
  if (nrow(il) > 0L) { linea("  ILEGIBLES en lo trackeado:"); print(il[, c("archivo","motivo")]) }
  if (nrow(h) == 0L && nrow(il) == 0L)
    linea("  0 hallazgos y 0 ilegibles sobre lo que el repositorio publica.")

  b_todo <- medir("todo 20_insumos/", rutas_barribles_locales())
  h2 <- hallazgos_del_barrido(b_todo); il2 <- ilegibles_del_barrido(b_todo)
  afect <- unique(c(h2$archivo, il2$archivo))
  fuera <- setdiff(afect, trackeados)
  linea("  archivos marcados en el conjunto amplio: %d | de ellos NO trackeados: %d",
        length(afect), length(fuera))
  if (length(fuera) > 0L) {
    sub2 <- vapply(strsplit(fuera, "/", fixed = TRUE), function(x) x[2], character(1))
    linea("  subdirectorios de los no trackeados: %s",
          paste(sprintf("%s=%d", names(table(sub2)), as.integer(table(sub2))), collapse = ", "))
    linea("  (esperado: 20_insumos/exploracion/, excluido por .gitignore -- ver R5 de P-99)")
  }
}

cat("\n")
