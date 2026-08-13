# Traspaso de cierre — v17

## 1. Identificación

- **Proyecto:** `transparencia_legislativa_chile`
- **Versión:** v17
- **Fecha:** 2026-08-08
- **Sesión:** 17. Foco: rescatar el nodo `Votaciones` que el paso 36 descartaba
  (P-63), previo rediseño de su caché para que la carpeta de dato crudo contenga
  dato crudo; merge a producción y medición de la llave directa voto ↔ proyecto.
- **Entorno:** R 4.5.2 en Positron sobre macOS; `gh` y `git` por CLI; ejecución
  autónoma delegada a Claude Code.
- **Archivos principales modificados:** `10_utils/10_utils.R`,
  `36_extraer_detalle_proyectos.R`.
- **Protocolo vigente:** `POLITICA_PROYECTO.md` v5.6,
  `SETTINGS_Y_PROMPTS_OPERACIONALES.md` v16 (verificados contra la knowledge base
  del Project al abrir; sin delta respecto de lo citado en v16).

## 2. Resumen ejecutivo

La sesión abrió con P-63 caracterizado como trabajo barato: conservar un nodo que
la API ya entrega y que el parser tiraba, con cero llamadas nuevas. La lectura de
`10_utils.R` y `36_extraer_detalle_proyectos.R` refutó esa premisa antes de
escribir una línea: `con_cache()` persiste el retorno de la función de descarga, y
en el 36 ese retorno ya es el tibble parseado, así que el XML nunca tocaba disco y
rescatar cualquier campo nuevo obligaba a volver a la red. El hallazgo de fondo no
fue el costo sino lo que implicaba: la guarda de autorregeneración que la sesión 16
había instalado prometía regenerar sin red algo que, para el paso 36, solo podía
reproducir con los campos que el parser de ese día decidió conservar. El titular
optó por arreglar la premisa antes de usarla, al mismo precio que ignorarla. Se
ejecutó un encargo autónomo con seis compuertas de precondición, doce criterios y
panel adversarial de cuatro: la captura pasó a ser XML crudo bajo clave propia, el
parser se extendió de forma aditiva a los catorce campos reales del nodo (el
traspaso anterior hipotetizaba cuatro), y el artefacto público quedó idéntico en
156 de 156 archivos excluido el campo volátil. El PR #7 se mergeó y `main` quedó en
`17af73c`. Una medición posterior, hecha por desconfianza ante dos cifras
demasiado redondas, resultó ser el hallazgo más valioso de la sesión: el `Id` de
votación del nodo particiona exactamente el universo de votaciones, lo que da a
P-66 una llave directa donde hoy hay una extracción por expresión regular sobre
texto libre. Quedan encendidos los dos gatillos de protocolo heredados y un
pendiente nuevo que nadie había visto: el nodo rescatado crece con el tiempo, y el
sello valida el corte declarado, no el contenido.

## 3. Estado al cierre

**Qué funciona.** `run_all()` completo, sin error, en 12,4 s tras el merge, con
`camara.refrescar = FALSE`; `validar_corte()` pasa 6 de 6 al corte `2026-08-03`
(fuente: corrida de verificación de la tarea 2, reportada por Claude Code). El
pipeline regenera los seis intermedios desde captura versionada sin una sola
llamada HTTP: 0 intentos contados con la red cortada, `run_all()` en 13,6 s desde
los seis intermedios borrados (fuente: criterio C7 del encargo P-63).

**Qué no funciona.** Nada reportado como roto. **0 bugs activos al cierre.**

**Estado del repositorio.** `main` local y remoto en `17af73c`, merge commit de dos
padres (`2cd04cd` + `eb22373`), fast-forward limpio; PR #7 en estado MERGED con
`mergedAt` no nulo (fuente: comandos `git`/`gh` ejecutados por Claude Code en la
tarea 2 de esta sesión). `CORTE_FECHA <- "2026-08-03"`
(`10_utils/10_configuracion.R:41`) y `ANIO_PROCESO <- 2026L` (`:27`), sin cambios
en la sesión: el último commit que tocó ese archivo es `5633db3` del 2026-08-03.
`git status` acotado a `docs/`: 0 líneas.

