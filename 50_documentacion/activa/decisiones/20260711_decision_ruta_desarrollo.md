# Decisión — Ruta de desarrollo del portal (D4–D7)

> **Destino canónico:** `50_documentacion/activa/decisiones/20260711_decision_ruta_desarrollo.md`
> **Sesión:** 8 · **Fecha:** 2026-07-11 · **Pendiente que cierra:** P-16
> **Insumos:** `traspaso_cierre_v07.md`, `auditoria_cobertura_camara.md`,
> `diagnostico_proposito.md` (sesión 7, cifras medidas), `backlog_acumulativo.md`.
>
> Este documento cierra las cuatro decisiones abiertas que el traspaso v07 §11
> dejó como condición para construir la ruta. Todas las cifras citadas provienen
> de la medición de la sesión 7, no de inferencia.

---

## Decisión D4 — El eje del portal es el parlamentario. La biblioteca histórica no lo redefine.

**Decisión:** el portal mantiene a la persona como entidad central. La biblioteca
histórica de proyectos y votaciones se reclasifica como **ampliación futura
(Capa 5)**, a construir sobre el modelo actual, no en lugar de él.

**Alternativas consideradas:**

1. Invertir el eje ahora: el proyecto o la votación como entidad de primera clase,
   con el parlamentario como atributo del voto.
2. Construir ambos ejes en paralelo.

**Justificación:** el objetivo declarado del proyecto (backlog, párrafo permanente)
es la fiscalización de un representante: "por parlamentario: asistencia, proyectos
presentados, proyectos votados y sentido del voto, y perfil". Un archivo legislativo
responde otra pregunta ("¿qué hizo el Congreso con la reforma X?"), valiosa pero
distinta. Hoy el portal **no cumple su eje actual**: territorio nulo en 155/155
perfiles, un tercio de los votos ilegible (27.974/84.927), materias vacías en
0/1.311 proyectos. Cambiar de eje antes de cumplir el eje declarado es huir hacia
adelante.

**Tensión resuelta (B.2 simplicidad vs. ambición de alcance):** se resuelve a favor
de cumplir el propósito declarado antes de ampliarlo.

**Costo de diferir (evaluado y bajo):** el modelo actual ya persiste `votacion_id`,
`boletin` y `fecha` por voto. Invertir el eje en el futuro no exige rehacer la
extracción: los datos están.

