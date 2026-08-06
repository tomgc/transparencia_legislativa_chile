# Traspaso de cierre — v09

## 1. Identificación

- **Proyecto:** `transparencia_legislativa_chile`
- **Versión:** v09
- **Fecha:** 2026-07-16
- **Sesión:** 9. Foco: SESIÓN DE HIGIENE. Cerrar los cuatro frentes de git abiertos de la sesión 8 (P-14), resolver P-17 y P-20, y dejar `main` limpio, integrado y pusheado antes de retomar features.
- **Entorno:** R 4.5.2 / Positron (macOS). Claude Code para ejecución autónoma. Repo público (Rama A). Sitio en producción: `https://tomgc.github.io/transparencia_legislativa_chile/`.
- **Archivos principales modificados:** ninguno de código nuevo en esta sesión (fue de integración). Se integraron a `main` los cambios de las sesiones 7 y 8 vía merge + rebase: `10_utils/10_utils.R`, `10_utils/10_configuracion.R`, `30_procesamiento/{32,33,34,35,36}_*.R`, `30_procesamiento/39_consolidar_json.R`, `docs/index.html`, `.claude/launch.json`, `CLAUDE.md`, y toda la memoria estructural de `50_documentacion/`. `31_explorar_api_camara.R` movido a `andamios/` (P-17). **`main` remoto ahora al día en `b707c51`.**

## 2. Resumen ejecutivo

Sesión de integración pura: no se tocó código nuevo, se consolidó en `main` todo el trabajo acumulado de las sesiones 7 y 8, que vivía en ramas y en un working tree sucio. Se versionó la memoria estructural pendiente (traspasos v07-v08, decisión de ruta, backlog de la sesión 7, poda de snapshots), se mergearon con `--no-ff` las dos ramas de la sesión 8 (sello de corte P-15 e infraestructura; Capa 1 de presentación), se sacó el Python de `.claude/launch.json` (P-20, reemplazado por `Rscript`/`servr::httd`) y se movió el script de exploración fuera del pipeline (P-17). El push chocó con un commit del bot de refresh semanal (corte 2026-07-13, pusheado el lunes 13-jul), que se resolvió con un rebase limpio de los commits de higiene sobre el refresh; `CORTE_FECHA` quedó en 2026-07-13. Finalmente se borraron las tres ramas ya integradas o muertas. `main` local == `origin/main` == `b707c51`, working tree limpio. Emergió un pendiente estructural nuevo (P-22: el cron semanal y el trabajo manual compiten por `main`) y un recordatorio operativo (la próxima corrida local disparará la validación de corte por diseño).

## 3. Estado al cierre

**Qué funciona:**
- Pipeline de la Cámara en producción. `main` remoto al día en `b707c51`, con todo el trabajo de las sesiones 7-8 integrado (sello de corte + Capa 1 de presentación) más el refresh automatizado del corte 2026-07-13.
- Sello de procedencia (P-15) operativo en `main`: `validar_corte` presente en `10_utils/10_utils.R`.
- Capa 1 de presentación en `main`: `toggle-votos`, `LIMITE_COLAPSADO`, `renderRegionChip` verificados presentes en `docs/index.html`.
- Working tree limpio, sin ramas zombis locales (las tres integradas/muertas borradas).

**Qué no funciona / pendiente:**
- Nada roto en el repo ni en producción.
- **Advertencia operativa (no es bug):** la próxima corrida local de `run_all(only = 39)` fallará ruidosamente por diseño — `CORTE_FECHA` es 2026-07-13 pero los intermedios locales de `40_salidas/intermedios/` siguen sellados con 2026-07-10 (corrida local del 11-jul). Es la compuerta funcionando. Se resuelve corriendo los pasos 32-36.

**Delta respecto a v08:**
- v08 dejó cuatro frentes de git abiertos; v09 los cierra todos y publica `main`.
- `CORTE_FECHA` avanzó de 2026-07-10 a 2026-07-13 (vino del refresh automatizado del bot, integrado por rebase).
- Tres ramas locales eliminadas.

## 4. Registro detallado de cambios

Esta sesión no produjo cambios de código; produjo operaciones de integración de git. Se registran como cambios conceptualmente independientes.

