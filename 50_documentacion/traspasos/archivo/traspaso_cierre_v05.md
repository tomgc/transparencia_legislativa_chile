# Traspaso de cierre — transparencia_legislativa_chile — v05

**Proyecto:** transparencia_legislativa_chile
**Versión:** v05
**Fecha:** 2026-07-10
**Sesión 5** — foco: actualización del backlog, evaluación del primer encargo de
exploración del Senado, diseño del módulo biblioteca histórica y del barrido de
opendata.congreso.cl, y preparación de los encargos de exploración v02.
**Entorno:** Claude conversacional (diseño, encargos, supervisión, verificación
web) + Claude Code (ejecución autónoma de 1 encargo de exploración), Positron/R
local, terminal.
**Archivos principales modificados/creados:**
`50_documentacion/activa/backlog_acumulativo.md` (actualizado 15-19),
`50_documentacion/activa/decisiones/20260710_decision_modulo_biblioteca_historica.md`
(nuevo),
`50_documentacion/activa/decisiones/20260710_decision_barrido_opendata_congreso.md`
(nuevo),
`50_documentacion/activa/encargo_exploracion_senado_v02.md` (nuevo, encargo listo
para ejecutar).
Generados por Claude Code (encargo de exploración v01, rama `explore/api-senado`,
sin merge): `30_procesamiento/31b_explorar_api_senado.R`,
`50_documentacion/activa/exploracion_api_senado.md`, muestras XML en
`andamios/exploracion_api_senado/`, log en `andamios/logs/`.

---

## Resumen ejecutivo

Sesión de diseño y planificación, sin tocar el pipeline en producción. Se
actualizó el backlog acumulativo con las entradas 15-19 de la sesión 4
(pendiente 9 de v04, cerrado). Se ejecutó y evaluó el primer encargo de
exploración de la API del Senado (Claude Code, rama `explore/api-senado`): trabajo
sólido y honesto, tres de cuatro entidades con fuente en `wspublico`, pero con dos
hallazgos que la verificación posterior contra fuentes oficiales corrigió (el
roster de 31 es incorrecto: el Senado tiene 50 en el período vigente LVII; y la
asistencia SÍ existe fuera de `wspublico`, no es hueco). Se registraron dos
pendientes de diseño nuevos: el módulo biblioteca histórica (pendiente 10, eje
proyecto/votación, no reemplaza nada) y el barrido completo de
opendata.congreso.cl (pendiente 11, prioridad baja). Se dejó preparado y en el
repo el encargo de exploración v02 del Senado, que cierra los tres huecos
(asistencia, roster de 50, evaluar opendata.congreso.cl como fuente con ids
estables). No se construyó pipeline del Senado: depende de lo que devuelva v02.
Un error del asistente registrado y corregido en el momento (ver §15).

---

## Estado al cierre

**Qué funciona (sin cambios respecto a v04, no se tocó producción):**
- Pipeline completo de la Cámara con `CORTE_FECHA` explícito; dashboard Fase 2 en
  producción (`https://tomgc.github.io/transparencia_legislativa_chile/`);
  workflow de Actions con gate de conteos; refresh automatizado funcionando.
- Backlog acumulativo actualizado a 19 entradas (era 14 al cierre de v04).

**Qué se agregó esta sesión (diseño/exploración, no producción):**
- Diagnóstico de la API del Senado v01 (rama `explore/api-senado`, sin merge a
  main): script reproducible `31b`, doc `exploracion_api_senado.md`, muestras
  XML reales de senadores/proyectos/votaciones/sesiones.
- Encargo de exploración v02 listo en `activa/`.
- Dos documentos de decisión nuevos en `decisiones/`.

**Qué no se probó / sigue pendiente:**
- El disparo por **cron** del workflow aún no se observa en vivo (heredado de v04,
  pendiente 8).
- No existe pipeline del Senado. Solo diagnóstico exploratorio, con la fuente aún
  no confirmada (v02 debe cerrarla antes de diseñar).
- La rama `explore/api-senado` (v01) queda sin merge: es exploración, no toca main
  hasta que haya pipeline real que integrar.

**Delta respecto a v04:** v04 cerró con la Cámara en producción y el alcance
Congreso completo recién reconocido como pendiente sin iniciar. v05 avanza el
diseño del Senado: primer diagnóstico de fuente hecho, corregido contra fuentes
oficiales, y con un segundo encargo de exploración preparado para cerrar los
huecos. Además nacen dos pendientes de diseño nuevos (10, 11).

