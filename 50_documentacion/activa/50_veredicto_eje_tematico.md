# Veredicto — ¿es construible el eje temático?

> Producto del encargo `50_documentacion/andamios/50_encargo_auditoria_fuentes_camara_senado.md`
> (sesión 16, 2026-08-07). Verificado adversarialmente por dos agentes independientes con
> código propio. **Propuesta, no ejecución: este documento no toca el pipeline.**
>
> La pregunta que el portal no responde hoy: *"quién vota qué en materia de vivienda"*.

---

## 1. Veredicto

# NO

**No con las fuentes disponibles y sobre el corpus que el portal publica hoy.** La cadena
voto → proyecto → materia se cierra para **2325 de 122 605 filas de voto (1,90 %)** y **15
de 791 votaciones**, sobre el universo persistido; y para **1737 de 96 397 filas (1,80 %)**
sobre el artefacto efectivamente publicado.

El encargo fijó el criterio: *"si esa cadena se cierra para una fracción baja de los votos,
el eje temático es una promesa y no un producto"*. **1,90 % es esa fracción baja.**

**El veredicto NO se debe a un eslabón roto en el pipeline.** Tres de los seis eslabones
están al 100 %. Se debe a **uno solo**: `proyecto → materia`, que cubre **5 de 381 boletines
(1,31 %)**. Todo lo demás funciona.

**Lo que sí es construible hoy, y es mucho** (§5): un eje de **tramitación** —en qué etapa
está cada proyecto, con fechas, cobertura **381 de 381**— que el portal tampoco tiene y que
responde una familia de preguntas distinta y valiosa.

---

## 2. Tabla de cobertura de la cadena

Todas las cifras son recuentos programáticos del 2026-08-07. **Los intermedios están
sellados al corte 2026-07-27** (ver §7, riesgo 5); el artefacto publicado, al 2026-08-03.

| Eslabón | Cobertura | Denominador | Artefacto del que sale |
|---|---|---|---|
| **Catálogo de materias existe y es estable** | **8518 materias**, 8518 Id enteros únicos, catálogo plano sin jerarquía; **0 altas y 0 bajas** entre 2026-07-10 y 2026-08-07 | 8518 de 8518 nodos devueltos; estabilidad sobre 2 cortes separados por 4 semanas | `WSLegislativo.asmx/retornarMaterias` (836 218 bytes) contra `50_documentacion/andamios/muestras/catalogo_materias.xml` |
| **Proyecto → materia** | **5 (1,31 %)** | **381 boletines** | `40_salidas/intermedios/proyectos_detalle.rds`, confirmado contra la API viva en 115 de 115 boletines votados |
| **Votación → proyecto** | **546 (100 %)** con el denominador correcto; 546 (69,03 %) con el denominador equivocado | **546 votaciones tipo `Proyecto de Ley`** / 791 votaciones totales | `40_salidas/intermedios/votos.rds` (sello 2026-07-27) |
| **Proyecto → tramitación** | **381 (100 %)**, con **4569 trámites, 4569 con fecha parseable**, mediana 2 y máximo 227 por proyecto | **381 boletines** | `tramitacion.senado.cl/wspublico/tramitacion.php` (SIL); reproducido en muestra propia: 20 de 20 |
| **Proyecto → autoría** | **1705 filas autor-proyecto** sobre 272 boletines autorados; rol siempre `firmante`, orden siempre `0` | 272 boletines autorados | `40_salidas/intermedios/proyectos.rds` |
| **Autor → padrón de parlamentarios** | **1625 filas (95,31 %)**; **155 de 199 autores distintos (77,89 %)**; **33 de 272 boletines** tienen al menos un autor fuera del padrón | 1705 filas / 199 autores / 272 boletines | `proyectos.rds` cruzado con `40_salidas/intermedios/diputados.rds` |
| **CADENA COMPLETA voto → proyecto → materia** | **2325 filas de voto (1,90 %)** y **15 votaciones (1,90 %)** | 122 605 filas y 791 votaciones | `votos.rds` × `proyectos_detalle.rds` |
| — la misma cadena, sobre lo **publicado** | **1737 filas (1,80 %)** | 96 397 filas de voto en los 155 perfiles | `40_salidas/json/perfiles/*.json` |

