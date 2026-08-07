# Catálogo de fuentes — API de la Cámara de Diputadas y Diputados

> **Qué es esto.** Inventario de todo lo que expone el servicio de datos abiertos de la
> Cámara, con qué llaves, qué granularidad y qué cobertura probada. Producto del encargo
> `50_documentacion/andamios/50_encargo_auditoria_fuentes_camara_senado.md` (auditoría de
> fuentes, sesión 16, 2026-08-07). **Medición de solo lectura: no modifica el pipeline.**
>
> **Reproducible:** `Rscript 50_documentacion/andamios/20260807_sondeo_fuentes.R camara`.
> Las respuestas crudas se cachean en `20_insumos/exploracion/20260807/`, que **no se
> versiona** (ver §6). La reproducibilidad la da el script, no los bytes.
>
> **Fecha de medición:** 2026-08-07. Toda cifra de este documento sale de un recuento
> programático de esa fecha, con su denominador en la misma línea.

---

## 1. Denominador declarado

| Qué | Cuánto | De dónde sale |
|---|---|---|
| Servicios `.asmx` con descriptor legible | **5** | descriptores WSDL y listados `.asmx` bajados el 2026-08-07 |
| **Operaciones que expone el conjunto de servicios** | **38** | recuento sobre los 5 descriptores; re-derivado desde los listados `.asmx` por `20260807_sondeo_fuentes.R` |
| Operaciones **EN USO** por el pipeline | **8** | extracción programática de las llamadas a `descargar_xml_camara()` en `30_procesamiento/*.R` |
| Operaciones **NO USADAS** | **30** de 38 | complemento del anterior sobre el descriptor |
| Operaciones **probadas** en esta auditoría con parámetros reales | **24** de las 30 no usadas | un archivo de caché por llamada en `20_insumos/exploracion/20260807/` |
| Operaciones **no probadas** | **6**, con motivo declarado en §5 | ídem |

**Reparto por servicio** (fuente: recuento sobre los 5 descriptores, corrida del
2026-08-07 de `20260807_sondeo_fuentes.R camara`):

| Servicio | Base | Operaciones |
|---|---|---|
| `WSSala.asmx` | `opendata.camara.cl/camaradiputados/WServices/` | 3 |
| `WSDiputado.asmx` | ídem | 4 |
| `WSLegislativo.asmx` | ídem | 14 |
| `WSComision.asmx` | ídem | 4 |
| `wscamaradiputados.asmx` (**legado**) | `opendata.camara.cl/` | 13 |
| | **total** | **38** |

### 1.1 Tres correcciones al conocimiento previo del proyecto

1. **No son ~49 operaciones, son 38.** El encargo heredaba la cifra de 49 de
   `backlog_acumulativo.md:277` y `traspaso_cierre_v07.md:236`, que la atribuyen a un
   artefacto `auditoria_cobertura_camara.md` que **no existe en el repositorio** (`find`
   con 0 resultados, corrido el 2026-08-07). No se puede saber si la diferencia es un
   cambio de la API, otro criterio de conteo o un error de origen. **Se declara 38, medido
   hoy, y se descarta 49 por no tener artefacto que lo sustente.**
2. **`WSComunes.asmx` no existe.** Devuelve una página "Sitio Web Temporalmente en
   Mantención" de 1286 bytes, **byte a byte idéntica** (md5 `a9066cc9274e...`) a la que
   devuelve un nombre de servicio **fabricado como control**. No es un servicio caído: es
   el catch-all del servidor. El proyecto lo tenía registrado como servicio real.
3. **Existen dos servicios que el proyecto no tenía registrados:** `WSComision` (4
   operaciones, con **asistencia nominal por sesión de comisión**) y el servicio legado
   `wscamaradiputados.asmx` (13 operaciones), que es además **el único que la documentación
   oficial de `opendata.camara.cl` documenta** (12 páginas de documentación descargadas; 0
   de 12 mencionan los servicios `WS*` de `/WServices/`).

