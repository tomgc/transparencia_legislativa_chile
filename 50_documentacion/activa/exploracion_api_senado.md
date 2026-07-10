# Exploracion de los web services del Senado de Chile

> Diagnostico insumos-first (rama `explore/api-senado`). Las muestras crudas las
> regenera `30_procesamiento/31b_explorar_api_senado.R` en
> `50_documentacion/andamios/exploracion_api_senado/`. Este documento es el
> analisis: firma real de cada servicio + comparacion de esquemas contra el
> contrato de datos que la Camara ya alimenta. NO se construyo pipeline.

- **Fecha de exploracion:** 2026-07-10
- **Base:** `https://tramitacion.senado.cl/wspublico/`
- **Transporte:** HTTPS GET con parametros en query-string. Respuesta **XML plano
  SIN namespace** (no requiere `xml_ns_strip`). NO es JSON y NO es un SOAP con
  sobre: son endpoints `.php` que devuelven XML. Cliente usado: `httr2` (el
  cliente `httr` de `10_utils/` es para la Camara; aqui no se reutiliza).
- **Contraste con la Camara:** la Camara es `opendata.camara.cl/.../WServices/`
  (ASMX, XML **con** namespace `.../camaradiputados/v1`). Dos fuentes, dos formas.

## Resumen de cobertura (4 entidades del contrato)

| Entidad | Fuente en el Senado | Estado |
|---------|--------------------|--------|
| Senadores (roster) | `senadores_vigentes.php` | ✅ con fuente |
| Proyectos (mocion/mensaje) | `tramitacion.php?boletin=<n>` | ✅ con fuente |
| Votaciones (con sentido) | `//votaciones` anidado en `tramitacion.php` | ✅ con fuente (join inherente) |
| Asistencia (nominal) | — ningun endpoint responde — | ❌ **HUECO** |

Entidad de soporte: `sesiones.php?legislatura=<id>` (lista de sesiones, SIN
asistencia nominal).

## Endpoints explorados

### 1. Senadores vigentes (roster)

- **Endpoint:** `senadores_vigentes.php` (sin parametros)
- **Raiz XML:** `<senadores>` · **N items (`//senador`):** **31**
- **Muestra:** `andamios/exploracion_api_senado/senadores_muestra.xml`

```
senador/PARLID
senador/PARLAPELLIDOPATERNO
senador/PARLAPELLIDOMATERNO
senador/PARLNOMBRE
senador/REGION
senador/CIRCUNSCRIPCION
senador/PARTIDO
senador/FONO
senador/EMAIL
senador/CURRICULUM
```

- **# REVISAR (conteo):** el endpoint devuelve **31** senadores "vigentes", por
  debajo de la dotacion esperada del Senado (43 hasta 2022; 50 desde entonces).
  No se hallo un endpoint alternativo de roster completo (`senadores.php`,
  `senadores.php?legislatura=`, `parlamentarios.php`, `senadores_periodo.php` →
  todos 404). Hay que confirmar con el titular si 31 es la dotacion real vigente
  (transicion post-eleccion 2025) o si `senadores_vigentes.php` esta incompleto
  y requiere una segunda fuente para el roster.
- **PARTIDO viene como texto** (`"P.P.D."`, `"U.D.I."`, `"R.N."`), NO como codigo
  estable — a diferencia de la Camara (`Partido/Id` = `PPD`, `UDI`).
- **REGION y CIRCUNSCRIPCION SI se exponen** (`"Region de Antofagasta"`, `"3"`) —
  al reves que la Camara, que no expone distrito/region.

### 2. Proyectos (tramitacion de un boletin)

- **Endpoint:** `tramitacion.php?boletin=<n>` — **OJO:** `<n>` es el numero ANTES
  del guion (p. ej. `16972`, no `16972-06`). Con el sufijo de materia devuelve
  "No existe el numero de boletin solicitado".
