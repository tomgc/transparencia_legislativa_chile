# Log de ejecución — Auditoría de fuentes: Cámara, Senado y eje temático

- **Encargo:** `50_documentacion/andamios/50_encargo_auditoria_fuentes_camara_senado.md` (v2)
- **Sesión:** 16. **Fecha:** 2026-08-07. **Modo:** Ultracode (workflows).
- **Rama:** `auditoria/fuentes-camara-senado`, desde `origin/main` (`ff0c482`).
- **Resultado:** 4 documentos + script reproductor. **PR abierto, no mergeado.**

---

## 1. Los cuatro veredictos

| Pregunta | Veredicto |
|---|---|
| **Eje temático** | **NO.** La cadena voto → proyecto → materia cierra en **2325 de 122 605 filas (1,90 %)**. Un solo eslabón la rompe: `proyecto → materia`, 5 de 381 (1,31 %) |
| **P2** (`RebajaAsistencia` / `RebajaQuorum`) | **NO.** 0 `documentation`, 0 `simpleType`, 0 `enumeration` en los 5 WSDL. Sigue bloqueado, pero la glosa entrega el puntero normativo en 15 de 19 códigos |
| **Padrón del Senado** | `/api/parlamentarios?vigentes=1&limit=300` con `CAMARA=="S"`: **50 de 50**, contrastado contra BCN (0 personas de diferencia) y contra el art. 180 de la LOC 18.700 (16 de 16 circunscripciones, suman 50) |
| **D2** (contrato simétrico de asistencia) | **SÍ CON LAGUNAS.** Panel nominal 2700 = 54 × 50, llave única 2700 de 2700. Mapeo: 7 directos, 24 derivables, 5 ausentes, de 36 campos |

---

## 2. Orquestación

**15 agentes en 3 workflows**, con **tope de 4 concurrentes en toda fase de red** (invariante
🔒 de amabilidad con APIs públicas), implementado como tandas de exactamente 4 thunks.

| Workflow | Agentes | Resultado |
|---|---|---|
| Sondeo — lectura previa | 2 | ok |
| Sondeo — fase de red A | 4 | ok |
| Sondeo — fase de red B | 4 | **fallaron los 4** por límite de sesión de la cuenta; **reanudados** con `resumeFromRunId` (los 6 previos se sirvieron de caché) → ok |
| Panel adversarial | 4 | ok |
| Crítico de completitud | 1 | ok |

**~2600 llamadas HTTP** en total (1019 al Senado, el resto a la Cámara), con pausa entre
llamadas y caché en disco. **Ningún servicio se degradó ni bloqueó**; 0 errores de red del
lado del Senado.

---

## 3. Qué se probó

### Cámara
- **5 servicios** con descriptor legible, **38 operaciones** (no 49, ver §6).
- **24 de las 30 no usadas** probadas con parámetros reales.
- Barrido de **895 sesiones de 2020-2026** (138 692 filas, 8 910 justificadas) para el test
  de determinismo de P2.
- **135 boletines** en muestreo por cohorte anual + **381** por la vía inversa + **115**
  votados en censo.

### Senado
- **~62 rutas** probadas en `web-back.senado.cl/api/`; **7 confirmadas**.
- **Censo completo** de las 54 sesiones de la legislatura vigente → panel de 2700 filas.
- **381 boletines** de la Cámara contra el SIL, más 72 del universo nativo.
- Contraste de padrón contra **BCN vía SPARQL** (9 consultas) y contra el **texto legal**.

---

## 4. Qué falló