### 1.2 El descriptor formal es intermitente

`?WSDL` en mayúsculas devolvió **HTTP 500 en 3 de 3** servicios probados. `?wsdl` en
minúsculas devolvió **200 en 5 de 5 por la mañana** (09:50) y **500 en 5 de 5 por la
tarde** (16:47) del mismo día. Por eso el script reproductor deriva el universo del WSDL
cuando responde y **degrada al listado `.asmx`** cuando no, declarando en la salida de qué
superficie salió cada fila. Las dos vías coinciden en 38 operaciones y en el mismo reparto
por servicio, lo que es una confirmación cruzada, no una redundancia.

**El script no persiste respuestas con status distinto de 200.** Cachear una página de
error como si fuera el descriptor convierte un fallo transitorio en un dato falso que
sobrevive a todas las corridas siguientes; ese error se cometió y se corrigió durante esta
auditoría.

---

## 2. Las 8 operaciones EN USO

Contraste programático contra los scripts (fuente: extracción de las llamadas a
`descargar_xml_camara()` en `30_procesamiento/*.R`, corrida del 2026-08-07). **8
operaciones distintas en 9 líneas de 5 scripts**; las 8 están en el descriptor.

| Operación | Servicio | Script y línea |
|---|---|---|
| `retornarDiputadosPeriodoActual` | WSDiputado | [32_extraer_diputados.R:66](30_procesamiento/32_extraer_diputados.R:66) |
| `retornarPeriodoLegislativoActual` | WSLegislativo | [33_extraer_asistencia.R:48](30_procesamiento/33_extraer_asistencia.R:48) |
| `retornarSesionesXAnno` | WSSala | [33_extraer_asistencia.R:78](30_procesamiento/33_extraer_asistencia.R:78) |
| `retornarSesionAsistencia` | WSSala | [33_extraer_asistencia.R:105](30_procesamiento/33_extraer_asistencia.R:105) |
| `retornarVotacionesXAnno` | WSLegislativo | [34_extraer_votaciones.R:35](30_procesamiento/34_extraer_votaciones.R:35) |
| `retornarVotacionDetalle` | WSLegislativo | [34_extraer_votaciones.R:51](30_procesamiento/34_extraer_votaciones.R:51) |
| `retornarMocionesXAnno` | WSLegislativo | [35_extraer_proyectos.R:28](30_procesamiento/35_extraer_proyectos.R:28) |
| `retornarProyectoLey` | WSLegislativo | [35_extraer_proyectos.R:56](30_procesamiento/35_extraer_proyectos.R:56) y [36_extraer_detalle_proyectos.R:75](30_procesamiento/36_extraer_detalle_proyectos.R:75) |

---

## 3. Catálogo de operaciones

Convenciones: **Estado** es `EN USO` (con su script) o `NO USADA`. **Cobertura probada**
declara los parámetros reales usados; "sin datos para los parámetros probados" **no**
significa "no expone". **Eje** es a qué eje del portal sirve. Todos los identificadores
usados en las pruebas son reales, leídos de `40_salidas/intermedios/` o devueltos por la
propia API.

### 3.1 `WSSala.asmx` (3 operaciones)

