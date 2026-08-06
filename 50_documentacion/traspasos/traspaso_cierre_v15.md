# Traspaso de cierre — v15

## 1. Identificación

- **Proyecto:** `transparencia_legislativa_chile` (portal serverless de transparencia legislativa de Chile, Cámara de Diputados, 155 diputados)
- **Versión del traspaso:** v15
- **Fecha:** 2026-08-03
- **Sesión:** 15. **Foco:** retiro del contrato legacy de asistencia (P-48) con su cadena P-52 y P-56, y redacción del encargo de auditoría de fuentes Cámara/Senado que desbloquea el pipeline del Senado.
- **Entorno:** R 4.5.2, Positron, macOS. Claude Code en la app de escritorio, con Ultracode activo en el segundo encargo. `gh` CLI autenticado. GitHub Actions con bot semanal.
- **Protocolo usado:** `POLITICA_PROYECTO.md` **v5.6** y `SETTINGS_Y_PROMPTS_OPERACIONALES.md` **v16** (fuente: encabezados de ambos, leídos vía `project_knowledge_search` en esta sesión). El traspaso v14 citaba v5.4/v12 y el asistente declaró v5.5/v14 en la Fase A: **ambas declaraciones eran incorrectas** (ver §15, error 1).
- **Archivos principales modificados:** `30_procesamiento/33_extraer_asistencia.R`, `30_procesamiento/39_consolidar_json.R`, `docs/index.html`, `.gitignore`, más la regeneración de `40_salidas/json/` y `docs/data/`.
- **Registro de ejecución detallado:** `50_documentacion/andamios/logs/20260803_p48_retiro_legacy_log.md` (log de la sesión de Claude Code; el detalle paso a paso no se reproduce aquí).

---

## 2. Resumen ejecutivo

La sesión se propuso retirar el contrato legacy de asistencia, que quedó sin precondiciones al cerrar P-47 en la sesión 14, y encadenar los dos pendientes baratos que se cierran leyendo los mismos archivos. Se logró todo el foco y más: los cinco campos legacy del bloque `asistencia` y el `tasa_asistencia` del índice dejaron de publicarse, el `33` perdió su segunda descarga completa de la asistencia, P-52 quedó respondida con evidencia, P-55 resuelta y P-56 cerrada como `+0` real. La verificación fue inusualmente fuerte: 1 058 008 claves comparadas en 155 perfiles con cero diferencias en los campos sobrevivientes, confirmadas después por un panel adversarial de cuatro agentes independientes que además detectó y corrigió su propio falso positivo. Se cerró también la prioridad 1 heredada: Pages sí había republicado el `index.html` de la sesión 14, comprobado por identidad de md5 contra `origin/main`. El trabajo quedó en el PR #4, abierto y sin mergear, porque cambia un contrato de datos público y esa decisión es del titular. Un segundo encargo, ya en modo Ultracode, midió el conflicto entre ese PR y el PR #3 del bot y produjo el hallazgo operativo más importante de la sesión: el conflicto es de un solo hunk por archivo y resolverlo a nivel de archivo resucita el contrato legacy en 310 de 310 perfiles. Quedó además redactado, y sin ejecutar, el encargo de auditoría de fuentes que desbloquea el pipeline del Senado. El proyecto cierra sin bugs de código, con dos PRs abiertos que exigen una decisión de merge, y con dos gatillos de protocolo encendidos que la apertura de esta sesión no declaró.

---

## 3. Estado al cierre

### Qué funciona

- **Pipeline completo**, corrido de punta a cabo dos veces en esta sesión sobre los cachés del corte `2026-07-27`, sin llamadas a la API (última ejecución exitosa: Fase 3 del encargo P-48, 2026-08-03).
- **Las tres capas en producción**: votaciones/frontend (Capa 1), territorio/distrito (Capa 2) y asistencia nominal simétrica con dos ámbitos (Capa 3).
- **Pages republica correctamente**: el `index.html` servido y el de `origin/main` comparten md5 `d946f6ebce626391dac28d51dd8a5262` y 72 289 bytes.
- **El gate de conteos del bot** no dependía del contrato legacy y no requirió adaptación.

### Qué no funciona / qué está en suspenso

- **Nada roto.** Cero bugs de código en la sesión.
- **Dos PRs abiertos que se pisan**: el #4 (retiro del contrato) y el #3 del bot (`refresh/2026-08-03`). Ambos tocan los mismos 310 archivos de datos. Ninguno mergeado.
- **Dos commits sin pushear** en `retiro/contrato-legacy-asistencia` (`25a579f`, `53d78b5`): las correcciones al log. Claude Code no los empujó porque actualizar el PR es acción hacia afuera y no estaba en el encargo.

### Delta respecto a v14

| Dimensión | v14 | v15 |
|---|---|---|
| Contrato publicado del bloque `asistencia` | 9 claves (5 legacy + 4 de Capa 3) | **4 claves** (`alcance_temporal`, `periodo_vigente`, `en_ejercicio`, `sesiones`) |
| Índice | `tasa_asistencia` + `tasa_presencia` | **solo `tasa_presencia`** |
| Descargas de asistencia por corrida del `33` | 2 (legacy + nominal) | **1** (nominal) |
| Intermedios leídos por el `39` | 7 | **6** |
| Pages republicado | sin comprobar | **comprobado por md5** |
| P-52 / P-55 / P-56 | abiertos | **cerrados** |
| Versiones de protocolo declaradas | v5.4 / v12 | **v5.6 / v16** (corregidas en sesión) |

---

## 4. Registro detallado de cambios

### 4.1 `39_consolidar_json.R` — retiro del contrato publicado

