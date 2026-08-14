# Veredicto — P-92: las cuatro vías derivadas del eje temático

> **Qué es esto.** Sondeo de solo lectura de las cuatro vías que quedaron abiertas
> después de que P-68 cerrara con NO la vía de LeyChile/BCN. Mide si alguna de ellas
> sostiene la pregunta del titular: *¿qué temas importan más a qué partidos o
> facciones políticas (derecha-izquierda)?*
>
> **Este documento mide y no construye.** No propone contrato de datos, no toca el
> pipeline y no decide cuál es el conjunto de temas del portal: eso es autoridad del
> titular. Encargo: `50_documentacion/andamios/50_encargo_p92_sondeo_eje_tematico.md`.
>
> **Fecha de medición:** 2026-08-13. Corte del dato: `CORTE_FECHA = "2026-08-12"`
> (`10_utils/10_configuracion.R:57`). Toda cifra sale de un recuento programático de
> esta sesión, con su denominador en la misma línea.
>
> **Reproducible:** `50_documentacion/andamios/50_sondeo_p92_f{0,0b,1,2,2b,2c,3,3b,4,5}.R`.
> Los seis primeros scripts corren con el fusible de red armado (`quit(99)`); solo
> `f2`, `f2c` y `f3` salen a la red, y cada llamada queda registrada en
> `50_documentacion/andamios/muestras/p92_llamadas_http.csv`.

---

## 1. Veredicto en una tabla

| Vía | Qué clasifica | Cobertura (con denominador) | Categorías | Control positivo | Veredicto |
|---|---|---|---|---|---|
| **1. Sufijo del boletín** | proyecto, por su número | **427/427 (100 %)** de los boletines; **86 955/130 510 (66,63 %)** de las filas de voto | **29**, de ellas **21 con n ≥ 5** | **5 de 5** (umbral 4/5) | **PASA**, sin glosa oficial |
| 2. Buscador "por Materia" de `camara.cl` | votación | **no medible** | — | no corrido | **BLOQUEADA** (403 Cloudflare) |
| 3. Léxico sobre el título del proyecto | proyecto | **308/427 (72,13 %)** de los boletines | 12 (léxico de prueba) | **3 de 5** (umbral 4/5) | **FALLA** |
| 4. Léxico sobre el texto de la votación | votación | **16/842 (1,90 %)** con `descripcion`; **0/281 (0 %)** de las votaciones sin boletín con `articulo` | — | no aplicable | **FALLA por falta de insumo** |

**La vía 1 es la única que pasa.** Su límite no es la cobertura sino el nombre: no
existe catálogo oficial que traduzca el código a una materia (§4), así que hoy es un
agrupador correcto y no publicable tal cual.

---

## 2. Las hipótesis del encargo, con su veredicto

| # | Hipótesis | Veredicto | Evidencia |
|---|---|---|---|
| H1 | Universo de 427 boletines y 842 votaciones | **CUMPLE** | 427 boletines distintos en `proyectos_detalle.rds` (427 filas); 842 `votacion_id` distintos en `votos.rds` (130 510 filas de voto) |
| H2 | Todo boletín tiene forma `NNNNN-NN` y sufijo extraíble sin ambigüedad | **CUMPLE** | **427/427** matchean `^[0-9]{5}-[0-9]{2}$`. **0 casos** fuera de la forma. Los 119 boletines citados en votaciones también: 119/119 |
| H3 | Existe catálogo oficial código → glosa del sufijo | **FALSA** | §4. 16 sondeos, ninguno lo entrega |
| H4 | El intermedio de votos trae texto descriptivo por votación, también sin boletín | **FALSA EN SUSTANCIA** | §5. Pasa la letra (842/842 no vacío) y falla el contenido: **811/842 (96,32 %)** son la etiqueta `Boletín N° X` / `Proyecto de Resolución N° X` |
| H5 | El padrón permite mapear cada votante a partido y tendencia | **FALSA como está escrita; con remedio medido** | Con el padrón vigente: **155/239** votantes (64,85 %) y **87 308/130 510** filas (66,90 %). Sumando el padrón histórico de la API: **239/239** votantes y **106 028/130 510** filas (81,24 %) |
| H6 | Existe una noción de bancada distinta de partido, con fuente | **FALSA** | 0 campos con `banc` en el padrón histórico (15 nombres de elemento distintos), 0 columnas en `diputados.rds`, 0 menciones en el catálogo de las 38 operaciones |
| H7 | El buscador "por Materia" devuelve catálogo cerrado o texto libre | **SIN RESPONDER** | §6. No es que no exista: el cliente está bloqueado |

### 2.1 Una corrección a R4

R4 declaraba *"de 791 votaciones, 546 son de tipo `Proyecto de Ley`"*. Al corte
2026-08-12 el recuento propio da **842 votaciones**, de las cuales **561 (66,63 %)**
son `Proyecto de Ley`. El reparto completo:

| Tipo | n | % de 842 |
|---|---|---|
| Proyecto de Ley | 561 | 66,63 |
| Otros | 138 | 16,39 |
| Proyecto de Resolución | 119 | 14,13 |
| Proyecto de Acuerdo | 24 | 2,85 |

**Votaciones con boletín: 561 de 842. Sin boletín: 281 de 842.** La diferencia con R4
es de corte, no de método: R4 medía el 2026-08-07.

---

## 3. Vía 1 — el sufijo del boletín

### 3.1 Cobertura y forma