| Operación | Estado | Parámetros | Llave / granularidad | Cobertura probada | Eje | Utilidad potencial |
|---|---|---|---|---|---|---|
| `retornarSesionAsistencia` | **EN USO** (`33`) | `prmSesionId` (int, oblig.) | `(sesion_id, diputado_id)`; una fila por diputado y sesión | 7 `prmSesionId` reales: 6 celebradas (4800, 4753, 4788, 4736, 4792, 4628) → **155 nodos `Asistencia` cada una**, 930 en total, 77 con `Justificacion`; 1 **Citada** (4810) → HTTP 200, 459 bytes, **0 nodos** | persona | Ya sostiene el titular de asistencia (D18). Límite nuevo medido: una sesión `Citada` devuelve 200 con cero filas, no error |
| `retornarSesionesXAnno` | **EN USO** (`33`) | `prmAnno` (int, oblig.) | `sesion_id`; una fila por sesión del año civil | `prmAnno=2026` → **77 sesiones** (73 Celebrada, 4 Citada), 2026-01-05 a 2026-08-12. **0 de 77** traen `ListadoAsistencia` o `Votaciones` pese a declararlos el schema | ninguno (calendario) | Define el universo temporal del `33`. Su límite: no ata una sesión a su legislatura |
| `retornarSesionesXLegislatura` | NO USADA | `prmLegislaturaId` (int, oblig.) | `sesion_id`; una fila por sesión de la legislatura | `58` (vigente) → **59 sesiones**, 2026-03-11 a 2026-08-12; `57` → **124 sesiones**. Unión restringida a 2026 = 77, **idéntica** al universo de `retornarSesionesXAnno(2026)` | ninguno (calendario) | **Alta y medida:** filtrando legislatura 58 por `Celebrada` y fecha ≤ corte se obtienen **51 sesiones, conjunto idéntico** al denominador `periodo_vigente` del pipeline. Permitiría dejar de derivar ese ámbito por fecha de instalación |

### 3.2 `WSDiputado.asmx` (4 operaciones)

| Operación | Estado | Parámetros | Llave / granularidad | Cobertura probada | Eje | Utilidad potencial |
|---|---|---|---|---|---|---|
| `retornarDiputadosPeriodoActual` | **EN USO** (`32`) | ninguno | `diputado_id`; una fila por diputado del período vigente | no re-probada (en uso productivo) | persona | Fuente del padrón de 155 y de la militancia |
| `retornarDiputados` | NO USADA | ninguno | `diputado_id`; padrón **histórico completo** | sin parámetros → **633 diputados**, 633 ids únicos. Los 155 del padrón vigente están los 155. `FechaNacimiento` en 507 de 633; **`RUT` no vacío en 0 de 633**; 1428 nodos `Militancia` | persona | Serie histórica y trayectoria de militancia con fecha, en **una sola llamada** |
| `retornarDiputado` | NO USADA | `prmDiputadoId` (int, oblig.) | `diputado_id`; una fila | 3 ids reales muestreados de `diputados.rds` (semilla 20260807): 1202, 1217, 1239 → 10 hijos y 1 `Militancia` cada uno; **`RUT` vacío en 3 de 3** | persona | Ninguna aparente frente a `retornarDiputados`: 155 llamadas donde una basta |
| `retornarDiputadosXPeriodo` | NO USADA | `prmPeriodoID` (int, oblig.) | `(periodo_id, diputado_id)` | período 11 → **155**; 10 → **157**; 9 → **163**. Del padrón vigente: 155, 71 y 30 respectivamente | persona | Reconstruir el padrón de cualquier período cerrado, **incluidos los reemplazos** (157 y 163 personas para 155 escaños) |

### 3.3 `WSLegislativo.asmx` (14 operaciones)

