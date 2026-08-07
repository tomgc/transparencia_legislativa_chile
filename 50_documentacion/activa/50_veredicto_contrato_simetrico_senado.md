# Veredicto — ¿es construible el contrato simétrico de asistencia (D2) para el Senado?

> Producto del encargo `50_documentacion/andamios/50_encargo_auditoria_fuentes_camara_senado.md`
> (sesión 16, 2026-08-07). Verificado adversarialmente por un agente independiente con código
> propio. **Propuesta, no ejecución: este documento no toca el pipeline.**
>
> Detalle de fuentes en [50_catalogo_fuentes_senado.md](50_documentacion/activa/50_catalogo_fuentes_senado.md).

---

## 1. Veredicto

# SÍ CON LAGUNAS

El Senado **sí** expone asistencia nominal por sesión, con la granularidad que D2 exige: una
fila por `(senador, sesión)` con estado, no un agregado.

`GET https://web-back.senado.cl/api/sessions/attendance?id_sesion=<id>`

**Panel completo de la legislatura vigente, medido dos veces con código independiente**
(agente de sondeo y reproductor `20260807_sondeo_fuentes.R senado`):

| Medición | Valor | Denominador |
|---|---|---|
| Filas nominales | **2700** = 54 sesiones × 50 senadores | — |
| Llave compuesta `(ID_SESION, ID_PARLAMENTARIO)` única | **2700 de 2700** | 2700 filas |
| Filas por sesión | **50**, valor único observado | 54 sesiones |
| Ids del panel contenidos en el padrón | **2700 de 2700**; 0 miembros del padrón ausentes | — |

⚠️ **La misma ruta con `?id_legislatura=` devuelve un agregado por senador sin dimensión de
sesión.** Es polimórfica: **solo la variante `?id_sesion=` satisface D2.** Confundirlas
produciría un contrato que parece simétrico y no lo es.

Las lagunas —cinco campos ausentes y una trampa de codificación— están en §3. Ninguna
impide construir el contrato; **una de ellas sí puede producir cifras falsas si no se
maneja**, y por eso el veredicto no es un SÍ limpio.

---

## 2. Mapeo campo a campo contra el contrato vigente de la Cámara

**Denominador declarado: 36 campos hoja canónicos.** Convención, que hay que explicitar
porque un tercero contaría 37: el recorrido bruto del árbol sobre los 155 perfiles
publicados da **37 rutas terminales**, pero una de ellas
(`asistencia.sesiones[].justificacion`) es **padre** de otras cuatro y aparece como terminal
solo porque viene `null` en la mayoría de las sesiones. 37 − 1 = **36 canónicos**
(fuente: recuento programático sobre la unión de los 155 perfiles de
`40_salidas/json/perfiles/`).

⚠️ **4 de esos 36 campos existen en 87 de 155 perfiles**, no en los 155: los cuatro
`justificacion.*`. Tratarlos como campos plenos del contrato **sobrestima lo que el Senado
tiene que igualar**.

**Resultado: 7 directos, 24 derivables, 5 ausentes.**

### 2.1 `alcance_temporal` (10 campos)

| Campo de la Cámara | Equivalente en el Senado | Veredicto |
|---|---|---|
| `anio_proceso` | constante de configuración, no de la fuente | derivable |
| `corte_fecha` | ídem | derivable |
| `sesiones_alcance` | `count()` sobre `/api/sessions?id_legislatura=` | derivable |
| `fecha_primera` | `min(FECHA)` del catálogo de sesiones | derivable |
| `fecha_ultima` | `max(FECHA)` del catálogo de sesiones | derivable |
| `periodo_id` | `PERIODOS[].ID` del padrón | **directo** |
| `periodo_nombre` | `DESDE`-`HASTA` de `PERIODOS[]` | derivable |
| `periodo_inicio` | `INICIO` de la legislatura vigente (`/api/legislatures`) | **directo** |
| `sesiones_periodo_vigente` | sesiones de la legislatura vigente | derivable |
| `nota` | texto compuesto por el pipeline | derivable |

**Anclas temporales verificadas:** `periodo_inicio` == `INICIO` de la legislatura 507;
`periodo_id` == `PERIODOS.ID`; `periodo_nombre` == `DESDE`-`HASTA`. **3 de 3 cuadran.**

### 2.2 `periodo_vigente` y `en_ejercicio` (8 campos cada uno, 16 en total)

| Campo de la Cámara | Equivalente en el Senado | Veredicto |
|---|---|---|
| `n_sesiones` | `count()` sobre el panel | derivable |
| `n_asiste` | `sum(ASISTENCIA == "Asiste")` | derivable |
| `n_no_asiste` | `sum(ASISTENCIA == "Ausente")` | derivable |
| **`n_sin_registro`** | **no existe**: el dominio del Senado tiene **2 valores** (`Asiste`, `Ausente`), el de la Cámara **3** (`asiste`, `no_asiste`, `sin_registro`) | **ausente** (×2 ámbitos) |
| `n_justificadas` | `sum(JUSTIFICACION != "")` | derivable |
| `n_injustificadas` | complemento | derivable |
| `tasa_presencia` | cociente | derivable |
| `tasa_presencia_o_justificada` | cociente | derivable |

