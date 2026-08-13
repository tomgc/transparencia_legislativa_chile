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
