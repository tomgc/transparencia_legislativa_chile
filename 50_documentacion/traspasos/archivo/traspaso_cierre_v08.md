# Traspaso de cierre — v08

## 1. Identificación

- **Proyecto:** `transparencia_legislativa_chile`
- **Versión:** v08
- **Fecha:** 2026-07-15
- **Sesión:** 8. Foco: cerrar el bug de reproducibilidad P-15 (sello de procedencia) y construir la ruta de desarrollo del portal (P-16) con las cifras del diagnóstico de la sesión 7 en mano; ejecutar la primera capa (presentación).
- **Entorno:** R 4.5.2 / Positron (macOS). Claude Code para ejecución autónoma. Repo público (Rama A). Sitio en producción: `https://tomgc.github.io/transparencia_legislativa_chile/`.
- **Archivos principales modificados:** `10_utils/10_utils.R`, `30_procesamiento/{32,33,34,35,36}_*.R`, `30_procesamiento/39_consolidar_json.R` (P-15, en rama `fix/sello-corte-intermedios`); `docs/index.html` (Capa 1, en rama `feat/presentacion-votos`). **Ninguno mergeado a `main`.**

## 2. Resumen ejecutivo

La sesión pasó de diagnóstico a ejecución: por primera vez desde la sesión 4 se tocó código, y quedó cerrado el único bug activo (P-15). El sello de procedencia impide que `run_all(only = 39)` republique con un intermedio de otro corte: cada intermedio viaja con `{corte_fecha, anio_proceso, hash_origen, escrito_en}` como atributos, y el `39` valida antes de consolidar, fallando ruidoso si algo no calza. La arqueología de la Fase 0 resolvió además una duda del traspaso anterior: el publish vigente es correcto (salió del caché del 10, que es `CORTE_FECHA`), y descubrió que **`CORTE_FECHA` es 2026-07-10, no 2026-07-06 como decía el v07 §9**. Con las cifras firmes, se aprobó la ruta de desarrollo en cinco capas (documento de decisión D4–D8) y se ejecutó la Capa 1: dos cambios de presentación en `index.html` (levantar el recorte a 16 votos con un toggle; que la celda de región lea el dato en vez de hardcodear "Sin dato"). El recorte a 16 ocultaba entre el 96 % y el 98 % del historial de votos de todos los diputados, no de unos pocos: fue la capa de mayor impacto real, no la menor. Quedan cuatro frentes de git sin cerrar y la sesión de higiene pasa a ser la próxima, no diferible.

## 3. Estado al cierre

**Qué funciona:**
- Pipeline de la Cámara en producción, sin cambios en `main`. Última corrida exitosa publicada: corte 2026-07-10 (155 perfiles, máx. 717 votos, control de votos íntegro).
- P-15 resuelto en rama `fix/sello-corte-intermedios`: sello + validación verificados con prueba de falla real y doble panel adversarial. `docs/` byte-idéntico tras el encargo.
- Capa 1 resuelta en rama `feat/presentacion-votos`: toggle de votos (717 = 717 en DOM, 9 ms de render) y celda de región habilitada (invisible hoy, habilitante para la Capa 2). Verificado en navegador.

**Qué no funciona / pendiente:**
- Nada roto. La deuda es de integración: dos ramas nuevas sin mergear, heredados sucios de la sesión 7, y `launch.json` con Python (§6, §11).

**Delta respecto a v07:**
- v07 cerró tres sesiones sin código; v08 rompe la racha con dos entregas ejecutadas y cero cambios en producción (`main` intacto).
- Corregido el valor de `CORTE_FECHA` (era erróneo en el registro).

## 4. Registro detallado de cambios