> **Nota de formato, no de estado (ver aprendizaje A69).** Este campo declara el
> hash de `main` en el momento de escribir el traspaso, y el acto de commitear el
> traspaso lo mueve. El hash real al abrir la sesión 18 será el hijo de `17af73c`,
> no `17af73c`. No es un error del cierre: es una limitación del formato,
> registrada como pendiente P-75. Verifica siempre con
> `git -C <raiz> log --oneline -5 origin/main` antes de afirmar nada.

**Delta respecto de v16.** El paso 36 dejó de guardar un derivado del parser en la
carpeta de dato crudo. `proyectos_detalle.rds` pasó de 5 a 20 columnas. Apareció
una captura nueva, `20_insumos/camara/20260803_detalle_proyectos_xml_2026_tope-inf.rds`,
de 129,39 K (fuente: `estructura_actual.md` del 2026-08-08 14:59:22, línea 55). El
eje temático sigue con veredicto NO y sin cambios; lo que cambió es la trazabilidad
voto ↔ proyecto, que pasó de depender de un regex a tener llave directa medida.

## 4. Registro detallado de cambios

### 4.1 Refutación de la premisa de P-63 y elección de la vía

**Archivos:** ninguno (análisis). **Categoría:** diagnóstico/exploración.

`con_cache()` (`10_utils.R:228-240`) persiste el retorno de `fn_descarga()`, y
`extraer_detalle()` del 36 (`36:69-104`) devuelve el tibble ya parseado. El XML
nunca se persiste, de modo que "cero llamadas nuevas" era falso y, más importante,
`20_insumos/camara/*detalle_proyectos*` no era captura cruda sino derivado del
parser. Se ofrecieron tres vías al titular (ejecutar P-63 pagando la descarga; o
arreglar primero la captura y luego P-63; o diferir a P-68) y se recomendó la
segunda: una sola descarga paga las dos cosas y vuelve verdadera la premisa que la
guarda de P-65 ya asumía. **Por qué (C.11):** una guarda que promete regenerar sin
red y no puede cumplirlo para uno de sus pasos es una falsa garantía, y la sesión
16 se cerró creyendo que esa garantía existía. **Verificado (B.4):** por lectura
directa de las dos funciones, citadas con línea.

### 4.2 Encargo autónomo con compuertas de precondición

**Archivo:** `50_documentacion/andamios/50_encargo_p63_captura_xml_y_nodo_votaciones.md`
(17,70 K; fuente: `estructura_actual.md` línea 2723). **Categoría:** documentación.

Estructura de meta, invariantes, compuertas, objetivos, criterios contrastables y
panel adversarial. Dos rasgos nuevos respecto de encargos anteriores. Primero, un
§0 que separa explícitamente lo respaldado por lectura de esta sesión de lo que es
hipótesis heredada, y prohíbe al cuerpo del encargo afirmar nada que no esté en la
tabla: es la aplicación del contrato positivo que la nota de patrón de v16 dejó
redactada para P-54, adelantada antes de que la política la incorpore. Segundo, un
punto de autorización único con umbral objetivo (2 MB por corte) en vez de una
pausa a discreción. **Verificado (B.4):** las seis compuertas se respondieron con
archivo y línea antes de tocar código; ninguna quedó supuesta.

### 4.3 Captura genuinamente cruda para el paso 36

**Archivos:** `10_utils/10_utils.R`, `36_extraer_detalle_proyectos.R`.
**Categoría:** extracción de datos.

El 36 persiste el XML de respuesta como `character` bajo clave nueva
(`detalle_proyectos_xml_<anio>`, `tope = Inf`) y deriva el tibble desde esa
captura. La clave es nueva y no reutiliza la anterior porque el contenido cambia de
forma, y la doctrina del propio proyecto (`10_utils.R:174-179`) exige que la clave
codifique todo parámetro que altere lo cacheado. `capturas_crudas_de_paso("36")` y
el `hash_origen_de()` del sello apuntan a la captura nueva. La captura anterior
quedó intacta: 43 de 43 md5 idénticos, 0 renombrados. **Por qué (C.11):**
reparsear con un parser distinto ya no necesita red, que era la promesa incumplida.
**Verificado (B.4):** C1 381 de 381 con XML no vacío; C2 43 de 43 md5 iguales; C3
10 de 10 reparseables desde el `.rds` releído; C7 0 intentos HTTP con los seis
intermedios borrados. **Dependencias afectadas:** la guarda de `00_run_all.R:84`
ahora apunta a una captura que sí puede cumplir su promesa.

