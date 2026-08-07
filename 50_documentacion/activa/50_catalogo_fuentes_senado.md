# Catálogo de fuentes — Senado de Chile

> **Qué es esto.** Inventario de lo que exponen las fuentes del Senado, con qué llaves y
> qué cobertura probada. Producto del encargo
> `50_documentacion/andamios/50_encargo_auditoria_fuentes_camara_senado.md` (sesión 16,
> 2026-08-07). **Medición de solo lectura: no modifica el pipeline.**
>
> **Reproducible:** `Rscript 50_documentacion/andamios/20260807_sondeo_fuentes.R senado`.
>
> **Diferencia estructural con la Cámara, y hay que decirla primero:** el Senado **no tiene
> descriptor**. `GET /api/openapi.json`, `/swagger.json`, `/docs` y la raíz `/api/`
> devuelven **404** (la raíz, con HTML de Drupal 10). Por lo tanto **el universo de
> operaciones del Senado NO es enumerable**: no hay denominador declarable como sí lo hay
> para la Cámara (38 operaciones). Toda ruta que no responde se registra como *probada y no
> existe con ese nombre*, **nunca** como *el servicio no lo expone*.

---

## 1. Denominador declarado — y por qué no es comparable con el de la Cámara

| Qué | Cuánto | Notas |
|---|---|---|
| Rutas distintas **probadas** en `web-back.senado.cl/api/` | **~62** entre las tres ramas del sondeo (30 + 12 + 32, con solapamiento) | "rutas que probamos", **no** "rutas que el servicio expone" |
| Rutas con al menos un **200** | **7** en el backend, más 4 en el SIL | ver §2 y §3 |
| Rutas solo-404 | **23** de 30 en la rama de descubrimiento; 8 de 12 en la de asistencia; 27 de 32 en la temática | cada una con su URL exacta en el caché |
| Llamadas HTTP totales del sondeo del Senado | **1019** (116 + 46 + 857) | 0 errores de red; el servicio **nunca se degradó** |

**Tres fuentes distintas, que conviene no confundir:**

| Fuente | Qué es | Tecnología |
|---|---|---|
| `web-back.senado.cl/api/` | Backend Drupal 10 del sitio senado.cl | JSON |
| `tramitacion.senado.cl/wspublico/` | **SIL**, el Sistema de Información Legislativa. Alojado en dominio del Senado pero **bicameral** | XML plano, sin namespace |
| `datos.bcn.cl/sparql` | Biblioteca del Congreso Nacional, **otra institución** | SPARQL/Virtuoso |

---

## 2. Padrón: cuál es la fuente confiable, y por qué

### Fuente: `GET https://web-back.senado.cl/api/parlamentarios?vigentes=1&limit=300`, filtrando `CAMARA == "S"`

Devuelve **50 filas con 50 `ID_PARLAMENTARIO` distintos**, de 205 filas del roster
unificado (155 `CAMARA=="D"` + 50 `CAMARA=="S"`), con `total` declarado 205. **16
circunscripciones que suman 50 escaños**, 16 regiones, 14 partidos, 34 hombres y 16
mujeres. Verificado dos veces con código independiente (agente de descubrimiento y
reproductor `20260807_sondeo_fuentes.R senado`).

**Que un endpoint responda no lo hace confiable.** Cuadra contra cuatro contrastes:

| # | Contraste | Resultado | Independiente de la fuente |
|---|---|---|---|
| 1 | **BCN vía SPARQL** (`datos.bcn.cl`, cargo `cl/cargo/2` "Senador" vigente al 2026-08-07) | **50 personas** en ambas fuentes. **Diferencia de 0 personas**; emparejamiento 1-1 inyectivo | **Editorial y técnicamente sí** (ver matiz abajo) |
| 2 | **Texto legal**: art. 180 de la LOC 18.700 refundida (LeyChile idNorma 30082) | **16 de 16 circunscripciones coinciden** con la API, suman 50 = 50, 0 filas sin par | **Sí — fuente normativa** |
| 3 | `sessions/attendance?id_legislatura=507` | `TOTAL_SENADORES` = 50, 50 filas, `setequal` con el padrón: 0 en cada diferencia simétrica | No (mismo backend) |
| 4 | Panel nominal de las 54 sesiones | 2700 filas = 50 × 54; los 2700 ids contenidos en el padrón; **0 miembros del padrón ausentes** | No (mismo backend) |

