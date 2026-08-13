# Veredicto — ¿LeyChile o `datos.bcn.cl` cierran el hueco temático?

> Producto del encargo `50_documentacion/andamios/50_encargo_p68_sondeo_leychile_bcn.md`
> (P-68, sesión 20, 2026-08-13). Bitácora de la corrida, compuerta por compuerta:
> `50_documentacion/andamios/logs/20260813_p68_sondeo_log.md`.
>
> **Sondeo de solo lectura.** No tocó `30_procesamiento/`, `10_utils/`,
> `00_run_all.R` ni `docs/`; no escribió un byte bajo `20_insumos/camara/` ni bajo
> `40_salidas/`; no propone contrato de datos. **43 llamadas HTTP sobre un
> presupuesto declarado de 500.**
>
> **Este documento incorpora el lote de consultas de estructura Q1-Q5**, pedido por
> el titular después del cierre de las compuertas. Q2 mostró que el camino
> interrogado por G5 era minoritario, y Q5 volvió a medir por el camino correcto
> sobre el universo completo. **El veredicto no cambió; su evidencia sí, y aquí
> está la versión corregida.**
>
> Origen: paso 7 del plan de construcción de `50_veredicto_eje_tematico.md` —
> *"antes de cualquier promesa temática, medir si LeyChile o `datos.bcn.cl` tienen
> materias para los boletines sin ellas. Si la respuesta es sí, el veredicto de
> este documento cambia"*.

---

## 1. Veredicto

# NO

**Ninguna de las dos fuentes de la BCN da vuelta el veredicto del eje temático.**
LeyChile queda cerrada por techo medido; `datos.bcn.cl` queda cerrada por dos
razones independientes: **falla el control positivo** (3 de 5, se exigían 5 de 5),
y **la medición por el camino portador correcto sobre el universo completo da cero**
— 0 de 422 boletines sin materia, 0 de 336 de la cohorte 2026 (§4.4).

Que sean dos razones importa: la primera, por sí sola, solo permitía declarar la
cobertura *inverificable*. La segunda la mide y da 0.

**Este sondeo NO refuta el veredicto vigente: confirma su hipótesis B desde el
otro lado.** Si la materia llega con la promulgación y no con el tiempo, entonces
las fuentes que indexan lo promulgado cubren **"lo legislado"** y no **"lo que se
vota este año"** — y eso es exactamente lo que las dos ramas midieron, cada una
por su cuenta.

**P-68 cierra con "no", y ese "no" fija el alcance de P-66:** el contrato de datos
de la entidad `proyecto` se diseña **sin** eje de materias y **con**
`cobertura_materias` explícito, como el veredicto vigente ya proponía. No lo
cancela: lo acota.

---

## 2. El universo de este sondeo, contado hoy

Todas las cifras de este documento se declaran sobre **este** universo, medido en
la corrida y no heredado de ningún documento.

| Magnitud | Valor | Origen |
|---|---|---|
| **Boletines totales** | **427** | Captura cruda `20260812_detalle_proyectos_xml_2026_tope-inf.rds`, corte **2026-08-12** |
| **Con al menos una materia** | **5 (1,17 % de 427)** | ídem |
| **Sin ninguna materia** ← universo objetivo | **422 (98,83 % de 427)** | ídem |
| **Sin materia, cohorte 2026** | **336 (79,62 % de 422)** | ídem, año de `FechaIngreso` |
| Nodo `<Materias>` presente | **427 de 427** | ídem |

⚠️ **Antecedente, nunca denominador.** El veredicto vigente reportó 381 boletines,
5 con materia y 376 sin, al corte **2026-08-03**. Esas cifras se citan aquí solo
como antecedente histórico. **El denominador de este documento es 427 / 422 / 336.**

**Nota de procedencia.** El intermedio `40_salidas/intermedios/proyectos_detalle.rds`
está sellado al 2026-08-03 mientras `CORTE_FECHA` es 2026-08-12, así que el universo
se midió sobre la captura cruda del corte vigente —los mismos bytes de los que la
guarda del pipeline reconstruiría el intermedio— para no escribir bajo `40_salidas/`.
Control de esa desviación: el parser propio del sondeo reproduce a
`parsear_contenido_proyecto()` en **381 de 381** boletines comunes, con `n_materias`
idéntico y 0 boletines presentes en el intermedio y ausentes de la captura.

---