- **Categoría temática:** deuda técnica / contrato de datos.
- **Qué:** salieron del bloque `asistencia` de cada perfil `anio`, `n_sesiones`, `n_asiste`, `n_no_asiste` y `tasa_asistencia`; salió del índice `tasa_asistencia`. Del código salieron `leer("asistencia")`, su `stopifnot` de llave, su `cobertura()`, el `resumen_asistencia` y su `left_join`.
- **Por qué (C.11):** desde `f55430d` (sesión 14) ningún consumidor los lee. `anio` no se pierde: viaja en `asistencia.alcance_temporal.anio_proceso`, que además declara su ámbito, de modo que el retiro elimina una duplicación sin ámbito, no información.
- **Cómo se verificó (B.4):** 0 de 155 perfiles con campo residual; 0 de 155 entradas del índice con `tasa_asistencia`; contra la línea base pre-cambio, 1 058 008 claves comparadas en 155 perfiles y 1 705 en el índice, **0 diferencias**, excluido `metadatos.generado`; `docs/data` reproduce `40_salidas/json` en los 155 md5.
- **Dependencias afectadas:** `validar_corte()` recibe ahora 6 sellos en vez de 7. Se comprobó por lectura (`10_utils/10_utils.R:104-124`) que itera `names(sellos)` sin número fijo ni nombre esperado: **no requirió adaptación**, y por eso `10_utils.R` no aparece en ningún commit.
- **Commit:** `4f0bfba`.

### 4.2 `33_extraer_asistencia.R` — retiro del bloque legacy y su descarga duplicada

- **Categoría temática:** deuda técnica / costo recurrente.
- **Qué:** salió el bloque 1 completo (`extraer_asistencia_long()`, su llamada, la validación de dominio, el agregado por diputado, su validación de integridad y la escritura de `40_salidas/intermedios/asistencia.rds`), más el `# REVISAR` que anunciaba este retiro. Se reescribió el encabezado del archivo para describir una sola granularidad.
- **Por qué (C.11):** era una segunda descarga completa de la asistencia en cada refresh semanal, bajo su propia clave de caché, sostenida solo para alimentar campos que ya no consumía nadie.
- **Cómo se verificó (B.4):** regeneración completa 32-36 y 39, y comparación contra la salida del cambio anterior: 1 058 008 claves en 155 perfiles y 1 705 en el índice, **0 diferencias**. Evidencia textual del barrido único: el log del `33` pasó de dos `cache hit` de asistencia a uno.
- **Decisiones tomadas en autonomía por Claude Code, todas correctas:** el intermedio `asistencia.rds` no estaba trackeado (el `.gitignore` ya excluye `40_salidas/intermedios/*.rds`), así que no hubo `git rm`; los `.rds` de la clave `asistencia_long_<anio>` en `20_insumos/camara/` **no se borraron** por gobernanza de dato crudo, solo dejaron de leerse; dos comentarios del bloque nominal que comparaban su universo con el legacy se reescribieron en pasado para que la explicación de la clave de caché siga en pie.
- **Commit:** `970d564`.

### 4.3 `docs/index.html` — glosa

- **Categoría temática:** documentación / coherencia del contrato.
- **Qué:** la glosa del bloque de derivación afirmaba que `tasa_asistencia` seguía publicado y solo no se consumía en el cliente. Tras el retiro eso es falso sobre el contrato. Se reescribió para declarar que `tasa_presencia` es el único indicador de asistencia del índice.
- **Por qué (C.11):** una glosa que describe un campo inexistente es una afirmación falsa sobre el contrato publicado, mismo mecanismo del aprendizaje A50.
- **Cómo se verificó (B.4):** `node --check` limpio sobre el `<script>` extraído; render local en dos fichas límite, 1013 con `n_no_asiste = 0` y 1107 con 49, ambas con las cuatro mini-tarjetas, la tabla de sesiones (69 filas en el alcance) y la frase condicional de justificación comportándose según A50.
- **Commit:** `545d053`.

### 4.4 `.gitignore` — configuración local de Claude Code (P-55)

- **Categoría temática:** administrativo / seguridad.
- **Qué:** `.claude/settings.local.json` pasó a estar ignorado. Se ignoró **el archivo, no la carpeta**: `.claude/launch.json` está versionado y debe seguir estándolo, porque configura el servidor de preview y sirve a cualquiera que clone.
- **Por qué (C.11):** contenía una entrada de permisos con rutas absolutas del filesystem del titular, en un repositorio público.
- **Commit:** `a2b0933`.

### 4.5 Corrección del log de ejecución (segundo encargo)

- **Categoría temática:** documentación / trazabilidad de cifras.
- **Qué:** la tabla §9 del log declaraba 9 183 filas de la serie nominal y otras dos secciones declaraban 10 690, citando ambas "log del 33". Se reescribió la tabla con tres columnas (qué mide / valor / artefacto) y se le sumaron las dos cifras de claves sin exclusiones.
- **Por qué (C.11):** no había cifra falsa sino **defecto de atribución**: el `33` emite ambas cifras y "log del 33" no identifica cuál. Ver D22.
- **Commits:** `25a579f` y `53d78b5` (**sin pushear**).

---

## 5. Backlog acumulativo

El backlog canónico vive en `50_documentacion/activa/backlog_acumulativo.md` (43,16 K; fuente: escáner `20260803_185714`) y **no se reproduce aquí**: se le agregan al final las entradas nuevas de esta sesión, con correlativo global asignado **leyendo la última entrada del propio archivo**, nunca de memoria (A21 / PAT-01).

**Entradas nuevas de la sesión 15, en orden, para agregar al final:**

