# =============================================================================
# 50_sondeo_p92_f5.R  --  P-92, F5: la prueba que decide
# -----------------------------------------------------------------------------
# VIA ELEGIDA: la 1 (sufijo del boletin). Se declara ANTES de correr la tabla,
# con el porque:
#   via 1  100 % de cobertura estructural (427/427), 29 categorias, 21 con n>=5,
#          discriminacion de vocabulario p=0.001 (z=18,1), estabilidad de
#          comision modal 92,9 % en los sufijos con n>=5, control positivo 5/5.
#   via 2  BLOQUEADA: camara.cl responde 403 de Cloudflare a la ruta real y a la
#          fabricada por igual. H7 sin responder.
#   via 3  cobertura 72,13 % (308/427), control positivo 3/5 (umbral 4/5: FALLA)
#          y brecha de apartado 10,74 pp sobre un umbral de 10 pp.
#   via 4  1,90 % (16/842) con la 'descripcion'; 0 % sobre las 281 votaciones sin
#          boletin con el 'articulo'. Sin insumo.
#
# ETIQUETADO (D42): el sufijo se reporta DESNUDO. La comision modal que lo
# acompana es una asociacion EMPIRICA medida en F1.4, rotulada como tal en cada
# tabla, y NO una glosa oficial: F2 establecio que no existe catalogo oficial.
#
# PRUEBA DE NO DEGENERACION, DECLARADA ANTES DE CORRERLA: el eje sirve si existe
# al menos un tema donde la diferencia de tasa de aprobacion entre izquierda y
# derecha supere 20 puntos porcentuales, con al menos 100 votos en cada celda.
# CERO red: el padron historico ya se bajo en F2.3.
# =============================================================================

RAIZ <- "/Users/tomgc/Projects/transparencia_legislativa_chile"
setwd(RAIZ)
source("10_utils/10_locale.R"); asegurar_locale_utf8("50_sondeo_p92_f5.R")
source("50_documentacion/andamios/50_fusible_red.R"); instalar_fusible_red(silencioso = TRUE)
suppressPackageStartupMessages({ library(dplyr); library(xml2); library(tidyr) })
MU <- "50_documentacion/andamios/muestras/p92"
sep <- function(t) cat("\n", strrep("=", 74), "\n", t, "\n", strrep("=", 74), "\n", sep = "")
frac <- function(n, d, etq) cat(sprintf("  %-54s %6d / %-6d  (%6.2f %%)\n", etq, n, d, 100 * n / d))

# El mapa vive en la configuracion del proyecto: se LEE, no se copia.
MAPA <- local({
  e <- new.env(); src <- readLines("10_utils/10_configuracion.R")
  i <- grep("^MAPA_PARTIDO_TENDENCIA <- c\\(", src); j <- i + which(grepl("^\\)", src[i:length(src)]))[1] - 1
  eval(parse(text = paste(src[i:j], collapse = "\n")), envir = e)
  get("MAPA_PARTIDO_TENDENCIA", envir = e)
})
cat(sprintf("MAPA_PARTIDO_TENDENCIA leido de 10_utils/10_configuracion.R: %d partidos.\n", length(MAPA)))

vo <- readRDS("40_salidas/intermedios/votos.rds")
di <- readRDS("40_salidas/intermedios/diputados.rds")
pd <- readRDS("40_salidas/intermedios/proyectos_detalle.rds")

# --- F5.1  H5: votante -> partido -> tendencia -------------------------------
sep("F5.1  H5  votante -> partido -> tendencia, con el padron historico")
x <- read_xml(file.path(MU, "diputados_historico.xml"))
nod <- xml_find_all(x, ".//*[local-name()='Diputado']")
hist <- bind_rows(lapply(nod, function(d) {
  id <- xml_text(xml_find_first(d, ".//*[local-name()='Id']"))
  mil <- xml_find_all(d, ".//*[local-name()='Militancia']")
  if (!length(mil)) return(data.frame(diputado_id = id, partido_id = NA_character_,
                                      ini = NA_character_, fin = NA_character_))
  data.frame(diputado_id = id,
    partido_id = xml_text(xml_find_first(mil, ".//*[local-name()='Partido']/*[local-name()='Alias']")),
    ini = xml_text(xml_find_first(mil, ".//*[local-name()='FechaInicio']")),
    fin = xml_text(xml_find_first(mil, ".//*[local-name()='FechaTermino']")), stringsAsFactors = FALSE)
}))
cat(sprintf("  padron historico: %d diputados, %d filas de militancia\n",
            length(nod), nrow(hist)))
# militancia mas reciente por diputado
hist_u <- hist |> filter(!is.na(partido_id), nzchar(partido_id)) |>
  arrange(diputado_id, desc(ini)) |> distinct(diputado_id, .keep_all = TRUE)
frac(nrow(hist_u), length(nod), "diputados historicos con militancia declarada")

votantes <- unique(vo$diputado_id)
cobertura <- data.frame(diputado_id = votantes) |>
  mutate(en_padron = diputado_id %in% di$diputado_id,
         en_hist   = diputado_id %in% hist_u$diputado_id)