**Cambio 1 — Sello de procedencia en los intermedios (P-15).** Categoría: infraestructura/reproducibilidad. `10_utils/10_utils.R`: se extendió `escribir_atomico(objeto, ruta, escritor, hash_origen = NULL)` para sellar con atributos cuando recibe `hash_origen`; se agregaron `sellar()`, `hash_origen_de()`, `ruta_cache()`, `leer_sellado()` (exige sello, `stop()` si falta) y `validar_corte()` (falla si falta sello, si el corte ≠ `CORTE_FECHA`, o si los hermanos son incoherentes). Los cinco `3x` pasan el hash de su caché de origen; el `39` valida antes de cualquier join o escritura. Por qué (C.11): un intermedio no versionado no es fuente de verdad reproducible, y el `39` lo consumía sin validar el corte. Verificación (B.4): `run_all(only = 39)` reproduce el publish (diff 0/155) con intermedios coherentes, y falla con `stop()` diagnóstico ante un intermedio adulterado (salida real en §13). Tensión C.2 vs C.3 resuelta a favor de sellar+validar (barato, observable) sobre regenerar-siempre.

**Cambio 2 — Capa 1, presentación (toggle de votos).** Categoría: frontend/presentación. `docs/index.html`: `state.votosExpandidos` (reseteado por perfil en `syncFromHash`), `buildVotacionesSection()` con `LIMITE_COLAPSADO = 16` y botón `toggle-votos`; la conjunción `hayMas && expandido` hace imposible que el botón desaparezca dejando la lista expandida sin colapsar. La lógica del voto sin proyecto no se tocó (bloque byte-idéntico a `main`). Por qué: el recorte a 16 impedía "verificar un voto puntual" (propósito declarado). Verificación: 717 filas en DOM = `n_votaciones`, clic real, 0 errores de consola.

**Cambio 3 — Capa 1, presentación (celda de región lee el dato).** Categoría: frontend/deuda habilitante. `docs/index.html`: `regionPartes()`, `renderRegionCell()` (tabla) y `renderRegionChip()` (encabezado de ficha, L1003, ampliación respecto del encargo); degradan a "Sin dato" solo si el dato es `null`/vacío. Por qué: la celda hardcodeaba el literal y habría seguido negando el dato tras la Capa 2. Verificación: con dato inyectado en memoria muestra región/distrito; con `null` (155/155 hoy) es byte-idéntico al literal anterior; escapado sólido.

## 5. Backlog acumulativo

Vive en `50_documentacion/activa/backlog_acumulativo.md` (archivo canónico independiente desde la sesión 2). **Delta de esta sesión:** 3 entradas nuevas (una por cambio de §4). Categorías tocadas: infraestructura/reproducibilidad (+1), frontend/presentación (+2). Sin refinamientos de taxonomía ni reclasificaciones. El detalle cronológico de la sesión 8 debe copiarse íntegro al archivo con numeración correlativa global (continuando desde la última entrada de la sesión 7); no reproduzco aquí la numeración porque el archivo canónico manda.

## 6. Bugs de la sesión

**Bug 1 (P-15) — RESUELTO.** Síntoma: `40_salidas/intermedios/asistencia.rds` (máx 58 sesiones) no correspondía al `docs/data/` publicado (máx 61); `run_all(only = 39)` republicaría stale sin fallar. Causa raíz: los intermedios están gitignored, así que el `.rds` en disco reflejaba la última corrida local (una prueba con el caché del 06), no el insumo del publish vigente (caché del 10); el `39` consumía el intermedio sin validar a qué corte pertenecía. Solución exacta: sello de procedencia en `10_utils/10_utils.R` + validación en `39_consolidar_json.R` (§4, Cambio 1). Verificación: prueba de falla real (§13) + panel adversarial con manifiestos md5. **Patrón general aprendido:** un artefacto intermedio no versionado no es fuente de verdad reproducible; si un paso aislado del orquestador puede consumirlo, ese intermedio necesita sello + validación que falle ruidosa, no silencio. Principios: C.2 (reproducibilidad), C.3 (idempotencia), C.8 (validar, no fallar en silencio). Estado: resuelto, en rama `fix/sello-corte-intermedios` (sin mergear).

No se descubrieron bugs de código nuevos en la Capa 1.

## 7. Aprendizajes y restricciones descubiertas

