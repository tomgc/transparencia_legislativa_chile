# Log acumulativo de cierres de sesión

> Un archivo, una sección por cierre, anexada al final. Las secciones previas no
> se editan. Reemplaza al esquema de un log por cierre (instrumento
> `cierre_sesion_autonomo_cc_v4.md`, F9.1): proyectado a cientos de sesiones,
> aquel poblaba `andamios/logs/` sin límite.

## v18 — 2026-08-12

Paquete: `paquete_cierre_v18.md` (57.961 bytes, md5 `100c69f63d8967a74b30bbcbe26dfefc`).
`push_autorizado: no` · `sello_escaner: regenerar` · `backlog_ultimo_previo: 52`.

### Fases

| Fase | Resultado | Evidencia |
|---|---|---|
| F0.1 | OK | `.git/` y `50_documentacion/traspasos/` presentes |
| F0.2 | OK | 1 paquete; 7 de 7 campos del front matter; 0 placeholders; 3 bloques abren y cierran |
| F0.3 | OK | `raiz_proyecto` == `pwd` == `/Users/tomgc/Projects/transparencia_legislativa_chile` |
| F0.4 | OK | vigente v17, máximo en `archivo/` v16 → siguiente **v18**, igual al front matter y al nombre del paquete |
| F0.5 | OK | último número real en disco **52** (grep sobre el detalle cronológico), igual al declarado |
| F0.6 | **FALLÓ y detuvo** (primer intento) | `M SETTINGS_Y_PROMPTS_OPERACIONALES.md`, 392 inserciones / 9 supresiones, fuera de las salidas del escáner |
| F0 (2.º intento) | OK | tras el commit `4f50b5b` del titular, `50_documentacion/` limpio salvo el paquete |
| F1 | OK | escáner regenerado; sello **20260812_215927**; podados los dos archivos de `20260808_082255` |
| F2 | OK | `git mv` de v17 a `archivo/` (`R100`); 0 traspasos planos rezagados |
| F3 | OK | `vigentes=1`; cuerpo idéntico byte a byte al bloque (diff vacío sobre 678 líneas) |
| F4 | OK | 21 cambios aplicados; 15 anclajes con ocurrencia única verificada antes de escribir |
| F5 | OK | `ESTADO.md` idéntico al bloque (33 líneas) |
| F6 | OK | 0 hallazgos en los 4 greps sobre los 3 archivos |
| F7 | OK | stage acotado; diff paquete↔destino vacío en los 3 bloques; paquete eliminado |
| F8 | local | `push_autorizado: no`; commit queda sin publicar |
| F9 | OK | esta sección, anexada antes de F7 y commiteada junto al resto |

### Verificaciones con cifra

- **Cifras del backlog recomputadas en R antes de escribirlas**, como exigía el
  propio delta: **10 de 10** filas coinciden con lo declarado, suma de la columna
  **56**, suma de porcentajes **100,0**. Ninguna cifra se escribió sin recomputar.
- Numeración: último previo **52**, primera nueva **53**, nuevas **53-55**, último
  ahora **55**, **0** duplicados, contiguo 1..55 sin huecos.
- Intangibilidad: las **651** líneas de las entradas 1-52 idénticas por contenido.
- Distribución: los tres bloques verificados por diff contra su destino antes de
  eliminar el vehículo.

### Desviaciones

1. **Delimitadores del paquete.** El paquete usa `<!-- destino: <ruta> -->` +
   `# BEGIN <BLOQUE>` … `# END <BLOQUE>` en vez de los `<<<BLOQUE destino: …>>>`
   que especifica el §2 del instrumento. No se detuvo: los tres bloques abren y
   cierran, y los tres destinos coinciden con los esperados, así que no había
   ambigüedad que interpretar. Anotado además en el §16 del traspaso por
   instrucción del titular.
2. **`traspaso_nuevo` como ruta.** El front matter trae
   `50_documentacion/traspasos/traspaso_cierre_v18.md` donde el §2 especifica
   `v<NN>`. Inequívoco; no detuvo.
3. **Línea añadida al bloque TRASPASO.** El §7 del instrumento prohíbe editar
   bloques del paquete. El titular instruyó explícitamente anexar un bullet al
   final del §16 (Fricciones) sobre la desviación 1. Se ejecutó su texto verbatim;
   el resto del bloque quedó idéntico byte a byte, verificado por diff.
4. **Parada en F0.6 y su resolución.** El titular commiteó `SETTINGS` por separado
   (`4f50b5b`) y autorizó el paso a `main` antes de reanudar.
