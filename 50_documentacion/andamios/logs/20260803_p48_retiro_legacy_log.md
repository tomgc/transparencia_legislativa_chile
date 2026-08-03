# Log de ejecución — P-48: retiro del contrato legacy de asistencia

- **Fecha de ejecución:** 2026-08-03 · **Sesión 15**
- **Rama:** `retiro/contrato-legacy-asistencia`, nacida de `origin/main` (`64a0ab9`)
- **Corte vigente:** `CORTE_FECHA <- "2026-07-27"` (fuente: `10_utils/10_configuracion.R:41`,
  leído en la Fase 0; no se escribió a mano en ninguna parte)
- **Encargo:** `50_documentacion/andamios/50_encargo_p48_retiro_contrato_legacy.md`

---

## 1. Resumen de la ejecución

Entraron las siete fases del encargo, en orden, sin detención. El contrato legacy
de asistencia dejó de publicarse (cinco campos del perfil y uno del índice) y el
extractor perdió su segunda descarga completa de la asistencia, que era el costo
recurrente que el pendiente venía pagando en cada refresh semanal.

Estado final: cuatro commits en la rama, PR abierto sin mergear, `main` intacto.
El panel adversarial de cuatro agentes independientes no encontró ninguna
diferencia.

Dos observaciones de método que costaron trabajo y quedan registradas abajo: el
criterio de éxito de la Fase 1 no era alcanzable como estaba escrito (§6), y el
corte quirúrgico del bloque legacy en el `33` se llevó una línea de más que hubo
que restaurar (§6).

---

## 2. Inventario de commits

| # | Hash | Tipo | Título | Qué hizo |
|---|---|---|---|---|
| 1 | `4f0bfba` | refactor | retirar campos legacy de asistencia del JSON publicado (P-48) | El `39` deja de leer `asistencia.rds`; el perfil pierde los 5 campos y el índice pierde `tasa_asistencia`. 313 archivos |
| 2 | `970d564` | refactor | eliminar la extracción legacy de asistencia y su descarga duplicada (P-48) | El `33` pierde su bloque 1 completo y el `# REVISAR` que anunciaba este retiro. 311 archivos |
| 3 | `545d053` | docs | corregir la glosa que citaba el campo legacy retirado (P-48) | Prosa de `docs/index.html` L511-513. 1 archivo |
| 4 | `a2b0933` | chore | ignorar la configuración local de Claude Code (P-55) | `.gitignore`. 1 archivo |
| 5 | *(este)* | docs | log de ejecución del retiro del contrato legacy (P-48) | Este archivo |

---

## 3. Cambios sustantivos

### 3.1 `39_consolidar_json.R` — retiro del contrato publicado

**Qué.** Del bloque `asistencia` de cada perfil salieron `anio`, `n_sesiones`,
`n_asiste`, `n_no_asiste` y `tasa_asistencia`; queda con `alcance_temporal`,
`periodo_vigente`, `en_ejercicio` y `sesiones`. Del índice salió
`tasa_asistencia`. Del código salieron `leer("asistencia")`, su `stopifnot` de
llave, su `cobertura()`, el `resumen_asistencia` y su `left_join`.

**Por qué.** Desde `f55430d` (sesión 14) ningún consumidor lo lee. `anio` no se
pierde: su valor viaja en `asistencia.alcance_temporal.anio_proceso`, con ámbito
declarado, así que retirarlo no borra información sino una duplicación sin
ámbito.

**Decisión tomada en autonomía.** El encargo pedía comprobar si `validar_corte()`
espera un número fijo de sellos, porque la lista pasa de 7 a 6. Leído
`10_utils/10_utils.R:104-124`: recorre `names(sellos)` y compara los cortes entre
sí, sin número fijo ni nombre de archivo concreto. **No hubo que adaptarla**, y
por eso `10_utils/10_utils.R` no aparece en ningún commit. El `log_msg` que
reporta la cantidad ya la derivaba de `length(sellos_intermedios)`, así que ahora
dice 6 sin tocar nada.

**Cómo se verificó.** Antes del commit: 0 de 155 perfiles con algún campo
residual; 0 de 155 entradas del índice con `tasa_asistencia`; y contra la línea
base de la Fase 1, **1 058 008 claves comparadas en 155 perfiles y 1 705 en el
índice, 0 diferencias**, excluido `metadatos.generado`. `docs/data` reproduce
`40_salidas/json` en los 155 md5.

