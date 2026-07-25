# Traspaso de cierre — v10

## 1. Identificación

- **Proyecto:** `transparencia_legislativa_chile`
- **Versión:** v10
- **Fecha:** 2026-07-25
- **Sesión:** 10. Foco: **Capa 2 (territorio)**. Medir la fuente territorial (D5/A28) y, con veredicto favorable, construir el crosswalk distrito↔diputado para poblar `distrito`/`region` en los 155 perfiles. Cierra el `# REVISAR` que el `32` arrastraba desde la sesión 1.
- **Entorno:** R 4.5.2 / Positron (macOS). Claude Code para ejecución autónoma. Repo público (Rama A). Producción: `https://tomgc.github.io/transparencia_legislativa_chile/`.
- **Archivos principales modificados:** `30_procesamiento/32_extraer_diputados.R` (join territorial reemplaza los `NA_character_`); nuevos insumos `20_insumos/territorio/{20260724_crosswalk_distrito_diputado.csv, catalogo_distrito_region.csv}`; `50_documentacion/andamios/medir_fuente_territorio.R` (andamio promovido a generador del insumo); `docs/index.html` (fix de copy/UI de territorio, **en curso al momento de redactar este traspaso**); JSON regenerados en `40_salidas/json/` y `docs/data/`. `39_consolidar_json.R` NO se tocó (solo propaga).

## 2. Resumen ejecutivo

Sesión de feature que completa la promesa territorial del portal. Abrió con la disciplina de D5/A28: medir la fuente antes de diseñar. La medición (encargo de solo lectura, rama `feat/territorio-crosswalk`) refutó el supuesto central S4/A28: BCN publica `bcn-biographies#idCamaraDeDiputados`, que es literalmente el `diputado_id` de la Cámara, de modo que el cruce es determinista por id (155/155), no por nombre. Con veredicto favorable, la construcción generó dos insumos estáticos versionados (crosswalk `diputado_id→distrito` de 155 filas con la regla de desambiguación de 4 ids colisionados materializada, y catálogo `distrito→region` de 28 filas contra la ley electoral), insertó dos `left_join` en el `32` con validación ruidosa, promovió el andamio de medición a generador reproducible del insumo (no a etapa del pipeline semanal), y regeneró los JSON al corte vigente 2026-07-20. Resultado verificado y auditado por panel adversarial (4/4): 155/155 con distrito y región no-NA, suma de escaños 155, 28 distritos, 16 regiones. Se corrigió durante la construcción un bug de encoding transversal (literales no-ASCII escapados bajo `LC_CTYPE=C`, invisible a `validUTF8()`). Emergió un error propio del asistente (afirmé en el encargo que Carter=distrito 20; es 12; octava variante de A21). Al cierre corre un encargo final de ajuste de copy/UI del frontend (el mensaje L778 y la opción "Sin dato" del filtro quedaron obsoletos al poblar territorio). Todo local, sin push: el merge a `main` es gate del titular.

## 3. Estado al cierre

**Qué funciona:**
- Rama `feat/territorio-crosswalk` con la Capa 2 construida y verificada: `distrito`/`region` poblados 155/155 en índice y perfiles del JSON publicado.
- Insumo territorial estático auditado en `20_insumos/territorio/` (crosswalk 155 + catálogo 28).
- `32` puebla territorio por join con validación ruidosa (`stop()` nombrando el `diputado_id` si un reemplazo futuro no está cubierto; valida rango 1–28, duplicados, cobertura de región).
- Andamio `medir_fuente_territorio.R` promovido a generador del insumo (fase `gen`, a mano, NO es etapa de `00_run_all`).
- Panel adversarial 4/4 sin discrepancias.
- `main` == `origin/main` == `720f4ff` (refresh del bot del 2026-07-20, integrado esta sesión por fast-forward).

**Qué no funciona / pendiente:**
- Nada roto. El único trabajo abierto es el **encargo de fix de copy/UI del frontend** (`docs/index.html`), en curso al redactar. Debe verificarse su reporte (0 ocurrencias de `__sindato__`, copy de territorio actualizado, fallback de perfil conservado) y su commit `fix:` en la rama ANTES del merge.
- La rama NO está mergeada a `main` ni pusheada: es el gate del titular tras revisión visual.

