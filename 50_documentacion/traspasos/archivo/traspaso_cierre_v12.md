# Traspaso de cierre — v12

## 1. Identificación

- **Proyecto:** `transparencia_legislativa_chile`
- **Versión:** v12
- **Fecha:** 2026-07-25
- **Sesión:** 12. Foco: confirmar y cerrar el estado que la sesión 11 dejó en vuelo (merge de la Capa 3, workflow semanal), y saldar la deuda de memoria del backlog acumulada durante cinco sesiones.
- **Entorno:** R 4.5.2 / Positron (macOS). Claude Code para ejecución autónoma. Repo público (Rama A). Producción: `https://tomgc.github.io/transparencia_legislativa_chile/`. Modelo de la sesión: Claude Opus 5.
- **Archivos principales modificados:** `50_documentacion/activa/backlog_acumulativo.md` (consolidación de las sesiones 7 a 11, +260 / −14); `50_documentacion/activa/backlog_entradas_sesion_7.md` (**eliminado**, superado por la consolidación); `.github/workflows/refresh-semanal.yml` (`timeout-minutes` declarado; commit no confirmado, ver §3). Ningún archivo de código del pipeline se tocó.

## 2. Resumen ejecutivo

Sesión de consolidación, sin código de pipeline. Abrió confirmando por evidencia lo que la sesión 11 había dejado explícitamente sin verificar: el merge de la Capa 3 se completó y está en producción (`70263cf`), con las cuatro verificaciones en verde (campos legacy idénticos 155/155 contra `ac177be`, tres bloques nuevos en 155/155, territorio 155/155, `docs/index.html` con blob idéntico). El pendiente marcado como alto para antes del lunes 27 (la doble descarga de asistencia contra el workflow semanal) quedó respondido por medición y no por conjetura: un solo job, barrido duplicado de unos 15 s sobre una corrida de ~9 m 50 s, sin ninguna parte del workflow que asuma un barrido único; el riesgo era nulo, y la medición dejó a la vista que el techo real era el default de 360 min, así que se declaró `timeout-minutes` explícito. El grueso de la sesión fue la deuda de memoria: el backlog canónico llevaba cerrado en v06 desde hacía cinco sesiones, con las entradas 24-26 viviendo en un archivo aparte. Se consolidó de una vez de la sesión 7 a la 11, con numeración correlativa verificada (32 entradas, sin huecos ni duplicados), se declararon dos mapeos de categoría y una discrepancia aritmética heredada que no se corrigió en silencio, y se retiró el archivo de trabajo superado (`a527a95`). Tres errores propios del asistente quedan registrados en §15: dos de la familia A21 (uno de ellos, la décima ocurrencia, en su variante de instrumento de verificación mal especificado) y uno de la familia A31 (uso de Python en una inspección auxiliar de solo lectura, contra el invariante R-only). Al cierre quedan dos hechos sin confirmar: el push de `a527a95` y el hash del commit del `timeout-minutes`.

## 3. Estado al cierre

**Qué funciona:**
- **Capa 3 en producción.** `70263cf` es HEAD de `origin/main` desde el inicio de esta sesión, con divergencia post-push `0 0` y las cuatro verificaciones PASA reportadas por el ejecutor.
- **Capa 2 en producción** desde `ac177be` (sesión 11), sin cambios.
- **Workflow semanal medido y sin riesgo** para el refresh del lunes 27: `.github/workflows/refresh-semanal.yml` es el único workflow, un solo job, `cron: "0 11 * * 1"` más `workflow_dispatch`. El `git add` es por directorio (los cachés nuevos entran solos) y el gate de `10_diff_conteos.R` no lee el bloque `asistencia`, así que los campos nuevos no lo alteran.
- **Backlog canónico al día.** `backlog_acumulativo.md` cubre las sesiones 1 a 11 sin huecos, entradas 1-32, 34,05K. Commit `a527a95`, path-scoped a dos rutas, sin push.
- Escáner al cierre: **2026-07-25 12:56:33, 23 carpetas, 461 archivos** (eran 462 y 49 `.md` en el escáner de las 07:58; la baja de exactamente un archivo `.md` corresponde a la eliminación de `backlog_entradas_sesion_7.md`, verificación aritmética independiente del `git status`).

**Qué no funciona / pendiente:**
- Nada roto. Producción sirve las tres capas.
- **Dos hechos SIN confirmar al cierre, que la sesión 13 debe verificar antes de afirmar nada:**
  1. **El push de `a527a95`.** Al último reporte, `main` estaba `## main...origin/main [ahead 1]`. No hay confirmación de que se haya publicado.
  2. **El hash del commit del `timeout-minutes`.** La fase 2 se dio por implementada, pero su reporte no llegó al chat. Que `ahead 1` contara un solo commit sugiere que ese commit ya estaba en `origin/main`, pero eso es **inferencia, no lectura**: verificar con `git log` y `grep -c 'timeout-minutes'` sobre el archivo en `main`.
- **Riesgo con fecha:** el bot corre el lunes 27 a las 11:00 UTC. Si `a527a95` sigue sin pushear para entonces, la sesión 13 abre resolviendo divergencia en vez de trabajando. Es el mismo peaje que ya se pagó en la sesión 9 (rebase) y la 10 (fast-forward): es P-22 cobrando por tercera vez.