## 3. Rama **LeyChile**: CERRADA por techo

LeyChile responde: `https://www.bcn.cl/leychile/consulta/obtxml?opt=7&idNorma=…`
devolvió **HTTP 200**, `text/xml`, 561 407 bytes, raíz **`Norma`**. La rama no se
cerró por falta de fuente.

**Se cerró porque indexa normas publicadas, y casi nada de este universo lo es.**

| # | Fracción que llegó a ser ley | Valor | Denominador |
|---|---|---|---|
| **(a)** | Sobre los boletines sin materia | **18 = 4,27 %** | **422 boletines sin materia**, corte 2026-08-12 |
| **(b)** | Sobre la cohorte 2026 | **4 = 1,19 %** | **336 boletines sin materia de cohorte 2026**, corte 2026-08-12 |

Por cohorte, cada una con su denominador:

| Cohorte | 2020 | 2021 | 2022 | 2023 | 2024 | 2025 | **2026** | Total |
|---|---|---|---|---|---|---|---|---|
| Sin materia | 1 | 2 | 6 | 7 | 32 | 38 | **336** | **422** |
| Es ley | 1 | 0 | 2 | 1 | 5 | 5 | **4** | **18** |
| % | 100 | 0 | 33,33 | 14,29 | 15,62 | 13,16 | **1,19** | **4,27** |

**El umbral y su resultado.** El techo de esta rama sobre la cohorte 2026 —**1,19 %
de 336**— es indistinguible del piso que el portal ya tiene (**1,17 %**, 5 de 427).
Aun suponiendo que LeyChile entregara descriptor temático para **todos** sus
aciertos —supuesto generoso que este sondeo no midió y que no hizo falta medir—, el
eje temático de 2026 pasaría de 0 a **4 proyectos sobre 336**. **No se escribió
extractor.**

**Cómo se midió el vínculo, y por qué es creíble.** El censo no fue una llamada por
boletín: `datos.bcn.cl` modela `bcn-resources:ProyectoDeLey` (19 181 instancias) con
la URI **construida desde el boletín**
(`http://datos.bcn.cl/recurso/cl/proyecto-de-ley/<boletin>`), y expone
`bcn-norms:leychileCode` (2 549 tripletas) como vínculo a la norma. **Control
positivo del vínculo: 5 de 5 boletines con materia están en el grafo y 4 de 5
traen `leychileCode`**, que reproduce exactamente lo que el veredicto vigente midió
por el SIL.

**Confirmador independiente de `leychileCode`, medido después.** La primera versión
de este documento dejó `leychileCode` como proxy validado solo sobre n = 5 y con
`publishDate` vacío. Los 4 códigos se pidieron a LeyChile por la vía que abrió G3:

| `leychileCode` | HTTP | Raíz | Fecha de publicación | Norma |
|---|---|---|---|---|
| 1224810 | 200 | `Norma` | 2026-06-06 | Ley 21824 |
| 1223368 | 200 | `Norma` | 2026-04-21 | Ley 21814 |
| 1223983 | 200 | `Norma` | 2026-05-12 | Ley 21813 |
| 1224631 | 200 | `Norma` | 2026-05-30 | Ley 21821 |

**4 de 4 resuelven a una `<Norma>` real, con número de ley y fecha de publicación**,
confirmados por una fuente distinta de la que afirmaba el vínculo. La lectura de
`leychileCode` como "llegó a ser ley" **ya no es un proxy sin confirmar**. El grafo
expone además `bcn-norms:promulgationDate` (529 980 tripletas) como confirmador
adicional disponible.

Salvedad que se mantiene: la clase dominante de los sujetos con `leychileCode` es
`Norm`/`Document` (748 783), no `ProyectoDeLey` (2 547) — lo cual es lo esperado,
porque el código identifica una norma. G4 no preguntó cuántos sujetos lo tienen,
sino si **este recurso `proyecto-de-ley/<b>`** lo lleva; el sujeto interrogado era
el correcto para esa pregunta.

---

## 4. Rama **`datos.bcn.cl`**: CERRADA por control positivo fallido

El endpoint responde: `https://datos.bcn.cl/sparql` devolvió **HTTP 200**,
`application/sparql-results+json`, resultado bien formado con `head` y `results`
(motor Virtuoso). La rama tampoco se cerró por falta de fuente.

**Se cerró porque no reproduce los boletines cuya materia ya conocemos.**

