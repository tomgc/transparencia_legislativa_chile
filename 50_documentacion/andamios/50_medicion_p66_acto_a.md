# P-66 acto A — Medición del contrato de la entidad `proyecto`

> **Encargo:** `50_documentacion/andamios/50_encargo_p66_acto_a_medicion.md`
> **Sesión:** 21 (2026-08-13) · **Rama:** `medicion/p66-acto-a`
> **Naturaleza:** medición y diagnóstico. **No** construye la entidad `proyecto`,
> **no** escribe en `40_salidas/`, **no** escribe en `docs/`, **no** modifica
> ningún script del pipeline.
> **Bitácora:** `50_documentacion/andamios/logs/20260813_p66_acto_a_log.md`

---

## 0. Lo que esta medición cambia respecto del contrato ya escrito

El contrato de la entidad `proyecto` está redactado en
`50_documentacion/activa/50_veredicto_eje_tematico.md` §5.2. **Todas sus cifras
son de un universo que ya no existe:** se midieron sobre **381** boletines con
intermedios sellados el 2026-07-27. El corte vigente (`CORTE_FECHA =
"2026-08-12"`, `10_utils/10_configuracion.R:57`) tiene **427** boletines, un
**12,08 % más**.

Tres conclusiones de esta medición, cada una con su sección:

1. **La tramitación es construible y sale completa.** El SIL resuelve **427 de
   427** boletines del corte vigente, con **4 799** trámites, **4 799 de 4 799**
   con fecha parseable, y `etapa` y `estado` no vacíos en **427 de 427**. Lo que
   la API de la Cámara no expone, el SIL lo entrega íntegro.
2. **`etapa` y `estado` son texto libre, sin código de dominio.** La respuesta
   del SIL trae **0 atributos XML** en todo el documento. D29 («los campos con
   atributo de dominio conservan código y glosa») **no se puede cumplir con esta
   fuente**: solo hay glosa.
3. **`ley_numero` cubre 28 de 427 (6,56 %)**, y esa es la cifra real, no un
   fallo de extracción: solo 26 proyectos del universo están `Publicado`.

---

## 1. Tabla de G1 — universo y denominadores al corte 2026-08-12

Medido sobre las **capturas crudas** `20260812_*` de `20_insumos/camara/`, nunca
sobre `40_salidas/intermedios/` (que están desalineados: `proyectos_detalle.rds`
trae 381 filas, el universo del corte anterior).

| # | Medida | Numerador | Denominador | Artefacto |
|---|---|---|---|---|
| 1 | Boletines totales del corte | **427** | 427 | `20260812_detalle_proyectos_xml_2026_tope-inf.rds` |
| 2a | Boletines con ≥1 materia | **5** | 427 boletines del corte | ídem |
| 2b | Boletines sin ninguna materia | **422** | 427 boletines del corte | ídem |
| 3 | Cohorte por `FechaIngreso`: 2016 / 2018 / 2020 / 2021 / 2022 / 2023 / 2024 / 2025 / **2026** | 3 / 2 / 1 / 2 / 6 / 7 / 32 / 38 / **336** | 427 boletines del corte | ídem |
| 4a | Votaciones totales (`votacion_id` distinto) | **842** | 842 votaciones del corte | `20260812_votos_long_2026_tope-inf.rds` |
| 4b | Votaciones tipo `Proyecto de Ley` (🔒 D26) | **561** | 842 votaciones del corte | ídem |
| 5a | Filas de voto totales | **130 510** | 130 510 filas del corte | ídem |
| 5b | Filas de voto con boletín no vacío | **86 955** | 130 510 filas del corte | ídem |
| 6a | Boletines con ≥1 autor | **314** | 427 boletines del corte | `20260812_proyectos_long_2026_tope-inf.rds` |
| 6b | Filas autor-proyecto | **1 997** | 1 997 filas de autoría | ídem |
| 7a | Autores distintos | **199** | 199 autores distintos | ídem |
| 7b | Autores en el padrón vigente | **155** | 199 autores distintos | `20260812_diputados.rds` (155 ids en el padrón) |