**Los 44 autores fuera del padrón** son la razón por la que el eje temático **no se puede
cruzar completamente con el eje persona**: son parlamentarios del período anterior que
firmaron mociones ingresadas antes de la instalación del período vigente (2026-03-11).
Resolverlo exige un padrón histórico, que **sí tiene fuente**:
`WSDiputado/retornarDiputados` (633 diputados en una llamada) o `retornarDiputadosXPeriodo`.

---

## 3. El eslabón "roto" no estaba roto: era un denominador equivocado

El encargo partía de que el eslabón votación → proyecto *"está roto en un tercio"*: 65 478
votos con proyecto y 30 919 sin (32,07 %). **Esa lectura es un artefacto del denominador.**

| Tipo de votación | Con boletín | Sin boletín |
|---|---|---|
| `Proyecto de Ley` | **546** | **0** |
| `Proyecto de Resolución` | 0 | 105 |
| `Proyecto de Acuerdo` | 0 | 23 |
| `Otros` | 0 | 117 |

(fuente: `table()` sobre `votos.rds`, reproducido por tres mediciones independientes)

**Las 245 votaciones sin boletín no son fallos de extracción: son votaciones sobre
instrumentos que estructuralmente no tienen boletín de proyecto de ley** — resoluciones,
acuerdos, acusaciones constitucionales y comisiones investigadoras. Ninguna de las 245
menciona "olet" en su descripción.

**El regex del `34` no falla.** Verificado en tres frentes:

- 546 de 546 descripciones de `Proyecto de Ley` tienen **exactamente una** coincidencia del
  patrón; **0 con cero, 0 con más de una**.
- **0 falsos positivos** sobre las 245 restantes.
- Las 546 coincidencias van precedidas de la cadena `"Boletín N° "` en 546 de 546.
- Contra el **campo estructurado** del servicio legado `getVotacion_Detalle`, el boletín
  extraído por regex coincide en **4 de 4** controles.

**La vía inversa lo confirma y no recupera nada:** `retornarVotacionesXProyectoLey` sobre
los **381 boletines reales** (381 de 381 HTTP 200) devuelve 723 votaciones, **todas** de tipo
`Proyecto de Ley`: reconfirma las 546 y recupera **0 de las 245**. Y la operación resulta
**idéntica byte a byte** a `retornarProyectoLey` (17 de 17 pares del primer agente, 5 de 5
pares disjuntos del verificador): es un alias del mismo recurso, así que **estructuralmente
no puede aportar nada que `retornarProyectoLey` no traiga**.

⚠️ **Salvedad de fragilidad que hay que dejar escrita:** que las 546 "traen boletín" es
cierto, pero **el boletín no es un campo de la API**. Sale de una expresión regular sobre el
texto de `Descripcion` ([34_extraer_votaciones.R:26-29](30_procesamiento/34_extraer_votaciones.R:26)).
El listado anual declara **12 nombres de elemento y ninguno es un vínculo a proyecto**; el
detalle de votación declara 18 y tampoco. **La API moderna no expone el vínculo
estructurado.** El servicio legado sí (`Boletin` en `classVotacion`), y ahí hay una mejora
de robustez disponible.

### 3.1 El residuo opaco, con sus dos cifras y su predicado exacto

Dos números que miden cosas distintas y que **no se contradicen**:

| Predicado | Votaciones | Filas de voto |
|---|---|---|
| `tipo == "Otros"` | **117** de 791 | **18 135** de 122 605 (14,79 %) |
| `descripcion == "1-Otros"` (subconjunto del anterior) | **94** de 791 | **14 570** de 122 605 (11,88 %) |

(fuente: recuento sobre `votos.rds` en este turno; el desglose de `tipo == "Otros"` es
`1-Otros` 94, `2-Acusacion Constitucional` 13, `3-Creacion Comision Investigadora` 9,
`4-Informe Comision Investigadora` 1)

Las 94 de `1-Otros` son **el residuo verdaderamente opaco**: las otras 23 al menos declaran
en su descripción de qué instrumento se trata. **Ninguna vía probada las vincula a un
proyecto**: `getVotacion_Detalle` del legado devuelve `<Votacion xsi:nil="true"/>` en 10 de
10 (muestra del verificador, disjunta de los 12 del primer agente) y en 12 de 12 (primer
agente), mientras que en los controles con boletín devuelve la respuesta completa. **El
significado de la etiqueta "1-Otros" no consta en la fuente y no se dedujo del nombre.**