**Delta respecto a v09:**
- `CORTE_FECHA` avanzó 2026-07-13 → **2026-07-20** (refresh del bot del lunes 20, integrado por fast-forward; conteos crecieron sin caídas: votaciones +3875, mociones +124).
- Territorio: de 0/155 a 155/155 con distrito y región.
- Nueva carpeta de insumo `20_insumos/territorio/`.
- Rama `feat/territorio-crosswalk` viva con 4-5 commits locales (medición + 3 de construcción + log + CLAUDE.md + fix de copy pendiente).

## 4. Registro detallado de cambios

**Cambio 1 — Integrar el refresh del bot del 2026-07-20 (fast-forward).** Categoría: git/integración. Al abrir, `fetch` mostró `origin/main` en `720f4ff` (autor `github-actions[bot]`), divergencia `1 0`: un commit remoto, cero locales. Se leyó el commit (`log -1 --stat`): refresh del corte 2026-07-20, toca `10_configuracion.R`, los 5 `.rds` de `20_insumos/camara/` y los 310 JSON. Fast-forward limpio (`merge --ff-only`). `CORTE_FECHA` leído de `10_configuracion.R` = 2026-07-20 (A21). Sin conflicto posible (nada local por delante).

**Cambio 2 — Versionar el cierre de la sesión 9 (residuo).** Categoría: documentación/git. Commit `9816532` (`docs:`). Al abrir, el working tree tenía sin commitear el traspaso v09, el escáner del 16-jul, la poda del snapshot `20260711_*` y `ESTADO.md` (residuo del cierre de la s9, que generó el traspaso pero no lo commiteó). Se versionó path-scoped a `50_documentacion/`. Git detectó el par de renames de la poda. Pusheado (`b707c51..9816532`). Este commit precede al refresh del bot en la historia local, pero como el bot ya estaba en `origin`, el fast-forward del Cambio 1 lo dejó por debajo.

**Cambio 3 — Medición de la fuente territorial (encargo de solo lectura).** Categoría: diagnóstico/exploración. Rama `feat/territorio-crosswalk`, commit `efb479e`. Veredicto en `50_documentacion/andamios/20260724_medicion_fuente_territorio.md`. Refutó S4: BCN expone `idCamaraDeDiputados` = `diputado_id`, cobertura 155/155, cruce determinista por id. Territorio NO está en el grafo RDF (38+23 tripletas vestigiales en nodos huérfanos; join SPARQL da 0 filas) pero sí en la ficha HTML "Reseñas parlamentarias". 4 ids colisionados (1159, 1175, 1209, 1252: histórico+vigente comparten id) desambiguados por período vigente. SERVEL descartado (Power BI embebido, no reproducible). Hallazgo lateral: la API de la Cámara expone RUT (llave nacional hoy sin uso).

**Cambio 4 — Insumo territorial estático (D5).** Categoría: infraestructura/datos. Commit `0f93cb5` (`feat:`). Dos CSV en `20_insumos/territorio/`: `20260724_crosswalk_distrito_diputado.csv` (155 filas: `diputado_id` character, `distrito` integer 1–28, `bcn_persona_id`, `capturado_el`, `fuente`; regla de desambiguación materializada en las filas y documentada en cabecera) y `catalogo_distrito_region.csv` (28 filas contra la Ley 20.840, con Ñuble en el D19 por Ley 21.033). Se congela y audita en vez de scrapear cada refresh, porque la ficha BCN es HTML sin contrato de datos (escribe el ordinal en tres formas: `13er`, `4°` U+00B0, `24º` U+00BA).

**Cambio 5 — Join territorial en el `32`.** Categoría: extracción/consolidación. Commit `a03be0a` (`feat:`). Reemplaza `distrito = NA_character_` / `region = NA_character_` (L63-65) por dos `left_join`: por `diputado_id` (character) contra el crosswalk, por `distrito` (integer) contra el catálogo. Validación ruidosa (C.8): `stop()` con el `diputado_id` culpable si un reemplazo no está cubierto; valida rango, duplicados, cobertura de región. Territorio nunca degrada a NA en silencio ni se fabrica. Cierra el `# REVISAR` de la entrada de sesión 1. `39` no se tocó.

