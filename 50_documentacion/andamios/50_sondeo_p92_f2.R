# =============================================================================
# 50_sondeo_p92_f2.R  --  P-92, F2: existe catalogo oficial codigo -> glosa
#                          para el sufijo del boletin?
# -----------------------------------------------------------------------------
# D42 gobierna esta fase: si no aparece catalogo oficial, el sufijo se reporta
# desnudo. NO se inventa una glosa por parecerse a lo que uno sabe.
#
# CONTROL NEGATIVO DECLARADO ANTES DE CORRER (§2 y catalogo de fuentes §1.1):
#   (a) una OPERACION fabricada contra un servicio .asmx real debe fallar (500);
#   (b) un SERVICIO fabricado debe devolver el catch-all de 1286 bytes, con md5
#       identico al de otro nombre fabricado. Si dos nombres inventados devuelven
#       md5 distinto y con contenido util, el sondeo no discrimina y no vale.
#   (c) una ruta fabricada en www.camara.cl debe devolver 404 o una pagina de
#       error, no un catalogo.
# Umbral: si (a), (b) o (c) devuelven contenido plausible, esta fase se anula.
# =============================================================================

RAIZ <- "/Users/tomgc/Projects/transparencia_legislativa_chile"
setwd(RAIZ)
source("10_utils/10_locale.R"); asegurar_locale_utf8("50_sondeo_p92_f2.R")
source("50_documentacion/andamios/50_sondeo_p92_http.R")
suppressPackageStartupMessages({ library(httr); library(xml2) })
MU <- "50_documentacion/andamios/muestras/p92"
dir.create(MU, showWarnings = FALSE, recursive = TRUE)
sep <- function(t) cat("\n", strrep("=", 74), "\n", t, "\n", strrep("=", 74), "\n", sep = "")

BASE_WS <- "https://opendata.camara.cl/camaradiputados/WServices"

# --- F2.0 CONTROLES NEGATIVOS (primero: si fallan, nada de lo que sigue vale) -
sep("F2.0  CONTROLES NEGATIVOS  (declarados arriba, corridos antes que el sondeo)")
cn1 <- p92_http(paste0(BASE_WS, "/WSLegislativo.asmx/retornarCatalogoSufijosBoletin"),
                "CN-a op fabricada en servicio real", guardar = file.path(MU, "cn_a_op_fabricada.txt"))
cn2 <- p92_http(paste0(BASE_WS, "/WSBoletines.asmx/retornarSufijos"),
                "CN-b servicio fabricado 1", guardar = file.path(MU, "cn_b1.html"))
cn3 <- p92_http(paste0(BASE_WS, "/WSNomenclatura.asmx/retornarCodigos"),
                "CN-b servicio fabricado 2", guardar = file.path(MU, "cn_b2.html"))
cn4 <- p92_http("https://www.camara.cl/legislacion/catalogo_sufijos_boletin_inventado.aspx",
                "CN-c ruta fabricada en camara.cl", guardar = file.path(MU, "cn_c.html"))
cat("\n  Veredicto de los controles negativos:\n")
cat(sprintf("    (a) operacion fabricada  : status=%s bytes=%s  -> %s\n", cn1$status, cn1$bytes,
            ifelse(!is.na(cn1$status) && cn1$status >= 400, "DISCRIMINA (falla como debe)",
                   "REVISAR: devolvio 2xx")))
cat(sprintf("    (b) servicios fabricados : md5_1=%s md5_2=%s -> %s\n",
            substr(cn2$md5, 1, 8), substr(cn3$md5, 1, 8),
            ifelse(identical(cn2$md5, cn3$md5), "DISCRIMINA (catch-all identico, ver catalogo §1.1)",
                   "REVISAR: md5 distintos")))
cat(sprintf("    (c) ruta fabricada web   : status=%s bytes=%s\n", cn4$status, cn4$bytes))
if (!is.na(cn2$status) && cn2$status == 200)
  cat("    NOTA: (b) devuelve 200 igual que un servicio real. Confirma que el status\n",
      "    no prueba existencia: la prueba es el md5 contra el catch-all.\n", sep = "")