**Implicancia:** cumple la instrucción ✅ del traspaso v07 §12 ("antes de decidir la
ruta del Senado, decidir si la biblioteca histórica redefine el eje"). Con un "no",
**el Senado queda desbloqueado por este flanco.**

---

## Decisión D5 — El territorio se resuelve con un mapeo verificado y versionado, no con matching difuso en producción.

**Decisión:** cruzar `diputado_id → distrito` contra una fuente externa por nombre,
**verificar exhaustivamente los 155 casos**, y persistir el resultado como archivo de
mapeo versionado que el pipeline lee. El matching difuso es un **andamio de una sola
vez**; lo que queda en producción es una tabla auditada, no una dependencia de
matching.

**Alternativas consideradas:**

1. Retirar la columna "Región / Distrito" y el filtro de región del frontend, bajando
   la promesa del objetivo declarado.
2. Aceptar la asimetría: el Senado con circunscripción poblada, la Cámara sin
   distrito.
3. Matching difuso ejecutándose en cada corrida del pipeline (descartada: introduce
   una dependencia frágil permanente para resolver un problema que se resuelve una
   sola vez).

**Justificación:** es la **única brecha que bloquea el propósito declarado**
(`diagnostico_proposito.md`, tabla de brechas #1: la segmentación territorial figura
explícitamente en el objetivo). La alternativa 2 es peor que la 1: el usuario vería un
filtro que funciona para senadores y no para diputados, sin explicación posible.

El argumento contra el matching por nombre es su tasa de error. Aquí no aplica con la
fuerza habitual: **el universo es de 155 personas conocidas y estables.** No es un join
de 100.000 filas donde un 2% de error es invisible; es una tabla que cabe en una
pantalla y que se verifica a mano una vez. Un error de matching en 155 filas no es un
riesgo estadístico: es un ítem de una lista revisable.

**Precondición NO verificada (medir antes de comprometerse):** el aprendizaje A28
(traspaso v07) establece que `datos.bcn.cl` es accesible por máquina (SPARQL, 200 OK)
pero deja **el predicado de distrito sin resolver**. No está demostrado que BCN
entregue distrito por parlamentario. Tampoco está verificado que el mapeo
diputado→distrito sea estable dentro del período (se asume que sí: un reemplazo
hereda el distrito de quien reemplaza; **es un supuesto, no un dato**).

**Regla de ejecución:** la Capa 2 **abre con una medición, no con código.** Si BCN no
entrega el distrito, la fuente pasa a SERVEL. Si ninguna sirve, esta decisión se revisa
y el fallback es la alternativa 1 (retirar la promesa), nunca inventar el dato.

---

## Decisión D6 — Las comisiones no entran al alcance ahora. La justificación de ausencia sí.

**Decisión:** las comisiones (`WSComision/*`) se difieren a Capa 5. La **justificación
de ausencia** (`Asistencia/Justificacion/{Nombre, RebajaAsistencia, RebajaQuorum}`)
entra en la Capa 3, dentro de la reescritura del `33`.

**Alternativas consideradas:** incorporar las comisiones ahora (la fuente las expone
con `Diputado/Id` cruzable al roster; el esfuerzo es ~1 script nuevo).

**Justificación:** las comisiones **no están en el objetivo declarado**. Sumar una
entidad nueva mientras las entidades existentes no cumplen su promesa es completismo,
no propósito (B.2). El bajo costo de una tarea no es razón suficiente para hacerla
antes que lo que sí bloquea el propósito.

La justificación de ausencia es el caso inverso: **es asistencia** (está en el
objetivo), responde una pregunta real del ciudadano ("¿faltó justificado?"), y entra a
**costo marginal cero** porque el `33` se reescribe de todos modos para D2 (contrato
simétrico nominal por sesión). Fue, además, el gap que el panel adversarial de la
sesión 7 destapó y que la enumeración inicial había dado por inexistente (A27).

**Salvedad heredada:** la asistencia a comisión NO está confirmada
(`retornarSesionesXComisionYAnno` devolvió 0 sesiones en las comisiones muestreadas
para 2025/2026). No se promete: requeriría exploración adicional antes de comprometerse.

---

## Decisión D7 — El 31,5 % de votos sin proyecto no requiere trabajo: ya está resuelto en presentación.

**Decisión:** ninguna acción. La legibilidad del voto sin proyecto de ley **ya está
implementada en el frontend**. Se documenta como cerrada para que no vuelva a
proponerse.

**Estado verificado (lectura de `docs/index.html`, sesión 8):**

- **Columna "Boletín"** (L825-827): si el voto tiene boletín lo muestra; si no, muestra
  `row.tipo` (Proyecto de Resolución / Acuerdo / Otros) en itálica con estilo
  diferenciado (`.voto-tipo-sinbol`). El comentario del código lo declara
  explícitamente: "deja claro que es un instrumento sin boletín, no un dato faltante".
- **Columna de contenido** (L832-836): si el voto tiene proyecto resuelto, muestra el
  título real del proyecto y sus materias; si no, cae a `row.descripcion` (la
  descripción cruda de la votación).

Es decir: el ciudadano **ya ve qué instrumento se votó y qué decía**, incluso cuando no
hay proyecto de ley asociado.

**Justificación de fondo (se mantiene):** A26 (traspaso v07) cerró el punto con
evidencia autoritativa: join sobre 490 boletines, d=460, c=0, a=0, b=212 (suma 672). Las
212 sin boletín son Proyecto de Resolución (97), "Otros" (95) y Proyecto de Acuerdo
(20): **cero Proyecto de Ley**. No es un defecto reparable del pipeline: es una
propiedad del universo votado, y la UI ya la comunica con honestidad.

**Corrección de registro:** la brecha #2 del `diagnostico_proposito.md` ("~1/3 de los
votos ilegibles", 27.974/84.927) describe correctamente **el JSON**, no la UI. El
asistente la trasladó a la UI sin leer `index.html` y propuso como trabajo algo que ya
existía. Registrado como error del asistente (ver más abajo).

**Invariante que esta decisión protege:** ⚠️ el 31,5 % NO se trata como bug, ni en el
pipeline ni en la UI. Si reaparece la tentación de "arreglarlo", releer A26 y esta
decisión antes.

---

## La ruta, por capas

| Capa | Contenido | Criterio de éxito (B.4) | Bloquea a |
|---|---|---|---|
| **0** | P-15 — sello de procedencia en los intermedios | ✅ **Cerrada (sesión 8).** `run_all(only = 39)` reproduce el publish o falla con `stop()` diagnóstico. Verificado con prueba de falla real y panel adversarial. | — |
| **1** | **Presentación (frontend, cero pipeline).** (a) Levantar el recorte a 16 votos: botón "ver los N votos" que expande la lista completa. (b) Que la celda de Región/Distrito **lea el dato** en vez de hardcodear "Sin dato" (L718), degradando a "Sin dato" solo si es `null`. | (a) Un diputado con N votos puede mostrar los N. (b) La celda de región refleja el dato del JSON, cualquiera sea. **Cero cambios en el pipeline.** | **(b) desbloquea silenciosamente la Capa 2** |
| **2** | **Territorio.** Medir la fuente → cruzar → verificar los 155 → versionar el mapeo. | `distrito` y `region` poblados y auditados en 155/155, **o** decisión explícita y documentada de retirar la promesa si la fuente falla. | nada |
| **3** | **Contrato simétrico de asistencia (D2).** Nominal por sesión + `Sesion/FechaInicio` + justificación. Reescritura del `33`. | El intermedio de asistencia es nominal por sesión, con fecha, en ambas cámaras. El denominador heterogéneo [43, 61] queda explicado, no oculto. | Capa 4 |
| **4** | **Senado.** P-13 (cerrar las 8 preguntas del contrato), P-9 (crosswalk, del titular), P-7 (pipeline). | Portal con ambas cámaras bajo el contrato común. | — |
| **5** | **Ampliación.** Comisiones, biblioteca histórica, comparativas (asistencia vs. promedio del partido, autor→voto, disciplina partidaria). | — | — |

### Fuera de las capas

**Higiene (sesión propia, no un hueco entre capas):** P-14 (7 ramas sin mergear,
incluida `fix/sello-corte-intermedios` de hoy), P-17 (siete scripts `31*` de
exploración conviviendo con el pipeline en `30_procesamiento/`), P-18 (push de `main`).
La sesión 7 abrió con una pérdida de memoria estructural que se materializó por
exactamente este descuido: tres sesiones de traspasos estaban untracked. No es
cosmética.

**P-9 (crosswalk partido → tendencia del Senado) puede avanzar en paralelo desde ya:**
es lo único de la Capa 4 que no depende de la Capa 3, es de baja complejidad, y es
**no delegable** (🔒: la clasificación de tendencia no se altera autónomamente;
`IND = NA_character_` es intencional).

---

## Decisión D8 — Los chips de materias se dejan como están (cierra P-19).

**Decisión:** ninguna acción sobre los chips de materias. La UI construida en la sesión
3 se mantiene intacta.

**Alternativas consideradas:** (1) retirar la UI de materias, dado que opera sobre un
campo vacío (0/1.311 proyectos, 3 % de los votos-con-proyecto); (2) buscar la materia
por otra vía (el catálogo `catalogo_materias.xml` existe en `andamios/muestras/`).

**Justificación:** `renderMaterias()` (L789-794 de `index.html`) ya degrada con
honestidad: ante materias vacías muestra "Sin materias registradas" en vez de un chip
falso o un vacío ambiguo. **No es un bug: es la comunicación correcta de un hueco de
fuente.** Retirar la UI sería trabajo para borrar algo que ya se comporta bien y que
revive solo si la fuente puebla el campo. La alternativa 2 no se descarta, pero es
exploración de fuente (Capa 5), no presentación.

---

## Corrección de registro (arrastrada a esta decisión)

El traspaso v07 §9 declara `CORTE_FECHA = 2026-07-06`. **El valor real en
`10_utils/10_configuracion.R` es `2026-07-10`**, verificado en la sesión 8 durante la
Fase 0 del encargo de P-15. La arqueología del publish confirmó que `docs/data/`
corresponde al corte del 10 (155/155 perfiles calzan, con control de votos validando el
método) y que el intermedio on-disk era el stale, del caché del 06.

**Implicancia:** la conjetura del asistente al cierre de la sesión 8 ("el publish
podría estar adelantado respecto a su corte declarado, segundo síntoma de la misma
causa raíz") era **falsa**. Nunca hubo segundo síntoma. Queda registrada como error del
asistente (POLITICA 0.5) en el traspaso v08.

**Pendiente de verificación:** revisar si el traspaso v04 (donde se introdujo
`CORTE_FECHA`) también declara el valor incorrecto, lo que indicaría que el error de
registro viene de más atrás.

---

## Principios y tensiones

- **B.1 (pensar antes de codificar / sin supuestos implícitos):** las dos
  verificaciones pendientes de este documento (el predicado de distrito en BCN; el
  render actual del voto sin proyecto en `index.html`) están **declaradas como no
  verificadas**, no asumidas. Ambas capas abren midiendo.
- **B.2 (simplicidad primero):** decide D4 (no cambiar de eje) y D6 (no sumar
  comisiones). El criterio operativo: cumplir el propósito declarado antes de ampliarlo.
- **B.4 (criterio de éxito antes de codificar):** cada capa lleva el suyo, definido
  aquí y no al momento de ejecutar.
- **Tensión declarada (completismo vs. propósito):** la auditoría de cobertura
  inventarió ~14 gaps. Esta ruta adopta **cuatro** (justificación de ausencia, nominal
  por sesión, fecha de sesión, join estructurado como deuda preventiva de prioridad
  baja) y difiere el resto. Que la fuente exponga un campo no es razón para consumirlo.