**Coincidencias declaradas.** 427, 422 y 336 coinciden con H2 del encargo; las
tres se contaron en esta corrida sobre el crudo, sin leer H2 antes de contar. La
coincidencia es un resultado, no una confirmación de que se heredó bien. El
universo del veredicto (381) **difiere**, y esa diferencia es el motivo del
encargo.

**Hallazgo lateral.** Las 86 955 filas con boletín son **exactamente** las filas
de tipo `Proyecto de Ley`. El boletín se recupera del texto de `Descripcion`
(34:26-29) si y solo si la votación es de ese tipo; `Otros` (21 390), `Proyecto
de Resolución` (18 445) y `Proyecto de Acuerdo` (3 720) nunca lo traen. Es la
forma de la fuente, no una falla del regex.

---

## 2. Tabla de G2 — inventario contra el contrato §5.2

Medido **leyendo el artefacto** (A70): se parsearon los 427 XML de la captura
cruda. Denominador por defecto: 427 boletines del corte.

| Campo del contrato | ¿Existe hoy? | Artefacto y nodo exactos | Cobertura | Qué falta |
|---|---|---|---|---|
| `boletin` | SÍ | captura XML `./NumeroBoletin` | **427/427 (100,00 %)** | nada |
| `nombre` | SÍ | `./Nombre` | **427/427 (100,00 %)** | nada |
| `tipo_iniciativa` | SÍ | `./TipoIniciativa` | **427/427 (100,00 %)** | nada |
| `camara_origen` | SÍ | `./CamaraOrigen` (texto + atributo `Valor`) | **427/427 (100,00 %)** | nada de fuente; el parser actual no lo extrae |
| `fecha_ingreso` | SÍ | `./FechaIngreso` | **427/427 (100,00 %)** | nada |
| `tramitacion.etapa_actual` | **NO** | ningún artefacto en disco | **0/427 (0,00 %)** | depende del SIL |
| `tramitacion.estado` | **NO** | ningún artefacto en disco | **0/427 (0,00 %)** | depende del SIL; hoy `admisible` como proxy |
| `tramitacion.ley_numero` | **NO** | ningún artefacto en disco | **0/427 (0,00 %)** | depende del SIL |
| `tramitacion.tramites[]` | **NO** | ningún artefacto en disco | **0/427 (0,00 %)** | depende del SIL |
| `autores[].parlamentario_id` | SÍ | `.//Autores/ParlamentarioAutor/Diputado/Id` | **364/427 (85,25 %)** | autores Senador se ignoran (35:62) |
| `autores[].nombre` | SÍ | `.//Autores/ParlamentarioAutor/Diputado/Nombre` | **364/427 (85,25 %)** | nada |
| `autores[].camara` | **NO** | `.//Autores/ParlamentarioAutor/Camara` | **0/427 (0,00 %)** | sin nodo por autor; derivable de `CamaraOrigen` |
| `votaciones[]` | SÍ | `./Votaciones/VotacionProyectoLey` | **119/427 (27,87 %)** | nada: persistido tras P-63 |
| `votaciones[].votacion_id` | SÍ | `…/Id` | **737/737 (100,00 %)** elementos | — |
| `votaciones[].fecha` | SÍ | `…/Fecha` | **737/737 (100,00 %)** elementos | — |
| `votaciones[].tipo` | SÍ | `…/Tipo` | **737/737 (100,00 %)** elementos | — |
| `votaciones[].tramite_constitucional` | SÍ | `…/TramiteConstitucional` | **737/737 (100,00 %)** elementos | — |
| `votaciones[].articulo` | SÍ | `…/Articulo` | **629/737 (85,35 %)** elementos | — |
| `votaciones[].resultado` | SÍ | `…/Resultado` | **737/737 (100,00 %)** elementos | — |
| `materias[]` | SÍ (parcial) | `.//Materias/Materia` | **5/427 (1,17 %)** | hueco de la fuente; P-68 cerró la vía BCN |
| `metadatos.cobertura_materias` | DERIVABLE | de `n_materias > 0` | **427/427** | campo derivado, no de fuente |

