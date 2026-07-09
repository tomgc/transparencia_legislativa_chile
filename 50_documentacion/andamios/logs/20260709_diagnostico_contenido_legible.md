# Diagnóstico — Contenido legible de proyectos y trazabilidad voto → proyecto

**Fecha:** 2026-07-09
**Rama:** `explore/contenido-proyectos-votos` (no `main`, sin push)
**Naturaleza:** andamio de diagnóstico (insumos-first). NO toca el pipeline de
producción ni `40_salidas/`. Todo en R (httr/xml2/dplyr).
**Script reproducible:** `50_documentacion/andamios/explorar_contenido_proyectos.R`
**Muestras crudas reales:** `50_documentacion/andamios/muestras/*.xml`

Toda afirmación de este documento sobre "la API expone X" está respaldada por
una respuesta real capturada en `muestras/` y verificada por la auto-auditoría
(sección 7). Los porcentajes se recalcularon en R sobre la captura real, no se
estimaron.

---

## 0. Rutas reales de la instrumentación (halladas por el escáner)

Confirmadas contra `50_documentacion/estructura/estructura_actual.md`, no
supuestas:

| Rol | Ruta |
|-----|------|
| Extrae VOTACIONES | `30_procesamiento/34_extraer_votaciones.R` |
| Extrae PROYECTOS/mociones | `30_procesamiento/35_extraer_proyectos.R` |
| Cliente HTTP (backoff, timeout) | `10_utils/10_utils.R` → `descargar_xml_camara()` |
| Config / constantes | `10_utils/10_configuracion.R` |
| Exploración previa (sesión 1) | `30_procesamiento/31_explorar_api_camara.R` |
| Consolidación a JSON | `30_procesamiento/39_consolidar_json.R` |

**Qué extrae hoy cada uno (lo relevante para el diagnóstico):**
- `34` parsea de `retornarVotacionDetalle`: `Descripcion`, `Fecha`, `Resultado`,
  `Tipo`, y por diputado `OpcionVoto`. El **boletín lo obtiene por regex** sobre
  `Descripcion` (`[0-9]{3,6}-[0-9]{1,2}`). `39` propaga al JSON `votacion_id`,
  `boletin`, `fecha`, `resultado`, `sentido`, `descripcion` — **pero NO `tipo`**.
- `35` parsea de `retornarProyectoLey` **solo** `//Autores/ParlamentarioAutor/
  Diputado`. **Descarta** `TipoIniciativa`, `Materias` y `Votaciones` del mismo
  response.

---

## 1. PREGUNTA 1 — Contenido legible de proyectos

### 1.1 Qué SÍ expone `retornarProyectoLey?prmNumeroBoletin=<bol>`

Árbol real (muestra `muestras/proyecto_18211_25.xml`, boletín 18211-25):

| Campo | Ejemplo real | ¿Lo usa el pipeline? |
|-------|--------------|:--:|
| `Id` (id interno del proyecto) | `18875` | No |
| `NumeroBoletin` | `18211-25` | Sí |
| `Nombre` (título largo) | "Modifica el código penal… ocultamiento de identidad…" | Sí |
| `FechaIngreso` | `2026-04-22T00:00:00` | Sí |
| `TipoIniciativa` (Valor) | `Moción` (Valor=2) | **No** |
| `CamaraOrigen` (Valor) | `Cámara de Diputados` (Valor=1) | Sí (para filtrar) |
| `Admisible` | `true` | Sí |
| `Autores/ParlamentarioAutor/{Orden, Diputado}` | Orden=0, Diputado 1259 | Sí |
| `Materias/Materia/{Id, Nombre}` | (ver 1.2) | **No** |
| `Votaciones/VotacionProyectoLey/…` | (ver Pregunta 2) | **No** |

### 1.2 Materias (categoría temática): existe, cobertura PARCIAL

- El nodo `Materias/Materia/{Id, Nombre}` es la **categorización temática** del
  proyecto (etiquetas legibles).