**Cambio 1 — Versionar la memoria estructural pendiente en `main`.** Categoría: documentación/git. Commit `71e4e68` (`docs:`). Se agregaron a `main`, path-scoped a `50_documentacion/`, los 15 archivos sucios de documentación: traspasos v07-v08, `20260711_decision_ruta_desarrollo.md`, `backlog_entradas_sesion_7.md`, snapshots de estructura nuevos y la poda de retención-2 (borrado de `20260709_*` y `20260710_071004_*`), más `ESTADO.md`. Por qué (C.11): estos archivos pertenecen a `main`, no a una rama de feature; commitearlos dentro de una feature ensuciaría su historia. `.claude/launch.json` se mantuvo fuera del stage a propósito (es P-20). Verificación: `git status` limpio salvo `launch.json` tras el commit.

**Cambio 2 — Integrar las dos ramas de la sesión 8 a `main` (`--no-ff`).** Categoría: git/integración. Commits de merge `ea4cb40` (sello de corte, P-15) y `a12007b` (Capa 1 de presentación), en ese orden (infraestructura antes que feature). Ambas ramas colgaban de `fe0e226` y no compartían archivos: cero conflicto. Verificación post-merge (en R, no grep): `toggle-votos`, `LIMITE_COLAPSADO`, `validar_corte` presentes → TRUE/TRUE/TRUE.

**Cambio 3 — P-20: Python fuera de `.claude/launch.json`.** Categoría: git/invariante R-only. Commit `c17129c` (`fix:`). Se confirmó por lectura que el archivo ya usaba `Rscript` + `servr::httd` (reemplazo hecho por el titular en la sesión 8, sin commitear) y se commiteó. Por qué: el invariante R-only no distingue contexto (A31). Verificación: lectura del archivo completo antes de commitear, sin rastro de `python3 -m http.server`.

**Cambio 4 — P-17: script de exploración fuera del pipeline.** Categoría: refactor/estructura. Commit `4217aa8` (`refactor:`). `git mv 30_procesamiento/31_explorar_api_camara.R 50_documentacion/andamios/`. Se verificó por lectura (en R) que ningún script del pipeline lo referencia (las 3 coincidencias eran 2 autorreferencias del propio archivo + 1 en `CLAUDE.md`). Se actualizó `CLAUDE.md:61` a la ruta nueva como consecuencia mecánica del `mv` (el contrato global exige mantener `CLAUDE.md` al día), incluida en el mismo commit. Verificación: `git status` limpio, rename detectado.

**Cambio 5 — Resolver la divergencia con el bot por rebase + push (P-18).** Categoría: git/integración. El push de los 14 commits fue rechazado (`fetch first`): el bot había pusheado `b0abaac` (refresh corte 2026-07-13) el lunes 13-jul. Diagnóstico por lectura: `b0abaac` toca solo `10_configuracion.R` (una línea, `CORTE_FECHA` por `sed`), los 5 `.rds` de origen del 13-jul en `20_insumos/`, y 310 JSON regenerados (+0 en conteos). Sin conflicto de archivos con los commits de higiene. Se midió (Fase 1 del encargo) que los intermedios de `40_salidas/intermedios/` estaban sellados y coherentes con el corte 10 → `validar_corte()` pasaba. Rebase limpio (`git rebase origin/main`): aplanó los 2 merge commits y reaplicó los 12 commits no-merge sobre `b0abaac`. Push fast-forward aceptado (`b0abaac..b707c51`). Verificación: `origin/main...main` → 0/0 contra ref refrescada; `CORTE_FECHA <- "2026-07-13"` confirmado en `main`; supervivencia de todos los cambios verificada TRUE.

**Cambio 6 — Borrar las tres ramas integradas/muertas (local).** Categoría: git/higiene. `fix/cache-key-tope` (muerta), `fix/sello-corte-intermedios` y `feat/presentacion-votos` (contenido en `main` vía rebase, con hashes nuevos). Verificación por `git cherry -v main <rama>` (no por `git diff`, que es simétrico y ciego a la dirección): cero `+` en las tres → todo su contenido publicado en `b707c51`. `fix/cache-key-tope` salió con `-d`; las dos rebaseadas requirieron `-D` (git las ve "not fully merged" por los hashes nuevos, justificado porque el contenido está verificado por patch-id). Borrado solo local; las contrapartes remotas (si existieran) quedan intactas.

## 5. Backlog acumulativo