### 4.4 El parser deja de descartar `Votaciones`

**Archivo:** `10_utils/10_utils.R` (`parsear_contenido_proyecto()`, antes en
`:405-418`). **Categoría:** extracción de datos.

Extensión aditiva: lo que la función ya devolvía no cambió de forma ni de valores.
El nodo trae **14 campos reales**, no los 4 que hipotetizaba v16 (los 4 existen y
son subconjunto). Seis de los 14 llevan atributo de dominio y se conservan con
código y glosa, siguiendo el patrón `attr_nodo()` + `texto_nodo()` que ya usan el
33 y el 34. El `Id` de votación se trata como llave (`como_llave()`, character).
Cardinalidad N votaciones por boletín, así que van como list-col replicando el
patrón de `materias`, más `n_votaciones` escalar: el intermedio mantiene una fila
por boletín. **Verificado (B.4):** C5 esquema de 20 columnas en 381 de 381; C4 0
diferencias en las 5 columnas previas sobre 381 boletines comunes; C6 nodo no vacío
en 115 de 115 boletines votados y 0 de 266 solo autorados, 723 nodos de votación en
total, `articulo` no vacío en 619 de 723. **Tensión entre principios:** B.1
(coherencia del contrato) contra C.11 (estabilidad para terceros) se resolvió por
neutralidad demostrada, no por argumento: C9 dio 156 de 156 artefactos idénticos
excluido `metadatos.generado`, y 0 claves nuevas en el JSON público.

### 4.5 Merge a producción y verificación post-merge

**Archivos:** ninguno del pipeline. **Categoría:** integración/repo.

Antes del merge se zanjó una contradicción de estado: v16 declaraba `main` en
`f1584b8` y el ejecutor reportaba `2cd04cd`. Ninguna era falsa: `f1584b8` es
ancestro de `2cd04cd` a exactamente 1 commit, y el commit que los separa es el que
agregó el propio `traspaso_cierre_v16.md`. Merge del PR #7 por la misma vía que el
repositorio ya usaba en el #6. **Verificado (B.4):** `run_all()` 12,4 s sin error;
`validar_corte()` 6 de 6; `docs/` 0 líneas; `CORTE_FECHA` sin cambios.

### 4.6 Medición de la llave directa voto ↔ proyecto (insumo de P-66, no implementado)

**Archivos:** ninguno. **Categoría:** diagnóstico/exploración.

El ejecutor reportó 546 nodos presentes en `votos.rds` y 245 solo en `votos.rds`.
Esas dos cifras son exactamente el denominador de D26 y su complemento, lo que era
demasiado redondo para ser coincidencia; se pidió medirlo desde el otro lado.
Resultó identidad de conjuntos, no coincidencia: filas con boletín no nulo cuyo
`votacion_id` está en el nodo, 84 630 de 84 630; con boletín nulo, 0 de 37 975; por
votación distinta, 546 de 546 de tipo `Proyecto de Ley` y 0 de 245 del resto
(`Otros` 0 de 117, `Proyecto de Resolución` 0 de 105, `Proyecto de Acuerdo` 0 de
23). `setequal()` verdadero en ambos sentidos. El boletín obtenido por llave
coincide con el extraído por regex en 546 de 546, 0 discrepancias. **Por qué
importa (C.11):** el regex de `34_extraer_votaciones.R:26-29` no está fallando hoy;
lo que se elimina es su dependencia del formato del texto libre, que es la zona
frágil 2 declarada en v16 §11.2. **No implementado**, por invariante del encargo.

## 5. Backlog acumulativo

