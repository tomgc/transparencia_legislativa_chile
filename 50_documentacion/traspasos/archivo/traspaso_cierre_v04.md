# Traspaso de cierre — transparencia_legislativa_chile — v04

**Proyecto:** transparencia_legislativa_chile
**Versión:** v04
**Fecha:** 2026-07-10
**Sesión 4** — foco: diseño y construcción del sistema de actualización
(corte temporal explícito + Actions), migración a GitHub, primer refresh
automatizado en producción.
**Entorno:** Claude conversacional (diseño, encargos, supervisión) + Claude
Code (ejecución autónoma de 2 encargos), Positron/R local, terminal.
**Archivos principales modificados:** `10_utils/10_configuracion.R`,
`10_utils/10_utils.R`, `10_utils/10_diff_conteos.R` (nuevo), `00_run_all.R`,
`.github/workflows/refresh-semanal.yml` (nuevo),
`50_documentacion/activa/procedimiento_actualizacion.md` (nuevo), `CLAUDE.md`,
`20_insumos/camara/*` (snapshots migrados/nuevos).

---

## Resumen ejecutivo

Se cerró el pendiente central heredado de v03 (el date-stamping en la clave
de caché) reemplazando `Sys.Date()` por un parámetro explícito `CORTE_FECHA`,
verificado con cache-hit reproducible y con `only=39` intacto. Se migró el
proyecto a GitHub (repo público `tomgc/transparencia_legislativa_chile`,
Pages activo sobre `/docs`) tras auditoría de seguridad manual del titular
(no automática). Se construyó y probó un workflow de GitHub Actions que
automatiza el refresh semanal con un gate de sanidad de conteos que aborta
el job ante cualquier caída; se disparó manualmente en producción y
funcionó de punta a punta (re-descarga real, gate OK, commit y push
automatizados, `95dedbc`). Los cinco pendientes de v03 relacionados con
actualización e infraestructura quedaron cerrados. Emergió una decisión de
alcance no trivial: el proyecto debe cubrir el Congreso completo (Cámara +
Senado), no solo la Cámara — queda como pendiente de diseño nuevo, sin
iniciar. Dos errores del asistente registrados y corregidos en el momento
(ver §15).

---

## Estado al cierre

**Qué funciona (última ejecución exitosa):**
- Pipeline completo con `CORTE_FECHA` explícito: corrida real en producción
  vía Actions, corte 2026-07-10, 155 perfiles, gate OK, commit `95dedbc`.
- `only=39` reproduce perfiles idénticos desde intermedios congelados
  (verificado dos veces: cierre del encargo de corte temporal y cierre del
  encargo de Actions, tras revertir residuos de prueba).
- Dashboard Fase 2 en producción real: `https://tomgc.github.io/transparencia_legislativa_chile/`
  (Pages activo, republicado automáticamente tras cada push a `main`).
- Workflow de GitHub Actions probado en producción con `workflow_dispatch`:
  9m50s, todos los steps en verde, gate OK, push exitoso.
- `10_diff_conteos.R` expone gate programático (`$gate`, `$motivos`),
  probado en ambos sentidos (crecimiento real → OK; caída simulada → FAIL,
  exit 1).

**Qué no funciona / no se probó aún:**
- El disparo por **cron** (schedule) del workflow no se ha observado en vivo
  todavía — solo se probó `workflow_dispatch` manual. El cron corre lunes
  11:00 UTC; primera observación real será la próxima semana.
- No existe extracción de datos del Senado. El pipeline cubre únicamente la
  Cámara de Diputadas y Diputados (alcance de Fase 1, ahora reconocido como
  incompleto respecto al objetivo real del proyecto, ver §11 y §8).

**Delta respecto a v03:** v03 cerró con main integrado localmente
(`71ff7c3`) sin remoto y con el date-stamping como bloqueante activo. v04
cierra con: date-stamping resuelto, remoto configurado y sincronizado
(`origin` = GitHub, público, Pages activo), automatización funcionando en
producción, y un refresh real ya publicado.

---

## Registro detallado de cambios