| Operación | Estado | Parámetros | Llave / granularidad | Cobertura probada | Eje | Utilidad potencial |
|---|---|---|---|---|---|---|
| `retornarProyectoLey` | **EN USO** (`35`, `36`) | `prmNumeroBoletin` (string) | `boletin`; un proyecto | **152 invocaciones** con boletines reales (17 de `proyectos_detalle.rds` + 135 de listados anuales) + 115 de los votados. Trae `Autores`, `Materias`, `Votaciones`, `Admisible`. **0 de 152 traen nodo `Estado`, `Tramitacion`, `Ley` o `FechaPublicacion`** | **ambos** | **La más infraexplotada del catálogo.** El pipeline ya la descarga para los 381 boletines y **descarta su nodo `Votaciones`** en [10_utils.R:279-292](10_utils/10_utils.R:279). Ese nodo trae `TipoVotacionProyectoLey`, `Articulo`, `TramiteConstitucional` y `TramiteReglamentario`: **costo marginal cero** |
| `retornarVotacionesXProyectoLey` | NO USADA | `prmNumeroBoletin` (string) | `boletin` → votaciones | **381 boletines reales, 381 de 381 HTTP 200**, 0 fallos. 266 devuelven 0 votaciones; 115 devuelven **723 votaciones**, todas `Tipo` Valor=1. Respuesta **idéntica byte a byte** a `retornarProyectoLey` en **17 de 17** pares (md5 común) y diferencia simétrica **0** sobre 723 ids | ambos | **Ninguna adicional sobre `retornarProyectoLey`.** Consumir una sola de las dos |
| `retornarMaterias` | NO USADA | ninguno | `materia_id`; una fila por materia | sin parámetros → **8518 nodos `Materia`**, 8518 Id únicos, todos enteros, rango 881-25716, catálogo **plano** (0 atributos, solo hijos `Id`/`Nombre`), 14 nombres vacíos. **Estabilidad: 0 altas y 0 bajas entre el 2026-07-10 y el 2026-08-07** (intersección 8518) | **temático** | **Es el catálogo del eje temático.** Una sola llamada. Su límite no es él sino el otro extremo: ver `50_veredicto_eje_tematico.md` |
| `retornarMocionesXAnno` | **EN USO** (`35`) | `prmAnno` (int) | `boletin`; mociones del año | 7 años reales: 2016 (517), 2018 (706), 2020 (727), 2021 (603), 2022 (757), 2024 (710), 2026 (461). **0 de 517 en 2016 traen nodo `Materias`** pese a que el detalle de esos mismos boletines sí las trae | temático | Universo anual de proyectos. Responde desde al menos 2016: habilita ampliar el corpus hacia atrás |
| `retornarMensajesXAnno` | NO USADA | `prmAnno` (int) | `boletin`; mensajes del Ejecutivo | 2026 → **52 proyectos**; 2016 → 59 | temático | **Alta: es el hueco simétrico de `retornarMocionesXAnno`.** El pipeline solo extrae mociones, sesgo no declarado hoy en el portal |
| `retornarVotacionesXAnno` | **EN USO** (`34`) | `prmAnno` (int) | `votacion_id` | `prmAnno=2026` → **821 votaciones**. **12 nombres de elemento en todo el documento, ninguno de vínculo a proyecto.** `Tipo/@Valor`: 1=555, 2=110, 3=23, 4=133 | persona | Punto de entrada del `34`. Aporta `Tipo/@Valor`, el código entero que el pipeline conserva como glosa |
| `retornarVotacionDetalle` | **EN USO** (`34`) | `prmVotacionId` (int) | `(votacion_id, diputado_id)` | 13 ids reales (12 sin boletín + 1 con). **Unión de 18 nombres de elemento sobre 12 respuestas; ninguno de vínculo a proyecto.** Idéntico set en las que sí tienen boletín | persona | Única fuente del voto nominal. **Para el eje temático no aporta nada** |
| `retornarProyectosLeyxNumeroLey` | NO USADA | `prmNumeroLey` (string) | número de ley → proyecto | `20019` (real, extraído del nombre de un proyecto) → 1 proyecto (boletín 3019-03), 0 materias. `20.019` con puntos → 0 | temático | Única operación que conecta el espacio de números de ley con el de boletines. Cerraría "qué proyectos llegaron a ser ley" |
| `retornarTramitesConstitucionales` | NO USADA | ninguno | catálogo | sin parámetros → **6 ítems** (Primer/Segundo/Tercer Trámite, Comisión Mixta…), sin hijos, sin parámetro de boletín | temático | **Vocabulario**, no etapa. Decodifica el campo `TramiteConstitucional` que viaja dentro de `VotacionProyectoLey` |
| `retornarTramitesReglamentarios` | NO USADA | ninguno | catálogo | sin parámetros → **8 ítems** | temático | Ídem, para `TramiteReglamentario` |
| `retornarLegislaturas` | NO USADA | ninguno | `legislatura_id` | sin parámetros → **56 legislaturas**, 56 ids únicos, 1990-03-11 a 2030-03-10 | ninguno | Provee el `prmLegislaturaId` real para `retornarSesionesXLegislatura` |
| `retornarLegislaturaActual` | NO USADA | ninguno | una fila | sin parámetros → Id **58**, Número 374, 2026-03-11 a 2030-03-10 | ninguno | Da el id de legislatura vigente **sin hardcodear** |
| `retornarPeriodosLegislativos` | NO USADA | ninguno | `periodo_id` | sin parámetros → **11 períodos**. El período 11 (2026-2030) contiene **1 legislatura**; los períodos 9 y 10, cuatro cada uno | ninguno | Hace auditable la relación período ↔ legislatura |
| `retornarPeriodoLegislativoActual` | **EN USO** (`33`) | ninguno | una fila | no re-probada (en uso productivo) | ambos | De aquí sale la fecha de instalación del período (2026-03-11) que usa el `33` |