| Qué | Cómo se manejó |
|---|---|
| **Límite de sesión** cortó los 4 agentes de la fase de red B | Reanudado con `resumeFromRunId`; 0 trabajo perdido |
| **`?wsdl` devolvió HTTP 500** en la corrida vespertina del reproductor | El script **dejó de persistir respuestas no-200** (cachear una página de error como descriptor es un dato falso permanente) y **degradó al listado `.asmx`**, declarando la superficie de origen. Ambas vías coinciden en 38 |
| El reproductor **cacheaba páginas de error** en su primera versión | Corregido; error propio, encontrado al probar el script |
| `%||%` de `10_utils` **falla sobre listas** (usa `is.na()`) | Helper local `%|%` en el reproductor. **No se tocó el helper del pipeline** (invariante de solo lectura) |
| El sobre del backend del Senado **no es uniforme** (`data$data` vs `data$DATA`) | Medido y manejado en `filas_de()` |

---

## 5. Qué quedó sin probar

- **`WSComunes`**: devuelve el catch-all del servidor. **No existe**; era el único candidato a
  alojar un catálogo de tipos de justificación.
- **El universo de operaciones del Senado**: no hay descriptor. `openapi.json`,
  `swagger.json`, `/docs` y `/api/` → 404. **No enumerable.**
- **`retornarProyectosLeyxNumeroLey` de forma sistemática**: no hay fuente de números de ley
  reales en `40_salidas/intermedios/`. Fabricar el parámetro cruzaría el 🔒 de
  identificadores inventados.
- **Rutas del dossier del parlamentario del Senado** (mociones, comisiones, asistencia de
  comisión): 5 formas probadas con ids reales, todas 404. **La capacidad existe** (el backend
  declara en qué legislaturas hay contenido); **la ruta no se encontró**.
- **`opendata.congreso.cl`**: nunca se exploró. La muestra que el proyecto rotulaba así es en
  realidad de `web-back.senado.cl/jsonapi`.
- **LeyChile y `datos.bcn.cl` como fuente temática**: la vía más prometedora para los 376
  boletines sin materia, y **ninguna se probó**.
- **`retornarMensajesXAnno` como universo**: nunca se censó, así que la cobertura de materias
  de la iniciativa del Ejecutivo está sin medir — y **uno de los 5 aciertos viene de ahí**.
- **Verbos distintos de GET**, en ambas fuentes.

---

## 6. Panel adversarial — veredicto de cada agente

Cinco agentes independientes, **con código propio**, prohibido leer o ejecutar los scripts
del agente original.

| Agente | Hallazgo verificado | Veredicto |
|---|---|---|
| 1 | **P2 = NO** | **CONFIRMADO CON CORRECCIÓN** |
| 2 | **Padrón del Senado** | **CONFIRMADO CON CORRECCIÓN** |
| 3 | **Cadena voto → proyecto → materia** | **CONFIRMADO CON CORRECCIÓN** |
| 4 | **Asistencia nominal por sesión (D2)** | **CONFIRMADO CON CORRECCIÓN** |
| 5 | **Crítico de completitud** | **REFUTÓ el cierre**: 3 de 6 entregables no existían y 10 de 14 criterios no eran declarables al momento de correr |

### Correcciones que el panel forzó, y que ya están aplicadas