El ámbito `en_ejercicio` es derivable del mismo modo, usando el catálogo de sesiones para
acotar por fecha de incorporación.

### 2.3 `sesiones[]` (10 campos: 6 + 4 de `justificacion`)

| Campo de la Cámara | Equivalente en el Senado | Veredicto |
|---|---|---|
| `sesion_id` | `ID_SESION` | **directo** |
| `sesion_numero` | `NUMERO_SESION` | **directo** |
| `fecha` | `FECHA` de `/api/sessions` (**no** viene en la respuesta de asistencia) | **directo** (vía join) |
| `tipo_sesion` | `TIPO` de `/api/sessions` | **directo** (vía join) |
| `en_periodo_vigente` | comparación contra `INICIO` de la legislatura | derivable |
| `asistencia` | `ASISTENCIA`, con **recodificación de 2 valores a 3** | derivable |
| `justificacion.glosa` | `JUSTIFICACION` (texto libre) | **directo** |
| **`justificacion.codigo`** | **no existe**: el Senado entrega glosa **sin código** | **ausente** |
| **`justificacion.rebaja_asistencia`** | **no existe** | **ausente** |
| **`justificacion.rebaja_quorum`** | **no existe** | **ausente** |

**Recuento: 7 directos + 24 derivables + 5 ausentes = 36.**

---

## 3. Lagunas

### Laguna 1 — La trampa de las sesiones centinela *(la grave)*

**Qué falta:** un discriminador entre "sesión sin registro de asistencia" y "sesión donde
nadie asistió". **3 de 54 sesiones devuelven las 50 filas en `Ausente`, con cero
asistentes**: ids 10225, 10249 y 10250. Dos son futuras; **la 10225 (Congreso pleno del
15/07/2026) ya se celebró**. Ni `HORA_TERMINO` (poblada en 54 de 54, incluidas las futuras)
ni ningún otro campo las distingue.

**Por qué es grave:** sin regla de detección, esas 3 sesiones entran como 150 inasistencias
reales y **hunden la tasa de presencia de los 50 senadores a la vez**. Es exactamente el tipo
de error que publica una cifra falsa con aspecto de correcta.

**Qué la hace salvable:** una regla de detección corroborable contra la propia fuente —
`sum(ASISTENCIA == "Asiste") == 0` marca la sesión como sin dato. Verificado:
**54 − 3 = 51 = `TOTAL_SESIONES`** que declara el agregado oficial. Y la conciliación cierra
sin residuo: `ASISTIO_A` coincide con el recuento del panel en **50 de 50** senadores,
`JUSTIFICADO` suma 21 = 21, `SIN_JUSTIFICAR` suma 199 = 220 − 21.

**Qué costaría:** una función de detección y un test que compare contra el agregado en cada
refresh. Bajo. **La compuerta ya existe en la fuente: hay que usarla.**

⚠️ La hipótesis "el Congreso pleno no registra asistencia" **queda refutada**: 2 de los 3
Congresos plenos de la legislatura sí tienen asistentes. **La anomalía de la 10225 queda
abierta.**

### Laguna 2 — Justificación sin código y sin catálogo

**Qué falta:** el Senado entrega `JUSTIFICACION` como **texto libre sin código**. **21 filas
de 2700**, con **2 glosas** (`Invitación oficial` 12, `Enfermedad` 9). La Cámara entrega
**12 códigos** con glosa y referencia a artículo, en 486 de 9183 filas.

**Qué la haría salvable:** un catálogo de códigos del Senado. **No se probó ninguna ruta
candidata** (p. ej. `/api/justificaciones`): hueco declarado. Sin él, la única vía es un
diccionario de normalización de texto mantenido a mano, que es deuda.

**Qué costaría:** medio. Y **hereda el problema de P2**: la semántica no consta.

### Laguna 3 — `JUSTIFICACION` no significa "motivo de ausencia"

**Qué falta:** la semántica. Coexiste con `ASISTENCIA == "Asiste"` en **2 filas de 2700**
(senador 1507, sesiones 10140 y 10141), y hay ausentes sin justificación.

**Es el mismo caso que `RebajaAsistencia`/`RebajaQuorum` en la Cámara (P2) y merece el mismo
trato: persistir, no calcular.** No se deduce del nombre del campo.

**Qué costaría:** nada persistirla; **alto** documentarla, porque exige fuente normativa.

### Laguna 4 — Sin `n_sin_registro`

El dominio del Senado tiene 2 valores donde el de la Cámara tiene 3. Salvable **solo
parcialmente**: las sesiones centinela de la laguna 1 son precisamente el caso de "sin
registro", pero a nivel de **sesión completa**, no de senador individual. Un senador
individual sin registro en una sesión con asistencia normal **es indistinguible de un
ausente**.

**Consecuencia para el contrato:** `n_sin_registro` del Senado debe publicarse como `null`,
no como `0`. Publicar `0` afirmaría algo que la fuente no dice.

### Laguna 5 — Asistencia de comisiones: no se encontró la ruta