### 3.2 `33_extraer_asistencia.R` — retiro del bloque legacy

**Qué.** Salió el bloque 1 completo: `extraer_asistencia_long()`, su llamada, la
validación de dominio de ese bloque, el agregado por diputado, su validación de
integridad y la escritura de `40_salidas/intermedios/asistencia.rds`. Salió
también el `# REVISAR` que anunciaba este retiro. Se reescribió el encabezado
(propósito, insumos, salidas) para describir una sola granularidad.

**Por qué.** Era una segunda descarga completa de la asistencia en cada refresh,
bajo su propia clave de caché, sostenida solo para alimentar campos que ya no
consumía nadie.

**Decisiones tomadas en autonomía.**

- `40_salidas/intermedios/asistencia.rds` **no estaba trackeado**
  (`git ls-files` vacío; el `.gitignore` ya excluye `40_salidas/intermedios/*.rds`),
  así que no hubo `git rm`: se borró del árbol de trabajo y basta.
- Los `.rds` de la clave `asistencia_long_<anio>` en `20_insumos/camara/` **no se
  borraron**, según instrucción: son captura cruda e inmutable por gobernanza.
  Solo dejaron de leerse.
- Dos comentarios del bloque nominal comparaban su universo con el del bloque
  legacy ("el legacy filtra solo por Estado…", "el esquema es distinto al del
  cache legacy"). Al desaparecer el bloque quedaban colgando; se reescribieron
  para que la comparación quede en pasado y siga explicando por qué la clave de
  caché es la que es. Es prosa, no fórmula.
- `00_run_all.R` y `10_utils/10_diff_conteos.R` no nombran ni el intermedio ni la
  métrica legacy (comprobado por búsqueda): no requirieron adaptación.

**Cómo se verificó.** Regeneración completa 32-36 y 39, y comparación contra la
salida de la **Fase 2**: 1 058 008 claves en 155 perfiles y 1 705 en el índice,
**0 diferencias**, excluido `metadatos.generado`. Eso es lo que prueba que
retirar la descarga duplicada no altera el dato publicado.

**Evidencia textual del barrido único** (criterio de éxito 4). Antes, el `33`
registraba dos cache hits de asistencia:

```
[33_asistencia] [INFO] cache hit: 20260727_asistencia_long_2026_tope-inf.rds
[33_asistencia] [INFO] Registros de asistencia (largo): 10690
[33_asistencia] [INFO] Escrito: .../asistencia.rds (239 filas)
[33_asistencia] [INFO] cache hit: 20260727_periodo_legislativo.rds
[33_asistencia] [INFO] cache hit: 20260727_asistencia_nominal_2026_tope-inf.rds
```

Después, uno solo:

```
[33_asistencia] [INFO] cache hit: 20260727_periodo_legislativo.rds
[33_asistencia] [INFO] cache hit: 20260727_asistencia_nominal_2026_tope-inf.rds
[33_asistencia] [INFO] Nominal: 10690 filas, 69 sesiones, 239 ids distintos.
```

### 3.3 `docs/index.html` — glosa

La glosa del bloque de derivación afirmaba que `tasa_asistencia` seguía publicado
en el JSON y que solo no se consumía en el cliente. Tras el retiro eso es falso
sobre el contrato. Se reescribió para declarar que `tasa_presencia` es el único
indicador de asistencia del índice y que `tasa_asistencia` ya no se publica.
**Cambio de prosa únicamente**; ninguna expresión que lea datos se tocó.

---

## 4. Estado de las cuatro premisas (§2.4 del encargo)

| # | Premisa | Veredicto | Evidencia |
|---|---|---|---|
| 1 | `docs/index.html` no consume campos legacy; L511 es prosa | **CONFIRMADA** | 9 líneas con ocurrencias antes del cambio: L511 (prosa), L1120 (comentario) y 7 lecturas, todas sobre `ej.*`, `pv.*`, `pvj.*`, `a.periodo_vigente.*` |
| 2 | Los únicos archivos de código que nombran el contrato son el `33` y el `39` | **CONFIRMADA con matiz** | La búsqueda devuelve 4 archivos: `33`, `39`, `docs/index.html` (prosa + lecturas de Capa 3, ya contemplado por la premisa 1) y `50_documentacion/andamios/50_medicion_p48_p52_p56.R`, que es el script de medición de esta misma sesión — andamio, no pipeline. Ninguno más |
| 3 | `10_diff_conteos.R` no depende de los campos retirados | **CONFIRMADA** | Leído entero: `contar_conteos_json()` solo lee `votaciones.n_votaciones`, `proyectos.n_proyectos` y `votos[].proyecto` (líneas 31-51). `METRICAS_GATE` no incluye ninguna métrica de asistencia. El workflow tampoco: solo orquesta |
| 4 | El `+0` entre los cortes del 25 y del 27 es real (P-56) | **CONFIRMADA** | 7 de 7 cachés pareados por sufijo con md5 idéntico entre `20260725_*` y `20260727_*`; el nominal da 10 690 filas, 69 sesiones y `fecha_ultima = 2026-07-22` en ambos cortes |

---

## 5. Veredicto de Pages (Fase 0.8)

**Pages republicó.** El `index.html` servido en
`https://tomgc.github.io/transparencia_legislativa_chile/` y el
`docs/index.html` de `origin/main` tienen el mismo md5,
`d946f6ebce626391dac28d51dd8a5262`, y el mismo tamaño, 72 289 bytes. Con esto
queda cerrada la prioridad 1 de la sesión, que el titular no había podido
comprobar.

---

## 6. Lo que costó: dos tropiezos y un falso positivo

### 6.1 El criterio de éxito de la Fase 1 no era alcanzable como estaba escrito

La Fase 1.3 pedía que `git status --porcelain -- docs/ 40_salidas/json/` saliera
**vacío** tras regenerar, y declaraba que cualquier diferencia era "un hallazgo
mayor que cambia el encargo". Salió con **310 archivos modificados** (155 perfiles
× 2 copias; el índice no).

