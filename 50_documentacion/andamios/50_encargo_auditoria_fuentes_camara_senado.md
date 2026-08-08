# Encargo Ultracode — Auditoría de fuentes: Cámara, Senado y eje temático

> **Proyecto:** `transparencia_legislativa_chile` · **v2, sesión 16** · 2026-08-07
> **Modo:** Ultracode (workflows dinámicos). **Ejecutor:** Claude Code, app de escritorio.
> **Naturaleza:** medición de solo lectura. Este encargo **no modifica el pipeline
> ni el contrato publicado**. Su producto son catálogos, veredictos y planes.
>
> **Cambios respecto a v1 (redactada en la sesión 15, sin ejecutar).** El titular
> declaró que el eje de mayor interés del proyecto es **temas, proyectos y
> votaciones**, con asistencia en segundo plano. La auditoría se amplía en
> consecuencia: se agrega una quinta pregunta de meta (§1), un artefacto de salida
> nuevo (§4.4, veredicto del eje temático), cinco criterios de éxito (§5, 10 a 14)
> y un cuarto hallazgo al panel adversarial (§6). Se corrige además el invariante
> sobre PRs abiertos, que quedó obsoleto: los dos PRs que v1 mandaba no tocar
> fueron mergeados en la sesión 16 y `main` está limpio. El resto del documento se
> conserva.
>
> **Por qué está escrito así.** Un encargo Ultracode no prescribe fases: la
> orquestación la decide el runtime. Lo que sí fija el redactor, y lo que este
> documento contiene, es la **meta**, los **invariantes**, el **contrato de
> salida** y los **criterios de éxito contrastables**. Si una instrucción de aquí
> te parece que compite con tu propia descomposición, gana tu descomposición,
> salvo que sea un 🔒.

---

## 1. Meta

Dos cosas a la vez, con la misma exploración y sin duplicar tráfico contra las
fuentes: saber si el **eje temático** (proyectos, materias y votaciones como
entidades de primera clase) es construible, y convertir el pipeline del **Senado**
de bloqueado a diseñable.

Concretamente, responder cinco preguntas con evidencia reproducible:

1. **¿Qué expone realmente la API de la Cámara?** El proyecto consume 8
   operaciones de un servicio que expone del orden de 49. Las otras ~41 nunca se
   han inventariado. Qué hay ahí, con qué llaves, con qué cobertura.
2. **¿Es construible el eje temático?** Es la pregunta de mayor valor de este
   encargo. El portal hoy responde bien preguntas sobre personas y no responde
   preguntas sobre temas: "quién vota qué en materia de vivienda" no tiene
   respuesta. Se detalla en §1.1.
3. **¿Alguna de las operaciones no usadas resuelve un pendiente abierto?** En
   particular **P2**: los campos `RebajaAsistencia` y `RebajaQuorum` se persisten
   pero están excluidos de toda fórmula porque su semántica reglamentaria no está
   documentada. Si alguna operación del servicio la documenta o la deriva, P2 deja
   de estar bloqueado.
4. **¿Qué expone el backend del Senado** (`web-back.senado.cl/api/`) y con qué
   llaves, sabiendo que `senadores_vigentes.php` **no es fuente confiable de
   padrón** para el período vigente?
5. **¿Es construible el contrato simétrico de asistencia nominal por sesión (D2)
   para el Senado?** Veredicto explícito: sí, no, o sí con estas lagunas.

### 1.1 La pregunta del eje temático, desglosada

No basta con "existe un catálogo de materias". Lo que decide si el eje es
construible es la **cobertura de la cadena completa**, medida sobre el universo
real del corte vigente, no sobre una muestra amable:

- **a) Catálogo de materias:** ¿existe, con qué cardinalidad, con o sin jerarquía,
  con identificadores estables? Hay una muestra previa en
  `50_documentacion/andamios/muestras/catalogo_materias.xml` que **no se toma como
  respuesta**: se re-deriva de la fuente y se compara con ella.
- **b) Proyecto → materia:** ¿cada proyecto trae sus materias? Con qué **cobertura
  sobre el universo de proyectos que el pipeline ya persiste**, declarando el
  denominador. Muestra previa:
  `50_documentacion/andamios/muestras/proyecto_con_materias_10986_24.xml`.