### 4.1 Control positivo: 3 de 5, por los dos caminos

`bcn-resources:tieneMateria` existe con **21 274 tripletas**. Sobre los 5 boletines
que **sí** traen materia en la Cámara, interrogada por **dos caminos**: colgando
del propio `ProyectoDeLey` (camino directo) y colgando de cualquier recurso a un
salto del proyecto, en cualquiera de las dos direcciones (camino indirecto).

| Boletín | Cohorte | ¿Lo encuentra? | Temas, camino **directo** | Temas, **a un salto** | Materias en la Cámara |
|---|---|---|---|---|---|
| 10634-29 | 2016 | sí | 0 | **2** (vía `MocionParlamentaria`) | 2 |
| 10795-33 | 2016 | sí | 2 | 0 | 2 |
| 10986-24 | 2016 | sí | 4 | 0 | 4 |
| 11608-09 | 2018 | sí | **0** | **0** | 2 |
| 12234-02 | 2018 | sí | **0** | **0** | 1 |

| Magnitud | Valor | Denominador |
|---|---|---|
| El grafo lo encuentra | **5 = 100 %** | **5 boletines con materia**, corte 2026-08-12 |
| Devuelve descriptor por el camino directo | **2 = 40 %** | **5 boletines con materia**, corte 2026-08-12 |
| **Devuelve descriptor por alguno de los dos caminos** | **3 = 60 %** | **5 boletines con materia**, corte 2026-08-12 |
| Coinciden **por id** con la Cámara | **0** | **11 materias** de esos 5 boletines |
| Coinciden por texto o por slug, camino directo | **6** | **11 materias** de esos 5 boletines |
| Coinciden por texto, camino a un salto | **1** | **11 materias** de esos 5 boletines |

⚠️ **Corrección de una versión previa de este documento.** La primera redacción
declaró **2 de 5**, porque solo se había interrogado el camino directo. Q2 mostró
que ese camino es el minoritario (§4.3) y Q4 volvió a medir a un salto: la cifra
correcta es **3 de 5**. **El criterio exigía 5 de 5, así que el control falla
igual** — pero la cifra y la evidencia son estas, no aquellas.

**El encargo fijó la consecuencia antes de medir:** *"si el control positivo falla,
cualquier cobertura que la fuente reporte sobre el resto es inverificable, y así se
declara: no se publica como cobertura"*. Falla. **Por eso M2 y M3 no se corrieron:
no quedaron pendientes, quedaron bloqueadas.**

### 4.3 Hallazgo estructural: el camino de G5 no era el principal

**`tieneMateria` cuelga sobre todo de otras clases, no de `ProyectoDeLey`.** Sujetos
distintos por clase (49 clases; las primeras):

| Clase portadora | Sujetos |
|---|---|
| `bcn-resources#SeccionRecurso` | **85 924** |
| `bcn-resources#Participacion` | 38 324 |
| `bcn-resources#IntervencionPeticionDeOficio` | 16 841 |
| `bcn-sessiondaily#SeccionProyectoDeLey` | 13 308 |
| `bcn-resources#TramitacionProyectoDeLey` | 12 975 |
| `bcn-resources#MocionParlamentaria` | 9 817 |
| **`bcn-resources#ProyectoDeLey`** | **5 830** |

El camino que interrogó el control positivo —`tieneMateria` colgando del propio
`ProyectoDeLey`— es la **12ª clase por volumen**, con **5 830 de 19 181** proyectos.
**Se midió por un portador que no es el principal.** Eso obligó a la medición de
§4.4, que es la que interroga el camino correcto sobre el universo entero.

### 4.4 La medición por el camino correcto, sobre los 422: **cero**

Cobertura por los tres portadores que §4.3 reveló, a un salto del proyecto,
filtrando por tipo del intermediario (sin suponer ningún nombre de relación) y con
`COUNT(DISTINCT ?tema)` agregado en el servidor:

| Portador | Sobre los **422 boletines sin materia** | Sobre los **336 de cohorte 2026** |
|---|---|---|
| `MocionParlamentaria` | **0 = 0 %** | **0 = 0 %** |
| `TramitacionProyectoDeLey` | **0 = 0 %** | **0 = 0 %** |
| `SeccionProyectoDeLey` | **0 = 0 %** | **0 = 0 %** |
| **UNIÓN de los tres** | **0 = 0 %** | **0 = 0 %** |

