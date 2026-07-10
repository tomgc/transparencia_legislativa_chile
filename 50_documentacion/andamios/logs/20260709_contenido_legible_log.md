# Log de ejecución — Contenido legible de proyectos + trazabilidad voto→proyecto

**Fecha:** 2026-07-09
**Rama:** `feature/contenido-legible-trazabilidad` (desde `main`; sin push).
**Entorno:** Claude Code, macOS, R 4.5.2.
**Naturaleza:** andamio congelado (registro de ejecución, no se actualiza).

## 1. Resumen

Encargo de construcción (toca producción) que hace LEGIBLE y TRAZABLE el
contenido de proyectos en los perfiles JSON, a partir del diagnóstico
`20260709_diagnostico_contenido_legible.md`: la API expone por proyecto
`tipo_iniciativa` y `materias` (que 35 descartaba), y el join voto→proyecto se
resuelve por boletín (100 % de las votaciones de Proyecto de Ley; el resto son
instrumentos sin boletín por naturaleza). Se agregó un paso 36 que baja el
contenido de los proyectos autorados y votados, 39 los une en los bloques
`proyectos` y `votaciones` del perfil, y el frontend los muestra (materias como
chips; título real del proyecto votado; tipo del voto cuando no hay boletín).
Cuatro commits atómicos. Auto-auditoría independiente en R 4/4 PASA. Sin push.

## 2. Inventario de commits

| Fase | Hash | Tipo | Título |
|------|------|------|--------|
| A+B | `3c26e10` | feat | 36 detalle de proyectos (tipo_iniciativa y materias) autorados y votados |
| C | `c064580` | feat | contenido y trazabilidad en perfiles json |
| D | `c678898` | feat | ui contenido legible y voto-proyecto |
| E | (este log) | docs | log de la sesión |

## 3. Cambios sustantivos (qué / por qué / cómo se verificó)

### 3.1 `10_utils/10_utils.R` — parser compartido
`parsear_contenido_proyecto(doc)` extrae de `retornarProyectoLey` el título,
`tipo_iniciativa` (texto legible) y `materias` (data.frame id/nombre; 0 filas si
no hay, nunca fabricado). Reusado por el paso 36. Verificado: materias con id
character; dominio tipo_iniciativa {Moción, Mensaje}.

### 3.2 `30_procesamiento/36_extraer_detalle_proyectos.R` — nuevo paso
Lee los boletines de los intermedios CONGELADOS (`proyectos.rds` autorados +
`votos.rds` votados, unión), baja el detalle por boletín (resiliente: tryCatch
por boletín, `con_cache`), y escribe `proyectos_detalle.rds` (una fila por
boletín, `materias` list-col). Registrado en `00_run_all.R` (id 36, entre 35 y
39). Verificado (`run_all(only=36)`): 317 boletines, autorados 218/218, votados
104/104 (100 % del join); 5 con materias, 312 sin.

### 3.3 `30_procesamiento/39_consolidar_json.R` — consolidación
- `proyectos[]`: cada proyecto suma `tipo_iniciativa` y `materias` (array; `[]`
  explícito si vacío).
- `votos[]`: cada voto suma `tipo` (ya en votos.rds) y `proyecto` (sub-objeto
  {boletin,nombre,tipo_iniciativa,materias} si el boletín se resolvió; `null` si
  no). Se preserva el esquema previo del voto.
Los bloques se reescribieron de `transmute` (data.frame) a `lapply` (lista de
listas) para anidar `materias` (array) y `proyecto` (objeto/null) limpiamente.
Verificado: jsonlite serializa NULL→`null`, df 0 filas→`[]`, df 1 fila→array.

### 3.4 `docs/index.html` — frontend
`renderMaterias()` (chips); proyectos muestran tipo + materias o "Sin materias
registradas"; votaciones muestran el título real del proyecto y sus materias, o
el `tipo` del voto cuando no hay boletín. Vanilla JS, sin red (grep = 0).

## 4. Bugs encontrados y resueltos

- **Crecimiento del corpus al re-descargar (causa raíz).** El primer enfoque
  (enriquecer 35 con una clave de caché nueva) re-descargó la LISTA de mociones,
  que creció 218→228 boletines (1313→1391 filas de autoría) en los 3 días desde
  el snapshot del 2026-07-06. Esto rompía la invariante "corre con los
  intermedios ya cacheados" y la auditoría FASE E (c) "n_proyectos intactos", y
  dejaba `votos.rds` (06-jul) inconsistente con `proyectos.rds` (09-jul). **Fix:**
  se revirtió 35, se restauró `proyectos.rds` congelado (desde la captura
  `20260706_proyectos_long_2026.rds` + rol), y todo el detalle se movió al paso
  36, que lee los boletines desde los intermedios congelados (el detalle
  título/tipo/materias es estable entre días). Ver decisión 5.1.
- **`[[` sobre vector nombrado lanza error** (no devuelve NULL) para llave
  ausente, en el script de auditoría. Fix: `did %in% names(map)` antes de indexar.

## 5. Decisiones de diseño