No es un hallazgo mayor: es que `metadatos.generado` es un timestamp de reloj que
se reescribe en cada corrida, de modo que `git status` **nunca** puede quedar
vacío después de regenerar. El propio encargo lo reconoce en la Fase 2.3, donde
manda excluirlo de la comparación; la Fase 1.3 simplemente no lo contempló.

Antes de detenerme lo medí: comparación clave a clave entre la versión
commiteada y la regenerada, **la única ruta que difiere es `metadatos.generado`,
155 veces sobre 155 perfiles**, y el índice tiene 0 diferencias sobre 1 860
claves. Es decir, la salida publicada **sí** es reproducible desde el estado
actual, que es lo que la comprobación quería establecer. Se siguió adelante.

*Para el próximo encargo:* el check correcto es la comparación clave a clave con
`metadatos.generado` excluido, no `git status`.

### 6.2 El corte del bloque legacy se llevó una línea de más

Al eliminar el rango de líneas del bloque 1 se fue también el `# ====` de
apertura del banner del bloque 2, que quedó huérfano. Se detectó al releer el
archivo inmediatamente después del corte y se restauró en el mismo movimiento,
renombrando el banner a `EXTRACCION NOMINAL (Capa 3)`, ya que "bloque 2" no
significa nada cuando no hay bloque 1. No llegó a ningún commit.

### 6.3 Un `grep` con metacaracteres dio un falso vacío (Fase 0)

La comprobación de la premisa que busca `refresh/${CORTE}` en el workflow —usada
en encargos anteriores— vuelve a fallar si se corre sin `-F`: `{` y `}` son
metacaracteres y el patrón no matchea, devolviendo vacío como si la línea no
existiera. Con `-F` aparece en la línea 108. El encargo ya lo advertía; se anota
porque es la tercera vez en la cartera que un check de verificación falla por su
propio patrón y no por el objeto verificado.

**No hubo bugs de producto.** Ninguno de los tres tropiezos llegó a un commit ni
alteró un dato.

---

## 7. Verificación de invariantes (§3 del encargo)