- **A29 — El sello de procedencia como contrato de reproducibilidad.** Regla: todo intermedio `.rds` que alimente la consolidación viaja con `{corte_fecha, anio_proceso, hash_origen, escrito_en}` vía `escribir_atomico()`; el consumidor valida con `validar_corte()` antes de escribir. Contexto (qué pasa si se viola): sin el sello, un `only = 39` con un intermedio de otro corte republica mal en silencio (el bug de esta sesión). Ejemplo: la prueba de falla de §13. Principio: C.3, C.8. **Se propaga al `4x` del Senado automáticamente** por vivir en `escribir_atomico()`.
- **A30 — El recorte de presentación ocultaba el 96–98 % del historial.** Regla: cuando un recorte de UI (`slice(0, N)`) opera sobre un universo cuyo tamaño real no se midió, el recorte puede estar ocultando la casi totalidad del dato, no un excedente. Contexto: se dimensionó la Capa 1 como "la más barata" y resultó la de mayor impacto sobre el propósito. Ejemplo: máx 717 votos, mín 405, recorte a 16. Lección: medir el universo antes de calificar un recorte de "cosmético".
- **A31 — Hay Python institucionalizado en el repo.** `.claude/launch.json` (commiteado en `main` desde `63e6d57`) usa `python3 -m http.server` como servidor de preview, contradiciendo el invariante R-only "en ningún contexto". No es un desliz transitorio: es permanente y precede a esta sesión. Pendiente de decisión del titular (§11, P-20).

## 8. Decisiones de diseño

Documento formal en `50_documentacion/activa/decisiones/20260711_decision_ruta_desarrollo.md` (D4–D8). Resumen:

- **D4 — El eje del portal es el parlamentario.** La biblioteca histórica no redefine el eje; se difiere a Capa 5, a construir sobre el modelo actual (que ya persiste `votacion_id`, boletín y fecha por voto). Cumple la instrucción ✅ del v07 y **desbloquea el Senado** por ese flanco. Alternativa descartada: invertir el eje ahora (huir hacia adelante mientras el eje declarado no se cumple).
- **D5 — Territorio por mapeo verificado y versionado, no matching difuso en producción.** Cruce por nombre contra BCN/SERVEL + verificación exhaustiva de los 155 + archivo de mapeo versionado. El matching difuso es andamio de una vez. **Precondición no verificada:** que BCN entregue distrito por parlamentario (A28 lo deja sin resolver) y que el mapeo diputado→distrito sea estable en el período. La Capa 2 abre midiendo, no codificando.
- **D6 — Comisiones fuera de alcance ahora; justificación de ausencia dentro.** Las comisiones a Capa 5 (no están en el objetivo). La justificación (`Asistencia/Justificacion`) entra en la Capa 3 a costo marginal cero (el `33` se reescribe para D2). Salvedad: la asistencia a comisión no está confirmada (0 sesiones en el muestreo).
- **D7 — El 31,5 % de votos sin proyecto NO requiere trabajo: ya está resuelto en la UI.** Verificado en `index.html` (L822-836): el voto sin boletín muestra el tipo (itálica) y la descripción cruda. La brecha #2 del diagnóstico describía el JSON, no la UI. Invariante: no tratarlo como bug ni en pipeline ni en UI.
- **D8 — Chips de materias se dejan como están (cierra P-19).** `renderMaterias()` degrada con "Sin materias registradas" ante el hueco de fuente (0/1.311). No es bug: es comunicación honesta. Retirar la UI sería borrar algo que ya se comporta bien y revive si la fuente puebla.

## 9. Constantes y parámetros vigentes

| Constante | Valor | Archivo | Nota |
|---|---|---|---|
| `CORTE_FECHA` | **2026-07-10** | `10_utils/10_configuracion.R` | **CORREGIDO respecto de v07 §9, que decía 2026-07-06 (erróneo).** Fuente canónica: el archivo, no el traspaso (A21). |
| `LIMITE_COLAPSADO` | 16 | `docs/index.html` | Nuevo (Capa 1). Votos mostrados en estado colapsado del perfil. |
| `MAX_SESIONES_DETALLE` | (sin cambios) | `10_utils/10_configuracion.R` | Tope del caché de asistencia. |
| Sello (campos) | `corte_fecha, anio_proceso, hash_origen, escrito_en` | `10_utils/10_utils.R` | Nuevo (P-15). Atributos del `.rds` intermedio. |