### Cambio 1 — CORTE_FECHA reemplaza Sys.Date() en la clave de caché
**Archivos:** `10_utils/10_configuracion.R`, `10_utils/10_utils.R`,
`00_run_all.R`. **Categoría:** infraestructura / deuda técnica.
**Qué:** nueva constante `CORTE_FECHA` (string `AAAA-MM-DD`, sin default
silencioso); nueva función `corte_para_clave()` que valida formato y hace
`stop()` claro si falta/vacía/inválida; `con_cache` la usa en vez de
`Sys.Date()`; `run_all()` valida el corte al inicio (antes de cualquier
paso), no a mitad de pipeline. **Por qué:** el date-stamping (`Sys.Date()`
en la clave) era el bloqueante central heredado de v03 — un snapshot
descargado un día no daba cache-hit al día siguiente, forzando re-descarga
no controlada y cambios de conteo silenciosos (corpus creció 218→228
mociones entre el 06 y el 09-jul en sesión 3). **Cómo se verificó:** dos
`run_all(only=34)` consecutivos con mismo `CORTE_FECHA` → cache-hit, mtime
del snapshot idéntico, sin re-descarga; `stop()` verificado sin corte y con
formato inválido. **Dependencias afectadas:** todo `con_cache()` en 33/34/35
(y 36 vía Fase 2, ver Cambio 2). Ejecutado por Claude Code (encargo
`encargo_corte_temporal_v01.md`), commit `3765dbf`.

### Cambio 2 — Migración de snapshots al corte canónico
**Archivos:** `20_insumos/camara/` (rename).
**Categoría:** infraestructura. **Qué:** decisión (criterio propio de
Claude Code, dentro de su autonomía normal) de fijar un corte canónico
único `2026-07-06` para todo el dataset; solo se renombró el snapshot de
detalle (capturado 09-jul, enriquecimiento estable de los mismos
proyectos del 06-jul) a ese corte. **Por qué:** etiquetar todo "as-of
06-jul" es honesto (el detalle no agrega proyectos nuevos, solo enriquece
los existentes) y permite que un `run_all()` con `CORTE_FECHA=2026-07-06`
dé cache-hit en TODO, sin drift. Alternativas descartadas: corte
por-fecha-real (dejaría cortes distintos, un run re-descargaría el
detalle) y archivar-y-partir-limpio (re-descargaría todo el corpus).
**Cómo se verificó:** `only=39` reproduce perfiles idénticos; `only=36`
pasó a dar cache-hit (317/317, prueba directa de que el drift se resolvió).
Commit `e1af2b9`.

### Cambio 3 — Procedimiento de actualización semanal (documentación)
**Archivos:** `50_documentacion/activa/procedimiento_actualizacion.md`
(nuevo). **Categoría:** documentación. **Qué:** procedimiento manual de 5
pasos (respaldar JSON, fijar `CORTE_FECHA`, `run_all()`, diff de conteos
antes de publicar, commit atómico) más un esqueleto en prosa/pseudocódigo
del futuro workflow de Actions, explícitamente marcado "no ejecutar aún".
**Por qué:** diseño acordado en sesión conversacional antes de construir
nada — evita improvisar el canal de ejecución sin decidir primero qué
automatiza y qué no. Commit `e5c4fdd`.

### Cambio 4 — Script de diff de conteos
**Archivos:** `10_utils/10_diff_conteos.R` (nuevo).
**Categoría:** infraestructura / verificación. **Qué:** utilidad reusable
(ubicada en `10_utils/` por convención POLITICA 1.2.4, no es paso de
pipeline) que compara dos versiones del JSON publicado y reporta diff de
conteos clave (perfiles, votaciones, mociones, split con/sin proyecto).
Standalone o sourced. **Cómo se verificó:** self-diff = 0 en todos los
conteos. Commit `a0d0c9c`.

### Cambio 5 — Migración a GitHub
**Categoría:** integración/repo. **Qué:** repo creado (`gh repo create`),
inicialmente privado, remoto `origin` configurado, primer push de todo el
historial (`main` con 1048 objetos). **Auditoría de seguridad
pre-migración (protocolo 4.3 Fase 1):** el titular declaró haberla hecho
manualmente y confirmó que el proyecto está limpio; **no se ejecutó el
script automático `diagnostico_migracion_github.R`** — desviación
explícita y documentada del protocolo, decisión del titular, no del
asistente. **Por qué relevante:** el protocolo marca esta auditoría como
compuerta de gobernanza; se registra la excepción para que quede
trazable, no para objetarla. **Verificación previa al push:** `git status`
limpio confirmado antes de empujar. Sin script de comandos (ejecutado
directo en terminal por el titular con comandos que el asistente
proporcionó).