**Y 0 en las siete cohortes**, de 2020 a 2026, cada una sobre su denominador.

**Un cero no se reporta sin control.** Un 0 sobre 422 tiene dos explicaciones
incompatibles —cobertura nula o consulta rota—, así que la **misma consulta** se
corrió contra los 5 con materia: devolvió **2 temas para 10634-29 vía
`MocionParlamentaria`**, los mismos que §4.1 encontró a un salto. **La consulta está
viva y el cero es medición.** Guarda adicional: la unión (0) no supera el techo por
presencia (272 de 422); si lo superara habría error de denominador y la fase se
detiene sola.

**El hallazgo estructural de §4.3 era real, y aun así no rescata la cobertura.**

### 4.2 Dos matices que no conviene perder

**El fallo es de cobertura de proyectos, no de fidelidad del descriptor.** Las 6
materias de los **2** boletines que sí respondieron quedan cubiertas **6 de 6** por
texto o slug. Donde BCN contesta, contesta bien; el problema es que contesta para 2
de 5.

**El vocabulario no es el de la Cámara: 0 de 11 por id.** La Cámara usa enteros de
un catálogo de 8518; BCN usa URIs con slug (`.../recurso/tema/servicios-sanitarios`).
Un eje temático que mezclara ambos estaría **mezclando dos vocabularios sin
decirlo**. Y el descriptor no es uniformemente una materia legislativa: de los 6
temas devueltos, **3 están tipados `bcn-resources:Materia`**, 1 solo como
`frbr:Subject` + `EntidadTemporal`, y **2 no tienen ninguna tripleta como sujeto**.

---

## 5. Techo por presencia: es un techo, no una cobertura

**Distinción que el lector no debe perder.** Lo que sigue **no** es cobertura
temática medida: es el máximo que la cobertura podría alcanzar si cada boletín
presente en el grafo trajera descriptor, cosa que §4.1 muestra que no ocurre.

| Universo | Presentes en el grafo BCN | **Techo duro** |
|---|---|---|
| Sin materia, cohorte 2026 | 186 | **55,36 % de 336 boletines sin materia de cohorte 2026** |
| Todos los sin materia | 272 | **64,45 % de 422 boletines sin materia** |

**150 de los 422 no están en el grafo, y los 150 son de la cohorte 2026.** Es rezago
de indexación del año en curso: cohortes 2020-2025 están al 100 %.

---

## 6. Estatuto de lo que NO se midió

**Un lector futuro debe poder distinguir "medido y bajo" de "no medido".** Esta
sección existe para eso.

| Medición | Estado | Por qué |
|---|---|---|
| **M1** — censo del vocabulario temático de la fuente | **NO CORRIDA** | Decisión de alcance: con el control positivo fallido, la cardinalidad del catálogo no cambia el veredicto |
| **M2** — cobertura sobre muestra aleatoria estratificada de los sin materia | **BLOQUEADA, y luego superada** | El control positivo falló, así que la muestra quedó bloqueada. **§4.4 midió después algo más fuerte: el universo completo (422), no una muestra**, por los portadores correctos |
| **M3** — extensión al universo completo | **CUBIERTA por §4.4** | No como M3 del encargo, sino por la vía que Q2 hizo necesaria: 422 de 422 interrogados, cobertura 0 |
| **M4** — naturaleza del descriptor (¿mismo tesauro o vocabulario ajeno?) | **RESPUESTA PARCIAL, medida** | No se corrió como medición propia, pero §4.1 y el panel P3 la responden sobre los 6 temas observados: **0 de 11 por id** y **3 de 6** tipados como `Materia` |
| Bloque `<Metadatos>` del XML de LeyChile | **NO INSPECCIONADO** | Instrucción del titular: era candidato de M4 y solo importaba si el techo de G4 lo justificaba. No lo justifica |
| Cobertura temática de LeyChile sobre sus 18 aciertos | **NO MEDIDA** | Innecesaria: aun al 100 % el techo sobre 2026 sería 4 de 336 |
| **46 de las 49 clases portadoras de `tieneMateria`** | **NO MEDIDAS sobre el universo** | §4.4 midió las 3 que el titular nombró como portadores de proyecto. Las de mayor volumen son entidades de sesión y de intervención, no de proyecto. Queda anotado en §7.2 como refutación posible |

**Ninguna de estas ausencias se compensa con una estimación.** Lo no medido se
declara no medido.