1. Retiro del contrato legacy de asistencia del JSON publicado: cinco campos del bloque `asistencia` del perfil y `tasa_asistencia` del índice. Categoría: deuda técnica.
2. Eliminación del bloque de extracción legacy del `33` y de su segunda descarga completa de la asistencia por corrida. Categoría: deuda técnica.
3. Corrección de la glosa de `docs/index.html` que citaba el campo retirado como vigente. Categoría: documentación.
4. `.claude/settings.local.json` excluido del versionado por contener rutas absolutas del titular en un repositorio público (cierra P-55). Categoría: administrativo.
5. Cierre de P-56: el `+0` de conteos entre los cortes del 25 y del 27 es real, no anomalía de captura. Categoría: deuda de datos.
6. Cierre de P-52 con hallazgo abierto: la auditoría de apertura #3 da conforme sobre 11 scripts y cero rutas absolutas escritas a mano. Categoría: documentación.
7. Comprobación de la republicación de Pages por identidad de md5, que cerró la prioridad 1 heredada de la sesión 14. Categoría: verificación.
8. Medición del conflicto entre el PR #4 y el PR #3 del bot, con el hallazgo del hunk único y del modo de fallo por resolución a nivel de archivo. Categoría: deuda de datos.
9. Redacción del encargo de auditoría de fuentes Cámara/Senado, sin ejecutar. Categoría: documentación.

---

## 6. Bugs de la sesión

**Ninguno.** No se detectó ni se introdujo ningún bug de código. Los tres tropiezos de la ejecución (§6 del log) no llegaron a ningún commit ni alteraron ningún dato: el criterio inalcanzable de la Fase 1, el corte que se llevó una línea de más y se restauró en el mismo movimiento, y el `grep` con metacaracteres sin `-F`. El primero y el tercero son errores del asistente y del instrumental, no del producto, y están registrados en §15 y en A57.

---

## 7. Aprendizajes y restricciones descubiertas

### A54 — Un criterio de éxito que compara artefactos regenerados debe excluir explícitamente los campos volátiles, en el mismo lugar donde se enuncia

**Regla:** todo gate que compare una salida regenerada contra una versión anterior declara, en su propio enunciado, qué campos son volátiles por construcción y quedan fuera de la comparación. No basta con declararlo en otra fase del mismo documento.
**Principio:** B.4 (ejecución dirigida por objetivos).
**Contexto (qué pasa si se viola):** el gate no puede pasar nunca, y el ejecutor queda ante la disyuntiva de detenerse por un falso hallazgo o seguir contra la letra del encargo. Ambas salidas son malas: la primera cuesta una sesión, la segunda erosiona el valor de los gates.
**Ejemplo de la sesión:** la Fase 1.3 del encargo P-48 pedía `git status --porcelain` vacío tras regenerar, y la Fase 2.3 del mismo encargo excluía `metadatos.generado` de la comparación. Como ese campo es un timestamp de reloj, `git status` **nunca** puede quedar vacío después de regenerar. Salieron 310 archivos modificados y Claude Code tuvo que diagnosticar antes de continuar.
**Corolario:** el check correcto para "la salida es reproducible" no es `git status`, es la comparación clave a clave con los campos volátiles excluidos.

### A55 — Un conflicto de merge sobre archivos de datos se resuelve por hunk, jamás por archivo

**Regla:** ante un conflicto que abarca cientos de archivos de datos regenerados, se mide **cuántos hunks tiene cada archivo** antes de decidir cómo resolver. Si el conflicto es de un hunk aislado, se resuelve por hunk. `git checkout --ours` o `--theirs` a nivel de archivo está prohibido sobre artefactos de datos que hayan sufrido un cambio de contrato.
**Principio:** C.11 (causa raíz sobre síntoma).
**Contexto (qué pasa si se viola):** el gesto instintivo ante 310 archivos en conflicto es resolver por archivo, porque "es data regenerada, me quedo con la del bot". En este proyecto eso **resucita el contrato legacy en 310 de 310 perfiles**, y encima deja el estado incoherente, porque el índice no conflicta y sí conserva la versión sin `tasa_asistencia`.
**Ejemplo de la sesión:** medido sobre los dos PRs abiertos: 310 de 310 blobs con exactamente un hunk, y ese hunk es la línea `metadatos.generado` en 310 de 310. Resolviendo por hunk, por cualquiera de los dos lados, quedan 0 de 310 con campos legacy y `corte_fecha = 2026-08-03` en 310 de 310.

### A56 — Cuando dos cifras del mismo objeto difieren, la falla suele ser de atribución y no de aritmética

**Regla:** toda cifra publicada declara **qué mide y de qué artefacto sale**, no solo la familia de su fuente. "Log del `33`" no es una fuente cuando el `33` emite varias cifras del mismo nombre.
**Principio:** POLITICA 0.6 (marcador de fuente en línea).
**Contexto (qué pasa si se viola):** una contradicción aparente dispara una investigación por aritmética que no encuentra nada, porque ambas cifras son correctas y miden objetos distintos. El costo no es el error sino la búsqueda.
**Ejemplo de la sesión:** 10 690 son las filas del caché crudo (69 sesiones × los 239 ids que registra la fuente, incluidos los 84 del período anterior); 9 183 son las filas de la serie persistida, acotada al roster vigente y, por diputado, a su universo `en_ejercicio`. Reconciliación verificada por identidad de conjuntos, y confirmada por una derivación independiente que no toca el caché: 71 × 69 + 84 × 51 = 9 183 (71 reelectos con 69 sesiones, 84 entrantes con 51).

### A57 — Un patrón de búsqueda con metacaracteres se corre con `-F` o no se corre