### Cambio 6 — Repo público + GitHub Pages
**Categoría:** integración/repo. **Qué:** visibilidad cambiada de privado a
público (`gh repo edit --visibility public`) porque Pages sobre repos
privados requiere plan pago y el proyecto es 100% público por naturaleza
(datos de diputados, Rama A de POLITICA §6.2); Pages activado sirviendo
`/docs` en `main` (`gh api .../pages`). **Resultado:**
`https://tomgc.github.io/transparencia_legislativa_chile/` operativo.
**Decisión del titular**, no unilateral del asistente (presentada como
alternativas con recomendación antes de ejecutar).

### Cambio 7 — Workflow de GitHub Actions para refresh semanal
**Archivos:** `.github/workflows/refresh-semanal.yml` (nuevo),
`10_utils/10_diff_conteos.R` (extendido). **Categoría:** infraestructura /
automatización. **Qué:** workflow con dos disparadores (`cron: "0 11 * *
1"` — lunes 11:00 UTC, horario fijo todo el año por ser Actions UTC puro —
y `workflow_dispatch` manual); pasos: checkout, instalar R, instalar 7
paquetes vía RSPM, calcular corte del día (`date +%Y-%m-%d`), copiar el
JSON del checkout de HEAD a un temporal (JSON "anterior", NO un respaldo
local persistente — adaptación del invariante al entorno de runner), `sed`
sobre `10_configuracion.R` (ancla `^CORTE_FECHA <- `, no matchea
comentarios), `run_all()`, gate de conteos, commit+push condicional con
`GITHUB_TOKEN` automático (sin PAT). `10_diff_conteos.R` se extendió
(cambio quirúrgico, aditivo) para retornar además `$gate` (`"OK"`/`"FAIL"`)
y `$motivos`: el gate falla si `perfiles < 155` (piso absoluto) o si cae
cualquiera de `perfiles, votaciones, mociones, votos_con_proyecto`;
`votos_sin_proyecto` se reporta pero no gatea (una caída ahí es mejora, no
pérdida). **Por qué estas decisiones:** las tres (sed vs. env var,
GITHUB_TOKEN vs. PAT, abortar vs. solo advertir) se fijaron en sesión
conversacional antes de redactar el encargo, no improvisadas por Claude
Code. **Cómo se verificó:** validación de sintaxis YAML + ASCII puro;
simulación local completa con corte de prueba nuevo (refresh real,
289.9s, re-descarga confirmada); gate probado en AMBOS sentidos con exit
codes reales sin pipe (crecimiento → exit 0; caída simulada 155→150 →
exit 1); tras la prueba, revert completo verificado sin residuos
(`only=39` reprodujo el corpus congelado exacto, diff=0). Ejecutado por
Claude Code (encargo `encargo_github_actions_v01.md`), commits `07a2852`,
`c950e5b`, `0fe8803`. Log:
`50_documentacion/andamios/logs/20260710_github_actions_refresh_log.md`.

### Cambio 8 — Merges a main y primer refresh real en producción
**Categoría:** integración/repo. **Qué:** merge `--no-ff` de
`feature/corte-temporal-explicito` (`736e7e9`) y de
`feature/github-actions-refresh` (`deab646`) a `main`, con revisión del
diff completo por el titular antes de cada merge (no solo confianza en el
log del encargo). Push a `origin`. Disparo manual del workflow
(`gh workflow run` + `gh run watch`) como primera prueba en producción:
corrida real de 9m50s, gate `GATE OK -> se publica`, commit automatizado
`95dedbc` (`data: refresh corte 2026-07-10 (automatizado)`) confirmado en
`origin/main` vía `git fetch` + `git log`. **Cómo se verificó:** grep del
log del job (`GATE OK`), confirmación del hash del commit en el remoto,
no solo en el resumen del job. Commit del log del corte temporal
(`ad7ca07`) también commiteado aparte tras un olvido inicial (ver §15,
no es un error de esta categoría, fue una acción pendiente correctamente
identificada y cerrada, no una desviación de regla).

