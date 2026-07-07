# Exploracion de la API de la Camara de Diputadas y Diputados

> Generado por `30_procesamiento/31_explorar_api_camara.R` (Fase 1.B, instrumentacion). Evidencia regenerable: re-correr el script actualiza este archivo con la forma REAL de la API en el momento de la corrida.

- **Fecha de exploracion:** 2026-07-06 20:02:08
- **Base:** `https://opendata.camara.cl/camaradiputados/WServices/`
- **Transporte:** SOLO HTTPS (el esquema HTTP hace timeout).
- **Formato:** XML con namespace `http://opendata.camara.cl/camaradiputados/v1`.

## Endpoints explorados

**Periodo legislativo vigente:** Id `11` (2026-2030).

### Roster de diputados del periodo vigente

- **Operacion:** `WSDiputado.asmx/retornarDiputadosPeriodoActual`
- **Raiz XML:** `DiputadosPeriodoColeccion`
- **Namespace declarado:** `http://opendata.camara.cl/camaradiputados/v1` (removido al parsear)
- **N de items (//DiputadoPeriodo):** 155

Estructura de nodos hoja (primer item):

```
DiputadoPeriodo/FechaInicio
DiputadoPeriodo/FechaTermino
DiputadoPeriodo/Diputado/Id
DiputadoPeriodo/Diputado/Nombre
DiputadoPeriodo/Diputado/Nombre2
DiputadoPeriodo/Diputado/ApellidoPaterno
DiputadoPeriodo/Diputado/ApellidoMaterno
DiputadoPeriodo/Diputado/FechaNacimiento
DiputadoPeriodo/Diputado/RUT
DiputadoPeriodo/Diputado/RUTDV
DiputadoPeriodo/Diputado/Sexo
DiputadoPeriodo/Diputado/Militancias/Militancia/FechaInicio
DiputadoPeriodo/Diputado/Militancias/Militancia/FechaTermino
DiputadoPeriodo/Diputado/Militancias/Militancia/Partido/Id
DiputadoPeriodo/Diputado/Militancias/Militancia/Partido/Nombre
DiputadoPeriodo/Diputado/Militancias/Militancia/Partido/Alias
```

Dominio observado de **Partido/Id (todas las militancias, historico)**:

```
  IND                            58
  PREP                           39
  RN                             38
  UDI                            27
  FA                             26
  PS                             20
  PC                             17
  PDG                            15
  DC                             13
  PNL                            10
  PCS                            8
  PPD                            7
  PSC                            6
  RD                             6
  FRVS                           4
  EVOP                           3
  LIBERAL                        3
  PR                             3
  DEM                            2
  PAH                            2
  PH                             2
  PL                             2
  COMUNES                        1
  PCC                            1
  PRI                            1
  PRO                            1
```

### Sesiones de sala del anno 2026

- **Operacion:** `WSSala.asmx/retornarSesionesXAnno`
- **Parametros:** `prmAnno=2026`
- **Raiz XML:** `SesionesSalaColeccion`
- **Namespace declarado:** `http://opendata.camara.cl/camaradiputados/v1` (removido al parsear)
- **N de items (//Sesion):** 61

Estructura de nodos hoja (primer item):

```
Sesion/Id
Sesion/Numero
Sesion/FechaInicio
Sesion/FechaTermino
Sesion/Tipo
Sesion/Estado
```

### Asistencia de una sesion (Id 4736)

- **Operacion:** `WSSala.asmx/retornarSesionAsistencia`
- **Parametros:** `prmSesionId=4736`
- **Raiz XML:** `SesionSala`
- **Namespace declarado:** `http://opendata.camara.cl/camaradiputados/v1` (removido al parsear)
- **N de items (//Asistencia):** 155

Estructura de nodos hoja (primer item):

```
Asistencia/TipoAsistencia
Asistencia/Diputado/Id
Asistencia/Diputado/Nombre
Asistencia/Diputado/ApellidoPaterno
Asistencia/Diputado/ApellidoMaterno
```

Dominio observado de **TipoAsistencia (Valor | etiqueta)**:

```
  1 | Asiste                     146
  0 | No Asiste                  9
```

### Votaciones nominales del anno 2026

- **Operacion:** `WSLegislativo.asmx/retornarVotacionesXAnno`
- **Parametros:** `prmAnno=2026`
- **Raiz XML:** `VotacionesColeccion`
- **Namespace declarado:** `http://opendata.camara.cl/camaradiputados/v1` (removido al parsear)
- **N de items (//Votacion):** 672

Estructura de nodos hoja (primer item):

```
Votacion/Id
Votacion/Descripcion
Votacion/Fecha
Votacion/TotalSi
Votacion/TotalNo
Votacion/TotalAbstencion
Votacion/TotalDispensado
Votacion/Quorum
Votacion/Resultado
Votacion/Tipo
```

### Detalle de una votacion (Id 89288)

- **Operacion:** `WSLegislativo.asmx/retornarVotacionDetalle`
- **Parametros:** `prmVotacionId=89288`
- **Raiz XML:** `Votacion`
- **Namespace declarado:** `http://opendata.camara.cl/camaradiputados/v1` (removido al parsear)
- **N de items (//Voto):** 155

Estructura de nodos hoja (primer item):

```
Voto/Diputado/Id
Voto/Diputado/Nombre
Voto/Diputado/ApellidoPaterno
Voto/Diputado/ApellidoMaterno
Voto/OpcionVoto
```

Dominio observado de **OpcionVoto (Valor | etiqueta)**:

```
  0 | En Contra                  67
  1 | Afirmativo                 67
  4 | No Vota                    20
  2 | Abstención                1
```

### Mociones (proyectos de iniciativa parlamentaria) del anno 2026

- **Operacion:** `WSLegislativo.asmx/retornarMocionesXAnno`
- **Parametros:** `prmAnno=2026`
- **Raiz XML:** `ProyectosLeyColeccion`
- **Namespace declarado:** `http://opendata.camara.cl/camaradiputados/v1` (removido al parsear)
- **N de items (//ProyectoLey):** 344

Estructura de nodos hoja (primer item):

```
ProyectoLey/Id
ProyectoLey/NumeroBoletin
ProyectoLey/Nombre
ProyectoLey/FechaIngreso
ProyectoLey/TipoIniciativa
ProyectoLey/CamaraOrigen
ProyectoLey/Admisible
```

Dominio observado de **CamaraOrigen (Valor | etiqueta)**:

```
  1 | Cámara de Diputados       218
  2 | Senado                     126
```

### Detalle de un proyecto de origen Camara (boletin 18327-07)

- **Operacion:** `WSLegislativo.asmx/retornarProyectoLey`
- **Parametros:** `prmNumeroBoletin=18327-07`
- **Raiz XML:** `ProyectoLey`
- **Namespace declarado:** `http://opendata.camara.cl/camaradiputados/v1` (removido al parsear)
- **N de items (//Autores/ParlamentarioAutor):** 8

Estructura de nodos hoja (primer item):

```
ParlamentarioAutor/Orden
ParlamentarioAutor/Diputado/Id
ParlamentarioAutor/Diputado/Nombre
ParlamentarioAutor/Diputado/ApellidoPaterno
ParlamentarioAutor/Diputado/ApellidoMaterno
```

## Hallazgos que condicionan el pipeline

1. **La API responde solo por HTTPS.** El esquema `http://` hace timeout.
2. **Distrito y region NO se exponen** en ningun endpoint de diputados (`retornarDiputadosPeriodoActual`, `retornarDiputado`, `retornarDiputadosXPeriodo` tienen estructura de nodos identica y sin distrito/region). Quedan como `NA_character_` en el JSON, documentado como hueco de la fuente. # REVISAR: requeriria una segunda fuente (BCN/SERVEL), fuera del alcance de Fase 1.
3. **Estado de tramitacion de un proyecto NO se expone** en `retornarProyectoLey` (solo Id, NumeroBoletin, Nombre, FechaIngreso, TipoIniciativa, CamaraOrigen, Autores, Votaciones, Materias, Admisible). Se conserva `Admisible` como proxy parcial; el estado de tramitacion queda `NA`. # REVISAR.
4. **La militancia vigente** de un diputado es la de mayor `FechaInicio` (ninguna militancia trae `FechaTermino` vacia; todas cierran en el fin de periodo). El partido actual = esa militancia.
5. **El boletin de una votacion** viene embebido en el texto de `Descripcion` (p.ej. "Boletin N 16851-14"); se extrae por expresion regular.
6. **Tendencia (izquierda/derecha) no viene en la API**: es una columna derivada del mapeo `MAPA_PARTIDO_TENDENCIA` en `10_utils/10_configuracion.R`, decision metodologica del titular.