**6 rutas candidatas probadas, todas 404.** El dossier del parlamentario **indexa
`ASISTENCIA_COMISIONES` con 15 legislaturas**, así que el dato probablemente existe.
**Se registra como "no encontré la ruta", no como "no expone".** No bloquea D2, que es de
Sala; sí bloquearía una eventual extensión a comisión (que del lado Cámara **sí** tiene
fuente: `WSComision/retornarSesionesXComisionYAnno`).

---

## 4. Plan de construcción propuesto

**Propuesta, no ejecución.** Convertible en encargos independientes.

### Paso 1 — Capa de normalización (D1), sin tocar el pipeline de la Cámara

Un módulo nuevo, `30_procesamiento/3X_normalizar_asistencia.R`, que reciba el formato de
cada cámara y emita el contrato común. **La Cámara pasa por él sin cambios de salida**:
verificable byte a byte contra los JSON publicados de hoy. Esa es la compuerta del paso.

### Paso 2 — Extractor del Senado

`30_procesamiento/3X_extraer_senado_asistencia.R`, con:

1. `/api/legislatures?limit=100` → **derivar la legislatura vigente por fecha**, nunca
   hardcodear (la exploración previa usó la 504, que es de 2024-2025).
2. `/api/sessions?id_legislatura=<vigente>&limit=500` → catálogo con fecha y tipo.
3. `/api/sessions/attendance?id_sesion=<id>` por cada sesión → panel nominal.
4. `/api/parlamentarios?vigentes=1&limit=300`, filtrando `CAMARA=="S"` → padrón.

**Verificable en cada paso:** filas por sesión == 50; llave `(sesión, senador)` única;
ids ⊆ padrón; y la compuerta de la laguna 1 (catálogo − centinelas == `TOTAL_SESIONES`).

**Cliente HTTP:** hace falta uno nuevo. `descargar_xml_camara()` de `10_utils` es XML-only y
el backend del Senado es JSON. Reusar el patrón de caché (`con_cache`), no el parser.

### Paso 3 — Llave compuesta `(camara, parlamentario_id)` (D3)

**No es opcional.** Hay **5 colisiones numéricas activas** entre ids de senador vigente y
`diputado_id`, y en **5 de 5 designan personas distintas**; los rangos se solapan
(803-1264 vs 911-1518). Un join sin la llave compuesta produciría 5 cruces silenciosamente
incorrectos **hoy mismo**. Ver la corrección a D3 en el catálogo del Senado.

### Paso 4 — Regla de sesiones sin dato

Implementar la detección de la laguna 1 **antes** de calcular cualquier tasa, con el test
contra el agregado oficial como compuerta permanente del refresh.

### Paso 5 — Publicación incremental

Publicar primero **el panel nominal y las tasas del ámbito `periodo_vigente`**, que es lo
que tiene fuente sólida. Dejar `justificacion.codigo`, `rebaja_*` y `n_sin_registro` como
`null` explícito, **declarando la asimetría en el propio JSON**, no en una nota al pie.

---

## 5. Riesgos, el que más preocupa primero

1. **Las sesiones centinela publicadas como inasistencia real.** Es el único riesgo de esta
   lista que **produce una cifra falsa con aspecto de correcta**, y afecta a los 50
   senadores simultáneamente. Mitigación: laguna 1, con compuerta permanente.

2. **La colisión de identificadores.** 5 pares activos hoy, 5 de 5 personas distintas. Un
   join descuidado mezcla parlamentarios. Mitigación: D3, llave compuesta, sin excepción.

3. **La asimetría de justificaciones publicada como equivalencia.** La Cámara tiene 12
   códigos con referencia normativa; el Senado, 2 glosas de texto libre en 21 de 2700 filas.
   Publicar `tasa_presencia_o_justificada` para ambas cámaras **como si midieran lo mismo**
   sería una comparación inválida. Mitigación: publicar el titular D18
   (`tasa_presencia`) para ambas, y la tasa con justificación **solo para la Cámara**.

4. **Sin descriptor, el contrato del Senado no tiene garantía.** No hay OpenAPI ni WSDL: la
   forma de la respuesta se conoce **por observación**. Un cambio del backend rompería el
   extractor sin aviso previo. Y **el sobre no es uniforme entre rutas del mismo backend**
   (`data$data` en unas, `data$DATA` en otras). Mitigación: validación de forma en cada
   extracción, con `stop()` diagnóstico.

5. **Estabilidad de identificadores verificada solo a 4 semanas.** 50 de 50 senadores y 155
   de 155 diputados conservan id, nombre y slug entre el 2026-07-10 y el 2026-08-07. No hay
   captura anterior a marzo de 2026, y el caso Longton/Mirosevic prueba que **una persona
   recibe id nuevo al cambiar de cámara**: el id es estable **por ficha**, no por persona.

6. **`page` se ignora en silencio** en `/api/votes`. No afecta a asistencia, pero el mismo
   backend ya demostró que puede aceptar un parámetro y no aplicarlo. Mitigación: usar
   `offset` y verificar solapamiento entre páginas.