**Matiz sobre la independencia de BCN, que no conviene sobrevender.** BCN es la Biblioteca
del **Congreso Nacional**: un órgano del mismo Congreso al que pertenece el Senado, no un
tercero externo. Además su campo `idSenado` es una llave foránea hacia la numeración del
Senado. El contraste es **editorial y técnicamente** independiente (roster, períodos y
ontología propios, y discrepa en 5 puntos, lo que prueba que no es copia mecánica), pero
llamarlo *institucionalmente* independiente es una etiqueta más fuerte que la evidencia.

**Y BCN NO corrobora el reparto territorial:** el predicado `representing` viene NULL en
**50 de 50**. El reparto por circunscripción lo sostienen la API del Senado y el texto legal
(contraste 2), no BCN.

**Las 5 discrepancias del contraste 1, completas.** El catálogo previo reportaba 2; son 5:

| Tipo | Casos | Detalle |
|---|---|---|
| **Identificador** | **2 de 50** | Longton (Senado `1512` vs BCN `1264`) y Mirosevic (`1513` vs `1144`) |
| **Nombre** (tras normalizar) | **3 de 50** | 911 "Carlos Ignacio Kuschel Silva" vs "Carlos Kuschel Silva"; 1502 "Miguel Angel Becker Alvear" vs "Miguel Becker Alvear"; 1505 "Rodolfo Carter Fernandez" vs "Rodolfo Rafael Carter Fernandez" |

**Ninguna llave sola cubre 50 de 50**: por id salen 48, por nombre 47. El emparejamiento
completo exige las dos. **Diferencia real de personas: 0 de 50.**

⚠️ **Precisión imprescindible sobre los ids 1264 y 1144, porque la lectura natural en este
proyecto es falsa.** Conviven **tres** numeraciones para la misma persona:

| Numeración | Longton | Mirosevic |
|---|---|---|
| Ficha `CAMARA=="S"` del portal del Senado | 1512 | 1513 |
| Ficha `CAMARA=="D"` **del mismo portal del Senado** | **1264** | **1144** |
| `idCamaraDeDiputados` de BCN (la llave que este proyecto **ya usa** para territorio) | 1046 | 991 |

BCN pobló `idSenado` con la **segunda**, no con la tercera. Decir "el id del lado diputado"
a secas induce a leer `idCamaraDeDiputados`, que es otro número. La doble ficha D/S es
**sistémica, no una anomalía de 2 casos**: hay **66 nombres con más de una ficha** en las 817
del padrón histórico.

⚠️ **Trampa del parámetro `limit`:** `data.total` **no** es el número de filas devueltas.
Sin `limit`, el endpoint devuelve **10 filas** pero sigue declarando `total` 205; sin ningún
parámetro declara 817 y devuelve 10. Quien consuma esta fuente debe verificar
`length(data$data) == data$total`. (`limit=300` y `limit=1000` son idénticos byte a byte:
300 no trunca.)

### 🔒 `senadores_vigentes.php` NO se usa como padrón — y ahora se sabe por qué

⚠️ **El host importa:** el servicio vive en `https://tramitacion.senado.cl/wspublico/senadores_vigentes.php`
(HTTP 200, `application/xml`, 12 897 bytes). El host "obvio",
`https://www.senado.cl/wspublico/senadores_vigentes.php`, devuelve **404**. Nombrar el
archivo sin el host lleva a concluir que el servicio no existe.

Devuelve **31 nodos `//senador`**, no 50. Los 31 son **subconjunto estricto** de los 50 del
padrón vigente (31 por `PARLID` y 31 por nombre normalizado; 0 fuera).