Vive en `50_documentacion/activa/backlog_acumulativo.md` (archivo canónico independiente desde la sesión 2). **Delta de esta sesión:** la sesión 9 fue de integración de git, no de cambios de producto en el sentido de la nota metodológica del backlog (una solicitud distinguible del usuario que altera el artefacto entregado). Las operaciones de git no son "cambios" del backlog de producto. Se registra en el resumen estadístico por sesión como sesión de higiene con 0 cambios de producto, y el detalle cronológico se limita a una nota de sesión (integración + resolución de divergencia + limpieza de ramas). No hay entradas nuevas numeradas en el detalle cronológico. Sin refinamientos de taxonomía ni reclasificaciones. El archivo canónico manda; ver ahí la numeración correlativa global.

## 6. Bugs de la sesión

No se descubrieron ni resolvieron bugs de código en esta sesión. La única "falla" observada fue el rechazo del push, que no es un bug sino el comportamiento correcto de git ante un remoto adelantado; se resolvió por rebase (§4, Cambio 5).

## 7. Aprendizajes y restricciones descubiertas

- **A32 — Una compuerta de divergencia evaluada contra una ref sin refrescar es falsa.** Regla: toda compuerta que mida `origin/main...main` (commits por pushear, divergencia) debe ir precedida de `git fetch origin` en el mismo encargo; sin él, `rev-list --left-right --count` mide contra la copia local de `origin/main` en disco, que puede tener días de antigüedad. Contexto (qué pasa si se viola): la compuerta "0 divergencia" del primer encargo de push pasó "limpia" (0/14) contra una foto de cinco días y el push fue rechazado igual. Ejemplo: FETCH_HEAD fechado 2026-07-10 vs. remoto real en `b0abaac` del 13-jul. Principio: C.8 (validar contra el estado real, no supuesto). **Aplicado ya en el encargo de rebase (fetch dentro de la propia compuerta).**
- **A33 — El bot de refresh semanal pushea a `main` y compite con el trabajo manual.** Regla: mientras `refresh-semanal.yml` haga `git push` directo a `main` cada lunes (`cron: "0 11 * * 1"`), cualquier commit local sin pushear el lunes siguiente chocará. Contexto: la divergencia de esta sesión fue exactamente eso (refresh del 13-jul vs. higiene local). No es un bug del workflow; es un patrón de proceso. Se formaliza como P-22. Principio: proceso/gobernanza de flujo.
- **A34 — El rebase deja los intermedios locales desfasados por diseño.** Regla: tras integrar un refresh que avanza `CORTE_FECHA`, los intermedios locales de `40_salidas/intermedios/` (gitignored, de la última corrida local) quedan sellados a un corte anterior; el próximo `run_all(only = 39)` fallará por `validar_corte()`. Es la compuerta del sello (A29) funcionando, no un bug. Se resuelve corriendo 32-36. Contexto: no afecta al repo ni al remoto (los intermedios son locales; el JSON publicado lo generó el runner del bot). Principio: C.3, C.8.

## 8. Decisiones de diseño

- **Integración por rebase, no merge, para la divergencia con el bot.** Alternativas: (a) `merge` del refresh en `main` local (crea un merge commit que mezcla un refresh de datos con la higiene); (b) `rebase` de los commits de higiene sobre el refresh (historia lineal, orden causal correcto: primero llega el dato, después la infraestructura que lo valida). Elegida (b). Justificación: `main` es producción de la Cámara; una historia lineal con el refresh en la base y la higiene encima es más legible y respeta el orden causal. Implicancia: los 2 merge commits `--no-ff` de la Fase 2 se aplanaron (esperado); el conteo pasó de 14 a 12 commits reaplicados, con el contenido íntegro.
- **Borrado de ramas por `git cherry` (patch-id), no por `git diff`.** El test correcto para "¿esta rama tiene algo que `main` no refleje?" es direccional y por patch-equivalencia, porque el rebase reaplica commits con hashes nuevos. `git diff main <rama>` es simétrico y habría marcado las tres como CONSERVAR. Implicancia: `-D` es correcto sobre ramas rebaseadas cuyo contenido está verificado por `git cherry`, pese al "not fully merged" de git.

## 9. Constantes y parámetros vigentes