---

## Registro detallado de cambios

### Cambio 1 — Actualización del backlog acumulativo (entradas 15-19)
**Archivo:** `50_documentacion/activa/backlog_acumulativo.md`.
**Categoría:** documentación. **Qué:** se copió íntegro el backlog de v04 y se
agregaron las cinco entradas de la sesión 4 (15 corte temporal explícito, 16
migración a GitHub, 17 workflow de Actions, 18 primer refresh en producción, 19
decisión de alcance Congreso completo). Taxonomía ampliada con dos categorías
nuevas (`automatizacion`, `decision de alcance`); conteos actualizados
(`infraestructura` 2→3, `integracion/repo` 1→3); objetivo del proyecto
actualizado para reconocer el alcance Congreso completo. **Por qué:** pendiente 9
de v04 (instrucción ✅ explícita: actualizar antes de cualquier trabajo nuevo).
**Cómo se verificó:** entradas 1-14 intactas sin renumerar; total coherente
(14+5=19); delta v04 declarado. Sin commitear aún (decisión del titular sobre
cuándo).

### Cambio 2 — Ejecución y evaluación del encargo de exploración del Senado v01
**Categoría:** diagnóstico/exploración. **Qué:** se redactó y entregó a Claude
Code el encargo de exploración de la API del Senado (patrón dirigido-por-meta,
insumos-first, muestra real de cada entidad). Claude Code lo ejecutó autónomo en
la rama `explore/api-senado` (commits `a698390`, `a466c88`, `f8a6141`, sin push).
**Evaluación del trabajo:** sólido y honesto — descubrió la firma real
empíricamente en 7 rondas (no la asumió), auto-auditó abriendo cada muestra en R,
reportó el hueco de asistencia sin fabricar endpoint, respetó todos los
invariantes, no tocó los cambios pre-existentes del working tree. Manejo correcto
del caso de detención #3 (elevó la asistencia ausente como decisión del titular en
vez de abortar con entregables incompletos). **Limitación no resuelta:** los
conteos y la firma salen del log de Claude Code, no se verificaron contra los XML
crudos en esta sesión (el asistente conversacional no tenía las muestras en su
filesystem). No bloqueante para lo que sigue.

### Cambio 3 — Verificación contra fuentes oficiales (corrige hallazgos de v01)
**Categoría:** diagnóstico/exploración. **Qué:** búsqueda web para resolver las
dos decisiones abiertas (asistencia y roster). Dos correcciones a los hallazgos de
Claude Code:
- **Roster:** el Senado tiene **50 senadores** en el período vigente (LVII,
  iniciado 11-mar-2026), no 31. El endpoint `senadores_vigentes.php` que devolvió
  31 es un artefacto (desactualizado o filtrado), no la dotación real. La fuente
  de roster de v01 NO sirve para el período vigente.
- **Asistencia:** SÍ existe (v01 la dio por hueco total). Está en el sitio web del
  Senado (`senado.cl/actividad-legislativa/sala/asistencia`) y posiblemente en un
  portal de datos abiertos del Congreso (`opendata.congreso.cl`) que v01 no
  exploró. **No se omite** la asistencia del Senado: el módulo mantiene simetría de
  contrato entre cámaras.
**Por qué relevante:** ambas correcciones cambian la premisa del diseño del
pipeline. Diseñar sobre `wspublico` con roster incorrecto e identidad-por-nombre,
cuando puede existir un portal con ids estables, sería construir sobre la fuente
equivocada. De ahí el encargo v02.

### Cambio 4 — Documento de decisión: módulo biblioteca histórica (pendiente 10)
**Archivo:** `decisiones/20260710_decision_modulo_biblioteca_historica.md` (nuevo).
**Categoría:** decisión de diseño / documentación. **Qué:** registro extenso
(anti-olvido, a pedido del titular) del módulo biblioteca: eje en el proyecto/
votación como entidad de primera clase, historial completo, Congreso completo, con
clasificación temática y búsqueda por concepto ("Familia", "Seguridad") como
objetivo final. **Es un MÓDULO NUEVO, no reemplaza el dashboard por-parlamentario
actual; ambos ejes coexisten.** Desglose en dos hitos: A (corpus Cámara al nuevo
eje + verificar cobertura histórica real, factible ya) y B (extender a Senado +
clasificación temática, depende del pendiente 7). **Por qué:** el titular lo pidió
registrar durante la sesión; la verificación de "todos los registros históricos"
quedó como primer paso del hito A (no se asume, B.1).