**Cómo debe declararse este sesgo en el portal:** el denominador de cualquier métrica
temática tiene que ser **las votaciones de tipo `Proyecto de Ley`** (546), y el portal debe
decir explícitamente que **14,79 % de las filas de voto corresponden a instrumentos sin
proyecto asociado** y quedan fuera del eje temático por construcción. Publicar una cobertura
sobre 791 sería publicar una cobertura implícita falsa.

---

## 4. El cuello de botella real: `proyecto → materia`, y por qué

**5 de 381 boletines (1,31 %) traen materia.** No es un problema del camino: es la fuente.

- **No hay segunda vía.** `retornarVotacionesXProyectoLey` es un alias byte a byte de
  `retornarProyectoLey`. Los listados anuales (`retornarMocionesXAnno`,
  `retornarMensajesXAnno`) **no emiten el nodo `Materias`** (0 de 517 en 2016, 0 de 461 en
  2026), ni siquiera para boletines cuyo detalle sí lo trae. El Id interno de proyecto **no
  es llave de consulta** (0 hijos para 2 ids reales probados).
- **El hueco tiene forma de nodo vacío, no de nodo ausente.** `<Materias/>` viene
  **presente y autocerrado** en **332 de 332** respuestas inspeccionadas. Son cosas distintas
  y esta es la primera.
- **No es artefacto de caché.** Re-consultados contra la API viva el 2026-08-07: 8 de 8
  coinciden, y el intermedio coincide con la fuente en **115 de 115** boletines votados.
- **El déficit no es de la Cámara.** El SIL del Senado devuelve **exactamente los mismos 5
  boletines con las mismas `n_materias` (2, 2, 4, 2, 1)**.

### 4.1 Dos mecanismos compiten, y ninguno está zanjado

**Este documento no declara cuál es. Los dos tienen soporte y están confundidos entre sí.**

**Hipótesis A — gradiente temporal de indexación.** Cobertura por cohorte anual de mociones
(muestra aleatoria del verificador, **n = 20 por cohorte, semilla 90210, 200 descargas, 0
fallos**, sobre un universo censado de 6538 mociones):

| Cohorte | 2014 | 2016 | 2018 | 2019 | 2020 | 2021 | 2022 | 2023 | 2024 | 2026 |
|---|---|---|---|---|---|---|---|---|---|---|
| Con materia | 100 % | 100 % | 100 % | 100 % | 55 % | 25 % | 20 % | 10 % | **0 %** | **0 %** |

**Correcciones a la primera medición**, que decía "0 % desde 2022": el 0 % **empieza en
2024**; la zona de cobertura total **llega hasta 2019**, no hasta 2018; y **no hay salto
binario, hay un gradiente monótono con cuatro años de transición**. Llamarlo "frontera"
induce un corte que los datos no muestran.

**Hipótesis B — la materia llega con la tramitación, no con el tiempo.** En cohortes ≥ 2020,
tener votaciones multiplica por 8 las probabilidades de traer materia:
P(materia | con votaciones) = **52,6 %** vs P(materia | sin votaciones) = **11,9 %**;
Fisher exacto OR = 8,02 (IC95 2,41–27,82), **p = 0,000195**. Y por otra vía: **4 de los 5
boletines con materia son ley publicada** contra **0 de 15** sin materia; mediana de **98
trámites** contra **2**; Fisher **p = 0,001032**.

**Por qué la distinción no es académica:** si la materia llega con la tramitación y no con
el tiempo, el eje temático cubriría **"lo legislado"** y no **"lo que se vota este año"**.
Son dos productos distintos, con dos promesas distintas al lector.

**Evidencia contra el backfill rápido** (modalidad diacrónica que el repositorio ya permitía
y nadie había corrido): **7 cortes** de `20_insumos/camara/*detalle_proyectos*.rds` entre el
2026-07-06 y el 2026-08-03 muestran **el mismo conjunto de 5 boletines y las mismas 11
materias**, mientras el universo creció de 317 a 381 boletines. **0 de los 64 boletines
nuevos recibió materia.** Descarta un backfill rápido en 28 días; **no** descarta uno anual
ni uno disparado por la promulgación.

**Qué lo zanjaría:** la serie diacrónica se extiende sola con cada refresh semanal. Es un
instrumento permanente, no una medición de una vez. Y consultar `datos.bcn.cl` o LeyChile
como fuente temática alternativa —**ninguna de las dos se probó**— es la vía más prometedora,
precisamente porque 4 de los 5 aciertos son ley publicada.