**Delta respecto a v11:**
- Capa 3: de "mergeada sin confirmar" a **confirmada en producción** (`70263cf`).
- Workflow: de "sin revisar contra la doble descarga" a **medido, sin riesgo, con timeout declarado**.
- Backlog: de **cinco sesiones de deuda** a canónico al día (23 → 32 entradas).
- Un archivo menos en el repo (`backlog_entradas_sesion_7.md`); 462 → 461 archivos.
- `CORTE_FECHA`: **sin dato nuevo leído en esta sesión.** El último valor verificado contra `10_configuracion.R` es 2026-07-20 (registrado en v11 §9). En esta sesión no se adjuntó el archivo, así que el valor se arrastra como heredado, no como verificado (A21).

## 4. Registro detallado de cambios

**Cambio 1 — Confirmación del merge y la publicación de la Capa 3.** Categoría: git/verificación. No produjo commit propio: fue la lectura del reporte del encargo que corría al cerrar la sesión 11. Verificado: merge `70263cf` (estrategia `ort`, 337 archivos, +190 657 / −949), push `ac177be..70263cf`, divergencia post-push `0 0`. Las cuatro verificaciones sobre `main` antes del push: (1) campos legacy idénticos contra `ac177be`, 0 perfiles con diferencia en los 5 campos ni en los bloques `perfil`/`votaciones`/`proyectos`, e índice con 11 campos previos de orden y valor intactos, 155/155; (2) los tres bloques nuevos presentes en 155/155, con 48 sesiones de denominador en `periodo_vigente` y `tasa_presencia` en el índice; (3) territorio 155/155, 28 distritos; (4) `docs/index.html` con el mismo blob que `ac177be` (`bf0cee83...`), no solo con diff vacío. Por qué importa la forma de (4): comparar el blob prueba identidad de contenido, mientras que un `diff --stat` vacío es compatible con un archivo restaurado; ambas se reportaron.

**Cambio 2 — Medición del workflow contra la doble descarga (cierra el pendiente alto de v11).** Categoría: diagnóstico/automatización. Encargo de solo lectura sobre `.github/workflows/refresh-semanal.yml`. Resultados: único workflow del repo; cadencia `cron: "0 11 * * 1"` (07:00 en Chile en invierno, 08:00 en verano) más `workflow_dispatch`; `grep -c 'timeout-minutes'` = 0 en todos los niveles, de modo que solo aplicaba el default de 360 min por job. El barrido nominal duplicado que introdujo la Capa 3 añade del orden de 15 s (el barrido de 66 sesiones tardó 14 s medidos) sobre una corrida de producción de ~9 m 50 s. Ninguna parte del workflow asume un único barrido: el `git add ... 20_insumos/camara ...` agrega el directorio completo, así que los cachés nuevos (`*_asistencia_nominal_*.rds`, `*_periodo_legislativo.rds`) entran sin listarse por nombre, y el gate de `10_diff_conteos.R` solo lee `votaciones.n_votaciones`, `proyectos.n_proyectos` y el split voto→proyecto, sin tocar el bloque `asistencia`. **Conclusión: el refresh del 27 no corre riesgo por la doble descarga.**

**Cambio 3 — `timeout-minutes` declarado en el workflow.** Categoría: automatización. La medición del Cambio 2 cerró la pregunta de riesgo pero dejó a la vista que el techo real era el default de 6 h: ante un cuelgue de la API, el job se arrastraría seis horas antes de fallar en vez de fallar legible en media hora. Se declaró `timeout-minutes: 30` a nivel de job (margen de ~3x sobre los ~10 min medidos, sin volverse decorativo). **Commit no confirmado en el chat** (ver §3).

**Cambio 4 — Consolidación del backlog acumulativo, sesiones 7 a 11.** Categoría: documentación/memoria. Commit `a527a95` (`docs:`), +260 / −14, path-scoped a dos rutas. El canónico estaba cerrado en v06 (23 entradas) desde hacía cinco sesiones; las entradas 24-26 vivían en `backlog_entradas_sesion_7.md` y las sesiones 8 a 11 no estaban consolidadas. Se incorporaron de una vez: entradas 24-26 copiadas **verbatim** desde el archivo de trabajo (no reescritas), 27-29 derivadas de v08 §4-§5, la sesión 9 como nota de sesión con 0 entradas numeradas (según su propia declaración: las operaciones de git no son cambios de producto), 30 derivada de v10 §5 y 31-32 de v11 §5. Se agregó la columna `%` que exige §2.2.5 y faltaba. Numeración verificada programáticamente: 32 entradas, máximo 32, sin huecos ni duplicados. Por qué se consolidó de una vez y en orden estricto: la numeración es global y permanente, de modo que escribir la sesión 11 antes que la 10 (cuyo traspaso no estaba adjunto al empezar) habría obligado a renumerar, que es exactamente lo que el protocolo prohíbe; se pidió `traspaso_cierre_v10.md` y se esperó en vez de fabricar las entradas faltantes.

