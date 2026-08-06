# Traspaso de cierre v07

## 1. Identificación

- **Proyecto:** `transparencia_legislativa_chile`
- **Versión:** v07
- **Fecha:** 2026-07-11
- **Sesión:** 7. Foco: cerrar el pendiente 12 (auditoría adversarial de cobertura
  de la fuente de la Cámara) y, a partir de sus hallazgos, levantar un diagnóstico
  de brecha entre el propósito declarado del portal y lo que hoy entrega.
- **Entorno:** macOS, R 4.5.2, Positron. Claude Code para los dos encargos
  autónomos. Claude conversacional (Opus 4.8) como asistente de análisis.
- **Archivos principales creados:** `30_procesamiento/31f_auditar_cobertura_camara.R`,
  `30_procesamiento/31g_diagnostico_proposito.R`,
  `50_documentacion/activa/auditoria_cobertura_camara.md`,
  `50_documentacion/activa/diagnostico_proposito.md`, más 20 muestras crudas en
  `50_documentacion/andamios/muestras/` y dos logs de ejecución.
- **Archivos de producción modificados:** NINGUNO. Las dos corridas fueron de solo
  lectura sobre el pipeline.

## 2. Resumen ejecutivo

La sesión abrió con una tarea de higiene no prevista: el escáner adjunto no
correspondía a `main`, y al verificar con Git se descubrió que la memoria
estructural de tres sesiones (traspasos v04–v06, la carpeta `decisiones/`
completa, los tres encargos de la sesión 6, el backlog con las entradas 20–23 y
el `ESTADO.md`) estaba **sin versionar**: existía solo en el working tree. Se
commiteó a `main` como `fe0e226` antes de tocar nada más. Cerrado eso, se
ejecutaron dos encargos autónomos consecutivos. El primero cerró el pendiente 12:
el web service de la Cámara expone 5 servicios y 49 operaciones, de las cuales el
pipeline usa 8; se inventariaron ~14 gaps con muestra real, se confirmó A23 y se
extendió (la asistencia trae además justificación por diputado), y su panel
adversarial cazó un falso negativo del propio auditor. El segundo encargo midió la
brecha de propósito y produjo el resultado más importante de la sesión, que es un
resultado **negativo**: la hipótesis central del asistente (que el regex del
script `34` estaba perdiendo boletines y que había datos incompletos o erróneos
publicados) es **falsa**. Con 490 boletines consultados a la fuente, el join
autoritativo devuelve d=460, c=0, a=0, b=212: el regex es exacto y el 31,5% de
votaciones sin boletín es 100% estructural. En cambio, persiguiendo una
discrepancia menor que nadie había pedido investigar, el encargo destapó un hazard
real de reproducibilidad en producción: el intermedio `asistencia.rds` en disco
está desincronizado de lo publicado en `docs/data/`, de modo que
`run_all(only = 39)` hoy republicaría el dashboard con asistencia stale. El
proyecto queda con el mapa completo levantado, cero código de producción tocado, y
una ruta de desarrollo pendiente de construir con las cifras ahora reales.

## 3. Estado al cierre

**Qué funciona:**
- Pipeline de la Cámara en producción, intacto. Última corrida exitosa: el publish
  vigente en `docs/data/` (`CORTE_FECHA = 2026-07-06`).
- Dashboard en GitHub Pages, sin cambios.
- GitHub Actions de refresco semanal, sin cambios.
- `main` ahora sí contiene la memoria estructural del proyecto (`fe0e226`).

**Qué no funciona (descubierto esta sesión):**
- **Reproducibilidad rota.** `40_salidas/intermedios/asistencia.rds` (mtime 11:58,
  máx 58 sesiones) NO corresponde a `docs/data/` (generado 16:13, máx 61 sesiones):
  los 155 perfiles difieren. `votos.rds` sí coincide. Síntoma observable: correr
  `run_all(only = 39)` republica con datos de asistencia distintos a los vigentes.
  Los intermedios están gitignored, así que reflejan la última corrida local
  (residuo de corridas de prueba), no el estado publicado.
- **Territorio: promesa muerta.** `distrito` y `region` son nulos en 155/155
  perfiles. El frontend tiene columna "Región / Distrito" (siempre "Sin dato") y un
  filtro de región que devuelve lista vacía para cualquier región real.
- **Materias vacías.** 0 de 1.311 proyectos presentados traen materia; solo 3% de
  los votos-con-proyecto. Los chips de materias del frontend (sesión 3) operan
  sobre un campo esencialmente vacío.

**Delta respecto a v06:** ninguna línea de código de producción cambió. Lo que
cambió es el conocimiento: se pasó de suponer a medir en cuatro frentes (cobertura
de la fuente, integridad del join, estado de lo publicado, fuentes alternativas de
territorio), y se derogó una hipótesis del asistente que había sido presentada como
hallazgo casi cierto.