**Regla:** todo `grep` de verificación cuyo patrón contenga `{`, `}`, `[`, `]`, `(`, `)`, `$` o `.` va con `-F`, o el patrón se escapa explícitamente. Un check que devuelve vacío por su propio patrón es indistinguible de un check que devuelve vacío porque el objeto no existe.
**Principio:** B.4.
**Contexto:** es la tercera ocurrencia en la cartera de un check de verificación que falla por su patrón y no por el objeto verificado. Es el mismo mecanismo de PAT-02 (`gh pr diff --name-only` devolviendo 406 y dejando un `grep -c` contando sobre vacío): **el verde silencioso**.
**Ejemplo de la sesión:** buscar `refresh/${CORTE}` en el workflow sin `-F` devuelve vacío; con `-F` aparece en la línea 108.

---

## 8. Decisiones de diseño

### D21 — El retiro del contrato legacy se publica como retiro, no como deprecación anunciada

- **Decisión:** los cinco campos del perfil y el `tasa_asistencia` del índice salen del JSON en un solo cambio, sin período de deprecación ni campos vacíos de transición.
- **Alternativas consideradas:** (a) deprecación anunciada, publicando los campos con valor nulo durante N cortes; (b) retiro directo.
- **Justificación:** dentro del proyecto no queda ningún consumidor, comprobado por lectura sobre 80 archivos de código y documentación. Un consumidor externo desconocido rompería igual con campos nulos, porque el valor cambiaría de sentido sin avisar; el retiro al menos falla ruidosamente.
- **Tensión resuelta:** B.1 (coherencia del contrato) contra C.11 (estabilidad para terceros). Se resolvió a favor de B.1 con una salvaguarda: el PR queda abierto y la publicación es decisión explícita del titular, no un efecto colateral del refactor.
- **Implicancia:** el JSON público cambia de forma. Cualquier consumidor externo que leyera `asistencia.tasa_asistencia` o los cuatro conteos legacy dejará de encontrarlos.

### D22 — Toda cifra del proyecto declara el artefacto del que sale, no la familia de su fuente

- **Decisión:** las tablas de cifras de los logs y traspasos llevan una columna de artefacto con la ruta concreta, no una referencia genérica al proceso que la emitió.
- **Alternativas consideradas:** (a) mantener la referencia por proceso y confiar en el contexto; (b) exigir el artefacto.
- **Justificación:** el `33` emite dos cifras distintas del mismo concepto y ambas son correctas. Sin la ruta, el lector no puede saber cuál está leyendo, y una contradicción aparente cuesta una investigación completa.
- **Implicancia:** es la forma operativa de POLITICA 0.6 dentro de las tablas de cifras, y la reformulación es de tipo **forma del output** (SETTINGS 2.2.16), no de disciplina: se arregla con una columna obligatoria, no con una prohibición.

---

## 9. Constantes y parámetros

**Sin cambios en esta sesión.** `CORTE_FECHA <- "2026-07-27"` sigue vigente (fuente: `10_utils/10_configuracion.R:41`, leído en la Fase 0 del encargo P-48). El PR #3 del bot propone `2026-08-03`, pero no está mergeado.

Fuente canónica de las constantes vigentes: `10_utils/10_configuracion.R`.

Constante decidida y **no** movida en esta sesión: `CODIGOS_JUSTIFICACION_OBSERVADOS`, hoy en `30_procesamiento/33_extraer_asistencia.R:162`. Ver P-57.

---

## 10. Arquitectura de archivos

Escáner de cierre: `50_documentacion/estructura/20260803_185714_estructura.md` — **23 carpetas, 481 archivos** (fuente: cabecera del escáner, leída en esta sesión).

### Desviaciones respecto de la política vigente

| # | Desviación | Estado |
|---|---|---|
| 1 | **`50_documentacion/traspasos/` tiene 14 archivos planos** (`traspaso_cierre_v01.md` a `v14.md`) y no existe `traspasos/archivo/` | **Se corrige en ESTE cierre**, no se hereda: SETTINGS 2.1 lo declara parte del cierre |
| 2 | Los archivos de `50_documentacion/activa/` no llevan prefijo `50_`, salvo los exceptuados por contrato de cartera | Deuda heredada. Entra por §4.7 (ordenación del repositorio), no se ajusta en silencio |
| 3 | Tres encargos de Senado viven en `activa/` cuando son andamios (`encargo_contrato_datos_camara_senado.md`, `encargo_exploracion_asistencia_senado_h1bis.md`, `encargo_exploracion_senado_v02.md`), y hay un cuarto en `activa/decisiones/` | Deuda heredada, misma vía que la anterior. Los dos encargos nuevos de esta sesión sí nacieron en `andamios/` |
| 4 | `Portal Transparencia.dc.html` con espacio en el nombre | **Excepción permanente declarada** (v13 §10): andamio congelado |
| 5 | `50_documentacion/estructura/` tiene tres pares de snapshots y la retención es 2 | Menor; lo resuelve el escáner en la próxima poda |

---

## 11. Pendientes y ruta sugerida

### 11.1 Inventario

#### P-57 — Migrar `CODIGOS_JUSTIFICACION_OBSERVADOS` a `10_configuracion.R`

- **Descripción:** la constante vive en `30_procesamiento/33_extraer_asistencia.R:162` y es el catálogo observado de códigos de justificación, es decir una constante metodológica y no una derivada de la corrida.
- **Contexto:** detectada al cerrar P-52; no se movió en el encargo P-48 por instrucción explícita, para no ensuciar el diff del cambio de contrato.
- **Tipo:** deuda técnica. **Impacto:** bajo. **Dependencias:** ninguna. **Complejidad:** baja.
- **Principios:** C.11, y POLITICA 5.4 (constantes al inicio y en fuente única).
- **Precauciones:** el `33` es un script del pipeline; el cambio exige regenerar y comprobar que la serie nominal no varía.
- **Criterio de éxito:** la constante vive en `10_configuracion.R`, el `33` la consume desde ahí, y la regeneración da 0 diferencias sobre los 155 perfiles.