---

## Backlog acumulativo

Ver `50_documentacion/activa/backlog_acumulativo.md`. Estado al cierre de
v04: 14 entradas hasta v03; esta sesión agrega entradas 15-19
(aproximadamente — el archivo debe actualizarse aparte con el detalle
exacto de esta sesión, siguiendo el mismo patrón de v01→v02→v03; no se
adjuntó reescritura completa en este traspaso porque el archivo de
`backlog_acumulativo.md` no fue solicitado para edición en esta sesión).
**Pendiente inmediato de la próxima apertura:** extraer y agregar las
entradas de sesión 4 al backlog antes de iniciar trabajo nuevo, siguiendo
la nota metodológica ya establecida (un "cambio" = solicitud distinguible
del titular). Candidatas de esta sesión: (15) corte temporal explícito,
(16) migración a GitHub, (17) workflow de Actions, (18) primer refresh en
producción, (19) decisión de alcance Congreso completo.

---

## Bugs de la sesión

Ninguno de código. La única incidencia técnica fue de herramienta, no de
lógica: `$?` tras un pipe (`Rscript ... | grep`) medía el exit code de
`grep`, no de `Rscript`, durante la prueba local del gate en Claude Code;
se corrigió redirigiendo sin pipe. No es un bug del entregable (el gate en
el workflow real no usa pipe), es un artefacto de cómo se probó
localmente. Documentado en el log de Actions §4, sin acción pendiente.

---

## Aprendizajes y restricciones descubiertas

- **El JSON "anterior" en un runner de CI no puede ser un respaldo local
  persistente.** A diferencia del procedimiento manual (que sí tiene
  filesystem persistente entre pasos), en Actions cada corrida parte de
  un checkout limpio: el JSON "previo" correcto es una copia del árbol de
  trabajo tal como llegó del checkout, tomada ANTES de que `run_all()` lo
  sobrescriba. Regla concreta: cualquier automatización futura en CI que
  necesite "el estado antes del cambio" debe copiarlo explícitamente al
  inicio del job, nunca asumir que existe un directorio de respaldo de
  una corrida anterior.
- **Pages en repos privados requiere plan pago.** Antes de activar Pages,
  verificar visibilidad del repo. Para proyectos ya declarados 100%
  públicos (Rama A), pasar a público antes de Pages es la secuencia
  correcta, no una sorpresa a mitad de camino.
- **`GATE OK`/`GATE FAIL` con exit code real, sin pipe, es la única forma
  confiable de probar un gate de CI localmente antes de confiar en el
  runner.** Confirmar el exit code inmediatamente después del comando
  real (no de memoria, no derivado de un pipe intermedio) es coherente
  con el principio de verificación entre generación y commit
  (`encargo_autonomo_claude_code_v1.md` §2.4).

---

## Decisiones de diseño

### D1 — Corte canónico único vs. corte por-fecha-real (Cambio 2)
Ya detallada en Cambio 2. Implicancia: cualquier futuro enriquecimiento de
datos ya extraídos (no datos nuevos) debe evaluarse contra la misma
pregunta — ¿es dato nuevo o refinamiento de lo ya capturado bajo el
corte vigente? Si es refinamiento, hereda el corte existente.

### D2 — Inyección de CORTE_FECHA por sed vs. variable de entorno
Decidida en sesión conversacional antes del encargo de Actions: `sed`
sobre el archivo de configuración (no `Sys.getenv()`), para que el commit
del refresh incluya el cambio de `CORTE_FECHA` como parte trazable del
historial de datos, no como un valor efímero de la corrida de CI.
Implicancia: el archivo de configuración cambia en cada refresh
automatizado; esto es intencional, no un descuido.

### D3 — Gate excluye votos_sin_proyecto de la condición de falla
Ya detallada en Cambio 7. Implicancia: si en el futuro se agrega una
métrica nueva al gate, aplicar el mismo criterio (¿una caída en esta
métrica es pérdida de datos, o es una mejora estructural?) antes de
incluirla ciegamente en `METRICAS_GATE`.

