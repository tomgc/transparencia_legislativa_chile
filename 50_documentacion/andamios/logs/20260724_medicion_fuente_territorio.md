# Medición de la fuente territorial (Capa 2, D5/A28) — veredicto

**Fecha:** 2026-07-24 · **Rama:** `feat/territorio-crosswalk` · **Modo:** medición pura,
sin crosswalk escrito. Todo en R (🔒 invariante 1). Sin push, sin PR.

---

## 0. Veredicto en una línea

**La Capa 2 puede proceder.** Existe una fuente que entrega el distrito de los
**155 de 155** diputados vigentes, y el cruce es **determinista por el id de la
Cámara**, no por nombre. **El supuesto S4 del encargo queda refutado** y con él
la premisa central de A28.

---

## 1. Supuestos del encargo, contrastados contra la fuente

| # | Supuesto | Resultado |
|---|---|---|
| S1 | 155 diputados, `id` character en el índice | ✅ **Confirmado.** 155 filas, 155 ids únicos, `class(id) == "character"` |
| S2 | Roster fuente con distrito y región en `NA` | ✅ **Confirmado.** `docs/data/indice_diputados.json` y `40_salidas/intermedios/diputados.rds`: 0/155 no-NA en ambas columnas |
| S3 | No existe mapa de fuentes de la sesión 7 | ⚠️ **Parcialmente refutado.** No hay archivo dedicado, pero el mapa existe como **A28** en `50_documentacion/traspasos/traspaso_cierre_v07.md` (§7). Se leyó y se usó como punto de partida |
| S4 | La llave será el nombre normalizado, porque BCN/SERVEL no conocen el `diputado_id` de la Cámara | ❌ **REFUTADO.** BCN publica `bcn-biographies#idCamaraDeDiputados`: **es literalmente el id de la Cámara**. Cobertura 155/155 |

La refutación de S4 es el hallazgo central. A28 concluía que ninguna fuente era
"a la vez accesible por máquina y cruzable por id"; la medición muestra que BCN
**sí lo es**, por un predicado que la sesión 7 no encontró.

---

## 2. Fuente elegible

**BCN — Biblioteca del Congreso Nacional**, en dos recursos complementarios:

| Recurso | URL | Formato | Rol |
|---|---|---|---|
| Endpoint SPARQL | `https://datos.bcn.cl/sparql` | `application/sparql-results+json` | Da la **llave**: `persona ↔ idCamaraDeDiputados`, y la URL de la ficha (`bcnPage`) |
| Ficha "Reseñas parlamentarias" | `https://www.bcn.cl/historiapolitica/resenas_parlamentarias/wiki/<nombre>` (URL obtenida del propio SPARQL, no construida) | HTML con tabla "Trayectoria Parlamentaria" | Da el **dato**: distrito por período |

Ambos responden HTTP 200 sin WAF, sin autenticación y sin captcha (contraste con
`camara.cl`, que A28 reportó bloqueado con 403).

### Predicados relevantes (medidos, no supuestos)

```
bcn-biographies#idCamaraDeDiputados   -> id de la Cámara, xsd:string
bcn-biographies#bcnPage               -> URL de la ficha
skos#prefLabel / rdfs:label           -> nombre
```

---

## 3. El territorio NO está en el grafo RDF (medición negativa, con evidencia)

Esto confirma y **precisa** A28: BCN modela el territorio en su ontología, pero
la carga de datos está esencialmente vacía.

| Predicado | Tripletas en TODO el store |
|---|---|
| `bcn-biographies#representing` | **38** |
| `bcn-biographies#representingPlaceNamed` | **23** |
| `bcn-biographies#hasRepresentationIn` | **0** |

Y esas 38 tripletas cuelgan de nodos `persona/<n>/cargo/<k>` con `k` de un dígito
(carga antigua, `hasPeriod` de 2014) que **la persona no enlaza**: los cargos
vivos son `cargo/1104xx` / `cargo/105xx` y no llevan territorio. Verificado sobre
Vlado Mirosevic (`persona/4531`): la persona apunta a `cargo/110395, 10450, 10303,
110834`; el nodo con `representing` es `cargo/1`, que ningún predicado de la
persona referencia.

**Consecuencia:** el join SPARQL `persona → hasParliamentaryAppointment → cargo →
representing` devuelve **0 filas**. El grafo no sirve para el territorio. Sí sirve,
y de forma decisiva, para la **llave**.

---

## 4. Cobertura medida

### 4.1 La llave (SPARQL)

| Métrica | Valor |
|---|---|
| Personas BCN con `idCamaraDeDiputados` | 846 filas / 829 ids únicos |
| **De los 155 del índice, presentes en BCN** | **155 / 155** |
| Ausentes | **0** |
| Con ficha `bcnPage` | **155 / 155** |

### 4.2 El dato (ficha)