**El 31 no es arbitrario, y la razón es lo que importa para el invariante.** Los 19 que
omite son **exactamente** los 19 con `ID_PARLAMENTARIO >= 1500`, todos de la cohorte que
inició el 2026-03-11; los 31 incluidos tienen todos id < 1500. Es decir: **es un servicio
legacy que no incorporó las fichas creadas en la renovación de marzo de 2026** (los pocos de
esa cohorte que sí aparecen son reelectos que conservaron su ficha antigua).

**El invariante útil no es "el php da 31"** —número que cambiará— **sino "el php ignora las
fichas nuevas: usar `web-back`".** Sigue sin usarse como padrón. Utilidad residual: señal
auxiliar de continuidad entre períodos.

---

## 3. Identificadores: la premisa D3 del proyecto necesita una corrección

La decisión D3 registrada dice que los espacios de identificadores de Cámara y Senado son
distintos y que **"no hay colisión que resolver"**. La primera mitad es correcta; **la
segunda es falsa** y hay que corregirla.

| Medición | Resultado | Denominador |
|---|---|---|
| Diputados vigentes empalmados por nombre entre el backend del Senado y `diputados.rds` | **150 empalmes, de los cuales 0 tienen el mismo número de id** | 155 filas `CAMARA=="D"` del backend vs 155 de `diputados.rds` |
| **Colisiones numéricas activas** entre ids de senador vigente y `diputado_id` de la Cámara | **5** (1110, 1117, 1215, 1222, 1224), y en **5 de 5 designan personas distintas** | 50 senadores vs 155 `diputado_id` |
| Colisión ampliada: ids `CAMARA=="D"` del backend que coinciden numéricamente con un `diputado_id` | **11**, y en 11 de 11 son personas distintas | 155 filas `CAMARA=="D"` del backend |
| Rangos | `diputado_id` de la Cámara: **803–1264**. Ids de senadores vigentes: **911–1518** | — |

**Los rangos se solapan.** Un join sin la llave compuesta `(camara, parlamentario_id)`
—que es exactamente lo que D3 manda— produciría 5 cruces silenciosamente incorrectos hoy
mismo. **D3 es correcta como decisión; su justificación registrada estaba mal.**

**`ID_PARLAMENTARIO` es de (persona × cámara), no de persona.** En el padrón histórico de
817 filas hay **77 nombres normalizados repetidos** sobre 740 nombres distintos; el `SLUG`
desambigua con sufijo `-dip` / `-sen` (189 de 189 filas `CAMARA=="S"`). De los 19 senadores
de la cohorte 2026 (bloque de ids contiguo **1500–1518**), **14 tienen además una fila
`CAMARA=="D"` con OTRO id**.

**Estabilidad verificada: 4 semanas.** Entre el 2026-07-10 y el 2026-08-07, 50 de 50
senadores y 155 de 155 diputados conservan id, nombre y slug (`setequal` = TRUE), y las 26
columnas del contrato son idénticas. **No se puede afirmar más que eso**: no existe captura
del backend anterior a la instalación de marzo de 2026, así que no se pudo verificar si el
id de una persona cambia al pasar de la Cámara al Senado.

---

## 4. Sesiones

**Sí existe catálogo, con fecha y legislatura.**

| Qué | Medición |
|---|---|
| `GET /api/legislatures?limit=100` | **56 legislaturas**, 56 ids distintos, `NUMERO` 319–374, desde 1990-03-11 |
| **Legislatura vigente** | **ID 507**, número 374, 11/03/2026 a 10/03/2027 — **derivada por fecha, no hardcodeada** |
| `GET /api/sessions?id_legislatura=507&limit=500` | **54 sesiones**, 54 `ID_SESION` distintos, `total` declarado 54 |
| Celebradas vs futuras | 52 celebradas al 2026-08-07; 2 futuras (11 y 12 de agosto) |
| Tipos | Ordinaria 32, Especial 15, Congreso pleno 3, Extraordinaria 3, de Instalación 1 |
| Universo global | `total` declarado **3538** sesiones |

⚠️ **Corrección a la exploración previa del proyecto:** la documentación archivada usaba
`id_legislatura=504`, que **no es la legislatura vigente**: declara `NRO_LEGISLATURA` 372 y
su sesión más reciente es del 05-03-2025. Todo el andamiaje previo de asistencia agregada
apuntaba a un período cerrado.