### Cambio 5 — Documento de decisión: barrido de opendata.congreso.cl (pendiente 11)
**Archivo:** `decisiones/20260710_decision_barrido_opendata_congreso.md` (nuevo).
**Categoría:** decisión de diseño / documentación. **Qué:** registro del barrido
exploratorio COMPLETO del portal opendata.congreso.cl para inventariar datos
complementarios (comisiones, intervenciones, dietas, viajes, etc.). Prioridad
baja (complementario, no bloqueante). **Distinción clave documentada:** es
distinto del encargo v02, que solo consulta el portal acotado a las necesidades
del Senado; este lo barre entero por lo que podría aportar de nuevo.

### Cambio 6 — Encargos de exploración v02 preparados
**Archivo:** `activa/encargo_exploracion_senado_v02.md` (nuevo, en el repo). Además
se produjo un esqueleto bloqueado del encargo de pipeline del Senado (queda como
artefacto de sesión; el titular decide si lo incorpora al repo). **Categoría:**
planificación / instrumento de sesión. **Qué:** encargo dirigido-por-meta que
cierra los tres huecos (H1 asistencia, H2 roster de 50, H3 evaluar
opendata.congreso.cl como fuente con ids estables), en orden H3→H2→H1 porque el
portal puede resolver los otros dos de una vez. **Por qué:** dejar los encargos
con contexto fresco antes de cerrar, para ejecutarlos al abrir la próxima sesión.

---

## Backlog acumulativo

Ver `50_documentacion/activa/backlog_acumulativo.md` (actualizado esta sesión a 19
entradas; entradas 15-19 agregadas). **Pendiente para el próximo cierre:** agregar
las entradas de la sesión 5. Candidatas (por intención primaria, un "cambio" =
solicitud distinguible del titular): (20) evaluación del primer encargo de
exploración del Senado; (21) módulo biblioteca histórica (decisión de diseño);
(22) barrido de opendata.congreso.cl (decisión de diseño); (23) preparación del
encargo de exploración v02. La actualización del backlog con 15-19 hecha ESTA
sesión ya está reflejada en el archivo, pero como cambio de la sesión 4 (no se
recuenta como cambio de la 5).

---

## Bugs de la sesión

Ninguno. Sesión de diseño y exploración; no se escribió ni modificó código del
pipeline.

---

## Aprendizajes y restricciones descubiertas

- **Un endpoint que responde no es un endpoint correcto.** `senadores_vigentes.php`
  devolvió 31 senadores sin error; el dato es incorrecto para el período vigente
  (son 50). Regla: cuando un conteo devuelto por una fuente no cuadra con el dato
  oficial conocido, dudar de la fuente, no ajustar el supuesto. Verificar el roster
  contra la dotación oficial antes de asumir cobertura.
- **Un "hueco" en una fuente no es un hueco en todas.** v01 concluyó que la
  asistencia del Senado no existe porque no está en `wspublico`; sí existe en el
  sitio web y posiblemente en opendata.congreso.cl. Regla: antes de declarar una
  entidad como hueco total del proyecto, agotar las fuentes alternativas (sitio
  web, portal de datos abiertos del Congreso, no solo el web service tradicional).
- **La identidad por nombre es el riesgo de correctitud central del Senado.**
  `wspublico` identifica al votante/autor por nombre string (tres formatos), sin
  id. Si opendata.congreso.cl trae ids estables, cambia todo el diseño del
  pipeline. Este es el punto que el encargo v02 debe resolver primero.

---

## Decisiones de diseño

### D1 (v05) — Asistencia del Senado: buscar segunda fuente, no omitir
El titular decidió que la asistencia debe existir y buscarse, no omitirse. La
verificación web lo confirmó (existe fuera de wspublico). El módulo mantiene
simetría de contrato entre cámaras. Implicancia: el encargo v02 debe localizar la
fuente estructurada de asistencia; solo si resulta inaccesible de forma
estructurada (solo PDF, o inexistente) se reevalúa omitirla.