| Métrica | Valor |
|---|---|
| **Con distrito del período 2026-2030** | **155 / 155** |
| Distritos distintos observados | **28** (el país tiene 28) |
| Suma de escaños | **155** |
| Rango de magnitud por distrito | **3 – 8** |

La distribución de escaños es una validación independiente fuerte: 28 distritos,
magnitudes entre 3 y 8, sumando exactamente 155 — que es la configuración legal
del sistema electoral chileno. Ninguna de esas tres cifras fue impuesta por el
método de medición; salieron del parseo.

Distribución completa:

```
distrito  1  2  3  4  5  6  7  8  9 10 11 12 13 14
escaños   3  3  5  5  7  8  8  8  7  8  6  7  5  6
distrito 15 16 17 18 19 20 21 22 23 24 25 26 27 28
escaños   5  4  7  4  5  8  5  4  7  5  4  5  3  3
```

---

## 5. Llave de cruce y calidad del match

**La llave es `idCamaraDeDiputados` (character), idéntica al `diputado_id` del
pipeline.** Verificado punto a punto: `persona/4558` → `idCamaraDeDiputados = "1017"`
→ en el índice, id `1017` = Álvaro Carter Fernández. Cero matching difuso.

### 5.1 Un defecto de la fuente que sí exige regla explícita

BCN **reutiliza el mismo `idCamaraDeDiputados` en dos personas distintas** en 4
casos: un parlamentario histórico y uno vigente comparten id.

| id | Persona histórica (BCN) | Persona vigente (BCN) |
|---|---|---|
| 1159 | `persona/170` — Agustín Aldunate Palacios | `persona/5221` — Lorena Pizarro Sierra |
| 1175 | `persona/877` — Joaquín Díaz Garcés | `persona/5194` — Cristián Tapia Ramos |
| 1209 | `persona/879` — Patricio Javier Lynch Zaldívar | `persona/7181` — Matías Fernández Hartwig |
| 1252 | `persona/944` — José Antonio De Huici Trucíos | `persona/4710` — Constanza Schönhaut Soto |

**Es un error de datos de BCN, no ambigüedad de nombre.** Se desambigua con una
regla determinista y verificable: entre los candidatos que comparten id, **gana
el que tenga fila del período vigente en su "Trayectoria Parlamentaria"**. Con esa
regla los 4 resuelven limpio (13, 4, 24, 11 respectivamente) y la cobertura pasa
de 151/155 a **155/155**. La ficha de la persona histórica de `1175` además
devuelve **HTTP 404**, así que ni siquiera compite.

### 5.2 La llave de respaldo (nombre), medida por si acaso

Aunque no se necesita, se midió para dejar el contraste registrado:

| Métrica (clave de tokens normalizados, insensible al orden) | Valor |
|---|---|
| Match exacto contra el `prefLabel` de BCN | **145 / 155** |
| Claves ambiguas (mismo nombre normalizado, >1 persona) | 0 |
| **Sin match** | **10** |

Los 10 sin match por nombre: Agustín Romero Leiva (1165), Andrea Macías Palma
(1222), Coca Ericka Ñanco Vásquez (1153), Iracÿ Hassler Jacob (1213), Juan Carlos
Beltrán Silva (1108), Luis Sánchez Ossa (1170), Marco Antonio Sulantay Olivares
(1174), Mauro González Villarroel (1131), Valentina Cáceres Monsálvez (1207),
Álvaro Ortiz Vera (1238). La causa habitual es que BCN usa el nombre legal completo
(dos nombres de pila) y la Cámara el nombre de uso.

**Lectura:** el cruce por nombre habría dejado un residuo de 10 casos a revisión
manual. El cruce por id deja **cero**. Esto vuelve innecesario el "matching difuso
como andamio de una vez" que D5 contemplaba.

---

## 6. Fuentes descartadas, con evidencia

| Fuente | Medición | Veredicto |
|---|---|---|
| **API de la Cámara** (`WSDiputado.asmx`) | 4 operaciones; unión de campos sobre los 155 items: `Id, Nombre, Nombre2, ApellidoPaterno, ApellidoMaterno, FechaNacimiento, RUT, RUTDV, Sexo, Militancias` | ❌ Ningún campo territorial. Confirma el `# REVISAR` del `32`. **Hallazgo lateral:** sí expone **RUT**, una llave nacional inequívoca hoy sin uso |
| **`WSComun.asmx`** | 24 operaciones, todas catálogos (`retornarTiposX`, `retornarPartidosPoliticos`) | ❌ Sin vínculo diputado↔distrito |
| **SERVEL** | `servel.cl` 200 OK, pero los resultados de diputados son **embeds de Power BI** (`app.powerbi.com/view?r=...`); el histórico en HTML llega solo hasta 2009; `elecciones.servel.cl/data/*.json` → **403** | ❌ No consultable de forma reproducible sin reversar la API privada de Power BI |
| **datos.gob.cl (CKAN)** | `package_search` q=`servel` → 0; q=`electos` → 0; q=`diputados` → 2 (irrelevantes) | ❌ No publica el dato |
| **`datos.bcn.cl` SPARQL, vía territorial** | 38 + 23 tripletas vestigiales en nodos huérfanos (§3) | ❌ Para el territorio. ✅ Para la llave |