- **Cobertura parcial y sesgada a proyectos antiguos/avanzados.** Recalculado en
  R sobre boletines reales:
  - Mociones recientes de 2026 (18211-25, 18048-06, 18157-33): **0 materias**.
  - Proyecto más antiguo 10986-24: **4 materias reales** →
    `BALDOMERO LILLO FIGUEROA`, `MONUMENTOS`, `COMUNA DE LOTA`, `ESCRITOR CHILENO`
    (muestra `muestras/proyecto_con_materias_10986_24.xml`).
  - De 8 boletines de Proyecto de Ley probados, solo 1 traía materias.
- Existe además el **catálogo completo** `retornarMaterias` (sin parámetros):
  **8.518 materias** con `{Id, Nombre}` (muestra `muestras/catalogo_materias.xml`,
  836 KB). Es el diccionario; la asignación por proyecto es lo que viene ralo.

### 1.3 Qué NO expone la API (huecos reales de contenido)

Verificado sobre el response crudo (auto-auditoría): `retornarProyectoLey`
**NO** trae ninguno de estos:
- **Resumen / sumilla / idea matriz / descripción extendida.** El único texto de
  contenido es `Nombre` (el título). No hay nodo `Sumilla`, `Resumen`,
  `IdeaMatriz` ni una `Descripcion` a nivel de proyecto.
- **Enlace al texto oficial / al expediente.** No hay URL ni identificador de
  documento en el response.
- **Estado / etapa de tramitación *actual* del proyecto** como campo propio.
  (Hay trámite por votación — ver 1.4 y Pregunta 2 — pero no un "estado vigente"
  del proyecto.) Concuerda con el hueco ya documentado en sesión 1.

### 1.4 Etapa/trámite: solo como catálogo o por-votación, no "estado actual"

- `retornarTramitesConstitucionales` (6 tipos) y `retornarTramitesReglamentarios`
  (8 tipos) son **catálogos de TIPOS de trámite, sin parámetros** — no devuelven
  la etapa de un proyecto concreto.
- La etapa **sí aparece por votación**, dentro de `VotacionProyectoLey`
  (`TramiteConstitucional`, `TramiteReglamentario`) — ver Pregunta 2. Es "en qué
  trámite estaba el proyecto al momento de esa votación", no el estado vigente.

---

## 2. PREGUNTA 2 — Trazabilidad voto → proyecto

### 2.1 El detalle de la votación NO trae referencia estructurada al proyecto

`retornarVotacionDetalle?prmVotacionId=` (muestra
`muestras/votacion_detalle_89288.xml`) a nivel votación trae solo: `Id`,
`Descripcion`, `Fecha`, `TotalSi/No/Abstencion/Dispensado`, `Quorum`,
`Resultado`, `Tipo`, y los 155 `Voto`. **No hay `Boletin`, `NumeroBoletin` ni
`ProyectoLey` como campo.** El único vínculo al proyecto desde la votación es el
**texto** de `Descripcion` (p. ej. "Boletín N° 16851-14") → de ahí el regex del
pipeline. Confirmado por auto-auditoría.

### 2.2 Existe un vínculo ESTRUCTURADO en sentido proyecto → votaciones

`retornarProyectoLey` (y su equivalente `retornarVotacionesXProyectoLey`, que
devuelve **bytes idénticos** para el mismo boletín) trae
`Votaciones/VotacionProyectoLey`, con campos que el pipeline hoy **no** captura
(muestra `muestras/votaciones_x_proyecto_18211_25.xml`):

| Campo de `VotacionProyectoLey` | Ejemplo | Utilidad |
|--------------------------------|---------|----------|
| `Id` | `89242` | **Llave de join** votación ↔ proyecto (estructurada, sin regex) |
| `Descripcion`, `Fecha`, `Resultado`, `Quorum`, `Tipo` | — | metadatos de la votación |
| `TotalSi/No/Abstencion/Dispensado` | 100/36/2/0 | tablero |
| `TipoVotacionProyectoLey` (Valor) | `General` (Valor=1) | **general vs. particular** (¿voto de idea de legislar o de un artículo?) |
| `Articulo` | (vacío en general) | qué artículo se votó (en votaciones particulares) |
| `TramiteConstitucional` (Id) | `Primer Trámite` (Id=1) | **etapa** al momento del voto |
| `TramiteReglamentario` (Id) | `Primer Informe` (Id=1) | etapa reglamentaria |