### 5.1 Forma del intermedio de detalle (fusión de Fase A y Fase B)
El encargo planteó Fase A (enriquecer 35, autorados) y Fase B (nuevo 36,
votados) como intermedios separados. Se **fusionaron en un solo paso 36** con un
único intermedio `proyectos_detalle.rds` (unión de boletines autorados +
votados). **Razón (integridad, prevalece sobre la estructura sugerida):** los
responses crudos de `retornarProyectoLey` nunca se cachearon, así que enriquecer
exige re-descargarlos; re-correr 35 refresca la lista de mociones y rompe el
snapshot congelado (bug 4.1). 36 sólo lee boletines de los intermedios
congelados y baja detalle estable, sin tocar `proyectos.rds`/`votos.rds`.
Alternativa descartada: dos intermedios con doble descarga del solape (5
boletines) y riesgo de descongelar el corpus. Un intermedio único además
simplifica 39 (un solo lookup para ambos bloques).

### 5.2 Materias vacías = hueco explícito
La mayoría de las mociones 2026 no traen materias (0 de 228 autoradas); sólo 5
boletines más antiguos (votados) las tienen. Se representa `[]` en el JSON y
"Sin materias registradas" en la UI; nunca se fabrica (invariante 🔒 no
sintético).

### 5.3 `tipo` del voto propagado
`votos.rds` ya traía `tipo` (Proyecto de Ley/Acuerdo/Resolución/Otros); 39 lo
omitía. Se propaga para que un voto sin proyecto muestre su naturaleza en vez de
un boletín ausente.

## 6. Verificación de invariantes (🔒)

| Invariante | Estado | Evidencia |
|-----------|--------|-----------|
| R único lenguaje (pipeline + verificación) | PASA | 36/39/parser en R; auditoría FASE E en R; 0 Python |
| No sintético (materias vacías = hueco) | PASA | `[]` / "Sin materias registradas"; 312/317 sin materias, reales |
| Llaves character (boletin, materia id, ...) | PASA | stopifnot en 39; parser `como_llave`; auditoría |
| Escritura atómica | PASA | `escribir_atomico` en 36 y 39 |
| Navegador solo JSON precomputado; sin CDN | PASA | grep de red en docs/index.html = 0 |
| No alterar tendencia | PASA | 39 no toca índice/tendencia; null=25 intacto |
| No cambiar topes; correr con intermedios cacheados | PASA (con matiz) | MAX_* sin cambios; `votos.rds`/`proyectos.rds` congelados; 36 sólo baja detalle estable. Matiz: el detalle SÍ se descargó hoy (inevitable: los responses crudos no estaban cacheados), pero es temporalmente estable y no cambia conteos |
| No push, no PR | PASA | 4 commits locales en la rama feature |

## 7. Auto-auditoría independiente (FASE E) — 4/4 PASA

Script en R (código nuevo, re-deriva desde `docs/data/perfiles/*.json` + los
intermedios congelados, sin reusar la lógica de 39). 155 perfiles; 52.148 votos
con proyecto, 25.804 sin proyecto (66,9 %, consistente con el 68,5 % de
votaciones-únicas):
- (a) todo voto con boletín resuelto tiene `proyecto != null` — 0 violaciones.
- (b) todo voto sin boletín tiene `proyecto = null` — 0 violaciones.
- (c) `n_votaciones`/`n_proyectos` por diputado intactos vs baseline congelado —
  0 violaciones.
- (d) `materias` siempre array, nunca null — 0 violaciones.

## 8. Cobertura del join voto→proyecto (recalculada)

- Boletines votados resueltos: **104/104 (100 %)**.
- Votos con proyecto ≠ null: **52.148 / 77.952 (66,9 %)**; el resto son votos
  sobre instrumentos sin boletín (Acuerdo/Resolución/Otros), correctamente con
  `proyecto = null` y `tipo` legible.

## 9. Pendientes y `# REVISAR`

- **# REVISAR (cobertura de materias):** la fuente sólo pobló materias en 5 de
  317 boletines (proyectos más antiguos). Las mociones 2026 vienen sin materias.
  No se puede hacer más desde la Cámara; documentado como hueco, no fabricado.
- **# REVISAR (drift del corpus):** el pipeline regenera desde la API en vivo;
  re-correr 34/35 hoy trae más datos que el snapshot 2026-07-06. Este encargo
  congeló el snapshot leyendo los intermedios cacheados. Para un refresh real y
  coherente habría que re-correr 32-36 completo (fuera de alcance; cambia
  conteos). La deuda de la clave de caché sin tope (de sesiones previas) sigue
  abierta.
- **Estado de tramitación vigente** sigue sin exponerse (sólo etapa por votación
  vía `VotacionProyectoLey/Tramite*`, no incorporada aquí — posible mejora
  futura: mostrar la etapa del proyecto votado).
- **Rol autor/coautor** sigue uniforme "firmante" (Orden=0 en la API).

## 10. Notas para el revisor

- La decisión 5.1 (fusionar A+B en 36) es la desviación consciente más
  importante respecto al encargo; se tomó para no descongelar el snapshot.
  Si se prefiere el corpus fresco, basta correr `run_all()` completo (con
  refresco) — pero eso cambia `n_proyectos`/`n_votaciones`.
- Los screenshots profundos del preview salieron intermitentemente en blanco
  (timing del tool); la verificación de la UI se hizo por DOM (`preview_eval`)
  además del screenshot de la sección de votaciones, que sí capturó el título
  real del proyecto y el "Otros" en vez de boletín.
- `proyectos_detalle.rds` es un intermedio gitignored (regenerable por 36); la
  captura cruda `20260709_detalle_proyectos_2026.rds` sí se versionó (provenance
  del snapshot congelado del detalle).
- El diagnóstico y las muestras que fundamentan esto viven en la rama
  `explore/contenido-proyectos-votos` (no en esta feature branch, que partió de
  main).