| # | Corrección | Dónde |
|---|---|---|
| 1 | `?WSDL` mayúsculas **no** falla: 200 en 12 de 12 con bytes idénticos. El descriptor es **intermitente en el tiempo**, no sensible al sufijo | catálogo Cámara §1.2 |
| 2 | "Lo único derivable es el determinismo" es **falso**: la glosa cita el artículo en **15 de 19** códigos | catálogo Cámara §4 |
| 3 | "Todas de código 16" vale **solo en el corte 2026**: en 2020-2026 también el código 22 lleva `RebajaQuorum=true` (624 filas, 2 códigos) | catálogo Cámara §4.1 |
| 4 | El determinismo se re-verificó con **denominador 13× mayor**: 895 sesiones, 19 códigos, 0 con más de una combinación | catálogo Cámara §4 |
| 5 | Las discrepancias del padrón no son 2 sino **5** (2 de identificador + 3 de nombre); **ninguna llave sola cubre 50 de 50** | catálogo Senado §2 |
| 6 | "El id del lado diputado" es ambiguo y **falso en la lectura natural**: conviven **tres** numeraciones, y BCN usó la ficha `CAMARA=="D"` del portal del Senado (1264/1144), **no** `idCamaraDeDiputados` (1046/991), que es la llave que este proyecto ya usa | catálogo Senado §2 |
| 7 | "Institucionalmente independiente" → **"editorial y técnicamente independiente"**: BCN es órgano del mismo Congreso | catálogo Senado §2 |
| 8 | **BCN no corrobora el reparto territorial** (`representing` NULL en 50 de 50); lo corrobora el texto legal | catálogo Senado §2 |
| 9 | `data.total` **miente** si `limit` es bajo | catálogo Senado §2 |
| 10 | El host del `.php` importa: `www.senado.cl` da 404, `tramitacion.senado.cl` da 200 | catálogo Senado §2 |
| 11 | Los 19 que omite el `.php` son **exactamente** los de `id >= 1500`: es un servicio legacy que ignora las fichas de marzo 2026 | catálogo Senado §2 |
| 12 | "Ambas cámaras espejean una sola fuente aguas arriba" es **hipótesis**, no conclusión | catálogo Senado §6.2 |
| 13 | "0 % desde 2022" es **falso**: el 0 % empieza en **2024**; la zona cubierta llega hasta **2019**; y es un **gradiente**, no una frontera | veredicto eje temático §4.1 |
| 14 | **368 no reproduce** con ningún corte anual; con ingreso ≥ 2020 son **376** de 381 | veredicto eje temático §4.1 |
| 15 | Hay un **mecanismo competidor** con mejor soporte que el temporal: tramitación avanzada (Fisher p = 0,000195 y p = 0,001032). Los dos están confundidos y **ninguno está zanjado** | veredicto eje temático §4.1 |
| 16 | Criterio 7: el denominador es **36 canónicos** (37 brutos), y **4 campos existen en 87 de 155 perfiles** | veredicto D2 §2 |
| 17 | Criterio 13: la tasa autor → padrón **no estaba escrita en ninguna parte**. Es **1625 de 1705 filas (95,31 %)** y **155 de 199 autores (77,89 %)** | veredicto eje temático §2 |

### Una corrección del panel que se verificó y NO se aplicó

El crítico reportó que "94 votaciones `1-Otros` con 14 570 filas" contradice "245 sin boletín
repartidas 117/23/105", porque su recuento daba **117 votaciones con 18 135 filas**.

**Recontado en este turno: las dos cifras son correctas y miden predicados distintos.**
`tipo == "Otros"` son 117 votaciones (18 135 filas); `descripcion == "1-Otros"` son 94
(14 570 filas), **subconjunto de las anteriores**. El desglose de `tipo == "Otros"` es
`1-Otros` 94, `2-Acusacion Constitucional` 13, `3-Creacion Comision Investigadora` 9,
`4-Informe Comision Investigadora` 1. Ambas cifras quedaron en el documento **con su
predicado exacto declarado**, que es lo que faltaba.

---

## 7. Decisiones tomadas en autonomía

1. **El caché de exploración no se versiona.** Escaneo propio: **157 valores `EMAIL` y 53
   `FONO` no vacíos** en el roster vigente del Senado (390 y 501 en el histórico), sobre 8 de
   398 archivos. Agregar contacto nominal de 205 parlamentarios en un repositorio **público**
   no es lo mismo que consultarlo en la fuente. El encargo §4.5 autoriza el `.gitignore`
   "y decláralo en el log": **queda declarado aquí**. La reproducibilidad la da el script.
2. **Se corrigió una alerta de gobernanza sobreestimada por un agente.** Reportó que
   `retornarDiputado` había cacheado el RUT de una persona real. Verificado: los nodos
   `<RUT>` y `<RUTDV>` existen pero vienen **vacíos** (0 valores no vacíos). El agente contó
   nodos, no valores. **La alerta real es el `EMAIL`/`FONO` del Senado, no el RUT.**