**427 de 427 (100 %)** de los boletines tienen sufijo numérico extraíble, y los 427
están en la forma estricta `NNNNN-NN`. **29 categorías distintas.** La mayor es `07`,
con **117 de 427 (27,40 %)** — muy por debajo del 60 % que el encargo declaró como
umbral de no discriminación. **21 categorías tienen n ≥ 5**; solo 2 tienen n = 1.

Concentración: Herfindahl **0,1112**; entropía de Shannon **3,951 bits** sobre un
máximo de 4,858 para 29 categorías, es decir **81,3 % de la entropía máxima**.

### 3.2 Control de discriminación (declarado antes de correrlo)

**Estadístico:** Jaccard medio de los conjuntos de tokens del título entre pares del
mismo sufijo, menos el de pares de sufijo distinto. Se eligió Jaccard sobre coseno
tf-idf porque los títulos son cortos (**mediana de 12 tokens útiles**, rango 2-27) y
la repetición no aporta. Nulo por **999 permutaciones** de las etiquetas de sufijo,
semilla 92.

| Qué | Valor |
|---|---|
| Jaccard medio, **mismo** sufijo | 0,04970 (9 926 pares) |
| Jaccard medio, **distinto** sufijo | 0,02122 (81 025 pares) |
| delta observado | **0,02848** |
| nulo por permutación | media 0,00001 · sd 0,00157 · máximo 0,00556 |
| p (una cola) | **0,0010** |
| z | **18,09** |

El delta observado es **cinco veces el máximo de 999 permutaciones**. El sufijo
informa del vocabulario del título; no es una etiqueta arbitraria.

### 3.3 Control positivo: 5 de 5 (umbral declarado antes: 4 de 5)

Los 5 boletines que sí traen materia oficial (**5 de 427, 1,17 %**) son el patrón de
oro. Como no hay glosa oficial del sufijo (§4), la coherencia se juzga contra los
**títulos hermanos** del mismo sufijo, con ambos textos a la vista para que el
titular pueda revisar el juicio.

| Boletín | Sufijo | Materia oficial | Títulos hermanos del sufijo | Juicio |
|---|---|---|---|---|
| `10634-29` | 29 | SOCIEDADES ANÓNIMAS DEPORTIVAS PROFESIONALES | fútbol profesional; fútbol amateur; apuestas deportivas en línea | **coherente** |
| `10795-33` | 33 | SERVICIOS SANITARIOS; SERVICIOS PÚBLICOS SANITARIOS | Superintendencia de Servicios Sanitarios; derechos de aprovechamiento de aguas; Código de Aguas | **coherente** |
| `10986-24` | 24 | MONUMENTOS; ESCRITOR CHILENO; COMUNA DE LOTA | fomento a las artes de la visualidad; agrupaciones folclóricas; Televisión Nacional | **coherente** |
| `11608-09` | 09 | EXTRACCIÓN DE AGUA DE MAR; DESALINIZACIÓN | extracción de áridos; aguas residuales de emisarios submarinos; empresas sanitarias y bienes nacionales | **coherente**, el más débil de los cinco (ver nota) |
| `12234-02` | 02 | SISTEMA DE INTELIGENCIA DEL ESTADO | Carabineros y porte de armas; protección del espacio aéreo; armas hechizas | **coherente** |

*Nota sobre `11608-09`:* es el único de los cinco cuya comisión de tramitación
(Recursos Hídricos) difiere de la comisión modal de su sufijo (Obras Públicas). El
tema es contiguo, no ajeno, y por eso se cuenta como coherente — pero es exactamente
el tipo de caso que la §3.4 acota.

**El control puede dar rojo con estos datos.** Si el sufijo fuera ruido, los hermanos
de `10986-24` (monumentos) serían de pesca o de tributos y no de cultura. Los cinco
sufijos del patrón de oro son cinco categorías distintas, y las cinco aciertan.

### 3.4 Estabilidad semántica — el hallazgo que acota la vía

El sufijo se asigna al **ingreso** y refleja la comisión de origen, que puede no ser
la que tramita. Medición: se extrajo de `tramitacion.rds` toda mención `Comisión de X`
de los trámites. **423 de 427 (99,06 %)** boletines nombran al menos una comisión;
**96 comisiones distintas** en todo el corpus.

| Qué se midió | Resultado |
|---|---|
| Sufijos con n ≥ 5 | **20** |
| Cobertura media de su comisión modal | **92,9 %** |
| Boletines cuya comisión primera ≠ la modal de su sufijo | **36 de 423 (8,51 %)** |
| Boletines que pasan por **más de una** comisión distinta | **134 de 427 (31,38 %)** |

**Lectura:** el sufijo predice la comisión de tramitación en cerca de 9 de cada 10
casos, y en 12 de los 20 sufijos con n ≥ 5 lo hace en el 100 %. Pero **casi un tercio
de los proyectos pasa por más de una comisión**, así que el sufijo nombra el punto de
entrada, no el recorrido. Para un portal que dice *"este proyecto es de tema X"* eso
es aceptable; para uno que dijera *"esta comisión tramitó X"* no lo sería.

⚠️ **La asociación sufijo → comisión de esta sección es EMPÍRICA**, derivada de la
tramitación medida hoy. **No es una glosa oficial** y no debe publicarse como tal
(§4, D42).

---

## 4. F2 — ¿existe catálogo oficial código → glosa? **NO.**

### 4.1 Controles negativos, corridos antes del sondeo