| Constante | Valor | Archivo | Nota |
|---|---|---|---|
| `CORTE_FECHA` | **2026-07-13** | `10_utils/10_configuracion.R` | **AVANZÓ respecto de v08 (2026-07-10).** Vino del refresh automatizado del bot (`b0abaac`), integrado por rebase. Fuente canónica: el archivo, no el traspaso (A21). |
| `LIMITE_COLAPSADO` | 16 | `docs/index.html` | Capa 1. Sin cambios. |
| Sello (estructura) | atributo `sello` = lista de `{corte_fecha, anio_proceso, hash_origen, escrito_en}` | `10_utils/10_utils.R` | **CORRECCIÓN respecto de cómo lo describió v08 §9 (cuatro atributos sueltos): es UN atributo `sello` que contiene una lista de cuatro campos.** `validar_corte()` compara `sellos[[nm]]$corte_fecha` con `CORTE_FECHA` (`10_utils.R:104`). |
| `MAX_SESIONES_DETALLE` | (sin cambios) | `10_utils/10_configuracion.R` | Tope del caché de asistencia. |

## 10. Arquitectura de archivos

Escáner al cierre: `50_documentacion/estructura/estructura_actual.md`, fechado 2026-07-16 07:21:04 (22 carpetas, 410 archivos). Confirmado desde el escáner: `31_explorar_api_camara.R` ya NO está en `30_procesamiento/` (P-17 aplicado), y los `.rds` del corte 2026-07-13 están presentes en `20_insumos/camara/`. La estructura respeta la política. **A25:** la rama del escáner debe confirmarse con `git -C <raiz> branch --show-current` al abrir la próxima sesión; al cierre de esta sesión el trabajo quedó en `main` == `origin/main` == `b707c51`.

## 11. Pendientes y ruta sugerida

**Inventario:**

- **P-22 (choque cron semanal vs. trabajo manual) — NUEVO, decisión de flujo del titular.** El bot `refresh-semanal.yml` pushea a `main` cada lunes 11:00 UTC. Todo commit local sin pushear el lunes siguiente chocará (pasó esta sesión). Opciones a evaluar: (a) que el bot trabaje en rama y abra PR en vez de pushear a `main`; (b) disciplina de pushear siempre antes del lunes; (c) que el flujo local siempre haga `fetch` + rebase antes de trabajar. Complejidad: media (toca el workflow YAML). No bloqueante. Se resuelve mejor en sesión dedicada de gobernanza de flujo, no mezclada con features. Recomendación de la sesión: (a) el bot en rama + PR — hace el refresh auditable y elimina el choque de raíz.
- **Recordatorio operativo (no es pendiente de código):** antes de la próxima corrida local, correr los pasos 32-36 para regenerar los intermedios al corte 2026-07-13; si no, `run_all(only = 39)` fallará por `validar_corte()` (A34). No afecta al repo.
- **Verificación de ramas remotas — administrativo, bajo.** El borrado de las tres ramas fue solo local. Confirmar con `git branch -r` si `fix/cache-key-tope`, `fix/sello-corte-intermedios` o `feat/presentacion-votos` tienen contraparte en `origin`; si la tienen, `git push origin --delete <rama>` con visto bueno. En el `branch -a` del inicio de esta sesión no aparecían upstream (solo `origin/main` y `HEAD`), así que probablemente no exista contraparte remota.
- **Capa 2 (territorio) — SIGUIENTE FEATURE, ahora habilitada.** El working tree está limpio y `main` al día: la condición que la bloqueaba (higiene pendiente) está resuelta. Abre MIDIENDO la fuente (D5): verificar empíricamente que BCN entregue distrito por parlamentario (A28); si no, SERVEL; si ninguna, revisar D5. No codificar antes de medir.
- **Capa 3 (asistencia simétrica, D2) — tras la Capa 2.** Reescritura del `33`: nominal por sesión + fecha + justificación.
- **P-9 (crosswalk partido → tendencia del Senado) — del titular, paralelizable.** Puede avanzar desde ya; es lo único de la Capa 4 que no depende de la Capa 3.
- **P-13 (contrato de datos Cámara/Senado) — Capa 4.** Rama `design/contrato-datos` (intacta).
- **P-7 (pipeline del Senado) — Capa 4.** Depende de P-13 y P-9.

**Evaluación de deuda técnica:** el working tree quedó limpio y las ramas zombis eliminadas; la deuda de integración que arrastraba la sesión 8 está saldada. La zona frágil ahora es el proceso (P-22), no el árbol de git.

**Auditoría de cierre (POLITICA 5.6):**
- #2 (pipeline de cero sin intervención manual): sí, con P-15 ya en `main` (dejó de vivir en rama). El recordatorio de A34 es la compuerta funcionando, no una intervención manual espuria.
- #6 (outputs reproducibles e idempotentes): sí, con el sello en `main`.
- #8 (nombres sin tildes/ñ/espacios): sí.

