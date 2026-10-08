# Log de ejecución — P-62: sello de los intermedios desalineado, y merge del PR #5

- **Encargo:** `50_documentacion/andamios/50_encargo_p62_sello_intermedios.md`
- **Sesión:** 16. **Fecha:** 2026-08-07.
- **Resultado:** proyecto corrible. `validar_corte()` pasa 6 de 6, `39` corre completo y el
  dato publicado no cambió. P-61 cerrado (PR #5 mergeado).

---

## 1. Fase 1 — Cierre de P-61

`gh api --paginate /repos/tomgc/transparencia_legislativa_chile/pulls/5/files`, parseado con
`jsonlite`: **denominador 8 archivos**.

| Ruta de pipeline | Archivos del PR |
|---|---|
| `10_utils/` | **0** de 8 |
| `30_procesamiento/` | **0** de 8 |
| `docs/` | **0** de 8 |
| `40_salidas/` | **0** de 8 |

El criterio 9 de P-61 no era un falso verde. PR #5 mergeado; `main` avanzó `ff0c482` →
`3ea5ec1`. **0 PRs abiertos.**

---

## 2. Mecanismo del sello (Fase 2.1)

| Qué | Dónde | Cómo |
|---|---|---|
| **Se escribe** | `sellar()`, [10_utils/10_utils.R:65](../../../10_utils/10_utils.R:65) | Como **atributo del propio objeto**: `attr(objeto, "sello") <- list(corte_fecha, anio_proceso, hash_origen, escrito_en)`. No es columna, ni archivo lateral, ni nombre de archivo. `corte_fecha` se toma de la global `CORTE_FECHA` **en el momento de escribir** |
| **Se aplica** | `escribir_atomico()`, [10_utils.R:51](../../../10_utils/10_utils.R:51) | Solo si recibe `hash_origen`; si no, escribe sin sellar (por eso el texto JSON del `39` no se sella) |
| **Se lee** | `leer_sellado()`, [10_utils.R:89](../../../10_utils/10_utils.R:89) | `stop()` diagnóstico si el archivo no existe o no trae sello |
| **Se valida** | `validar_corte()`, [10_utils.R:104](../../../10_utils/10_utils.R:104) | Compara `sello$corte_fecha` contra el corte pasado, y además exige que **todos los hermanos declaren el mismo** |
| **Quién invoca** | [39_consolidar_json.R:45](../../../30_procesamiento/39_consolidar_json.R:45) (`leer_sellado` sobre los 6) y [:65](../../../30_procesamiento/39_consolidar_json.R:65) (`validar_corte`); [33_extraer_asistencia.R:197](../../../30_procesamiento/33_extraer_asistencia.R:197) (`leer_sellado` sobre `diputados.rds`) | |

`hash_origen` guarda el **md5 de la captura cruda** que alimentó el intermedio
(`hash_origen_de()`, [10_utils.R:81](../../../10_utils/10_utils.R:81)). Ese campo resultó
ser la pieza que permitió resolver la procedencia sin ambigüedad.

---

## 3. Los 6 intermedios, antes del arreglo (Fase 2.2)

| Artefacto | Sello declarado | `escrito_en` / mtime | Filas |
|---|---|---|---|
| `asistencia_ambitos` | 2026-07-27 | 2026-08-03 18:08:00 | 310 |
| `asistencia_nominal` | 2026-07-27 | 2026-08-03 18:08:00 | 9 183 |
| `diputados` | 2026-07-27 | 2026-08-03 18:08:00 | 155 |
| `proyectos_detalle` | 2026-07-27 | 2026-08-03 18:08:01 | 381 |
| `proyectos` | 2026-07-27 | 2026-08-03 18:08:01 | 1 705 |
| `votos` | 2026-07-27 | 2026-08-03 18:08:01 | 122 605 |

**6 de 6** leídos, **6 de 6** con sello, **6 de 6** declarando 2026-07-27.

**La firma del defecto está en la tabla:** los seis fueron **escritos el 2026-08-03** y
sellados con corte **2026-07-27**. No es un sello viejo de un archivo viejo: es un sello
viejo en un archivo nuevo.

---

## 4. Veredicto de procedencia (Fase 2.3): el contenido SÍ es del corte vigente

El encargo advirtió contra la trampa de dar por buena la reconciliación interna
`96 397 = 65 478 + 30 919`, que suma igual en cualquier corte. Se resolvió **contra el
artefacto publicado**:

| Prueba | Qué mide | Resultado |
|---|---|---|
| **Perfiles publicados vs intermedios** *(la decisiva)* | Si los 155 perfiles (que declaran `corte_fecha` **2026-08-03**) se derivan de estos intermedios | `n_votaciones` **155 de 155**; `n_proyectos` **155 de 155**; `tasa_presencia` **155 de 155**. Sumas: 96 397 y 1 625, ambas iguales |
| **`hash_origen` del sello vs captura cruda** | De qué archivo crudo se derivó cada intermedio | **6 de 6** coinciden con el crudo `20260727_*` |
| **Captura cruda 20260727 vs 20260803** | Si el refresh del bot trajo datos distintos | **md5 idénticos en 6 de 6** |
| **Conteos derivados vs PR #3 del bot** | Contraste con el resumen del refresh publicado | `votos_con_proyecto` 65 478, `votos_sin_proyecto` 30 919, suma 96 397, mociones 1 625 — **4 de 4 exactos** |

**Veredicto: Contingencia A.** El contenido corresponde al corte vigente. El defecto es el
**sello**, no el dato. Y hay una razón física para que así sea: **el refresh del 2026-08-03
bajó un snapshot byte a byte idéntico al del 2026-07-27**, coherente con que el PR #3
declarara `+0` en los cinco conteos.

---

## 5. Causa raíz (Fase 2.4), con evidencia

**Los intermedios no viajan, y el corte sí.**

| Evidencia | Dónde |
|---|---|
| `40_salidas/intermedios/*.rds` está **ignorado por git** | `.gitignore:42` |
| De ese directorio hay **1 archivo versionado**, y es `.gitkeep` | `git ls-files 40_salidas/intermedios/` |
| El workflow commitea `10_utils/10_configuracion.R`, `20_insumos/camara`, `40_salidas/json` y `docs/data` — **no los intermedios** | [refresh-semanal.yml:115](../../../.github/workflows/refresh-semanal.yml:115) |
| El workflow **sí** mueve `CORTE_FECHA`, con `sed` sobre el archivo de configuración, y lo commitea | [refresh-semanal.yml:75](../../../.github/workflows/refresh-semanal.yml:75) y :115 |

**El mecanismo, paso a paso:** el CI regenera los intermedios dentro del runner, publica el
JSON y avanza `CORTE_FECHA` en el repositorio; los `.rds` que produjo se descartan con el
runner. Al mergear ese refresh, el árbol local recibe el corte nuevo pero conserva los
intermedios de su **última corrida local** — la del 2026-08-03 18:08, cuando `CORTE_FECHA`
todavía valía 2026-07-27 porque el PR #3 se mergeó recién hoy.

**Esto no es un accidente de esta semana: se repetirá en cada refresh del bot**, para
cualquier copia local. Las otras tres hipótesis quedan descartadas por la misma evidencia:
el sello **no** se resuelve antes de tiempo (`escrito_en` prueba que se escribió el 08-03 con
el valor vigente **entonces**), y los intermedios **sí** se regeneraron (mtime del 08-03).

**La compuerta hizo exactamente su trabajo.** Distinguió "mi copia está atrasada" de "el dato
está mal", que es para lo que existe.

---

## 6. Arreglo aplicado (Fase 3)

**Contingencia A, con el mecanismo real y no con un sello escrito a mano:** se corrieron los
pasos **32–36** con `CORTE_FECHA = 2026-08-03`, que es el mismo código que produce el sello
en producción. Así el sello queda correcto **por construcción**, sin tocar el atributo a
mano y sin inventar un mecanismo nuevo.

**Costo real: 0,9 s y 0 llamadas a la API.** Los cinco extractores dieron **cache hit** sobre
la captura cruda del corte vigente, que el workflow **sí** commitea:

```
32_diputados   cache hit: 20260803_diputados.rds
33_asistencia  cache hit: 20260803_periodo_legislativo.rds / 20260803_asistencia_nominal_2026_tope-inf.rds
34_votaciones  cache hit: 20260803_votos_long_2026_tope-inf.rds
35_proyectos   cache hit: 20260803_proyectos_long_2026_tope-inf.rds
36_detalle     cache hit: 20260803_detalle_proyectos_2026_tope-inf.rds
```

🔒 5 verificado: `20_insumos/camara/` quedó **idéntico** — 43 archivos antes y después,
**43 de 43 md5 iguales**, 0 archivos nuevos, `identical()` TRUE sobre la tabla completa.

**Corrección de causa raíz aplicada:** `50_documentacion/activa/procedimiento_actualizacion.md`
documentaba, en su sección "Verificación de reproducibilidad", correr `run_all(only = 39)` —
**que es precisamente lo que falla** después de un refresh del bot. Se agregó el paso previo
`run_all(from = 32, to = 36)`, con la explicación del mecanismo y la advertencia de que **no
se arregla tocando `CORTE_FECHA` ni relajando la compuerta**.

**Lo que este encargo NO decidió**, conforme a su §5: si los intermedios deben versionarse.
Esa es la decisión de diseño que cerraría la causa raíz de fondo, y queda pendiente para el
titular (ver §9).

---

## 7. Verificación (Fase 4)

| # | Qué | Cifra | Denominador |
|---|---|---|---|
| 1 | `validar_corte()` invocada como la invoca el pipeline | **PASA** | 6 de 6 intermedios, contra `CORTE_FECHA` = 2026-08-03 leído de `10_utils/10_configuracion.R:41` |
| 2 | `39` corre completo | **sin error, 10,2 s**; declaró "Procedencia validada: 6 intermedios al corte 2026-08-03" | — |
| 3 | JSON regenerado vs publicado, **excluido `metadatos.generado`, que es volátil por construcción** | **156 de 156 idénticos** | 155 perfiles + 1 índice |
| 3b | `corte_fecha`, que **no** es volátil y sí se compara | **155 de 155 idéntico**, valor único `2026-08-03` | 155 perfiles |
| 3c | Artefactos que difieren **solo** por `generado` | 155 de 156 (el índice no lleva ese campo, por eso su md5 crudo ya coincidía) | 156 |
| 4 | Diferencias fuera de `generado` | **0 de 156** | 156 |
| 5 | `git status` acotado a `docs/` | **0 líneas** | — |

Sobre el punto 5: `39` publica también en `docs/data/` ([39:388-396](../../../30_procesamiento/39_consolidar_json.R:388)),
así que tras correrlo quedaron 155 archivos modificados ahí. Se verificó **archivo por
archivo contra `HEAD`** que la diferencia era **solo `metadatos.generado`** (155 de 155
idénticos excluido ese campo) y **recién entonces** se restauraron `docs/` y
`40_salidas/json/` con `git checkout`. Este encargo no republica. `validar_corte()` se
re-verificó después del checkout: sigue pasando 6 de 6.

---

## 8. Criterios de éxito (§4 del encargo)

| # | Criterio | Medida | Estado |
|---|---|---|---|
| 1 | PR #5 mergeado sin tocar el pipeline | **0 de 8** archivos bajo las 4 rutas de pipeline | **CUMPLE** |
| 2 | Mecanismo del sello documentado | Se escribe en `10_utils.R:65`, se aplica en `:51`, se lee en `:89`, se valida en `:104`, se invoca en `39:45` y `39:65` | **CUMPLE** |
| 3 | Los 6 intermedios inventariados | **6 de 6** con sello declarado, mtime y filas contadas | **CUMPLE** |
| 4 | Procedencia resuelta contra el artefacto publicado, no por reconciliación interna | 155 de 155 perfiles coinciden en `n_votaciones`, `n_proyectos` y `tasa_presencia`; más `hash_origen` 6 de 6 y md5 crudo 6 de 6 | **CUMPLE** |
| 5 | Causa raíz sostenida con evidencia | `.gitignore:42` + `refresh-semanal.yml:115` + `git ls-files` (1 archivo, `.gitkeep`) + `escrito_en` 2026-08-03 con sello 2026-07-27 | **CUMPLE** |
| 6 | `validar_corte()` pasa | **6 de 6** | **CUMPLE** |
| 7 | `39` corre completo | Sin error, **10,2 s** | **CUMPLE** |
| 8 | El dato publicado no cambió | **156 de 156** idénticos, excluido `metadatos.generado` | **CUMPLE** |
| 9 | La compuerta no fue debilitada | `10_utils/10_utils.R` **sin cambios** (`git status` vacío sobre esa ruta); 0 usos de `try()` o `suppressWarnings()` sobre `validar_corte()`; `CORTE_FECHA` sin tocar | **CUMPLE** |
| 10 | `docs/` intacto | `git status` acotado a `docs/`: **0 líneas** | **CUMPLE** |

**10 CUMPLE, 0 NO CUMPLE.**

---

## 9. Decisiones tomadas en autonomía

1. **Se eligió Contingencia A** porque 2.3 lo dictó (el contenido es del corte vigente), no por preferencia.
2. **A se aplicó corriendo 32–36 en vez de escribir el atributo a mano**: es el mismo código que produce el sello en producción, cuesta 0,9 s y 0 llamadas gracias a que la captura cruda del corte vigente sí está versionada.
3. **Se restauraron `docs/` y `40_salidas/json/` tras correr `39`**, previa verificación archivo por archivo de que la única diferencia era el timestamp volátil. Sin esa verificación no se habría restaurado nada.
4. **La corrección de causa raíz se limitó a documentar el paso faltante** en `procedimiento_actualizacion.md`, porque la corrección de fondo (versionar los intermedios) es una decisión de diseño que el §5 del encargo excluye explícitamente.
5. **No se tocó `10_utils/10_utils.R`.** La compuerta detectó un defecto real y quedó intacta.

---

## 10. Pendiente de decisión del titular

**¿Deben versionarse los intermedios?** Es la única forma de cerrar la causa raíz de fondo.
Las dos opciones, con su costo:

| Opción | Qué implica | Costo |
|---|---|---|
| **Dejarlo como está** | Cada refresh del bot deja toda copia local desalineada. El titular corre `run_all(from = 32, to = 36)` antes de tocar el `39`. Ya está documentado | 0,9 s por refresh, y recordar hacerlo |
| **Versionar los intermedios** | Quitar `40_salidas/intermedios/*.rds` del `.gitignore` y agregar la ruta al `git add` del workflow. Deja cualquier clon corrible sin paso previo | ~200 KB por refresh en el historial; y contradice el comentario del `.gitignore`, que los declara "regenerables, no entregable ni fuente" |

**Recomendación: dejarlo como está.** El costo de regenerar es 0,9 s y cero tráfico, el
`stop()` es diagnóstico y ahora está documentado; versionar un artefacto derivado para
ahorrar un segundo va contra la razón por la que se ignoró en primer lugar.

**Observación al margen, no corregida:** `procedimiento_actualizacion.md` §"Pendiente 2"
sigue rotulado *"Automatización con GitHub Actions (NO EJECUTAR AÚN)"* y describe el workflow
como pseudocódigo, cuando `.github/workflows/refresh-semanal.yml` existe y corre desde el
2026-07-10. Está fuera del alcance de P-62; queda anotado.