| Control | Resultado | Discrimina |
|---|---|---|
| (a) operación fabricada contra un servicio `.asmx` **real** | HTTP **500**, 93 bytes | **sí** |
| (b) dos servicios **fabricados** distintos | HTTP **200**, 1 286 bytes, **md5 idéntico** (`a9066cc9…`) | **sí** — y confirma que 200 no prueba existencia |
| (c) ruta fabricada en `www.camara.cl` | HTTP 403 | ver §6 |

El md5 de (b) coincide con el catch-all documentado en
`50_catalogo_fuentes_camara.md` §1.1, medido el 2026-08-07: la página no cambió.

### 4.2 El candidato más serio, y por qué se descarta

`WSComision.asmx/retornarComisionesXPeriodo` entrega un campo **`<Numero>`** por
comisión (Salud = 10, Ética y Transparencia = 25, Futuro = 17). Si `<Numero>` fuera el
sufijo del boletín, existiría catálogo oficial.

**Hipótesis nula declarada antes:** `<Numero>` **no** es el sufijo. Umbral para
rechazarla: ≥ 15 de los 20 sufijos con n ≥ 5 deben casar.

**Resultado: 7 de 20.** No se rechaza la nula.

| Sufijo | Comisión modal (empírica) | `<Numero>` oficial de esa comisión | ¿Casa? |
|---|---|---|---|
| 07 | Constitución, Legislación, Justicia y Reglamento | 3 | no |
| 06 | Gobierno Interior, Nacionalidad, Ciudadanía y Regionalización | 1 | no |
| 04 | Educación | 4 | **sí** |
| 13 | Trabajo y Seguridad Social | 11 | no |
| 25 | Seguridad Ciudadana | 21 | no |
| 15 | Obras Públicas, Transportes y Telecomunicaciones | 7 | no |
| 03 | Economía, Fomento… | 13 | no |
| 11 | Salud | 10 | no |
| 10 | Relaciones Exteriores… | 2 | no |
| 14 | Vivienda, Desarrollo Urbano y Bienes Nacionales | 14 | **sí** |
| 18 | Familia | 16 | no |
| 02 | Defensa Nacional | 6 | no |
| 05 | Hacienda | 5 | **sí** |
| 29 | Deportes y Recreación | 29 | **sí** |
| 24 | Cultura, Artes y Comunicaciones | 24 | **sí** |
| 01 | Agricultura, Silvicultura y Desarrollo Rural | 8 | no |
| 19 | Futuro, Ciencias, Tecnología… | 17 | no |
| 08 | Minería y Energía | 12 | no |
| 33 | Recursos Hídricos y Desertificación | 33 | **sí** |
| 35 | De Personas Mayores y Discapacidad | 35 | **sí** |

**Control positivo del propio cruce** (para descartar que el 7/20 sea culpa del
emparejador de nombres): autoemparejamiento de las 28 comisiones consigo mismas
**28/28 (100 %)**; emparejamiento empírico → oficial **20/20 (100 %)**. El emparejador
encuentra las 20 comisiones; lo que no coincide son los números.

*Dos defectos de medición propios, detectados y corregidos durante esta fase:* la
primera versión comparaba `"04"` con `"4"` como texto (falso negativo) y hacía casar
`cultura` dentro de `agricultura` (falso emparejamiento). Las cifras de arriba son de
la versión corregida.

### 4.3 Lo intentado, uno por uno

| # | Fuente sondeada | Resultado |
|---|---|---|
| 1 | `retornarTramitesConstitucionales` | 6 ítems, catálogo de trámites, no de materias |
| 2 | `retornarTramitesReglamentarios` | 8 ítems, ídem |
| 3 | `retornarComisionesVigentes` | 2 comisiones |
| 4 | `retornarComisionesXPeriodo` (período 11) | 2 comisiones, md5 idéntico al anterior |
| 5 | `retornarComisionesXPeriodo` (período 10) | 133 comisiones; 28 Permanentes con `<Numero>` en 1-35 → §4.2 |
| 6 | `retornarMaterias` | **8 518 nodos, 8 518 ids únicos, 14 nombres vacíos** (R1 **confirmado**). **0 ids de 1-2 dígitos**: no es un catálogo de sufijos |
| 7 | `www.camara.cl` (3 rutas, sin y con cabeceras de navegador) | 403 Cloudflare → §6 |
| 8 | `www.senado.cl/comisiones` | HTTP 404 |
| 9 | `bcn.cl/leychile/consulta/ayuda_tramitacion` | 200, 9 771 bytes, 0 fragmentos con código de 2 dígitos |
| 10 | `bcn.cl/formacioncivica` (guía de tramitación) | 200, 31 570 bytes, **0** menciones de "bolet", 2 de "comisi", **0 `<select>`** |
| 11 | `senado.cl` y `tramitacion.senado.cl` (búsqueda avanzada del SIL) | 200 con **cuerpo de 0 bytes** en 2 de 2 |
| 12 | catálogo de 8 518 materias, buscando una glosa de sufijo | 76 nombres empiezan con `COMISI`, 8 contienen `BOLET`; ninguno es un catálogo de códigos |

### 4.4 Consecuencia de producto

**La vía 1 queda usable como agrupador y sin nombre publicable.** Nadie busca
"tema 07". Las opciones que esto le deja al titular están en §8; ninguna se toma aquí.

🔒 **No se inventó ninguna glosa (D42).** La columna "comisión modal (empírica)" de
este documento es una medición de la tramitación, rotulada como tal en cada tabla, y
**no** una traducción oficial del código.

---

## 5. F4 — vías 3 y 4, clasificación propia sobre texto