- **c) Votación → proyecto:** este eslabón ya está medido y **está roto en un
  tercio**. El refresh del corte 2026-08-03 declara 65 478 votos con proyecto y
  30 919 sin proyecto (fuente: cuerpo del PR #3, reproducido en
  `50_documentacion/andamios/logs/20260806_p58_resolucion_prs_log.md`). La
  pregunta no es si el eslabón existe sino **por qué falta en ~32 % de los votos**
  y si esa laguna es recuperable por alguna operación no usada. Si no lo es, el
  eje temático nace con un sesgo que hay que declarar en el portal, no esconder.
- **d) Tramitación y estado:** ¿se puede saber en qué etapa está un proyecto, con
  fechas? ¿Es un estado puntual o una serie de trámites?
- **e) Autoría:** ¿quién patrocina o firma cada moción, y los identificadores de
  autor **empalman con el padrón de parlamentarios** que el proyecto ya usa? Si no
  empalman, el eje temático no se puede cruzar con el eje persona, que es
  justamente lo que lo haría valioso.
- **f) Simetría con el Senado:** todo lo anterior, ¿existe también del lado del
  Senado? Un eje temático que solo cubre la Cámara es aceptable como fase 1, pero
  la respuesta debe ser explícita y no un silencio.

**La cifra que manda es la cobertura de la cadena voto → proyecto → materia sobre
el universo del corte vigente.** Si esa cadena se cierra para una fracción baja de
los votos, el eje temático es una promesa y no un producto, y este encargo tiene
que decirlo con el número en la mano.

---

## 2. Contexto mínimo suficiente

### 2.1 El proyecto

Portal serverless de transparencia legislativa de Chile. Scripts en R consolidan
API públicas en JSON estáticos que consume un `docs/index.html` de una pieza,
servido por GitHub Pages desde `/docs`. Raíz:
`/Users/tomgc/Projects/transparencia_legislativa_chile`.

### 2.2 Lo que ya está decidido y no se re-discute

- **D1:** el Senado entra por un pipeline extendido con capa de normalización, no
  por un pipeline paralelo ni por un esquema distinto.
- **D2:** el contrato de asistencia es **simétrico** entre cámaras: serie nominal
  por sesión, con estado por parlamentario y por sesión, no un agregado.
- **D3:** la llave es compuesta, `(camara, parlamentario_id)`, con fecha de
  captura. Los espacios de identificadores de Cámara y Senado son **distintos**;
  no hay colisión que resolver, hay que declarar la separación.
- **D18:** el titular de asistencia del portal es
  `asistencia.periodo_vigente.tasa_presencia`.

Este encargo **no revisa estas decisiones**. Las usa como vara: mide si las
fuentes las soportan.

Lo que este encargo **sí** puede proponer, porque todavía no está decidido, es la
forma del contrato del eje temático. Propone; no decide y no implementa.

### 2.3 Dónde mirar en el propio repositorio antes de salir a la red

- `30_procesamiento/32_extraer_diputados.R`, `33_extraer_asistencia.R`,
  `34_extraer_votaciones.R`, `35_extraer_proyectos.R`,
  `36_extraer_detalle_proyectos.R`: las 8 operaciones que **sí** se usan, con su
  forma de invocación real y su manejo de caché. Los dos últimos son los más
  relevantes para el eje temático.
- `10_utils/10_utils.R` y `10_utils/10_configuracion.R`: utilidades de descarga,
  caché, sellado y validación de corte. **Reúsalas**; no escribas un cliente HTTP
  nuevo si ya hay uno.
- `40_salidas/intermedios/proyectos.rds`, `proyectos_detalle.rds` y `votos.rds`:
  el universo real sobre el que se miden las coberturas del eje temático. De ahí
  salen también los identificadores para muestrear (ver 🔒 sobre identificadores
  inventados).
- `50_documentacion/activa/exploracion_api_camara.md` y
  `50_documentacion/andamios/31_explorar_api_camara.R`: exploración previa del
  servicio de la Cámara.
- `50_documentacion/andamios/explorar_contenido_proyectos.R`: exploración previa
  específica del contenido de proyectos. **Léelo antes de sondear nada temático**:
  es el intento anterior sobre este mismo terreno.
- `50_documentacion/andamios/muestras/`: respuestas crudas ya capturadas, incluidas
  `catalogo_materias.xml`, `proyecto_con_materias_10986_24.xml`,
  `proyecto_18211_25.xml`, `votaciones_x_proyecto_16857_07.xml` y
  `votaciones_x_proyecto_18211_25.xml`. Son pistas de qué existe, **no evidencia
  vigente**: se usan para orientar el sondeo y se re-derivan.