### D2 (v05) — Roster de 50, fuente de v01 descartada
La dotación real es 50 (período LVII). `senadores_vigentes.php` no es fuente
confiable de roster para el período vigente. El encargo v02 debe encontrar la
fuente del roster real de 50, priorizando opendata.congreso.cl o el listado del
sitio.

### D3 (v05) — Módulo biblioteca es adición, no reemplazo
Ver documento de decisión completo. El dashboard por-parlamentario actual se
mantiene intacto; el módulo (eje proyecto/votación) se suma. Ambos ejes coexisten.

### D4 (v05) — Encargo v02 antes de diseñar el pipeline del Senado
No se diseña el pipeline del Senado hasta que v02 confirme la fuente primaria, la
existencia de ids estables, el roster de 50 y la fuente de asistencia. Diseñar
antes sería fabricar arquitectura sobre fuente no confirmada (B.1).

### Decisiones de arquitectura AÚN ABIERTAS (heredadas de la sesión de diseño,
### a resolver cuando vuelva v02):
- Arquitectura del pipeline: extendido con capa de normalización vs. duplicado
  (recomendación previa: extendido con contrato común, a confirmar contra la
  fuente real).
- Modelo del dashboard: unificar con filtro `camara` vs. segmentar (recomendación
  previa: unificar; requisito nuevo: el frontend debe tolerar métricas ausentes
  por cámara).
- Resolución de identidad: directa por id vs. capa de fuzzy name matching
  auditable (depende del hallazgo de ids de v02).
Estas están detalladas en el esqueleto bloqueado del encargo de pipeline.

---

## Constantes y parámetros vigentes

Sin cambios respecto a v04 (no se tocó código). Referencia: `CORTE_FECHA`
(sin default silencioso), `piso_perfiles=155L`, `METRICAS_GATE`, cron
`"0 11 * * 1"`, `MAPA_PARTIDO_TENDENCIA`. Ver v04 §Constantes para el detalle.

Dato de referencia nuevo (no es constante de código, es dato de dominio a fijar
en el pipeline del Senado): **dotación del Senado = 50** (período LVII desde
2026-03-11). Análogo al 155 de la Cámara.

---

## Arquitectura de archivos

Ver escáner `50_documentacion/activa/estructura/estructura_actual.md`
(snapshot `20260710_164032`, tomado al cierre de esta sesión). Estructura por
decenas intacta, sin deuda heredada nueva. Novedades de la sesión: los tres
archivos de decisión/encargo en `activa/` y `activa/decisiones/`; los entregables
de la exploración v01 del Senado (`31b`, doc, muestras, log) presentes desde la
rama `explore/api-senado`. La rama de exploración v01 no está mergeada a main.

---

## Pendientes y ruta sugerida

### Inventario

| # | Descripción | Tipo | Complejidad | Dependencias | Criterio de éxito sugerido |
|---|---|---|---|---|---|
| 5 | Diff por-diputado en `10_diff_conteos.R` (solo compara totales; no detecta cambios compensados) | mejora | Baja-Media | Ninguna | Diff detecta un caso sintético de cambio compensado |
| 6 | Acumulación de snapshots `.rds` en Git (cada refresh agrega binarios; sin límite) | deuda técnica | Media | Diferido a propósito hasta decidir alcance Senado | Definir política de retención o mover snapshots viejos fuera del historial activo |
| 7 | **Congreso completo: agregar Senado** | funcionalidad (alcance) | Alta | Encargo v02 debe cerrar la fuente antes de diseñar el pipeline | Sesión de diseño con v02 en mano: arquitectura, resolución de identidad, dashboard; luego encargo de construcción |
| 8 | Observar el primer disparo real por **cron** (no solo `workflow_dispatch`) | verificación | Baja | Que llegue el lunes | Confirmar en Actions que el run programado corrió sin intervención |
| 10 | **Módulo biblioteca histórica** (eje proyecto/votación, adición no reemplazo). Hito A (corpus Cámara + verificar cobertura, factible ya); Hito B (Senado + clasificación temática, depende del 7). Detalle en `decisiones/20260710_decision_modulo_biblioteca_historica.md` | funcionalidad (módulo) | Alta | Hito B depende del 7; B.1 verificar cobertura | Hito A: biblioteca JSON con eje proyecto/votación sin tocar los JSON actuales. Hito B: búsqueda por concepto cruzando ambas cámaras |
| 11 | **Barrido exploratorio completo de opendata.congreso.cl** (datos complementarios: comisiones, intervenciones, dietas, viajes). Distinto del encargo v02. Detalle en `decisiones/20260710_decision_barrido_opendata_congreso.md` | exploración / mejora | Media | Conviene tras el encargo v02; prioridad BAJA | Catálogo del portal con recomendación de 2-3 datasets complementarios |