### 3.4 `WSComision.asmx` (4 operaciones) — servicio no registrado por el proyecto

| Operación | Estado | Parámetros | Llave / granularidad | Cobertura probada | Eje | Utilidad potencial |
|---|---|---|---|---|---|---|
| `retornarComisionesVigentes` | NO USADA | ninguno | `comision_id` | sin parámetros → **2 comisiones** (ids 544 Ética y Transparencia, 411 Salud) | persona | Puerta de entrada del servicio: da los `prmComisionId` reales |
| `retornarComisionesXPeriodo` | NO USADA | `prmPeriodoId` (int) | `(periodo_id, comision_id)` | período 11 → **2**, ambas Permanente (md5 idéntico a `retornarComisionesVigentes`); período 10 → **133** (79 Especial Investigadora, 32 Permanente, 15 Acusación Constitucional, 7 Unida) | persona | Única vía al catálogo histórico de comisiones. 28 de 58 presidentes del período 10 empalman con el padrón vigente |
| `retornarComision` | NO USADA | `prmComisionId` (int) | `comision_id` | ids reales 544 y 411 → integrantes vigentes (8 y 13), históricos (70 y 85) y presidencias con fecha (8 y 23) | persona | La más rica del lote: habilitaría un bloque "comisiones" en el perfil |
| `retornarSesionesXComisionYAnno` | NO USADA | `prmComisionId`, `prmAnno` | `(comision_id, sesion_id, diputado_id)` | 6 combinaciones reales → **83 sesiones y 821 filas diputado × sesión**, con los mismos campos `Justificacion`/`RebajaAsistencia`/`RebajaQuorum` de la Sala. **0 de 83 son posteriores a la instalación del período vigente** (máxima observada: 2026-03-04) | persona | **Asistencia nominal de comisión**, que el contrato vigente (solo Sala) no cubre. La capacidad existe; el dato del período vigente **todavía no** |

### 3.5 `wscamaradiputados.asmx` — servicio LEGADO (13 operaciones)

Modelo de datos distinto (`classVotacion`, `classDiputado`, `DIPID`). Está **congelado en
varias ramas**: conoce 7 períodos contra 11 del moderno, `getPeriodoLegislativoActual`
devuelve nodo nulo, y `Militancias_Periodos` viene vacío en 155 de 155. Pero expone campos
que el moderno **no** tiene.