- `50_documentacion/activa/encargo_contrato_datos_camara_senado.md` y
  `50_documentacion/activa/encargo_exploracion_asistencia_senado_h1bis.md`:
  exploraciones previas del lado del Senado. **Léelos antes de empezar**:
  contienen hallazgos que no hay que redescubrir y, posiblemente, callejones sin
  salida ya recorridos.

---

## 3. Invariantes (🔒)

- 🔒 **Solo lectura sobre el proyecto.** No se modifica ningún script del
  pipeline, ningún JSON publicado, ningún archivo de `docs/`. Lo único que este
  encargo escribe son los artefactos del contrato de salida (sección 4).
- 🔒 **No mergees ningún PR, no dispares el workflow de GitHub Actions, no
  escribas en `main`.** `main` quedó limpio al cerrar P-58 y este encargo trabaja
  en rama propia y termina en PR abierto, nunca mergeado.
- 🔒 **R es el único lenguaje** para toda consulta, parseo e inspección de datos.
  Prohibido `jq`, `awk`, `python` y prohibido `grep`/`sed` sobre artefactos de
  datos. Sobre código fuente puedes buscar con las herramientas del entorno.
- 🔒 **Ningún identificador inventado.** Todo muestreo usa identificadores reales
  leídos de `40_salidas/intermedios/` o devueltos por la propia API. Probar una
  operación con un ID fabricado y concluir que "no devuelve datos" es exactamente
  el error que este encargo existe para no cometer.
- 🔒 **Ausencia de dato ≠ ausencia de capacidad.** Si una operación devuelve vacío
  para el muestreo, se registra como *sin datos para los parámetros probados*, con
  los parámetros declarados. Nunca como *no expone*.
- 🔒 **No se fabrica semántica.** Si el significado de un campo no consta en la
  fuente, se registra como *no documentado*, no se deduce del nombre. Esta es la
  regla que mantiene a P2 honestamente bloqueado en vez de falsamente resuelto, y
  la que impide que una materia se infiera del título de un proyecto.
- 🔒 **Ninguna cobertura se estima sobre una muestra conveniente.** Toda cifra de
  cobertura del eje temático se calcula sobre el universo completo del corte
  vigente que ya está en `40_salidas/intermedios/`, con el denominador declarado
  en la misma línea. Si el cálculo exige más tráfico del razonable, se mide sobre
  una muestra **aleatoria** con su tamaño y su método declarados, y se dice que es
  una muestra.
- 🔒 **Amabilidad con las APIs públicas.** Ambos servicios son infraestructura
  pública de un tercero. **Máximo 4 agentes concurrentes en cualquier fase que
  toque la red**, pausa entre llamadas, y toda respuesta se cachea en disco para
  no repetir una descarga ya hecha. Si un servicio empieza a devolver errores o a
  degradarse, esa rama **se detiene** y se registra; no se reintenta en bucle.
- 🔒 **`20_insumos/camara/` es dato crudo inmutable y no se toca.** Todo lo que
  descargue esta exploración va a `20_insumos/exploracion/<AAAAMMDD>/`, un
  directorio nuevo y separado, para que la exploración no contamine el insumo del
  pipeline.
- 🔒 **`senadores_vigentes.php` no se usa como fuente de padrón** para el período
  vigente: ya se comprobó que no es confiable. Puede inventariarse como operación,
  con esa advertencia registrada.
- 🔒 **El repositorio es público.** Ningún artefacto de salida incluye rutas
  locales del titular, tokens, cabeceras de autenticación ni nada que no deba
  quedar publicado.

---

## 4. Contrato de salida

Cinco artefactos, todos en la rama de trabajo, ninguno mergeado.

### 4.1 `50_documentacion/activa/50_catalogo_fuentes_camara.md`

Una fila por operación expuesta por el servicio. **El universo debe salir del
descriptor del propio servicio** (WSDL o equivalente), no de los scripts del
proyecto ni de una lista recordada: el denominador se declara y se cita su fuente.

Por operación:

| Campo | Contenido |
|---|---|
| Operación | Nombre exacto |
| Estado | `EN USO` (con el script que la invoca) / `NO USADA` |
| Parámetros | Nombre, tipo, obligatoriedad |
| Campos de respuesta | Nombre, tipo, y si es llave |
| Llave | Cuál identifica unívocamente la fila |
| Granularidad | Qué representa una fila |
| Cobertura probada | Qué parámetros se probaron y qué devolvió |
| Solapamiento | Si duplica algo que el proyecto ya obtiene por otra vía |
| Eje | `persona` / `temático` / `ambos` / `ninguno`: a qué eje del portal sirve |
| Utilidad potencial | Qué pendiente o capacidad habilitaría, o "ninguna aparente" |
| Notas | Rarezas, campos sin documentar, inconsistencias |