### 5.1 El insumo de la vía 4 no existe

`votos.rds` trae `descripcion` no vacía en **842 de 842 (100 %)** votaciones. Ese es
el número que H4 anticipaba. Pero el contenido es una **etiqueta**:

| Forma de la `descripcion` | n | % de 842 |
|---|---|---|
| `Boletín N° X` / `Proyecto de Resolución N° X` / `Proyecto de Acuerdo N° X` / `N-Otros` | **811** | 96,32 |
| cualquier otra forma | **31** | 3,68 |

Y las 31 restantes son otras tres etiquetas: `3-Creacion Comision Investigadora`,
`2-Acusacion Constitucional`, `4-Informe Comision Investigadora`. **266 descripciones
distintas sobre 842 votaciones**, casi todas el mismo molde con un número dentro.

El otro texto disponible es `articulo`, del nodo `Votaciones` que P-63 rescató:
**629 de 737 filas (85,35 %)** lo traen. Pero ese nodo cuelga del boletín:

> **Votaciones sin boletín cubiertas por `articulo`: 0 de 281 (0,00 %).**

**H4 pasa la letra y falla la sustancia**, y su falsedad es la razón por la que la
vía 4 no se puede medir: no hay texto que clasificar justo donde la vía 4 tenía que
aportar. Medido de todos modos, por si el titular quiere la cifra:

| Vía 4, variante | Cae en algún tema | Denominador |
|---|---|---|
| 4a `descripcion`, universo completo | **16** | 842 votaciones (1,90 %) |
| 4a `descripcion`, solo las sin boletín | **16** | 281 votaciones (5,69 %) |
| 4b `articulo`, filas que lo traen | **499** | 629 filas (79,33 %) |
| 4b `articulo`, sobre el universo de votaciones | **629** | 842 votaciones (74,70 %) |
| 4b `articulo`, sobre las votaciones **sin boletín** | **0** | 281 votaciones (0,00 %) |

Los 16 de 4a son las etiquetas de comisión investigadora y acusación constitucional
pegando contra el tema institucional: es la etiqueta, no el tema del proyecto.

### 5.2 Vía 3 — el léxico sobre el título del proyecto

⚠️ **El léxico de 12 temas usado aquí NO es una taxonomía propuesta.** Es un
instrumento de medición escrito para responder "¿se puede clasificar esto?" y nada
más. La clasificación temática del portal es autoridad del titular.

**Cobertura (universo: 427 boletines, 427 con título no vacío):**

| Qué | n | % |
|---|---|---|
| cae en al menos un tema | **308** | 72,13 |
| cae en más de un tema (ambigüedad) | **115** | 26,93 |
| no cae en ningún tema | **119** | 27,87 |

**Control de sobreajuste.** El 20 % del universo se apartó con semilla 92 **antes** de
escribir el léxico (85 boletines apartados, 342 de trabajo).

| Conjunto | Cae en algún tema | Cobertura |
|---|---|---|
| trabajo (80 %) | 254 / 342 | **74,27 %** |
| apartado (20 %) | 54 / 85 | **63,53 %** |

**Brecha: 10,74 pp**, sobre un umbral declarado antes de 10 pp → **dispara la sospecha
de sobreajuste**. Con n = 85 en el apartado, sin embargo, la brecha **no es
distinguible del ruido**: `prop.test` da χ² = 3,390, gl = 1, **p = 0,0656**, IC 95 %
de la diferencia **[−1,23 ; +22,71] pp**, que contiene el cero. **El control es
inconcluyente a este tamaño de muestra** — no absuelve al léxico ni lo condena.

*Declaración de contaminación honesta:* durante F0 y F1 quedaron a la vista unos 30
títulos (los 5 del patrón de oro y sus hermanos de sufijo). El léxico se escribió con
vocabulario legislativo general, sin ajustarlo a título alguno, pero la contaminación
existe y se declara.

**Control positivo: 3 de 5. Umbral declarado antes: 4 de 5. FALLA.**

| Boletín | Materia oficial | Tema asignado por el léxico | Juicio |
|---|---|---|---|
| `10634-29` | SOCIEDADES ANÓNIMAS DEPORTIVAS | `economia_tributos`, `cultura_deporte_ciencia` | ✅ |
| `10795-33` | SERVICIOS SANITARIOS | `salud` | ❌ *"sanitario" aquí es agua potable y alcantarillado, no salud* |
| `10986-24` | MONUMENTOS; ESCRITOR CHILENO | `cultura_deporte_ciencia` | ✅ |
| `11608-09` | DESALINIZACIÓN DE AGUA | `ambiente_energia` | ✅ |
| `12234-02` | SISTEMA DE INTELIGENCIA DEL ESTADO | `cultura_deporte_ciencia` | ❌ *entra por la palabra "inteligencia", que el léxico tiene por tecnología* |

**Los dos fallos son del mismo tipo: polisemia.** `sanitario` e `inteligencia`
significan cosas distintas en dominios distintos, y un léxico de palabras sueltas no
puede distinguirlas. Esto no se arregla agrandando la lista: se arregla con
desambiguación por contexto, que es otro problema.

**Reparto por tema** (un proyecto puede caer en varios; denominador 427):