**Cambio 5 — Retiro de `backlog_entradas_sesion_7.md`.** Categoría: higiene documental. `git rm` en el mismo commit `a527a95`, no antes. Por qué borrar y no archivar en `_archivo/`: dos archivos reclamando las mismas entradas 24-26 es la heterogeneidad exacta que produjo esta deuda, y el archivo está versionado desde `71e4e68`, de modo que la historia de Git lo preserva mejor que `_archivo/`, que está fuera de Git. Antes de borrar se verificó con `git ls-files` la ruta real (no se adivinó) y se buscaron referencias colgantes: ningún script ni documento activo lo consume; las menciones que quedan son de procedencia.

## 5. Backlog acumulativo

Vive en `50_documentacion/activa/backlog_acumulativo.md`, **al día por primera vez desde v06**. Cubre las sesiones 1 a 11 con 32 entradas correlativas sin huecos, más las dos entradas nuevas de esta sesión (33-34), que llevan el total a **34**.

**Delta de la sesión 12:** 2 entradas nuevas.
- **33.** `timeout-minutes` declarado en el workflow semanal. Categoría: automatización (1 → 2).
- **34.** Consolidación del backlog de las sesiones 7 a 11 y retiro del archivo de trabajo. Categoría: documentación (2 → 3).

**Lo que NO se contó como entrada, declarado para que una sesión futura no lo duplique:**
- El **merge y la publicación de la Capa 3** ocurrieron materialmente al inicio de esta sesión, pero ya están registrados dentro de la entrada 32 (con su hash `70263cf`), porque v11 §5 declaró dos entradas para la sesión 11 y una de ellas es la Capa 3 completa. Crear una entrada nueva por el merge duplicaría el mismo hecho.
- El **push del cierre de la sesión 11** y el commit de consolidación son operaciones de git, no cambios de producto (precedente de la sesión 9).
- La **medición del workflow** (Cambio 2) es el diagnóstico que fundamenta la entrada 33, no un cambio distinguible por sí mismo.

**Discrepancia heredada, abierta:** la columna de N de la clasificación temática suma 35 contra 34 entradas numeradas. Viene de antes de v06 (la tabla declaraba 23 con una columna que sumaba 24). No se corrige en silencio porque resolverla exige reclasificar alguna de las entradas 1-23.

## 6. Bugs de la sesión

**No aplica en esta sesión:** no se tocó código del pipeline ni del frontend, y no se descubrieron bugs de código. El único defecto encontrado fue de un instrumento de verificación redactado por el asistente, que por su naturaleza se registra en §15 (errores del asistente) y no aquí (§2.2.15: un bug de código se corrige editando el código; un error del asistente se corrige ajustando el comportamiento del asistente).

## 7. Aprendizajes y restricciones descubiertas

- **A42 — El código de verificación con escapes de regex no se prescribe inline en `Rscript -e`, y se prueba contra un caso real antes de prescribirse.** Regla: todo verificador que use expresiones regulares va en un archivo `.R` (donde los escapes no atraviesan dos capas de comillas), y antes de entregarse se ejecuta mentalmente o de hecho contra al menos una línea real del artefacto que va a medir. Contexto (qué pasa si se viola): el verificador de numeración del backlog falló dos veces en el mismo turno, primero por colapso de `\\.` a `\.` dentro de `-e` con comillas dobles (R 4.5 rechaza el escape), y luego, ya corregido eso, por extraer el número con `gsub("[^0-9]", "", <línea completa>)`, que concatena todos los dígitos de la línea: la entrada 14, que cita el commit `71ff7c3`, produjo `14713`, descartado después por el filtro `n < 100`. El resultado fue "17 entradas y 9 huecos" sobre un archivo correcto. Principio: B.4, C.8.
- **A43 — Un archivo puede verificarse por dos vías independientes cuando una de ellas no está disponible.** Regla: cuando no se tiene acceso al estado de git, el conteo del escáner sirve como verificación aritmética independiente de una operación de archivos. Contexto: la eliminación de `backlog_entradas_sesion_7.md` se confirmó porque el escáner pasó de 462 a 461 archivos y de 49 a 48 `.md`, exactamente la baja esperada, sin necesidad de leer `git status`. Corolario: el escáner **no** sustituye a git para el estado de ramas y commits (A25 sigue vigente), pero sí es una segunda vía para la presencia o ausencia de archivos.

## 8. Decisiones de diseño