Un proyecto puede tener **varias** `VotacionProyectoLey` (ej. 16857-07 → 9;
15936-18 → 10; 16851-14 → 3): la votación general y las particulares por artículo.

### 2.3 Mecanismo de join real y su cobertura (recalculado en R)

**Dos mecanismos, que concuerdan:**
1. **Regex sobre `Descripcion`** (lo que hace el pipeline). Extrae el boletín del
   texto de la votación.
2. **Estructurado**: iterar proyectos → `VotacionProyectoLey/Id` construye el
   mapa `votacion_id → boletin` sin regex, y de paso aporta etapa/tipo/artículo.

**Verificación de la cadena con ids reales** (muestra + captura): proyecto
18211-25 → `VotacionProyectoLey/Id` = 89242 → esa votación **está** en la captura
de votos, con `boletin` parseado por regex = 18211-25. **Ambos mecanismos dan el
mismo mapeo.**

**Cobertura del vínculo por boletín** (recalculada sobre `votos.rds`,
672 votaciones únicas de 2026):

| `Tipo` de votación | sin boletín | con boletín |
|--------------------|:--:|:--:|
| Proyecto de Ley | 0 | **460** |
| Proyecto de Acuerdo | 20 | 0 |
| Proyecto de Resolución | 97 | 0 |
| Otros (acusación constitucional, informe comisión…) | 95 | 0 |

- **460 de 672 (68,5 %) tienen boletín; el 31,5 % restante NO es pérdida de
  parseo: es estructural.** Todas las votaciones `Proyecto de Ley` (460/460)
  tienen boletín; las 212 sin boletín son votaciones sobre instrumentos que **no
  tienen boletín por naturaleza** (acuerdos, resoluciones, acusaciones, informes).
- Dicho de otro modo: **el regex tiene recall 100 % sobre las votaciones que
  vinculan a un proyecto de ley.** El campo `Tipo` (ya capturado en el intermedio,
  pero no propagado al JSON) explica por completo el hueco.

**Se puede reconstruir "el diputado X votó [sentido] el proyecto boletín Y, que
trata de Z"?** Sí para votaciones de Proyecto de Ley: `votacion_id → boletin`
(regex o estructurado) → `retornarProyectoLey` → `Nombre` (título) + `Materias`
(cuando existen). El "de qué trata" queda en el **título** siempre, y en las
**materias** solo cuando el proyecto las tiene pobladas (1.2).

---

## 3. Recomendaciones de campos a incorporar al pipeline

> Recomendaciones de diagnóstico; NO implementadas (este encargo no toca
> producción). Cada una es de bajo costo: los datos ya vienen en responses que
> el pipeline **ya descarga**, solo se están descartando.

### 3.1 En votaciones (`34` → `votos.rds` → `39`)
- **Propagar `tipo` al JSON** (ya se captura en `votos.rds`; `39` lo omite en el
  bloque `votos` del perfil). Hace legible por qué una votación no tiene boletín
  ("Proyecto de Acuerdo", "Otros") en vez de mostrar "Sin boletín" a secas.

### 3.2 En proyectos (`35` → `proyectos.rds` → `39`)
Del mismo `retornarProyectoLey` que `35` ya baja:
- **`TipoIniciativa`** (Moción/Mensaje) — un `attr Valor` + texto.
- **`Materias`** (`Id` + `Nombre`) — categoría temática legible. Marcar el hueco
  cuando viene vacío (mayoría de mociones 2026), no inventarla.
- **`Votaciones/VotacionProyectoLey`** — para cada proyecto, la lista de sus
  votaciones con `Id`, `TipoVotacionProyectoLey` (general/particular), `Articulo`,
  `TramiteConstitucional`/`TramiteReglamentario` (etapa), y tablero. Habilita:
  (a) mostrar en la ficha del proyecto "se votó en general el 24-jun, aprobado
  100-36-2, primer trámite"; (b) un **join estructurado** `votacion_id → boletin`
  como alternativa/refuerzo al regex, con la etapa incluida.

### 3.3 Enriquecimiento cruzado voto ↔ proyecto
- Con `VotacionProyectoLey/Id`, el bloque `votaciones` del perfil de un diputado
  podría enlazar cada voto de Proyecto de Ley a: título del proyecto, materias
  (si hay), tipo de votación (general/particular) y etapa. Hoy el perfil solo
  tiene boletín + descripción + resultado + sentido.