- **Raiz XML:** `<proyectos>` · un `<proyecto>` por boletin
- **Muestra:** `andamios/exploracion_api_senado/proyectos_muestra.xml` (boletin 16972)

```
proyecto/descripcion/boletin
proyecto/descripcion/titulo
proyecto/descripcion/fecha_ingreso
proyecto/descripcion/iniciativa          (Mocion / Mensaje)
proyecto/descripcion/camara_origen       (texto: "Senado")
proyecto/descripcion/urgencia_actual
proyecto/descripcion/etapa
proyecto/descripcion/subetapa
proyecto/descripcion/leynro
proyecto/descripcion/diariooficial
proyecto/descripcion/estado              (¡EXPUESTO! p. ej. "En tramitacion")
proyecto/descripcion/refundidos
proyecto/descripcion/link_mensaje_mocion
proyecto/autores/autor/PARLAMENTARIO     (NOMBRE, sin id: "Araya Guerrero, Pedro")
proyecto/tramitacion/tramite/SESION
proyecto/tramitacion/tramite/FECHA
proyecto/tramitacion/tramite/DESCRIPCIONTRAMITE
proyecto/tramitacion/tramite/ETAPDESCRIPCION
proyecto/tramitacion/tramite/CAMARATRAMITE
proyecto/votaciones                      (anidado; ver entidad 3)
proyecto/urgencias · informes · comparados · oficios · indicaciones · observaciones · materias
```

- **`estado` de tramitacion SI se expone** — es un hueco `# REVISAR` de la Camara
  (que solo tiene `Admisible` como proxy). Ventaja del Senado.
- **Autores por NOMBRE, sin id** — la Camara da `Autores/.../Diputado/Id`.
- **No hay listado global de boletines del Senado.** `tramitacion.php` es por
  boletin; `proyectos.php` → 404. Para enumerar boletines de origen Senado se
  usa, de paso, la lista de la Camara (`retornarMocionesXAnno`, `CamaraOrigen=2`).

### 3. Votaciones (anidadas en el boletin — join inherente)

- **Endpoint:** el mismo `tramitacion.php?boletin=<n>`; las votaciones viven en
  `//proyecto/votaciones`. **No hay endpoint global de votaciones**
  (`votaciones.php` responde `<votaciones></votaciones>` vacio con cualquier
  parametro probado; `votacion.php`, `votacion_detalle.php` → 404).
- **Muestra:** `andamios/exploracion_api_senado/votaciones_muestra.xml` (boletin
  15776: 1 votacion, 29 votos nominales, 21 Si / 2 No / 6 Abstencion / 0 Pareo).

```
votacion/SESION
votacion/FECHA
votacion/TEMA
votacion/SI · NO · ABSTENCION · PAREO         (agregados)
votacion/QUORUM
votacion/TIPOVOTACION
votacion/ETAPA
votacion/DETALLE_VOTACION/VOTO/PARLAMENTARIO  (NOMBRE abreviado: "Coloma C., Juan Antonio")
votacion/DETALLE_VOTACION/VOTO/SELECCION      (Si / No / Abstencion / Pareo)
```

- **Join voto→proyecto: INHERENTE y mas fuerte que en la Camara.** Cada votacion
  ya cuelga de su boletin; no hace falta el cruce por `VotacionProyectoLey/Id` que
  la Camara exige. El boletin del voto ES el boletin del proyecto contenedor.
- **Sentido del voto: EXPLICITO** en `SELECCION` (dominio observado: `Si`, `No`,
  `Abstencion`; la etiqueta `Pareo` existe como campo agregado y como valor
  posible de `SELECCION`). El **pareo** es una figura propia del Senado (acuerdo
  entre dos senadores de no votar) que la Camara no reporta asi.
- **Votante por NOMBRE, sin PARLID** — la Camara da `Voto/Diputado/Id`. El nombre
  del voto (`"Coloma C., Juan Antonio"`) ni siquiera coincide en formato con el
  del roster (`PARLNOMBRE` + `PARLAPELLIDOPATERNO` + `PARLAPELLIDOMATERNO`) ni con
  el de autores (`"Araya Guerrero, Pedro"`). Tres formatos de nombre distintos.