- **D12 — Los mapeos de categoría del backlog se resuelven contra la taxonomía canónica, no creando categorías por sinonimia.** Los traspasos v08 y v10-v11 etiquetaron sus cambios con vocabulario ad hoc ("infraestructura/reproducibilidad", "frontend/presentación"). Se mapearon por significado a las categorías canónicas existentes (`infraestructura`, `interfaz/dashboard`, `extraccion de datos`, `integracion/repo`). Alternativa descartada: abrir categorías nuevas por cada matiz, que rompe la exclusividad mutua por intención primaria que exige §2.2.5 y habría llevado la taxonomía por encima de las 15 categorías con pares casi sinónimos. Implicancia: el mapeo queda declarado en el delta del backlog, de modo que es auditable y reversible si el titular prefiere las categorías separadas.
- **D13 — Un traspaso cerrado no se edita para corregir una afirmación que el tiempo volvió falsa.** `traspaso_cierre_v11.md` §5 y su lista de adjuntos siguen diciendo que la consolidación está pendiente y que hay que adjuntar un archivo que ya no existe. Era cierto cuando se escribió. Alternativa descartada: editar v11 para dejarlo consistente, que falsifica el registro histórico (POLITICA §1.7: los traspasos solo se agregan). La corrección viaja hacia adelante: este traspaso la declara y el propio backlog la declara en su cabecera. Implicancia asumida: un lector que llegue a v11 sin pasar por v12 leerá una instrucción obsoleta; el costo es aceptable frente a corromper la trazabilidad.
- **D14 — Los errores de instrumento del asistente no son causal de detención del ejecutor.** Cuando una verificación prescrita falla por un defecto del propio verificador y el dato subyacente confirma la meta, Claude Code sustituye el instrumento, continúa y reporta literalmente la salida rota, la corregida y el código sustituto. Alternativa descartada: tratar toda discrepancia con lo esperado como bloqueo duro, que convertiría los defectos del redactor en cuello de botella de la ejecución y contradice el reparto dual-Claude. Precedente: la sustitución de `git diff` por `git cherry` en la sesión 9. Límite: la regla de detención sigue vigente cuando el dato **contradice** la meta, no cuando la confirma por otra vía.

## 9. Constantes y parámetros vigentes

| Constante | Valor | Archivo | Nota |
|---|---|---|---|
| `CORTE_FECHA` | 2026-07-20 | `10_utils/10_configuracion.R:41` | **Heredado de v11, NO releído en esta sesión** (el archivo no se adjuntó). El bot corre el 27: verificar antes de usarlo (A21). |
| `timeout-minutes` | 30 (por job) | `.github/workflows/refresh-semanal.yml` | Nuevo. Commit no confirmado. Margen ~3x sobre los ~10 min medidos. |
| Cadencia del refresh | `0 11 * * 1` | idem | Lunes 11:00 UTC + `workflow_dispatch`. Sin cambios. |
| Duración medida del refresh | ~9 m 50 s | medición de esta sesión | Incluye el barrido nominal duplicado (~15 s). |
| Entradas del backlog | 34 (1-34) | `50_documentacion/activa/backlog_acumulativo.md` | Sin huecos ni duplicados, verificado programáticamente. |
| Suma de la columna de clasificación | 35 | idem | Discrepancia heredada de una unidad, declarada y abierta. |
| Todo lo demás | sin cambios | — | Denominadores, serie nominal, catálogo de justificaciones, crosswalk territorial y `LIMITE_COLAPSADO` sin tocar; ver v11 §9. |

## 10. Arquitectura de archivos

Escáner al cierre: `50_documentacion/estructura/estructura_actual.md`, fechado **2026-07-25 12:56:33**, 23 carpetas y **461 archivos** (462 al abrir; la baja de uno, y de 49 a 48 `.md`, corresponde exactamente a la eliminación de `backlog_entradas_sesion_7.md`). No se creó ni movió ninguna carpeta. La estructura respeta la política.

**A25 — rama al cierre:** `main`. Procedencia: la línea `## main...origin/main [ahead 1]` del reporte del ejecutor al commitear `a527a95`. **No se confirmó con `git branch --show-current` en un turno posterior**, de modo que si hubo trabajo entre ese reporte y el cierre, el dato es de esa marca de tiempo y no del instante final.

**Nota de retención (POLITICA §7.4):** en la foto del árbol conviven tres timestamps sellados (`075257`, `075818`, `125633`), porque el escáner fotografía antes de podar. Tras la poda deben quedar dos. El alias `.md` aparece en la foto con el tamaño del snapshot anterior por el mismo motivo (el árbol se captura antes de refrescar el alias); no es una desincronización real.

**Registro de ejecución detallado:** esta sesión no generó logs de andamio (dos encargos cortos sin riesgo de datos, reportados al chat por decisión explícita del encargo). El detalle vive en el historial de la conversación de la sesión 12.

## 11. Pendientes y ruta sugerida

**Inventario:**