| 🔒 | Invariante | Veredicto | Evidencia |
|---|---|---|---|
| 1 | `main` no recibe escrituras directas | **PASA** | Todo el trabajo en `retiro/contrato-legacy-asistencia`; `origin/main` sigue en `64a0ab9` |
| 2 | No mergear ningún PR | **PASA** | El PR #3 del bot (`refresh/2026-08-03`, abierto 13:53Z) se dejó intacto; el PR de esta rama se abre sin mergear |
| 3 | No disparar el workflow | **PASA** | Ninguna invocación de `workflow_dispatch` ni de `gh workflow run` en toda la ejecución |
| 4 | `sin_registro` no se imputa | **PASA** | Sigue siendo tercer estado: 5 entradas en 2 de 155 perfiles, verificado por agente independiente |
| 5 | Las rebajas se persisten y no entran en ninguna fórmula | **PASA** | El bloque nominal no se tocó; siguen viajando al JSON y ninguna fórmula las usa |
| 6 | Ningún campo sobreviviente cambia de valor | **PASA** | 1 058 008 claves en 155 perfiles y 1 705 en el índice, 0 diferencias, verificado además por agente independiente con su propio comparador |
| 7 | Gate de conteos, commit condicional y protección de `main` intocables | **PASA** | `10_diff_conteos.R` y el workflow no se modificaron (no aparecen en ningún commit); no requerían adaptación |
| 8 | El backlog no se renumera ni se reescribe | **PASA** | `backlog_acumulativo.md` no se tocó |
| 9 | No editar traspasos, logs ni escáneres | **PASA** | Ningún archivo de `traspasos/`, `logs/` previos ni `estructura/` en los commits |

---

## 8. Panel adversarial (Fase 5)

Cuatro agentes de solo lectura, cada uno con comparador propio en R, sin
reutilizar los checks de las fases anteriores.

| # | Afirmación auditada | Denominador declarado | Veredicto |
|---|---|---|---|
| 1 | Invarianza de valores | 155 perfiles, **1 058 938 rutas** (unión) + 1 860 del índice | **PASA**. 930 diferencias = exactamente 6 × 155: las 5 retiradas + `metadatos.generado`. Ninguna ruta inesperada. Comparó con 22 dígitos de precisión |
| 2 | Completitud del retiro | 155 perfiles en `40_salidas/json` **y** 155 en `docs/data` | **PASA**. `asistencia.n_sesiones` (nivel superior) no existe; `asistencia.periodo_vigente.n_sesiones` sí. El bloque `asistencia` tiene exactamente 4 claves en los 155. Índice: 0/155 con `tasa_asistencia`, 155/155 con `tasa_presencia` |
| 3 | Coherencia interna de la Capa 3 | 155 perfiles, 2 ámbitos | **PASA**. Las dos identidades cuadran 155/155 en ambos ámbitos; denominador común de `periodo_vigente` = **51**, valor único; las 4 tasas re-derivadas cuadran 155/155 a 1e-12; y el control cruzado que reconstruye los conteos desde `sesiones[]` coincide 155/155 |
| 4 | Contrato del índice | 155 entradas, en `40_salidas/json` y `docs/data` | **PASA**. `indice.tasa_presencia` == `perfil.asistencia.periodo_vigente.tasa_presencia` en 155/155, diferencia máxima 0. Control de discriminación: difiere de `en_ejercicio` en 61/155, así que la prueba no es degenerada |

El agente 2 dejó una nota metodológica honesta: su primera pasada marcó falla
espuria por tratar "aparición de `anio` en cualquier parte" como violación;
`proyectos.anio` y `votaciones.anio` son campos preexistentes de otros bloques,
ajenos a esta afirmación. Corregido el nivel, PASA.

---

## 9. Cifras críticas

| Métrica | Valor | Fuente |
|---|---|---|
| Perfiles publicados | 155 | corrida del `39`, esta sesión |
| Claves comparadas, perfiles (Fase 2 y Fase 3) | 1 058 008 | comparador de verificación, esta sesión |
| Claves comparadas, índice | 1 705 | ídem |
| Diferencias en campos sobrevivientes | **0** | ídem, y agente adversarial 1 |
| Sesiones del alcance / del periodo vigente | 69 / 51 | log del `33`, esta sesión |
| Denominador común de `periodo_vigente` | 51, valor único en los 155 | agente adversarial 3 |
| Filas de la serie nominal | 9 183 | log del `33` |
| Entradas `sin_registro` | 5, en 2 de 155 perfiles | agente adversarial 3 |
| Perfiles con `n_no_asiste` = 0 / > 0 (periodo vigente) | 68 / 87 | conteo en R sobre `docs/data`, esta sesión |