### D4 — Visibilidad pública sin auditoría automática de seguridad previa
El titular decidió saltar el script `diagnostico_migracion_github.R` del
protocolo 4.3 Fase 1, confiando en revisión manual propia. Registrado
como excepción explícita (Cambio 5), no como error — es una decisión del
titular dentro de su autoridad, pero se deja constancia porque el
protocolo la marca como compuerta de gobernanza no negociable
("esperar revisión del usuario"), y aquí se saltó la ejecución del
script, no la revisión en sí.

### D5 (pendiente de decisión completa, solo iniciada) — Alcance del
proyecto: Congreso completo
El titular corrigió durante la sesión que el alcance correcto del
proyecto es el Congreso completo (Cámara + Senado), no solo la Cámara.
Esto no se diseñó ni se construyó en esta sesión — se registra como
decisión de alcance para la próxima apertura. Ver §11.

---

## Constantes y parámetros vigentes

| Constante | Valor | Archivo | Nota |
|---|---|---|---|
| `CORTE_FECHA` | `"2026-07-10"` (tras el refresh automatizado) | `10_utils/10_configuracion.R` | Cambia en cada refresh; sin default silencioso |
| `piso_perfiles` (gate) | `155L` | `10_utils/10_diff_conteos.R` (parámetro de `diff_conteos_json`) | Piso absoluto; ajustar si el roster cambia estructuralmente |
| `METRICAS_GATE` | `c("perfiles","votaciones","mociones","votos_con_proyecto")` | `10_utils/10_diff_conteos.R` | `votos_sin_proyecto` excluido a propósito (D3) |
| cron del workflow | `"0 11 * * 1"` | `.github/workflows/refresh-semanal.yml` | Lunes 11:00 UTC, fijo todo el año |
| `MAPA_PARTIDO_TENDENCIA` | sin cambios desde v02 | `10_utils/10_configuracion.R` | No tocado esta sesión |

---

## Arquitectura de archivos

Ver escáner `50_documentacion/activa/estructura/estructura_actual.md`
(snapshot `20260710_121540`, tomado antes del merge final de Actions —
no refleja aún `.github/workflows/` ni los archivos del segundo encargo;
re-escanear en la próxima apertura). Estructura por decenas intacta, sin
deuda heredada nueva. Novedad de esta sesión: carpeta `.github/workflows/`
(fuera de la numeración por decenas por convención de GitHub, excepción
correcta — no es parte del flujo de ejecución del pipeline R).

---

## Pendientes y ruta sugerida

### Inventario

| # | Descripción | Tipo | Complejidad | Dependencias | Principios | Criterio de éxito sugerido |
|---|---|---|---|---|---|---|
| 5 | Diff por-diputado en `10_diff_conteos.R` (el actual solo compara totales; no detecta cambios compensados) | mejora | Baja-Media | Ninguna | C.8 (validación de integridad) | Diff detecta un caso sintético de cambio compensado (uno sube, otro baja, total igual) |
| 6 | Acumulación de snapshots `.rds` en Git (cada refresh agrega binarios; sin límite) | deuda técnica | Media | Ninguna, diferido a propósito | POLITICA §1.5 (`_archivo/`) | Definir política de retención o mover snapshots viejos fuera del historial activo |
| 7 | **Congreso completo: agregar Senado** | funcionalidad (alcance) | Alta | Ninguna, pero redefine el objetivo del proyecto | B.1 (sin supuestos implícitos), POLITICA §8 (bifurcación) | Sesión de diseño dedicada: explorar API del Senado, decidir pipeline extendido vs. duplicado, decidir si el dashboard unifica o segmenta por cámara |
| 8 | Observar el primer disparo real por **cron** (no solo `workflow_dispatch`) | verificación | Baja | Que llegue el lunes | — | Confirmar en la pestaña Actions que el run programado corrió sin intervención |
| 9 | Actualizar `backlog_acumulativo.md` con las entradas 15-19 de esta sesión | documentación | Baja | Ninguna | POLITICA §10 | Archivo actualizado siguiendo el patrón v01→v02→v03 |

### Evaluación de deuda técnica