- **Push de `a527a95` — inmediato, con fecha.** Tipo: bloqueante blando. `main` quedó `ahead 1` con la consolidación del backlog sin publicar. Impacto: si el bot del lunes 27 escribe en `origin/main` antes del push, la sesión 13 abre resolviendo divergencia. Dependencias: compuerta A32 (`git fetch` dentro del propio encargo). Complejidad: baja. Criterio de éxito: divergencia post-push `0 0` y `git status` sin líneas de archivo.
- **Confirmar el commit del `timeout-minutes` — inmediato.** Tipo: verificación. La fase 2 se implementó pero su reporte no llegó al chat. Impacto: bajo si está, medio si no (el workflow quedaría con el techo de 6 h). Criterio de éxito: hash del commit y `grep -c 'timeout-minutes'` mayor que 0 sobre el archivo en `main`. Precaución: no dispararlo con `workflow_dispatch` para comprobarlo; una corrida real descarga de la API y escribe datos en `main`.
- **P-22 (el bot y el trabajo manual compiten por `main`) — deuda de proceso, alta prioridad.** Tipo: gobernanza de flujo. Recomendación vigente desde v09: el bot trabaja en rama y abre PR. Impacto: ya cobró peaje tres veces (rebase en s9, fast-forward en s10, riesgo vivo en s12). Decisión abierta que el titular debe tomar: si el PR se automergea o pasa por revisión. Complejidad: media. Criterio de éxito: una corrida por `workflow_dispatch` que deje su resultado en una rama y un PR abierto, con `main` intacto. Precaución: no romper el gate de conteos ni el commit condicional al mover el flujo a rama.
- **Frontend de asistencia — funcionalidad nueva, alta complejidad, sesión dedicada.** Los campos de la Capa 3 llevan publicados desde `70263cf` sin que la interfaz los consuma. Decisiones que la sesión debe tomar: **P7** (cuál tasa se muestra por defecto y cómo se explica la diferencia entre ambas), cómo presentar los dos ámbitos sin inducir comparaciones inválidas entre diputados, cómo mostrar la glosa de justificación por entrada y el estado `sin_registro`. Prerequisito: ninguno. Precaución: `docs/index.html` es un archivo de ~61K en producción; cambios quirúrgicos (B.3) y verificación en navegador.
- **Retiro del contrato legacy — deuda con fecha de vencimiento conocida.** Encadenar con el frontend, no antes: al migrar la interfaz a los campos nuevos, retirar el agregado legacy elimina la doble descarga y la discrepancia de un punto entre `n_sesiones` legacy (65 sesiones) y `en_ejercicio` (66).
- **Borrar `feat/territorio-crosswalk` y `feat/capa3-asistencia` — administrativo, bajo.** Ambas publicadas. Verificar con `git cherry -v main <rama>` (patch-id), nunca con `git diff` (simétrico y ciego a la dirección), y `git branch -r` para las contrapartes remotas.
- **Discrepancia aritmética de la clasificación temática — deuda de memoria, baja.** La columna suma 35 contra 34 entradas. Exige auditar la clasificación de las entradas 1-23 contra los traspasos v01-v06 y corregir con una entrada o nota explícita, nunca reescribiendo entradas anteriores.
- **`tests/` no existe — deuda heredada declarada.** La política lo deja a criterio del proyecto (§1.7), pero con tres capas en producción conviene que la decisión sea explícita, aunque sea "no".
- **Auditoría de apertura #3 sin verificar.** Paquetes, rutas y constantes al inicio de cada script: no se comprobó esta sesión (no se leyó código). Resolver en la próxima sesión que toque el `33` o el `39`.
- **Capa 4:** P-13 (contrato Cámara↔Senado), P-7 (pipeline Senado), P-9 (crosswalk partido→tendencia, paralelizable y barato), P-10 (biblioteca histórica, que además desbloquearía el "en ejercicio" plurianual de D7). El RUT sigue anotado como llave nacional para el cruce entre cámaras.
- **Preguntas de fuente, ninguna bloqueante:** P1 (sin catálogo oficial de justificaciones), **P2** (semántica de las rebajas; la única que impediría publicar una "tasa oficial"), P4 (Senado no medido), P5 (`TipoTitularAsistencia` vacío), P3 (14 vs 13 justificaciones sobre sesiones con asistencia registrada; explicación probable no verificada, se cierra en la sesión de frontend).
- **Vigilar los 5 `sin_registro` entre cortes.** Si el número crece, deja de ser una arista y pasa a ser un problema de cobertura de la fuente.
- **`# REVISAR` ajenos:** estado de tramitación de proyectos (`NA`, proxy `admisible`); rol autor/coautor (`Orden=0` para todos los firmantes).
- **Cartera (fuera de este proyecto): sesión BIBLIOTECA de `slep_estado_proyectos_monitoreo`.** A21 acumula **diez** ocurrencias en seis sesiones, con dos variantes maduras (valor afirmado de memoria; instrumento de verificación mal especificado) y un correctivo identificado que no depende de la disciplina del redactor. Ver §15.

**Evaluación de deuda técnica:** el pipeline está limpio y auditado; no hay zonas frágiles nuevas. La deuda que queda es de proceso (P-22, que ya cobró tres veces) y de decisión pendiente (P7, P2). La deuda de memoria, que fue la más grande del proyecto durante cinco sesiones, quedó saldada esta sesión.

**Auditoría de cierre (POLITICA 5.6):**
- #2 (pipeline de cero sin intervención manual): sí, sin cambios respecto de v11; no se ejecutó pipeline esta sesión.
- #5 (cada transformación crítica con validación): no aplica, no hubo transformaciones de datos.
- #6 (outputs reproducibles e idempotentes): sin cambios; la salvedad A40 sigue vigente.
- #7 (decisiones metodológicas como constantes nombradas): sí; `timeout-minutes` quedó como valor declarado en el workflow con su justificación registrada (§4, Cambio 3), no como número suelto.
- #8 (nombres sin tildes, ñ ni espacios): sí.