| Tema | n | % |
|---|---|---|
| seguridad_delito | 107 | 25,06 |
| institucional_electoral | 68 | 15,93 |
| trabajo_pensiones | 41 | 9,60 |
| derechos_justicia | 37 | 8,67 |
| vivienda_ciudad | 35 | 8,20 |
| educacion | 31 | 7,26 |
| familia_ninez_genero | 30 | 7,03 |
| cultura_deporte_ciencia | 28 | 6,56 |
| economia_tributos | 25 | 5,85 |
| ambiente_energia | 22 | 5,15 |
| salud | 18 | 4,22 |
| agro_pesca_rural | 8 | 1,87 |

---

## 6. F3 — la vía 2 está bloqueada, no ausente

Los 4 intentos de alcanzar `camara.cl` desde R devolvieron **403, 403, 520, 403**, con
cuerpo `<title>Attention Required! | Cloudflare</title>` de 5 836 bytes.

**El control negativo no discrimina, y eso es lo importante.** Se comparó línea a
línea el 403 de la ruta **real** (`votaciones.aspx`) con el de la ruta **fabricada**:

> **3 líneas distintas de 91.** Son el `Cloudflare Ray ID` y el orden del script de
> `cloudflareinsights`. El resto es idéntico.

Es decir: `camara.cl` responde exactamente lo mismo a una ruta que existe y a una que
inventamos. **Reportar esto como "el buscador por Materia no existe" sería un falso
negativo fabricado.** Lo medido es que el cliente está bloqueado.

**H7 queda sin responder.** Lo que el encargo pedía —ejecutar el postback
`link_PorMateria` con `__VIEWSTATE` y `__EVENTVALIDATION`, contar las entradas del
`select` y cruzarlas con las 8 518 materias— **no se hizo**, porque no se pudo llegar
a la página que contiene esos campos.

*Por qué no se buscó otro cliente:* el invariante 🔒 del proyecto declara a R como
único lenguaje en todo contexto, incluida la inspección de solo lectura. Traer un
navegador sin cabeza para saltar un WAF es una decisión de metodología que este
encargo no resolvió, y la regla de detención §3 la reserva al titular. Queda como
pendiente abierto (§9).

---

## 7. F5 — la prueba que decide

### 7.1 Vía elegida, declarada antes de correr la tabla

**La vía 1.** Es la única con cobertura estructural completa (427/427), la única que
supera su control positivo (5/5), y la única cuyo poder discriminante se midió contra
un nulo (p = 0,0010). La vía 2 está bloqueada; la 3 falla su control positivo (3/5) y
tiene el control de sobreajuste inconcluyente; la 4 no tiene insumo.

### 7.2 H5 — mapeo votante → partido → tendencia

| Fuente | Votantes cubiertos | Filas de voto con tendencia |
|---|---|---|
| padrón vigente (`diputados.rds`, 155) | 155 / 239 (64,85 %) | 87 308 / 130 510 (66,90 %) |
| **+ padrón histórico** (`retornarDiputados`, 633) | **239 / 239 (100 %)** | **106 028 / 130 510 (81,24 %)** |
| solo período vigente (fecha ≥ 2026-03-11) | 155 / 155 (100 %) | 68 900 / 82 150 (83,87 %) |

Los 84 votantes que faltaban son del período anterior: **las 244 votaciones de enero
de 2026 tienen votantes fuera del padrón vigente en 244 de 244**, y desde abril de
2026 en 0 de 491. El padrón histórico los recupera a los 84 con militancia declarada
(632 de 633 diputados la traen).

**No mapeados, por causa** (nadie recibe una tendencia inventada):

| Causa | Filas de voto |
|---|---|
| `IND`: sin militancia, no clasificable (decisión del titular, sesión 2) | 23 546 |
| partido histórico fuera de `MAPA_PARTIDO_TENDENCIA`: `AMA` | 312 |
| ídem `LIBERAL` | 312 |
| ídem `PEV` | 312 |

Hay **14 partidos históricos fuera del mapa** (PRI 3 diputados, RD 3, y 12 con 1 cada
uno); solo tres de ellos alcanzan a votar en el corte.

### 7.3 H6 — bancada

**No existe como dato.** 0 nombres de elemento con `banc` entre los 15 del padrón
histórico, 0 columnas en `diputados.rds`, 0 menciones en el catálogo de las 38
operaciones de la API. Se trabaja con partido y tendencia, y se declara.

### 7.4 La tabla `tema × tendencia`

Cobertura de la vía 1 sobre las filas de voto: **86 955 / 130 510 (66,63 %)**; con
sufijo **y** tendencia: **70 422 / 130 510 (53,96 %)**.

**Definición de la tasa:** votos emitidos = `a_favor + en_contra + abstencion`. Se
excluyen `no_vota` y `dispensado`, que son ausencias y no posiciones. `tasa` =
a favor / emitidos. **Ninguna celda se reporta sin su n.**

**Universo completo — 130 celdas, 63 566 votos emitidos.** Tasa de voto a favor (%) y
n por celda, ordenado por volumen:

| Sufijo | Comisión modal (empírica) | izq % | n | c-izq % | n | centro % | n | c-der % | n | der % | n |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 05 | Hacienda | 57,6 | 5 427 | 57,9 | 3 590 | 60,6 | 3 535 | 59,3 | 2 739 | 63,2 | 9 572 |
| 04 | Educación | 79,2 | 2 639 | 83,1 | 1 673 | 70,3 | 1 395 | 42,4 | 1 489 | 30,7 | 4 329 |
| 07 | Constitución | 62,9 | 1 060 | 74,3 | 711 | 76,2 | 739 | 71,9 | 565 | 68,4 | 1 962 |
| 06 | Gobierno Interior | 46,7 | 728 | 56,3 | 501 | 76,1 | 497 | 83,9 | 409 | 80,0 | 1 327 |
| 25 | Seguridad Ciudadana | 73,4 | 658 | 81,4 | 419 | 78,0 | 336 | 57,2 | 334 | 61,7 | 1 039 |
| 14 | Vivienda | 93,2 | 637 | 94,5 | 382 | 75,9 | 328 | 41,8 | 340 | 49,6 | 946 |
| 08 | Minería y Energía | 58,1 | 394 | 70,8 | 260 | 65,4 | 361 | 76,9 | 247 | 74,9 | 837 |
| 13 | Trabajo y Seguridad Social | 71,9 | 442 | 68,7 | 278 | 79,5 | 234 | 79,0 | 243 | 74,5 | 703 |
| 10 | Relaciones Exteriores | 98,7 | 383 | 99,6 | 235 | 99,1 | 230 | 100,0 | 208 | 98,5 | 654 |
| 03 | Economía | 85,7 | 314 | 88,3 | 205 | 68,9 | 183 | 52,1 | 192 | 34,1 | 537 |
| 29 | Deportes y Recreación | 100,0 | 184 | 100,0 | 135 | 100,0 | 175 | 61,1 | 95 | 73,2 | 396 |
| 31 | Desarrollo Social | 91,1 | 135 | 92,2 | 102 | 99,1 | 115 | 59,0 | 83 | 61,9 | 291 |
| 09 | Obras Públicas | 93,5 | 168 | 95,9 | 98 | 86,7 | 45 | 81,7 | 104 | 82,5 | 194 |
| 18 | Familia | 100,0 | 115 | 100,0 | 80 | 100,0 | 105 | 92,7 | 55 | 56,7 | 245 |
| 33 | Recursos Hídricos | 100,0 | 122 | 96,1 | 77 | 97,3 | 74 | 60,7 | 61 | 37,0 | 211 |
| 15 | Obras Públicas | 98,1 | 106 | 80,0 | 60 | 89,2 | 83 | 28,2 | 39 | 96,9 | 162 |
| 12 | Agricultura | 77,8 | 90 | 66,7 | 27 | 78,6 | 14 | 61,3 | 31 | 25,7 | 187 |
| 19 | Futuro | 73,0 | 89 | 80,6 | 62 | 79,7 | 79 | 74,5 | 47 | 68,5 | 197 |
| 24 | Cultura | 100,0 | 72 | 100,0 | 68 | 100,0 | 59 | 100,0 | 55 | 47,8 | 113 |
| 02 | Defensa Nacional | 59,2 | 49 | 100,0 | 48 | 100,0 | 37 | 35,9 | 39 | 100,0 | 66 |
| 17 | Derechos Humanos | 61,2 | 49 | 93,5 | 31 | 91,7 | 12 | 100,0 | 36 | 45,2 | 62 |
| 11 | Salud | 100,0 | 27 | 100,0 | 16 | 100,0 | 6 | 100,0 | 18 | 100,0 | 31 |
| 22 | Emergencia | 100,0 | 23 | 100,0 | 17 | 100,0 | 21 | 100,0 | 12 | 100,0 | 50 |
| 34 | Mujeres y Equidad de Género | 100,0 | 23 | 100,0 | 17 | 100,0 | 22 | 100,0 | 12 | 100,0 | 50 |
| 35 | Personas Mayores y Discapacidad | 100,0 | 23 | 66,7 | 15 | 95,5 | 22 | 100,0 | 12 | 100,0 | 49 |
| 37 | Cultura | 4,5 | 22 | 100,0 | 17 | 100,0 | 21 | 100,0 | 13 | 100,0 | 47 |

### 7.5 Prueba de no degeneración — **PASA**

**Declarada antes de correrla:** el eje sirve si existe al menos un tema donde la
diferencia de tasa de aprobación entre las dos tendencias extremas (izquierda y
derecha) supere **20 puntos porcentuales**, con **al menos 100 votos en cada celda**.

**Precisión del criterio, porque cambia el resultado:** se evalúa sobre el **valor
absoluto** de la brecha, `|tasa_derecha − tasa_izquierda| > 20`. Es la lectura natural
de "la diferencia supere 20 puntos" (una brecha de −63 pp *es* una diferencia de 63
puntos), pero conviene decirlo: **con el criterio signado (`brecha > 20`, es decir,
solo donde la derecha aprueba más), cumplirían 1 sufijo en el universo completo y 4 en
el período vigente, no 8.** Las tablas de abajo muestran el signo en todos los casos
para que el titular pueda aplicar el criterio que prefiera.

**Universo completo: 16 de 26 sufijos tienen n ≥ 100 en ambas celdas extremas; 8 de
ellos superan los 20 pp en valor absoluto.** Brecha máxima: **63,0 pp**, sufijo 33.

| Sufijo | Comisión modal (empírica) | izq % (n) | der % (n) | Brecha (der − izq) |
|---|---|---|---|---|
| 33 | Recursos Hídricos y Desertificación | 100,0 (122) | 37,0 (211) | **−63,0** |
| 03 | Economía | 85,7 (314) | 34,1 (537) | **−51,6** |
| 04 | Educación | 79,2 (2 639) | 30,7 (4 329) | **−48,5** |
| 14 | Vivienda | 93,2 (637) | 49,6 (946) | **−43,6** |
| 18 | Familia | 100,0 (115) | 56,7 (245) | **−43,3** |
| 06 | Gobierno Interior | 46,7 (728) | 80,0 (1 327) | **+33,3** |
| 31 | Desarrollo Social | 91,1 (135) | 61,9 (291) | **−29,2** |
| 29 | Deportes y Recreación | 100,0 (184) | 73,2 (396) | **−26,8** |