Nota: el pendiente 9 de v04 (actualizar backlog) quedó cerrado esta sesión.

### Evaluación de deuda técnica

Sin deuda técnica nueva (no se tocó código). La zona más frágil sigue siendo la
acumulación de snapshots en Git (pendiente 6), diferida a propósito hasta saber si
el dataset se duplica con el Senado.

### Auditoría de cierre (POLITICA 5.6, preguntas "Cierre")

Sesión de diseño/exploración sin cambios de código en el pipeline; las preguntas
de cierre sobre validación/reproducibilidad/constantes no aplican a cambios de
esta sesión (no los hubo). Los documentos producidos son de decisión y
planificación. Naming de los archivos nuevos: sin tildes/ñ/espacios, verificado.

### Ruta sugerida para la próxima sesión

**Prioridad 1:** ejecutar el encargo de exploración v02
(`activa/encargo_exploracion_senado_v02.md`) en Claude Code, y evaluar su reporte.
Cierra los tres huecos que bloquean el diseño del pipeline del Senado.

**Prioridad 2:** con v02 en mano, sesión de diseño para resolver las decisiones de
arquitectura abiertas (pipeline extendido vs. duplicado, resolución de identidad,
modelo del dashboard) y completar el encargo de construcción del pipeline del
Senado (esqueleto bloqueado ya preparado).

**Diferir:** pendientes 5, 6 (mejoras no bloqueantes), 11 (barrido opendata,
prioridad baja), y el hito A del módulo biblioteca (10) hasta después de tener el
Senado encaminado. Pendiente 8 (cron) se confirma pasivamente cuando corra el
lunes.

**Recomendación:** Prioridad 1 → Prioridad 2. La exploración v02 es la compuerta:
sin la fuente confirmada, todo diseño del pipeline es especulativo.

---

## Instrucciones específicas para la próxima sesión

⚠️ NO diseñar ni construir el pipeline del Senado sin el reporte del encargo v02 en
mano. La fuente primaria, los ids estables, el roster de 50 y la asistencia deben
estar confirmados primero (B.1).

⚠️ NO asumir que `senadores_vigentes.php` da el roster correcto: devolvió 31, la
dotación real es 50. Usar la fuente que v02 valide.

⚠️ NO confundir el encargo v02 (consulta acotada de opendata.congreso.cl para el
Senado) con el pendiente 11 (barrido completo del portal). Son tareas distintas,
documentadas por separado.

⚠️ NO asumir que el cron ya se probó en producción — solo `workflow_dispatch`
manual fue verificado (heredado de v04).

✅ ANTES de generar comandos de terminal, usar SIEMPRE ruta absoluta completa en
cada línea (`git -C <ruta> ...`), nunca asumir `cd` heredado entre bloques
(regla de userPreferences, violada en v04; respetada en v05).

✅ El módulo biblioteca (pendiente 10) es una ADICIÓN, no un reemplazo del
dashboard actual. Releer su documento de decisión antes de diseñarlo.

🔒 `CORTE_FECHA` sin default silencioso; gate de `10_diff_conteos.R` no se modifica
sin justificar qué caída es aceptable; R único lenguaje incluida toda verificación.
(Invariantes heredados de v04, intactos.)

🔒 La rama `explore/api-senado` (v01) NO se mergea a main: es exploración. Lo mismo
aplicará a `explore/api-senado-v02` cuando corra.

---

## Fragmentos de código de referencia

Sin fragmentos nuevos esta sesión (no se escribió código). Los patrones de
referencia vigentes (gate programático reusable, corte temporal en clave de caché)
están en el traspaso v04 §Fragmentos, sin cambios.

---

## Reapertura

**Nombre del chat:** `transparencia_legislativa_chile, sesión 6 (Opus 4.8)`

