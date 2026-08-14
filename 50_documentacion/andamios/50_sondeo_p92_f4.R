# =============================================================================
# 50_sondeo_p92_f4.R  --  P-92, F4: vias 3 y 4, clasificacion propia sobre texto
# -----------------------------------------------------------------------------
# VIA 3: clasifica el TITULO DEL PROYECTO.
# VIA 4: clasifica el TEXTO DE LA VOTACION. Se miden por separado.
#
# EL LEXICO DE ABAJO NO ES UNA TAXONOMIA PROPUESTA. Es un instrumento de
# medicion, escrito para responder "se puede clasificar esto?" y nada mas. La
# clasificacion tematica del portal es autoridad del titular (§2 del encargo).
#
# CONTROL DE SOBREAJUSTE: el 20 % del universo se aparta ANTES (semilla 92) y no
# se mira hasta el final. Declaracion honesta de contaminacion: durante F0 y F1
# quedaron a la vista ~30 titulos (los 5 del patron de oro y sus hermanos de
# sufijo). El lexico se escribio con vocabulario legislativo general, no
# ajustado a titulo alguno, pero la contaminacion existe y se declara.
# CERO red.
# =============================================================================

RAIZ <- "/Users/tomgc/Projects/transparencia_legislativa_chile"
setwd(RAIZ)
source("10_utils/10_locale.R"); asegurar_locale_utf8("50_sondeo_p92_f4.R")
source("50_documentacion/andamios/50_fusible_red.R"); instalar_fusible_red(silencioso = TRUE)
suppressPackageStartupMessages(library(dplyr))
set.seed(92)
sep <- function(t) cat("\n", strrep("=", 74), "\n", t, "\n", strrep("=", 74), "\n", sep = "")
frac <- function(n, d, etq) cat(sprintf("  %-54s %6d / %-6d  (%6.2f %%)\n", etq, n, d, 100 * n / d))