Y al final, cuatro secciones cerradas:

- **Veredicto sobre P2:** ¿alguna operación documenta o permite derivar la
  semántica de `RebajaAsistencia` / `RebajaQuorum`? Sí (con cuál y cómo), o no
  (con la lista de las que se descartaron y por qué).
- **Operaciones que sirven al eje temático**, listadas aparte y ordenadas por lo
  que aportan a la cadena voto → proyecto → materia.
- **Operaciones que valdría la pena consumir**, ordenadas por valor para el
  portal, cada una con qué agrega y qué costaría.
- **Denominador declarado:** cuántas operaciones expone el descriptor, cuántas se
  probaron, cuántas quedaron sin probar y por qué.

### 4.2 `50_documentacion/activa/50_catalogo_fuentes_senado.md`

Misma estructura, adaptada al backend del Senado. Además, obligatoriamente:

- **Padrón:** cuál es la fuente confiable de senadores del período vigente, con la
  evidencia de por qué es confiable (no basta que responda: tiene que cuadrar
  contra algo independiente).
- **Identificadores:** qué espacio de IDs usa, si es estable en el tiempo, y cómo
  se relaciona (o no) con el de la Cámara.
- **Sesiones:** existe o no un catálogo de sesiones del Senado, con fecha y
  legislatura.
- **Asistencia:** existe o no asistencia **nominal por sesión**; si solo hay
  agregados, decirlo con todas las letras.
- **Votaciones, proyectos y materias:** qué hay, con el mismo desglose de §1.1
  aplicado al Senado. Si el eje temático no es simétrico entre cámaras, esa
  asimetría es un hallazgo de primer orden y va declarada, no en una nota al pie.

### 4.3 `50_documentacion/activa/50_veredicto_contrato_simetrico_senado.md`

Corto, decidible, sin relleno:

1. **Veredicto sobre D2:** el contrato simétrico de asistencia nominal por sesión
   ¿es construible para el Senado? `SÍ` / `NO` / `SÍ CON LAGUNAS`.
2. **Mapeo campo a campo** entre el contrato actual de la Cámara (léelo del JSON
   publicado y del `39`) y lo que el Senado puede entregar. Tres columnas: campo
   de la Cámara, equivalente en el Senado, veredicto (`directo`, `derivable`,
   `ausente`).
3. **Lagunas**, cada una con: qué falta, qué la haría salvable, y qué costaría.
4. **Plan de construcción propuesto**, en el nivel de detalle que permita
   convertirlo en encargos: qué scripts nuevos, qué capa de normalización, qué
   orden, qué se puede verificar en cada paso. **Propuesta, no ejecución.**
5. **Riesgos**, con el que más te preocupe primero.

### 4.4 `50_documentacion/activa/50_veredicto_eje_tematico.md`

El artefacto de mayor valor de este encargo. Mismo estándar: corto, decidible, con
las cifras y su denominador en la misma línea.

1. **Veredicto:** el eje temático (proyectos, materias y votaciones como entidades
   de primera clase) ¿es construible con las fuentes disponibles?
   `SÍ` / `NO` / `SÍ CON LAGUNAS`. Una de las tres formas cerradas, nunca prosa
   evasiva.
2. **Tabla de cobertura de la cadena**, una fila por eslabón de §1.1, con
   numerador, denominador y fuente del conteo:

   | Eslabón | Cobertura | Denominador | Artefacto del que sale |
   |---|---|---|---|
   | Catálogo de materias existe y es estable | | | |
   | Proyecto → materia | | | |
   | Votación → proyecto | | | |
   | Proyecto → tramitación | | | |
   | Proyecto → autoría | | | |
   | Autor → padrón de parlamentarios | | | |

3. **Diagnóstico del eslabón roto:** por qué ~32 % de los votos no empalma con un
   proyecto, si es recuperable, y por qué vía. Si no es recuperable, cómo debería
   declararse ese sesgo en el portal para no publicar una cobertura implícita
   falsa.
4. **Contrato propuesto para la entidad temática:** qué JSON nuevo o qué bloque
   nuevo haría falta, con qué llave, qué granularidad y qué relación con los
   perfiles ya publicados. Incluye qué preguntas quedarían respondidas y, más
   importante, **cuáles no**. Propuesta, no decisión.