Archivo canónico: `50_documentacion/activa/backlog_acumulativo.md`, actualizado en
este cierre. **2 entradas nuevas (51 y 52).** Conteos actualizados: extracción de
datos 6 → 7, diagnóstico/exploración 10 → 11. Suma de la columna 51 → 53,
porcentajes recalculados sobre 53 (suman 100,1 por redondeo a un decimal). Sin
categorías nuevas, sin renumeración ni reescritura de entradas 1-50. Verificación
programática del archivo antes de editarlo: 50 entradas numeradas, rango 1-50, 0
duplicadas, 0 huecos (fuente: `conteo_cierre_v17.R` ejecutado en esta sesión). La
discrepancia heredada sigue abierta con el mismo signo y la misma unidad (columna
53, entradas 52).

## 6. Bugs de la sesión

Ninguno. **0 bugs de código detectados y 0 activos al cierre.**

Un falso positivo de instrumento, que no es bug del artefacto: el primer chequeo
del invariante de neutralidad buscaba colisión de nombre de clave y marcó
`n_votaciones`, que existía en el bloque `votaciones` del perfil desde la sesión 1
(`39:323`) y no tiene relación con la columna nueva del intermedio. El artefacto
nunca estuvo mal; el test sí, y se reescribió para comparar el conjunto de rutas de
clave contra `HEAD`. Se registra aquí porque un instrumento que marca CUMPLE o NO
CUMPLE por la razón equivocada es la mitad benigna de PAT-02: esta vez falló hacia
el lado ruidoso.

## 7. Aprendizajes y restricciones

- **A66 — Una carpeta de dato crudo que recibe el retorno de un parser contiene un
  derivado, no un crudo.** `con_cache()` es genérico y cachea lo que la función le
  dé; la decisión de qué es "crudo" la toma, sin declararlo, cada llamador. El 32 a
  35 cachean respuestas; el 36 cacheaba un tibble. Nada en el nombre de la carpeta
  ni en la firma de la función delata la diferencia.
- **A67 — El sello valida el corte declarado, no el contenido.** Un campo con
  eventos posteriores al corte pasa `validar_corte()` sin ruido en 6 de 6. La
  captura del corte `20260803` se descargó el 08-08 y contiene una votación del
  08-04. Hoy no daña porque nadie lo consume; es precondición de P-66.
- **A68 — El nodo `Votaciones` particiona exactamente el universo de votaciones.**
  Su intersección con `votos.rds` es el conjunto de votaciones tipo `Proyecto de
  Ley` y su complemento es el resto, verificado con `setequal()` en ambos sentidos,
  porque las votaciones de acuerdo y resolución no cuelgan de ningún boletín.
- **A69 — Un traspaso no puede citar el hash de su propio commit.** El campo "main
  en X" del §3 es estructuralmente incitable: el acto de commitear el traspaso mueve
  `main`. Llega siempre desactualizado en exactamente 1 commit, y "0 PRs abiertos"
  tiene el mismo defecto con peor cara, porque parece verificable.
- **A70 — Un comentario de código es fuente secundaria.** `10_utils.R:403`
  declaraba `parsear_contenido_proyecto()` "compartido por 35 y 36"; el barrido de
  24 archivos encontró 1 definición y 1 sola invocación real, en el 36. El
  comentario quedó corregido, pero el aprendizaje es que un comentario no releva de
  leer al consumidor.
- **A71 — Una cifra sospechosamente redonda merece medición, no confirmación.** Dos
  números que coincidían con un denominador conocido resultaron ser el mismo
  conjunto, y medirlo desde el otro lado convirtió una coincidencia en un teorema
  utilizable. La sospecha barata pagó el hallazgo más valioso de la sesión.

## 8. Decisiones de arquitectura

- **D27.** La captura del paso 36 es el XML de respuesta tal cual, bajo clave propia
  `detalle_proyectos_xml_<anio>`. La captura anterior no se sobrescribe ni se
  retira: convive como artefacto histórico del corte.
- **D28.** `proyectos_detalle.rds` mantiene **una fila por boletín**. Las votaciones
  viajan como list-col más un escalar `n_votaciones`; no se expande a formato largo
  en este intermedio.
- **D29.** Los campos con atributo de dominio se conservan con **código y glosa**,
  nunca solo uno de los dos, siguiendo el patrón ya establecido en 33 y 34.
- **D30.** El cruce voto ↔ proyecto por `votacion_id` queda **medido y no
  implementado** en esta sesión. Su implementación es parte de P-66 y requiere
  antes resolver P-74.

