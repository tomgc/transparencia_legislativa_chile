# Traspaso de cierre v02 — transparencia_legislativa_chile

## 1. Identificacion

- **Proyecto:** transparencia_legislativa_chile
- **Version del traspaso:** v02
- **Fecha:** 2026-07-06
- **Sesion:** 2 (CONTINUATION). Foco: precisar el invariante R-only, clasificar
  la tendencia de los 18 partidos y correr el pipeline del anno completo.
- **Entorno:** Claude Code, macOS, R 4.5.2. Modelo: Claude Opus 4.8.
- **Archivos principales modificados:** `CLAUDE.md`, `10_utils/10_configuracion.R`,
  `40_salidas/json/` (indice + 155 perfiles regenerados), capturas en
  `20_insumos/camara/`.
- **Registro de ejecucion detallado:**
  `50_documentacion/andamios/logs/20260706_tendencia_annocompleto_log.md`
  (detalle paso a paso no reproducido aqui).

## 2. Resumen ejecutivo

Sesion de continuacion con tres cambios encadenados y committeados atomicamente.
Se cerro la ambiguedad del traspaso v01 §15 (error 2) precisando en CLAUDE.md
que el invariante R-only cubre pipeline Y verificacion/auditoria. El titular
fijo la clasificacion de tendencia de los 18 partidos del roster (taxonomia de
5 niveles; IND=NA), poblando `MAPA_PARTIDO_TENDENCIA`. Se pusieron los topes de
extraccion en Inf y se corrio `run_all()` de cero: 672 votaciones y 218 mociones
(vs 120/150 en sesion 1), con la tendencia propagada a los 155 perfiles. Una
auditoria adversarial EN R (re-parseo de la captura cruda, mapa independiente)
confirmo que la distribucion de tendencia coincide con el indice comprometido.
Quedo pendiente el diseno de la Fase 2 (dashboard) y un # REVISAR nuevo (clave
de cache sin tope). Sin push.

## 3. Estado al cierre

**Funciona (ultima ejecucion 2026-07-06 20:35):**
- `run_all()` de cero: 5 pasos, 0 errores, 167.9s (anno completo).
- indice (155) == perfiles (155); tendencia poblada; auditoria adversarial en R
  PASA (distribucion re-derivada identica al indice).

**No incluido (por alcance):** dashboard (Fase 2), Senado, BCN, GitHub Actions.

**Delta respecto a v01:**
- Invariante R-only precisado (alcance total).
- Tendencia: de 18 partidos en NA -> clasificados (5 niveles); solo IND (25
  diputados) queda NA por decision del titular.
- Cobertura: de topes 120/150 -> anno completo (672 votaciones, 218 mociones).

## 4. Registro detallado de cambios

Detalle en el log (§3). En sintesis, tres cambios conceptualmente independientes:
1. CLAUDE.md — precision del invariante R-only (commit `2ddd754`).
2. `10_configuracion.R` — `MAPA_PARTIDO_TENDENCIA` poblado (commit `a11b3fb`).
3. `10_configuracion.R` (topes Inf) + regeneracion del JSON del anno completo
   (commit `48e158c`).

## 5. Backlog acumulativo

Extraido a archivo independiente en este cierre (segundo cierre, POLITICA §10):
**`50_documentacion/activa/backlog_acumulativo.md`**. Numeracion global continua;
entradas 1-5 de v01 (copiadas integras), entradas 6-8 de la sesion 2. Ver ese
archivo; no se reproduce aqui.

## 6. Bugs de la sesion

Sin bugs de codigo en esta sesion (fue una sesion de clasificacion + corrida de
produccion sobre codigo ya validado en sesion 1). El unico hallazgo tecnico es
una limitacion de diseno preexistente, no un bug introducido: ver §7 y el
pendiente # REVISAR de §11.

## 7. Aprendizajes y restricciones descubiertas

- **La clave de `con_cache()` no codifica el tope de extraccion.** Contexto: si
  se cambia `MAX_*_DETALLE` y se re-corre sin `options(camara.refrescar=TRUE)`,
  el snapshot del dia se reutiliza con el tope viejo (cobertura silenciosamente
  incorrecta). Regla aprendida: una clave de cache debe codificar todo parametro
  que altere el contenido cacheado. Mitigacion aplicada esta sesion: refresco
  forzado. Fix pendiente en §11.