# --- F2.1 catalogos de la propia API ----------------------------------------
sep("F2.1  CATALOGOS DE LA API  (mapa: 50_catalogo_fuentes_camara.md §3)")
ops <- list(
  c("WSLegislativo.asmx/retornarTramitesConstitucionales", "tramites constitucionales"),
  c("WSLegislativo.asmx/retornarTramitesReglamentarios",   "tramites reglamentarios"),
  c("WSComision.asmx/retornarComisionesVigentes",          "comisiones vigentes"),
  c("WSComision.asmx/retornarComisionesXPeriodo?prmPeriodoId=11", "comisiones periodo 11"),
  c("WSComision.asmx/retornarComisionesXPeriodo?prmPeriodoId=10", "comisiones periodo 10")
)
res_ops <- list()
for (o in ops) {
  arch <- file.path(MU, paste0(gsub("[^A-Za-z0-9]", "_", o[2]), ".xml"))
  r <- p92_http(paste0(BASE_WS, "/", o[1]), o[2], guardar = arch)
  res_ops[[o[2]]] <- r
  if (!is.na(r$status) && r$status == 200 && !is.na(r$texto)) {
    x <- tryCatch(read_xml(r$texto), error = function(e) NULL)
    if (!is.null(x)) {
      hijos <- xml_children(x)
      cat(sprintf("        -> raiz <%s>, %d hijos. Nombres de campo: %s\n",
                  xml_name(x), length(hijos),
                  paste(unique(xml_name(xml_children(hijos[[1]]))), collapse = ", ")))
      # buscar cualquier campo cuyo valor sea un entero de 1-2 digitos == sufijo
      if (length(hijos)) {
        muestra <- utils::head(hijos, 6)
        for (h in muestra)
          cat("           | ", paste(sprintf("%s=%s", xml_name(xml_children(h)),
                substr(xml_text(xml_children(h)), 1, 46)), collapse = " ; "), "\n")
      }
    }
  }
}

# --- F2.2 catalogo de materias (R1) -----------------------------------------
sep("F2.2  retornarMaterias  (R1: 8518 entradas, catalogo plano)")
rm1 <- p92_http(paste0(BASE_WS, "/WSLegislativo.asmx/retornarMaterias"), "retornarMaterias",
                guardar = file.path(MU, "retornar_materias.xml"))
if (!is.na(rm1$status) && rm1$status == 200) {
  x <- read_xml(rm1$texto)
  nodos <- xml_find_all(x, ".//*[local-name()='Materia']")
  ids <- xml_text(xml_find_first(nodos, ".//*[local-name()='Id']"))
  nom <- xml_text(xml_find_first(nodos, ".//*[local-name()='Nombre']"))
  cat(sprintf("  nodos Materia: %d ; ids unicos: %d ; nombres vacios: %d\n",
              length(nodos), length(unique(ids)), sum(!nzchar(trimws(nom)))))
  cat(sprintf("  R1 declara 8518 -> %s\n",
              ifelse(length(nodos) == 8518, "CONFIRMADO", paste0("DIFIERE (", length(nodos), ")"))))
  cat(sprintf("  ids que son enteros de 1-2 digitos (candidatos a ser el sufijo): %d\n",
              sum(grepl("^[0-9]{1,2}$", ids))))
  saveRDS(data.frame(id = ids, nombre = nom, stringsAsFactors = FALSE),
          file.path(MU, "materias.rds"))
}

# --- F2.3 padron historico (remedio medido para H5) --------------------------
sep("F2.3  retornarDiputados  (padron historico: remedio de H5)")
rd <- p92_http(paste0(BASE_WS, "/WSDiputado.asmx/retornarDiputados"), "retornarDiputados historico",
               guardar = file.path(MU, "diputados_historico.xml"))
if (!is.na(rd$status) && rd$status == 200) {
  x <- read_xml(rd$texto)
  nodos <- xml_find_all(x, ".//*[local-name()='Diputado']")
  cat(sprintf("  nodos Diputado: %d\n", length(nodos)))
  cat("  campos del primero: ", paste(xml_name(xml_children(nodos[[1]])), collapse = ", "), "\n")
}

# --- F2.4 la web: comisiones permanentes y numeracion del boletin -----------
sep("F2.4  WEB  paginas candidatas a publicar la glosa del sufijo")
urls <- c(
  "https://www.camara.cl/comisiones/comisiones.aspx"                       = "camara comisiones",
  "https://www.camara.cl/legislacion/comisiones/comisiones_permanentes.aspx"= "camara comisiones permanentes",
  "https://www.senado.cl/comisiones"                                        = "senado comisiones",
  "https://www.bcn.cl/leychile/consulta/ayuda_tramitacion"                  = "bcn ayuda tramitacion",
  "https://www.camara.cl/legislacion/proyectosdeley/proyectos_ley.aspx"     = "camara buscador proyectos"
)
for (i in seq_along(urls)) {
  arch <- file.path(MU, paste0("web_", gsub("[^A-Za-z0-9]", "_", unname(urls[i])), ".html"))
  r <- p92_http(names(urls)[i], unname(urls[i]), guardar = arch)
  if (!is.na(r$status) && r$status == 200 && !is.na(r$texto)) {
    txt <- r$texto
    # busca patrones "-07", "07 =", "Comision de X (07)" y similares
    hits <- unlist(regmatches(txt, gregexpr("[^<>]{0,60}\\b0[1-9]\\b[^<>]{0,60}", txt)))
    cat(sprintf("        -> %d caracteres. Fragmentos con un codigo 0X: %d\n", nchar(txt), length(hits)))
    if (length(hits)) for (h in utils::head(unique(trimws(hits)), 5)) cat("           ~ ", substr(h, 1, 110), "\n")
  }
}

p92_reporte_presupuesto()