Zona más frágil: acumulación de snapshots en `20_insumos/camara` (pendiente
6) — no es urgente, pero cada refresh semanal la empeora linealmente; vale
la pena resolverla antes de que el repo crezca a un tamaño incómodo, no
después. El pendiente 7 (Congreso completo) no es deuda técnica: es una
redefinición del objetivo del proyecto declarada en el propio backlog
(`Fase 1 cubre solo la Cámara`), que ahora se sabe incompleta respecto a
la intención real del titular.

### Auditoría de cierre (POLITICA 5.6, preguntas "Cierre")

| # | Pregunta | Respuesta |
|---|---|---|
| 5 | ¿Cada transformación crítica tiene check de validación? | Sí — gate de conteos cubre el refresh automatizado |
| 6 | ¿Los outputs son reproducibles e idempotentes? | Sí — verificado dos veces con `only=39` |
| 7 | ¿Decisiones metodológicas como constantes nombradas? | Sí — `piso_perfiles`, `METRICAS_GATE`, cron explícitos y documentados |
| 8 | ¿Nombres de archivos y carpetas sin tildes, ñ ni espacios? | Sí, sin excepciones nuevas |

Sin "no" en esta auditoría; sin pendientes nuevos derivados de ella.

### Ruta sugerida para la próxima sesión

**Prioridad 1:** actualizar `backlog_acumulativo.md` (pendiente 9) — bajo
costo, evita que el backlog quede desfasado antes de sesiones más largas.

**Prioridad 2:** sesión de diseño dedicada para el pendiente 7 (Congreso
completo). Es alta complejidad y redefine alcance; no debe mezclarse con
trabajo operativo menor (un cambio conceptual por intervención, y este es
grande).

**Diferir:** pendientes 5 y 6 (mejoras, no bloqueantes) hasta después de
decidir el alcance del Senado — tiene más sentido diseñar el diff
por-diputado y la política de retención de snapshots ya sabiendo si el
dataset va a duplicarse en tamaño con el Senado.

**Recomendación:** Prioridad 1 → Prioridad 2, en ese orden — el backlog
es de minutos y evita perder trazabilidad; la decisión de Senado merece
una apertura propia con el traspaso ya limpio.

---

## Instrucciones específicas para la próxima sesión

⚠️ NO iniciar diseño o construcción del Senado sin una sesión de diseño
conversacional dedicada primero (mismo patrón que se usó para el sistema
de actualización: diseñar antes de encargar a Claude Code).

⚠️ NO asumir que el cron ya se probó en producción — solo
`workflow_dispatch` manual fue verificado. Confirmar el primer disparo
programado (lunes) antes de declarar la automatización completamente
validada.

✅ ANTES de cualquier trabajo nuevo, actualizar `backlog_acumulativo.md`
con las entradas de sesión 4 (pendiente 9).

✅ ANTES de generar comandos de terminal, usar SIEMPRE ruta absoluta
completa en cada línea (`git -C <ruta> ...`), nunca asumir `cd` heredado
entre bloques de comandos — regla ya existía en userPreferences y se
violó dos veces esta sesión (ver §15).

🔒 `CORTE_FECHA` sin default silencioso — cualquier cambio a
`10_configuracion.R` debe preservar el `stop()` si no está fijada.

🔒 El gate de `10_diff_conteos.R` (`METRICAS_GATE`, `piso_perfiles`) no se
modifica sin justificar explícitamente qué caída es aceptable y cuál no
(D3).

🔒 R único lenguaje, incluida cualquier verificación o script auxiliar de
CI.

---

## Fragmentos de código de referencia

**Patrón de gate programático reusable** (la forma correcta de exponer una
verificación tanto para consola como para un gate de CI en este proyecto):

```r
# Retorna invisible una lista con datos + veredicto, sin romper el uso
# standalone (que solo imprime). Ver 10_utils/10_diff_conteos.R completo.
mi_verificacion <- function(...) {
  # ... cálculo y print normales ...
  motivos <- character()
  if (condicion_de_falla) motivos <- c(motivos, "descripción del problema")
  gate <- if (length(motivos) > 0) "FAIL" else "OK"
  invisible(list(datos = df, gate = gate, motivos = motivos))
}
```