**Mensaje de apertura pre-armado:**

> Tipo: CONTINUATION. El protocolo (POLITICA_PROYECTO.md,
> SETTINGS_Y_PROMPTS_OPERACIONALES.md) vive en la knowledge base del Project y se
> lee desde ahí. Adjunto: `traspaso_cierre_v05.md`, `estructura_actual.md`
> (snapshot `20260710_164032`), `backlog_acumulativo.md` (19 entradas). Estado: la
> Cámara sigue en producción sin cambios. Esta sesión se dedicó a diseño: se
> evaluó el primer diagnóstico de la API del Senado (rama `explore/api-senado`, sin
> merge), se corrigió contra fuentes oficiales (el Senado tiene 50 senadores, no
> 31; la asistencia sí existe fuera de wspublico), y se dejó preparado el encargo
> de exploración v02 (`activa/encargo_exploracion_senado_v02.md`) que cierra los
> tres huecos antes de diseñar el pipeline. Nacieron dos pendientes de diseño: el
> módulo biblioteca histórica (10) y el barrido de opendata.congreso.cl (11). Foco
> propuesto: ejecutar el encargo de exploración v02 en Claude Code y evaluar su
> reporte.

**Documentos para la próxima sesión:**

1. *Protocolo en knowledge base* (verificar que esté al día, no adjuntar):
   `POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
2. *Opcionales según foco:* `encargo_autonomo_claude_code_v1.md` (el encargo v02
   sigue ese patrón); `CLAUDE.md` si la sesión correrá en Claude Code.
3. *Específicos de la sesión (SÍ adjuntar):* `traspaso_cierre_v05.md` (este
   documento); `estructura_actual.md` (snapshot `20260710_164032`);
   `backlog_acumulativo.md` (19 entradas). Para ejecutar el encargo v02, no hace
   falta adjuntarlo: ya vive en `activa/` del repo, Claude Code lo lee del
   filesystem. Adjuntar el reporte del encargo v01 (`exploracion_api_senado.md` o
   su log) si se quiere revisar el punto de partida.

**Nota final:** si algún archivo listado cambió entre el cierre de esta sesión y
la apertura de la próxima, adjuntar la versión más reciente y avisarlo en el
mensaje de apertura.

---

## Errores del asistente (registro obligatorio, POLITICA 0.5)

| momento | disparador | que_paso | regla_violada | causa_raiz | salvaguarda_presente | patron |
|---|---|---|---|---|---|---|
| Al indicar al titular en qué carpeta dejar los archivos de la sesión, tras generar los encargos | usuario lo corrigió explícitamente ("tienen que quedar en el directorio del proyecto, no en herramientas_dev") | Se indicó que `encargo_exploracion_senado_v02.md` (y el esqueleto de pipeline) iban a `herramientas_dev/prompts/`, cuando son instrumentos de esta sesión específica del proyecto y van en la documentación activa del propio repo | POLITICA §1.1 / §10 (la documentación del proyecto, incluidos encargos de sesión, vive en `50_documentacion/activa/` del repo); confusión con la biblioteca transversal `herramientas_dev/prompts/`, que es para instrumentos reutilizables cross-proyecto | Se clasificó el encargo como artefacto transversal reutilizable (como los prompts genéricos de `herramientas_dev/`) cuando en realidad es específico de la continuación de este proyecto; la distinción "instrumento transversal vs. instrumento de sesión de un proyecto" no se aplicó al momento de indicar la ruta | POLITICA (§10 sobre ubicación de documentación del proyecto) | nuevo (variante de un error de ubicación/clasificación de archivo: asignar un artefacto específico de proyecto a una carpeta transversal) |

Un error, corregido en el momento; no bloqueó el avance de la sesión.

---

## Nota de reparto (encargos como andamios vs. traspaso)

El encargo de exploración v02 vive en `activa/` (no en `andamios/logs/`) porque es
un instrumento AÚN NO EJECUTADO: es memoria viva de lo que se va a hacer, no
registro congelado de lo que se hizo. Cuando se ejecute, generará su propio log en
`andamios/logs/` (como hizo el v01). El esqueleto bloqueado del encargo de pipeline
del Senado queda como artefacto de esta sesión; el titular decide si lo incorpora
al repo en `activa/` o lo mantiene fuera hasta desbloquearlo.