**Cambio 6 — Andamio promovido a generador del insumo.** Categoría: refactor/documentación. Commit `8c0ba3a` (`refactor:`). `medir_fuente_territorio.R` gana una fase `gen` que regenera el CSV del crosswalk de forma reproducible (SPARQL + parseo de ficha + regla de desambiguación) dado el índice vigente. Cabecera documenta: generador del insumo, correr a mano cuando cambie el roster, NO es etapa de `00_run_all`. No conectado a `39` ni al orquestador.

**Cambio 7 — Bug de encoding corregido durante la construcción.** Categoría: bugfix. El catálogo salió con `Región de Ñuble` escapado como texto literal (`Regi<c3><b3>n de <c3><91>uble`, 29 chars ASCII en vez de 15). Causa raíz: bajo `LC_CTYPE=C`, R convierte los literales no-ASCII del propio script a forma escapada al parsear; el archivo era "UTF-8 válido" (`validUTF8()` daba TRUE) pero su contenido era el de los escapes. Corrección doble: el generador corre bajo `LC_ALL=en_US.UTF-8`, y el `32` marca `Encoding()<-"UTF-8"` en las columnas de texto leídas del CSV (no-op en Positron, blinda en CI). Sin esto, el pipeline sería correcto en Positron y roto en CI.

**Cambio 8 — Regeneración al corte vigente (A34).** Categoría: pipeline. Los intermedios locales estaban sellados a 2026-07-10 contra `CORTE_FECHA`=2026-07-20; la compuerta `validar_corte()` habría fallado. Se corrió `run_all(from=32)`: los 5 cachés del corte vigente ya estaban locales, así que 32–36 resolvieron por cache hit (sin llamadas a la API) y `39` validó procedencia antes de consolidar. JSON regenerados en `40_salidas/json/` y `docs/data/`.

**Cambio 9 (EN CURSO) — Fix de copy/UI del frontend.** Categoría: interfaz. Encargo corriendo al cierre. Al poblar territorio, quedaron obsoletos: el mensaje de estado vacío (L778, "aún no está disponible en la fuente"), la opción "Sin dato" del filtro de región (L581/L619, ahora rama inalcanzable) y comentarios internos (L313-321, L708). El fix reescribe el mensaje, elimina la opción "Sin dato" y su lógica `__sindato__`, actualiza comentarios y conserva el fallback defensivo de perfil (L720/L731). Commit `fix:` esperado en la misma rama. **Verificar su reporte antes del merge.**

## 5. Backlog acumulativo

Vive en `50_documentacion/activa/backlog_acumulativo.md`. **Estado detectado esta sesión:** el archivo canónico está cerrado en v06 (23 entradas). Las entradas 24-26 de la sesión 7 viven en `backlog_entradas_sesion_7.md` (archivo aparte) y NO están fusionadas al canónico; las sesiones 8-9 tampoco están consolidadas. **Delta de la sesión 10:** la Capa 2 es un cambio de producto en el sentido de la nota metodológica (solicitud distinguible del titular que altera el artefacto: territorio poblado). Corresponde una entrada nueva de la sesión 10 ("Capa 2 territorio: crosswalk BCN determinista por id, 155/155 poblados"). **Pendiente de consolidación (P-nuevo):** fusionar 24-26 (s7) + s8 + s9 (higiene, 0 cambios) + s10 (Capa 2) al canónico, con numeración correlativa global continuada, y actualizar la clasificación temática y el resumen por sesión. No se hizo esta sesión por foco; queda como deuda de memoria documentada.

## 6. Bugs de la sesión

- **Bug de encoding del catálogo** (resuelto): ver §4 Cambio 7. Síntoma: `Región de Ñuble` como texto escapado. Causa raíz: literales no-ASCII escapados por R bajo `LC_CTYPE=C` al parsear el script. Fix: generador bajo locale UTF-8 + `Encoding()<-` explícito en el `32`. Verificación: `nchar()` vs bytes (15 vs 17), no `validUTF8()`. **Patrón general:** `validUTF8()` sobre el archivo no prueba que el contenido sea el esperado; la comprobación que discrimina es `nchar()` vs bytes. Riesgo latente en TODA la cartera para scripts que escriben literales acentuados corridos en CI.

## 7. Aprendizajes y restricciones descubiertas