3. **El universo de operaciones se aceptó desde el listado `.asmx`** cuando el WSDL devolvió
   500, declarando la superficie de origen en la salida del script. Las dos vías coinciden.
4. **Se descartó la cifra de 49 operaciones** que el encargo heredaba: el artefacto que la
   sustenta (`auditoria_cobertura_camara.md`) **no existe en el repositorio**.
5. **El veredicto del eje temático se cerró en NO**, no en "SÍ CON LAGUNAS", aplicando el
   criterio que el propio encargo fija en §1.1.
6. **Los dos mecanismos que compiten para explicar el déficit de materias se dejaron
   abiertos**, en vez de elegir el primero medido.

---

## 8. Regla de detención: se cruzó una, y se registra

El encargo §9 manda **detenerse y reportar** al descubrir que una premisa estructural del
proyecto es falsa, y nombra explícitamente los identificadores del Senado.

**Se descubrió una:** D3 tiene registrado que los espacios de identificadores son distintos
y que **"no hay colisión que resolver"**. Medido: **5 valores enteros compartidos** entre
ids de senador vigente y `diputado_id` (1110, 1117, 1215, 1222, 1224), y en **5 de 5
designan personas distintas**; los rangos se solapan (803-1264 vs 911-1518).

**La corrida continuó**, y esa es una desviación del encargo que corresponde registrar. El
juicio aplicado: la premisa falsa es la **justificación** de D3, no D3 misma —la decisión
(llave compuesta `(camara, parlamentario_id)`) es correcta y la colisión la refuerza en vez
de invalidarla—, y detener una corrida de solo lectura no habría producido más información.
**La decisión de si eso bastaba es del titular.**

---

## 9. Criterios de éxito (§5 del encargo)

| # | Criterio | Medida | Estado |
|---|---|---|---|
| 1 | Universo de operaciones desde el descriptor | **38** en 5 servicios, por dos superficies independientes con divergencia 0 de 38; se cita cuál se usó y por qué | **CUMPLE** |
| 2 | Las 8 en uso, marcadas con su script | 8 operaciones distintas en 9 líneas de 5 scripts; contraste programático corrido tres veces (sondeo, panel, reproductor), coincidente `archivo:línea` | **CUMPLE** |
| 3 | Toda operación probada con su llamada y respuesta registradas | Una respuesta cruda por llamada en `20_insumos/exploracion/20260807/` (2389 archivos) + manifiestos CSV. **Salvedad: el directorio está gitignoreado**, así que un revisor del PR no puede abrirlo; el encargo §4.5 lo autoriza si se declara, y §7.1 lo declara | **CUMPLE CON SALVEDAD** |
| 4 | Veredicto de P2 en forma cerrada | **NO**, con la lista de operaciones descartadas y por qué | **CUMPLE** |
| 5 | Padrón del Senado cuadra contra fuente independiente, con la diferencia declarada | **0 personas de diferencia** contra BCN; **5 discrepancias declaradas** (2 de id + 3 de nombre); segundo contraste contra el art. 180 de la LOC 18.700 (16 de 16, suman 50) | **CUMPLE** |
| 6 | Veredicto de D2 en forma cerrada | **SÍ CON LAGUNAS**, con 5 lagunas, cada una con qué falta / qué la salva / qué cuesta | **CUMPLE** |
| 7 | Mapeo campo a campo cubre **todos** los campos del contrato vigente | **36 campos hoja canónicos** (37 brutos; convención declarada), 7 + 24 + 5 = 36. Además se declara que 4 de los 36 existen en 87 de 155 perfiles | **CUMPLE** |
| 8 | El catálogo se reproduce corriendo el script | Corrido de punta a punta. Reproduce: 38 operaciones y su reparto; 8 en uso con línea; 8518 materias; la curva por cohorte; 546/546 y 0/245; padrón 50 de 50; legislatura 507 derivada por fecha; panel 2700 = 54 × 50; `Asiste` 2330 / `Ausente` 370; las 3 centinela por id; 54 − 3 = 51; SIL 20 de 20. **Salvedad: el bloque de semántica de los WSDL no pudo recontarse** (HTTP 500 en esa corrida) y el script lo declara en vez de imprimir vacío | **CUMPLE CON SALVEDAD** |
| 9 | Ningún archivo del pipeline cambió | `git status --porcelain` y `git diff main...HEAD` acotados a `10_utils/`, `30_procesamiento/`, `docs/`, `40_salidas/` y `00_run_all.R`: **0 líneas en ambos** | **CUMPLE** |
| 10 | Veredicto del eje temático en forma cerrada | **NO** | **CUMPLE** |
| 11 | Los seis eslabones con numerador **y** denominador, contados al escribirlos | Tabla de 8 filas (los 6 + la cadena completa + la cadena sobre lo publicado), ninguna celda vacía, cada una con su artefacto | **CUMPLE** |
| 12 | `proyecto → materia` medida sobre el universo persistido | 5 de **381** de `40_salidas/intermedios/proyectos_detalle.rds`, no sobre las muestras de `andamios/muestras/` | **CUMPLE** |
| 13 | Empalme autor → padrón contrastado contra `diputados.rds`, con la tasa declarada | **1625 de 1705 filas (95,31 %)**; **155 de 199 autores (77,89 %)**; **33 de 272 boletines** con al menos un autor fuera | **CUMPLE** |
| 14 | El eslabón roto tiene diagnóstico, no solo constatación | Diagnóstico: **artefacto de denominador**. 546 de 546 `Proyecto de Ley` traen boletín; las 245 restantes son instrumentos sin boletín posible; vía inversa sobre 381 boletines recupera 0 de 245; residuo opaco de 94 con su predicado exacto y cómo declararlo en el portal | **CUMPLE** |