frac(sum(cobertura$en_padron), nrow(cobertura), "votantes en el padron vigente (155)")
frac(sum(cobertura$en_hist),   nrow(cobertura), "votantes con militancia en el padron historico")
frac(sum(cobertura$en_padron | cobertura$en_hist), nrow(cobertura), "votantes cubiertos por alguna de las dos")

# tendencia unificada: padron vigente manda; historico rellena
tend <- di |> select(diputado_id, partido_id, tendencia) |> mutate(fuente = "padron_vigente")
faltan <- hist_u |> filter(!diputado_id %in% di$diputado_id) |>
  transmute(diputado_id, partido_id, tendencia = unname(MAPA[partido_id]), fuente = "historico")
tend <- bind_rows(tend, faltan)
cat(sprintf("\n  partidos historicos NO presentes en MAPA_PARTIDO_TENDENCIA: %d\n",
            sum(!faltan$partido_id %in% names(MAPA))))
if (any(!faltan$partido_id %in% names(MAPA))) {
  cat("  (se listan con su recuento de diputados; quedan en NA, no se les inventa tendencia)\n")
  print(as.data.frame(faltan |> filter(!partido_id %in% names(MAPA)) |> count(partido_id, sort = TRUE)))
}
vt <- vo |> left_join(tend, by = "diputado_id")
frac(sum(!is.na(vt$tendencia)), nrow(vt), "FILAS de voto con tendencia (universo completo)")
INST <- "2026-03-11"
vt_p <- vt |> filter(fecha >= INST)
frac(sum(!is.na(vt_p$tendencia)), nrow(vt_p), "FILAS de voto con tendencia (periodo vigente)")
cat("\n  no mapeados, por causa:\n")
print(as.data.frame(vt |> filter(is.na(tendencia)) |>
  mutate(causa = ifelse(is.na(partido_id), "sin militancia en ninguna fuente",
                 ifelse(partido_id == "IND", "IND: sin militancia, no clasificable (decision del titular)",
                        paste0("partido fuera del mapa: ", partido_id)))) |>
  count(causa, sort = TRUE)))

# --- F5.2  H6: existe bancada? ----------------------------------------------
sep("F5.2  H6  existe una nocion de bancada distinta de partido, con fuente?")
campos_hist <- unique(unlist(lapply(utils::head(nod, 50), function(d) xml_name(xml_find_all(d, ".//*")))))
cat("  campos distintos en el padron historico (50 primeros diputados):\n    ",
    paste(sort(campos_hist), collapse = ", "), "\n")
cat(sprintf("  campos que mencionan 'banc': %d\n", sum(grepl("banc", campos_hist, ignore.case = TRUE))))
cat(sprintf("  columnas de diputados.rds que mencionan 'banc': %d\n",
            sum(grepl("banc", names(di), ignore.case = TRUE))))
cat("  operaciones del catalogo de fuentes (38) que mencionan 'bancada': ")
cat(sum(grepl("bancada", readLines("50_documentacion/activa/50_catalogo_fuentes_camara.md", warn = FALSE),
              ignore.case = TRUE)), " lineas\n")
cat("  -> H6 FALSA para lo medible: no hay campo ni operacion de bancada. Se\n")
cat("     trabaja con partido y tendencia, y se declara.\n")

# --- F5.3  la tabla tema x tendencia ----------------------------------------
sep("F5.3  TABLA  sufijo (via 1) x tendencia x resultado")
vt <- vt |> mutate(sufijo = ifelse(!is.na(boletin) & nzchar(trimws(boletin)),
                                   sub("^[0-9]+-", "", trimws(boletin)), NA_character_))
frac(sum(!is.na(vt$sufijo)), nrow(vt), "FILAS de voto con sufijo (cobertura de la via 1)")
frac(sum(!is.na(vt$sufijo) & !is.na(vt$tendencia)), nrow(vt), "FILAS con sufijo Y tendencia")
# etiqueta EMPIRICA del sufijo (F1.4), rotulada como tal
f1 <- readRDS("50_documentacion/andamios/muestras/p92_f1.rds")
etq <- f1$res_com |> select(sufijo, comision_modal_empirica = modal, pct_modal, n_boletines = n)

emitidos <- c("a_favor", "en_contra", "abstencion")
tabla_de <- function(d, etiqueta) {
  cat(sprintf("\n  --- %s ---\n", etiqueta))
  b <- d |> filter(!is.na(sufijo), !is.na(tendencia), sentido %in% emitidos) |>
    summarise(n = n(), a_favor = sum(sentido == "a_favor"), .by = c(sufijo, tendencia)) |>
    mutate(tasa = round(100 * a_favor / n, 1))
  cat(sprintf("      celdas: %d ; votos emitidos considerados: %d\n", nrow(b), sum(b$n)))
  ancho <- b |> select(sufijo, tendencia, tasa, n) |>
    pivot_wider(names_from = tendencia, values_from = c(tasa, n)) |>
    left_join(etq, by = "sufijo") |>
    arrange(desc(n_izquierda + n_derecha))
  invisible(list(largo = b, ancho = ancho))
}
T_con <- tabla_de(vt, "UNIVERSO COMPLETO (todas las votaciones; las 281 sin boletin quedan sin sufijo)")
T_per <- tabla_de(vt |> filter(fecha >= INST), "PERIODO VIGENTE (fecha >= 2026-03-11)")