**Pendiente de verificación:** revisar si el traspaso v04 (donde se introdujo `CORTE_FECHA`) también declara el valor incorrecto, para saber si el error de registro viene de más atrás o se introdujo al transcribir el v07.

## 10. Arquitectura de archivos

Escáner al cierre: `50_documentacion/estructura/estructura_actual.md`, fechado 2026-07-15 23:23:07 (22 carpetas, 403 archivos). **A25:** el escáner refleja el filesystem, no la verdad de git; la rama desde la que se tomó no está declarada en su header y **debe confirmarse con `git -C <raiz> branch --show-current` al abrir la próxima sesión**, no inferirse. La estructura respeta la política: en `30_procesamiento/` solo `31_explorar_api_camara.R` convive con el pipeline (el resto de la exploración ya migró a `andamios/`), de modo que **P-17 es un script, no siete** como sugería el v07.

## 11. Pendientes y ruta sugerida

**Inventario:**

- **P-14 (higiene de ramas) — bloqueante de nuevo trabajo.** Cuatro frentes de git sin cerrar: `fix/sello-corte-intermedios` (P-15, sesión 8), `feat/presentacion-votos` (Capa 1, sesión 8), 13 heredados sucios en `50_documentacion/` (sesión 7, mtime 11-jul), y `.claude/launch.json` modificado sin commitear. Impacto: apilar más trabajo encima arriesga repetir la pérdida de memoria de la sesión 7. Complejidad: media. Criterio de éxito: `main` con las dos ramas de la sesión 8 mergeadas (o decididas), working tree limpio, heredados resueltos.
- **P-17 (script de exploración en el pipeline) — deuda heredada, baja.** `31_explorar_api_camara.R` no es etapa del pipeline. Mover a `andamios/` o renumerar fuera del rango de ejecución. Un solo archivo.
- **P-18 (push de `main`) — administrativo.** `main` local adelantado respecto al remoto; push tras la higiene, con `git status` mostrado (nunca `git add .`).
- **P-20 (Python en `.claude/launch.json`) — NUEVO, decisión del titular.** Reemplazar por `servr::httd` en R (ya existe en el working tree), o declarar excepción para dev local. Recomendación de la sesión: reemplazar (el invariante no distingue contexto). Entra en la sesión de higiene.
- **P-9 (crosswalk partido → tendencia del Senado) — del titular, paralelizable.** 14 partidos, 10 con equivalente en la Cámara; resolver Nacional Libertario y los independientes. No delegable (🔒 tendencia). Puede avanzar en paralelo desde ya: es lo único de la Capa 4 que no depende de la Capa 3.
- **P-13 (contrato de datos Cámara/Senado) — Capa 4.** Las 8 preguntas abiertas del documento `contrato_datos_camara_senado.md` (rama `design/contrato-datos`). Se resuelven mejor tras la Capa 3.
- **P-7 (pipeline del Senado) — Capa 4.** Depende de P-13 y P-9.
- **Capa 2 (territorio) — siguiente feature tras la higiene.** Abre midiendo la fuente (D5).
- **Capa 3 (asistencia simétrica, D2) — tras la Capa 2.** Reescritura del `33`: nominal por sesión + fecha + justificación.

**Evaluación de deuda técnica:** el working tree con cuatro frentes es la zona frágil. El acoplamiento latente de la nota de votos (`n_votaciones` → `list.length`, 0 divergencias hoy) es benigno y autodelator si algún día diverge.

**Auditoría de cierre (POLITICA 5.6):**
- #2 (¿pipeline de cero sin intervención manual?): **ahora sí**, con P-15 resuelto — pero la resolución vive en rama sin mergear. Se cierra de verdad al mergear.
- #5 (¿cada transformación crítica con check?): el `39` ahora valida procedencia antes de consolidar. Sí.
- #6 (¿outputs reproducibles e idempotentes?): sí, con el sello. Sí.
- #8 (¿nombres sin tildes/ñ/espacios?): sí.