**Ruta sugerida para la sesión 13:** (1) confirmar el push y el commit del `timeout-minutes`, con fetch previo; (2) **P-22, bot en rama + PR**, media sesión, porque es el único pendiente que abarata todas las sesiones siguientes y la del frontend va a producir varios commits sobre `main`; (3) limpieza de ramas y decisión sobre `tests/`, baratas con el contexto de git ya cargado. Diferir el frontend a una **sesión 14 dedicada**, sin compartir foco, porque es donde se decide P7 y donde muere el contrato legacy. Diferir también la Capa 4 (decisiones de alcance no tomadas) y la discrepancia aritmética del backlog (encadenable a cualquier sesión corta).

## 12. Instrucciones específicas para la próxima sesión

- ⚠️ NO asumir que `a527a95` está pusheado ni que el commit del `timeout-minutes` existe: ninguno de los dos se confirmó al cerrar la sesión 12. Leer el estado real (`git log`, divergencia, `grep` sobre el archivo en `main`) antes de cualquier afirmación.
- ⚠️ NO afirmar `CORTE_FECHA` desde este traspaso: el valor 2026-07-20 se arrastra de v11 y no se releyó en la sesión 12. El bot corre los lunes. Leerlo de `10_configuracion.R` (A21, **diez** ocurrencias).
- ⚠️ NO editar `traspaso_cierre_v11.md` para corregir su §5 y su lista de adjuntos, que quedaron obsoletos: los traspasos solo se agregan (D13).
- ⚠️ NO correr `run_all(only=39)` local sin regenerar 32-36 al corte vigente (A34).
- ⚠️ NO disparar el workflow por `workflow_dispatch` solo para verificar el timeout: una corrida real descarga de la API y escribe en `main`.
- ✅ ANTES de cualquier push, `git fetch origin` dentro de la propia compuerta de divergencia (A32); el bot corre los lunes.
- ✅ ANTES de prescribir un verificador con expresiones regulares, ponerlo en un archivo `.R` y probarlo contra una línea real del artefacto (A42).
- ✅ ANTES de decidir el borrado de una rama, `git cherry -v main <rama>` (patch-id), nunca `git diff`.
- ✅ ANTES de comparar dos agregados, comparar sus universos, no sus fórmulas (A41).
- ✅ ANTES de verificar igualdad de datos en artefactos sellados, comparar el contenido sin los campos de procedencia; el hash siempre difiere.
- 🔒 R-only en todo contexto (excepto `docs/index.html`, HTML/JS single-file sin CDN).
- 🔒 Los campos legacy de `asistencia` y del índice no cambian de nombre, fórmula ni valor mientras el portal los consuma.
- 🔒 `RebajaAsistencia` / `RebajaQuorum` se publican pero no entran en ninguna fórmula mientras P2 siga abierta.
- 🔒 Sin `DOMINIO_JUSTIFICACION` cerrado: un código nuevo emite `warning()`, jamás `stop()`.
- 🔒 La fecha de instalación del período se lee de la API, jamás se hardcodea.
- 🔒 `sin_registro` no se imputa a asistencia ni a inasistencia.
- 🔒 El territorio es insumo estático auditado (D5); `distrito`/`region` jamás fabricados.
- 🔒 `CORTE_FECHA` sin default silencioso; el sello de procedencia no se rompe.
- 🔒 La clasificación de tendencia no se altera autónomamente; `IND = NA_character_` es intencional.
- 🔒 Las entradas del backlog no se reescriben, resumen ni renumeran; un error se corrige con una entrada nueva.

## 13. Fragmentos de código de referencia

Verificador de numeración correlativa del backlog, en la forma correcta (archivo `.R`, no `Rscript -e`; número leído solo del prefijo de línea, no de la línea entera):

```r
# Falla de A42: gsub("[^0-9]", "", linea) concatena TODOS los digitos.
# La entrada 14 cita el commit 71ff7c3 -> "14713" -> descartada por n < 100.
# La forma correcta lee solo el prefijo, y contempla las dos grafias del archivo
# (entradas 1-23 llanas "23. ...", entradas 24+ en negrita "**32. ...").
x     <- readLines(ruta, warn = FALSE)
lineas <- grep("^(\\*\\*)?[0-9]+\\.", x, value = TRUE)
n     <- as.integer(sub("^(\\*\\*)?([0-9]+)\\..*$", "\\2", lineas))
cat("entradas:", length(n),
    "| max:", max(n),
    "| huecos:", paste(setdiff(seq_len(max(n)), n), collapse = ","),
    "| duplicados:", paste(n[duplicated(n)], collapse = ","), "\n")
```

Verificación aritmética de una eliminación de archivo sin acceso a git (A43):

```
# Escaner antes: 462 archivos, 49 .md
# Escaner despues: 461 archivos, 48 .md
# Baja de exactamente 1 archivo .md = la eliminacion esperada, por una via
# independiente del `git status` reportado por el ejecutor.
```

## 14. Reapertura