**Antes de declarar la ausencia se buscó (A83).** Diez rutas candidatas sobre
los 427 documentos: `.//Tramitacion`, `.//Tramites`, `.//Tramite`, `.//Etapa`,
`.//EtapaActual`, `.//Estado`, `.//Ley`, `.//LeyNumero`, `.//NumeroLey` dieron
**0 de 427** cada una. `.//TramiteConstitucional` aparece en 119 de 427 **pero
cuelga de `Votaciones`**: es el trámite de cada votación, no la tramitación del
proyecto. El root `ProyectoLey` tiene 10 hijos y ninguno es de tramitación.

**H3 confirmada.** El nodo `Votaciones` quedó persistido tras P-63: **119 de
427** boletines, **737** elementos, **14** campos hijo distintos. Los seis
campos que el contrato §5.2 pide para `votaciones[]` están todos cubiertos.

---

## 3. Tabla de G4 — censo del SIL sobre el universo completo

`GET https://tramitacion.senado.cl/wspublico/tramitacion.php?boletin=<NNNNN>`.
**Cuadre D38 con `stopifnot()`: la lista pedida y el censo coinciden en 427
boletines. PASA.** Toda la reconciliación es contra la lista **pedida**.

| # | Medida | Valor | Denominador |
|---|---|---|---|
| 1 | Boletines resueltos | **427/427 (100,00 %)** | 427 boletines **pedidos** |
| — | Boletín devuelto == boletín pedido | **427/427 (100,00 %)** | 427 resueltos |
| 2a | Trámites totales | **4 799** | — |
| 2b | Trámites por boletín (mín / mediana / máx) | **2 / 2 / 227** | 427 boletines resueltos |
| 2c | Trámites por boletín (media · p75 · p90 · p99) | **11,24 · 9 · 23 · 110,18** | 427 boletines resueltos |
| 3a | Trámites con fecha **parseable** (`%d/%m/%Y`) | **4 799/4 799 (100,00 %)** | nodos `FECHA` de trámite |
| 3b | Trámites con fecha **dentro de rango plausible** | **4 797/4 799 (99,96 %)** | nodos `FECHA` de trámite |
| 4a | Boletines con `etapa` no vacía | **427/427 (100,00 %)** sobre resueltos · **427/427 (100,00 %)** sobre pedidos | ambos |
| 4b | Boletines con `estado` no vacío | **427/427 (100,00 %)** sobre resueltos · **427/427 (100,00 %)** sobre pedidos | ambos |
| 4c | Boletines con `ley_numero` no vacío | **28/427 (6,56 %)** sobre resueltos · **28/427 (6,56 %)** sobre pedidos | ambos |
| 4d | Boletines con `subetapa` no vacía | **427/427 (100,00 %)** sobre resueltos · **427/427 (100,00 %)** sobre pedidos | ambos |
| 5a | Valores distintos de `etapa` | **12** | 427 boletines con etapa no vacía |
| 5b | Valores distintos de `estado` | **4** | 427 boletines con estado no vacío |
| 5c | Atributos XML en toda la respuesta (🔒 D29) | **0** | 427 respuestas |

Los dos denominadores de la fila 4 coinciden **porque la cobertura es total**:
427 resueltos de 427 pedidos. No es una redundancia del reporte — si el SIL
hubiera fallado en algún boletín, serían dos cifras distintas.

### Distribución de `etapa` (12 valores, sobre 427)

| Etapa | n |
|---|---|
| Primer trámite constitucional (C.Diputados) | 309 |
| Segundo trámite constitucional (Senado) | 51 |
| Tramitación terminada | 34 |
| Comisión Mixta por rechazo de modificaciones (Senado) | 9 |
| Trámite de aprobación presidencial (C.Diputados) | 8 |
| Archivado | 6 |
| Trámite finalización en Cámara de Origen (C.Diputados) | 4 |
| Trámite en Tribunal Constitucional (C.Diputados) | 2 |
| Comisión Mixta por rechazo de idea de legislar (Senado) | 1 |
| Primer trámite constitucional (Senado) | 1 |
| Tercer trámite constitucional (C.Diputados) | 1 |
| Tercer trámite constitucional (Senado) | 1 |

### Distribución de `estado` (4 valores, sobre 427)

| Estado | n |
|---|---|
| En tramitación | 394 |
| Publicado | 26 |
| Archivado | 6 |
| Rechazado | 1 |