5. **Simetría con el Senado:** el eje temático ¿nace en las dos cámaras o solo en
   la Cámara? Con evidencia.
6. **Plan de construcción propuesto**, convertible en encargos: qué scripts, qué
   orden, qué se verifica en cada paso, qué se puede publicar primero.
7. **Riesgos**, con el que más te preocupe primero.

### 4.5 `20_insumos/exploracion/<AAAAMMDD>/` y su script reproductor

El sondeo se hace con un script en R que queda guardado en
`50_documentacion/andamios/<AAAAMMDD>_sondeo_fuentes.R`, y las respuestas crudas
quedan cacheadas en `20_insumos/exploracion/<AAAAMMDD>/`. Esto no es burocracia:
un catálogo que no se puede volver a derivar es una afirmación de memoria, y este
proyecto tiene un patrón documentado de errores por afirmar sin releer. **Si el
catálogo no se puede reproducir corriendo un archivo, el encargo no está
terminado.**

Si la exploración pesa lo suficiente como para ensuciar el repositorio, cachea
igual pero añade el directorio a `.gitignore` y decláralo en el log: la
reproducibilidad la da el script, no los bytes.

---

## 5. Criterios de éxito contrastables

Cada uno debe poder fallar ruidosamente. Un criterio que no puede fallar no es un
criterio.

| # | Criterio | Cómo se contrasta |
|---|---|---|
| 1 | El universo de operaciones de la Cámara sale del descriptor del servicio | El catálogo cita el descriptor y su total; el número no proviene de ningún script del proyecto |
| 2 | Las 8 operaciones en uso aparecen en el catálogo marcadas `EN USO`, con el script que las invoca | Contraste programático contra los scripts `32`–`36` |
| 3 | Toda operación marcada como probada tiene registrada la llamada real y su respuesta | El caché de `20_insumos/exploracion/` contiene la respuesta de cada una |
| 4 | El veredicto de P2 es una de las dos formas cerradas, nunca "no está claro" | Lectura del documento |
| 5 | La fuente de padrón del Senado cuadra contra una fuente independiente | Se declara cuál y qué diferencia hubo (cero o la que sea) |
| 6 | El veredicto sobre D2 es `SÍ` / `NO` / `SÍ CON LAGUNAS`, nunca prosa evasiva | Lectura del documento |
| 7 | El mapeo campo a campo cubre **todos** los campos del contrato de asistencia vigente | Contraste contra el bloque `asistencia` de un perfil publicado real |
| 8 | Todo el catálogo se reproduce corriendo el script de sondeo | Correrlo de nuevo y comparar |
| 9 | Ningún archivo del pipeline cambió | `git status` acotado a `10_utils/`, `30_procesamiento/`, `docs/`, `40_salidas/` |
| 10 | El veredicto del eje temático es `SÍ` / `NO` / `SÍ CON LAGUNAS` | Lectura del documento |
| 11 | Los seis eslabones de la tabla de cobertura tienen numerador **y** denominador, contados programáticamente en el momento de escribirlos | Ninguna celda vacía ni con cifra sin artefacto declarado |
| 12 | La cobertura de proyecto → materia se mide sobre el universo persistido, no sobre las muestras de `andamios/muestras/` | El script de sondeo lee `40_salidas/intermedios/` como denominador |
| 13 | El empalme autor → padrón se contrasta contra los identificadores reales del proyecto y se declara la tasa de empalme | Contraste programático contra `40_salidas/intermedios/diputados.rds` |
| 14 | El eslabón roto voto → proyecto tiene diagnóstico y no solo constatación | El documento dice por qué falta y si es recuperable, con evidencia |

---

## 6. Exigencias de calidad (esto es lo que separa un catálogo útil de una lista)

- **Verificación adversarial de los hallazgos de alto riesgo.** Los cuatro que hay
  que re-derivar con agentes independientes, con código propio, sin reutilizar el
  del hallazgo original: el **veredicto de P2**, la **fuente de padrón del
  Senado**, la **existencia de asistencia nominal por sesión en el Senado**, y la
  **cobertura de la cadena voto → proyecto → materia**. Un falso positivo en
  cualquiera de los cuatro manda al proyecto a construir sobre arena. El cuarto es
  el más peligroso de todos, porque una cobertura sobreestimada produce un portal
  que responde preguntas temáticas con datos parciales sin decirlo. Si el
  verificador no puede confirmar ni refutar, se reporta como **no verificado**,
  que no es lo mismo que refutado.
