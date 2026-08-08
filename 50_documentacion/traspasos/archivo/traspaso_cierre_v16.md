# Traspaso de cierre — v16

## 1. Identificación

- **Proyecto:** `transparencia_legislativa_chile` — portal serverless de transparencia legislativa de Chile.
- **Versión del traspaso:** v16. **Fecha:** 2026-08-08. **Sesión:** 16.
- **Foco:** desatascar la publicación (dos PRs abiertos que conflictaban en ambos órdenes), ejecutar la auditoría de fuentes ampliada al eje temático, y cerrar el desalineamiento de sello que dejaba el pipeline sin poder correr.
- **Entorno:** R 4.5.2 sobre macOS (Positron); Claude Code para la ejecución autónoma; GitHub Pages desde `/docs`.
- **Protocolo usado:** `POLITICA_PROYECTO.md` v5.6 y `SETTINGS_Y_PROMPTS_OPERACIONALES.md` v16, verificados contra la knowledge base del Project al abrir. Sin delta respecto de lo citado en v15.
- **Archivos principales modificados:** `10_utils/10_utils.R`, `00_run_all.R`, `40_salidas/intermedios/*.rds` (re-sellados), `50_documentacion/activa/procedimiento_actualizacion.md`, `CLAUDE.md`, `.gitignore`, más cinco documentos nuevos de auditoría y tres logs de ejecución.

---

## 2. Resumen ejecutivo

La sesión se propuso resolver P-58 (los dos PRs abiertos sobre los mismos 310 archivos) y encadenar P-61 (auditoría de fuentes Cámara/Senado), y terminó cerrando cuatro pendientes y abriendo una línea de trabajo nueva. P-58 se resolvió por hunk como el traspaso anterior exigía: el conflicto resultó ser un único hunk de `metadatos.generado` en 310 de 310 archivos, se conservó el lado del bot, y `main` quedó con el contrato legacy retirado y el corte 2026-08-03 publicado, con 8 de 8 criterios cumplidos. A mitad de sesión el titular declaró que el eje de mayor interés del proyecto es **temas, proyectos y votaciones**, con asistencia en segundo plano, así que el encargo de P-61 se amplió antes de lanzarlo con una quinta pregunta de meta, un artefacto de salida nuevo y cinco criterios adicionales. La auditoría corrió con 10 agentes más un panel adversarial de 5 y devolvió cuatro veredictos: el eje temático **no** es construible hoy (la cadena voto → proyecto → materia cierra en 1,90 %), P2 sigue sin fuente semántica, el padrón del Senado sí es confiable por una ruta distinta de la ya descartada, y el contrato simétrico D2 es construible con cinco lagunas. La auditoría además refutó dos premisas que el proyecto daba por buenas, una de ellas mía y de esta misma sesión. De paso destapó que ninguna corrida de `39` era posible, lo que abrió P-62: el diagnóstico mostró que los intermedios están en `.gitignore` y no viajan, mientras `CORTE_FECHA` sí, de modo que toda copia local queda desalineada tras cada merge del bot. Se arregló corriendo `32`–`36` desde caché (0,9 s, cero tráfico) y, con la decisión del titular de no versionar los intermedios, se construyó en P-65 una guarda en el orquestador que detecta el desfase, avisa y regenera sin red, o falla ruidosamente si no puede. El proyecto cierra sin bugs activos, con `main` en `f1584b8`, 0 PRs abiertos, `run_all()` corriendo completo en 12,1 s, y con el eje temático convertido de aspiración vaga en una decisión informada con cifras.

---

## 3. Estado al cierre

### Qué funciona

| Componente | Estado | Última ejecución exitosa |
|---|---|---|
| Pipeline completo `32`–`39` | Correcto | `run_all()` completo, 2026-08-08, sin error, 12,1 s, 6 pasos, 0 saltados (fuente: log P-65 §4) |
| Guarda de autorregeneración | En producción | 4 escenarios probados, mergeada en `f1584b8` |
| Contrato de asistencia (Capa 3) | Publicado sin campos legacy | 0 de 310 perfiles con los 5 campos retirados (fuente: log P-58) |
| Bot semanal | Operativo | PR #3 mergeado; abre PR, no escribe en `main` |
| Compuerta `validar_corte()` | Intacta y pasando | 6 de 6 intermedios al corte 2026-08-03 |
| Portal (`docs/`) | Publicado y sin cambios en esta sesión | `git status` acotado a `docs/`: 0 líneas |

### Qué no funciona

Nada. **0 bugs activos al cierre.** El único defecto de la sesión (el desalineamiento de sello) resultó no ser un bug sino una consecuencia del diseño de versionado, y quedó resuelto estructuralmente en P-65.

### Delta respecto de v15