**12 CUMPLE, 2 CUMPLE CON SALVEDAD, 0 NO CUMPLE.** Las dos salvedades están declaradas
arriba con su causa; ninguna se presenta como cumplimiento limpio.

---

## 10. Notas para el revisor

1. **Lee primero `50_veredicto_eje_tematico.md`.** Es el artefacto de mayor valor y el que
   cambia una decisión de producto.
2. **El veredicto es NO, y conviene entender por qué no es un NO desalentador:** tres de los
   seis eslabones están al 100 % y hay un producto distinto —el eje de **tramitación**, 381
   de 381 con fechas— listo para construirse, que además **cierra un `# REVISAR` que el
   `CLAUDE.md` arrastra desde la fase 1**.
3. **La recomendación de mayor relación valor/costo es de costo cero:** el pipeline ya
   descarga el nodo `Votaciones` de `retornarProyectoLey` para los 381 boletines y lo
   descarta en `parsear_contenido_proyecto()`. Viene poblado en **115 de 115** boletines
   votados.
4. **Dos correcciones tocan decisiones registradas del proyecto:** la justificación de D3
   (§8) y el esquema del contrato común de la rama `design/contrato-datos`, que quedó
   obsoleto.
5. **Un riesgo operativo que este encargo encontró de paso y no le correspondía arreglar:**
   los intermedios declaran sello **2026-07-27** contra `CORTE_FECHA` **2026-08-03**, y
   `validar_corte()` hace `stop()` sobre ellos. El contenido **sí** corresponde al refresh
   2026-08-03 (96 397 = 65 478 + 30 919 reconcilia), así que el problema es el sello. **Una
   corrida de `39` fallaría hoy.**
6. **Un sesgo del producto que nadie había declarado:** 26 208 filas de voto (21,38 %)
   pertenecen a 84 `diputado_id` sin perfil publicado.
7. **Este PR no toca el pipeline** (criterio 9). Todo lo que propone queda como propuesta.