**Sobre D29.** `0` atributos en toda la respuesta significa que `etapa` y
`estado` llegan como **texto libre, solo glosa, sin código de dominio**. El
invariante D29 exige conservar código y glosa cuando el campo trae atributo de
dominio; aquí **no hay atributo que conservar**. Publicar un código exigiría
fabricar un catálogo propio, que es decisión del titular y no de esta medición.

### Tres trampas de medición que este censo esquivó, y que el acto B hereda

**(a) «Parseable» no es «válida».** Las 4 799 fechas parsean al 100 %, pero
**2 de 4 799 caen fuera del rango plausible**:

| Boletín | Fecha del SIL | Problema |
|---|---|---|
| `18232-25` | `25/05/2626` | Errata evidente de la fuente: año 2626 |
| `18507-04` | `13/08/2026` | **Un día posterior a `CORTE_FECHA = 2026-08-12`** |

El segundo caso es el que importa para la arquitectura: **el SIL entrega el
estado del proyecto al momento de la llamada, no al corte declarado**. Es
exactamente la asimetría que P-74 (A) cerró para el nodo `Votaciones` de la
Cámara. Un extractor de tramitación necesita el mismo acotamiento temporal, o el
artefacto publicado bajo el corte `2026-08-12` contendrá eventos posteriores.
Excluyendo esas dos, el rango es **2016-05-02 a 2026-08-12**, que cierra
exactamente en el corte. Ver gate G-8.

**(b) Presencia de nodo no es presencia de dato (A62).** El nodo `leynro` está
**presente en 427 de 427** y **vacío en 399**. Contar por presencia da 427 en vez
de 28: **error de 15,2×**. Todas las cifras de esta ficha cuentan contenido no
vacío, no presencia. (`etapa` y `estado` sí traen contenido en 427/427, así que
ahí las dos formas de contar coinciden — pero coinciden por el dato, no por el
método.)

**(c) El conteo de `estado` es correcto hoy y frágil mañana.** Los 427 valores
llegan con **espacio final** (`"En tramitación "`). Como el defecto es universal,
`trimws()` no altera el conteo (4 con y sin). Basta un solo valor sin ese espacio
para que un conteo sin normalizar salte a 5.

**Nota sobre `estado` = `Publicado` (26) frente a `ley_numero` no vacío (28).**
Las dos cifras no son la misma y no tienen por qué serlo: `ley_numero` se puebla
en 28 boletines, 2 más que los 26 marcados `Publicado`. La discrepancia se
reporta medida, no se explica: resolverla exige inspeccionar esos 2 casos y eso
es acto B.

---

## 4. Tabla de G5 — costo por refresh

| # | Medida | Valor |
|---|---|---|
| 1 | Duración total del censo | **370,4 s (6,2 min)** para 427 llamadas, con pausa de cortesía de 0,35 s |
| 2 | Latencia mediana por llamada | **466 ms** |
| 3 | Latencia máxima por llamada | **2 373 ms** |
| 4 | Tasa de respuestas no 200 | **0/427 (0,00 %)** |
| 5 | Tamaño agregado descargado | **3,13 MB** (solo cuerpos con status 200) |

**Proyección al cron semanal:** **+6,2 min por corrida** y **+3,13 MB por
corte**, creciendo con el universo (427 hoy, 381 hace cuatro semanas: **+12,08 %
en 16 días**).

**La decisión de si la tramitación entra al cron semanal, entra con caché por
corte o entra como paso manual es del titular.** Ver gate abierto #1.

---

## 5. Tabla de G6 — la compuerta ausente

| Qué | Cuántas | Dónde |
|---|---|---|
| Métricas que el diff **cuenta** | **5** | `contar_conteos_json()`, `10_utils/10_diff_conteos.R:57-61` |
| Métricas que **gatean** | **4** | `METRICAS_GATE`, `10_utils/10_diff_conteos.R:68` |
| Piso absoluto adicional | 1 (`piso_perfiles = 155L`) | `10_utils/10_diff_conteos.R:78` |

Las cuatro que gatean: `perfiles`, `votaciones`, `mociones`,
`votos_con_proyecto`. La quinta, `votos_sin_proyecto`, se reporta y
deliberadamente **no** gatea (una caída ahí es mejora, no pérdida).