## 4. Registro detallado de cambios

### Cambio 24 — Versionado de la memoria estructural (`fe0e226`)
- **Archivos:** `50_documentacion/traspasos/traspaso_cierre_v04.md`, `v05.md`,
  `v06.md`; `50_documentacion/activa/decisiones/` (3 archivos);
  `50_documentacion/activa/encargo_*.md` (3 archivos);
  `backlog_acumulativo.md`; `ESTADO.md`.
- **Categoría:** integración / repo.
- **Qué se hizo:** se commitearon a `main` 9 archivos de documentación que estaban
  untracked o modificados sin commitear.
- **Por qué:** el traspaso es, por protocolo (SETTINGS §2.1), "el único puente
  entre sesiones". Tenerlo untracked contradice su función: un working tree perdido
  se llevaba tres sesiones de memoria. Se detectó porque el escáner mostraba lo
  mismo en dos ramas distintas (los untracked no cambian con el checkout), lo que
  llevó a verificar con `git ls-tree` en vez de con el escáner (aprendizaje A20).
- **Cómo se verificó:** `git status --short` revisado antes del commit; el commit
  reporta 11 files changed, 2430 insertions.
- **Sin pushear.** Queda a decisión del titular.

### Cambio 25 — Auditoría adversarial de cobertura de la Cámara (pendiente 12)
- **Archivos:** `30_procesamiento/31f_auditar_cobertura_camara.R` (nuevo),
  `50_documentacion/activa/auditoria_cobertura_camara.md` (nuevo), 20 muestras en
  `andamios/muestras/`, log `20260710_cobertura_camara_log.md`.
- **Rama:** `explore/cobertura-camara` (desde `main`). Commits `bc3850e`, `978c1ee`.
- **Categoría:** diagnóstico / exploración.
- **Qué se hizo:** se enumeró el catálogo ASMX completo (5 servicios, 49
  operaciones; el pipeline usa 8), se bajó una respuesta real de cada endpoint
  (usado y no usado), se sondearon parámetros y endpoints alternativos, y se
  inventariaron ~14 gaps con muestra real como evidencia.
- **Por qué:** A24 (traspaso v06) estableció que la Cámara se construyó explorando
  hasta el primer endpoint que funcionó, sin el escrutinio adversarial que sí
  recibió el Senado. La pregunta era si arrastraba huecos como A23.
- **Cómo se verificó:** cada gap citando la ruta de su muestra cruda; panel
  adversarial de dos agentes re-derivando las afirmaciones de mayor riesgo.
- **Resultado:** A24 confirmado. La Cámara estaba sub-explorada.

### Cambio 26 — Diagnóstico de brecha de propósito
- **Archivos:** `30_procesamiento/31g_diagnostico_proposito.R` (nuevo),
  `50_documentacion/activa/diagnostico_proposito.md` (nuevo), muestras adicionales,
  log `20260711_diagnostico_proposito_log.md`.
- **Rama:** `explore/diagnostico-proposito` (desde `explore/cobertura-camara`).
  Commits `ddb310f`, `0a2b1dc`.
- **Categoría:** diagnóstico / exploración.
- **Qué se hizo:** cuatro fases. (1) Join autoritativo votación↔proyecto sobre 490
  boletines consultados a la fuente. (2) Estado real de lo publicado en
  `docs/data/`. (3) Análisis del frontend: qué consume, qué promete, cómo degrada
  ante `null`. (4) Comisiones (entidad no cubierta) y mapa de fuentes alternativas
  de territorio (con búsqueda web).
- **Por qué:** el objetivo declarado del proyecto promete cosas (segmentación
  territorial, "qué votó y cómo") cuya entrega real nunca se había medido.