---

## 7. Qué mediría alguien que quisiera refutar este veredicto

### 7.1 La refutación principal: **corrida en esta sesión, y no refuta**

`bcn-resources:tieneTerminoLibre` era la candidata: **24 840 tripletas**, **más que
las 21 274 de `tieneMateria`**. Una versión previa de este documento la dejó
"nombrada y no corrida". **Se corrió.**

| Boletín | ¿Lo encuentra? | Términos libres | Materias en la Cámara |
|---|---|---|---|
| 10634-29 | sí | 0 | 2 |
| 10795-33 | sí | 2 | 2 |
| 10986-24 | sí | 0 | 4 |
| 11608-09 | sí | 0 | 2 |
| 12234-02 | sí | 0 | 1 |

**Devuelve término libre en 1 de 5** —peor que las 2 de 5 del camino directo de
`tieneMateria`— y el cotejo contra las 11 materias da **0 por id, 0 por texto y 0
por slug**. **La propiedad con más tripletas del grafo no refuta el veredicto: lo
refuerza.**

La segunda candidata de esa lista, `tieneMateria` por sus portadores reales, también
se corrió: es §4.4, y dio **0 sobre 422**.

### 7.2 Lo que sigue abierto para un refutador futuro

**Barata: volver a medir el techo por presencia en un corte posterior.** El 55,36 %
de la cohorte 2026 es rezago de indexación, no ausencia estructural. Repetir el
censo **cuesta 9 llamadas** y dice si el grafo alcanza al año en curso o si el rezago
es permanente. Se puede correr en cualquier refresh futuro.

**Media: los portadores que este sondeo NO interrogó.** §4.3 listó 49 clases
portadoras de `tieneMateria`; §4.4 midió tres. Las de mayor volumen —`SeccionRecurso`
(85 924) y `Participacion` (38 324)— **no se midieron sobre el universo**, porque no
son entidades de proyecto sino de sesión y de intervención. Si alguna resultara
alcanzable desde el boletín y portara materia del proyecto, la cobertura cambiaría.
Cuesta 9 llamadas por portador.

**Cara: el SIL, boletín por boletín.** 422 llamadas para contrastar la condición de
ley publicada contra una fuente distinta de `leychileCode`. Este sondeo la declaró
como plan B y no la gastó: el censo agregado la hizo innecesaria, y §3 la confirmó
por otra vía con 4 de 4.

---

## 8. Advertencia técnica para cualquier trabajo futuro contra `datos.bcn.cl`

**Virtuoso omite la fila de un sujeto que no existe.** Una consulta de la forma

```sparql
SELECT ?s ?x WHERE { VALUES ?s { <a> <b> <c> } OPTIONAL { ?s <prop> ?x } }
```

**no** devuelve una fila por cada valor de `VALUES` con los `OPTIONAL` vacíos:
devuelve filas **solo** para los sujetos que aparecen en alguna tripleta. Un sujeto
inexistente **desaparece de la respuesta**.

**Consecuencia práctica: agregar sobre lo devuelto en vez de sobre lo pedido infla
la cobertura en silencio.** En este sondeo el defecto apareció **tres veces** —en el
censo de los 422, en el cotejo de etiquetas y en el tipado de temas— y las tres
fueron atrapadas por un `stopifnot()` de cuadre de sumas, no por inspección. La
primera vez censó 272 de 422 y reportó la fracción de la cohorte 2026 como
**4 de 186 = 2,15 %** en vez de **4 de 336 = 1,19 %**: el numerador correcto con el
denominador equivocado.

**Regla para el próximo:** reconciliar siempre contra la lista **pedida**, y cerrar
cada agregación con un cuadre de sumas que aborte si no da.

**Y una segunda, del control negativo:** como la URI del recurso se **construye**
desde el boletín, un identificador inventado produce una URI sintácticamente
válida. Combinado con la omisión anterior, eso hace que **"no está" y "está vacío"
se lean igual** si no se prueban identificadores falsos. Aquí se probaron **7** y
devolvieron **0** con apariencia de dato, así que la distinción quedó establecida
por medición.

---

## 9. Qué cambia y qué no en el veredicto vigente