**Precisión sobre R4 del encargo.** El número «cuatro» es correcto; la línea
citada (57) **no**: ahí se abre el vector de las **cinco** que se cuentan. Las
cuatro que gatean están en la **68**.

**Ninguna de las cuatro cubre materias ni tramitación.** Las cinco métricas se
derivan de `perfiles/<id>.json`, y ni el índice ni los perfiles tienen bloque de
tramitación.

### Métrica propuesta para el acto B — **no implementada aquí**

| Métrica | Contra qué se compara | Por qué |
|---|---|---|
| `proyectos_con_tramitacion` | corte anterior, regla «no debe caer» | Análogo directo de `votos_con_proyecto`: mide el eslabón que el nuevo artefacto promete. Una caída significa que el SIL dejó de resolver boletines que antes resolvía |
| `tramites_totales` | corte anterior, regla «no debe caer» | El corpus del SIL solo crece. Una caída delata pérdida de datos, no cambio de la fuente |

Ambas exigen que `contar_conteos_json()` aprenda a leer un segundo directorio de
salida (`40_salidas/json/proyectos/`), que hoy no existe: la función recorre solo
`perfiles/`. **Eso es acto B.**

---

## 6. Gates abiertos para el titular

Son **decisiones**, no sugerencias. Ninguna se tomó en esta medición.

### G-1. ¿Cómo entra la tramitación al refresh?

Tres vías, con su costo medido: **427 llamadas, 6,2 min y 3,13 MB por corte**.

| Vía | Qué implica |
|---|---|
| (a) Dentro del cron semanal | El refresh pasa de su duración actual a +6,2 min. La tramitación queda siempre fresca. Un fallo del SIL rompe el refresh completo |
| (b) Con caché por corte, como el resto | Misma clave `CORTE_FECHA` que las capturas de la Cámara; se descarga una vez por corte y se reutiliza. Coherente con la arquitectura existente |
| (c) Paso manual, fuera del cron | Cero riesgo para el refresh; la tramitación envejece hasta que alguien la corra |

**Recomendación: (b)** — es la única que respeta el patrón `con_cache()` ya
establecido, deja el dato reproducible sin red y no acopla el refresh semanal a
la disponibilidad de un servicio de otro poder del Estado.

### G-2. ¿Sobre qué universo se rehace el contrato §5.2?

El contrato se redactó sobre 381 boletines; el corte vigente tiene **427**, y el
universo creció **12,08 % en 16 días**. Hay que decidir si el contrato se
reescribe sobre 427 o si se declara explícitamente que sus cifras son de un
corte anterior.

### G-3. `etapa` y `estado` sin código de dominio (🔒 D29)

Medido: **0 atributos XML** en las 427 respuestas. Opciones: publicar solo la
glosa (12 y 4 valores distintos), o construir un catálogo propio código→glosa.
Lo segundo es fabricar un dato que la fuente no da.

### G-4. `ley_numero` con 6,56 % de cobertura

**28 de 427.** El contrato §5.2 lo incluye sin flag de cobertura. Si se publica
así, el lector no puede distinguir «este proyecto no es ley» de «no lo sabemos»
— exactamente el problema que `cobertura_materias` existe para resolver en el
bloque de materias. ¿Se agrega un flag análogo?

### G-5. `autores[].camara` no existe en la fuente

**0 de 427.** El contrato lo pide. Se puede derivar de `CamaraOrigen` (100 % de
cobertura) o retirarlo del contrato. Derivarlo es una inferencia, no un dato.

### G-6. Los 44 autores fuera del padrón vigente

**155 de 199** autores distintos están en el padrón. El plan §7 paso 4 del
veredicto propone `retornarDiputados` (padrón histórico, 1 llamada). ¿Entra en
el acto B o queda fuera de alcance?

### G-7. Qué métrica de compuerta se adopta

Ver §5. La propuesta son dos métricas; la decisión de cuál o cuáles entran, y de
si el diff aprende a leer un segundo directorio, es del titular.

### G-8. Acotamiento temporal del SIL — **el gate que esta medición descubrió**