- `main` pasó de `ff0c482` a `f1584b8`, con 4 PRs cerrados (#3, #4, #5, #6) y 0 abiertos.
- El contrato legacy de asistencia dejó de estar "esperando merge" y está retirado en producción.
- El eje temático pasó de concepto sin medir a veredicto con cifras: `NO`, con el cuello de botella identificado y dos hipótesis en competencia declaradas.
- D3 quedó **refutada en su justificación**: existen 5 colisiones numéricas activas entre identificadores de senador y `diputado_id`, y en 5 de 5 designan personas distintas.
- `00_run_all.R` y `10_utils/10_utils.R` ganaron la guarda de autorregeneración; ninguna de las tres funciones de la compuerta (`sellar`, `leer_sellado`, `validar_corte`) fue tocada.
- El proyecto conoce por primera vez el universo real de su fuente principal: **38 operaciones en 5 servicios**, no 49.

---

## 4. Registro detallado de cambios

### 4.1 Resolución de los dos PRs por hunk (P-58)

- **Archivos:** los 310 perfiles de `40_salidas/json/perfiles/` y `docs/data/perfiles/`.
- **Categoría:** deuda de datos / publicación.
- **Qué se hizo:** se mergeó primero el PR #3 del bot tras leer su resumen de conteos (cinco métricas en `+0`), luego se trajo `origin/main` a la rama del retiro y se midió el conflicto **antes** de resolverlo: 310 archivos, 1 hunk cada uno, y el contenido del hunk sólo `"generado"` en 310 de 310. Se resolvió conservando el lado del bot mediante un script en R que reescribe cada archivo dejando el bloque entre `=======` y `>>>>>>>`, y se mergeó el PR #4.
- **Por qué (C.11):** resolver a nivel de archivo habría resucitado los cinco campos legacy en 310 de 310 perfiles (A55). La causa del conflicto es un timestamp, no una divergencia de contenido.
- **Cómo se verificó (B.4):** 0 de 310 perfiles con campos legacy; índice con 0 `tasa_asistencia` y 155 `tasa_presencia`; `corte_fecha` uniforme en 310 de 310; `docs/data` reproduciendo `40_salidas/json` en 156 de 156 md5; 4 claves sobrevivientes en 310 de 310. 8 de 8 criterios CUMPLE.
- **Dependencias afectadas:** el contrato de datos público. Ningún consumidor externo conocido.
- **Tensión resuelta:** B.1 (coherencia del contrato) contra C.11 (estabilidad para terceros), abierta desde D21. Se cerró a favor de B.1 por merge, no por excepción.

### 4.2 Ampliación del encargo de auditoría al eje temático (P-61 v2)

- **Archivo:** `50_documentacion/andamios/50_encargo_auditoria_fuentes_camara_senado.md`.
- **Categoría:** documentación / diseño de encargo.
- **Qué se hizo:** quinta pregunta de meta con seis eslabones desglosados; artefacto de salida nuevo (`50_veredicto_eje_tematico.md`); criterios de éxito 10 a 14; cuarto hallazgo en el panel adversarial; invariante nuevo contra medir cobertura sobre muestras convenientes; corrección del invariante de PRs, que había quedado obsoleto al mergearse los dos PRs que mandaba no tocar.
- **Por qué (C.11):** el titular declaró el eje de interés a mitad de sesión. Sondear la misma API dos veces para dos preguntas que dependen de las mismas operaciones no usadas habría duplicado tráfico sin separar riesgos.
- **Cómo se verificó (B.4):** los cinco artefactos exigidos existen y los 14 criterios se contrastaron en el log de ejecución.

### 4.3 Auditoría de fuentes ejecutada (P-61)

- **Archivos creados:** `50_documentacion/activa/50_catalogo_fuentes_camara.md`, `50_catalogo_fuentes_senado.md`, `50_veredicto_contrato_simetrico_senado.md`, `50_veredicto_eje_tematico.md`; script reproductor `50_documentacion/andamios/20260807_sondeo_fuentes.R`; log `20260807_auditoria_fuentes_log.md`.
- **Categoría:** medición / exploración de fuentes.
- **Qué se hizo:** 10 agentes en dos sondeos más un panel adversarial de 5 verificadores independientes con código propio. El panel refutó el cierre en tres cifras y las correcciones se aplicaron antes del PR.
- **Cómo se verificó (B.4):** criterio 8 del encargo, el más exigente: el catálogo se re-deriva corriendo el script. Al probarlo se descubrió que el servicio devolvía HTTP 500 en `?wsdl` y el reproductor cacheaba la página de error como si fuera el descriptor; se corrigió para no persistir respuestas no-200 y degradar al listado `.asmx`, que confirmó el mismo reparto de operaciones desde una segunda superficie.
- **Tensión resuelta:** el caché de exploración contenía 157 valores `EMAIL` y 53 `FONO` no vacíos de parlamentarios, sobre un repositorio público. Se resolvió por la vía conservadora que el propio encargo autorizaba: no versionar el caché, declararlo en `.gitignore` y en el log, y dejar la reproducibilidad en el script.

### 4.4 Arreglo del sello de los intermedios (P-62)

- **Archivos:** los 6 `.rds` de `40_salidas/intermedios/`; `50_documentacion/activa/procedimiento_actualizacion.md`.
- **Categoría:** deuda de datos / reproducibilidad.
- **Qué se hizo:** diagnóstico completo del mecanismo de sello, prueba de procedencia contra el artefacto publicado, identificación de la causa raíz, y regeneración de `32`–`36` desde la captura cruda versionada.
- **Por qué (C.11):** el sello viejo en un archivo nuevo era la firma del defecto. La compuerta no estaba equivocada: distinguía correctamente "mi copia está atrasada" de "el dato está mal".
- **Cómo se verificó (B.4):** `validar_corte()` pasa 6 de 6; `39` corre en 10,2 s declarando procedencia validada; 156 de 156 artefactos idénticos a los publicados excluido `metadatos.generado`; `20_insumos/camara/` con 43 de 43 md5 iguales antes y después. 10 de 10 criterios CUMPLE.
- **Líneas clave:** `sellar()` en `10_utils/10_utils.R:65`; `escribir_atomico()` en `:51`; `leer_sellado()` en `:89`; `validar_corte()` en `:104`; invocación en `39_consolidar_json.R:45` y `:65`.

### 4.5 Guarda de autorregeneración en el orquestador (P-65)

- **Archivos:** `10_utils/10_utils.R` (+126, líneas 242-366), `00_run_all.R` (+14, invocación en `:84`), `procedimiento_actualizacion.md`, `CLAUDE.md`.
- **Categoría:** infraestructura / orquestación.
- **Qué se hizo:** `regenerar_intermedios_si_desalineados()` (`10_utils.R:294`) lee el sello de los 6 intermedios; si están alineados no hace nada; si no, comprueba que la captura cruda del corte esté versionada y, si está, avisa y regenera `32`–`36` con `camara.refrescar = FALSE` forzado y restaurado por `on.exit`; si no está, hace `stop()` nombrando los archivos que faltan y los `source()` exactos.
- **Por qué (C.11):** la causa raíz no se puede eliminar sin versionar un derivado, y el titular decidió no hacerlo. Convertir un paso que hay que recordar en un invariante del código es la única corrección que no contradice esa decisión.
- **Cómo se verificó (B.4):** cuatro escenarios (alineado, desalineado con caché, intermedio ausente, caché ausente), el segundo cerrado con `run_all(only = 39)`, que es la invocación exacta que P-62 encontró rota. 13 de 13 criterios CUMPLE.
- **Dependencias afectadas:** todas las formas de invocación de `run_all()`, que pasan por un punto único.
- **Tensión resuelta:** conveniencia contra fallo ruidoso. Se resolvió acotando la automatización a lo que puede hacerse sin red: la guarda nunca descarga, y cuando no puede resolver, falla.

### 4.6 Corrección de documentación (P-64, absorbido en P-65)

`procedimiento_actualizacion.md` tenía dos defectos: instruía correr `run_all(only = 39)` como verificación de reproducibilidad, que es exactamente lo que falla tras un refresh; y su sección "Pendiente 2" describía como pseudocódigo, con el rótulo "NO EJECUTAR AÚN", un workflow que existe y corre desde el 2026-07-10. Ambos corregidos. Queda una sola instrucción sobre regeneración.

---

## 5. Backlog acumulativo

Archivo canónico: `50_documentacion/activa/backlog_acumulativo.md`, append-only, nunca renumerado.

**Delta de esta sesión: 5 entradas nuevas (46 a 50). Total acumulado: 50 cambios en 16 sesiones.** Sin refinamientos de taxonomía ni reclasificaciones.

| # | Cambio |
|---|---|
| 46 | Resolución por hunk de los dos PRs abiertos y publicación del contrato de asistencia depurado (P-58) |
| 47 | Ampliación del encargo de auditoría de fuentes al eje temático, antes de lanzarlo (P-61 v2) |
| 48 | Ejecución de la auditoría de fuentes Cámara/Senado con panel adversarial: cuatro veredictos y cinco artefactos (P-61) |
| 49 | Diagnóstico y arreglo del sello desalineado de los intermedios, más cierre de P-61 por merge del PR #5 (P-62) |
| 50 | Guarda de autorregeneración de intermedios en el orquestador, y corrección de `procedimiento_actualizacion.md` (P-65, absorbe P-64) |

---

## 6. Bugs de la sesión

**Ningún bug de código del pipeline fue detectado ni introducido en esta sesión.** Se registran dos defectos de instrumental auxiliar, ambos detectados y corregidos por Claude Code dentro de la propia corrida:

| Síntoma | Causa raíz | Solución | Verificación | Patrón aprendido | Estado |
|---|---|---|---|---|---|
| El script reproductor de la auditoría devolvía 0 operaciones al re-derivar el catálogo | El servicio respondía HTTP 500 en `?wsdl` y el reproductor **cacheaba la página de error como si fuera el descriptor** | No persistir respuestas no-200 y degradar al listado `.asmx`, declarando de qué superficie sale el universo | El universo de 38 operaciones se re-derivó desde la segunda superficie con el mismo reparto por servicio | Un caché que no discrimina el código de respuesta convierte un fallo transitorio en un dato falso permanente. Es PAT-02 (falso verde silencioso) en versión de caché | Resuelto |
| Un agente del panel reportó RUT en el caché de exploración | El agente **contó nodos, no valores**: `<RUT>` y `<RUTDV>` existen pero vienen vacíos | Verificación independiente con `xml2` sobre el archivo | 0 valores no vacíos de 1 nodo cada uno | Presencia de nodo no es presencia de dato. El mismo patrón, invertido, aparece en el hallazgo de `<Materias/>` | Resuelto (falso positivo) |

---

## 7. Aprendizajes y restricciones descubiertas

- **A58 — Una cifra sin su predicado es una hipótesis, no un dato.** El "eslabón roto en un tercio" de esta sesión salió de tomar `votos_sin_proyecto = 30 919` del cuerpo de un PR y atribuirle el predicado "fallo de extracción". El predicado real era "instrumentos que no tienen boletín posible". *Principio: B.4.* *Si se viola:* se construye un plan entero para arreglar algo que no está roto. *Ejemplo:* §4.2 de esta sesión, y §3 del veredicto del eje temático que lo refutó.
- **A59 — Una reconciliación interna no prueba procedencia.** `96 397 = 65 478 + 30 919` suma igual en cualquier corte: es una partición, no una fecha. La procedencia se prueba contra el artefacto publicado. *Principio: B.4.* *Ejemplo:* P-62 §4, donde la prueba decisiva fueron los 155 perfiles coincidiendo en tres métricas.
- **A60 — El sello y el corte viajan por vías distintas.** Los intermedios están en `.gitignore:42` y el workflow no los commitea; `CORTE_FECHA` sí se commitea (`refresh-semanal.yml:75` y `:115`). Toda copia local queda desalineada tras cada merge del bot, por diseño. *Principio: C.11.* *Ejemplo:* P-62 §5.
- **A61 — El denominador de una fuente sale de su descriptor, no de la memoria.** El proyecto operaba con "49 operaciones"; el descriptor declara **38 en 5 servicios**, y `WSComunes` no existe (devuelve el mismo catch-all que un nombre fabricado de control). *Principio: B.4.* *Ejemplo:* catálogo de fuentes de la Cámara.
- **A62 — Nodo vacío y nodo ausente son cosas distintas, y esta fuente usa la primera.** `<Materias/>` viene **presente y autocerrado** en 332 de 332 respuestas inspeccionadas. Tratarlo como ausencia habría llevado a buscar una operación alternativa que no existe. *Principio: B.4.*
- **A63 — Un caché de exploración puede contener dato personal aunque cada dato venga de fuente pública.** 157 `EMAIL` y 53 `FONO` no vacíos, agregados en un archivo, sobre un repositorio público. La agregación cambia la naturaleza del riesgo. *Principio: gobernanza, POLITICA §6.* *Regla:* todo caché de exploración se evalúa antes de commitear, y la reproducibilidad la da el script, no los bytes.
- **A64 — Una misma ruta puede ser polimórfica y sólo una variante sirve.** `/api/sessions/attendance?id_sesion=` entrega el panel nominal que D2 exige; la misma ruta con `?id_legislatura=` entrega un agregado sin dimensión de sesión. Confundirlas produciría un contrato que parece simétrico y no lo es. *Principio: B.1.*
- **A65 — Un invariante de entorno no puede depender del estado que dejó el operador.** La guarda de P-65 fuerza `camara.refrescar = FALSE` y lo restaura con `on.exit`, en vez de confiar en cómo estaba la opción. *Principio: B.4.* *Ejemplo:* decisión 4 del log de P-65.

---

## 8. Decisiones de diseño

### D23 — El eje de mayor interés del proyecto es temas, proyectos y votaciones

- **Decisión:** el eje temático es la línea de desarrollo prioritaria; asistencia queda como capa cerrada y secundaria.
- **Alternativas:** mantener el eje persona como organizador único; construir el Senado antes que cualquier eje nuevo.
- **Justificación:** declarada por el titular. El portal responde bien preguntas sobre personas y no responde ninguna sobre temas.
- **Implicancia:** P-57 y P-59 bajan a relleno; el pipeline del Senado se subordina a lo que aporte al eje temático.

### D24 — Los intermedios no se versionan; el orquestador los regenera

- **Decisión:** `40_salidas/intermedios/*.rds` sigue en `.gitignore`; `00_run_all.R` detecta el desfase y regenera.
- **Alternativas:** (a) dejarlo como está y documentar el paso manual; (b) versionar los intermedios y agregarlos al `git add` del workflow.
- **Justificación:** regenerar cuesta 0,9 s y cero tráfico. Versionar un derivado para ahorrar un segundo contradice la razón por la que se ignoró, y agrega ~200 KB por refresh al historial. La tercera vía convierte un paso que hay que recordar en un invariante del código.
- **Tensión resuelta:** conveniencia contra fallo ruidoso. La guarda nunca descarga: si no puede regenerar sin red, hace `stop()`.

### D25 — La llave compuesta `(camara, parlamentario_id)` es obligatoria, y la justificación de D3 era falsa

- **Decisión:** D3 se mantiene en su conclusión (llave compuesta) y se corrige en su fundamento.
- **Justificación:** existen **5 colisiones numéricas activas** entre identificadores de senador vigente y `diputado_id`, y en 5 de 5 designan personas distintas; los rangos se solapan (803-1264 contra 911-1518). "No hay colisión que resolver" es falso **hoy**, no en el futuro.
- **Implicancia:** cualquier join entre cámaras sin la llave compuesta produce 5 cruces silenciosamente incorrectos. Además, el caso Longton/Mirosevic prueba que una persona recibe id nuevo al cambiar de cámara: el id es estable **por ficha**, no por persona.

### D26 — El denominador de toda métrica temática es `Proyecto de Ley`

- **Decisión:** las 245 votaciones sin boletín (resoluciones, acuerdos, acusaciones constitucionales, comisiones investigadoras) quedan fuera del eje temático por construcción, y el portal debe declararlo.
- **Justificación:** no son fallos de extracción; son instrumentos que estructuralmente no tienen boletín. Publicar cobertura sobre 791 sería publicar una cobertura implícita falsa.
- **Implicancia:** el portal debe decir que 14,79 % de las filas de voto corresponden a instrumentos sin proyecto asociado.

---

## 9. Constantes y parámetros

| Constante | Valor anterior | Valor nuevo | Archivo | Motivo |
|---|---|---|---|---|
| `CORTE_FECHA` | `2026-07-27` | `2026-08-03` | `10_utils/10_configuracion.R:41` | Merge del PR #3 del bot; el workflow la mueve con `sed` y la commitea |

Constantes nuevas introducidas en código y no en configuración: `INTERMEDIOS_PIPELINE` (`10_utils.R:258`) y `PASOS_EXTRACCION` (`00_run_all.R:50`, derivado de `PASOS` con `Filter`, no una segunda lista).

Fuente canónica de las vigentes: `10_utils/10_configuracion.R`.

**Constante decidida y aún no en código:** ninguna.

---

## 10. Arquitectura de archivos

Escáner al cierre: **2026-08-08 08:22:56, 26 carpetas, 2890 archivos** (fuente: cabecera de `estructura_actual.md` regenerada al cierre).

Cambios de estructura respecto de v15 (23 carpetas, 481 archivos en el escáner del 2026-08-03 18:57):

- `50_documentacion/traspasos/archivo/` pasa de 14 a 15 traspasos; `traspasos/` queda con el vigente únicamente. `git mv` registrado como rename, historial rastreable con `git log --follow`.
- Carpetas nuevas: `20_insumos/exploracion/20260807/` (caché de la auditoría, en `.gitignore`) y `50_documentacion/andamios/logs/`.
- El salto de 481 a 2890 archivos es atribuible al caché de exploración de P-61, que vive en disco y no en el repositorio (hipótesis, verificar con: `find 20_insumos/exploracion -type f | wc -l`).

Verificación contra la política: la deuda heredada de la pregunta 4 de la auditoría de apertura sigue vigente (prefijo `50_` ausente en `activa/`, encargos ubicados como documentación activa). Es P-60 y no se abordó.

---

## 11. Pendientes y ruta sugerida

### 11.1 Inventario

**Cerrados en esta sesión:** P-58, P-61, P-62, P-64, P-65.

| ID | Descripción | Tipo | Impacto | Dependencias | Complejidad | Criterio de éxito sugerido |
|---|---|---|---|---|---|---|
| **P-63** | Dejar de descartar el nodo `Votaciones` de `retornarProyectoLey` en `parsear_contenido_proyecto()` (`10_utils.R:279-292`) | Funcionalidad | Alto para el eje temático, costo cero | Ninguna | Baja | Aparecen `TipoVotacionProyectoLey`, `Articulo`, `TramiteConstitucional` y `TramiteReglamentario`; 115 de 115 boletines votados traen el nodo; `Articulo` no vacío en 619 de 723 |
| **P-66** | Publicar la entidad `proyecto` con tramitación desde el SIL | Funcionalidad | Alto: es el producto que la auditoría declaró construible | P-63, extractor y cliente HTTP nuevos | Alta | 381 de 381 boletines resueltos, con `cobertura_materias` explícito en cada uno |
| **P-67** | Padrón histórico vía `retornarDiputados` (633 diputados en una llamada) | Deuda de datos | Medio: hoy 44 autores quedan fuera del padrón | Ninguna | Baja | Los 199 autores distintos resuelven contra padrón; hoy 155 de 199 |
| **P-68** | Sondear LeyChile y `datos.bcn.cl` como fuente temática alternativa | Medición | Muy alto: es lo único que podría dar vuelta el veredicto del eje temático | Ninguna | Media | Veredicto sobre si existen materias para los 376 boletines que hoy no las tienen |
| **P-69** | Construir el pipeline del Senado (D1 + D2 con las 5 lagunas declaradas) | Funcionalidad | Alto: duplica el alcance del portal | P-70; capa de normalización | Alta | Panel nominal 2700 = 54 × 50, llave única, y la compuerta de sesiones centinela activa |
| **P-70** | Implementar la llave compuesta `(camara, parlamentario_id)` | Bloqueante de P-69 | Alto: sin ella hay 5 cruces incorrectos | Ninguna | Media | 0 colisiones tras el join sobre las 5 parejas conocidas |
| **P-71** | Declarar el sesgo de padrón en el portal | Documentación / honestidad del dato | Medio | Ninguna | Baja | El portal declara que 26 208 filas de voto (21,38 %) pertenecen a 84 `diputado_id` sin perfil publicado |
| **P-72** | Extender las compuertas del refresh a materias y tramitación | Deuda técnica | Alto si se publica el eje temático sin ellas | P-66 | Media | `10_diff_conteos.R` cubre las métricas nuevas; hoy cubre 4 y ninguna es temática |
| **P-73** | Serie diacrónica de materias para zanjar hipótesis A contra B | Medición | Medio: define qué promete el eje temático | Ninguna: se extiende sola con cada refresh | Baja | Detección de altas de materia entre cortes, con la cohorte anual declarada |
| **P-59** | Guarda de locale UTF-8 (gatillo 4ter) | Deuda heredada | Medio | Ninguna | Baja | `grep -rl asegurar_locale_utf8 10_utils \| wc -l` ≥ 1, sin `try()` envolviendo el `Sys.setlocale()`, y marcador depositado |
| **P-60** | Ordenación del repositorio (gatillo 4bis) | Deuda heredada | Bajo | Ninguna | Media | Marcador `50_ordenacion_repositorio.md` depositado; prefijo `50_` aplicado en `activa/` |
| **P-57** | Migrar `CODIGOS_JUSTIFICACION_OBSERVADOS` a `10_configuracion.R` | Deuda técnica | Bajo | Ninguna | Baja | El `33` la consume desde configuración; 0 diferencias tras regenerar |
| **P2** | Semántica de `RebajaAsistencia` / `RebajaQuorum` | Bloqueado | Medio | Fuente normativa externa | Alta | **La auditoría lo cerró como NO por la vía de la API:** los 5 WSDL suman 0 `documentation`, 0 `simpleType`, 0 `enumeration`. Lo único derivable es que el código de justificación determina ambas rebajas (13 códigos → 13 combinaciones, 651 de 651 filas). Sigue abierto sólo por vía normativa |
| P-49, P-50, P-51, P-53, P-54 | Heredados sin cambio | Varios | — | — | — | Sin novedad en esta sesión |

### 11.2 Evaluación de deuda técnica

- **Zona frágil 1 — `retornarProyectoLey` es un punto único de falla.** Es la única vía a materias, a autoría y al nodo `Votaciones`, y su descriptor es intermitente (HTTP 500 observado durante la sesión). Viola la redundancia implícita en C.11.
- **Zona frágil 2 — el boletín se extrae por expresión regular sobre texto libre.** `34_extraer_votaciones.R:26-29`. Funciona hoy en 546 de 546, con 0 falsos positivos sobre las 245 restantes y coincidencia 4 de 4 contra el campo estructurado del servicio legado, pero **la API moderna no expone el vínculo estructurado** y el legado sí. Hay una mejora de robustez disponible.
- **Zona frágil 3 — el backend del Senado no tiene descriptor.** La forma de la respuesta se conoce por observación, y el sobre no es uniforme entre rutas del mismo backend (`data$data` en unas, `data$DATA` en otras). Cualquier extractor necesita validación de forma con `stop()` diagnóstico.
- **Oportunidad — el nodo `Votaciones` ya se descarga y se descarta.** Es la mejora de mayor relación valor/costo del inventario: cero llamadas nuevas.

### 11.3 Auditoría de cierre (política 5.6, preguntas "Cierre")

| # | Pregunta | Respuesta |
|---|---|---|
| 2 | ¿El pipeline corre de cero sin intervención manual? | **Sí**, y mejoró en esta sesión: la guarda de P-65 eliminó la última dependencia de estado manual. `run_all()` completo, sin error, 12,1 s |
| 5 | ¿Cada transformación crítica tiene check de validación? | **No.** Las compuertas del refresh cubren 4 métricas (`perfiles`, `votaciones`, `mociones`, `votos_con_proyecto`) y ninguna cubre materias ni tramitación (`10_diff_conteos.R:57`) → **pendiente P-72** |
| 6 | ¿Los outputs son reproducibles e idempotentes? | **Sí.** Comprobado dos veces en la sesión: 156 de 156 artefactos idénticos, excluido `metadatos.generado` que es volátil por construcción |
| 7 | ¿Decisiones metodológicas como constantes nombradas? | **No.** `CODIGOS_JUSTIFICACION_OBSERVADOS` sigue fuera de `10_configuracion.R` → **pendiente P-57**, heredado |
| 8 | ¿Nombres sin tildes, ñ ni espacios? | **Sí**, con la excepción permanente de `Portal Transparencia.dc.html` |

### 11.4 Ruta sugerida para la próxima sesión

Aplicando los criterios de 1.2.4: no hay bugs activos (criterio 1) ni bloqueantes (criterio 2), así que manda el criterio 6, complejidad alta al inicio, y la línea de trabajo que el titular declaró prioritaria.

1. **P-63 — nodo `Votaciones`.** *Por qué primero:* cero llamadas nuevas, alto valor para el eje temático, y es precondición de P-66. *Criterio de éxito:* el intermedio de detalle expone las cuatro claves nuevas y `Articulo` viene no vacío en 619 de 723 votaciones.
2. **P-68 — sondeo de LeyChile y BCN.** *Por qué segundo:* es lo único que puede dar vuelta el veredicto del eje temático, y construir P-66 sin saberlo arriesga diseñar el contrato dos veces. *Criterio de éxito:* veredicto cerrado sobre si existen materias para los 376 boletines sin ellas.
3. **P-66 — entidad `proyecto` con tramitación.** *Por qué tercero:* es el producto, pero su contrato depende del resultado de P-68. *Criterio de éxito:* 381 de 381 boletines publicados con `cobertura_materias` explícito.
4. **P-59 — locale UTF-8.** *Por qué al final:* gatillo encendido desde la sesión 15, baja complejidad, cierra deuda heredada.

**Diferir:** P-69 y P-70 (el Senado merece sesión propia y su encargo depende de la capa de normalización, que aún no existe); P-60 (mueve muchos archivos y compite mal con trabajo de datos); P-54 (es sesión BIBLIOTECA de cartera, no de este proyecto); P-71 y P-72 (dependen de que exista el producto que declaran).

---

## 12. Instrucciones específicas para la próxima sesión

- ⚠️ **NO** publicar cobertura temática sobre el denominador de 791 votaciones: el denominador correcto es **546 votaciones tipo `Proyecto de Ley`** (D26). Publicar sobre 791 es publicar una cobertura implícita falsa.
- ⚠️ **NO** publicar un bloque `materias` ni una vista temática mientras la cobertura sea 5 de 381: respondería preguntas temáticas con datos parciales sin decirlo.
- ⚠️ **NO** hacer join entre datos de Cámara y Senado por identificador numérico solo: hay 5 colisiones activas y en 5 de 5 son personas distintas (D25).
- ⚠️ **NO** afirmar `CORTE_FECHA` ni el sello de un intermedio sin leerlos en el momento de afirmarlo, con ruta y línea.
- ⚠️ **NO** atribuir un predicado a una cifra heredada de otro documento sin verificar qué mide (A58). Una partición que reconcilia no prueba procedencia (A59).
- ⚠️ **NO** usar `gh pr diff --name-only` en este repositorio: devuelve 406 en PRs grandes. Usar `gh api` paginado sobre `/pulls/<n>/files` y declarar el denominador.
- ⚠️ **NO** tratar `<Materias/>` como nodo ausente: viene presente y autocerrado en 332 de 332 respuestas (A62).
- ⚠️ **NO** usar `senadores_vigentes.php` como fuente de padrón. La ruta confiable es `/api/parlamentarios?vigentes=1&limit=300` filtrando `CAMARA=="S"`, verificada 50 de 50 contra BCN.
- ⚠️ **NO** usar `/api/sessions/attendance?id_legislatura=`: devuelve un agregado sin dimensión de sesión. Solo `?id_sesion=` satisface D2 (A64).
- ✅ **ANTES** de calcular cualquier tasa de asistencia del Senado, aplicar la detección de sesiones centinela (`sum(ASISTENCIA == "Asiste") == 0`): 3 de 54 sesiones devuelven las 50 filas en `Ausente` y hundirían la tasa de los 50 senadores a la vez. La compuerta ya existe en la fuente: `54 − 3 = 51 = TOTAL_SESIONES`.
- ✅ **ANTES** de commitear cualquier caché de exploración, evaluar si contiene dato personal agregado (A63). El repositorio es público.
- ✅ **ANTES** de declarar una cobertura, declarar su denominador en la misma línea y contarlo programáticamente en ese turno.
- ✅ **ANTES** de escribir un criterio que compare artefactos regenerados, declarar en el mismo enunciado que `metadatos.generado` es volátil (A54).
- ✅ **ANTES** de dar por entregado un artefacto, comprobar que quedó adjunto en el mismo turno que lo anuncia (A52).
- 🔒 La guarda de `00_run_all.R:84` **no descarga nada**: si la captura cruda del corte no está versionada, hace `stop()`. Esa restricción es el motivo de que la guarda sea aceptable.
- 🔒 `sellar()`, `leer_sellado()` y `validar_corte()` no se tocan para hacer pasar nada. La compuerta detectó un defecto real.
- 🔒 Los intermedios **no se versionan** (D24). Están en `.gitignore:42` a propósito.
- 🔒 `main` no recibe escrituras automáticas del bot. El bot abre PR; el merge es manual.
- 🔒 El gate de conteos aborta el job sin publicar rama ni PR. Intocable.
- 🔒 `sin_registro` no se imputa, ni en el dato ni en la presentación. Las rebajas se publican y quedan fuera de toda fórmula mientras P2 siga abierta.
- 🔒 El titular de asistencia del portal es `asistencia.periodo_vigente.tasa_presencia` (D18). El campo vive en `asistencia.alcance_temporal.corte_fecha`, **no** en `metadatos`.
- 🔒 R es el único lenguaje, en todos los contextos, incluida la inspección auxiliar. Sin `jq`, `awk`, `python`, ni `grep`/`sed` sobre artefactos de datos.
- 🔒 `git add` siempre con ruta acotada. Nunca `git add .` ni `git add -A`. Git siempre con `-C <ruta absoluta>`; `gh pr` siempre con `-R tomgc/transparencia_legislativa_chile`.
- 🔒 `20_insumos/camara/` es dato crudo inmutable. El backlog nunca se renumera.

---

## 13. Fragmentos de código de referencia

**Patrón nuevo 1 — resolución de conflicto por hunk, conservando un lado.** Sirve cada vez que un merge conflictúa por un campo volátil en muchos archivos.

```r
# Conserva el lado de origin/main (entre ======= y >>>>>>>) y deja
# intacto todo lo que el merge ya resolvio limpio.
resolver_hunk <- function(ruta) {
  lineas <- readLines(ruta, warn = FALSE)
  ini <- grep("^<<<<<<<", lineas)
  sep <- grep("^=======$", lineas)
  fin <- grep("^>>>>>>>", lineas)
  stopifnot(length(ini) == 1L, length(sep) == 1L, length(fin) == 1L,
            ini < sep, sep < fin)
  salida <- c(
    if (ini > 1L) lineas[1:(ini - 1L)] else character(0),
    lineas[(sep + 1L):(fin - 1L)],
    if (fin < length(lineas)) lineas[(fin + 1L):length(lineas)] else character(0)
  )
  writeLines(salida, ruta, useBytes = TRUE)
  invisible(TRUE)
}
```

**Patrón nuevo 2 — medir la forma del conflicto antes de resolverlo.** El paso que convierte "resolver a ciegas" en "resolver con premisa verificada".

```r
medir_conflicto <- function(rutas) {
  purrr::map_dfr(rutas, function(r) {
    lineas <- readLines(r, warn = FALSE)
    ini <- grep("^<<<<<<<", lineas); sep <- grep("^=======$", lineas)
    fin <- grep("^>>>>>>>", lineas)
    ok <- length(ini) == 1L && length(sep) == 1L && length(fin) == 1L
    solo_campo <- FALSE
    if (ok) {
      cuerpo <- trimws(lineas[(ini + 1L):(fin - 1L)])
      cuerpo <- cuerpo[nzchar(cuerpo) & !grepl("^=======$", cuerpo)]
      solo_campo <- length(cuerpo) > 0L &&
        all(grepl('"generado"', cuerpo, fixed = TRUE))
    }
    data.frame(ruta = r, n_hunks = length(ini), ok_forma = ok,
               solo_campo = solo_campo, stringsAsFactors = FALSE)
  })
}
```

**Patrón nuevo 3 — lector de sello que diagnostica en vez de abortar.** `leer_sellado()` es la compuerta y aborta por diseño; cuando "no legible" ES la condición a diagnosticar, se envuelve en lugar de escribir un segundo lector.

```r
corte_declarado_por <- function(ruta) {
  tryCatch({
    obj <- leer_sellado(ruta)
    attr(obj, "sello")$corte_fecha
  }, error = function(e) NA_character_)
}
```

Los patrones estables del proyecto viven en `CLAUDE.md` y en `10_utils/10_utils.R`; el traspaso no los re-copia.

---

## 14. Reapertura

### Mensaje de apertura pre-armado

> Tipo: CONTINUATION. El protocolo (`POLITICA_PROYECTO.md` v5.6, `SETTINGS_Y_PROMPTS_OPERACIONALES.md` v16) vive en la knowledge base del Project y se lee desde ahí; verifica las versiones contra la knowledge base, no contra ninguna otra fuente, antes de la Fase A. Estado: `main` en `f1584b8`, 0 PRs abiertos, 0 bugs activos, `run_all()` corriendo completo en 12,1 s con la guarda de autorregeneración en producción. La sesión 16 cerró P-58, P-61, P-62, P-64 y P-65, y dejó el eje temático medido: el veredicto es NO por materias (la cadena voto → proyecto → materia cierra en 1,90 %), pero la entidad `proyecto` con tramitación sí es construible con cobertura 381 de 381. El foco propuesto es P-63, dejar de descartar el nodo `Votaciones` que `retornarProyectoLey` ya trae y el parser descarta: cero llamadas nuevas y precondición de todo lo demás. Encadenado: P-68, sondear LeyChile y `datos.bcn.cl` como fuente temática alternativa, que es lo único que podría dar vuelta el veredicto. Dos gatillos de protocolo siguen encendidos: 4bis (ordenación, P-60) y 4ter (locale UTF-8, P-59). `CORTE_FECHA` cambia con cada merge de PR del bot, así que confírmalo en `10_utils/10_configuracion.R` antes de afirmarlo. Adjunto: `traspaso_cierre_v16.md`, `estructura_actual.md`.

### Documentos para la sesión 17

1. **Protocolo (knowledge base, NO adjuntar, solo verificar que esté al día):** `POLITICA_PROYECTO.md` v5.6, `SETTINGS_Y_PROMPTS_OPERACIONALES.md` v16.
2. **Opcionales según el foco real:** `CLAUDE.md` si el trabajo corre en Claude Code; `10_utils/10_utils.R` y `36_extraer_detalle_proyectos.R` si se aborda P-63; `50_veredicto_eje_tematico.md` si se aborda P-66 o P-68 (voluminoso pero crítico: contiene la tabla de cobertura y el contrato propuesto); `50_veredicto_contrato_simetrico_senado.md` si se aborda P-69 o P-70; `10_utils/10_configuracion.R` para el valor vigente de `CORTE_FECHA`; `backlog_acumulativo.md` solo si se aborda P-51 o un análisis de patrones; `prompt_ordenacion_repositorio_v1.md` si se aborda P-60.
3. **Sí se adjuntan:** `traspaso_cierre_v16.md`; `estructura_actual.md`.

Si `10_utils/10_configuracion.R` cambió por el merge de algún PR, adjunta la versión actualizada y avísalo al abrir.

---

## 15. Errores del asistente (POLITICA 0.5)

| momento | disparador | que_paso | regla_violada | causa_raiz | salvaguarda_presente | patron | gatillo_observable |
|---|---|---|---|---|---|---|---|
| Redacción del encargo de P-58 | El ejecutor lo detectó al fallar la verificación V3 | Se escribió el criterio de corte sobre `metadatos.corte_fecha`, una ruta que no existe: el campo vive en `asistencia.alcance_temporal.corte_fecha` | POLITICA, PAT-01: no afirmar estructura sin leer la fuente autoritativa | Se compuso la ruta por analogía con `metadatos.generado`, que sí existe, en vez de leer un JSON. El traspaso v15 §4.1 ya decía que `anio` viaja en `alcance_temporal`: la evidencia estaba a la vista y no se consultó | POLITICA (0.5, PAT-01); traspaso v15 §12 | PAT-01, sobre ruta de campo en JSON | El encargo nombraba una ruta de campo sin que ningún JSON hubiera sido leído en la sesión |
| Redacción del encargo de P-58 | El ejecutor lo señaló al chocar con la contradicción interna | El invariante 7 se escribió como "`main` no recibe push directo", generalizando el 🔒 heredado, que dice "`main` no recibe escrituras **automáticas del bot**". La generalización contradijo el §5 del propio encargo y bloqueó al ejecutor | SETTINGS 2.2 punto 12: las instrucciones heredadas se reproducen literalmente, no se parafrasean | Se citó el candado de memoria en vez de releerlo del traspaso adjunto, y la paráfrasis lo ensanchó | Traspaso v15 §12 (reproducido literal en el acuse de esta misma sesión) | PAT-01, sobre reproducción de invariante heredado | Un invariante del encargo entraba en conflicto con otra sección del mismo encargo |
| Ampliación del encargo de P-61 y tres turnos de conversación | La auditoría lo refutó con medición | Se afirmó que el eslabón votación → proyecto estaba "roto en un tercio", tomando `votos_sin_proyecto = 30 919` del cuerpo de un PR y atribuyéndole el predicado "fallo de extracción". El predicado real es "instrumentos sin boletín posible"; sobre el denominador correcto la cobertura es 546 de 546 | userPreferences, marcador de fuente: toda cifra comunicada admite solo un recuento programático del mismo turno | Se heredó una cifra de un documento anterior y se le adjuntó una interpretación que ninguna medición respaldaba. La cifra era correcta; el predicado, inventado | userPreferences; POLITICA 0.5 | PAT-01, sobre predicado de una cifra heredada | Una cifra se comunicó con una interpretación causal sin que ningún recuento del turno la hubiera producido |
| Cierre de la sesión, mensaje de instrucciones a Claude Code (dos veces: en el primer cierre y en la reentrega corregida) | El titular lo corrigió | El mensaje a Claude Code ordenaba "deposita los tres archivos" en sus rutas del repositorio, que es trabajo manual del titular (descargar y mover), y además imposible para el agente, que no tiene acceso a los archivos producidos en el contenedor del asistente | userPreferences, autonomía: las tareas mecánicas manuales (descargar un archivo, arrastrarlo a una carpeta, reemplazarlo a mano) son del titular; no se generan scripts ni instrucciones para ellas, se dicen en una línea | Se armó el mensaje al agente como una lista de todo lo que faltaba para cerrar, sin separar lo que ejecuta el agente de lo que hace el titular a mano. El error se repitió en el mismo turno de corrección de otro error del mismo límite, lo que muestra que la revisión se centró en el artefacto y no en el mensaje que lo acompañaba | userPreferences (autonomía y edición de archivos) | PAT-NUEVO-limite-manual-autoria, dirección inversa a la fila anterior. **Subsume la entrada propuesta `PAT-NUEVO-entrega-por-delta`:** un solo patrón, *confusión del límite entre el trabajo mecánico del titular y la autoría del asistente*, con dos direcciones — delegar al titular la integración de un artefacto (autoría mal asignada) y delegar a un agente el trabajo manual del titular (mecánica mal asignada) | El mensaje dirigido a un agente contenía un verbo de manipulación de archivos que el titular haría a mano ("deposita", "arrastra", "guarda en"), o el agente no tenía acceso al archivo que se le mandaba mover |
| Cierre de la sesión, entrega de los artefactos de cierre | El titular lo corrigió | El backlog se entregó como un archivo de delta (`delta_backlog_sesion_16.md`) con la instrucción de anexarlo al acumulativo, en vez de entregar `backlog_acumulativo.md` completo y ya integrado | userPreferences, materialización: pasar contenido al usuario para que él lo cree, pegue, reemplace o ensamble es una violación, no un atajo; el trabajo mecánico es del titular, la autoría del artefacto es del asistente | Se trató la regla append-only del backlog (SETTINGS 2.2.5) como si obligara a entregar el añadido por separado. Append-only describe cómo se edita el archivo, no cómo se entrega: el archivo completo con las entradas nuevas al final cumple las dos reglas a la vez | userPreferences (edición de archivos y materialización); SETTINGS 2.2.5 | PAT-NUEVO-entrega-por-delta, sobre entrega de un incremento en vez del artefacto integrado. Ningún `PAT-NN` vigente cubre el mecanismo: no es afirmar sin leer (PAT-01) ni verbosidad (PAT-08), sino trasladar al titular el trabajo de integración. **Entrada propuesta para el catálogo:** *entregar un fragmento, parche o delta cuya integración queda a cargo del titular, en vez del artefacto completo ya integrado* | El mensaje de entrega contenía la palabra "anexar" (o "reemplaza el bloque", "pega esto en") referida a un archivo persistente |
| Ejecución de P-61 (Claude Code) | El ejecutor lo reportó espontáneamente al cerrar | Se cruzó la regla de detención del §9 del encargo (premisa estructural falsa, con los ids del Senado nombrados explícitamente) y se continuó la corrida en vez de detenerse y reportar | Encargo P-61 §9, regla de detención | Se juzgó que la premisa falsa era la justificación de D3 y no D3 misma, y que detener una corrida de solo lectura no aportaba información. El juicio puede ser correcto y la regla igual fue cruzada sin autorización | Encargo P-61 §9 | PAT-01, sobre reinterpretación de una regla de detención en vez de aplicarla | La corrida encontró exactamente la condición que el encargo nombraba como causal de detención |

**Fricciones registradas:**

- `friccion: la recomendación de cierre de P-62 se redactó de forma ambigua ("un encargo único que incluya el merge del PR #5 al cerrar"), y el titular tuvo que preguntar si el merge se podía incluir → se aclaró en el turno siguiente y se fijó el orden explícito (merge primero, arreglo después).`
- `friccion: el riesgo del sello se presentó como "bug vivo" y encabezó la ruta como bloqueante, cuando era una consecuencia esperable del diseño de versionado con costo de 0,9 s → se corrigió al recibir el diagnóstico de P-62.`

**Nota de patrón:** de los seis registros, cuatro son `PAT-01` y dos son el mismo mecanismo nuevo, en direcciones opuestas (las dos últimas filas). Los tres primeros `PAT-01` y comparten mecanismo (afirmar desde una fuente secundaria o desde la memoria en vez de leer la autoritativa), con lo que el patrón acumula recurrencia dentro de una **misma sesión**, no ya entre sesiones. Según SETTINGS 2.2.16, antes de reformular la regla hay que clasificar la falla: los tres casos son de **forma del output** (el encargo salió con una ruta, un invariante y un predicado sin recuento, no por prisa ni por desconocimiento de la regla), así que la corrección correcta **no** es una prohibición más enfática sino un contrato positivo: **todo encargo debe declarar, en una sección propia, la lista de rutas de campo, invariantes heredados y cifras que contiene, cada uno con el archivo leído en la sesión que lo respalda; lo que no aparezca en esa lista no puede aparecer en el cuerpo del encargo.** Eso es P-54 aterrizado a este proyecto y se propone como entrada de la próxima revisión de gobernanza.

Los dos últimos registros son de otra naturaleza y por eso llevan `PAT-NUEVO`: no son fallas de verificación sino de **reparto del trabajo**, y ambos ocurrieron en el cierre, el segundo dentro del turno que corregía el primero. Se proponen como **una sola entrada nueva** del catálogo canónico en `herramientas_dev/gobernanza/`: *confusión del límite entre el trabajo mecánico del titular y la autoría del asistente*, con dos direcciones observables.

Su corrección es una regla de forma verificable antes de enviar, en dos partes: **(a)** si el mensaje de entrega dice "anexa", "reemplaza el bloque" o "pega esto" sobre un archivo persistente, el artefacto está mal armado y hay que rehacerlo completo; **(b)** si el mensaje dirigido a un agente contiene un verbo de manipulación de archivos que el titular hará a mano ("deposita", "arrastra", "guarda en"), o manda mover un archivo al que el agente no tiene acceso, ese ítem no va en el mensaje al agente. La regla positiva que reemplaza a ambas: **el asistente entrega archivos completos; el titular los mueve; el agente solo recibe lo que puede ejecutar sobre archivos que ya están en el repositorio.**