| Operación | Estado | Cobertura probada | Eje | Utilidad potencial |
|---|---|---|---|---|
| `getVotacion_Detalle` | NO USADA | 20 votaciones reales: **12 sin boletín (muestra aleatoria, semilla 20260807) → `<Votacion/>` vacío en 12 de 12**; 8 con boletín → 16 hijos, boletín coincidente en 8 de 8 | ambos | **La de mayor valor entre las no usadas.** Entrega 6 campos que el moderno no da: `Sesion`, **`Boletin` estructurado**, `Articulo`, `Tramite`, `Informe`, `Pareos`. Da votación → sesión y votación → trámite **sin parsear texto libre** |
| `getVotaciones_Boletin` | NO USADA | 2 boletines reales → 1 votación cada uno, coincidente con `votos.rds` | temático | Vía boletín → votaciones con trámite incluido |
| `getDiputados_Vigentes` | NO USADA | sin parámetros → 155 `DIPID`, **conjunto ordenado idéntico** al de `diputados.rds` | persona | **Compuerta de verificación** del padrón desde un servicio independiente |
| `getDiputados` | NO USADA | 632 diputados (el moderno da 633; el id que sobra es `9999`) | persona | Ninguna: el moderno da lo mismo y además la militancia |
| `getDiputados_Periodo` | NO USADA | período 11 → 155; período 8 → 121 | persona | Ninguna frente al moderno |
| `getSesiones` | NO USADA | legislatura 58 → **59 sesiones, ids idénticos** a `WSSala/retornarSesionesXLegislatura(58)`; 57 → 124 | persona | Cotejo independiente |
| `getSesionDetalle` | NO USADA | 2 sesiones reales → 7 hijos y **`<Asistencia/>` vacío** en 2 de 2 | persona | Ninguna aparente: el campo existe en el esquema y viene vacío |
| `getSesionBoletinXML` | NO USADA | 2 sesiones reales → HTTP 200 con cuerpo de **38 bytes sin elemento raíz** en 2 de 2 | ninguno | Ninguna al 2026-08-07. Por el nombre podría ser el acta; **no se deduce la semántica** |
| `getLegislaturas` | NO USADA | 56 legislaturas, **mismos ids** que el moderno | ninguno | Cotejo |
| `getLegislaturaActual` | NO USADA | Id 58, Número 374 | ninguno | Ninguna: el moderno da lo mismo |
| `getPeriodosLegislativos` | NO USADA | **7 períodos** (ids 1-6 y 8); el último que conoce es 2014-2018 | ninguno | Ninguna: no conoce el período vigente ni los dos anteriores |
| `getPeriodoLegislativoActual` | NO USADA | **0 hijos, `xsi:nil="true"`** | ninguno | Ninguna. La rama más claramente rota del legado |
| `getComisiones_Vigentes` | NO USADA | 2 comisiones, ids 411 y 544 (los mismos del moderno) | persona | Cotejo: dos servicios coinciden en que hoy solo hay 2 comisiones vigentes |

---

## 4. Veredicto sobre P2 (`RebajaAsistencia` / `RebajaQuorum`)

### **NO.** Ninguna operación de la API documenta ni permite derivar la semántica reglamentaria de esos dos campos.

**Evidencia positiva de la ausencia** (fuente: recuento sobre los 5 descriptores WSDL
bajados el 2026-08-07):

| Qué se buscó | Encontrado | Denominador |
|---|---|---|
| Nodos `<documentation>` | **0** | los 5 WSDL, y sus 38 operaciones |
| `<simpleType>` (enumeraciones tipadas) | **0** | los 5 WSDL |
| `<enumeration>` | **0** | los 5 WSDL |
| `<complexType>` | 147 | los 5 WSDL |

La fuente **no declara ni un solo dominio de códigos ni una sola glosa semántica**, para
ningún campo. `RebajaAsistencia` y `RebajaQuorum` están declarados como `s:boolean`
obligatorios dentro de `JustificacionInasistencia`, sin glosa.

**Operaciones descartadas, y por qué:**

| Operación | Por qué se descarta |
|---|---|
| `retornarTramitesConstitucionales` | Catálogo de 6 tipos de trámite; **0 nodos** cuyo nombre mencione justificación, asistencia o rebaja |
| `retornarTramitesReglamentarios` | Ídem, 8 tipos |
| `retornarLegislaturas`, `retornarPeriodosLegislativos`, `retornarLegislaturaActual` | Catálogos temporales; **0 nodos** con esos nombres |
| `retornarDiputado`, `retornarDiputados` | 0 de 32 nodos mencionan asistencia o justificación |
| `WSComunes.asmx` | **No existe** (§1.1). Era el único camino identificado que podría haber alojado un catálogo de tipos |
| Todas las de `WSComision` | Traen los mismos campos sin glosa; no los definen |