**Ruta sugerida para la sesión 10:** Capa 2 (territorio), abriendo con la MEDICIÓN de la fuente BCN/SERVEL (D5/A28), no con código. Criterio de éxito: veredicto empírico y documentado de si BCN entrega distrito por parlamentario para los 155, antes de decidir el diseño del crosswalk. Diferir: P-22 a sesión de gobernanza de flujo; el Senado (P-13, P-7) hasta después de la Capa 3. P-9 puede correr en paralelo cuando el titular quiera.

## 12. Instrucciones específicas para la próxima sesión

- ⚠️ NO correr `run_all(only = 39)` local sin antes correr 32-36: los intermedios locales están sellados al corte 2026-07-10 y `CORTE_FECHA` es 2026-07-13; fallará por diseño (A34).
- ⚠️ NO empezar la Capa 2 codificando: abre MIDIENDO la fuente (D5/A28). Verificar que BCN entregue distrito por parlamentario antes de diseñar el crosswalk.
- ⚠️ NO afirmar desde qué rama se tomó el escáner: confirmarlo con `git -C <raiz> branch --show-current` (A25).
- ✅ ANTES de cualquier push, `git fetch origin` DENTRO de la propia compuerta de divergencia (A32); el bot pudo haber pusheado.
- ✅ ANTES de comprometerse con `CORTE_FECHA` en cualquier documento, leerla de `10_configuracion.R`, nunca de un traspaso (A21).
- 🔒 R-only en todo contexto, incluida inspección auxiliar.
- 🔒 La Cámara en producción (`main`) no se toca sin decisión explícita.
- 🔒 La clasificación de tendencia no se altera autónomamente; `IND = NA_character_` es intencional.
- 🔒 `CORTE_FECHA` sin default silencioso.

## 13. Fragmentos de código de referencia

Mensaje diagnóstico esperado del `stop()` de `validar_corte()` en la próxima corrida local (A34), forma correcta ya establecida en v08 §13:

```
validar_corte: 'diputados' declara corte 2026-07-10, pero el corte vigente
(CORTE_FECHA) es 2026-07-13. El intermedio NO corresponde al corte publicado;
regenera los pasos 32-36 con CORTE_FECHA=2026-07-13.
```

Test correcto para decidir el borrado de una rama tras un rebase (por patch-id, no por diff simétrico):

```
git -C <raiz> cherry -v main <rama>
# prefijo '-' en cada línea = main ya contiene un patch equivalente a ese commit
# cero '+' = todo el contenido de la rama está publicado en main -> borrable con -D
```

**Registro de ejecución detallado:** esta sesión no generó logs de andamio nuevos (fue integración de git conducida turno a turno, no un encargo con log de cierre). El detalle vive en el historial de la conversación de la sesión 9.

## 14. Reapertura