- **A35 — El territorio de BCN vive en la ficha HTML, no en el grafo RDF.** Regla: el store RDF de `datos.bcn.cl` modela el territorio (`representing`, `representingPlaceNamed`) pero la carga está vacía/vestigial (38+23 tripletas en nodos huérfanos que la persona no enlaza). El dato consultable está en la ficha "Reseñas parlamentarias" (HTML). El SPARQL sirve para la LLAVE (`idCamaraDeDiputados` + `bcnPage`), no para el dato territorial. Contexto: un join SPARQL persona→cargo→representing da 0 filas. Principio: C.8 (medir la fuente real).
- **A36 — `validUTF8()` no discrimina contenido escapado.** Regla: un archivo puede ser UTF-8 válido y contener el texto de los escapes (`<c3><b3>`) en vez de los caracteres. La prueba que discrimina es `nchar()` (caracteres) vs longitud en bytes. Contexto: bajo `LC_CTYPE=C` R escapa literales no-ASCII del script al parsear; el archivo escrito es válido pero incorrecto. Corolario operativo: scripts que escriben literales acentuados deben correr bajo locale UTF-8 y marcar `Encoding()<-"UTF-8"` en la lectura aguas abajo. **Transversal a la cartera; candidato a POLITICA.** Principio: C.7 (portabilidad, UTF-8 explícito).
- **A37 — BCN reutiliza `idCamaraDeDiputados` entre persona histórica y vigente.** Regla: 4 ids (1159, 1175, 1209, 1252) apuntan a dos personas distintas en BCN; se desambigua deterministamente por fila del período vigente en la "Trayectoria Parlamentaria" (la histórica no la tiene; la de 1175 da HTTP 404). Contexto: deduplicar por conveniencia (`!duplicated()`) pierde justamente a la persona correcta. Principio: C.8, B.1.

## 8. Decisiones de diseño

- **D5 aplicada — Territorio como insumo estático versionado, no scraping recurrente.** Alternativas: (a) consultar BCN en cada refresh semanal; (b) congelar el mapeo en un CSV auditado y regenerarlo a mano cuando cambie el roster. Elegida (b). Justificación: la ficha BCN es HTML sin contrato de datos (tres formas de ordinal ya observadas); un cambio de plantilla rompería el refresh en silencio. Implicancia: un reemplazo dentro del período hace fallar ruidosamente el `32` (con el `diputado_id`), y la corrección es correr la fase `gen` del andamio y revisar el diff del CSV.
- **Llave del crosswalk = `diputado_id`, no RUT.** Aunque la Cámara expone RUT (llave nacional), la medición probó `idCamaraDeDiputados` = `diputado_id` con cobertura 155/155. Se mantuvo `diputado_id` para no agrandar el alcance. El RUT queda anotado como vía natural para el crosswalk Cámara↔Senado (donde la identidad cross-fuente es el problema central, entrada 22).
- **`distrito` como `integer` en el JSON.** El frontend ya coercía con `String(r.distrito)`. El invariante de llaves-character aplica a llaves de join, no a `distrito` (atributo). Funciona en ambos casos.
- **Opción "Sin dato" eliminada del filtro de región (Cambio 9).** La validación ruidosa del `32` garantiza que nunca se publica un diputado sin territorio, así que "Sin dato" es rama inalcanzable; dejarla es UI muerta. El fallback defensivo de las celdas de perfil sí se conserva (barato, buena higiene).

## 9. Constantes y parámetros vigentes

| Constante | Valor | Archivo | Nota |
|---|---|---|---|
| `CORTE_FECHA` | **2026-07-20** | `10_utils/10_configuracion.R` | AVANZÓ desde v09 (2026-07-13). Refresh del bot del lunes 20, integrado por fast-forward. Fuente canónica: el archivo (A21). |
| Crosswalk territorial | 155 filas, `diputado_id→distrito` | `20_insumos/territorio/20260724_crosswalk_distrito_diputado.csv` | Insumo estático auditado (D5). Regla de desambiguación de 4 ids en las filas + cabecera. |
| Catálogo distrito→región | 28 filas | `20_insumos/territorio/catalogo_distrito_region.csv` | Contra Ley 20.840 + Ley 21.033 (Ñuble D19). |
| Territorio publicado | 155/155 distrito + región | JSON en `docs/data/` | 28 distritos, 16 regiones, suma escaños 155, magnitudes 3–8. |
| `LIMITE_COLAPSADO` | 16 | `docs/index.html` | Capa 1. Sin cambios. |