**Lo único que sí se deriva de la fuente** (y que es un hallazgo, no una respuesta a P2):
el código de justificación **determina** ambas rebajas. **13 códigos distintos → 13
combinaciones `(código, RebajaAsistencia, RebajaQuorum)` distintas**, sobre 651 filas con
justificación del caché crudo del corte 2026-07-27; sin una sola contradicción. El cotejo
entre Sala y Comisión coincide en glosa y en ambas rebajas en **6 de 6 códigos
compartidos**.

**Precisión que el veredicto exige.** Esto es "no consta en la API", no "no existe". La
semántica de "rebajar" es reglamentaria: vive en el Reglamento de la Cámara, que es fuente
normativa y **quedó fuera del alcance de una auditoría de APIs**. Cerrar P2 por esa vía
sería una decisión metodológica del titular, no un dato de la fuente. **P2 sigue
bloqueado, honestamente.**

### 4.1 Hallazgo colateral: `RebajaQuorum` desaparece del intermedio publicado

`RebajaQuorum = true` en **72 de 651** filas con justificación del caché crudo, **todas**
de código 16 ("Desafuero (Art. 40)"), y 72 de 72 filas de código 16 lo tienen. Pero en el
intermedio publicado `40_salidas/intermedios/asistencia_nominal.rds` (sello corte
2026-07-27) `RebajaQuorum = true` en **0 de 486** filas con justificación, y solo aparecen
12 de los 13 códigos: **falta el 16**. La causa medida: los 4 ids con código 16 **no están
en el padrón de 155**. El caché crudo tiene 239 ids distintos, 84 de ellos fuera del
padrón, que aportan 165 de las 651 filas justificadas.

**Consecuencia práctica:** hoy `rebaja_quorum` es una columna constante en el intermedio
publicado. Si el proyecto alguna vez le diera uso, la variación existe en la fuente pero se
pierde en el filtro por padrón.

---

## 5. Lo que no se pudo probar

| Qué | Por qué |
|---|---|
| **`WSComunes`** | Devuelve el catch-all del servidor. **Sin datos para los parámetros probados**, no ausencia de capacidad |
| **El WSDL formal** | HTTP 500 intermitente (§1.2). El universo de 38 se re-derivó del listado `.asmx`, que es del mismo servidor pero **no es el descriptor formal**: no se puede descartar que el WSDL declare operaciones que el listado no muestre |
| **`retornarProyectosLeyxNumeroLey` de forma sistemática** | Probada con **un** número de ley real en dos formatos. `40_salidas/intermedios/` guarda boletines, no números de ley, y las 135 respuestas cacheadas de `retornarProyectoLey` **no contienen ningún nodo `Ley`**. Fabricar el parámetro cruzaría el invariante de identificadores inventados |
| **Cobertura de `retornarSesionesXComisionYAnno` en el período vigente** | 6 combinaciones reales probadas, **0 de 83 sesiones posteriores al 2026-03-11**. Sin datos para los parámetros probados |
| **Que el universo de servicios esté cerrado** | `GET` sobre el directorio `/WServices/` devuelve **HTTP 403** y `robots.txt` da 404. Los 5 servicios son el máximo verificable tras sondear **31 nombres candidatos** (1 acierto: `WSComision`). Un sexto servicio con nombre no anticipado **no queda descartado** |
| **Estabilidad temporal de cualquier identificador** | Solo hay dos cortes para el catálogo de materias (2026-07-10 y 2026-08-07, sin cambios). Para el resto, una sola foto |
| **Los códigos de justificación 20, 22, 24, 26 y 27** | Nunca observados en ninguna de las tres fuentes medidas. No consta si existen |

---

## 6. Sobre el caché de exploración