imprimir <- function(a, titulo) {
  cat(sprintf("\n  %s\n", titulo))
  cols <- c("sufijo", "comision_modal_empirica", "pct_modal",
            "tasa_izquierda", "n_izquierda", "tasa_centroizquierda", "n_centroizquierda",
            "tasa_centro", "n_centro", "tasa_centroderecha", "n_centroderecha",
            "tasa_derecha", "n_derecha")
  cols <- cols[cols %in% names(a)]
  d <- as.data.frame(a[, cols])
  d$comision_modal_empirica <- substr(d$comision_modal_empirica, 1, 26)
  print(d, row.names = FALSE)
}
imprimir(T_con$ancho, "UNIVERSO COMPLETO — tasa de voto a favor (%) y n de votos emitidos por celda")
imprimir(T_per$ancho, "PERIODO VIGENTE — tasa de voto a favor (%) y n de votos emitidos por celda")

# --- F5.4  prueba de no degeneracion ----------------------------------------
sep("F5.4  PRUEBA DE NO DEGENERACION  (umbral declarado antes: >20 pp, n>=100/celda)")
prueba <- function(a, etiqueta) {
  d <- a |> filter(!is.na(tasa_izquierda), !is.na(tasa_derecha)) |>
    mutate(brecha = round(tasa_derecha - tasa_izquierda, 1),
           n_min = pmin(n_izquierda, n_derecha),
           cumple = abs(brecha) > 20 & n_min >= 100) |>
    arrange(desc(abs(brecha)))
  cat(sprintf("\n  --- %s ---\n", etiqueta))
  print(as.data.frame(d |> select(sufijo, comision_modal_empirica, tasa_izquierda, n_izquierda,
                                  tasa_derecha, n_derecha, brecha, n_min, cumple) |>
          mutate(comision_modal_empirica = substr(comision_modal_empirica, 1, 24))), row.names = FALSE)
  cat(sprintf("\n  sufijos con n >= 100 en ambas celdas extremas: %d de %d\n",
              sum(d$n_min >= 100), nrow(d)))
  cat(sprintf("  sufijos con brecha > 20 pp Y n >= 100: %d\n", sum(d$cumple)))
  cat(sprintf("  brecha maxima con n >= 100: %.1f pp (sufijo %s)\n",
              max(abs(d$brecha[d$n_min >= 100])), d$sufijo[d$n_min >= 100][which.max(abs(d$brecha[d$n_min >= 100]))]))
  cat(sprintf("  VEREDICTO: %s\n", ifelse(any(d$cumple),
      "PASA. El eje distingue: hay al menos un tema donde izquierda y derecha se separan mas de 20 pp.",
      "FALLA. El eje es tematicamente real pero POLITICAMENTE MUDO: ningun tema separa a las tendencias extremas mas de 20 pp con n suficiente.")))
  invisible(d)
}
D_con <- prueba(T_con$ancho, "UNIVERSO COMPLETO")
D_per <- prueba(T_per$ancho, "PERIODO VIGENTE")

# --- F5.5  con y sin las votaciones sin boletin ------------------------------
sep("F5.5  cuanto aporta la via 4: con y sin las votaciones sin boletin")
sin_b <- vt |> filter(is.na(sufijo))
cat(sprintf("  votaciones sin boletin: %d de %d ; filas de voto: %d de %d (%.2f %%)\n",
            n_distinct(sin_b$votacion_id), n_distinct(vt$votacion_id),
            nrow(sin_b), nrow(vt), 100 * nrow(sin_b) / nrow(vt)))
cat("  La via 4 habria clasificado ese bloque. Como no hay texto (F4.1), el bloque\n")
cat("  entero queda FUERA del eje: no es que se clasifique mal, es que no se puede.\n")
cat("\n  tasa de aprobacion global por tendencia, dentro y fuera del eje:\n")
print(as.data.frame(vt |> filter(!is.na(tendencia), sentido %in% emitidos) |>
  mutate(bloque = ifelse(is.na(sufijo), "sin boletin (fuera del eje)", "con boletin (dentro del eje)")) |>
  summarise(n = n(), tasa_a_favor = round(100 * mean(sentido == "a_favor"), 1),
            .by = c(bloque, tendencia)) |>
  pivot_wider(names_from = tendencia, values_from = c(tasa_a_favor, n))))

saveRDS(list(T_con = T_con, T_per = T_per, D_con = D_con, D_per = D_per, tend = tend),
        file.path(MU, "p92_f5.rds"))
cat("\nF5 terminada sin red.\n")