- **Cada afirmación con su fuente en la misma línea**, en los cuatro documentos:
  el archivo leído o la llamada hecha. Una afirmación sin fuente es una hipótesis
  y se marca como tal, con el comando que la resolvería.
- **Las cifras se cuentan programáticamente en el momento de escribirlas.**
  Aritmética mental, cifras heredadas de otro documento y cifras recordadas no son
  fuentes. Esto incluye las cifras de este propio encargo: los 65 478 / 30 919 de
  §1.1 son el punto de partida, no un resultado, y se recuentan.
- **Lo que no se pudo probar se dice.** Un catálogo con huecos declarados vale
  más que uno completo por relleno. El objetivo es un documento sobre el que se
  pueda decidir, no uno que se vea terminado.
- **Prefiere el fan-out ancho al agente largo.** Si el runtime interrumpe la
  corrida, un fan-out de agentes cortos conserva mucho más trabajo hecho que unos
  pocos agentes largos.

---

## 7. Orden sugerido (no prescriptivo)

Lo determinista antes que lo interpretativo; lo local antes que la red.

1. Lectura del repositorio: scripts `32`–`36`, `10_utils/`, la exploración previa
   de contenido de proyectos y los dos encargos de exploración del Senado. Sin red.
2. Descriptor del servicio de la Cámara y construcción del universo de
   operaciones. Denominador declarado.
3. **Medición local del eje temático**: todo lo que se puede contar sin salir a la
   red, leyendo `40_salidas/intermedios/`. Aquí sale el denominador real de la
   cadena y probablemente el diagnóstico del eslabón roto.
4. Sondeo de la Cámara, con identificadores reales y caché, cubriendo a la vez las
   operaciones no usadas y las que sirven al eje temático.
5. Backend del Senado: descubrimiento, padrón, sesiones, asistencia, materias.
6. Mapeo contra el contrato vigente, veredicto sobre D2 y veredicto sobre el eje
   temático.
7. Panel adversarial sobre los cuatro hallazgos de alto riesgo.
8. Escritura de los artefactos, commits atómicos, rama, PR.

Si tu descomposición encuentra un orden mejor, úsalo. **Lo único no negociable es
que el panel adversarial vaya después de los hallazgos y antes del PR**, y que la
medición local (paso 3) preceda al sondeo de red, porque es la que define qué vale
la pena sondear.

---

## 8. Cierre

- Rama: `auditoria/fuentes-camara-senado`, desde `origin/main` actualizado.
- Commits atómicos por artefacto, con `git add` de ruta acotada (nunca `git add .`).
- Comandos de git con `git -C /Users/tomgc/Projects/transparencia_legislativa_chile`;
  subcomandos de `gh` con `-R tomgc/transparencia_legislativa_chile`. Prohibido
  `gh pr diff --name-only` en este repositorio.
- **Log** en `50_documentacion/andamios/logs/<AAAAMMDD>_auditoria_fuentes_log.md`:
  qué se probó, qué falló, qué quedó sin probar y por qué, veredicto de cada
  agente del panel, y las notas para el revisor.
- **PR abierto y no mergeado.** El cuerpo lleva: los cuatro veredictos (eje
  temático, P2, padrón del Senado, D2), el denominador de operaciones, la tabla de
  cobertura de la cadena temática, y una línea que diga que este PR no toca el
  pipeline.
- **Reporte final al chat**, compacto: rama, URL del PR, los cuatro veredictos, la
  cobertura de la cadena con su denominador, el denominador de operaciones, qué
  quedó sin probar, y la ruta del log. El detalle vive en los documentos; el
  reporte es el índice.

---

## 9. Regla de detención

Un workflow no admite intervención a mitad de corrida, así que aquí no hay gates
de titular: **lo que en otro encargo sería una pregunta, aquí es un registro**.
Ante una ambigüedad, documenta las alternativas y sigue con la más conservadora,
dejando la decisión anotada en el log.

Detente de verdad, y reporta, solo si:

- cumplir una instrucción te obligaría a cruzar un 🔒;
- un servicio público empieza a degradarse o a bloquear (ahí paras esa rama,
  registras, y no reintentas);
- descubres que una premisa estructural del proyecto es falsa (por ejemplo, que
  los IDs del Senado **no** son estables, contra lo que el proyecto tiene
  registrado, o que el catálogo de materias no tiene identificadores estables
  entre cortes). Eso no se resuelve dentro de una corrida: se reporta.