## 10. Arquitectura de archivos

Escáner al cierre: `50_documentacion/estructura/estructura_actual.md`, fechado 2026-07-25 06:15:05 (23 carpetas, 436 archivos). Nueva carpeta `20_insumos/territorio/` con los dos CSV. Andamios nuevos: `20260724_capa2_territorio_log.md`, `20260724_medicion_fuente_territorio.md`, `medir_fuente_territorio.R`, y 8 muestras en `andamios/muestras/`. `traspaso_cierre_v09.md` versionado. La estructura respeta la política. **A25:** al cierre el trabajo vive en `feat/territorio-crosswalk`, NO en `main`; confirmar rama con `git -C <raiz> branch --show-current` al abrir la próxima sesión.

**Registro de ejecución detallado:** `50_documentacion/andamios/logs/20260724_capa2_territorio_log.md` (log de la sesión de Claude Code; detalle paso a paso no reproducido aquí).

## 11. Pendientes y ruta sugerida

**Inventario:**

- **Merge de la Capa 2 a `main` — GATE DEL TITULAR, inmediato.** La rama `feat/territorio-crosswalk` tiene la Capa 2 completa y verificada, más el fix de copy (Cambio 9, en curso). Precondiciones antes del merge: (1) verificar el reporte del encargo de copy (0 `__sindato__`, copy de territorio actualizado, fallback conservado, commit `fix:` en la rama); (2) revisión visual del dashboard con preview local (territorio poblado + copy corregido); (3) `git fetch` dentro de la compuerta de divergencia (A32: el bot pudo pushear si es lunes). Merge `--no-ff`, luego push. Criterio de éxito: producción muestra distrito/región reales en los 155 y ningún copy que diga que el territorio no está disponible.
- **Consolidación del backlog — deuda de memoria, media.** Fusionar al canónico `backlog_acumulativo.md` las entradas 24-26 (s7, hoy en archivo aparte), la s8, la s9 (higiene, 0 cambios) y la s10 (Capa 2), con numeración correlativa global continuada y taxonomía/resumen actualizados. Ver §5.
- **Región en reemplazos dentro del período — supuesto no verificado de D5.** Si entra un reemplazante, el `32` falla ruidosamente con su `diputado_id`; la corrección es la fase `gen` del andamio + diff del CSV. Sigue sin verificarse que un reemplazante herede el distrito de quien reemplaza (el flujo va a la fuente, no lo asume).
- **RUT como llave sin uso — hallazgo lateral, para Capa 4.** La API de la Cámara expone RUT/RUTDV, llave nacional inequívoca. Vía natural para cruzar con fuentes futuras (SERVEL, patrimonio) o con el Senado. Anotar en el diseño del contrato Cámara↔Senado (P-13).
- **P-22 (choque cron semanal vs. trabajo manual) — gobernanza de flujo.** El bot pushea a `main` cada lunes; esta sesión volvió a integrarse (fast-forward, sin choque porque no había local por delante). Recomendación: bot en rama + PR. Sesión dedicada.
- **Capa 3 (asistencia simétrica, D2) — siguiente feature.** Reescribir el `33` para persistir asistencia nominal por sesión + fecha + justificación (hoy agrega a tasa y descarta `sesion_id`/fecha; hallazgo (b) de la entrada 22). Prerequisito del contrato simétrico y del Senado. Aplica A34 (regenerar 32-36 antes de tocar).
- **P-9 (crosswalk partido→tendencia del Senado) — paralelizable.** Único ítem de Capa 4 sin dependencia de Capa 3.
- **P-13 (contrato Cámara/Senado), P-7 (pipeline Senado), P-10 (biblioteca histórica) — Capa 4.** En orden de dependencia, tras Capa 3.
- **`# REVISAR` ajenos al territorio:** estado de tramitación de proyectos (`NA`, proxy `admisible`); rol autor/coautor (`Orden=0` para todos los firmantes).
- **Verificación de ramas remotas — administrativo, bajo.** El borrado de las tres ramas de la s9 fue local; confirmar con `git branch -r` si tienen contraparte en `origin`.