- **Independencia adversarial en R.** La auditoria se re-implemento en R sin
  sourcear los helpers del pipeline (xml2 directo, mapa propio), cumpliendo el
  invariante R-only precisado. Regla: la independencia se logra desacoplando el
  codigo, no cambiando de lenguaje.

## 8. Decisiones de diseno

- **Taxonomia de tendencia de 5 niveles** (izquierda/centroizquierda/centro/
  centroderecha/derecha), IND=NA. Decision del titular. Alternativa: eje binario
  izq/der. Justificacion: mayor resolucion analitica. Implicancia: la vista
  segmentada debe manejar 5 grupos + un grupo NA (IND).
- **Refresco forzado para la corrida del anno completo.** Alternativa: borrar el
  cache manualmente. Justificacion: `camara.refrescar=TRUE` es el mecanismo
  canonico y deja el snapshot del dia consistente con los topes de produccion.

## 9. Constantes y parametros

Fuente canonica: `10_utils/10_configuracion.R`. Cambios de esta sesion:

| Constante | Valor anterior | Valor nuevo | Motivo |
|-----------|----------------|-------------|--------|
| `MAX_VOTACIONES_DETALLE` | `120L` | `Inf` | produccion, anno completo |
| `MAX_PROYECTOS_DETALLE` | `150L` | `Inf` | produccion, anno completo |
| `MAPA_PARTIDO_TENDENCIA` | 18 x `NA` | 17 clasificados + IND `NA` | clasificacion del titular |

## 10. Arquitectura de archivos

Escaner al cierre: `50_documentacion/estructura/estructura_actual.md`
(2026-07-06 20:46; 15 carpetas, 191 archivos). Estructura sin cambios respecto a
v01; solo se agrego `backlog_acumulativo.md` y este traspaso.

## 11. Pendientes y ruta sugerida

### Inventario de pendientes
1. **Diseno y construccion de la Fase 2 — dashboard estatico** (pendiente
   principal). Tipo: funcionalidad nueva. Consume el JSON ya producido. Dos
   decisiones de diseno abiertas: **(a) carga perezosa de perfiles** (el indice
   pesa poco, pero los 155 perfiles suman ~17 MB; cargar `perfiles/<id>.json` on
   demand vs. un bundle unico); **(b) tratamiento de los 25 IND sin tendencia**
   en la vista segmentada por tendencia (grupo "sin clasificar" explicito vs.
   excluirlos del eje). Complejidad: alta. Criterio de exito: dashboard estatico
   que renderiza indice + perfil sin backend, sirviendo el JSON existente.