Las respuestas crudas quedan en `20_insumos/exploracion/20260807/` (398 archivos, 9,94 MB
al momento del escaneo de gobernanza). **Ese directorio está en `.gitignore` y no viaja al
repositorio**, por dos razones declaradas en el commit correspondiente:

1. **Gobernanza:** el sondeo del Senado dejó cacheados endpoints de padrón con **157
   valores `EMAIL` y 53 `FONO` no vacíos** solo en el roster vigente (390 y 501 en el
   histórico), sobre 8 de 398 archivos. Agregar eso a un repositorio **público** no es lo
   mismo que consultarlo en la fuente.
2. **Peso**, secundariamente.

`20_insumos/camara/` (el insumo del pipeline) **no se tocó**: sigue siendo dato crudo
inmutable y versionado.

---

## 7. Operaciones que sirven al eje temático

Ordenadas por lo que aportan a la cadena voto → proyecto → materia. El veredicto completo
vive en [50_veredicto_eje_tematico.md](50_documentacion/activa/50_veredicto_eje_tematico.md).

| # | Operación | Qué eslabón aporta | Estado del aporte |
|---|---|---|---|
| 1 | `retornarProyectoLey` | proyecto → materia, proyecto → autoría, **y proyecto → votación por su nodo `Votaciones` hoy descartado** | Único camino a materias. Su nodo `Votaciones` es la mejor relación valor/costo del catálogo: **ya se descarga** |
| 2 | `retornarMaterias` | catálogo de materias | 8518 entradas con Id entero estable. Listo para ser entidad de primera clase |
| 3 | `retornarVotacionesXProyectoLey` | votación → proyecto (dirección inversa) | **Idéntica a `retornarProyectoLey`**: no agrega nada, no consumir las dos |
| 4 | `retornarMensajesXAnno` | universo de proyectos | Cierra el sesgo: hoy el pipeline solo cubre mociones |
| 5 | `retornarTramites{Constitucionales,Reglamentarios}` | vocabulario de etapas | Decodifican campos que ya viajan dentro de `VotacionProyectoLey` |
| 6 | legado `getVotacion_Detalle` | votación → sesión y votación → trámite | Da `Boletin` **estructurado**, sin regex. No recupera el eslabón roto (§ veredicto) |
| 7 | `retornarProyectosLeyxNumeroLey` | proyecto → ley promulgada | Sin probar sistemáticamente (§5) |

---

## 8. Operaciones que valdría la pena consumir, por valor para el portal

| Prioridad | Operación | Qué agrega | Qué costaría |
|---|---|---|---|
| **1** | `retornarProyectoLey` — **dejar de descartar su nodo `Votaciones`** | Vínculo estructurado proyecto ↔ votación, más `TramiteConstitucional`, `TramiteReglamentario` y `Articulo` (texto legible del artículo votado) | **Cero llamadas nuevas.** Es una modificación de `parsear_contenido_proyecto()` en `10_utils.R`, que hoy bota ese nodo |
| **2** | `retornarMaterias` | El catálogo del eje temático, 8518 entradas | 1 llamada por refresh |
| **3** | `retornarMensajesXAnno` | Los proyectos de iniciativa del Ejecutivo, hoy ausentes del portal | 1 llamada por año + detalle por boletín nuevo |
| **4** | `retornarSesionesXLegislatura` | El denominador `periodo_vigente` **directo de la fuente** en vez de derivado por fecha de instalación | 1 llamada; ya verificado que reproduce las 51 sesiones exactas |
| **5** | legado `getDiputados_Vigentes` | Compuerta de verificación del padrón contra un servicio independiente | 1 llamada; ya verificado que da los mismos 155 ids |
| **6** | `WSComision` (las 4) | Bloque de comisiones en el perfil y asistencia nominal de comisión | Varias llamadas; **el dato del período vigente todavía no existe** |
| **7** | `retornarDiputadosXPeriodo` | Serie histórica de padrones, con reemplazos | 1 llamada por período |