**Período vigente (fecha ≥ 2026-03-11): 13 de 22 sufijos con n ≥ 100 en ambas celdas;
8 superan los 20 pp.** Brecha máxima: **44,0 pp**, sufijo 03.

| Sufijo | Comisión modal (empírica) | izq % (n) | der % (n) | Brecha |
|---|---|---|---|---|
| 03 | Economía | 72,4 (163) | 28,4 (345) | **−44,0** |
| 18 | Familia | 100,0 (115) | 56,7 (245) | **−43,3** |
| 05 | Hacienda | 35,6 (3 190) | 74,9 (6 799) | **+39,3** |
| 06 | Gobierno Interior | 43,8 (395) | 83,1 (860) | **+39,3** |
| 13 | Trabajo y Seguridad Social | 48,9 (190) | 87,9 (404) | **+39,0** |
| 29 | Deportes y Recreación | 100,0 (184) | 73,2 (396) | **−26,8** |
| 25 | Seguridad Ciudadana | 56,9 (255) | 81,3 (546) | **+24,4** |
| 31 | Desarrollo Social | 88,6 (105) | 66,7 (261) | **−21,9** |

### 7.5.1 ⚠️ El "universo completo" agrega dos Cámaras distintas, y eso distorsiona

**Esta advertencia la levantó el panel adversarial (§10) y corrige una lectura
demasiado benigna de la versión previa de este documento.**

El universo completo mezcla el período legislativo anterior (23 075 votos emitidos,
hasta el 2026-03-10) con el vigente (40 491, desde el 2026-03-11). Son dos
composiciones de la Cámara y dos agendas. Consecuencia medida: **de los 9 sufijos
elegibles en ambos tramos, 4 cambian de signo de brecha.** El caso extremo es el
sufijo **05 (Hacienda): −54,4 pp antes y +39,3 pp después**, que al agregarse se
cancelan a **+5,6 pp** y lo dejan clasificado como "no cumple" cuando en ambos tramos
por separado la brecha es enorme. Y al revés: el sufijo **33, que sostiene la brecha
máxima de 63,0 pp del universo completo, no es elegible en el tramo vigente** por
falta de n.

**Consecuencia para la lectura:** la tabla del **período vigente es la
interpretable**; la del universo completo es aritméticamente correcta pero sus
magnitudes no deben leerse como propiedades del eje. Los 63,0 pp del sufijo 33 en
particular **no** son una propiedad del eje temático.

**El eje no es políticamente mudo.** En el período vigente, Economía, Familia,
Hacienda, Gobierno Interior y Trabajo separan a izquierda y derecha entre 39 y 44
puntos, con hasta 6 799 votos en una celda. La pregunta del titular tiene respuesta
con esta vía.

**Robustez** (verificada por el panel, §10): el veredicto PASA no depende de dos
decisiones metodológicas que se podrían haber tomado al revés. Sin el padrón
histórico, cumplen 7 sufijos y PASA igual. Contando `no_vota` y `dispensado` como
votos emitidos, cumplen 7 y PASA igual.

### 7.6 Cuánto aporta lo que la vía 4 no pudo cubrir

**281 de 842 votaciones (33,4 %) no tienen boletín**, y son **43 555 de 130 510 filas
de voto (33,37 %)**. Ese bloque queda **entero fuera del eje**: no se clasifica mal,
no se puede clasificar.

Tasa global de voto a favor, dentro y fuera del eje:

| Bloque | izq | c-izq | centro | c-der | der |
|---|---|---|---|---|---|
| **con** boletín (dentro del eje) | 69,1 % (n=13 979) | 72,2 % (9 124) | 71,1 % (8 728) | 60,8 % (7 478) | 59,5 % (24 257) |
| **sin** boletín (fuera del eje) | 69,7 % (5 853) | 75,5 % (3 681) | 72,3 % (4 068) | 67,4 % (3 281) | 62,7 % (10 825) |

Las resoluciones se aprueban algo más que los proyectos de ley en las cinco
tendencias, con la brecha izquierda-derecha ligeramente **menor** fuera del eje (7,0
pp) que dentro (9,6 pp). Es decir: el bloque perdido no es un bloque políticamente
neutro, pero tampoco es donde más se separan las facciones en el agregado. **Su
pérdida es de cobertura, no de señal.**

---

## 8. Recomendación al titular — opciones abiertas, no una decisión

**Lo que el sondeo establece:** la vía 1 funciona como eje temático y responde la
pregunta política; su único defecto es que el código no tiene nombre oficial y que
deja fuera un tercio de las votaciones.

Cuatro caminos, no excluyentes:

1. **Publicar la vía 1 con el código desnudo y la comisión modal como atributo
   medido**, rotulado explícitamente como derivación del proyecto y no como dato de
   la fuente. Costo: cero llamadas nuevas, es todo dato que ya está en disco. Riesgo:
   el 8,51 % de boletines cuya comisión difiere de la modal quedan mal etiquetados si
   la etiqueta se presenta como verdad.
2. **Pedir la glosa a la fuente por fuera de la API.** El catálogo existe en el mundo
   (los boletines se numeran por algo), pero no está publicado en ninguna de las 12
   superficies sondeadas. Un oficio o una consulta a la Cámara lo resolvería, y es una
   gestión del titular, no del pipeline.