**Patrón de corte temporal en clave de caché** (ya en producción, no
reinventar si se necesita un mecanismo similar en otra parte del
pipeline):

```r
corte_para_clave <- function() {
  corte <- CORTE_FECHA
  if (is.null(corte) || !nzchar(corte) || is.na(as.Date(corte, "%Y-%m-%d", optional = TRUE))) {
    stop("CORTE_FECHA no esta fijada o es invalida. Definela como AAAA-MM-DD en 10_configuracion.R antes de correr el pipeline.")
  }
  format(as.Date(corte), "%Y%m%d")
}
```

---

## Reapertura

**Nombre del chat:** `transparencia_legislativa_chile, sesión 5 (Opus 4.8)`

**Mensaje de apertura pre-armado:**

> Tipo: CONTINUATION. El protocolo (POLITICA_PROYECTO.md,
> SETTINGS_Y_PROMPTS_OPERACIONALES.md) vive en la knowledge base del
> Project y se lee desde ahí. Adjunto: `traspaso_cierre_v04.md`,
> `estructura_actual.md` (re-escaneado), `backlog_acumulativo.md`
> (actualizado con entradas 15-19 antes de abrir esta sesión). Estado:
> corte temporal explícito en producción, migración a GitHub completa
> (repo público, Pages activo), workflow de Actions probado en producción
> con `workflow_dispatch` (pendiente: primer disparo por cron). Decisión
> de alcance pendiente de diseño: Congreso completo (Cámara + Senado), no
> solo Cámara. Foco propuesto: sesión de diseño para el Senado (no
> construcción todavía).

**Documentos para la próxima sesión:**

1. *Protocolo en knowledge base* (verificar que esté al día, no adjuntar):
   `POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
2. *Opcionales según foco:* `CLAUDE.md` si la sesión correrá en Claude
   Code; `encargo_autonomo_claude_code_v1.md` si la sesión de diseño del
   Senado deriva en un encargo de exploración de API a Claude Code.
3. *Específicos de la sesión (SÍ adjuntar):* `traspaso_cierre_v04.md`
   (este documento); `estructura_actual.md` re-escaneado (el snapshot
   `20260710_121540` quedó desactualizado, tomado antes del merge de
   Actions); `backlog_acumulativo.md` actualizado con entradas 15-19.

**Nota final:** si alguno de estos archivos cambió entre el cierre de esta
sesión y la apertura de la próxima, adjuntar la versión más reciente y
avisarlo en el mensaje de apertura.

---

## Errores del asistente (registro obligatorio, POLITICA 0.5)

| momento | disparador | que_paso | regla_violada | causa_raiz | salvaguarda_presente | patron |
|---|---|---|---|---|---|---|
| Comandos de terminal para revisar/mergear la primera rama (corte temporal), tras la ejecución del encargo | usuario lo señaló explícitamente ("no me diste la ruta completa") | Los comandos git (`cd`, `git add`, etc.) se dieron sin ruta absoluta consistente en cada línea | userPreferences, sección Code edits: "In terminal commands, always use the full path from the project root; never assume the current working directory" | El primer comando del bloque sí llevó `cd` a la ruta absoluta; se asumió que el resto de la sesión de terminal heredaba ese directorio — exactamente el supuesto que la regla prohíbe | userPreferences | nuevo |
| Migración a GitHub, tras el éxito de `gh repo create --source=... --remote=origin` | usuario lo señaló al ejecutar (`error: remote origin already exists`) | Se entregó un segundo bloque de comandos (fallback manual de `git remote add origin`) sin advertir que era condicional al fracaso del primero; el usuario corrió ambos en secuencia | SETTINGS §1.2.6 ("Un cambio conceptual por intervención"); implícitamente, falta de claridad sobre condicionalidad de instrucciones alternativas | El primer bloque incluía tanto el camino "con gh CLI" como el fallback "manual" en la misma respuesta sin marcar explícitamente que solo uno debía ejecutarse según el resultado del primero | Ninguna regla explícita lo cubre directamente; buena práctica de claridad no aplicada | nuevo (variante del patrón de ruta incompleta: instrucciones dadas sin condicionar su ejecución al resultado del paso anterior) |

Ambos corregidos en el momento; no bloquearon el avance de la sesión.