---

## 4. Muestras reales capturadas (`50_documentacion/andamios/muestras/`)

| Archivo | Qué demuestra |
|---------|---------------|
| `proyecto_18211_25.xml` | Estructura completa de un proyecto (Materias vacío, Votaciones con trámite) |
| `proyecto_con_materias_10986_24.xml` | Proyecto con 4 materias reales pobladas |
| `catalogo_materias.xml` | Catálogo `retornarMaterias`: 8.518 materias |
| `votacion_detalle_89288.xml` | Detalle de votación: sin ref estructurada al proyecto |
| `votaciones_x_proyecto_18211_25.xml` | `retornarVotacionesXProyectoLey` (idéntico a `retornarProyectoLey`) |
| `votaciones_x_proyecto_16857_07.xml` | Proyecto con 9 votaciones (general + particulares) |
| `hallazgos_muestra.rds` | Tidy: boletines de muestra, votación de muestra, árbol del proyecto |

---

## 5. Respuesta resumida a las dos preguntas

- **P1 (contenido):** La API expone, por proyecto, `TipoIniciativa` y `Materias`
  (categoría temática, `Id`+`Nombre`) — pero las materias vienen **pobladas solo
  en una minoría** de proyectos (0 en las mociones 2026 probadas). **NO** expone
  resumen/sumilla/idea matriz, ni enlace al texto oficial, ni estado de
  tramitación vigente. El "de qué trata" legible hoy = título (`Nombre`) siempre
  + materias cuando existen.
- **P2 (trazabilidad):** La votación **no** trae el proyecto como campo
  estructurado (solo el boletín embebido en `Descripcion` → regex). Pero el
  proyecto **sí** trae sus votaciones (`VotacionProyectoLey/Id`) de forma
  estructurada, con etapa y tipo de votación. El join por boletín cubre el
  **100 % de las votaciones de Proyecto de Ley** (460/460); el 31,5 % de
  votaciones sin boletín es estructural (acuerdos/resoluciones/otros sin boletín),
  no un fallo de parseo.

---

## 6. Marcas `# REVISAR` abiertas

- **# REVISAR (cobertura de Materias):** ¿por qué las mociones 2026 no traen
  materias y un proyecto antiguo (10986-24) sí? Hipótesis no confirmada: las
  materias se asignan en una etapa posterior de tramitación. No se pudo
  determinar la regla exacta con la muestra; **no se infiere**. Requeriría
  muestrear por año/etapa para cuantificar la cobertura real.
- **# REVISAR (estado de tramitación vigente):** sigue sin exponerse un "estado
  actual" del proyecto; solo etapa por votación. Confirma el hueco de sesión 1.
- **# REVISAR (enlace al texto):** no hay URL al expediente/oficio en ningún
  response explorado. Si se quisiera el texto del proyecto, habría que evaluar
  otra fuente (sitio web de la Cámara, no la API WServices).
- **# REVISAR (`retornarVotacionesXProyectoLey` vs `retornarProyectoLey`):**
  devuelven bytes idénticos para el mismo boletín en la muestra; parecen
  redundantes. No se probó si difieren en algún boletín con muchas votaciones.

---

## 7. Auto-auditoría (respaldo de cada afirmación)

Ejecutada en R contra los XML crudos guardados (no contra deducción). 11/11
verificaciones PASA:

- proyecto crudo tiene `VotacionProyectoLey`, `TramiteConstitucional`,
  `VotacionProyectoLey/Id`, `TipoIniciativa`, nodo `Materias` — PASA.
- proyecto crudo **NO** tiene `Sumilla/Resumen/IdeaMatriz` — PASA (hueco real).
- 10986-24 crudo tiene 4 `Materia` — PASA (materias sí se llenan en algunos).
- votación detalle **NO** trae boletín/proyecto estructurado, sí `Descripcion`+
  `Tipo` — PASA.
- catálogo de materias crudo > 1000 materias — PASA.
- 16857-07 crudo tiene 9 `VotacionProyectoLey` — PASA.

Cobertura (68,5 %; cruce Tipo × boletín) recalculada en R sobre `votos.rds`, no
estimada.