- **Nombre del chat:** `transparencia_legislativa_chile, sesión 13 (Claude Opus 5)`.
- **Mensaje de apertura pre-armado:** "Tipo: CONTINUATION. El protocolo (`POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`) vive en la knowledge base del Project y se lee desde ahí. Las tres capas están en producción (Capa 3 confirmada en `70263cf`). El backlog quedó consolidado y al día (32 entradas hasta la sesión 11, más 2 de la sesión 12). **Dos hechos sin confirmar al cerrar la sesión 12: el push de `a527a95` y el hash del commit del `timeout-minutes` del workflow; hay que leerlos antes de afirmar nada.** El foco propuesto es P-22 (el bot trabaja en rama y abre PR), que ya cobró peaje tres veces. `CORTE_FECHA` = 2026-07-20 heredado de v11 y NO releído en la sesión 12: confirmar en `10_configuracion.R` (el bot corre los lunes). Adjunto: `traspaso_cierre_v12.md`, `estructura_actual.md` (re-escaneado, con rama declarada)."
- **Documentos para la sesión 13:**
  1. *Protocolo (knowledge base, NO adjuntar, solo verificar que esté al día):* `POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
  2. *Opcionales según el foco real:* `CLAUDE.md` si el trabajo corre en Claude Code; `10_configuracion.R` para el valor vigente de `CORTE_FECHA`; `.github/workflows/refresh-semanal.yml` **si la sesión aborda P-22** (es el archivo que se va a reescribir, y es imprescindible en ese caso); `docs/index.html` y `20260725_capa3_asistencia_log.md` si la sesión se adelanta al frontend; `backlog_acumulativo.md` solo si se aborda la discrepancia aritmética.
  3. *Sí se adjuntan:* `traspaso_cierre_v12.md`; `estructura_actual.md` (re-escaneado, con rama declarada).
- **Nota final:** si `CORTE_FECHA` cambió (el bot corre cada lunes; el 27 es el próximo), adjuntar `10_configuracion.R` actualizado y avisarlo en el mensaje de apertura. Antes de cualquier corrida local, regenerar 32-36 (A34). Verificar la rama con `git -C <raíz> branch --show-current` al abrir: el dato de este traspaso (`main`) proviene de un reporte intermedio, no del instante de cierre.

## 15. Errores del asistente (POLITICA 0.5)

| momento | disparador | que_paso | regla_violada | causa_raiz | salvaguarda_presente | patron |
|---|---|---|---|---|---|---|
| Sesión 12, encargo de versionado de la consolidación del backlog (bloque de verificación previa al commit) | El ejecutor (Claude Code) lo señaló espontáneamente al obtener huecos falsos y diagnosticar el instrumento | El asistente prescribió un verificador en R con dos defectos independientes: escapes de regex frágiles dentro de `Rscript -e` con comillas dobles (`\\.` colapsa a `\.` y R 4.5 lo rechaza), y extracción del número por `gsub("[^0-9]", "", <línea completa>)`, que concatena todos los dígitos de la línea (la entrada 14, que cita el commit `71ff7c3`, produce `14713`, descartado luego por `n < 100`). Reportó "17 entradas, máx 26, 9 huecos" sobre un archivo correcto de 32 entradas sin huecos | B.4 (criterio de éxito definido sobre un instrumento que no mide lo que se necesita); SETTINGS §1.2.6 | Escribió el extractor desde la forma general del problema ("sacar los dígitos de la línea") sin ejecutarlo contra una línea real, teniendo el archivo delante y habiendo corrido él mismo un chequeo equivalente minutos antes. No fue falta de acceso a la fuente sino falta de prueba del instrumento | POLITICA 5.1 / B.1 + B.4 + SETTINGS §1.2.6 + el registro acumulado de A21 en v07-v11, incluida la variante idéntica de v09 (`git diff` simétrico donde correspondía `git cherry`) | **Décima ocurrencia de A21**, segunda de la variante "test de verificación mal especificado" (la primera fue v09, `git diff` vs `git cherry`). Ángulo nuevo: el instrumento falló de forma mecánica, no conceptual, y produjo un falso negativo ruidoso. El correctivo volvió a ser la disciplina del ejecutor, por sexta vez consecutiva |
| Sesión 12, Fase C de la apertura (ruta de desarrollo propuesta) | El asistente lo detectó al recibir `traspaso_cierre_v10.md` y comprobar que la consolidación no era ejecutable con los insumos que él mismo había pedido | El asistente propuso la consolidación del backlog como prioridad de la sesión y listó como suficientes los cuatro adjuntos que v11 §5 nombraba, sin comprobar que ese inventario cubriera todas las sesiones sin consolidar. Faltaba `traspaso_cierre_v10.md`, de modo que la tarea se ejecutó en dos tandas y hubo que detenerse a pedir el archivo | B.1 (sin supuestos implícitos); SETTINGS §1.2.4 (los pendientes son el mapa de la próxima ruta: sus campos son el insumo, no una lista a copiar sin validar) | Tomó el inventario de insumos de un traspaso como completo por venir del propio protocolo, sin contrastarlo contra el hecho verificable de qué sesiones estaban sin consolidar (v08, v09, **v10**, v11), que el mismo traspaso declaraba una línea antes | POLITICA 5.1 / B.1 + SETTINGS §1.2.4 + el registro acumulado de A21 | Variante de A21 aplicada a un inventario de insumos en vez de a un valor. Coste real bajo (una tanda extra, ningún dato fabricado: se pidió el archivo en vez de reconstruir la sesión 10 de memoria), pero es el mismo mecanismo: confiar en lo que un documento afirma sin cruzarlo con lo que el propio documento permite verificar |

| Sesión 12, redacción del cierre (inspección auxiliar del backlog antes de editar sus tablas) | El asistente lo detectó al releer su propia llamada, después de ejecutarla | El asistente usó Python (`python3 - <<'PY'`) para contar apariciones de tres cadenas en `backlog_acumulativo.md` antes de aplicar las ediciones, en vez de R o de herramientas de shell. Inspección de solo lectura, sin efecto sobre ningún artefacto entregado, pero prohibida igual | 🔒 R-only en todo contexto, incluida inspección auxiliar (`userPreferences`, tooling; POLITICA 5.1; instrucción heredada §12 de v08-v11, donde el invariante dice explícitamente "en todo contexto") | Reflejo de alcanzar la herramienta más rápida para una tarea trivial de conteo, antes de que el invariante se activara conscientemente. El invariante estaba escrito en cuatro lugares distintos del contexto de la sesión | `userPreferences` + POLITICA + las instrucciones §12 de v08, v09, v10 y v11 (los cuatro traspasos lo repiten) | **Segunda ocurrencia del patrón A31** (Python en contexto auxiliar), y **primera del asistente**: la primera fue de Claude Code en la sesión 8, también en una inspección auxiliar y también autodetectada. NO es variante de A21. Dato relevante para la cartera: el mismo invariante, escrito y repetido, ha sido violado por las dos partes del reparto dual-Claude en el mismo tipo de tarea (conteo trivial de solo lectura), lo que sugiere que el punto débil no es el conocimiento de la regla sino el momento en que se activa: antes de la primera acción, no al revisarla |

**Nota de patrón para análisis cruzado de cartera (SETTINGS §2.2.15):** con esta sesión, A21 acumula **diez ocurrencias en seis sesiones** (cuatro en v08, tres en v09, una en v10, una en v11, dos en v12). El registro ya distingue dos variantes maduras: **(a)** afirmar un valor verificable de memoria (v08 `CORTE_FECHA`, v10 Carter=20, v11 la identidad de asistencia densa), y **(b)** especificar un instrumento de verificación que no mide lo que se necesita (v09 `git diff` simétrico, v12 el extractor de numeración). La salvaguarda propuesta en v11 (todo criterio de éxito debe citar la línea o cifra del insumo del que se deriva) direcciona la variante (a) pero **no** habría atajado la (b): en la variante (b) el criterio es correcto y lo que está roto es el código que lo mide. La regla que sí ataja (b) es A42 de esta sesión: **el código de verificación con expresiones regulares va en un archivo `.R`, nunca inline en `Rscript -e`, y se prueba contra al menos un caso real antes de prescribirse.** Ambas variantes comparten la misma causa raíz, ahora nítida tras seis sesiones: el asistente escribe el instrumento desde la forma general del problema en vez de derivarlo del artefacto concreto que tiene delante. Y las diez ocurrencias comparten el mismo correctivo efectivo: **Claude Code verifica contra la fuente real en su Fase 0 y sustituye lo que no sirve**, mecanismo que ha funcionado seis veces consecutivas sin costo de re-trabajo. Esta sesión aporta además la contraparte de proceso, registrada como D14: los errores de instrumento del asistente **no** deben tratarse como causal de detención del ejecutor cuando el dato subyacente confirma la meta, porque eso convertiría los defectos del redactor en el cuello de botella de la ejecución. Candidata madura y sobrada para la próxima sesión BIBLIOTECA de `slep_estado_proyectos_monitoreo`: diez ocurrencias, dos variantes caracterizadas, una causa raíz precisa y un correctivo estructural probado que ninguna de las salvaguardas escritas direcciona todavía.

**Segundo patrón de esta sesión, distinto de A21: A31 (invariante R-only en contexto auxiliar).** El tercer error de la tabla no pertenece a la familia A21. Es la segunda ocurrencia de A31 en el proyecto y la primera del asistente: la primera fue de Claude Code en la sesión 8, y ambas ocurrieron en el mismo tipo de tarea (un conteo trivial de solo lectura) y ambas fueron autodetectadas después de ejecutar, no antes. Que el mismo invariante, escrito en `userPreferences`, en POLITICA y repetido como 🔒 en las instrucciones §12 de cuatro traspasos consecutivos, haya sido violado por las **dos** partes del reparto dual-Claude, indica que el punto débil no es el conocimiento de la regla sino el instante en que se activa: se recuerda al revisar la acción, no al elegir la herramienta. Es un segundo insumo para la sesión BIBLIOTECA de cartera, con una forma de salvaguarda distinta de la de A21: aquí no sirve "citar la procedencia" ni "probar el instrumento", sino un chequeo de herramienta previo a la primera llamada de cualquier encargo o turno que vaya a inspeccionar archivos.