3. **Desbloquear la vía 2.** `camara.cl` está tras Cloudflare para un cliente R. Si el
   titular autoriza otro cliente, H7 se responde y con ella si existe un catálogo
   cerrado de materias por votación — que sería la única vía que cubre las 281
   votaciones sin boletín. **Es la decisión de metodología con mayor retorno.**
4. **Ampliar el universo de proyectos con `retornarMensajesXAnno`.** Hoy el pipeline
   solo extrae mociones; los mensajes del Ejecutivo (52 en 2026) están fuera. No es
   una vía temática, pero afecta el denominador de todas.

**Lo que este sondeo recomienda no hacer:** publicar la vía 3. Su control positivo
falla por polisemia (`sanitario`, `inteligencia`), y un léxico de palabras sueltas
autoría del pipeline sería, además, una taxonomía sin autoridad.

---

## 9. Panel adversarial

Dos agentes de solo lectura, con **código propio**, sin acceso a los scripts del
sondeo (la instrucción se los prohibió explícitamente, para no heredar sus puntos
ciegos), sin red y sin permiso de escritura. Ambos corrieron y ambos entregaron
resultado: **las afirmaciones de abajo están verificadas por panel, no por primera
parte.**

### 9.1 Panel A — cobertura de la vía ganadora sobre las filas de voto

| Cifra | Sondeo | Panel A | ¿Coincide? |
|---|---|---|---|
| filas de voto con sufijo | 86 955 / 130 510 (66,63 %) | 86 955 / 130 510 | **sí** |
| filas con sufijo **y** tendencia | 70 422 / 130 510 (53,96 %) | 70 422 / 130 510 | **sí** |
| filas con tendencia (universo) | 106 028 / 130 510 (81,24 %) | 106 028 / 130 510 | **sí** |
| votantes distintos / en padrón / con militancia | 239 / 155 / 239 | 239 / 155 / 239 | **sí** |

Ambigüedades que el panel resolvió y que conviene dejar por escrito: **0 boletines con
más de un guion y 0 con cadena vacía**, así que el sufijo es unívoco bajo cualquiera
de las tres definiciones posibles; y existe **un solo empate** de `FechaInicio` máxima
en el padrón histórico (id 1180, alias `FA` e `IND` el mismo día), que no afecta a
ninguna cifra porque ese diputado está en el padrón vigente y nunca cae en la rama
histórica. **0 votantes fuera del padrón vigente tienen empate.**

### 9.2 Panel B — prueba de no degeneración

Las **6** cifras reproducen: 16 sufijos elegibles, 8 que cumplen, brecha máxima 63,0 pp
en el sufijo 33, veredicto PASA, 63 566 votos emitidos en la tabla; y en el período
vigente, 8 que cumplen con máximo 44,0 pp en el sufijo 03 y veredicto PASA.

**Control adversarial de barajado** (el que demuestra que la prueba puede dar rojo):
barajando la etiqueta de tendencia entre filas de voto, **0 de 20 barajados producen un
solo sufijo que cumpla**, y la brecha máxima colapsa de 63,0 a 6,0 pp. El panel agregó
por su cuenta un barajado **a nivel de diputado**, que preserva el agrupamiento de cada
legislador y es un nulo más exigente: también **0 de 20**.

**Dos observaciones del panel se incorporaron al cuerpo de este documento:** la
precisión sobre el valor absoluto en el criterio (§7.5) y el artefacto de agregar dos
composiciones de la Cámara (§7.5.1). La segunda cambia la lectura del resultado y es
la contribución más valiosa del panel.

---

## 10. Pendientes abiertos

- `# REVISAR` **H7 sin responder.** El postback `link_PorMateria` no se ejecutó:
  Cloudflare bloquea al cliente R. Requiere decisión del titular sobre el cliente.
- `# REVISAR` **No existe catálogo oficial código → glosa del sufijo** en las 12
  superficies sondeadas. El sufijo es publicable como código, no como nombre.
- `# REVISAR` **El control de sobreajuste de la vía 3 es inconcluyente** (n = 85,
  p = 0,0656). Si alguna vez se retoma la vía 3, el apartado debe ser mayor.
- `# REVISAR` **`camara.cl` es una fuente frágil por diseño.** Es HTML raspado, no
  API: cambia sin aviso y sin versión. Cualquier vía que dependa de él hereda esa
  fragilidad y hay que decirlo en el portal.
- `# REVISAR` **14 partidos históricos fuera de `MAPA_PARTIDO_TENDENCIA`.** Tres de
  ellos (AMA, LIBERAL, PEV) aportan 936 filas de voto sin tendencia. Clasificarlos es
  decisión metodológica del titular.
- `# REVISAR` **`sentido == "dispensado"` tiene 33 filas en todo el corte.** No se
  investigó su semántica; se excluyó de las tasas junto con `no_vota`.
- `# REVISAR` **Las muestras de comisiones van redactadas.** `retornarComisionesXPeriodo`
  devuelve correos y teléfonos por comisión (91 correos `@congreso.cl`, 137 teléfonos)
  y este repositorio es público, así que se redactaron 394 campos en 3 archivos
  siguiendo el criterio que el propio proyecto fijó en `50_catalogo_fuentes_camara.md`
  §6. Detalle y md5 originales en `50_documentacion/andamios/muestras/p92/LEEME_redaccion.md`.
  **Si el titular prefiere el criterio contrario, la decisión es suya y se revierte
  volviendo a correr `50_sondeo_p92_f2.R`.**