## 9. Estado de datos y artefactos

`CORTE_FECHA = 2026-08-03` (`10_utils/10_configuracion.R:41`). Seis intermedios
sellados y validados 6 de 6. 156 artefactos JSON en `40_salidas/json/`, espejados
en `docs/data`, idénticos a los publicados excluido `metadatos.generado`. Captura
cruda nueva de 129,39 K, un 6,3 % del umbral de 2 MB fijado en el encargo.
Universo de boletines contado: 272 autorados, 115 votados, 381 en unión, 6 en
intersección (fuente: compuerta G5 del encargo). 723 nodos de votación extraídos.

## 10. Estructura de archivos

Escáner del 2026-08-08 14:59:22: 26 carpetas, 2894 archivos. Respecto del escáner
de apertura (08:22:56, 2890 archivos), 4 archivos nuevos: la captura XML, el
encargo, su log de ejecución y el propio escáner. Sin movimientos de carpeta.

## 11. Pendientes, deuda técnica y ruta

### 11.1 Inventario

| ID | Pendiente | Estado |
|---|---|---|
| P-63 | Rescatar el nodo `Votaciones` | **CERRADO** en esta sesión |
| P-74 | **NUEVO.** El nodo `Votaciones` crece con el tiempo y el sello no lo detecta. Decidir el contrato temporal (¿se filtra por corte al derivar? ¿el corte pasa a ser una propiedad del contenido?) antes de que P-66 lo consuma | Abierto, precondición de P-66 |
| P-75 | **NUEVO.** El §3 del traspaso pide un dato estructuralmente incitable (hash del propio commit) y "0 PRs abiertos" con el mismo defecto. Reformular el campo para que declare lo que sí es verdadero al escribirlo | Abierto, gobernanza |
| P-68 | Sondear LeyChile y `datos.bcn.cl` como fuente temática alternativa | Abierto, foco propuesto |
| P-66 | Construir la entidad `proyecto` con tramitación | Abierto, ahora con llave directa disponible |
| P-59 | Guarda de locale UTF-8 (gatillo 4ter) | Abierto desde la sesión 15 |
| P-60 | Ordenación del repositorio (gatillo 4bis) | Abierto desde la sesión 15 |
| P-57 | `CODIGOS_JUSTIFICACION_OBSERVADOS` fuera de `10_configuracion.R` | Abierto |
| P-67, P-69 a P-73 | Senado, llave compuesta, diff de conteos, y resto del lote de P-61 | Abiertos |
| P2 | Semántica de `RebajaAsistencia` / `RebajaQuorum` | Abierto; cerrado como NO por la vía de la API en v16 |
| P-49 a P-54 | Gobernanza de patrones de error | Abiertos; P-54 parcialmente aplicado de hecho en el §0 del encargo |

### 11.2 Zonas frágiles

1. **`retornarProyectoLey` sigue siendo punto único de falla** y su descriptor es
   intermitente. Ahora, además, es la única fuente de un campo que crece.
2. **La extracción por regex del boletín** (`34:26-29`) tiene reemplazo estructural
   disponible y medido (546 de 546, 0 discrepancias). Deja de ser frágil el día que
   P-66 use la llave.
3. **El contrato temporal del nodo** (P-74). Es la zona frágil nueva y la única que
   esta sesión creó.

### 11.3 Auditoría de cierre (política 5.6)

Preguntas 1, 2 y 8: sí, sin cambios. Pregunta 3: parcial, P-57 sigue abierto.
Pregunta 4: no, P-60 sigue abierto y el escáner nuevo lo confirma sin cambios.
Ambos ya son pendientes; no se agregan duplicados.

### 11.4 Ruta sugerida para la sesión 18

1. **P-74**, contrato temporal del nodo. Complejidad baja, es precondición de P-66
   y es deuda que esta sesión creó. Criterio: queda decidido y documentado si el
   corte filtra el contenido derivado o si el sello pasa a validar contenido.
2. **P-68**, sondeo de LeyChile. Complejidad media. Es lo único que puede dar vuelta
   el veredicto del eje temático. Criterio: veredicto cerrado con denominador
   declarado, más reproductor que no persista respuestas no-200.