---

## 10. Pendientes abiertos

- **P-52 — conforme, con un hallazgo abierto que NO se corrigió.** La auditoría
  de apertura da conforme: **11 scripts** del pipeline (`00_run_all.R`,
  `00_escanear_proyecto.R`, los 3 de `10_utils/` y los 6 de `30_procesamiento/`)
  y **cero rutas absolutas escritas a mano** (búsqueda de `/Users/tomgc` en los
  11: sin resultados). El hallazgo abierto:
  `CODIGOS_JUSTIFICACION_OBSERVADOS` está declarada en
  `30_procesamiento/33_extraer_asistencia.R:162`, y es una constante metodológica
  —el catálogo observado de códigos de justificación—, no una derivada de la
  corrida; su lugar natural es `10_utils/10_configuracion.R`. **No se movió en
  este encargo por instrucción explícita**: mezclarla con el retiro del contrato
  ensuciaría el diff. Queda para el titular.
- **P-55 — resuelto.** `.claude/settings.local.json` contenía una entrada de
  permisos con **rutas absolutas del filesystem del titular**, en un repositorio
  público. Se ignoró el archivo, no la carpeta: `.claude/launch.json` sí está
  versionado y debe seguir estándolo (configura el servidor de preview, útil para
  cualquiera que clone). Su contenido no se reproduce aquí a propósito.
- **P-56 — cerrado.** Ver la premisa 4 de la §4. No se re-investigó.
- **`# REVISAR` que sobreviven:** el del `39` sobre `rebaja_asistencia` /
  `rebaja_quorum`, que se publican sin uso a la espera de que se establezca su
  semántica reglamentaria (P2). El del `33` que anunciaba este retiro **se fue con
  el bloque**.
- **Dos archivos sin trackear al cierre**, ambos del propio encargo:
  `50_documentacion/andamios/50_encargo_p48_retiro_contrato_legacy.md` y
  `50_documentacion/andamios/50_medicion_p48_p52_p56.R`. No se versionaron porque
  ninguna fase del encargo autoriza un `git add` sobre ellos, y el staging es
  path-scoped. Si el criterio del proyecto es versionar los andamios de la sesión
  —como se hizo en la 11—, es un commit de una línea que decide el titular.

---

## 11. Notas para el revisor

1. **Este PR cambia el contrato de datos publicado.** Es el punto que merece más
   ojo: cualquier consumidor externo que hubiera empezado a leer
   `asistencia.tasa_asistencia` o los cuatro conteos legacy dejará de
   encontrarlos. Dentro del proyecto no queda ninguno, pero el JSON es público y
   servido por Pages, así que la decisión de publicarlo es del titular.
2. **`anio` desapareció del bloque `asistencia`.** Si en alguna vista futura se
   quiere el año, está en `asistencia.alcance_temporal.anio_proceso`, que además
   declara su ámbito. `votaciones.anio` y `proyectos.anio` siguen intactos.
3. **El diff es enorme por los datos, no por el código.** El PR cambia **317
   archivos**: 310 perfiles (155 × las dos copias, `40_salidas/json` y
   `docs/data`), los 2 índices, y solo **5 archivos que no son datos** — el `33`,
   el `39`, `docs/index.html`, `.gitignore` y este log. Todo el volumen es la
   regeneración del JSON.
4. **Mirar con ojo crítico la Fase 1.** Su criterio de éxito no se cumplió tal
   como estaba escrito y la ejecución siguió adelante con un diagnóstico. Está
   documentado en §6.1 y es el punto donde conviene contrastar el razonamiento.
5. **El PR #3 del bot sigue abierto** (`refresh/2026-08-03`). Los dos PRs tocan
   los mismos 310 archivos de datos, así que mergear uno va a exigir resolver el
   otro. Orden sugerido: decidir primero cuál entra, porque el segundo va a
   necesitar regenerarse sobre el `main` resultante, no un merge a mano.