El SIL entrega el estado del proyecto **al momento de la llamada**, no al corte
declarado. Medido: el boletín `18507-04` trae un trámite fechado `13/08/2026`,
**un día después de `CORTE_FECHA = 2026-08-12`**. Es la misma asimetría que P-74
(A) cerró para el nodo `Votaciones`, y aparece aquí por segunda vez en otra
fuente.

Tres opciones, ninguna tomada aquí:

| Vía | Qué implica |
|---|---|
| (a) Acotar al corte, como P-74 (A) | El artefacto respeta su clave de caché. Se descartan eventos posteriores contándolos y emitiéndolos por log, nunca en silencio |
| (b) Publicar sin acotar y declararlo en `metadatos` | El dato es más fresco que el corte y el lector lo sabe. Rompe la promesa de que un corte es reproducible |
| (c) No decidir ahora | El artefacto nacería con el mismo defecto que P-74 acaba de cerrar en otro lado |

**Recomendación: (a)** — es la doctrina que el proyecto ya adoptó, está
implementada y probada en `acotar_votaciones_al_corte()`
(`30_procesamiento/36_extraer_detalle_proyectos.R:176`), y su patrón de descarte
contado y emitido por log es reutilizable tal cual.

---

## 7. Presupuesto de red

| Concepto | Gastado | Autorizado |
|---|---|---|
| G3 — prueba de vida y controles | **10** | 20 |
| G4 — censo | **427** | 560 |
| **Total** | **437** | **600** |

Ninguna respuesta con status distinto de 200 se persistió. Tasa de no-200:
**0/427 (0,00 %)**.

---

## 8. Estado de los invariantes 🔒

| Invariante | Estado | Evidencia |
|---|---|---|
| Cero escrituras en `40_salidas/` y `docs/` | **CUMPLE** | Panel P3: 0 de 163 y 0 de 167 archivos con mtime posterior al corte; 0 con **ctime** posterior a hoy 00:00; `git status --porcelain -uall` con 0 líneas; 0 de 20 commits de hoy tocan esas rutas |
| Cero modificaciones a `30_procesamiento/`, `10_utils/`, `00_run_all.R` | **CUMPLE** | `git status` no los lista; solo se leyeron |
| `20_insumos/camara/` crudo inmutable | **CUMPLE** | Sello apertura == cierre: 51 archivos, 1 533 938 bytes, md5 agregado `8bf1b0b4765a99e8b15ce7747de2609e`, **51 de 51 md5 idénticos** |
| Ninguna respuesta HTTP distinta de 200 se persiste | **CUMPLE** | 0 de 437 llamadas con status != 200; el manifiesto registra todas |
| `main` sin push directo de este encargo | **CUMPLE** | El trabajo va en `medicion/p66-acto-a` |
| D26: denominador tipo `Proyecto de Ley` | **CUMPLE** | 561 de 842 votaciones, declarado en la misma línea |
| D28 / D29 | **CUMPLE con hallazgo** | D28 no se toca (no se escribe el intermedio). D29: la fuente **no trae atributos**, así que no hay código que conservar — reportado, no fabricado |
| Toda cifra recontada en esta corrida | **CUMPLE** | Ninguna cifra del veredicto ni del traspaso se hereda; las coincidencias con H2 se declaran como resultado |

---

## 9. Reproductor y artefactos

Todo en `20_insumos/exploracion/20260813/` (**gitignorada**, `.gitignore:57`):

| Archivo | Qué es |
|---|---|
| `p66_sil.R` | **Reproductor** del sondeo y censo del SIL. `Rscript … p66_sil.R g3` \| `g4`. Contador de llamadas duro, persiste solo 200 |
| `p66_manifiesto_llamadas.csv` | **Manifiesto**: fase, boletín, destino, status, bytes, latencia_ms, nota — una fila por llamada |
| `p66_g0_sello.R` / `p66_g0_sello_cierre.R` | Sello del crudo, apertura y cierre |
| `p66_g1_universo.R` | Medición de G1 |
| `p66_g2_inventario.R` | Inventario de G2 |
| `p66_g3b_estructura.R` | Mapa de la estructura real del SIL (cero red) |
| `p66_g4g5_analisis.R` | Cuadre D38, cobertura y costo |
| `p66_g4_<NNNNN>.xml` | 427 respuestas del censo, una por boletín |