5. **Rama.** El working tree venía de `fix/guarda-bot-primera-corrida`, ya
   mergeada. El cierre se ejecutó sobre `main` tras `checkout` + `pull`, con
   `3f01124` (merge del PR #10) verificado como ancestro.

### Pendientes fuera de scope detectados

- Las 6 capturas del corte 2026-08-09 que produjo la descarga no solicitada siguen
  en cuarentena fuera del repo (`scratchpad/cuarentena/capturas_20260809/`), sin
  borrar y sin decisión del titular.
- El escáner podó `20260808_082255_*`; la poda es comportamiento propio del
  escáner, no del cierre.

## v19 — 2026-08-13

Paquete: `paquete_cierre_v19.md` (711 líneas, md5 `c5683dea97485810a452fad2b6ce2d8e`).
`push_autorizado: no` · `sello_escaner: regenerar` · `backlog_ultimo_previo: 55`.

### Fases

| Fase | Resultado | Evidencia |
|---|---|---|
| F0.1 | OK | `.git/` y `50_documentacion/traspasos/` presentes |
| F0.2 | OK | 1 paquete; 7 de 7 campos del front matter; 3 bloques abren y cierran (líneas 18/556, 560/671, 675/711); 0 placeholders |
| F0.3 | OK | `raiz_proyecto` == `pwd` == `/Users/tomgc/Projects/transparencia_legislativa_chile` |
| F0.4 | OK | máximo en `traspasos/` = v18, en `archivo/` = v17 → siguiente **v19**, igual al front matter y al nombre del paquete |
| F0.5 | OK | último número real del backlog en disco = **55**, contiguo 1-55 sin duplicados ni huecos, igual al declarado |
| F0.6 | OK | `git status --porcelain -- 50_documentacion/` solo reporta el propio paquete (el vehículo); nada más sucio |
| F1 | OK | `sello_escaner: regenerar` → escáner corrido; sello **20260813_091918**; podados los dos archivos de `20260808_145921` |
| F2 | OK | `git mv` de v18 a `archivo/` (`R`); 0 traspasos planos rezagados |
| F3 | OK | 534 líneas escritas; `vigentes = 1` (`traspaso_cierre_v19.md`) |
| F4 | OK | 5 operaciones, cada par con **exactamente una** coincidencia; primera entrada nueva = **56** = 55+1; recuento final **1-58 contiguo**, 0 duplicados, 0 huecos; suma de la columna N = **59** (recuento programático, no heredado) |
| F5 | OK | 25 líneas; `slug` y `nombre_real` conservados del disco, como exige el bloque |
| F6 | OK | 5 archivos revisados, **0 hallazgos** (RUT, OneDrive, coautoría a la herramienta, placeholders) |
| F7.3 | OK | 4 de 4 bloques idénticos a su destino: TRASPASO (534 vs 534 líneas), entradas del backlog (36 líneas verbatim), delta del backlog (22 líneas verbatim), ESTADO (25 líneas) |
| F8 | No aplica | `push_autorizado: no`: el commit queda local y se declara |

### Desviaciones

1. **El cierre se ejecuta sobre `main`, no sobre la rama de trabajo.** La sesión
   terminó en `chore/p59-locale-utf8`; el traspaso §1 cita `main` = `97dab39`
   como "previo al commit de cierre", que es exactamente el `HEAD` de `main`. Se
   hizo `checkout main` antes de F1. El instrumento no habla de ramas; dejar la
   memoria del proyecto dentro de un PR abierto habría sido peor.
2. **F7.3 se corrió ANTES del commit**, no después. Es estrictamente más
   estricto: si un bloque no calzaba, no quedaba nada commiteado que revertir.
3. **Bug propio en F4, detectado y revertido dentro de la fase.** El primer
   intento insertaba la fila de v19 con un `\n` embebido y luego separaba con
   `strsplit`, que sobre una línea vacía devuelve `character(0)`: eso borró las
   83 líneas en blanco del backlog. Se detectó por conteo (1 vs 83), se restauró
   con `git checkout --` (md5 idéntico al respaldo previo a la fase) y se
   reaplicó insertando la fila como línea propia. Resultado final: 88 líneas en
   blanco (83 previas + 5 de los dos bloques anexados).
4. **`traspaso_nuevo` trae un nombre de archivo** (`traspaso_cierre_v19.md`) donde
   el instrumento describe `v<NN>`. Los tres orígenes coinciden en 19, así que no
   detiene; se anota como desprolijidad del paquete.

### Pendientes fuera de scope detectados

- **La nota de la discrepancia heredada quedó a medias.** El delta ordenó
  recalcular los porcentajes sobre 59 y actualizar el texto de la nota, pero
  autorizó tocar solo `**56**` → `**59**` en la fila del total. Los porcentajes
  redondeados ahora suman **100,2** mientras la fila del total sigue declarando
  `**100,0**` y la nota sigue afirmando que "suman 100,0 por redondeo". Es
  exactamente el tipo de rótulo stale que el instrumento pide evitar; no se
  corrigió porque ningún par buscar→reemplazar lo cubría.
- **La entrada de P-59 en `CLAUDE.md` sigue pendiente**: el PR #11 ya modifica esa
  lista y agregarla en la rama de P-59 habría garantizado conflicto.
- **Dos PR abiertos y sin mergear al cierre**, #11 y #12, ambos con sus criterios
  medidos. El último commit de `chore/p59-locale-utf8` (el log con C8) está sin
  push, así que el PR #12 todavía no lo muestra.

### Corrección posterior al commit de cierre

- **`b13d9d7`, posterior a `1d4c189`.** La fila `**Suma de la columna**` y la nota
  de la discrepancia heredada declaraban `100,0` cuando los diez porcentajes ya
  recalculados sobre 59 suman **100,2**. Quedó fuera del commit de cierre porque
  el BACKLOG_DELTA del paquete no traía par buscar→reemplazar para ese texto:
  autorizaba `**56**` → `**59**` en esa fila y nada sobre su porcentaje, y F4 no
  inventa reemplazos que el delta no declara. Se corrigió en un commit propio, con
  la suma obtenida por recuento programático en R sobre la columna ya escrita, y
  con el diff acotado a esas dos ocurrencias (2 líneas cambiadas).
- **Queda un tercer texto stale, NO corregido:** la misma nota sigue diciendo que
  los porcentajes "se calculan sobre la suma de la columna (56)", cuando se
  calculan sobre 59. No entraba en el encargo de la corrección (que acotó a las
  dos ocurrencias del 100,0) y se deja declarado aquí para el próximo cierre.
- **`87cb64a` cierra el pendiente anterior.** La misma nota afirmaba que los
  porcentajes "se calculan sobre la suma de la columna (56)"; ahora dice 59, que es
  la base sobre la que F4 los recalculo. Una sola ocurrencia (diff de 1 linea, y
  cero ocurrencias de "(56)" en el archivo tras el reemplazo). Con esto los tres
  textos stale que el BACKLOG_DELTA no cubria quedan cerrados: la cifra de la fila
  del total, la frase que la afirmaba y la base del calculo. **Ninguno era un fallo
  del cierre**: los tres nacieron de que el delta acotaba sus pares
  buscar->reemplazar a la columna N, y F4 no inventa reemplazos no declarados.
  Leccion para el redactor del proximo paquete: cuando un delta cambia una base de
  calculo, sus pares tienen que cubrir tambien lo que esa base afirma en prosa.

## v20 — 2026-08-13

Cierre ejecutado con el instrumento v4
(`herramientas_dev/prompts/cierre_sesion_autonomo_cc_v4.md`), paquete
`paquete_cierre_v20.md`, modo autónomo. `push_autorizado: no`.

### Fases y evidencia

| Fase | Qué se hizo | Evidencia |
|---|---|---|
| **F0.1** | `.git` y `50_documentacion/traspasos` presentes | `test -d` OK en ambos |
| **F0.2** | Exactamente **1** paquete; 7 campos de front matter; 0 placeholders | `ls` = 1 archivo; grep de `<NN>`, `<slug>`, `[...]`, `<N>` = 0 hallazgos |
| **F0.3** | Guardia de repo | `raiz_proyecto` del front matter = `pwd` = `/Users/tomgc/Projects/transparencia_legislativa_chile` |
| **F0.4** | Correlativo por triple origen | máx. en `traspasos/` = v19, en `archivo/` = v18 → **19 + 1 = 20**; `traspaso_nuevo` = `traspaso_cierre_v20.md`; nombre del paquete = `paquete_cierre_v20.md`. Los tres coinciden |
| **F0.5** | `backlog_ultimo_previo` contra disco | recuento programático en R: **58** entradas, 1-58 contiguas, 0 duplicados, 0 huecos. Front matter declara 58 |
| **F0.6** | Sucios en `50_documentacion/` | solo `?? paquete_cierre_v20.md`, que es el vehículo mismo y no puede tratarse como sucio bloqueante. Ningún otro |
| **F1** | Escáner regenerado (`sello_escaner: regenerar`) | `Rscript 00_escanear_proyecto.R`, exit 0. Sello **`20260813_125459`**. Podó `20260812_215927` |
| **F2** | Archivado del v19 | `git mv` (nunca `cp`+`rm`). Resultado: **0** traspasos planos, **19** en `archivo/` |
| **F3** | Traspaso escrito | 568 líneas, 33 441 bytes. **`vigentes=1`** (`traspaso_cierre_v20.md`) |
| **F4** | Delta del backlog aplicado | ver bloque siguiente |
| **F5** | `ESTADO.md` escrito | 27 líneas, 852 bytes, front matter `sesion_actual: v20` |
| **F6** | Cuatro greps de gobernanza sobre los archivos escritos | RUT **0**; OneDrive/Dropbox **0**; coautoría de la herramienta **0**; placeholders **0** |
| **F7** | `git add` selectivo (nunca `git add .`, nunca el paquete) + commit + verificación de distribución + `rm` del vehículo | ver bloque de cierre |
| **F8** | `push_autorizado: no` → **no se hizo push** | queda local en `main` |

### F4 — Verificación programática del backlog (la que el paquete exige, en R)

Los 12 pares buscar→reemplazar aparecieron **exactamente una vez cada uno** antes
de aplicarse (n=1 en los 12; ninguno ausente ni duplicado). Después de aplicar:

| Verificación exigida | Resultado |
|---|---|
| Primera entrada nueva = `backlog_ultimo_previo` + 1 | **59** = 58 + 1 |
| Correlativo del detalle cronológico | **1-60**, contiguo, **0** duplicados, **0** huecos |
| Suma de la columna `N` de clasificación | **61**, igual a la declarada en la fila |
| Porcentajes recalculados sobre 61 | coinciden con los declarados en los **10** renglones |
| Suma de `N cambios` del resumen por sesión | **60**, igual a la fila `Total` |

El recuento reconoce los **tres** formatos de entrada que conviven en el archivo
(1-23 como lista ordenada, 24-58 con negrita sobre número y título, 59-60 con el
formato del paquete); ninguno se normalizó.

### Desviaciones del instrumento, declaradas

1. **Delimitadores del paquete.** F0.2 exige que "los tres delimitadores abren y
   cierran", con la forma `<<<TRASPASO destino: …>>>` / `TRASPASO>>>` de §2. El
   paquete v20 usa en su lugar banderas HTML
   (`<!-- ===== BLOQUE X ===== -->` seguido de `<!-- destino: … -->`) y **no trae
   delimitador de cierre**: cada bloque termina donde empieza el banner siguiente,
   y el último en fin de archivo. **Se continuó, no se detuvo**, porque las tres
   rutas de destino están declaradas explícitamente, las fronteras son
   inequívocas, y F7.3 verifica la extracción por diff contra el destino, que es
   la garantía que la regla protege. Queda declarado para que el redactor del
   próximo paquete use la forma del instrumento.
2. **Rama de destino del cierre.** `/cierre` se lanzó desde
   `sondeo/p68-fuentes-tematicas`. El cierre se ejecutó sobre **`main`**
   (`git switch main`, working tree limpio salvo el vehículo), porque el §1 del
   propio traspaso declara `main` = `0ecb44e` **"previo al commit de cierre"**, y
   esa etiqueta solo es cierta si el commit de cierre aterriza en `main`; además
   su §11.1 deja la rama del sondeo pendiente de decisión del titular. El
   instrumento no norma la rama. La rama del sondeo queda intacta, con sus 6
   commits y sin push.

### Observaciones sobre el paquete, no corregidas

- **Formato de las entradas nuevas.** El delta escribe `- **59.** Texto`, mientras
  las entradas 24-58 del archivo usan `**24. Título…**` sin guion. Se escribió
  **byte a byte como lo trae el paquete**: F4 no edita bloques.
- **Falta el encabezado `### Sesion 20 (v20) — …`.** Las 19 sesiones previas
  tienen uno; el delta no lo provee y agregarlo sería completar el bloque, que
  está prohibido. Las entradas 59-60 quedan bajo el encabezado de la sesión 19.

### Pendientes fuera de scope, detectados en esta corrida

- **La nota "Discrepancia heredada" volvió a quedar stale, en tres cifras.** Dice
  que "hoy la columna suma **59** mientras las entradas… son **58** (1-58)", que
  "los porcentajes se calculan sobre la suma de la columna (**59**)" y que "suman
  **100,2** por redondeo". Tras el delta la columna suma **61**, las entradas son
  **60** (1-60), y los diez porcentajes recalculados suman **100,0** exactamente
  (verificado en R). **El BACKLOG_DELTA no trae ningún par buscar→reemplazar para
  ese texto**, así que F4 no lo tocó durante las fases.
  Es **la tercera repetición del mismo patrón**: el log de v19 ya registró dos
  correcciones posteriores al commit de cierre por esta misma nota y dejó escrita
  la lección — *"cuando un delta cambia una base de cálculo, sus pares tienen que
  cubrir también lo que esa base afirma en prosa"*. La lección no se aplicó en el
  paquete v20. **Ninguna de las tres cifras es un fallo del cierre**; las tres son
  del delta.
- **Corregida por el cierre, no por el delta, y por tercera vez.** Por instrucción
  explícita del titular posterior al commit `ec474ae`, las tres cifras se
  actualizaron a los valores ya verificados en R durante F4: columna **59 → 61**,
  entradas **58 → 60 (1-60)**, y la frase del redondeo pasa a declarar que en este
  corte los diez porcentajes suman **100,0 exactamente**, reservando la explicación
  del redondeo para los cortes en que no sumen 100,0. Se deja constancia de la
  autoría del arreglo: **lo hizo el cierre, fuera de F4 y por orden del titular, no
  el BACKLOG_DELTA**, igual que en v18 y v19. F4 por sí sola no habría tocado ese
  texto, y no debe: no inventa reemplazos que el delta no declara.
- **El pendiente de fondo sigue abierto**, y ahora con la misma unidad de siempre:
  columna 61 contra entradas 60. Resolverlo exige auditar la clasificación de las
  entradas 1-23, que el propio archivo declara como pendiente.

### Para el redactor del próximo paquete de cierre

El BACKLOG_DELTA debe traer SIEMPRE los pares de la nota 'Discrepancia
heredada', no solo los de la tabla de clasificacion. Tercera repeticion
(v18, v19, v20). Si el redactor solo actualiza la tabla, la nota queda stale
y la corrige el cierre, que no deberia inventar reemplazos.

---

## v21 — 2026-08-13

**Sesión 21:** entidad `proyecto` con tramitación desde el SIL (P-66, actos A y B).
Paquete: `paquete_cierre_v21.md`. `push_autorizado: no`.

### Fases

| Fase | Resultado | Evidencia |
|---|---|---|
| F0 | CUMPLE tras **dos rechazos previos** (ver desviaciones) | 7 campos; 6 delimitadores 1 a 1 (L12/635, L638/722, L725/749); 0 placeholders sobre 6 patrones; `raiz_proyecto` == `pwd`; correlativo triple v20+1=21; backlog 60 == 60; sucio = solo el paquete |
| F1 | CUMPLE | `sello_escaner: regenerar` → `Rscript 00_escanear_proyecto.R`, exit 0. Generó `20260813_192111_estructura.{md,txt}` y `estructura_actual.{md,txt}`; podó la corrida `20260813_091918` |
| F2 | CUMPLE | `git mv` de `traspaso_cierre_v20.md` a `archivo/`. 20 en archivo, 0 planos |
| F3 | CUMPLE | `traspaso_cierre_v21.md`, 620 líneas. **`vigentes = 1`** |
| F4 | CUMPLE | 6 operaciones, todas con verificación de unicidad. Resultado: **62 entradas, 1-62, contigua, sin huecos ni duplicados**; primera nueva = 61 = 60+1 |
| F5 | CUMPLE | `ESTADO.md`, 22 líneas, abre en `---` |
| F6 | CUMPLE | 0 hallazgos: RUT 0, OneDrive/Dropbox 0, coautoría 0, placeholders 0, sobre los 5 archivos escritos |
| F7 | CUMPLE | commit selectivo; 3 diffs bloque↔destino vacíos; paquete eliminado |
| F8 | Sin push | `push_autorizado: no` |

### Detalle de F4

Seis operaciones, cada una con verificación de unicidad (ausente o duplicada → `stop()`):

1. **Reparación estructural declarada por el paquete:** insertado
   `### Sesion 20 (v20) — veredicto de fuentes tematicas BCN (P-68)` antes de la
   entrada 59, que quedó colgando bajo el encabezado de la sesión 19 porque el
   cierre v20 no creó el suyo. No se renumeró ni reescribió ninguna entrada.
2. Encabezado de la sesión 21 más las entradas **61** y **62**, al final del detalle.
3. `diagnostico/exploracion` 13 → 14; `consolidacion/salida` 3 → 4.
4. Suma de la columna recalculada **en R**: **63**, que coincide con la declarada
   por el paquete. Porcentajes recalculados sobre 63 y reescrita la columna completa.
5. Nota de la discrepancia heredada actualizada (61→63, 60→62, base y cierre).
6. Fila de la sesión 21 en el resumen y `Total` 60 → 62.

**Declaración exigida por el propio delta:** los porcentajes recalculados suman
**99,9** y no 100,0. El delta ordena declarar la diferencia en vez de ajustar
ninguna celda a mano, y así se hizo: la nota del backlog dice ahora "en este corte
suman 99,9 … y cuando no sumen 100,0 sera por redondeo a un decimal, no por una
entrada sobrante". La discrepancia heredada sigue abierta con el mismo signo y la
misma unidad (columna 63, entradas 62).

### Desviaciones — dos rechazos de F0, uno legítimo y uno mío

**Rechazo 1 (legítimo).** El primer paquete no traía los delimitadores
`<<<BLOQUE … BLOQUE>>>` que exige §2 del instrumento (0 ocurrencias de `<<<` y de
`>>>`; solo comentarios HTML que marcaban el inicio y no el cierre), y su campo
`escaner` decía `regenerar` en vez de nombrar el script. Sin marca de cierre, las
fronteras de cada bloque solo podían inferirse, y F7.3 exige diffear cada bloque
contra su destino: ese diff habría validado un recorte propio, no el contenido del
redactor. El redactor corrigió ambas cosas.

**Rechazo 2 (error mío, y el más caro de la sesión).** Rechacé el paquete
corregido afirmando que `backlog_ultimo_previo: 60` no cuadraba con el disco, que
—dije— tenía 58 entradas. **Era falso.** Mi patrón de recuento estaba anclado a
inicio de línea (`^\*\*N\.`) y el backlog usa **tres** formas: `N. `, `**N. ` y
`- **N.** `. Las entradas 59 y 60 son de la tercera forma (L820 y L826) y mi
patrón las perdía. Peor: sobre esa medición mala construí un diagnóstico
equivocado —"el backlog es internamente inconsistente, el resumen cuenta 2
entradas que el detalle nunca recibió"— y ofrecí al titular dos salidas para un
problema inexistente. Una búsqueda literal con `fixed = TRUE`, que es lo que
correspondía desde el principio para verificar una ausencia, lo habría descartado
en un intento. **Lección: para afirmar que algo NO está, la herramienta es la
búsqueda literal, no un patrón anclado que uno cree exhaustivo.**

**Dos fallos de script durante F4**, ambos detenidos antes de escribir nada y con
el backlog verificado idéntico a su respaldo en cada caso: `grep(fixed = TRUE)`
con un `^` que en modo literal no ancla, e índices de columna desplazados en uno al
partir las filas de la tabla por `" | "`.

### Pendientes fuera de scope detectados

- La discrepancia heredada del backlog (columna 63 contra 62 entradas) sigue
  abierta; su resolución exige auditar la clasificación de las entradas 1-23.
- El delta no aportó texto de glosa para las categorías cuyo N cambió, así que las
  columnas de descripción de `diagnostico/exploracion` y `consolidacion/salida` no
  mencionan las entradas 61 y 62. Se dejó como está: inventar esa glosa habría sido
  completar el paquete.
- Ramas `medicion/p66-acto-a` y `construccion/p66-acto-b` sin borrar, por
  instrucción del titular.
## v22 — 2026-08-14

Instrumento: `cierre_sesion_autonomo_cc_v4.md`. Paquete: `paquete_cierre_v22.md`.
`push_autorizado: si`. `sello_escaner: regenerar`.

### Fases

| Fase | Qué se hizo | Evidencia |
|---|---|---|
| F0 | Precondiciones | `.git` y `50_documentacion/traspasos` presentes; **1** paquete; 7 campos de front matter; 3 delimitadores abren y 3 cierran; **0** placeholders; `raiz_proyecto` = `pwd`; correlativo por triple origen: máximo en `traspasos/` + `archivo/` = **21**, +1 = **22** = `traspaso_nuevo` = nombre del paquete; `backlog_ultimo_previo: 62` = último número real en disco (grep); **0** sucios en `50_documentacion/` excluyendo el paquete y las salidas del escáner |
| F1 | Escáner regenerado | `sello_escaner: regenerar` → `Rscript 00_escanear_proyecto.R`. Generó `20260814_054531_estructura.{md,txt}` y actualizó `estructura_actual.{md,txt}`; podó `20260813_125459_*` |
| F2 | Archivado | `git mv` (rename `R` en el índice, no `cp`+`rm`) de `traspaso_cierre_v21.md` a `archivo/`. Planos restantes **0**; en `archivo/` **21** |
| F3 | Traspaso | Bloque extraído en R y escrito byte a byte: **585 líneas**, `identical()` contra el bloque del paquete **TRUE**. `vigentes = 1` |
| F4 | Backlog | **18 pares** buscar→reemplazar, los 18 con **exactamente 1 ocurrencia** verificada ANTES de escribir; entradas 63 y 64 anexadas; bullet de v22 anexado |
| F5 | ESTADO.md | Bloque escrito: **27 líneas**, `identical()` **TRUE** |
| F6 | Gobernanza | 4 chequeos (RUT, OneDrive, coautoría, placeholders) sobre 7 archivos escritos: **0 hallazgos** |
| F7 | Commits | `git add` selectivo (traspasos nuevo y archivado, backlog, ESTADO, salidas del escáner, este log). Nunca `git add .`, nunca el paquete |
| F8 | Push | `push_autorizado: si` |
| F9 | Log y reapertura | Esta sección, anexada antes de F7 para entrar en el mismo commit (forma preferida del instrumento) |

### Verificaciones del backlog (F4)

- **Numeración:** 64 entradas en el detalle cronológico, rango **1-64**, **0** duplicados, **0** huecos, contigua. Primera entrada nueva **63** = `backlog_ultimo_previo` + 1.
- **Recuento programático exigido por la nota de ejecución del paquete:** los 10 porcentajes recalculados en R sobre el archivo ya modificado **coinciden los 10** con lo declarado; suma de la columna **65** (declarada 65) y suma de porcentajes **100,0** (declarada 100,0). Sin parada.
- **Fila del resumen:** `Total = 64` = entradas numeradas en disco.
- **Bullets de delta:** 21 presentes, de `v01` a `v22`; **falta el de `v21`**, tal como el propio paquete declara y deja como **P-98**. No se reconstruyó de memoria.

### Desviaciones y defectos detectados

1. **El paquete no trae encabezado de sesión para el backlog.** El bloque `BACKLOG_DELTA`
   ordena "anexar al final del detalle cronológico" y entrega las entradas 63 y 64, pero
   **no entrega un `### Sesion 22 (v22) — …`**. Se aplicó literalmente, así que ambas
   entradas quedan bajo el encabezado `### Sesion 21 (v21)` (línea 838), que es
   incorrecto. **No se fabricó el encabezado:** componer su título sería completar
   contenido del redactor, que el instrumento §5 prohíbe. Los 21 cierres anteriores sí
   traen encabezado por sesión, así que la omisión es del paquete v22, no del formato.
   **Queda para reparación del titular.**
2. **El cierre se ejecutó sobre `main`, no sobre la rama de trabajo.** `/cierre` se
   invocó con el árbol en `sondeo/p92-eje-tematico` (con PR #17 abierto). El instrumento
   no fija rama, pero el traspaso §1 cita `main` como "previo al commit de cierre" y el
   cierre v21 (`4160f46`) vive en `main`: ambos indican que el commit de cierre va sobre
   `main`. Se hizo `git checkout main` antes de F1 y se revalidó F0.6 allí (**0** sucios).
   Dejarlo en la rama del sondeo habría metido documentación de cierre dentro del PR #17.
3. **Fecha:** el traspaso declara "Fecha de cierre 2026-08-13" y `Sys.Date()` en la
   ejecución da **2026-08-14**. Esta sección del log usa la fecha del sistema, como manda
   F9.3. El traspaso **no se editó**.
4. **Heterogeneidad de formato de las entradas del backlog, preexistente:** conviven tres
   formas (`N. ` en 23 entradas, `**N.**` en 39, `- **N.**` en 2). Las entradas 63 y 64
   usan `**N.**`, que es la forma que el paquete entregó y la misma de 61 y 62. No se
   normalizó nada.
5. **Dos defectos en mis propios scripts de verificación**, corregidos antes de dar F4 por
   buena: el primer patrón de recuento solo capturaba `**N.**` y contó **4** entradas en
   vez de 64 (falso verde por criterio que no cubre el universo); y `sub()` sin anclar
   `.*$` devolvía el número pegado al texto y producía `NA`. El recuento definitivo es el
   del tercer intento.

### Pendientes fuera de scope detectados

- **P-98** (ya en el traspaso): falta el bullet de delta de `v21` en el backlog.
- **Nuevo, sin número:** el paquete de cierre debería entregar el encabezado de sesión
  del backlog junto con las entradas. Es la desviación 1 de arriba y afectará a todo
  cierre futuro si el redactor no lo incorpora.
- **Ramas locales sin podar:** 16 ramas locales, varias ya mergeadas
  (`feat/captura-xml-y-nodo-votaciones`, `fix/autorregeneracion-intermedios`,
  `construccion/p66-acto-b`, entre otras). No se tocó ninguna: borrar ramas exige
  compuerta de confirmación del titular.
- **PR #16 y #17 abiertos** al cierre, ninguno mergeado, como declara el traspaso.


## v23 — 2026-08-19

Instrumento: `cierre_sesion_autonomo_cc_v8.md`. Paquete: `paquete_cierre_v23.md`
(segunda emision). `push_autorizado: si`. `sello_escaner: regenerar`.

### Fases

| Fase | Que se hizo | Evidencia |
|---|---|---|
| F0 | Precondiciones, 7 puntos | `.git` y `traspasos/` presentes; **1** paquete en `andamios/`; **13 de 13** campos de front matter; **4** delimitadores abren y **4** cierran; `raiz_proyecto` = `pwd`; correlativo triple max(`v22`)+1 = `v23` = `traspaso_nuevo` = nombre del paquete; `backlog_total_previo` **64** = ultimo numero real del Detalle cronologico; entradas **65, 66, 67** contiguas; tramo `65→67`; `settings_version` calza con la linea real de SETTINGS; `compuerta_dudas: 5 registradas` = **5** filas de §11.4 con sus tres campos |
| F1 | Copia de trabajo | Los tres destinos copiados al scratchpad; el arbol real no se toco hasta F6 |
| F2 | Inserciones por posicion estructural | Los 3 encabezados aparecen **exactamente 1 vez** (resumen L66, detalle L99, delta L896). Bloque de sesion 23 al final del Detalle; fila del resumen; bullet del delta |
| F3 | Rotulos derivados | **5** patrones con disparo (14 reescrituras), **10** con cero. Umbral 7.3 dispensado por el titular; ver Desviaciones |
| F4 | Invariantes I1-I7 | **7 de 7 VERDES**, sin excepcion |
| F5 | Compuerta | Pasa |
| F6 | Arbol real | Escaner regenerado (poda incluida); `git mv` de `traspaso_cierre_v22.md` a `archivo/` (**22** en archivo, **1** plano vigente); tres archivos copiados desde la copia de trabajo |
| F8 | Distribucion | **3 de 3** bloques `identical()` TRUE contra su destino. Verificado ANTES del commit |
| F7 | Commit y push | `git add` selectivo; nunca `git add .` ni el paquete |
| F9 | Log y reapertura | Esta seccion |

### F3 — disparos por patron

| Patron | Disparos | Resultado |
|---|---|---|
| R12-tabla | 10 | suma de la columna 65->68; 10 porcentajes recalculados sobre 68; suman 100,1 |
| R12-prosa-estado | 1 | columna 65->68, entradas 64->67, rango (1-64)->(1-67) |
| R12-prosa-denominador | 1 | denominador 65->68 |
| R12-prosa-suma-pct | 1 | suma de porcentajes -> 100,1 |
| R11-puntero | 1 | `cierre v22` -> `cierre v23`; **0** sobrevivientes |
| R1 a R10 | 0 | ninguno de esos rotulos existe en este backlog |

### F4 — invariantes

| # | Resultado |
|---|---|
| I1 | VERDE. **67** entradas en el Detalle cronologico, rango 1-67, **0** duplicados, **0** huecos |
| I2 | VERDE. Las **23** filas de sesion suman **67** = `Total` declarado = `backlog_total_nuevo` |
| I3 | VERDE. Filas del resumen 22 -> **23** |
| I4 | VERDE. **19** apariciones de 64/65/`cierre v22`, las **19** clasificadas como historicas o legitimas: ids de pendiente (`P-64`, `P-65`), referencia de linea (`00_run_all.R:64`), numeros de entrada del propio detalle, bullet historico de v22 y las transiciones del bullet nuevo. **0** sobrevivientes de `cierre v22` |
| I5 | VERDE. **0** autorreferencias de cifras en el bloque de autoria |
| I6 | VERDE. **0** hallazgos sobre 3 archivos en los 5 chequeos (RUT, OneDrive, credenciales, coautoria, placeholders) |
| I7 | VERDE. **1** traspaso vigente tras el archivado |

### Desviaciones

1. **Regla 7.3 dispensada por el titular.** El catalogo de la seccion 5 es de cartera y
   este backlog nunca llevo R1-R10: no tiene rango en el encabezado, ni mapa de tramos,
   ni cabecera del resumen, ni nota de cierre. La premisa del umbral ("indica que la
   estructura del archivo cambio") queda falsada por medicion: el log del cierre v22
   describe este mismo archivo con la misma forma. El cierre se detuvo en F3, el titular
   autorizo el paso por excepcion y la correccion del instrumento quedo registrada como
   **P-104**. Los siete invariantes de F4 se mantuvieron bloqueantes.
2. **`Delta del backlog` es una lista de bullets, no una tabla.** F2 nombra "tabla"; el
   encabezado existe y es unico, asi que la insercion se resolvio igual y el item nuevo
   copio el formato del ultimo bullet existente.
3. **La ultima fila de la tabla del resumen es `| Total |`, un agregado.** "Final de la
   tabla" en sentido literal habria puesto la fila de sesion 23 debajo del Total; entro
   antes, y el Total paso 64 -> 67 por ser magnitud derivada.
4. **Prosa reenvuelta.** El bloque de la discrepancia heredada se normalizo por
   envoltorio (F3) y se reescribio a 76 columnas, asi que su diff toca lineas cuyo texto
   no cambio.
5. **Glosa de la columna de descripcion sin tocar.** Las categorias `infraestructura` y
   `diagnostico/exploracion` cambiaron de N pero su glosa no menciona las entradas 65-67:
   inventarla habria sido completar contenido del redactor. Mismo criterio que en v21.
6. **Dos defectos en mis propios scripts, corregidos antes de dar la fase por buena:** un
   indice desplazado en la tercera insercion de F2 (se rehizo desde copia limpia con
   orden de insercion estrictamente descendente) y la fila `Suma de la columna` perdiendo
   su celda final vacia en F3 (`strsplit` descarta campos vacios al final).

### Pendientes fuera de scope detectados

- **P-104** (ya en el traspaso): el umbral de la regla 7.3 mide un proxy que no aplica a
  este repo.
- **P-98** sigue abierto: falta el bullet de delta de `v21` en el backlog. No se
  reconstruyo de memoria.
- **Discrepancia heredada** del backlog abierta, ahora columna 68 contra 67 entradas.
- **Copia sobrante del paquete en `50_documentacion/traspasos/paquete_cierre_v23.md`.** El
  titular la declaro borrada; sigue presente y sin trackear (49 042 bytes, emision
  anterior del paquete). No detiene (F0.7 exceptua "paquete"), no se conto para el
  correlativo, no se commiteo y no se borro: la unica eliminacion que el instrumento
  sanciona es la del vehiculo en `andamios/`.
- **Snapshot `20260819_161404_estructura.{md,txt}`** quedaba sin trackear de una corrida
  previa del escaner en esta misma sesion. Entra en el commit por ser salida del escaner,
  categoria que F7 nombra explicitamente; se declara aqui por no haberla producido este
  cierre.
- **PR #19 abierto** al cierre, sin mergear, como declara el traspaso.