# --- LEXICO DE PRUEBA (12 temas gruesos, sin tildes) -------------------------
LEXICO <- list(
  seguridad_delito = c("delito","delitos","delictual","penal","penales","pena","penas","seguridad",
    "carabineros","policia","policial","investigaciones","robo","robos","hurto","narcotrafico",
    "droga","drogas","arma","armas","crimen","criminal","homicidio","secuestro","receptacion",
    "prision","carcel","carceles","penitenciario","reincidencia","terrorismo","extorsion","sicariato"),
  salud = c("salud","sanitario","sanitarios","sanitaria","medico","medicos","medica","enfermedad",
    "enfermedades","farmaco","farmacos","medicamento","medicamentos","hospital","hospitales",
    "isapre","isapres","fonasa","cancer","paliativos","mental","adicciones","tabaco","alcohol",
    "vacuna","vacunacion","obstetrica","clinica","clinicas","enfermeria"),
  educacion = c("educacion","educacional","educativo","educativa","escolar","escuela","escuelas",
    "liceo","liceos","docente","docentes","profesor","profesores","estudiante","estudiantes",
    "universidad","universidades","parvularia","curricular","magisterio","matricula","establecimientos",
    "alumno","alumnos","pedagogia","cae"),
  trabajo_pensiones = c("trabajo","trabajador","trabajadores","trabajadora","laboral","laborales",
    "empleo","empleador","empleadores","sueldo","salario","remuneracion","remuneraciones","sindicato",
    "sindical","huelga","pension","pensiones","jubilacion","cotizacion","cotizaciones","previsional",
    "afp","feriado","jornada","despido","indemnizacion","subcontratacion"),
  ambiente_energia = c("ambiental","ambientales","ambiente","contaminacion","contaminante","residuo",
    "residuos","reciclaje","plastico","agua","aguas","hidrico","hidricos","glaciar","glaciares",
    "bosque","bosques","biodiversidad","animal","animales","fauna","flora","clima","climatico",
    "energia","energetica","electrica","electricidad","renovable","renovables","mineria","minero",
    "minera","desalinizacion","humedal","humedales","desertificacion"),
  economia_tributos = c("tributario","tributaria","tributo","impuesto","impuestos","iva","banco",
    "bancos","bancaria","financiero","financiera","credito","creditos","deuda","deudas","consumidor",
    "consumidores","competencia","empresa","empresas","pyme","pymes","mercado","precio","precios",
    "inversion","presupuesto","hacienda","cooperativa","cooperativas","comercio","exportacion",
    "aranceles","quiebra","insolvencia","sociedades","anonimas"),
  vivienda_ciudad = c("vivienda","viviendas","habitacional","urbano","urbana","urbanismo","inmueble",
    "inmuebles","arriendo","arrendamiento","copropiedad","campamento","campamentos","suelo",
    "territorial","transporte","transportes","locomocion","vial","vialidad","trafico","transito",
    "conduccion","licencia","estacionamiento","carretera","carreteras","subsidio","construccion"),
  familia_ninez_genero = c("familia","familiar","nino","ninos","ninas","ninez","adolescente",
    "adolescentes","infancia","mujer","mujeres","genero","maternidad","paternidad","postnatal",
    "adopcion","alimentos","matrimonio","conviviente","filiacion","tuicion","embarazo","lactancia",
    "femicidio","intrafamiliar"),
  institucional_electoral = c("constitucion","constitucional","electoral","electorales","eleccion",
    "elecciones","voto","sufragio","partido","partidos","municipal","municipalidad","municipalidades",
    "regional","regionales","gobernador","alcalde","concejal","concejales","probidad","transparencia",
    "corrupcion","funcionario","funcionarios","estatuto","administrativo","congreso","camara",
    "diputados","senado","plebiscito","organica"),
  derechos_justicia = c("derechos","humanos","discriminacion","indigena","indigenas","pueblo",
    "pueblos","originarios","migracion","migrante","migrantes","extranjeria","refugiado","asilo",
    "justicia","tribunal","tribunales","procesal","judicial","juez","jueces","defensoria","victima",
    "victimas","reparacion","privacidad","datos","habeas"),
  agro_pesca_rural = c("agricola","agricolas","agricultura","rural","rurales","campesino","campesinos",
    "pesca","pesquero","pesqueros","pesquera","acuicultura","ganaderia","ganadero","forestal",
    "riego","silvoagropecuario","apicola","vitivinicola","semillas","cultivo","cultivos"),
  cultura_deporte_ciencia = c("cultura","cultural","culturales","patrimonio","patrimonial","monumento",
    "monumentos","arte","artes","artista","artistas","musica","audiovisual","deporte","deportivo",
    "deportiva","deportivas","futbol","ciencia","ciencias","tecnologia","tecnologias","innovacion",
    "digital","internet","telecomunicaciones","inteligencia","artificial","turismo")
)
cat(sprintf("LEXICO DE PRUEBA: %d temas, %d terminos en total, %d terminos repetidos entre temas.\n",
            length(LEXICO), length(unlist(LEXICO)),
            sum(duplicated(unlist(LEXICO)))))

norm <- function(x) {
  x <- tolower(x); x <- iconv(x, "UTF-8", "ASCII//TRANSLIT")
  x <- gsub("[^a-z0-9 ]", " ", x); trimws(gsub("\\s+", " ", x))
}
clasificar <- function(textos) {
  tk <- strsplit(norm(textos), " ")
  t(vapply(tk, function(v) vapply(LEXICO, function(term) any(v %in% term), logical(1)),
           logical(length(LEXICO))))
}

pd <- readRDS("40_salidas/intermedios/proyectos_detalle.rds")
vo <- readRDS("40_salidas/intermedios/votos.rds")
N  <- nrow(pd)

# --- APARTADO (antes de mirar nada) -----------------------------------------
sep("F4.0  APARTADO DE SOBREAJUSTE  (semilla 92, 20 % del universo)")
idx_ap <- sample(seq_len(N), round(0.20 * N))
pd$apartado <- FALSE; pd$apartado[idx_ap] <- TRUE
frac(sum(pd$apartado), N, "boletines apartados")
frac(sum(!pd$apartado), N, "boletines de trabajo")