**Ruta sugerida para la sesión 9:** SESIÓN DE HIGIENE (P-14, P-17, P-18, P-20). Criterio de éxito: `main` limpio con el trabajo de la sesión 8 integrado, working tree sin heredados, Python resuelto. Diferir: la Capa 2 hasta que el working tree esté limpio. P-9 puede correr en paralelo cuando el titular quiera.

## 12. Instrucciones específicas para la próxima sesión

- ⚠️ NO iniciar la Capa 2 (ni ningún feature) sin cerrar antes P-14: el working tree tiene cuatro frentes abiertos.
- ⚠️ NO mergear `fix/sello-corte-intermedios` ni `feat/presentacion-votos` sin `git status` revisado y sin confirmar que los heredados sucios no se cuelen en el merge.
- ⚠️ NO afirmar desde qué rama se tomó el escáner: confirmarlo con `git branch --show-current` (A25).
- ⚠️ El 31,5 % de votos sin proyecto NO es bug (A26); ya está resuelto en la UI (D7).
- ✅ ANTES de la Capa 2, verificar empíricamente que BCN entregue distrito por parlamentario (A28/D5); si no, SERVEL; si ninguna, revisar D5.
- ✅ ANTES de comprometerse con `CORTE_FECHA` en cualquier documento, leerla de `10_configuracion.R`, nunca de un traspaso (A21, cuarta ocurrencia esta sesión).
- 🔒 R-only en todo contexto, incluida inspección auxiliar (violado dos veces esta sesión; ver §15).
- 🔒 La Cámara en producción (`main`) no se toca sin decisión explícita.
- 🔒 La clasificación de tendencia no se altera autónomamente; `IND = NA_character_` es intencional.
- 🔒 `CORTE_FECHA` sin default silencioso.

## 13. Fragmentos de código de referencia

Salida real de la prueba de falla de P-15 (intermedio adulterado a corte 2026-07-06, `run_all(only = 39)`):

```
STOP -> Paso 39 fallo: validar_corte: 'asistencia.rds' declara corte 2026-07-06,
pero el corte vigente (CORTE_FECHA) es 2026-07-10. El intermedio NO corresponde al
corte publicado; regenera los pasos 32-36 con CORTE_FECHA=2026-07-10.
```

Es la forma correcta del mensaje diagnóstico: nombra el archivo, el corte declarado, el corte esperado y la acción correctiva. Cualquier validación futura de procedencia (incluido el `4x` del Senado) debe replicar este nivel de especificidad.

**Registro de ejecución detallado:** `50_documentacion/andamios/logs/20260715_presentacion_votos_log.md` (log de la sesión de Claude Code de la Capa 1; detalle paso a paso no reproducido aquí). El log de P-15 vive en `50_documentacion/andamios/logs/20260711_sello_corte_log.md`.

## 14. Reapertura