---

## 5. Contrato propuesto para la entidad temática

**Propuesta, no decisión.** Y la propuesta honesta **no es** un eje de materias.

### 5.1 Lo que NO se debe publicar hoy

Un bloque `materias` en el perfil, o una vista "votaciones por tema". Con 1,31 % de
cobertura, respondería preguntas temáticas con datos parciales **sin decirlo**, que es
exactamente lo que el encargo señala como el peor resultado posible.

### 5.2 Lo que SÍ se puede publicar: la entidad `proyecto`, con tramitación

Un artefacto nuevo, `40_salidas/json/proyectos/<boletin>.json`, con llave **`boletin`**
(character, invariante de llave del proyecto) y granularidad **una fila por proyecto**:

```
{
  "boletin", "nombre", "tipo_iniciativa", "camara_origen", "fecha_ingreso",
  "tramitacion": { "etapa_actual", "estado", "ley_numero",
                   "tramites": [ { "fecha", "camara", "etapa", "descripcion" } ] },
  "autores":    [ { "camara", "parlamentario_id", "nombre" } ],
  "votaciones": [ { "votacion_id", "fecha", "tipo", "tramite_constitucional",
                    "articulo", "resultado" } ],
  "materias":   [ { "id", "nombre" } ],
  "metadatos":  { "cobertura_materias": true|false, ... }
}
```

**Relación con lo ya publicado:** los perfiles de diputado enlazan por `boletin`, que ya
está en el bloque `proyectos` de cada perfil. **No se toca ningún campo existente.**

**Qué preguntas quedarían respondidas:** en qué etapa está un proyecto y desde cuándo; qué
proyectos llegaron a ser ley; quién firmó cada moción; qué se votó de cada proyecto y en qué
trámite; cuánto demora un proyecto entre etapas.

**Qué preguntas NO quedarían respondidas, y hay que decirlo en el propio JSON:** *"quién vota
qué en materia de vivienda"*. El campo `materias` vendría vacío en **376 de 381** proyectos.
Por eso el bloque `metadatos` lleva `cobertura_materias` explícito: **el lector debe poder
distinguir "no tiene materias" de "no lo sabemos"**.

---

## 6. Simetría con el Senado

**El eje temático NO es simétrico entre los backends propios de cada cámara, pero SÍ puede
ser bicameral sobre la llave `boletin`.**

| Eslabón | Cámara | Senado |
|---|---|---|
| Catálogo de materias | **8518 entradas, Id entero único** | **No existe** (6 rutas candidatas → 404); solo `<DESCRIPCION>` como texto libre sin id |
| Proyecto → materia | 5 de 381 (1,31 %) | 5 de 381 (1,31 %) — **el mismo conjunto** |
| Votación → proyecto | 546 de 791 (69,03 %) | **259 de 278 (93,17 %)** en la legislatura vigente |
| Proyecto → tramitación | **no lo expone la API** | **381 de 381 (100 %)** vía SIL |
| Proyecto → autoría | 1705 filas con `diputado_id` | **330 de 330 mociones**, pero **sin identificador**: solo texto libre |
| Autor → padrón | 1625 de 1705 filas (95,31 %) por id | **2127 de 2127 pares (100 %)** por nombre, con **33 de 282 claves ambiguas** |

**El puente bicameral es el SIL** (`tramitacion.senado.cl/wspublico/tramitacion.php`), que
pese a estar en dominio del Senado resuelve **381 de 381 boletines de la Cámara**, con
título idéntico en 381 de 381 tras decodificar entidades HTML.

⚠️ **Y hay una trampa que documentar antes de construir nada sobre `/api/votes` del Senado:**
el campo `BOLETIN` **mezcla dos espacios de numeración sin discriminador**. De 78 valores
distintos, **21 son "Asuntos"** (serie `2xxx-`) que resuelven contra proyectos de 2001 sin
relación. La verificación `boletin_devuelto == boletin_pedido` deja pasar **2 de 15** falsos
positivos.

---

## 7. Plan de construcción propuesto

**Convertible en encargos.** Ordenado por relación valor/costo medida, no por preferencia.