- **Nombre del chat:** `transparencia_legislativa_chile, sesión 10 (Claude Opus 4.8)`.
- **Mensaje de apertura pre-armado:** "Tipo: CONTINUATION. El protocolo (`POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`) vive en la knowledge base del Project y se lee desde ahí. La higiene (sesión 9) quedó cerrada: `main` limpio y pusheado en `b707c51`, `CORTE_FECHA = 2026-07-13`. Esta sesión inicia la Capa 2 (territorio), que ABRE MIDIENDO la fuente BCN/SERVEL (D5/A28), no codificando. Adjunto: `traspaso_cierre_v09.md`, `estructura_actual.md` (re-escanear e indicar rama, A25), `backlog_acumulativo.md`."
- **Documentos para la sesión 10:**
  1. *Protocolo (knowledge base, NO adjuntar, solo verificar que esté al día):* `POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
  2. *Opcionales:* `CLAUDE.md` si la Capa 2 corre en Claude Code; `10_configuracion.R` si se necesita el valor vigente de `CORTE_FECHA`.
  3. *Sí se adjuntan:* `traspaso_cierre_v09.md`; `estructura_actual.md` (re-escaneado, con rama declarada); `backlog_acumulativo.md`. Para la medición de la Capa 2, la referencia de la fuente BCN/SERVEL y el documento de decisión D5 (`20260711_decision_ruta_desarrollo.md`).
- **Nota final:** si `CORTE_FECHA` cambió de nuevo entre sesiones (el bot corre cada lunes), adjuntar `10_configuracion.R` actualizado y avisarlo. El valor vigente al cierre de la sesión 9 es 2026-07-13. Antes de la primera corrida local, regenerar 32-36 (A34).

## 15. Errores del asistente (POLITICA 0.5)

| momento | disparador | que_paso | regla_violada | causa_raiz | salvaguarda_presente | patron |
|---|---|---|---|---|---|---|
| Sesión 9, primer encargo de push (compuerta de divergencia) | El propio ejecutor (Claude Code) lo señaló al fallar el push y diagnosticar | El asistente redactó la compuerta "0 divergencia" (`rev-list --left-right --count origin/main...main`) SIN un `git fetch` previo dentro del mismo encargo, de modo que midió contra una copia de `origin/main` de cinco días y dio 0/14 falso; el push fue rechazado | SETTINGS §1.2.6 (no operar sobre estado supuesto); C.8 (validar contra estado real) | Asumió que `origin/main` en disco reflejaba el remoto, sin forzar el refresh que lo garantiza; es una variante de A21 aplicada a refs de git en vez de a constantes del proyecto | POLITICA 5.1 / B.1 + SETTINGS §1.2.6 | Variante de A21 (afirmar/medir sobre un estado sin leer la fuente fresca). Lo atajó el ejecutor, no el diseño del encargo. Corregido en A32 y aplicado en el encargo siguiente (fetch dentro de la compuerta) |
| Sesión 9, encargo de rebase (Fase 1, descripción del sello) | El ejecutor (Claude Code) lo detectó al obtener un "falso rojo" y corregir la lectura | El asistente describió el sello como "cuatro atributos sueltos (`corte_fecha`, `anio_proceso`, `hash_origen`, `escrito_en`)" cuando en realidad es UN atributo `sello` que contiene una lista de cuatro campos; el chequeo escrito contra esa forma dio "SIN SELLAR" en los cinco intermedios | SETTINGS §1.2.6; B.1 (sin supuestos implícitos) | Tomó la descripción del sello del traspaso v08 §9 (que ya la describía como cuatro atributos) sin contrastarla con `attributes()` ni con el código de `validar_corte()` | userPreferences + POLITICA + SETTINGS + el registro de A21 en v07-v08 | Variante de A21. Si el ejecutor no hubiera verificado contra el código real, habría abortado el rebase por una premisa falsa del asistente. Lo atajó la verificación del ejecutor, no el encargo |
| Sesión 9, encargo de borrado de ramas (Fase 1, test de verificación) | El ejecutor (Claude Code) lo señaló al notar que el test pedido era direccionalmente ciego | El asistente pidió verificar la integridad de las ramas con `git diff main <rama> --stat`, un test simétrico que habría marcado las tres ramas como CONSERVAR (diff no vacío por el avance de `main`), contradiciendo la premisa del encargo; el test correcto era `git cherry` (patch-id) | SETTINGS §1.2.6; B.1; B.4 (criterio de éxito verificable mal definido) | Especificó un comando de verificación sin razonar que `git diff` es simétrico y no responde la pregunta direccional "¿la rama tiene algo que `main` no refleje?" | POLITICA + SETTINGS + el encargo | Tercera variante en la misma sesión del patrón "especificar un test/estructura sin verificar que mide lo que se necesita". Lo atajó el ejecutor sustituyendo el test |

**Nota de patrón para análisis cruzado de cartera (SETTINGS §2.2.15):** los tres errores de esta sesión son variantes del mismo patrón raíz —**el asistente especifica una estructura, un valor o un test de verificación desde su memoria o desde un traspaso, sin contrastarlo con la fuente real (el código, `attributes()`, la semántica del comando de git)**— que es la misma familia de A21 (afirmar un valor verificable sin leer la fuente), ahora extendida de "valores del proyecto" a "estructuras de datos y comandos de verificación". En las tres, el correctivo que funcionó fue que **Claude Code verificó contra la fuente real antes de actuar**, no la disciplina del asistente al redactar. Esto refuerza la conclusión ya registrada en v08 §15: "verifica antes de afirmar/especificar" no se sostiene como regla de disciplina y debe subir a POLITICA como precondición mecánica del redactor de encargos: **todo valor, estructura o test que el encargo afirme debe ser marcado como supuesto a verificar por el ejecutor en su Fase 0, nunca como hecho establecido**. Candidata firme a reformulación de salvaguarda para la próxima sesión BIBLIOTECA de `slep_estado_proyectos_monitoreo`. Con esto el patrón A21 acumula siete ocurrencias del asistente en tres sesiones (cuatro en v08, tres en v09), muy por encima del umbral de reformulación de §2.2.15.
