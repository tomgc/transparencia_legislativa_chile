# Exploracion API Senado v02 — cierre de los huecos de v01

> Segundo diagnostico insumos-first (rama `explore/api-senado-v02`). Continua
> `exploracion_api_senado.md` (v01). Las muestras las regenera
> `30_procesamiento/31c_explorar_api_senado_v02.R` en
> `50_documentacion/andamios/exploracion_api_senado_v02/`. NO se construyo pipeline.

- **Fecha:** 2026-07-10
- **Hallazgo central:** el sitio `senado.cl` esta respaldado por un **backend JSON
  moderno**, `https://web-back.senado.cl/api/` (+ un Drupal JSON:API en
  `/jsonapi/`). Ese backend expone roster, asistencia y votaciones **con un
  identificador estable de parlamentario (`ID_PARLAMENTARIO` / `PARLID`)**
  consistente entre las tres entidades. Resuelve los tres huecos de v01 y
  **elimina el fuzzy name matching** que v01 daba por inevitable.
- **`opendata.congreso.cl` NO es una API nueva:** es un **portal de documentacion**
  que enlaza los servicios ya conocidos — `wspublico` del Senado (v01, name-based)
  y `wscamaradiputados.asmx` de la Camara. Su Drupal `jsonapi` tiene
  `node--parlamentarios` (con `field_id` = PARLID) pero es delgado; el backend de
  datos util es `web-back.senado.cl`.

## Estado de los tres huecos

| Hueco | Estado v02 | Fuente que lo resuelve |
|-------|-----------|------------------------|
| **H1 — Asistencia nominal** | ✅ **RESUELTO** | `web-back.senado.cl/api/sessions/attendance?id_legislatura=<id>` |
| **H2 — Roster de 50 senadores** | ✅ **RESUELTO** (50 exactos) | `web-back.senado.cl/api/parlamentarios?vigentes=1` filtrando `CAMARA=="S"` |
| **H3 — opendata.congreso.cl + ids estables** | ✅ **RESUELTO** (por el backend, no por opendata.congreso.cl) | `web-back.senado.cl/api/*` con `ID_PARLAMENTARIO`/`PARLID` |

### H1 — Asistencia nominal (RESUELTO)
`GET /api/sessions/attendance?id_legislatura=504` → JSON `{TOTAL_SENADORES,
TOTAL_SESIONES, DATA[]}`. Cada senador: `NOMBRE`, `APELLIDO_PATERNO`,
`APELLIDO_MATERNO`, `SLUG`, **`ID_PARLAMENTARIO`**, `JUSTIFICADO`, `ASISTIO_A`,
`TOTAL_SESIONES_TOTAL`, `SIN_JUSTIFICAR`. Es asistencia **agregada por senador por
legislatura** (p. ej. asistio 92 de 105, 8 justificadas, 5 sin justificar) —
exactamente la metrica del contrato del dashboard, y **cruzable por id**. La
muestra (legislatura 504) trae 51 senadores (la legislatura incluye un reemplazo;
el roster vigente actual es 50). Nota: `id_legislatura` del backend (504) es un
espacio de ids PROPIO, distinto al de `wspublico` (374).

### H2 — Roster de 50 (RESUELTO)
`GET /api/parlamentarios?vigentes=1&limit=300` → **205 vigentes = 155 diputados
(`CAMARA="D"`) + 50 senadores (`CAMARA="S"`)**. 26 columnas, incluyendo:
`ID_PARLAMENTARIO` (id estable), `UUID`, `NOMBRE`/`APELLIDO_*`, tres formatos de
nombre (`NOMBRE_COMPLETO`, `NOMBRE_COMPLETO_CORTO`, `NOMBRE_COMPLETO_POR_APELLIDOS`),
`PARTIDO_ID` (**codigo numerico**) + `PARTIDO` (texto), `CIRCUNSCRIPCION_ID`,
`REGION` + `REGION_ID`, `SEXO`, `COMITE`, `EMAIL`, imagenes. El **31 de v01**
(`senadores_vigentes.php`) era un artefacto del endpoint viejo; esta fuente da
los 50 reales del periodo vigente.

### H3 — opendata.congreso.cl e ids estables (RESUELTO por el backend)
- `opendata.congreso.cl` es un **directorio de documentacion** (214 recursos en su
  `jsonapi`; para el Senado enlaza de vuelta a `wspublico`, para la Camara a
  `wscamaradiputados.asmx`). NO agrega una fuente de datos del Senado mas limpia
  por si mismo. Su `node--parlamentarios` trae `field_id` (=PARLID) pero sin
  circunscripcion/partido/votos.
- **El identificador estable SI existe**, en el backend `web-back.senado.cl`:
  `ID_PARLAMENTARIO` (roster y asistencia) = `PARLID` (votos) = `field_id`
  (jsonapi) = `PARLID` de `wspublico`. **Mismo espacio de ids** en todas las
  fuentes (verificado: id `1110` = Pedro Araya aparece en roster, asistencia y
  votos).