- **Cómo se verificó:** todas las cifras recontadas programáticamente en el momento;
  panel adversarial de dos agentes (uno técnico re-derivando cifras, uno "ciudadano
  adversarial" recorriendo el portal).
- **Tensión declarada:** el encargo se redactó como **medición**, no como decisión.
  Todo lo que requería criterio humano (¿el territorio se busca en otra fuente?, ¿las
  comisiones entran al alcance?) quedó explícitamente fuera y sigue siendo del
  titular. Esto fue deliberado: un encargo de "despeja las dudas estructurales" es
  exploración abierta sin criterio de éxito, el caso donde
  `encargo_autonomo_claude_code_v1.md` §0 dice que el patrón NO aplica.

## 5. Backlog acumulativo

Ver `50_documentacion/activa/backlog_acumulativo.md`. **Delta de esta sesión:** 3
entradas nuevas (24, 25, 26), llevando el total de 23 a 26. Sin refinamientos de
taxonomía ni reclasificaciones. Categoría dominante de la sesión: diagnóstico /
exploración (2 de 3).

## 6. Bugs de la sesión

### Bug 1 — Desincronización intermedio ↔ publicado (ACTIVO, toca producción)
- **Síntoma observable:** `40_salidas/intermedios/asistencia.rds` reporta un máximo
  de 58 sesiones por diputado; los 155 perfiles en `docs/data/perfiles/` reportan
  hasta 61. Los 155 difieren. `votos.rds` sí coincide con lo publicado (los 27.974
  votos con `proyecto: null` cuadran exactamente).
- **Causa raíz:** los intermedios están en `.gitignore`, de modo que el `.rds` en
  disco es el residuo de la última corrida local (una corrida de prueba), no el
  insumo que generó el publish vigente. El `39` consume el intermedio en disco.
- **Consecuencia:** `run_all(only = 39)` hoy republicaría el dashboard con datos de
  asistencia stale, silenciosamente. Nadie lo notaría: el JSON se regenera sin error.
- **Estado:** PENDIENTE. No se corrigió (el encargo era de solo lectura, por diseño).
- **Patrón general aprendido:** un artefacto intermedio no versionado no es una
  fuente de verdad reproducible. Si el pipeline puede correr un paso aislado que
  consume un intermedio, ese intermedio necesita o bien versionarse, o bien
  regenerarse siempre antes de consumirse, o bien llevar un sello (hash/timestamp)
  que el consumidor valide contra lo publicado.
- **Principio violado:** POLITICA 5.2.2 (reproducibilidad completa: "el flujo corre
  de cero sin intervención manual y produce el mismo resultado"). Hoy no lo produce.
- **Cómo se encontró:** de rebote. Claude Code persiguió una discrepancia menor que
  el encargo no le había pedido investigar. Vale la pena notarlo: el hallazgo más
  grave de la sesión no estaba en el plan de ninguno de los dos encargos.

## 7. Aprendizajes y restricciones descubiertas

### A25 — El escáner no distingue tracked de untracked; Git sí
Un archivo untracked aparece en el escáner desde cualquier rama, porque el escáner
lee el filesystem, no el índice. Consecuencia: **el escáner no puede responder "¿qué
tiene esta rama?"**. Solo `git ls-tree` puede. Esta sesión abrió con un escáner que
se creía de `main` y no lo era, y el diagnóstico correcto solo llegó al mirar Git.
Es una extensión de A20 (confirmar con `git ls-files`, no con el escáner), ahora
con un modo de fallo concreto: la memoria de tres sesiones estaba a un `rm -rf` de
perderse y ningún escáner lo habría mostrado.
**Regla:** antes de afirmar qué contiene una rama, `git ls-tree`. El escáner
describe el disco, no el repositorio.

### A26 — El regex del `34` es exacto: el 31,5% es estructural (deroga la hipótesis)
Medido contra la fuente con el join autoritativo (490 boletines, 0 fallos):
d=460 (con boletín, confirmado), c=0 (ninguno erróneo), a=0 (ninguno perdido),
b=212 (sin proyecto genuinamente). Suma 672. Las 212 son todas Proyecto de
Resolución (97), Otros (95) y Proyecto de Acuerdo (20): **cero Proyecto de Ley**.
El traspaso v03 tenía razón. El join estructurado
(`retornarProyectoLey/Votaciones/VotacionProyectoLey/Id`) sigue siendo más robusto
por diseño (el regex es "accidentalmente exacto" para este corte, no por
construcción), pero migrar a él **no cambiaría ni un dato hoy**.
**Regla:** el 31,5% de votos con `proyecto: null` no es un defecto reparable del
pipeline. Es una propiedad del universo votado. Si molesta al propósito, se resuelve
en **presentación** (decirle al ciudadano qué se votó cuando no es un proyecto de
ley), no en extracción.

### A27 — El panel adversarial atrapa lo que el auditor no ve (segunda confirmación)
En el encargo de cobertura, el auditor enumeró los campos de la asistencia mirando
solo el **primer item** de la colección (que era un "Asiste", sin justificación) y
reportó la justificación como inexistente. El Panel B la encontró. Se corrigió el
método (unión de campos sobre todos los items) y apareció el gap.
**Regla técnica concreta:** al enumerar los campos de una colección XML/JSON, unir
los campos de TODOS los items, nunca inferir el esquema del primero. Los campos
opcionales (justificación, que solo aparece en los ausentes) son invisibles a la
inspección del primer elemento.

### A28 — Ninguna fuente de territorio es a la vez accesible por máquina y cruzable por id
Investigadas cuatro: `camara.cl` (cruce perfecto por `Diputado/Id`, pero WAF la
bloquea con 403); SERVEL (autoritativo distrito↔electo, pero cruza por nombre);
`datos.bcn.cl` (SPARQL accesible por máquina, 200 OK, pero cruza por nombre y exige
aprender su ontología); `WSComun/retornarDistritos` (da el catálogo de distritos,
pero no vincula al diputado).
**Consecuencia para el propósito:** la segmentación territorial que el objetivo
promete no tiene hoy una solución limpia. Cualquier camino implica o bien un
matching difuso por nombre (con su tasa de error), o bien vencer un WAF (con lo que
eso implica en estabilidad y en términos de uso). Es una decisión del titular, no un
problema técnico con respuesta única.

## 8. Decisiones de diseño

Ninguna decisión de arquitectura se tomó esta sesión: fue de diagnóstico. Las tres
decisiones vigentes (D1 pipeline extendido con normalización; D2 asistencia simétrica
nominal-por-sesión; D3 clave compuesta `(camara, parlamentario_id)` con fecha) siguen
en pie y **ninguna se ve afectada** por lo medido. D2 sale reforzada: la auditoría
confirmó con muestra real que la Cámara sí entrega nominal por sesión, fecha y
justificación, de modo que el contrato simétrico es alcanzable en ambas cámaras.

Decisión de método, sí registrable: **el encargo de diagnóstico se redactó como
medición pura, sin pedirle a Claude Code ninguna recomendación.** Alternativa
considerada: pedirle que además propusiera la ruta. Se descartó porque decidir qué
hacer con las brechas es del titular, y porque un encargo con criterio de éxito
difuso es el caso donde el patrón de encargo autónomo explícitamente no aplica.

## 9. Constantes y parámetros vigentes

| Constante | Valor | Archivo | Nota |
|---|---|---|---|
| `CORTE_FECHA` | `2026-07-06` | `10_utils/10_configuracion.R` | Sin cambios. No se altera ni se usa como default silencioso. |
| Catálogo ASMX Cámara | 5 servicios / 49 operaciones | (descubierto) | El pipeline usa 8. Documentado en `auditoria_cobertura_camara.md`. |
| Parámetro del join estructurado | `prmNumeroBoletin` | (fuente) | `prmBoletin` y `prmProyectoLeyId` devuelven HTTP 500. |
| `TipoAsistencia` (dominio) | 0, 1, 2 (=Justificado) | (fuente) | El `33` mapea 0/1. El valor 2 no aparece en datos 2026 (gap latente). |
| Votaciones del corte | 672 (460 con boletín / 212 sin) | `votos.rds` | El 31,5% sin boletín es estructural (A26). |
| Votos con `proyecto: null` | 27.974 / 84.927 (32,9%) | `docs/data/perfiles/` | Mediana 35% por diputado. Consecuencia de lo anterior. |
| Cobertura de materias | 0/1.311 proyectos; 3% de votos | `docs/data/` | El campo está esencialmente vacío. |

## 10. Arquitectura de archivos

Escáner al cierre: `50_documentacion/estructura/estructura_actual.md`
(2026-07-11 13:39:25; 22 carpetas, 438 archivos), tomado desde
`explore/diagnostico-proposito`.

**Cambio estructural:** dos scripts exploratorios nuevos en `30_procesamiento/`
(`31f`, `31g`), siguiendo la convención ya establecida por `31b`–`31e`. Ninguno
entra a `PASOS` del orquestador: son andamios, no etapas del pipeline. Esto
consolida una **deuda heredada** que conviene resolver: hay ya siete scripts `31*`
de exploración conviviendo con el pipeline en `30_procesamiento/`, cuando
conceptualmente pertenecen a `50_documentacion/andamios/`. Se propone como pendiente
(ver §11), a resolver junto con la higiene de ramas.

**Registro de ejecución detallado:**
`50_documentacion/andamios/logs/20260710_cobertura_camara_log.md` y
`50_documentacion/andamios/logs/20260711_diagnostico_proposito_log.md` (logs de las
sesiones de Claude Code; detalle paso a paso no reproducido aquí).

**Estado de ramas al cierre (5 sin mergear):**
`explore/api-senado`, `explore/api-senado-v02`, `explore/api-senado-v02-asistencia`,
`design/contrato-datos`, `explore/cobertura-camara`, `explore/diagnostico-proposito`.
Ninguna pusheada. `main` tiene `fe0e226` sin pushear.

## 11. Pendientes y ruta sugerida

### Inventario

**P-15 — Corregir la desincronización intermedio ↔ publicado (BUG ACTIVO)**
- **Descripción:** `asistencia.rds` en disco no corresponde a lo publicado; correr
  `run_all(only = 39)` republica con datos stale.
- **Tipo:** bug activo. **Toca producción.**
- **Impacto:** alto. Es un hazard silencioso: no falla, publica mal.
- **Dependencias:** ninguna. Es lo único de esta lista que se puede hacer hoy.
- **Complejidad:** baja-media. La corrección conceptual es clara (el `39` no debe
  poder consumir un intermedio que no corresponde al corte vigente); el diseño de la
  salvaguarda es la parte a pensar (¿sello de corte en el intermedio y validación en
  el `39`? ¿regenerar siempre antes de consolidar?).
- **Principios:** POLITICA 5.2.2 (reproducibilidad), 5.2.3 (idempotencia), 5.3.8
  (validación de integridad: alertar, no fallar en silencio).
- **Precaución:** el `33` va a cambiar de todos modos cuando se implemente el
  contrato simétrico (D2). Conviene decidir si la corrección se hace ahora de forma
  acotada o si se absorbe en esa reescritura. **Recomendación: ahora y acotada** —
  el hazard existe hoy, el contrato simétrico está a varias sesiones de distancia, y
  un `run_all` intermedio publicaría mal.
- **Criterio de éxito sugerido:** correr `run_all(only = 39)` sobre el corte vigente
  reproduce byte-idéntico el `docs/data/` publicado, o falla con un mensaje claro.

**P-16 — Construir la ruta de desarrollo con las cifras del diagnóstico**
- **Descripción:** la sesión levantó el mapa completo (cobertura, brechas de
  propósito, fuentes de territorio, comisiones) pero NO construyó la ruta. Es la
  tarea natural de la próxima sesión.
- **Tipo:** decisión estratégica (del titular, no delegable).
- **Estructura propuesta (esbozada, no decidida):** cuatro capas por dependencia —
  Capa 0 corrección (P-15); Capa 1 completitud de la base (cuáles de los 14 gaps
  sirven al propósito y cuáles son completismo); Capa 2 alcance (el Senado);
  Capa 3 propósito (territorio, presentación de los votos sin proyecto,
  comparabilidad); Capa 4 ampliación (biblioteca histórica, búsqueda temática).
- **Decisiones abiertas que la ruta debe cerrar:** ¿el territorio se busca en otra
  fuente (con qué método de cruce), se degrada la promesa, o se acepta asimétrico
  (el Senado sí lo tiene)? ¿Las comisiones entran al alcance? ¿La biblioteca
  histórica redefine el eje del portal, y si sí, debe decidirse ANTES de construir
  el Senado (porque cambia qué se guarda)? ¿Los votos sin proyecto de ley se
  presentan de otro modo?
- **Complejidad:** alta (es la sesión, no una tarea de la sesión).
- **Criterio de éxito:** documento de decisión en `activa/decisiones/` con la ruta
  aprobada y sus criterios de éxito por capa.

**P-9 — Crosswalk partido → tendencia del Senado (SIN TOCAR, arrastrado de v06)**
- 14 partidos; 10 con equivalente en la Cámara. Casos a resolver: Nacional
  Libertario y el tratamiento de los 10 Independientes. **No delegable** (🔒: la
  clasificación de tendencia no se altera autónomamente).
- **Complejidad:** baja. Es una decisión, no un desarrollo.
- Bloquea la normalización del pipeline del Senado.

**P-13 — Cerrar las 8 preguntas abiertas del contrato de datos**
- La auditoría cambió las respuestas: **Q1 (asistencia) cambia** — el nominal por
  sesión, la fecha y la justificación están disponibles en la Cámara, luego la
  simetría es alcanzable. **Q8 (fecha as-of) cambia** — `Sesion/FechaInicio` está en
  la fuente. **Q6 (estado de proyectos) cambia parcialmente** — el estado de
  tramitación no existe, pero el trámite por-voto sí. **Q2 (llave)** gana un matiz:
  el RUT está disponible en la Cámara pero no cruza al Senado. Q3, Q4, Q5, Q7 sin
  cambio (Q5 confirma el hueco de territorio).
- **Dependencia:** el contrato vive en `design/contrato-datos`, no en `main`.
- **Complejidad:** media.

**P-7 — Construir el pipeline del Senado**
- Bloqueado por P-13 y P-9. Precondición ya cumplida: el pendiente 12 está cerrado.

**P-17 (NUEVO) — Reubicar los scripts exploratorios `31*`**
- Siete scripts de exploración en `30_procesamiento/` que no son etapas del
  pipeline. Deuda heredada consolidada. Resolver junto con la higiene de ramas
  (P-14), decidiendo qué exploración vale como memoria y qué se archiva.
- **Tipo:** deuda heredada. **Complejidad:** baja. **No bloquea nada.**

**P-14 — Higiene de ramas (6 sin mergear)**
- Arrastrado. Ahora con dos ramas más (`explore/cobertura-camara`,
  `explore/diagnostico-proposito`), ambas con contenido que SÍ vale como memoria
  (los dos documentos de diagnóstico y sus muestras).

**P-18 (NUEVO) — Decidir el push de `main`**
- `fe0e226` está commiteado sin pushear. Decisión del titular.

**P-19 (NUEVO) — Los chips de materias operan sobre un campo vacío**
- 0/1.311 proyectos con materia. La UI construida en la sesión 3 (backlog 12) no
  tiene datos que mostrar. Decidir: ¿se busca la materia por otra vía (el catálogo
  `catalogo_materias.xml` existe en `andamios/muestras/`), se retira la UI, o se
  deja latente?
- **Tipo:** brecha de propósito. **Complejidad:** por determinar.

### Evaluación de deuda técnica

**Zonas frágiles:** (1) el consumo de intermedios no versionados por pasos aislados
del orquestador (P-15; viola 5.2.2); (2) la acumulación de siete scripts
exploratorios en la carpeta del pipeline (P-17; viola la separación de 1.3); (3) seis
ramas sin mergear con memoria valiosa dentro (P-14; riesgo de pérdida como el que se
materializó al inicio de esta sesión con los traspasos untracked).

**Oportunidad de mejora declarada:** el join estructurado
(`VotacionProyectoLey/Id`) es más robusto que el regex aunque hoy produzca el mismo
resultado (A26). Migrar a él es deuda técnica preventiva, no un bugfix. Prioridad
baja: no cambia ningún dato hoy.

### Auditoría de cierre (POLITICA 5.6)

| # | Pregunta | Respuesta |
|---|---|---|
| 2 | ¿El pipeline corre de cero sin intervención manual y produce el mismo resultado? | **NO.** Bug 1. → P-15. |
| 5 | ¿Cada transformación crítica tiene check de validación? | **NO.** El `39` consume un intermedio sin validar que corresponda al corte vigente. Es la misma causa raíz del Bug 1. → P-15. |
| 6 | ¿Los outputs son reproducibles e idempotentes? | **NO.** Ídem. → P-15. |
| 7 | ¿Decisiones metodológicas como constantes nombradas? | Sí, sin cambios. |
| 8 | ¿Nombres sin tildes, ñ ni espacios? | Sí. (Salvedad heredada: `Portal Transparencia.dc.html` en `andamios/`, con espacio, es un artefacto externo congelado.) |

Las tres respuestas "no" convergen en el mismo pendiente: **P-15**.

### Ruta sugerida para la próxima sesión

1. **P-15 (bug activo, toca producción).** Criterio de priorización 1: los bugs
   activos van primero, siempre. Además es lo único ejecutable sin decisiones
   previas. Criterio de éxito: `run_all(only = 39)` reproduce el publish vigente o
   falla con mensaje claro.
2. **P-16 (construir la ruta).** Es la sesión, propiamente. Con el mapa levantado y
   el bug cerrado, decidir las cuatro capas. Ojo: la decisión sobre la biblioteca
   histórica (Capa 4) debe tomarse **antes** de construir el Senado, porque cambia
   qué se guarda.
3. **P-9 (crosswalk).** Baja complejidad, no delegable, desbloquea el Senado. Puede
   resolverse en paralelo.

**Diferir:** P-7 (el Senado; su precondición real ahora es P-13 y P-9, no el
pendiente 12, que está cerrado). P-14, P-17, P-18 (higiene; ninguno bloquea).
P-19 (materias; entra naturalmente en la discusión de la Capa 3 de P-16).

## 12. Instrucciones específicas para la próxima sesión

- ⚠️ **NO correr `run_all()` ni `run_all(only = 39)` sobre el estado actual** sin
  antes resolver P-15: republicaría el dashboard con asistencia stale,
  silenciosamente.
- ⚠️ **NO tratar el 31,5% de votos sin boletín como un bug.** Está medido: es
  estructural (A26). Si vuelve a aparecer la tentación de "arreglarlo" en el
  pipeline, releer A26 antes.
- ⚠️ **NO afirmar qué contiene una rama a partir del escáner.** Usar `git ls-tree`
  (A25).
- ⚠️ **NO enumerar el esquema de una colección desde su primer item.** Unir todos
  (A27).
- ✅ **ANTES de decidir la ruta del Senado**, decidir si la biblioteca histórica
  redefine el eje del portal: cambia qué se guarda, y decidirlo después implica
  rehacer.
- ✅ **ANTES de proponer buscar el territorio en otra fuente**, releer A28: las
  cuatro candidatas fallan, cada una por un motivo distinto. No hay opción limpia.
- 🔒 **R es el único lenguaje, para todo, incluida la inspección.** Cinco ocurrencias
  registradas del patrón contrario en la cartera.
- 🔒 **El pipeline de la Cámara en producción no se toca sin decisión explícita.**
- 🔒 **La clasificación de tendencia no se altera autónomamente.** `IND = NA_character_`
  es intencional.
- 🔒 **`CORTE_FECHA` nunca se usa como default silencioso.**

## 13. Fragmentos de código de referencia

**Verificar qué contiene realmente una rama (A25):**
```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile ls-tree --name-only -r main -- 30_procesamiento 50_documentacion/activa
```
El escáner NO sirve para esto: lee el disco, no el índice.

**Enumerar el esquema de una colección XML sin perder campos opcionales (A27):**
```r
# MAL: infiere el esquema del primer item; pierde los campos opcionales
campos <- xml2::xml_name(xml2::xml_children(items[[1]]))

# BIEN: une los campos de todos los items
campos <- unique(unlist(lapply(items, function(it) {
  xml2::xml_name(xml2::xml_children(it))
})))
```
La `Justificacion` de la asistencia solo aparece en los diputados ausentes: es
invisible si se mira solo el primer item (que suele ser un "Asiste").

**El join autoritativo votación → boletín (A26; disponible, hoy equivalente al regex):**
```r
# Parámetro correcto: prmNumeroBoletin (prmBoletin y prmProyectoLeyId dan HTTP 500)
url <- "https://opendata.camara.cl/wscamaradiputados.asmx/retornarProyectoLey"
resp <- httr2::request(url) |>
  httr2::req_url_query(prmNumeroBoletin = boletin) |>
  httr2::req_retry(max_tries = 3, is_transient = \(r) httr2::resp_status(r) %in% c(429, 500)) |>
  httr2::req_perform()
# Las votaciones que el proyecto declara:
# xml_find_all(doc, ".//Votaciones/VotacionProyectoLey/Id")
```

## 14. Reapertura

- **Nombre del chat:** `transparencia_legislativa_chile, sesión 8 (Opus 4.8)`

- **Mensaje de apertura pre-armado:**

> Tipo: CONTINUATION. El protocolo (`POLITICA_PROYECTO.md`,
> `SETTINGS_Y_PROMPTS_OPERACIONALES.md`) vive en la knowledge base del Project y se
> lee desde ahí. Adjunto: `traspaso_cierre_v07.md`, `estructura_actual.md`,
> `backlog_acumulativo.md` (26 entradas), `diagnostico_proposito.md`,
> `auditoria_cobertura_camara.md`.
>
> Estado: la Cámara sigue en producción sin cambios; ninguna línea de código de
> producción se tocó en la sesión 7. La sesión fue de diagnóstico y produjo tres
> resultados. (1) Se cerró el pendiente 12: el web service de la Cámara expone 49
> operaciones y el pipeline usa 8; hay ~14 gaps inventariados con muestra real. (2)
> Se derogó una hipótesis del asistente: el regex del `34` NO pierde boletines (join
> autoritativo sobre 490 boletines: d=460, c=0, a=0, b=212); el 31,5% de votos sin
> proyecto es estructural, no un bug. (3) Apareció un bug real y no buscado: el
> intermedio `asistencia.rds` está desincronizado de lo publicado, de modo que
> `run_all(only = 39)` republicaría con datos stale (P-15, toca producción).
>
> Foco propuesto: P-15 (el bug, primero) y luego P-16: construir la ruta de
> desarrollo en cuatro capas con las cifras del diagnóstico en la mano. Las
> decisiones abiertas que la ruta debe cerrar están en §11 del traspaso (territorio,
> comisiones, biblioteca histórica, presentación de los votos sin proyecto de ley).
> Sigue pendiente y sin tocar el crosswalk de partidos del Senado (P-9), que es
> decisión mía.

- **Documentos para la próxima sesión:**

  1. *Protocolo en knowledge base* (NO se adjuntan; verificar que estén al día):
     `POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
  2. *Opcionales según el foco:* `encargo_autonomo_claude_code_v1.md` (si habrá
     encargos); `CLAUDE.md` (si se corre en Claude Code).
  3. *Específicos de la sesión (SÍ se adjuntan):* `traspaso_cierre_v07.md`;
     `estructura_actual.md` (re-escanear, e indicar desde qué rama); 
     `backlog_acumulativo.md`; `diagnostico_proposito.md`;
     `auditoria_cobertura_camara.md`. Si se aborda P-15: los scripts `33` y `39`.
     Si se aborda P-13: `contrato_datos_camara_senado.md` (vive en
     `design/contrato-datos`, no en `main`).

- **Nota final:** si algún archivo listado cambió entre sesiones, adjuntar la versión
  más actualizada al abrir y avisarlo en el mensaje de apertura. En particular:
  `estructura_actual.md` debe re-escanearse, y debe declararse **desde qué rama** se
  tomó (A25).

## 15. Errores del asistente (POLITICA 0.5)

| Campo | Error 1 |
|---|---|
| `momento` | Turno de evaluación del encargo de cobertura (pendiente 12), y reiterado al proponer la ruta de diagnóstico. |
| `disparador` | El propio asistente lo señaló al recibir los resultados del segundo encargo, que lo desmintieron con datos medidos. |
| `que_paso` | Afirmó, con alta convicción y sin verificación, que el regex del `34` estaba perdiendo boletines y que había "datos publicados hoy en el dashboard que están incompletos"; lo calificó de "el hallazgo más importante de la auditoría" y de "cuarta ocurrencia del patrón A21". La medición posterior (join autoritativo, 490 boletines) devolvió a=0 y c=0: la afirmación era falsa y el traspaso v03 tenía razón. |
| `regla_violada` | POLITICA 5.1 / B.1 (pensar antes de codificar: supuestos explícitos, sin supuestos implícitos). Aprendizaje A21 del propio proyecto ("un endpoint que responde no es evidencia de que sea el único ni el completo", generalizable a: una inferencia plausible no es evidencia). |
| `causa_raiz` | Razonamiento por plausibilidad estructural: "existe un join estructurado sin usar + el pipeline usa un regex ⇒ el regex debe estar perdiendo cosas". La inferencia era razonable pero nunca se verificó antes de presentarla como hallazgo. Agravante: se cometió en el mismo turno en que se estaba advirtiendo sobre ese patrón, lo que sugiere que nombrar un patrón no protege de cometerlo. |
| `salvaguarda_presente` | POLITICA (5.1, B.1) + el propio backlog del proyecto (A21, tres ocurrencias previas registradas) + el traspaso v03, que ya había concluido correctamente que el 31,5% era estructural y cuya conclusión el asistente contradijo sin evidencia. |
| `patron` | Variante de A21 (aceptar una explicación plausible sin agotar la verificación). **Quinta ocurrencia en el proyecto, primera cometida por el asistente de análisis y no por el pipeline.** El correctivo que sí funcionó fue estructural, no de disciplina: el encargo estaba redactado como medición con criterio de éxito verificable ("las cuatro cifras deben sumar 672"), de modo que la hipótesis era falsable y el dato la mató. Sugerencia para la cartera: cuando el asistente formule una hipótesis causal sobre datos, redactarla siempre como cifra falsable antes de actuar sobre ella. |

| Campo | Error 2 |
|---|---|
| `momento` | Al intentar inspeccionar los archivos del dashboard adjuntos (`index.html`, `indice_diputados.json`). |
| `disparador` | El asistente lo señaló espontáneamente al turno siguiente, tras el fallo del comando. |
| `que_paso` | Intentó ejecutar R en su propio contenedor (`R -q -e ...`) para inspeccionar artefactos del proyecto; el contenedor no tiene R. El riesgo real no fue el fallo, sino la tentación inmediata de recurrir a otra herramienta (bash/grep) para leer los mismos archivos, lo que habría violado el invariante R-only. |
| `regla_violada` | Invariante 🔒 R-only del proyecto: R es el único lenguaje para toda inspección, verificación y auditoría de artefactos del proyecto, sin excepción por trivialidad. |
| `causa_raiz` | Confusión de entornos: el invariante rige sobre los artefactos del proyecto, y el asistente no tiene un entorno capaz de cumplirlo (su sandbox carece de R). La conclusión correcta, que se adoptó, es que **el asistente no inspecciona programáticamente artefactos del proyecto en absoluto**: los lee en contexto, o encarga la verificación a Claude Code, que sí corre R. |
| `salvaguarda_presente` | POLITICA (invariante del proyecto) + `userPreferences` (R como único lenguaje) + traspasos previos (tres ocurrencias registradas del mismo patrón en `mundial2026_confederaciones`). |
| `patron` | Variante del patrón R-only, ya registrado repetidamente en la cartera. **Aprendizaje nuevo y accionable:** la regla, tal como está escrita, no contempla el caso del asistente conversacional con sandbox propio. Debería reformularse para decir explícitamente que el asistente NO inspecciona artefactos del proyecto con herramientas de su contenedor bajo ninguna circunstancia, y que toda verificación programática se delega a Claude Code. Esto es exactamente el caso que POLITICA 0.5 anticipa: dos o más ocurrencias del mismo patrón indican que la salvaguarda debe reformularse, no repetirse con más énfasis. |