2. **Fix de la clave de cache (# REVISAR).** Tipo: deuda tecnica. Codificar el
   tope (o "Inf") en la clave de `con_cache` (o invalidar por parametros) para
   evitar reutilizar snapshots con tope distinto. Complejidad: baja. Toca
   `10_utils/10_utils.R` y las llamadas en 33/34/35.
3. **Segunda fuente para distrito/region** (BCN/SERVEL). Heredado. La API de la
   Camara no los expone. Complejidad: alta. Fuera de Fase 1/2.
4. **Estado de tramitacion de proyectos.** Heredado. No expuesto por la Camara;
   `admisible` como proxy. Complejidad: media (otra fuente).
5. **Rol autor/coautor.** Heredado. La API entrega `Orden=0` para todos; no
   jerarquiza. Requeriria otra fuente para el orden de firma.
6. **Asistencia con transicion de periodo.** Heredado. La asistencia por
   ANIO_PROCESO incluye sesiones ene-mar 2026 (periodo previo); evaluar filtrar
   por inicio de periodo. Complejidad: media.

### Evaluacion de deuda tecnica
Zona fragil: la clave de cache (pendiente 2) es la unica deuda tecnica activa.
El resto son huecos de la fuente, no deuda de codigo.

### Auditoria de cierre (POLITICA 5.6, preguntas "Cierre")
- ¿Pipeline corre de cero sin intervencion manual? **Si** (run_all anno completo).
- ¿Cada transformacion critica tiene check de validacion? **Si**.
- ¿Outputs reproducibles e idempotentes? **Si** (con la salvedad del pendiente 2:
  requiere refresco explicito al cambiar topes).
- ¿Decisiones metodologicas como constantes nombradas? **Si** (tendencia y topes).
- ¿Nombres sin tildes/ñ/espacios? **Si**.

### Ruta sugerida para la proxima sesion
Prioridad 1: brief y construccion del dashboard Fase 2, resolviendo primero las
dos decisiones de diseno (carga perezosa; tratamiento de IND). Prioridad 2 (si
hay margen): fix de la clave de cache. Diferir: segundas fuentes (distrito/
region, estado de tramitacion).

## 12. Instrucciones especificas para la proxima sesion

- ⚠️ NO publicar (push) sin visto bueno del titular.
- ⚠️ NO alterar la clasificacion de tendencia de un partido por criterio propio:
  la fija el titular (IND queda NA a proposito).
- ✅ ANTES de cambiar un tope de extraccion, forzar `options(camara.refrescar=TRUE)`
  o el snapshot del dia se reutiliza con el tope viejo (hasta que se arregle la
  clave de cache).
- ✅ ANTES de reportar cifras, recontar programaticamente en R sobre el JSON.
- 🔒 R unico lenguaje del proyecto: pipeline Y verificacion/auditoria. Nada de
  Python en ningun contexto.
- 🔒 Llaves de identificacion siempre `character`.
- 🔒 El navegador (Fase 2) solo lee JSON precomputado; sin backend ni API en
  caliente; web estatica autocontenida sin CDN salvo necesidad declarada.

## 13. Fragmentos de codigo de referencia

Sin patrones nuevos en esta sesion; los estables viven en `CLAUDE.md` y
`documentacion_tecnica_v1.md` y se referencian por nombre. La clasificacion de
tendencia vive en `MAPA_PARTIDO_TENDENCIA` (`10_utils/10_configuracion.R`).

## 14. Reapertura

**Mensaje de apertura pre-armado (copiar al abrir la proxima sesion):**

> Tipo: CONTINUATION. El protocolo (POLITICA_PROYECTO.md,
> SETTINGS_Y_PROMPTS_OPERACIONALES.md) vive en la knowledge base del Project y
> se lee desde ahi. Adjunto: `traspaso_cierre_v02.md`, `estructura_actual.md`,
> `backlog_acumulativo.md`, y `40_salidas/json/indice_diputados.json` mas un
> perfil de muestra (para disenar la vista). Estado: Fase 1 completa y anno
> completo corrido; indice + 155 perfiles con tendencia (5 niveles, IND=NA);
> auditoria en R PASA. Foco propuesto: brief y construccion del dashboard
> estatico (Fase 2), resolviendo primero las dos decisiones de diseno (carga
> perezosa de perfiles; tratamiento de los 25 IND sin tendencia).

**Documentos para la proxima sesion:**
1. *Protocolo en knowledge base (no se adjunta, solo verificar que este al dia):*
   `POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
2. *Opcionales segun foco:* `CLAUDE.md` (correra en Claude Code);
   `documentacion_tecnica_v1.md`.
3. *Especificos de la sesion (adjuntar):* `traspaso_cierre_v02.md`;
   `estructura_actual.md`; `backlog_acumulativo.md`;
   `40_salidas/json/indice_diputados.json` y un `perfiles/<id>.json` de muestra
   (referencia de la estructura que consumira el dashboard).

**Nota final:** si algun archivo listado cambio entre sesiones, adjuntar la
version mas actualizada al abrir y avisarlo.

## 15. Errores del asistente (registro obligatorio, POLITICA 0.5)

| momento | disparador | que_paso | regla_violada | causa_raiz | salvaguarda_presente | patron |
|---------|-----------|----------|---------------|------------|----------------------|--------|
| — | — | Sin errores registrados en esta sesion. | — | — | — | — |

> Seccion obligatoria aun vacia (SETTINGS §2.3 regla 11): la ausencia de errores
> es una afirmacion verificable. Las dos ambiguedades registradas en v01 §15 se
> trataron esta sesion: el error 2 (alcance del invariante R-only) quedo cerrado
> con el commit `2ddd754`; la auditoria de esta sesion se hizo integramente en R.