#### P-58 — Resolver los dos PRs abiertos

- **Descripción:** el PR #4 (retiro del contrato) y el PR #3 del bot (`refresh/2026-08-03`) tocan los mismos 310 archivos de datos y conflictan en ambos órdenes.
- **Contexto:** medido en esta sesión. El conflicto es de **un solo hunk por archivo** y ese hunk es `metadatos.generado` en 310 de 310. Los dos órdenes producen el mismo resultado salvo cuál timestamp gana.
- **Tipo:** bloqueante de publicación. **Impacto:** alto (es lo que decide qué se publica). **Complejidad:** baja si se respeta A55, alta si se resuelve mal.
- **Precauciones:** **A55 es la precaución**. Resolver a nivel de archivo resucita el contrato legacy en 310 de 310.
- **Criterio de éxito:** `main` con el contrato retirado, `corte_fecha = 2026-08-03` en los 310 perfiles, 0 campos legacy, y el índice coherente con los perfiles.

#### P-59 — Gatillo del invariante de entorno (locale UTF-8), SETTINGS §1.2.2 paso 4ter

- **Descripción:** no existe `50_documentacion/activa/50_locale_utf8.md`, así que el pendiente de POLITICA v5.6 §5.2bis está vigente en este proyecto: la locale UTF-8 debe quedar garantizada por una guarda de arranque.
- **Contexto:** el gatillo es nuevo en SETTINGS v16 y la apertura de esta sesión **no lo declaró**, porque el asistente leyó versiones desactualizadas del protocolo (§15, error 1). Este proyecto ya sufrió el defecto que la norma ataca: bajo `LC_CTYPE=C`, R escapa los literales no ASCII al parsear scripts y produce archivos UTF-8 válidos con contenido escapado, donde `validUTF8()` devuelve TRUE y solo el conteo de bytes revela la corrupción.
- **Tipo:** deuda de infraestructura. **Impacto:** alto si se materializa; silencioso hasta entonces. **Complejidad:** baja.
- **Precauciones:** el helper se copia **idéntico** desde `herramientas_dev/plantillas/10_locale.R` y no se edita por proyecto. La norma prohíbe explícitamente envolver `Sys.setlocale()` en `try(..., silent = TRUE)` o `suppressWarnings()`. La evidencia del gatillo es que la guarda esté **instalada** (`grep -rl asegurar_locale_utf8 10_utils | wc -l`), no que exista un archivo de configuración: medir el proxy en vez del riesgo es PAT-13.
- **Criterio de éxito:** la guarda instalada en el punto de arranque, el marcador depositado, y el `grep` devolviendo al menos 1.

#### P-60 — Ordenación del repositorio (SETTINGS §4.7, gatillo 4bis)

- **Descripción:** no existe `50_documentacion/activa/50_ordenacion_repositorio.md`; el pendiente sigue vigente. Cubre el prefijo `50_` en `activa/`, los encargos de Senado mal ubicados y la exclusión de árboles de terceros en el escáner.
- **Contexto:** declarado en la apertura de esta sesión y diferido por decisión de foco. La parte de traspasos (regla 1.3.1) **ya no forma parte de este pendiente**: se ejecuta en este cierre.
- **Tipo:** deuda de estructura. **Impacto:** medio. **Complejidad:** media (mueve muchos archivos).
- **Precauciones:** protocolo de dos fases; la fase 2 no se lanza sin aprobación explícita del encargo producido en la fase 1. Precondiciones bloqueantes de §4.7.1, rama propia, termina en PR y nunca en merge.
- **Criterio de éxito:** el marcador depositado y el árbol conforme a POLITICA v5.6 §2.

#### P-61 — Auditoría de fuentes Cámara y Senado (encargo redactado, sin ejecutar)

- **Descripción:** inventariar lo que expone la API de la Cámara (8 operaciones consumidas de ~49), auditar el backend del Senado, resolver si P2 tiene respuesta en alguna operación no usada, y emitir veredicto sobre si el contrato simétrico D2 es construible para el Senado, con plan de construcción.
- **Contexto:** el encargo está escrito en `50_documentacion/andamios/50_encargo_auditoria_fuentes_camara_senado.md`, en formato Ultracode (meta, invariantes, contrato de salida y criterios contrastables, sin fases prescritas). **No se ejecutó.**
- **Tipo:** bloqueante del pipeline del Senado. **Impacto:** el más alto de la cartera de pendientes. **Complejidad:** media, riesgo bajo (solo lectura).
- **Precauciones:** máximo 4 agentes concurrentes en cualquier fase que golpee la red; `20_insumos/camara/` no se toca y la exploración va a `20_insumos/exploracion/<AAAAMMDD>/`; `senadores_vigentes.php` no se usa como padrón.
- **Criterio de éxito:** los nueve criterios contrastables de §5 del encargo, con el veredicto sobre D2 en una de las tres formas cerradas.

#### Pendientes heredados sin cambio

**P2** (semántica reglamentaria de `RebajaAsistencia` / `RebajaQuorum`; sigue abierto y sus campos siguen fuera de toda fórmula y de todo conteo), **P-49**, **P-50**, **P-51**, **P-53** y **P-54**: sin cambio respecto de v14 §11, que sigue siendo su fuente. P-54 (respuesta estructural a PAT-01) **gana peso**: esta sesión aportó tres ocurrencias nuevas del mismo mecanismo, todas del asistente.