**Evaluación de deuda técnica:** la Capa 2 quedó limpia y auditada. La deuda visible es de memoria (backlog sin consolidar desde v06) y de proceso (P-22). El bug de encoding (A36) es deuda latente de toda la cartera, no solo de este proyecto.

**Auditoría de cierre (POLITICA 5.6):**
- #2 (pipeline de cero sin intervención manual): sí; el territorio es insumo estático auditado, regenerable por el andamio.
- #5 (cada transformación crítica con validación): sí; el join del `32` valida cobertura, rango, duplicados y región con `stop()` ruidoso.
- #6 (outputs reproducibles e idempotentes): sí; regenerado al corte 2026-07-20 con sello validado.
- #7 (decisiones metodológicas como constantes/insumos nombrados): sí; crosswalk y catálogo como insumos versionados, no números mágicos.
- #8 (nombres sin tildes/ñ/espacios): sí (el contenido de los CSV lleva tildes/ñ correctas por diseño; los nombres de archivo no).

**Ruta sugerida para la sesión 11:** cerrar el merge de la Capa 2 a `main` (verificar copy → revisión visual → fetch → merge --no-ff → push), consolidar el backlog al canónico, y abrir la Capa 3 (asistencia simétrica) abriendo por la regeneración de intermedios al corte vigente (A34). Diferir P-22 a sesión de gobernanza; el Senado (P-13, P-7) tras la Capa 3.

## 12. Instrucciones específicas para la próxima sesión

- ⚠️ NO mergear la Capa 2 sin antes: verificar el reporte del fix de copy (Cambio 9), hacer revisión visual del dashboard, y `git fetch` dentro de la compuerta (A32).
- ⚠️ NO correr `run_all(only=39)` local sin regenerar 32-36 al corte vigente: `validar_corte()` fallará por diseño (A34).
- ⚠️ NO afirmar un valor territorial concreto (distrito de un diputado, cobertura) sin leerlo del insumo o del JSON: el asistente ya erró Carter=20 (es 12) esta sesión (A21, §15).
- ✅ ANTES de comprometerse con `CORTE_FECHA` en cualquier documento, leerla de `10_configuracion.R` (A21).
- ✅ ANTES de cualquier push, `git fetch origin` dentro de la compuerta de divergencia (A32); el bot corre los lunes.
- ✅ ANTES de escribir literales acentuados desde un script que pueda correr en CI, verificar locale UTF-8 y `Encoding()<-` en la lectura (A36).
- 🔒 R-only en todo contexto (excepto el frontend `docs/index.html`, que es HTML/JS single-file sin CDN por naturaleza desde la sesión 3).
- 🔒 La Cámara en producción (`main`) no se toca sin decisión explícita.
- 🔒 El territorio es insumo estático auditado (D5), NO scraping en cada refresh.
- 🔒 `CORTE_FECHA` sin default silencioso; el sello de procedencia no se rompe.
- 🔒 `distrito`/`region` jamás fabricados: salen del insumo, no de deducción.
- 🔒 La clasificación de tendencia no se altera autónomamente; `IND = NA_character_` es intencional.

## 13. Fragmentos de código de referencia

Regla de desambiguación de los 4 ids colisionados de BCN (materializada en el crosswalk, la forma correcta):

```
# Entre personas BCN que comparten idCamaraDeDiputados, gana la que tiene
# fila del periodo vigente (2026-2030) en su "Trayectoria Parlamentaria".
# La historica no la tiene; la de 1175 devuelve HTTP 404 y ni compite.
# Resolucion: 1159->13, 1175->4, 1209->24, 1252->11 (persona vigente).
```

Comprobación que discrimina contenido escapado (A36), no `validUTF8()`:

```r
# validUTF8(x) puede dar TRUE sobre "Regi<c3><b3>n" (texto de los escapes).
# La prueba real:
nchar("Región de Ñuble")               # 15 caracteres esperados
nchar("Región de Ñuble", type = "bytes")  # 17 bytes (o, si corrupto, 29)
```

## 14. Reapertura