3. **P-59**, locale UTF-8. Complejidad baja, gatillo encendido desde la sesión 15.

**Diferir:** P-66 hasta que P-74 y P-68 estén resueltos, porque su contrato depende
de ambos. P-60 sigue ofrecido y sigue sin recomendarse: mueve muchos archivos y
compite mal con trabajo de datos.

## 12. Instrucciones específicas para la próxima sesión

- ⚠️ **NO** consumir el nodo `Votaciones` en ningún artefacto publicable antes de
  resolver P-74: contiene al menos un evento posterior al corte declarado y el
  sello no lo detecta.
- ⚠️ **NO** publicar cobertura temática sobre el denominador de 791 votaciones: el
  correcto es 546 votaciones tipo `Proyecto de Ley` (D26), ahora confirmado por
  partición exacta desde el nodo.
- ⚠️ **NO** publicar un bloque `materias` ni vista temática mientras la cobertura
  sea 5 de 381.
- ⚠️ **NO** hacer join entre Cámara y Senado por identificador numérico solo: 5
  colisiones activas, 5 de 5 personas distintas (D25).
- ⚠️ **NO** afirmar `CORTE_FECHA`, el sello de un intermedio ni el hash de `main`
  sin leerlos en el momento de afirmarlo. El §3 de este traspaso declara `main` en
  `17af73c` y ese valor caduca al commitear este archivo (A69).
- ⚠️ **NO** tratar un comentario de código como fuente sobre quién consume una
  función (A70).
- ⚠️ **NO** usar `gh pr diff --name-only`: HTTP 406 en PRs grandes. Usar `gh api`
  paginado sobre `/pulls/<n>/files` y declarar el denominador.
- ⚠️ **NO** tratar `<Materias/>` como nodo ausente: viene presente y autocerrado.
  El nodo `Votaciones` se comporta igual, confirmado en 10 de 10 boletines con
  contenedor presente y 5 de 10 con hijos.
- ⚠️ **NO** usar `senadores_vigentes.php` como padrón; la ruta confiable es
  `/api/parlamentarios?vigentes=1&limit=300` filtrando `CAMARA=="S"`.
- ⚠️ **NO** usar `/api/sessions/attendance?id_legislatura=`: devuelve un agregado
  sin dimensión de sesión. Solo `?id_sesion=` satisface D2.
- ✅ **ANTES** de calcular cualquier tasa de asistencia del Senado, aplicar la
  detección de sesiones centinela (3 de 54 devuelven las 50 filas en `Ausente`).
- ✅ **ANTES** de declarar una cobertura, declarar su denominador en la misma línea
  y contarlo programáticamente en ese turno.
- ✅ **ANTES** de commitear cualquier caché de exploración, evaluar si contiene dato
  personal (A63). El repositorio es público.
- ✅ **ANTES** de dar por entregado un artefacto, comprobar que quedó adjunto en el
  mismo turno que lo anuncia (A52).
- ✅ **ANTES** de aceptar una cifra que coincide con un denominador conocido,
  medirla desde el otro lado (A71).
- 🔒 La guarda de `00_run_all.R:84` no descarga nada y apunta a la captura XML.
- 🔒 `sellar()`, `leer_sellado()` y `validar_corte()` no se tocan.
- 🔒 Los intermedios no se versionan (D24). `20_insumos/camara/` es crudo inmutable.
- 🔒 `main` no recibe escrituras automáticas ni push directo. El bot abre PR.
- 🔒 `sin_registro` no se imputa, ni en el dato ni en la presentación.
- 🔒 El titular de asistencia del portal es `asistencia.periodo_vigente.tasa_presencia`
  (D18); el corte vive en `asistencia.alcance_temporal.corte_fecha`.
- 🔒 R es el único lenguaje, en todo contexto. Sin `jq`, `awk`, `python`, ni
  `grep`/`sed` sobre artefactos de datos; sin regex en `Rscript -e`.
- 🔒 `git` siempre con `-C <ruta absoluta>`, `gh` siempre con `-R tomgc/...`,
  `git add` siempre con ruta acotada.
- 🔒 `proyectos_detalle.rds` mantiene una fila por boletín (D28).
- 🔒 Los campos con atributo de dominio se conservan con código y glosa (D29).