#### Pendientes cerrados en esta sesión

**P-48** (retiro del contrato legacy, ejecutado y en PR), **P-52** (auditoría de apertura #3, conforme, con P-57 abierto como derivado), **P-55** (configuración local ignorada), **P-56** (`+0` clasificado como real).

### 11.2 Evaluación de deuda técnica

- **Zona frágil que mejoró:** el contrato de asistencia. Tenía dos granularidades vivas, una de ellas sin consumidores, y ahora tiene una. La descarga duplicada desapareció.
- **Zona frágil que persiste:** la **frontera entre el bot y el trabajo manual**. El bot corre los lunes y produce PRs que tocan los mismos 310 archivos que cualquier cambio de contrato. P-22 (sesión 13) resolvió la colisión de escritura, pero no la de contenido: dos PRs simultáneos sobre los mismos datos siguen exigiendo resolución manual informada.
- **Oportunidad de mejora:** un arnés de regresión que verifique las invariantes del contrato publicado en cada corrida (las mismas cuatro afirmaciones que el panel adversarial re-derivó en esta sesión) convertiría en gate automático lo que hoy es verificación puntual por encargo. Es la respuesta estructural a P-54.

### 11.3 Auditoría de cierre (POLITICA 5.6)

| # | Pregunta | Respuesta |
|---|---|---|
| 1 | ¿Datos crudos aislados e inmutables? | **Sí.** Los `.rds` de `asistencia_long` quedaron en `20_insumos/camara/` pese a dejar de usarse |
| 2 | ¿El pipeline corre de cero sin intervención manual? | **Sí.** Dos corridas completas en la sesión |
| 3 | ¿Paquetes, rutas y constantes al inicio de cada script? | **Sí**, con un hallazgo abierto (P-57). 11 scripts, cero rutas absolutas escritas a mano |
| 4 | ¿La estructura respeta la política vigente? | **No.** Cinco desviaciones en §10; la de traspasos se corrige en este cierre, las demás van a P-60 |
| 5 | ¿Todo cambio quedó verificado contra un criterio declarado antes? | **Sí**, salvo el criterio de la Fase 1, que era inalcanzable por construcción (A54) |
| 6 | ¿Queda algún artefacto sin versionar? | **Sí.** Tres andamios de esta sesión; se versionan en este cierre |
| 7 | ¿Nombres sin tildes, ñ ni espacios? | **Sí**, con la excepción permanente declarada |
| 8 | ¿El invariante de entorno está garantizado? | **No.** P-59 |

### 11.4 Ruta sugerida para la sesión 16

**Prioridad 1 — P-58, resolver los dos PRs.** Es lo único que separa el trabajo hecho de la producción, y es el pendiente con mayor costo si se hace mal. Criterio de éxito en su ficha. Bloqueante por definición (criterio 2 de 1.2.4).

**Prioridad 2 — P-61, auditoría de fuentes.** El encargo ya está escrito y es de solo lectura, así que puede lanzarse apenas los PRs estén resueltos. Es el pendiente que desbloquea el proyecto entero. Criterio 6 de 1.2.4 (alta complejidad al inicio, con más contexto).

**Prioridad 3 — P-59, gatillo de locale.** Barato, y este proyecto ya sufrió el defecto que ataca. Criterio 3 de 1.2.4 (instrucción explícita del protocolo).

**Prioridad 4 — P-57**, si sobra sesión: es un cambio de una constante con regeneración y comparación.

**Diferir:** P-60 (mueve muchos archivos, merece sesión propia y no compite bien con la auditoría), P-49, P-50, P-51, P-53, P2. **P-54** conviene abordarlo como sesión BIBLIOTECA de cartera, no aquí.

---

## 12. Instrucciones específicas para la próxima sesión

- ⚠️ **NO** resolver el conflicto entre el PR #4 y el PR #3 a nivel de archivo (`git checkout --ours` / `--theirs`, `git checkout <rama> -- <ruta>`): resucita el contrato legacy en 310 de 310 perfiles y deja el índice incoherente. **Se resuelve por hunk** (A55).
- ⚠️ **NO** afirmar el estado de `CORTE_FECHA` sin leer `10_utils/10_configuracion.R`: el bot lo reescribe en cada corrida y cada merge de PR lo cambia en `main`.
- ⚠️ **NO** mergear un PR del bot sin leer el resumen de conteos de su cuerpo: el gate detecta caídas de volumen, no cambios de sentido.
- ⚠️ **NO** usar `gh pr diff --name-only` sobre PRs de este proyecto (A45): devuelve 406 sobre PRs grandes y deja el check contando sobre vacío. Usar la API paginada de `/pulls/<n>/files` y declarar el denominador.
- ⚠️ **NO** correr un `grep` de verificación con metacaracteres sin `-F` (A57): un vacío por patrón es indistinguible de un vacío por ausencia.
- ⚠️ **NO** disparar el workflow por `workflow_dispatch` para comprobar algo que se puede leer por API o en los intermedios ya descargados: cada corrida cuesta ~11 minutos y golpea la API de la Cámara.
- ⚠️ **NO** emitir un subcomando `gh pr` sin `-R tomgc/transparencia_legislativa_chile` (A51), ni un comando de git sin `git -C <ruta absoluta>`. `gh api` es la excepción: el repositorio va en el endpoint, no en `-R`.
- ⚠️ **NO** verificar las versiones del protocolo contra ninguna fuente que no sea la knowledge base del Project (§15, error 1).
- ✅ **ANTES** de cualquier corrida local, regenerar 32-36 (A34).
- ✅ **ANTES** de escribir un criterio de éxito que compare artefactos regenerados, declarar en el mismo enunciado qué campos son volátiles (A54).
- ✅ **ANTES** de publicar una cifra, declarar qué mide y de qué artefacto sale, no la familia de su fuente (A56, D22).
- ✅ **ANTES** de repuntar un consumidor a un campo nuevo, verificar la correspondencia sobre el universo completo y declarar el denominador (A53).
- ✅ **ANTES** de dar por entregado un artefacto, comprobar que quedó adjunto en el mismo turno que lo anuncia (A52).
- ✅ **ANTES** de escribir una glosa que interprete una cifra, atarla al predicado que la hace verdadera y probar el caso vacío (A50).
- ✅ **ANTES** de tocar el workflow, leer el archivo completo: es el único mecanismo automático que escribe hacia producción.
- 🔒 El gate de conteos aborta el job sin publicar rama ni PR. Intocable.
- 🔒 El commit condicional: sin cambios, sin rama y sin PR. Intocable.
- 🔒 `main` no recibe escrituras automáticas del bot. El `--force` del workflow vive acotado por refspec a `refresh/*`.
- 🔒 `sin_registro` no se imputa: ni en el dato ni en la presentación.
- 🔒 Las rebajas se publican y quedan fuera de toda fórmula y de todo conteo mientras P2 siga abierta.
- 🔒 Territorio como insumo estático auditado. El backlog nunca se renumera.
- 🔒 El titular de asistencia del portal es `periodo_vigente.tasa_presencia` (D18). Cambiarlo es rehacer P7.
- 🔒 R es el único lenguaje, en todos los contextos, incluida la inspección auxiliar. Sin `jq`, `awk`, `python`, ni `grep`/`sed` sobre artefactos de datos.
- 🔒 `git add` siempre con ruta acotada. Nunca `git add .` ni `git add -A`.

---

## 13. Fragmentos de código de referencia

**Patrón nuevo de esta sesión: resolución de un conflicto de datos por hunk, con medición previa.** Ejecutable tal cual, en R, sobre el resultado de una simulación de merge. Mide antes de decidir; si algún archivo tiene más de un hunk, se detiene.

```r
# Medir la forma del conflicto ANTES de resolverlo (A55).
# Insumo: vector de rutas en conflicto, ya obtenido de git.
medir_conflicto <- function(rutas) {
  purrr::map_dfr(rutas, function(r) {
    lineas <- readLines(r, warn = FALSE)
    inicio <- grep("^<<<<<<<", lineas)
    data.frame(
      ruta    = r,
      n_hunks = length(inicio),
      # Un hunk aislado de timestamp es seguro de resolver por hunk;
      # cualquier otra cosa exige mirar el contenido.
      solo_generado = length(inicio) == 1L &&
        any(grepl("\"generado\"", lineas[inicio[1]:length(lineas)])),
      stringsAsFactors = FALSE
    )
  })
}

resumen <- medir_conflicto(rutas_en_conflicto)
stopifnot(all(resumen$n_hunks == 1L), all(resumen$solo_generado))
# Si el stopifnot falla, NO se resuelve por hunk a ciegas: se inspecciona.
```

Los patrones estables del proyecto viven en `50_documentacion/activa/documentacion_tecnica_v1.md` y en `CLAUDE.md`; este traspaso no los recopia.

---

## 14. Reapertura

### Mensaje de apertura pre-armado

> Tipo: CONTINUATION. El protocolo (`POLITICA_PROYECTO.md` v5.6, `SETTINGS_Y_PROMPTS_OPERACIONALES.md` v16) vive en la knowledge base del Project y se lee desde ahí; verifica las versiones **contra la knowledge base**, no contra ninguna otra fuente, antes de la Fase A. Estado: las tres capas en producción, el contrato legacy de asistencia retirado y esperando merge en el PR #4, sin bugs activos. Hay **dos PRs abiertos que tocan los mismos 310 archivos de datos** y conflictan en ambos órdenes: el conflicto es de un solo hunk (`metadatos.generado`) y resolverlo a nivel de archivo resucita el contrato legacy, así que el foco propuesto es P-58, resolverlos por hunk. Encadenado: P-61, la auditoría de fuentes Cámara/Senado, cuyo encargo ya está escrito en `50_documentacion/andamios/50_encargo_auditoria_fuentes_camara_senado.md` y solo hay que lanzar. Dos gatillos de protocolo están encendidos: 4bis (ordenación, P-60) y 4ter (locale UTF-8, P-59). `CORTE_FECHA` cambia con cada merge de PR del bot, así que confírmalo en `10_utils/10_configuracion.R` antes de afirmarlo. Adjunto: `traspaso_cierre_v15.md`, `estructura_actual.md`.

### Documentos para la sesión 16

1. **Protocolo (knowledge base, NO adjuntar, solo verificar que esté al día):** `POLITICA_PROYECTO.md` v5.6, `SETTINGS_Y_PROMPTS_OPERACIONALES.md` v16.
2. **Opcionales según el foco real:** `CLAUDE.md` si el trabajo corre en Claude Code; `10_utils/10_configuracion.R` para el valor vigente de `CORTE_FECHA`; `backlog_acumulativo.md` si se aborda P-51 o cualquier análisis de patrones; `50_encargo_auditoria_fuentes_camara_senado.md` si se lanza P-61 (vive en el repo, no hace falta adjuntarlo si Claude Code lo lee); `33_extraer_asistencia.R` y `10_configuracion.R` si se aborda P-57; `prompt_ordenacion_repositorio_v1.md` si se aborda P-60.
3. **Sí se adjuntan:** `traspaso_cierre_v15.md`; `estructura_actual.md`.

**Nota:** si `10_utils/10_configuracion.R` cambió por el merge de algún PR, adjuntar la versión actualizada y avisarlo en el mensaje de apertura.

---

## 15. Errores del asistente

Tres errores registrados, todos del mismo mecanismo.

### Error 1 — Versiones del protocolo afirmadas desde una fuente secundaria

| Campo | Contenido |
|---|---|
| `momento` | Fase A de la apertura, y de nuevo al final de la sesión, al afirmar que `POLITICA_PROYECTO.md` había desaparecido de la knowledge base |
| `disparador` | Usuario lo corrigió ("de que hablas, la kb esta llena de archivos") |
| `que_paso` | El asistente declaró que el protocolo estaba en v5.5/v14 y después que uno de los dos documentos no existía, leyendo un montaje de archivos del contenedor en vez de la knowledge base del Project; las versiones reales son v5.6 y v16 |
| `regla_violada` | POLITICA 0.6 (marcador de fuente en línea: la fuente debe ser el artefacto autoritativo) y SETTINGS 1.2.2 punto 3 (verificar la versión vigente **en la knowledge base**) |
| `causa_raiz` | El montaje del contenedor ofrecía los mismos nombres de archivo y respondía a `grep`, así que pasó por fuente primaria sin serlo. El asistente confundió *fuente legible* con *fuente autoritativa*, y no volvió a comprobar cuando el resultado (un documento maestro ausente) era en sí mismo inverosímil |
| `salvaguarda_presente` | POLITICA + SETTINGS + userPreferences (marcador de fuente) |
| `patron` | PAT-01, sobre fuente autoritativa: afirmar un valor verificable desde un espejo del artefacto en vez del artefacto |
| `gatillo_observable` | `afirmar-sin-leer`: se afirmó la versión de un documento de la knowledge base sin haber invocado la herramienta que lee la knowledge base en ese turno |
| `intentos_previos` | 0 en la apertura; 1 al final (la primera comprobación, sobre el montaje, ya había dado un resultado inverosímil y no se contrastó) |
| `costo` | Dos gatillos de protocolo no declarados en la apertura (4bis quedó declarado por otra vía, 4ter no se declaró en absoluto), un turno de corrección del usuario, y una afirmación falsa sobre la knowledge base |

### Error 2 — Destino de los encargos afirmado sin leer la regla

| Campo | Contenido |
|---|---|
| `momento` | Al entregar los dos encargos, P-48 y auditoría de fuentes |
| `disparador` | Usuario lo corrigió ("esto va a andamios no activa. no sabes?") |
| `que_paso` | Ambos encargos se rutearon a `50_documentacion/activa/` cuando SETTINGS §4.7.3 punto 1 sitúa el encargo previo en `50_documentacion/andamios/`, y §4.7.2 declara `andamios/` congelado |
| `regla_violada` | SETTINGS §4.7.3 punto 1; POLITICA 1.3 punto 7 (documentación bifurcada) |
| `causa_raiz` | El asistente clasificó el encargo por su parecido superficial con documentación de referencia en vez de por su ciclo de vida (se ejecuta una vez y queda como evidencia). La regla existía y no se consultó porque el destino no se percibió como una afirmación verificable |
| `salvaguarda_presente` | SETTINGS + POLITICA |
| `patron` | PAT-01, sobre destino de artefacto |
| `gatillo_observable` | `entrega-sin-destino-o-nombre`: se declaró la ruta de destino de un artefacto nuevo sin leer la sección que la norma |
| `intentos_previos` | 0. Ocurrió dos veces seguidas antes de la corrección, con el mismo mecanismo |
| `costo` | Un turno de corrección; un encargo ya lanzado con la ruta equivocada, que Claude Code resolvió buscando el archivo antes de concluir su ausencia |

### Error 3 — Criterio de éxito inalcanzable en el encargo P-48

| Campo | Contenido |
|---|---|
| `momento` | Redacción de la Fase 1 del encargo P-48 |
| `disparador` | Claude Code lo señaló en su log (§6.1) sin nombrarlo error del asistente |
| `que_paso` | La Fase 1.3 exigía `git status --porcelain` vacío tras regenerar y declaraba cualquier diferencia como "hallazgo mayor", cuando `metadatos.generado` garantiza que nunca puede quedar vacío |
| `regla_violada` | POLITICA B.4 (criterio de éxito verificable declarado antes de codificar); el propio encargo, cuya Fase 2.3 ya excluía el campo volátil |
| `causa_raiz` | El asistente escribió el gate de la Fase 1 antes que el de la Fase 2 y no releyó el primero a la luz del segundo. La exclusión del campo volátil se descubrió al redactar la comparación fina y no se propagó hacia atrás |
| `salvaguarda_presente` | POLITICA (B.4) + `encargo_autonomo_claude_code_v1.md` §2.5 |
| `patron` | PAT-01, en su variante de premisa de encargo: se enunció una condición verificable sin comprobar que fuera satisfacible |
| `gatillo_observable` | `encargos-premisas`: se declaró un criterio de éxito sobre un artefacto sin comprobar que el artefacto pudiera satisfacerlo |
| `intentos_previos` | 0 |
| `costo` | Una fase detenida a mitad de ejecución y un diagnóstico no planificado; sin daño al producto, porque el ejecutor midió antes de continuar |

### Fricciones

- `friccion: se afirmó que el modo Ultracode no existía, buscando "modos de Claude Code" en vez del término que el usuario usó → se corrigió con búsqueda del término literal y se rediseñó el encargo siguiente en formato Ultracode.`
- `friccion: el encargo de medición del PR #3 preguntaba a nivel de archivo ("¿reaparecen los campos?") cuando la unidad correcta era el hunk → la primera pasada dio una respuesta parcialmente errónea que el panel adversarial tuvo que voltear.`