---

## 5. Asistencia

### Sí existe asistencia NOMINAL por sesión. El veredicto completo está en [50_veredicto_contrato_simetrico_senado.md](50_documentacion/activa/50_veredicto_contrato_simetrico_senado.md).

`GET /api/sessions/attendance` es **polimórfico**: la misma ruta devuelve cosas distintas
según el parámetro, y **solo una de las dos satisface D2**.

| Parámetro | Qué devuelve | ¿Satisface D2? |
|---|---|---|
| `?id_sesion=<id>` | **Una fila por (senador, sesión)** con estado y justificación. Metadatos de la sesión al nivel del sobre | **Sí** |
| `?id_legislatura=<id>` | **Agregado por senador**, sin dimensión de sesión (`ASISTIO_A`, `JUSTIFICADO`, `SIN_JUSTIFICAR`, `TOTAL_SESIONES`) | **No** |

**Panel nominal de la legislatura vigente, medido dos veces con código independiente:**

| Medición | Valor | Denominador |
|---|---|---|
| Filas nominales | **2700** = 54 sesiones × 50 senadores | — |
| Pares (sesión, parlamentario) distintos | **2700 de 2700** (llave compuesta única) | 2700 filas |
| Filas por sesión | **50**, valor único observado | 54 sesiones |
| Dominio de `ASISTENCIA` | `Asiste` **2330**, `Ausente` **370** — **solo 2 valores**, frente a 3 en la Cámara | 2700 filas |
| Filas con `JUSTIFICACION` no vacía | **21**, con **2 glosas** (Invitación oficial 12, Enfermedad 9), **sin código** | 2700 filas |
| Profundidad histórica | 2002 **sí** trae dato (sesión 4248: 42 `Asiste` de 48); 1990 **no** (sesión 2643: 0 de 49) | 3 legislaturas sondeadas de 56 |

⚠️ **La trampa que hay que declarar: 3 de 54 sesiones devuelven las 50 filas en `Ausente`,
con cero asistentes** (ids 10225, 10249, 10250). Dos son futuras; **una ya se celebró** (la
10225, Congreso pleno del 15/07/2026). Es decir, **"sin dato" es indistinguible de
"inasistencia universal"** salvo por una regla de detección. La regla se corrobora con el
agregado oficial: **54 − 3 = 51 = `TOTAL_SESIONES`** declarado. Verificado en la corrida del
reproductor.

Y la conciliación cierra sin residuo: `ASISTIO_A` del agregado coincide con el recuento de
`Asiste` del panel en **50 de 50** senadores; `JUSTIFICADO` suma 21 = 21; `SIN_JUSTIFICAR`
suma 199 = 220 ausentes (excluidas las centinela) − 21 justificadas.

**`JUSTIFICACION` no significa "motivo de ausencia".** Coexiste con `ASISTENCIA == "Asiste"`
en 2 filas de 2700 (senador 1507, sesiones 10140 y 10141) y hay ausentes sin justificación.
**Su semántica no consta en la fuente**: mismo caso que `RebajaAsistencia`/`RebajaQuorum`
en la Cámara (P2), y merece el mismo trato — persistir, no calcular.

**Asistencia de comisiones: no se encontró la ruta.** 6 candidatas probadas, todas 404. El
dossier del parlamentario indexa `ASISTENCIA_COMISIONES` con 15 legislaturas, así que el
dato probablemente existe. Se registra como **no encontré la ruta**, no como *no expone*.

---

## 6. Votaciones, proyectos y materias

### 6.1 El Senado es MEJOR que la Cámara en votación → proyecto

| Medición | Senado | Cámara |
|---|---|---|
| Votaciones con boletín | **259 de 278** (93,17 %) en la legislatura vigente | 546 de 791 (69,03 %) |
| Universo declarado | 8781 votaciones | 821 en 2026 |

Muestra sistemática del archivo histórico (8 páginas de `limit=50` en offsets
equiespaciados): **351 de 400** con boletín (87,75 %). Es una muestra declarada, no un
censo: el detalle nominal anidado pesa ~8,7 KB por votación (~76 MB para el censo
completo), tráfico no justificado.