- **Nombre del chat:** `transparencia_legislativa_chile, sesión 9 (Claude Opus 4.8)`.
- **Mensaje de apertura pre-armado:** "Tipo: CONTINUATION. El protocolo (`POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`) vive en la knowledge base del Project y se lee desde ahí. Esta es una SESIÓN DE HIGIENE (P-14, P-17, P-18, P-20): cerrar cuatro frentes de git antes de retomar features. Adjunto: `traspaso_cierre_v08.md`, `estructura_actual.md` (re-escanear e indicar rama, A25), `backlog_acumulativo.md`."
- **Documentos para la sesión 9:**
  1. *Protocolo (knowledge base, NO adjuntar, solo verificar que esté al día):* `POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
  2. *Opcionales:* `CLAUDE.md` (la sesión de higiene corre en Claude Code); el protocolo 4.2 (migrar estructura) si P-17 se resuelve renumerando; el protocolo 4.3 no aplica (ya migrado a GitHub).
  3. *Sí se adjuntan:* `traspaso_cierre_v08.md`; `estructura_actual.md` (re-escaneado, con rama declarada); `backlog_acumulativo.md`. Para P-14, el output de `git -C <raiz> status` y `git -C <raiz> branch -a` (crítico: la higiene se hace sobre el estado real de git, no sobre el escáner — A25).
- **Nota final:** si `CORTE_FECHA` cambió entre sesiones (nueva corrida del pipeline), adjuntar `10_configuracion.R` actualizado y avisarlo. El valor vigente al cierre de la sesión 8 es 2026-07-10.

## 15. Errores del asistente (POLITICA 0.5)

| momento | disparador | que_paso | regla_violada | causa_raiz | salvaguarda_presente | patron |
|---|---|---|---|---|---|---|
| Sesión 8, redacción del encargo de P-15 y del cierre de la ruta propuesta | Claude Code lo señaló al leer el archivo real; el asistente no lo había detectado | Afirmó `CORTE_FECHA = 2026-07-06` (tomado del v07 §9 sin verificar contra `10_configuracion.R`) y construyó sobre ello una conjetura falsa ("el publish está adelantado respecto a su corte, segundo síntoma") | SETTINGS §1.2.6 (no operar sobre estado supuesto); B.1 | Tomó una constante del traspaso como fuente de verdad sin contrastarla con el archivo, y extrapoló una hipótesis causal de ella | POLITICA 5.1 / B.1 + SETTINGS §1.2.6 + el registro del mismo patrón en el propio v07 | Variante de A21 (asistente); tercera ocurrencia contando las dos de v07. Lo que lo atajó fue estructural (la Fase 0 medía con control), no la disciplina |
| Sesión 8, al recomendar el alcance de la Capa 1 antes de leer `index.html` | El asistente lo detectó al leer el archivo (autocorrección antes de redactar el encargo) | Afirmó que la UI no mostraba el tipo del voto sin proyecto y propuso implementarlo, cuando ya estaba implementado (L822-836); trasladó a la UI la brecha #2 que describía el JSON | SETTINGS §1.2.6; B.1 | Trasladó a la UI una cifra del diagnóstico que describía el JSON, sin leer la UI | userPreferences + POLITICA + SETTINGS + el registro de A21 en v07 y en esta misma sesión | Cuarta variante de A21. Lo atajó poner la lectura del archivo como precondición mecánica de la capa; la disciplina no bastó |
| Sesión 8, inicio del encargo de Capa 1 (Claude Code) | El propio ejecutor (Claude Code) lo señaló espontáneamente | Usó Python para ordenar el índice por `n_votaciones` en una inspección auxiliar, violando 🔒 R-only | 🔒 invariante R-only del encargo / `userPreferences` (R only) / POLITICA 5.1 | Reflejo de alcanzar la herramienta más rápida para una tarea trivial, antes de que el invariante se activara conscientemente | userPreferences + POLITICA + el encargo (los tres) | Nuevo en el registro (primer error de herramienta de Claude Code). La recuperación autónoma funcionó (rehízo en R, ningún dato reportado proviene de esa ejecución); el correctivo a reforzar: checkear el invariante ANTES de la primera acción |

**Nota de patrón para análisis cruzado de cartera (SETTINGS §2.2.15):** el patrón A21 (afirmar un valor verificable del proyecto sin leer la fuente) alcanza cuatro ocurrencias del asistente en dos sesiones. En las cuatro, el correctivo que funcionó fue **estructural** (precondición mecánica de lectura o medición), nunca la disciplina. Esto es evidencia suficiente, según el umbral de la propia §2.2.15 ("2 o más ocurrencias del mismo patrón → la salvaguarda debe reformularse, no repetirse"), de que "verifica antes de afirmar" **no se sostiene como regla de disciplina** y debe subir a POLITICA como precondición mecánica: toda afirmación del asistente sobre un valor del proyecto debe ser falsable y verificada antes de construir sobre ella. Candidata a reformulación de salvaguarda para la próxima sesión BIBLIOTECA de `slep_estado_proyectos_monitoreo`.