| Afirmación de `50_veredicto_eje_tematico.md` | Estado tras P-68 |
|---|---|
| El eje temático no es construible con las fuentes disponibles | **Confirmada, y ahora también contra las dos fuentes de la BCN** |
| Hipótesis B (la materia llega con la tramitación, no con el tiempo) | **Reforzada desde el otro lado**: las dos ramas cubren lo promulgado y no lo que se vota este año |
| Hipótesis A (gradiente temporal de indexación) | **No descartada**; el rezago de presencia del grafo en 2026 es compatible con ella |
| Ausencia de backfill rápido (0 de 64 boletines nuevos con materia) | **Extendida**: ahora **0 de 110** boletines nuevos acumulados desde el 2026-07-06, y el conjunto con materia sigue siendo el mismo |
| Cobertura `proyecto → materia` de 5 de 381 (1,31 %) | **Sustituida por 5 de 427 (1,17 %)** al corte 2026-08-12. El cambio es del denominador, no del numerador |
| Recomendación de publicar `cobertura_materias` explícito | **Sin cambio, y ahora con más razón** |

---

## 10. Criterios de éxito del encargo (§6)

| # | Criterio | Estado | Evidencia |
|---|---|---|---|
| C1 | G1 corrió con el fusible armado y no se disparó | **CUMPLE** | Exit code **0**; el reproductor además imprime *funciones de descarga del pipeline visibles: 0* |
| C2 | Todo denominador fue contado en esta corrida | **CUMPLE** | 427 / 422 / 336 / 5 / 11 / 51 / 22, cada uno con el paso que lo produjo, en la bitácora |
| C3 | 0 respuestas no-200 persistidas | **CUMPLE** | 43 de 43 son HTTP 200; **0** no-200, y **0** de ellas con archivo |
| C4 | Una fila de manifiesto por llamada, y total = contador | **CUMPLE** | **43 filas = 43 llamadas**, `n` consecutivos sin hueco, dos recuentos independientes |
| C5 | Control positivo resuelto en los dos sentidos, con su cifra | **CUMPLE** | Encuentra **5 de 5**; devuelve descriptor **3 de 5** por camino directo o a un salto (2 directo + 1 a un salto). Tablas en §4.1 y en la bitácora |
| C6 | Control negativo con 0 falsos positivos | **CUMPLE** | **7** identificadores inventados, **0** con apariencia de dato. Y un segundo control, de la propia consulta de §4.4, que devuelve 2 temas para 10634-29 y por eso valida sus ceros |
| C7 | El presupuesto de red no se excedió | **CUMPLE** | **43 de 500**; 457 disponibles |
| C8 | `20_insumos/camara/` intacto | **CUMPLE** | **51 archivos**, md5 agregado `687f75a…d285` idéntico al de G0, listado línea por línea idéntico |
| C9 | 0 archivos fuera de las rutas declaradas en §3 | **CUMPLE** | `git status --porcelain` vacío; 45 archivos en la carpeta del sondeo, **0 huérfanos**; se eliminó un `.rds` derivado que §3 no enumeraba |
| C10 | El reproductor corre de principio a fin en sesión limpia | **CUMPLE con salvedad declarada** | Cada fase corrió en su propio proceso `Rscript`, sin estado heredado, y las fases se re-ejecutaron reusando las respuestas persistidas. **No se hizo una corrida completa contra la red desde cero**: repetirla gastaría 43 llamadas nuevas contra un servicio público sin cambiar ningún resultado |
| C11 | El veredicto declara universo y denominador en la misma línea que cada cobertura | **CUMPLE** | §2, §3, §4.1, §4.4 y §5; el techo por presencia va además marcado como techo y no como cobertura |

**11 de 11 criterios CUMPLE**, uno de ellos (C10) con salvedad declarada en vez de
silenciada.

---

## 11. Lo que este veredicto NO autoriza

- **No autoriza publicar cobertura temática de `datos.bcn.cl`** sobre los 422, ni
  siquiera como estimación: el control positivo falló (3 de 5) y la cobertura por
  los portadores correctos, medida sobre el universo completo, es **0 de 422**.
- **No autoriza construir extractor de LeyChile.** El techo está medido.
- **No cancela P-66.** Lo acota: la entidad `proyecto` se diseña sin eje de
  materias, con `cobertura_materias` explícito, y con la tramitación —que sí tiene
  cobertura 381 de 381 según el veredicto vigente— como el eje que sí es
  construible.
- **No cierra la pregunta para siempre.** §7 nombra la medición de 1 llamada que
  podría darlo vuelta.