⚠️ **Trampa grave, y es de las que producen datos falsos sin avisar:** el campo `BOLETIN` de
`/api/votes` **mezcla dos espacios de numeración sin discriminador**. De 78 valores
distintos, **21 son "Asuntos" del Senado** (serie de 4 dígitos `2xxx-`), que resuelven
contra proyectos de 2001 sin ninguna relación. Al consultarlos contra el SIL, 13 de 15
delatan el error porque el sufijo devuelto no coincide, pero **en 2 casos el sufijo coincide
y el falso positivo es indetectable por esa verificación**. Los boletines de ley reales (5
dígitos) empalman 55 de 55.

**No existe discriminador de tipo documentado.** La verificación `boletin_devuelto ==
boletin_pedido` es **necesaria pero no suficiente**.

### 6.2 Materias: la asimetría es de primer orden

**El Senado no tiene catálogo de materias.** 6 rutas candidatas (`/api/materias`,
`/api/subjects`, `/api/topics`, `/api/temas`…) devuelven 404. Lo que sí entrega el SIL es
`<materia><DESCRIPCION>` como **texto libre, sin identificador**.

| Eslabón | Cámara | Senado |
|---|---|---|
| Catálogo de materias | **8518 entradas, Id entero único** | **No existe** |
| Materia como dato | `Id` + `Nombre` | solo `DESCRIPCION` (texto) |
| Proyecto → materia (universo local de 381 boletines) | **5 de 381** (1,31 %) | **5 de 381** (1,31 %) |
| ¿Los mismos 5? | **Sí: conjunto idéntico y `n_materias` idéntico (2, 2, 4, 2, 1)** | |

**Lo que esto establece, y lo que no.** Establecido: el déficit de materias **no es un
defecto de la API de la Cámara**, porque la otra superficie devuelve exactamente lo mismo
para exactamente los mismos boletines.

**Hipótesis, no hecho:** que ambas cámaras "espejeen una sola fuente aguas arriba". Que los
mismos 5 boletines aparezcan con las mismas `n_materias` en las dos superficies es
consistente con un origen común **y también** con que la materia sea un atributo del
registro del proyecto que ambas leen. **Ningún artefacto de esta auditoría establece la
dirección de la dependencia.** Lo resolvería consultar una tercera fuente independiente
(`datos.bcn.cl` o LeyChile) para los mismos 5 boletines.

Y el puente texto → Id funcionó en 11 de 11 casos observados, pero **no es inyectivo en
general**: 13 nombres normalizados del catálogo de la Cámara apuntan a más de un Id (sobre
8493 nombres distintos en 8518 entradas). **El puente de materias no se puede declarar
resuelto.**

### 6.3 El SIL cierra un hueco que la Cámara tiene abierto

`GET https://tramitacion.senado.cl/wspublico/tramitacion.php?boletin=<NNNNN>` es
**bicameral**, pese a estar en dominio del Senado:

| Medición | Valor | Denominador |
|---|---|---|
| Boletines de la **Cámara** que el SIL resuelve | **381 de 381** (100 %) | 381 boletines reales de `proyectos.rds` + `votos.rds` |
| Título del SIL idéntico al nombre de la Cámara (tras decodificar entidades HTML) | **381 de 381** | 381 |
| Proyectos con **≥1 trámite fechado** | **381 de 381** (100 %), **4569 trámites**, todos con fecha parseable | 381 |
| Trámites por proyecto | mediana 2, máximo 227 | 381 |
| Etapas distintas | 15 | 4569 trámites |
| Proyectos con `leynro` (ley publicada) | 28 | 381 |
| Proyectos que llegaron al Senado | 109 (28,61 %) | 381 |

**Esto es exactamente lo que la API de la Cámara NO expone.** El hueco "estado de
tramitación no se expone → `NA`", registrado en `CLAUDE.md` desde la fase 1, **tiene fuente**:
está en el SIL, no en `opendata.camara.cl`.

Confirmado independientemente por el reproductor sobre una muestra propia: **20 de 20**
boletines resueltos, **20 de 20** con trámite fechado, **0 de 20** con materia.