## 13. Fragmentos de código de referencia

Sin patrones nuevos que no vivan ya en el código. Los dos patrones que esta sesión
consolidó (persistir XML como `character` y no como `xml_document`; conservar
código y glosa con `attr_nodo()` + `texto_nodo()`) están implementados en
`10_utils/10_utils.R` y documentados en
`50_documentacion/andamios/logs/20260808_p63_captura_xml_log.md`, que es su fuente
única. No se re-copian aquí.

## 14. Reapertura

Adjuntar al abrir: este traspaso, un escáner reciente, y
`10_utils/10_configuracion.R` si algún PR del bot se mergeó en el intervalo.

Mensaje de apertura sugerido:

> Tipo: CONTINUATION. El protocolo (`POLITICA_PROYECTO.md` v5.6,
> `SETTINGS_Y_PROMPTS_OPERACIONALES.md` v16) vive en la knowledge base del
> Project; verifica las versiones ahí antes de la Fase A. Estado: la sesión 17
> cerró P-63; el paso 36 ahora persiste XML crudo bajo clave propia y el nodo
> `Votaciones` está extraído con sus 14 campos, sin cambiar nada de lo publicado
> (156 de 156 artefactos idénticos excluido el campo volátil). Verifica el hash de
> `main` con `git log` en vez de creerle al §3 del traspaso, que caduca al
> commitearse. El foco propuesto es P-74: el nodo rescatado crece con el tiempo y
> el sello valida corte declarado, no contenido, así que hay al menos un evento
> posterior al corte pasando las seis compuertas sin ruido; es precondición de
> P-66. Encadenado: P-68, sondear LeyChile como fuente temática. Dos gatillos de
> protocolo siguen encendidos: 4bis (ordenación, P-60) y 4ter (locale UTF-8,
> P-59). Adjunto: `traspaso_cierre_v17.md`, `estructura_actual.md`.

## 15. Errores del asistente (POLITICA 0.5)

| Campo | Error 1 | Error 2 | Error 3 |
|---|---|---|---|
| `momento` | Fase C de la apertura, al proponer P-63 como prioridad 1 | Turno de presentación de las tres vías, al estimar el peso de la captura XML | Cierre de la sesión, al actualizar `backlog_acumulativo.md` con las entradas 51 y 52 |
| `disparador` | El asistente lo detectó al leer los archivos en el turno siguiente | El asistente lo señala aquí; no fue corregido por el titular | El titular lo señaló al abrir la sesión 18, al notar que la fila faltaba en este archivo |
| `que_paso` | Se afirmó la ubicación `10_utils.R:279-292` para `parsear_contenido_proyecto()` y las cifras "115 de 115" y "619 de 723" sin marcador de fuente, copiadas del traspaso v16; la ubicación resultó falsa (esas líneas son `corte_declarado_por()`; la función está en `:405-418`) | Se comunicó "~1,1 MB" como producto de una multiplicación hecha a mano (3,03 K × 381) | Se editó `backlog_acumulativo.md` con Python; la edición se revirtió y se rehízo en R, y el error no quedó registrado en el §15 de este traspaso |
| `regla_violada` | POLITICA 0.6 y SETTINGS §1.2.6 (S-01), tipos 1 y 3: ruta de archivo no leído en la sesión, y cifra comunicada | POLITICA 0.6 (S-01), tipo 3: "las cifras solo admiten como fuente un recuento programático del mismo turno; la aritmética manual no es fuente" | POLITICA 5.4 y `userPreferences` ("R es el ÚNICO lenguaje"), más el 🔒 del §12 del traspaso v16, que lo declara invariante "en todo contexto". Secundariamente POLITICA 0.5 / SETTINGS §2.2.15, regla de registro: el error se anota en el momento, no se reconstruye al cerrar |
| `causa_raiz` | El traspaso es la fuente autorizada del estado, y eso se extendió indebidamente a las rutas y cifras que el traspaso contiene: se trató un documento de cierre como si fuera el archivo que describe. La Fase C pide proponer una ruta, y proponer se sintió como un registro distinto del de afirmar, donde el marcador parecía no aplicar | El marcador `(hipótesis, verificar con: ...)` sí se puso, lo que dio sensación de cumplimiento y ocultó que el defecto no era la incertidumbre sino el método: una cifra derivada a mano no es legal ni con marcador de hipótesis | El invariante está redactado como propiedad del proyecto ("R es el único lenguaje del pipeline") y la tarea se clasificó mentalmente como manipulación de texto de un documento, no como tarea del pipeline, de modo que el invariante pareció no aplicar. El instrumento se eligió por conveniencia inmediata en un momento de cierre, que es cuando el costo hundido presiona más |
| `salvaguarda_presente` | POLITICA 0.6, SETTINGS §1.2.6, `userPreferences` (marcador de fuente) — tres documentos | POLITICA 0.6, SETTINGS §1.2.6, `userPreferences` — tres documentos | POLITICA 5.4, `userPreferences`, `CLAUDE.md` y el §12 del traspaso vigente — cuatro documentos |
| `patron` | `PAT-01`, sobre ruta de función y cifra heredada de traspaso | `PAT-01`, variante aritmética: fuente secundaria sustituida por cálculo propio no programático | `PAT-01`, variante de instrumento (etiqueta propuesta por el titular). **Pendiente de verificación contra el catálogo:** `catalogo_patrones_errores_v3.md` no está en la knowledge base del Project y no se leyó; si el catálogo define `PAT-01` estrictamente como fuente secundaria, este registro corresponde a un patrón de disciplina distinto y debe reetiquetarse |
| `gatillo_observable` | "Estoy escribiendo una ruta con número de línea, o una cifra, y no he abierto ese archivo ni ejecutado ese conteo en esta sesión" | "Estoy escribiendo un número que no salió de una ejecución de este turno" | `costo-sobre-regla`: "Estoy por ejecutar un intérprete que no es R sobre un archivo versionado del repositorio" |
| `intentos_previos` | No registrado en el momento | No registrado en el momento | 0 |
| `costo` | No registrado en el momento | No registrado en el momento | Una reversión y una reejecución del mismo cambio; 0 artefactos publicados afectados; una fila de este §15 escrita fuera de sesión |