### 4. Asistencia nominal — HUECO

Ningun endpoint de asistencia responde: `asistencia.php`, `asistencias.php`,
`asistencia_sala.php`, `asistenciaSala.php`, `asistencia_senador.php` → todos
**404**. `sesiones.php` (ver abajo) lista sesiones pero **no anida asistencia
nominal** por senador. No se localizo fuente de asistencia nominal del Senado en
`wspublico`. Se reporta como hueco, no se fabrica endpoint (regla B.1).

### (soporte) Sesiones

- **Endpoint:** `sesiones.php?legislatura=<id>` (id entero de legislatura; sin
  endpoint de listado de legislaturas → se sondea el rango descendente y se toma
  el mayor con sesiones: al 2026-07-10 la vigente es **374**, 45 sesiones).
- **Raiz XML:** `<sesiones>` · **Muestra:** `sesiones_muestra.xml`

```
sesion/SESIID · NUMERO · TIPO · LEGISLATURA · FECHAINICIO · FECHATERMINO
sesion/IDDIARIO · TABLA · CUENTA · RESUMEN
```

Util para fechar votaciones (via `SESION` "NUMERO/LEGISLATURA"), NO para
asistencia.

## Comparacion de esquemas contra el contrato actual

Contrato por parlamentario (lo que el dashboard consume hoy): `id`, `nombre`,
`partido`, `tendencia`, `region`, `distrito`(→`circunscripcion` en el Senado), y
metricas: `asistencia`, `proyectos presentados`, `proyectos votados` + `sentido
del voto`.

| Campo del contrato | Equivalente en la Camara | Equivalente en el Senado | Brecha / nota |
|--------------------|--------------------------|--------------------------|---------------|
| `id` | `Diputado/Id` (num-como-string) | `PARLID` (num-como-string) | Ambos character. **Espacios de id distintos**: un diputado y un senador pueden compartir numero → hace falta *namespacing* (`camara:` / `senado:`) antes de unificar. |
| `nombre` | `Nombre` + `ApellidoPaterno` + `ApellidoMaterno` | `PARLNOMBRE` + `PARLAPELLIDOPATERNO` + `PARLAPELLIDOMATERNO` | Equivalente en el roster. Pero en votos/autores el nombre viene **abreviado y en otro formato** (ver `id del votante`). |
| `partido` | `Partido/Id` (codigo `PPD`,`UDI`) + `Nombre` | `PARTIDO` (**texto** `"P.P.D."`, sin codigo) | El Senado no da codigo estable → normalizar texto→codigo para poder mapear. |
| `tendencia` | derivada de `MAPA_PARTIDO_TENDENCIA[Partido/Id]` | derivable, pero **requiere primero** texto→codigo | `MAPA_PARTIDO_TENDENCIA` usa codigos de la Camara; falta una tabla de equivalencia `PARTIDO`-texto-Senado → codigo/tendencia. Decision metodologica del titular. |
| `region` | **NO expuesto** (`NA`, hueco Camara) | `REGION` (texto) | **El Senado SI lo puebla.** Invierte el gap de la Camara. |
| `distrito` / `circunscripcion` | **NO expuesto** (`NA`, hueco Camara) | `CIRCUNSCRIPCION` (numero) | El Senado SI expone circunscripcion (regional). `distrito` no aplica al Senado; registrar como `circunscripcion`. |
| `asistencia` (metrica) | `retornarSesionAsistencia` (nominal, `TipoAsistencia` 0/1) | **HUECO — sin endpoint** | **No poblable.** Ver caso de detencion #3 abajo. |
| `proyectos presentados` | `retornarMocionesXAnno` + `Autores/.../Diputado/Id` | `tramitacion.php` `autores/autor/PARLAMENTARIO` (nombre) | Autor **sin id**; join autor→senador por nombre (fragil). Sin lista global de boletines: enumerar via Camara `CamaraOrigen=2`. |
| `proyectos votados` + `sentido del voto` | `retornarVotacionDetalle` (`Voto/Diputado/Id` + `OpcionVoto` 0/1/2/3/4) | `//votaciones/.../VOTO` (`PARLAMENTARIO` nombre + `SELECCION`) | **Join voto→proyecto inherente (mejor).** Sentido explicito. Pero votante **sin id** → join voto→senador por nombre. |
| — (extra del Senado) | `Admisible` (proxy) | `descripcion/estado` | El Senado **SI expone estado de tramitacion**; la Camara no. |