# --- F4.1 cobertura de TEXTO disponible por via ------------------------------
sep("F4.1  cobertura de TEXTO DISPONIBLE, por via, con denominador")
frac(sum(!is.na(pd$nombre) & nzchar(trimws(pd$nombre))), N, "VIA 3: proyectos con titulo no vacio")
vu <- vo |> distinct(votacion_id, .keep_all = TRUE)
NV <- nrow(vu)
con_bol <- !is.na(vu$boletin) & nzchar(trimws(vu$boletin))
frac(sum(!is.na(vu$descripcion) & nzchar(trimws(vu$descripcion))), NV,
     "VIA 4: votaciones con 'descripcion' no vacia")
cat("\n  PERO 'descripcion' es una ETIQUETA, no texto tematico. Recuento:\n")
es_etiqueta <- grepl("^\\s*(Bolet[ií]n\\s*N|Proyecto de (Resoluci[oó]n|Acuerdo)\\s*N|[0-9]+-Otros)",
                     vu$descripcion, perl = TRUE)
frac(sum(es_etiqueta), NV, "  descripciones que son solo 'Boletin N X' / 'Proy. Res. N X'")
frac(sum(!es_etiqueta), NV, "  descripciones con cualquier otra forma")
cat("  las que NO son etiqueta, una por una:\n")
for (s in unique(vu$descripcion[!es_etiqueta])) cat("    | ", s, "\n")
cat(sprintf("\n  descripciones distintas: %d sobre %d votaciones (una etiqueta por votacion)\n",
            n_distinct(vu$descripcion), NV))
# el otro candidato de texto: el nodo Votaciones (P-63)
tiene <- vapply(pd$votaciones, function(x) is.data.frame(x) && nrow(x) > 0, logical(1))
VOTX <- bind_rows(lapply(which(tiene), function(i) { d <- pd$votaciones[[i]]; d$boletin <- pd$boletin[i]; d }))
cat("\n  candidato alternativo para la via 4: campo 'articulo' del nodo Votaciones (P-63)\n")
frac(sum(!is.na(VOTX$articulo) & nzchar(trimws(VOTX$articulo))), nrow(VOTX),
     "  filas del nodo con 'articulo' no vacio")
en_universo <- VOTX$votacion_id %in% vu$votacion_id
frac(sum(en_universo), nrow(VOTX), "  filas del nodo que estan en el universo de votos")
sin_bol_ids <- vu$votacion_id[!con_bol]
frac(sum(VOTX$votacion_id %in% sin_bol_ids), length(sin_bol_ids),
     "  votaciones SIN boletin cubiertas por el nodo Votaciones")
cat("\n  >> VEREDICTO DE INSUMO PARA LA VIA 4: el unico texto por votacion que\n",
    "     existe es 'articulo', y solo alcanza a votaciones CON boletin, que es\n",
    "     justo donde la via 3 ya llega. Para las ", sum(!con_bol), " votaciones SIN boletin\n",
    "     el texto disponible es la etiqueta 'Proyecto de Resolucion N X', que no\n",
    "     contiene tema alguno. H4 pasa la letra y falla la sustancia.\n", sep = "")

# --- F4.2 VIA 3: clasificacion del titulo del proyecto -----------------------
sep("F4.2  VIA 3  clasificacion del titulo del proyecto")
M3 <- clasificar(pd$nombre)
pd$n_temas <- rowSums(M3)
medir <- function(sel, etq) {
  d <- sum(sel)
  cat(sprintf("\n  --- %s (denominador %d) ---\n", etq, d))
  frac(sum(pd$n_temas[sel] >= 1), d, "cae en al menos un tema")
  frac(sum(pd$n_temas[sel] >  1), d, "cae en mas de un tema (ambiguedad)")
  frac(sum(pd$n_temas[sel] == 0), d, "no cae en ningun tema")
  invisible(mean(pd$n_temas[sel] >= 1))
}
c_tot <- medir(rep(TRUE, N), "UNIVERSO COMPLETO")
c_tra <- medir(!pd$apartado, "CONJUNTO DE TRABAJO (80 %)")
c_apa <- medir(pd$apartado,  "APARTADO (20 %) - control de sobreajuste")
cat(sprintf("\n  CONTROL DE SOBREAJUSTE: cobertura trabajo %.2f %% vs apartado %.2f %%; brecha %.2f pp\n",
            100 * c_tra, 100 * c_apa, 100 * (c_tra - c_apa)))