**Nota de formato.** Los campos `intentos_previos` y `costo` faltaban en la tabla
original de esta sesión, que cerró con ocho de los diez campos que SETTINGS §2.2.15
fija desde la v11. Se agregan aquí junto con el error 3; para los errores 1 y 2 no
se reconstruyen valores, porque reconstruirlos de memoria al cerrar es exactamente
lo que la regla de registro prohíbe.

**Nota de patrón.** El §0 del encargo de esta sesión es un contrato positivo contra
`PAT-01`, y ambos errores registrados son `PAT-01` cometidos en los turnos que
rodearon su redacción. Eso no invalida el contrato: lo ubica. El contrato funcionó
donde se aplicó (el encargo separó respaldado de hipótesis y las seis compuertas
convirtieron cada hipótesis en medición) y falló donde no existía, que es la prosa
de la conversación. El §0 obliga al documento; nada obliga al turno.

Esta es la tercera sesión consecutiva con `PAT-01` registrado y refuerza lo que
v16 §15 ya concluía: la salvaguarda tiene que ser estructural, no disciplinaria. La
forma que esta sesión sugiere, y que P-54 debería evaluar, es que el marcador deje
de ser un adorno de la afirmación y pase a ser una **precondición de escribirla**:
una ruta con número de línea o una cifra solo se teclean después de la lectura o
del conteo que las produce, no antes con la intención de verificarlas luego. El
gatillo observable de los errores 1 y 2 es el mismo y es barato de chequear: *si el
número o la línea no salió de algo que ejecuté en este turno, no se escribe*.

El error 3 no comparte ese mecanismo y no debe fundirse con los otros dos al
analizarlos. Clasificado según SETTINGS §2.2.16 es una falla de **disciplina**: la
regla era conocida, estaba en cuatro documentos, y se saltó bajo la presión de
cierre. Su forma de arreglo, por esa misma tabla, es la prohibición explícita con
gatillo observable, no una receta positiva; el matiz que P-54 debería recoger es que
el invariante hoy está redactado como propiedad del pipeline y el hueco por donde se
coló fue clasificar un archivo de documentación como algo ajeno al pipeline.
