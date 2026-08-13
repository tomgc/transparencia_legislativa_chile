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