cat(sprintf("  Umbral declarado: brecha > 10 pp = lexico ajustado a lo visto -> %s\n",
            ifelse(abs(c_tra - c_apa) > 0.10, "SOSPECHA DE SOBREAJUSTE", "SIN SOBREAJUSTE DETECTABLE")))
cat("\n  reparto por tema (un proyecto puede estar en varios):\n")
rep3 <- data.frame(tema = colnames(M3), n = colSums(M3)) |>
  mutate(pct = round(100 * n / N, 2)) |> arrange(desc(n))
print(as.data.frame(rep3), row.names = FALSE)
cat("\n  10 titulos que NO cayeron en ningun tema:\n")
for (s in utils::head(pd$nombre[pd$n_temas == 0], 10)) cat("    | ", substr(s, 1, 130), "\n")

# --- F4.3 control positivo de la via 3 --------------------------------------
sep("F4.3  CONTROL POSITIVO VIA 3  (umbral declarado ANTES: 4 de 5)")
n_mat <- vapply(pd$materias, function(m) if (is.data.frame(m)) nrow(m) else 0L, integer(1))
oro <- which(n_mat > 0)
for (i in oro) {
  temas <- colnames(M3)[M3[i, ]]
  m <- pd$materias[[i]]
  cat(sprintf("\n  %s (sufijo %s, apartado=%s)\n    titulo  : %s\n    materia : %s\n    temas   : %s\n",
              pd$boletin[i], sub("^[0-9]+-", "", pd$boletin[i]), pd$apartado[i],
              substr(pd$nombre[i], 1, 150), paste(m$nombre, collapse = " ; "),
              ifelse(length(temas), paste(temas, collapse = ", "), "(ninguno)")))
}

# --- F4.4 VIA 4: clasificacion del texto de la votacion ---------------------
sep("F4.4  VIA 4  clasificacion del texto de la votacion")
cat("  Se mide sobre los dos textos disponibles, por separado:\n")
# 4a: descripcion de votos.rds
M4a <- clasificar(vu$descripcion)
n4a <- rowSums(M4a)
frac(sum(n4a >= 1), NV, "4a 'descripcion': votaciones que caen en algun tema")
frac(sum(n4a >= 1 & !con_bol), sum(!con_bol), "4a  ... entre las SIN boletin")
# 4b: articulo del nodo Votaciones
VX <- VOTX |> filter(!is.na(articulo), nzchar(trimws(articulo)))
M4b <- clasificar(VX$articulo)
n4b <- rowSums(M4b)
frac(sum(n4b >= 1), nrow(VX), "4b 'articulo': filas con articulo que caen en algun tema")
frac(sum(n4b >  1), nrow(VX), "4b  ... en mas de uno (ambiguedad)")
frac(sum(n4b == 0), nrow(VX), "4b  ... en ninguno")
frac(nrow(VX), NV, "4b cobertura de 'articulo' sobre el universo de votaciones")
frac(0L, sum(!con_bol), "4b cobertura sobre votaciones SIN boletin (por construccion)")
cat("\n  10 'articulo' que NO cayeron en ningun tema:\n")
for (s in utils::head(VX$articulo[n4b == 0], 10)) cat("    | ", substr(s, 1, 120), "\n")

saveRDS(list(M3 = M3, temas = colnames(M3), pd_apartado = pd$apartado,
             pd_n_temas = pd$n_temas, boletin = pd$boletin, lexico = LEXICO),
        "50_documentacion/andamios/muestras/p92_f4.rds")
cat("\nF4 terminada sin red.\n")