- **Nombre del chat:** `transparencia_legislativa_chile, sesión 11 (Claude Opus 4.8)`.
- **Mensaje de apertura pre-armado:** "Tipo: CONTINUATION. El protocolo (`POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`) vive en la knowledge base del Project y se lee desde ahí. La Capa 2 (territorio) quedó construida y verificada en la rama `feat/territorio-crosswalk` (155/155 con distrito y región, panel adversarial 4/4), SIN mergear a `main`: el merge es el primer gate de esta sesión, tras verificar el fix de copy del frontend y revisión visual. `CORTE_FECHA` = 2026-07-20 al cierre (el bot corre los lunes; confirmar en `10_configuracion.R`). Adjunto: `traspaso_cierre_v10.md`, `estructura_actual.md` (re-escanear e indicar rama, A25), `backlog_acumulativo.md` (pendiente de consolidar desde v06)."
- **Documentos para la sesión 11:**
  1. *Protocolo (knowledge base, NO adjuntar, solo verificar que esté al día):* `POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
  2. *Opcionales:* `CLAUDE.md` si el merge/Capa 3 corre en Claude Code; `10_configuracion.R` para el valor vigente de `CORTE_FECHA`; el log `20260724_capa2_territorio_log.md` si se audita la Capa 2 antes del merge.
  3. *Sí se adjuntan:* `traspaso_cierre_v10.md`; `estructura_actual.md` (re-escaneado, con rama declarada); `backlog_acumulativo.md`.
- **Nota final:** si `CORTE_FECHA` cambió de nuevo (el bot corre cada lunes), adjuntar `10_configuracion.R` actualizado y avisarlo. El valor vigente al cierre de la sesión 10 es 2026-07-20. Antes de cualquier corrida local, regenerar 32-36 (A34). Verificar en qué rama quedó el escáner (A25): al cierre, `feat/territorio-crosswalk`.

## 15. Errores del asistente (POLITICA 0.5)

| momento | disparador | que_paso | regla_violada | causa_raiz | salvaguarda_presente | patron |
|---|---|---|---|---|---|---|
| Sesión 10, encargo de construcción (criterio de verificación de la Fase 4) | El ejecutor (Claude Code) lo detectó al contrastar el valor del encargo contra la fuente y la ficha BCN cruda | El asistente afirmó en el encargo que Carter (id 1017) era distrito 20 como criterio de verificación; la fuente dice 12 (D20 es Biobío, Carter es RM). El ejecutor usó el dato de la fuente y no ajustó nada para calzar con el encargo | SETTINGS §1.2.6 (no operar sobre estado supuesto); B.1 (sin supuestos implícitos); B.4 (criterio de éxito verificable mal definido, con un valor erróneo de memoria) | Especificó un valor territorial concreto desde su memoria en vez de leerlo del insumo/JSON; si el ejecutor hubiera "verificado contra el encargo" habría reportado un falso fallo | POLITICA 5.1 / B.1 + SETTINGS §1.2.6 + el registro acumulado de A21 en v07-v09 | **Octava ocurrencia de A21** (afirmar un valor verificable sin leer la fuente). Variante: el valor erróneo estaba en el CRITERIO DE ÉXITO del encargo, no en prosa. Lo atajó la disciplina del ejecutor de ir a la fuente, no el redactor. Refuerza la conclusión de v09 §15: todo valor que el encargo afirme debe marcarse como supuesto a verificar, nunca como hecho establecido |

**Nota de patrón para análisis cruzado de cartera (SETTINGS §2.2.15):** el error de esta sesión es la octava ocurrencia de A21 en cuatro sesiones (cuatro en v08, tres en v09, una en v10). Confirma que el correctivo que sostiene la calidad NO es la disciplina del asistente al redactar, sino que Claude Code verifica contra la fuente real en su Fase 0. Esta sesión aporta evidencia adicional de un ángulo nuevo: el valor erróneo no estaba en prosa descriptiva sino en el CRITERIO DE ÉXITO del encargo (Fase 4), el lugar donde un ejecutor menos disciplinado habría "verificado contra el encargo" y reportado un falso fallo, o peor, ajustado el dato para calzar. La salvaguarda estructural ya redactada (marcar todo valor afirmado como supuesto a verificar en Fase 0, nunca como hecho) debe extenderse explícitamente a los criterios de éxito, no solo al contexto. Candidata firme, ya madura, para la próxima sesión BIBLIOTECA de `slep_estado_proyectos_monitoreo`: A21 acumula ocho ocurrencias documentadas y un mecanismo correctivo identificado que no depende de la disciplina del redactor.