---

## 7. Lo que la medición NO establece (queda para el diseño, no se decidió aquí)

1. **Región.** La tabla de trayectoria da distrito, no región; la región aparece
   solo en prosa ("Distrito, Región Metropolitana"). Derivarla de un catálogo
   distrito→región (28 filas, estable por ley) es una vía obvia, **pero no se
   midió ni se diseñó** en este encargo.
2. **Reemplazos dentro del período.** Se midió el corte actual. Que un reemplazante
   herede el distrito de quien reemplaza sigue siendo **el supuesto no verificado
   que D5 señala**; la medición no lo toca.
3. **Estabilidad del scraping.** La ficha es HTML, no un contrato de datos. El
   ordinal ya aparece en dos formas ("12° Distrito" y "3er Distrito") — el parser
   tuvo que absorber ambas. Un cambio de plantilla de BCN rompe el parseo. Esto
   argumenta a favor de D5 tal como está escrita: **mapeo versionado**, generado
   una vez y auditado, no scraping en cada corrida del pipeline.
4. **Frecuencia de actualización.** `bcn-biographies#lastUpdate` existe por persona
   (Carter: `2025-07-15`). No se midió su distribución.

---

## 8. Recomendación

**Proceder al diseño del crosswalk, con BCN como fuente y `idCamaraDeDiputados`
como llave.** No hay bloqueo que decidir. Los tres puntos que el diseño debe fijar:

- La regla de desambiguación de los 4 ids colisionados (§5.1) queda **escrita en el
  crosswalk versionado**, no resuelta en tiempo de ejecución.
- El territorio se congela en un **archivo de mapeo versionado y auditado**
  (D5), generado por este andamio una vez, no consultado en cada refresh semanal.
- La región, si se quiere, sale de un catálogo distrito→región propio; **no**
  de la prosa de la ficha.

Con eso, `distrito` deja de ser `NA` en 155/155 y la promesa territorial del portal
pasa a estar cumplida y auditada.

---

## 9. Artefactos de esta medición

| Ruta | Qué es |
|---|---|
| `50_documentacion/andamios/medir_fuente_territorio.R` | Script de medición (andamio, **no** etapa del pipeline). Fases 1–4 + consulta SPARQL libre |
| `50_documentacion/andamios/muestras/bcn_id_camara.json` | Respuesta SPARQL cruda: 846 personas con `idCamaraDeDiputados` |
| `50_documentacion/andamios/muestras/bcn_grafos.json` | Grafos nombrados del store |
| `50_documentacion/andamios/muestras/bcn_label_carter.json` | Resolución de persona por label |
| `50_documentacion/andamios/muestras/bcn_territorio_por_cargo.json` | La respuesta **vacía** que prueba §3 |
| `50_documentacion/andamios/muestras/bcn_ficha_carter_4558.html` | Ficha HTML cruda de muestra |
| `50_documentacion/andamios/muestras/medicion_territorio_155.rds` | Resultado: id, nombre, distrito, estado — los 155 |
| `50_documentacion/andamios/muestras/medicion_indice_155.rds` | Índice publicado, congelado al momento de medir |

Reproducir:

```
Rscript 50_documentacion/andamios/medir_fuente_territorio.R 1   # estado local
Rscript 50_documentacion/andamios/medir_fuente_territorio.R 3   # llave y cobertura
Rscript 50_documentacion/andamios/medir_fuente_territorio.R 4   # distrito de los 155
```

---

## 10. Errores del asistente en esta medición (POLITICA 0.5)

1. **Primer conteo de cobertura falso por regex, no por fuente.** La primera corrida
   de la Fase 4 reportó 129/155 y 25 "fichas sin distrito del período". Era mi
   parser: BCN escribe el ordinal como "3er Distrito" además de "12° Distrito".
   Se detectó porque el número no cuadraba y se fue a mirar una ficha concreta
   antes de escribir el veredicto. **Regla:** un hueco de cobertura no se reporta
   como hueco de la fuente hasta haber inspeccionado un caso crudo.
2. **Descarte de duplicados antes de entenderlos.** La Fase 4 aplicó
   `!duplicated(idcam)` y perdió 4 casos, reportando 151/155. El duplicado no era
   ruido: era el defecto de datos de §5.1, y contenía justamente a la persona
   correcta. **Regla:** no deduplicar por conveniencia antes de saber qué genera
   el duplicado.
3. **Consulta SPARQL sin cota que agotó el timeout.** Un `FILTER(CONTAINS(...))`
   sobre `?s ?p ?o` sin acotar reventó a 60 s contra Virtuoso. Se resolvió acotando
   por grafo y por prefijo de sujeto.