| # | Paso | Qué verifica | Costo |
|---|---|---|---|
| **1** | **Dejar de descartar el nodo `Votaciones` de `retornarProyectoLey`** en `parsear_contenido_proyecto()` ([10_utils.R:279-292](10_utils/10_utils.R:279)) | Que aparezcan `TipoVotacionProyectoLey`, `Articulo`, `TramiteConstitucional` y `TramiteReglamentario`. **Cobertura medida: 115 de 115 boletines votados traen el nodo**, 723 votaciones, `Articulo` no vacío en 619 de 723 | **Cero llamadas nuevas.** El pipeline ya descarga esa respuesta |
| **2** | Consumir `retornarMaterias` y persistir el catálogo de 8518 | Cardinalidad 8518, Id únicos, y **serie diacrónica**: comparar contra el corte anterior para detectar altas | 1 llamada por refresh |
| **3** | Extractor de tramitación desde el SIL, por boletín | 381 de 381 resueltos; trámites con fecha parseable; `etapa` y `estado` no vacíos | 1 llamada por boletín; **cierra el hueco `# REVISAR` de estado de tramitación** |
| **4** | Padrón histórico vía `retornarDiputados` | Que los **44 autores fuera del padrón** queden resueltos: hoy 155 de 199 | 1 llamada |
| **5** | `retornarMensajesXAnno` para completar el universo | Que el corpus deje de cubrir solo mociones (52 mensajes en 2026) | 1 llamada por año |
| **6** | Publicar la entidad `proyecto` con `cobertura_materias` explícito | Que ningún proyecto sin materia se publique como "sin materias" en vez de "sin dato" | — |
| **7** | **Antes de cualquier promesa temática:** medir si LeyChile o `datos.bcn.cl` tienen materias para los 376 boletines sin ellas | Si la respuesta es sí, el veredicto de este documento cambia | Encargo propio |

⚠️ **Compuerta que hoy no existe:** las métricas que gatean el refresh semanal son 4
(`perfiles`, `votaciones`, `mociones`, `votos_con_proyecto`, en
[10_diff_conteos.R:57](10_utils/10_diff_conteos.R:57)). **Ninguna cubre materias ni
tramitación.** Cualquier eje temático nacería sin compuerta: hay que agregarla en el mismo
paso que lo publique.

---

## 8. Riesgos, el que más preocupa primero

1. **Publicar el eje temático con 1,31 % de cobertura sin declararlo.** Produciría un portal
   que responde "quién vota qué en vivienda" con 5 proyectos de 381 y **presenta el
   resultado como si fuera el universo**. Es el riesgo que este encargo existe para
   prevenir. Mitigación: `cobertura_materias` explícito, y no publicar la vista temática
   hasta que la cobertura lo justifique.

2. **Confundir "lo legislado" con "lo que se vota".** Si el mecanismo real es la hipótesis B,
   un eje temático construido hoy cubriría desproporcionadamente proyectos antiguos y ya
   promulgados, y **sesgaría el retrato del período vigente sin que se note**.

3. **Publicar cobertura sobre el denominador equivocado.** El 32 % de "votos sin proyecto" es
   un artefacto: 14,79 % de las filas son instrumentos sin boletín posible. Un portal que
   diga "cobertura del 68 %" estaría describiendo mal su propio producto.

4. **El sesgo de padrón, hoy no declarado.** **26 208 filas de voto (21,38 % de 122 605)**
   pertenecen a 84 `diputado_id` que **no tienen perfil publicado** (239 distintos en
   `votos.rds` contra 155 perfiles). El portal publica votaciones solo de los 155 vigentes y
   **no dice que el resto existe**.

5. **Los intermedios están desalineados con el corte publicado.** Declaran sello
   **2026-07-27** mientras `CORTE_FECHA` es **2026-08-03**, y `validar_corte()` —la propia
   compuerta del proyecto— **hace `stop()` sobre ellos** (ejecutado en esta auditoría). El
   contenido sí corresponde al refresh 2026-08-03 (96 397 = 65 478 + 30 919 reconcilia), así
   que el problema es el **sello**, no el dato. Pero cualquier corrida de `39` fallaría hoy,
   y no está determinado si el arreglo es re-sellar o re-extraer.

6. **La materia como llave depende de un join por texto en el lado del Senado.** 11 de 11 en
   la muestra observada, pero **13 nombres del catálogo apuntan a más de un Id**: el join no
   es inyectivo en general.

7. **`retornarProyectoLey` es un único punto de falla.** Es la única vía a materias, a
   autoría y al nodo `Votaciones`. Su descriptor es intermitente y la fuente no documenta
   ni un dominio de códigos (0 `enumeration` en los 5 WSDL).