## Votaciones con id (el punto que define el pipeline)

- `GET /api/votes` → lista de **8685 votaciones**; cada una:
  `ID_VOTACION`, `ID_SESION`, `NUMERO_SESION`, `FECHA_VOTACION`, `TEMA`, `QUORUM`,
  **`BOLETIN`** (join directo a proyecto), `SI`/`NO`/`ABS`/`PAREO`, `VOTACIONES`.
- `GET /api/votes?id_votacion=<id>` → detalle nominal. `VOTACIONES` es un objeto
  `{SI:[...], NO:[...], ABSTENCION:[...], PAREO:[...]}`; **cada votante trae
  `PARLID`** + `UUID` + nombre + slug. El **sentido del voto** = el grupo.
- Consecuencia: voto→proyecto por `BOLETIN` y voto→senador por `PARLID`, **ambos
  por id, sin matching por nombre.**

## Tabla comparativa de FUENTES por entidad

| Entidad | wspublico (v01) | opendata.congreso.cl | senado.cl backend (`web-back`) | Fuente recomendada | ¿id estable? |
|---------|-----------------|----------------------|-------------------------------|--------------------|--------------|
| **Senadores (roster)** | `senadores_vigentes.php` → **31** (artefacto), `PARTIDO` texto, sin id de circ. | enlaza a wspublico | `api/parlamentarios?vigentes=1` (`CAMARA=S`) → **50**, `ID_PARLAMENTARIO`, `PARTIDO_ID`, `CIRCUNSCRIPCION_ID`, `REGION`, `SEXO` | **backend** | **Si** (`ID_PARLAMENTARIO`) |
| **Asistencia** | ❌ hueco | ❌ | `api/sessions/attendance?id_legislatura=<id>` (agregada por senador, con id) | **backend** | **Si** (`ID_PARLAMENTARIO`) |
| **Votaciones** | anidada en `tramitacion.php`, votante por **nombre** | enlaza a wspublico | `api/votes` (lista, con `BOLETIN`) + `api/votes?id_votacion=` (nominal, con `PARLID`) | **backend** | **Si** (`PARLID`) |
| **Proyectos** | `tramitacion.php?boletin=<n>` — rico (estado, tramites, materias, autores por **nombre**) | enlaza a wspublico | sin endpoint de proyectos en el backend probado | **wspublico** (detalle) + backend (`BOLETIN` de votos) | Parcial |

## Recomendacion de fuente primaria

**Fuente primaria: el backend `web-back.senado.cl/api/`** para roster, asistencia
y votaciones — es JSON limpio, trae `ID_PARLAMENTARIO`/`PARLID` consistente, y
cubre exactamente las metricas del contrato (asistencia, votos + sentido, roster
con partido/region/circunscripcion).

**Fuente complementaria: `wspublico` (`tramitacion.php`)** para el **detalle de
proyectos** (titulo, estado de tramitacion, tramites, materias, autores), que el
backend no expone. Las **autorias** vienen por nombre en wspublico, pero ahora son
resolubles a `PARLID` sin fuzzy real: el roster del backend trae
`NOMBRE_COMPLETO_POR_APELLIDOS` (`"Araya Guerrero, Pedro"`) en el **mismo formato**
que el `PARLAMENTARIO` de wspublico → cruce nombre→id determinista via el roster.

**Riesgos residuales (menores):**
- El backend no es una API documentada/versionada: es el backend de un sitio web
  (puede cambiar de forma sin aviso). Mitigacion: 31c regenera muestras para
  detectar cambios de esquema (misma logica que 31/31b).
- `PARTIDO_ID` del backend es un codigo propio (numerico), distinto de los codigos
  de la Camara (`PPD`, `UDI`). El `MAPA_PARTIDO_TENDENCIA` necesitara un crosswalk
  `PARTIDO_ID`/`PARTIDO`(texto) → tendencia (decision metodologica del titular).
- `id_legislatura` del backend (504) ≠ legislatura de wspublico (374): son
  espacios distintos; no mezclar.
- Asistencia es **agregada** por legislatura (no por-sesion nominal en el endpoint
  probado); suficiente para la tasa de asistencia del dashboard.

## Estado del gap de identidad-por-nombre

**RESUELTO** para roster, asistencia y votaciones: todas traen `ID_PARLAMENTARIO`/
`PARLID` en el mismo espacio de ids. El fuzzy name matching que v01 consideraba
inevitable **se evita**. Unico residuo: las **autorias de proyectos** (solo en
wspublico, por nombre), pero con cruce determinista via `NOMBRE_COMPLETO_POR_APELLIDOS`
del roster (mismo formato) → tampoco requiere fuzzy real.

> Correccion formal a v01: v01 reporto (a) asistencia como hueco total y (b) roster
> de 31 y (c) identidad solo por nombre. Las tres se debian a explorar unicamente
> `wspublico`. Con el backend `web-back.senado.cl` las tres se corrigen. v01 sigue
> siendo valido para el **detalle de proyectos** (`tramitacion.php`), que el backend
> no cubre.