### 6.4 Autoría del Senado: completa, pero sin identificadores

| Medición | Valor | Denominador |
|---|---|---|
| Mociones con ≥1 autor | **330 de 330** (100 %) | 330 mociones del universo local |
| Campos por nodo autor | **1**: solo `PARLAMENTARIO`, texto libre **sin id** | — |
| Autores distintos empalmados con el padrón histórico del backend | **282 de 282** (100 %) | 282 cadenas distintas |
| Pares proyecto-autor empalmados | **2127 de 2127** (100 %) | 2127 pares |
| Autores que caen en **clave ambigua** (>1 `ID_PARLAMENTARIO`) | **33 de 282** | 282 |
| — de esas, ambiguas solo por duplicación D/S de la misma persona | 31 de 33 | 33 |
| — con **ambigüedad real** dentro de una misma cámara | **2** | 33 |

El empalme por nombre funciona, pero **es un cruce por texto, no por llave**, y quedan 2
casos sin resolver.

---

## 7. Catálogo de rutas

### 7.1 `web-back.senado.cl/api/` — confirmadas

| Ruta | Estado | Parámetros probados (reales) | Llave / granularidad | Eje | Utilidad |
|---|---|---|---|---|---|
| `GET /api/parlamentarios` | NO USADA | `?vigentes=1&limit=300` → 205 filas, 26 columnas; `?limit=1000` → 817 (histórico); sin parámetros → 10 de 817 | `ID_PARLAMENTARIO` | persona | **Fuente de padrón.** Trae partido, región, circunscripción y `PERIODOS` anidados |
| `GET /api/legislatures` | NO USADA | `?limit=100` → 56 | `ID_LEGISLATURA` | ninguno | Fija la legislatura vigente sin hardcodear |
| `GET /api/sessions` | NO USADA | `?id_legislatura=507&limit=500` → 54; sin parámetros → 10 de 3538 | `ID_SESION` | ninguno | Catálogo de sesiones con fecha y tipo: **el denominador de cualquier tasa** |
| `GET /api/sessions/attendance` | NO USADA | `?id_sesion=` (54 ids reales) → 50 filas c/u; `?id_legislatura=` (507, 505, 381, 161) → agregado | `(ID_SESION, ID_PARLAMENTARIO)` o `ID_PARLAMENTARIO` | persona | **Habilita D2.** Polimórfica (§5) |
| `GET /api/votes` | NO USADA | `?id_legislatura=507&limit=500` → 278; `?id_votacion=11252` → 1 con 38 votantes; `?boletin=18431-31` → 1; sin parámetros → 10 de 8781 | `ID_VOTACION`; `PARLID` en el detalle | ambos | Única puerta del backend al eje temático. `PARLID` **es** el espacio de `ID_PARLAMENTARIO` (38 de 38 contenidos en el padrón) |

⚠️ **Trampa de paginación:** `page` **se ignora en silencio** en `/api/votes` (`limit=50` y
`limit=50&page=2` son idénticos byte a byte). Lo que funciona es `offset` (0 ids solapados
entre `limit=50` y `limit=50&offset=50`).

### 7.2 `tramitacion.senado.cl/wspublico/` (SIL)

| Ruta | Estado | Cobertura probada | Eje | Utilidad |
|---|---|---|---|---|
| `tramitacion.php?boletin=<NNNNN>` | NO USADA | 381 boletines de la Cámara + 72 del universo nativo: **381 de 381 resueltos** | **ambos** | **La operación que hace bicameral el eje temático.** Única fuente medida de tramitación fechada |
| `senadores_vigentes.php` | NO USADA | sin parámetros → 31 nodos | persona | **NO usar como padrón** (§2) |
| `comisiones.php` | NO USADA | sin parámetros → 38 comisiones, con `PARLID` | persona | Integrantes de comisión en el **mismo espacio** de `ID_PARLAMENTARIO` |
| `votaciones.php` | NO USADA | `?boletin=10795` → votaciones nominales. Con `idsesion`, `id` y `fecha_*` **reales** → vacío | ambos | Menos útil que `/api/votes` |
| `sesiones.php` | **NO PROBADA** | Sin parámetros responde 200 con "No existe la legislatura solicitada". **Nombre del parámetro no descubierto** | — | No determinada |