### Respuestas explicitas a los 4 puntos del criterio

**(a) Protocolo del Senado.** XML plano sobre HTTPS GET, parametros en
query-string, **sin namespace**. Endpoints `.php` en `tramitacion.senado.cl/
wspublico/`. No es JSON ni SOAP-con-sobre. Distinto de la Camara (ASMX con
namespace). El cliente `descargar_xml_camara` de `10_utils/` **no** sirve tal
cual (asume namespace y base de la Camara); se uso `httr2` con reintento/backoff.

**(b) Tipo de las llaves.**
- `PARLID` (id de senador): numerico-como-string → tratar como **character**
  (invariante de llave). Distinto espacio de ids que el `Diputado/Id` de la Camara.
- **Autores y votantes NO traen id**: solo `PARLAMENTARIO` como **nombre** (y en
  tres formatos distintos entre roster / autores / votos). Resolver nombre→`PARLID`
  exige *matching* difuso — principal riesgo de integridad.
- `boletin`: string `"16972-06"`, pero el endpoint indexa por el numero antes del
  guion. `CIRCUNSCRIPCION`: numero-como-string. `PARTIDO`: texto sin codigo.

**(c) ¿Existe join voto→proyecto?** **Si, inherente** — las votaciones cuelgan del
boletin en `tramitacion.php`. Es mas directo que en la Camara. El join que **falta**
es voto→senador (el voto trae nombre, no id).

**(d) Campos del contrato que el Senado NO permite poblar.**
1. **`asistencia`**: hueco total (sin endpoint). Bloquea la metrica de asistencia
   para la camara alta.
2. **`id` estable del votante/autor**: no viene en votos ni en autores (solo
   nombre) → los cruces autor/voto ↔ senador dependen de resolver nombre→`PARLID`.
3. **`partido` como codigo** y por tanto **`tendencia`**: el Senado da partido en
   texto; falta la tabla de equivalencia (decision del titular).
4. **Roster completo**: `senadores_vigentes.php` da 31, posible incompletitud.

En cambio, el Senado **SI** puebla dos campos que son hueco en la Camara:
`region` y `circunscripcion`, y ademas expone `estado` de tramitacion.

## Riesgos que condicionan el futuro pipeline del Senado

1. **Asistencia nominal ausente** (caso de detencion #3): el contrato del
   dashboard incluye asistencia; para el Senado no hay fuente en `wspublico`. O se
   omite la metrica para senadores, o se busca una segunda fuente. **Decision del
   titular.**
2. **Identidad por nombre en votos/autores**: sin `PARLID` en votaciones ni
   autorias, la union con el roster es por *fuzzy name matching* (tres formatos de
   nombre, homonimos, tildes). Es el mayor riesgo de correctitud.
3. **Sin catalogo global de votaciones ni de boletines**: hay que iterar boletin
   por boletin (`tramitacion.php`), sembrando la lista desde la Camara
   (`CamaraOrigen=2`) o desde los tramites de sesiones. Costo y cobertura a
   dimensionar.
4. **Normalizacion de partido** texto→codigo→tendencia pendiente (metodologica).
5. **Roster de 31** a confirmar antes de asumir cobertura.