### 7.3 `datos.bcn.cl/sparql`

| Ruta | Estado | Cobertura probada | Utilidad |
|---|---|---|---|
| `GET /sparql` (cargo `cl/cargo/2`) | NO USADA para el Senado; **el proyecto ya lo usa para la Cámara** en `50_documentacion/andamios/medir_fuente_territorio.R` | 9 consultas, 9 HTTP 200. 50 personas con cargo Senador vigente | **El contraste independiente del padrón** (§2) |

### 7.4 Probadas y no existen (404 con URL exacta registrada)

`/api/proyectos`, `/api/boletines`, `/api/materias`, `/api/mociones`, `/api/bills`,
`/api/projects`, `/api/tramitacion`, `/api/tramites`, `/api/subjects`, `/api/topics`,
`/api/temas`, `/api/comisiones`, `/api/committees`, `/api/partidos`,
`/api/circunscripciones`, `/api/regiones`, `/api/sesiones`, `/api/votaciones`,
`/api/legislaturas`, `/api/parlamentarios/mociones`, `/api/parlamentarios/comisiones`,
`/api/parlamentarios/asistencia`, `/api/parlamentarios/asuntos`, `/api/attendance`,
`/api/asistencia`, `/api/openapi.json`, `/api/swagger.json`, `/api/docs`, `/api/` (raíz),
`/api/parlamentarios/911` y `/api/sessions/10241` (identificador en el *path*, con ids
reales).

Las dos últimas documentan la convención del servicio: **los identificadores van en
querystring, no en la ruta**.

---

## 8. Lo que no se pudo probar

| Qué | Por qué |
|---|---|
| **El universo de operaciones** | No hay descriptor. Vía pendiente no recorrida: extraer las rutas desde los *chunks* JS del frontend de senado.cl |
| **Rutas del dossier del parlamentario** | El backend declara que hay contenido para `MOCIONES`, `COMISIONES`, `ASISTENCIA_COMISIONES`, `ASUNTOS`, `OFICIOS_INCIDENTES`, `INTERVENCIONES_*`, pero las 5 formas probadas con ids reales dan 404. **La capacidad existe; la ruta se nos escapó** |
| **Cobertura de `BOLETIN` sobre las 8781 votaciones** | Medido el universo completo de la legislatura vigente (278) + muestra sistemática declarada de 400. Censo completo: ~76 MB, tráfico no justificado |
| **Estabilidad de identificadores más allá de 4 semanas** | No existe captura anterior a marzo de 2026 |
| **Cuál es cuál en las 2 claves de autor con ambigüedad real** | Quedan sin resolver |
| **`jsonapi` (raíz JSON:API del Drupal)** | 214 links de tipos de recurso, no re-derivado. Vía viva para cerrar el universo |
| **El reparto por circunscripción contra el texto de la Ley 20.840** | Se midió que suma 50 en 16 circunscripciones, **no** que coincida artículo por artículo |
| **`opendata.congreso.cl`** | **Nunca se exploró.** La muestra archivada que el proyecto rotulaba así es en realidad de `web-back.senado.cl/jsonapi` (self link y 214 de 214 hrefs en ese host). El veredicto previo "es un portal de documentación" **no tiene artefacto que lo respalde** |
| **Verbos distintos de GET** | No se sondearon |

---

## 9. Corrección al contrato común propuesto en la rama `design/contrato-datos`

El esquema del lado Cámara de ese documento **quedó obsoleto**: describe un
`asistencia.rds` agregado de 239 filas que **ya no existe** (hoy son `asistencia_nominal.rds`
con 9183 filas y `asistencia_ambitos.rds` con 310), y cifras superadas de votos, proyectos
y detalle (104 160 / 1313 / 317 contra 122 605 / 1705 / 381). Su pregunta abierta #1
(extender el extractor de la Cámara al nominal por sesión) **ya está resuelta y en
producción** desde la Capa 3. **Hay que re-derivar ese esquema antes de usarlo.**
