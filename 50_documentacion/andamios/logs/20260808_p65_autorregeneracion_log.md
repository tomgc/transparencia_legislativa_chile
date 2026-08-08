# Log de ejecución — P-65: el orquestador resuelve el desalineamiento de sello

- **Encargo:** `50_documentacion/andamios/50_encargo_p65_autorregeneracion_intermedios.md`
- **Sesión:** 16. **Fecha:** 2026-08-08.
- **Rama:** `fix/autorregeneracion-intermedios`. **PR abierto, no mergeado.**
- **Resultado:** `run_all()`, en cualquiera de sus formas, detecta el desfase que P-62
  documentó y regenera `32`–`36` desde la captura cruda ya versionada, sin red y con aviso.
  Si no puede hacerlo sin red, se detiene con el diagnóstico. La compuerta del `39` quedó
  intacta.

---

## 1. Fase 0 — lo que dictó el diseño

| Pregunta | Respuesta, con archivo y línea |
|---|---|
| Cómo se reciben `from`/`to`/`only`/`skip` | Firma única `run_all()` en [00_run_all.R:53](../../../00_run_all.R:53). Valida IDs en [:64-68](../../../00_run_all.R:64) y rutas en [:71-75](../../../00_run_all.R:71); resuelve en [:86-94](../../../00_run_all.R:86): `only` anula `from`/`to`, y `skip` se resta con `setdiff` |
| Orden de ejecución | Siempre recorre `PASOS` en su orden de declaración 32→33→34→35→36→39 ([:32-45](../../../00_run_all.R:32), bucle [:98](../../../00_run_all.R:98)). `only` filtra, no reordena |
| Dónde encaja el chequeo | **Punto único**: dentro de `run_all()`, tras validar rutas y antes de resolver pasos. Las cuatro formas de invocación pasan por ahí |
| Cómo se construye la ruta de la captura cruda | `ruta_cache(nombre, tope)` en [10_utils.R:223](../../../10_utils/10_utils.R:223) → `20_insumos/camara/<AAAAMMDD>_<nombre><sufijo_tope>.rds`, con `corte_para_clave()` ([:196](../../../10_utils/10_utils.R:196)) y `sufijo_tope()` ([:183](../../../10_utils/10_utils.R:183)) |
| ¿Utilidad de sello reutilizable? | `leer_sellado()` ([:89](../../../10_utils/10_utils.R:89)) y `validar_corte()` ([:104](../../../10_utils/10_utils.R:104)), pero **ambas abortan**: son la compuerta, no un inspector |

**Compuerta 0: pasa.** Hay un punto único de paso, así que no hubo que reportar
alternativas.

**Claves de caché por extractor (5 extractores, 6 capturas):**

| Paso | Clave(s) | Archivo del corte 2026-08-03 |
|---|---|---|
| 32 | `diputados` ([32:65](../../../30_procesamiento/32_extraer_diputados.R:65)) | `20260803_diputados.rds` |
| 33 | `periodo_legislativo` ([33:47](../../../30_procesamiento/33_extraer_asistencia.R:47)) y `asistencia_nominal_2026` ([33:76](../../../30_procesamiento/33_extraer_asistencia.R:76)) | `20260803_periodo_legislativo.rds`, `20260803_asistencia_nominal_2026_tope-inf.rds` |
| 34 | `votos_long_2026` ([34:33](../../../30_procesamiento/34_extraer_votaciones.R:33)) | `20260803_votos_long_2026_tope-inf.rds` |
| 35 | `proyectos_long_2026` ([35:26](../../../30_procesamiento/35_extraer_proyectos.R:26)) | `20260803_proyectos_long_2026_tope-inf.rds` |
| 36 | `detalle_proyectos_2026`, `tope = Inf` ([36:70](../../../30_procesamiento/36_extraer_detalle_proyectos.R:70)) | `20260803_detalle_proyectos_2026_tope-inf.rds` |

---

## 2. Fase 1 — dónde quedó la guarda

| Pieza | Ubicación |
|---|---|
| Bloque completo | [10_utils/10_utils.R:242-366](../../../10_utils/10_utils.R:242) |
| `INTERMEDIOS_PIPELINE` (los 6 que consume el `39`) | [10_utils.R:258](../../../10_utils/10_utils.R:258) |
| `capturas_crudas_de_paso()` (claves de caché por paso) | [10_utils.R:266](../../../10_utils/10_utils.R:266) |
| `corte_declarado_por()` (lector de sello que **no** aborta) | [10_utils.R:283](../../../10_utils/10_utils.R:283) |
| `regenerar_intermedios_si_desalineados()` | [10_utils.R:294](../../../10_utils/10_utils.R:294) |
| `PASOS_EXTRACCION` (derivado de `PASOS`, no una segunda lista) | [00_run_all.R:50](../../../00_run_all.R:50) |
| **Punto de inserción — 1 solo sitio de invocación** | **[00_run_all.R:84](../../../00_run_all.R:84)** |

Comportamiento, en orden: lee el sello de los 6 → si los 6 declaran el corte vigente
devuelve `FALSE` en silencio → si no, comprueba que la captura cruda del corte esté para
los 5 extractores → si está, anuncia y regenera 32–36 con caché forzado, y vuelve a
verificar (`stop()` si siguen desalineados) → si no está, `stop()` con los archivos que
faltan, el motivo y los `source()` exactos.

**Lo que la guarda NO hace:** no toca `CORTE_FECHA`, no escribe sellos a mano, no salta
`validar_corte()`, no descarga nada. Y no vive dentro del `39`: invocar el `39` suelto con
intermedios desalineados sigue fallando, que es lo correcto.

---

## 3. Fase 2 — banco de pruebas

Los 6 `.rds` se respaldaron antes de empezar (**6 de 6**).

| # | Escenario | Cómo se indujo | Resultado observado |
|---|---|---|---|
| **1** | Sellos alineados | Estado actual | `regenero = FALSE`, **0 líneas** de salida, **0 de 6** intermedios reescritos. **PASA** |
| **2** | Sello desalineado, caché presente | Se leyeron los 6, se puso `attr(x, "sello")$corte_fecha <- "2026-07-27"` y se reescribieron con `saveRDS()` a secas, **sin** `escribir_atomico()`. Después, `run_all(only = 39)` — la invocación exacta que P-62 encontró rota | La guarda avisó (**5 líneas**), regeneró con **6 cache hit / 0 descargas**, el `39` corrió y declaró *"Procedencia validada: 6 intermedios al corte 2026-08-03"*; **6 de 6** sellos al corte vigente; 11,8 s. **PASA** |
| **3** | Intermedio ausente | `asistencia_ambitos.rds` movido a un temporal (se eligió ese porque además lleva el atributo `alcance`) | Tratado como desalineado (`ausente o sin sello`); regeneró en **1,0 s**, **6 cache hit / 0 descargas**; **6 de 6** presentes y sellados; atributo `alcance` recuperado. **PASA** |
| **4** | Caché ausente | Corte inexistente `2099-01-01` reasignado **solo en memoria** de una sesión desechable. **No se borró ni movió nada** de `20_insumos/camara/` y **no se escribió** `10_utils/10_configuracion.R` (comprobado por md5 en la misma corrida) | `stop()` nombrando los **6** archivos `20990101_*` que faltan, el motivo (la regeneración no baja de la red) y los **5** `source()` exactos; **0 de 6** intermedios reescritos. **PASA** |

El escenario 4 sí se pudo inducir sin violar el invariante 5, así que **no queda ninguno
declarado como no probado**.

**Compuerta 2 — `20_insumos/camara/` inmutable:** **43 archivos** antes y después,
**43 de 43** md5 iguales, 0 nuevos, 0 perdidos, `identical()` TRUE sobre la tabla completa.

---

## 4. Fase 3 — no regresión

| # | Verificación | Cifra |
|---|---|---|
| 1 | `00_run_all.R` corre completo | **Sin error, 12,1 s**; 6 pasos ejecutados, 0 saltados |
| 2 | JSON regenerado vs publicado en `HEAD`, **excluido `metadatos.generado`, volátil por construcción** ([39:365](../../../30_procesamiento/39_consolidar_json.R:365)) | **156 de 156 idénticos** (155 perfiles + índice) |
| 2b | `corte_fecha`, que **no** es volátil y sí se compara | **155 de 155** idéntico, valor único `2026-08-03` |
| 2c | Artefactos que difieren **solo** por `generado` | 155 de 156 (el índice no lleva ese campo) |
| 3 | Diferencias fuera de `generado` | **0 de 156** |
| 4 | `docs/` y `40_salidas/json/` restaurados | Antes de restaurar, `docs/data` era copia fiel del canónico en **156 de 156** md5; tras `git checkout`, `git status` acotado a esas rutas: **0 líneas** |
| 5 | `sellar()`, `leer_sellado()` y `validar_corte()` | **3 de 3 idénticas a `HEAD`**, comparando el bloque completo de cada función (13, 11 y 21 líneas) |
| 6 | `10_utils/10_configuracion.R` | **Idéntico a `HEAD`**; `CORTE_FECHA` sigue en `2026-08-03` |

`validar_corte()` se re-verificó después del `checkout`: sigue pasando **6 de 6**.

---

## 5. Decisiones tomadas en autonomía

1. **La guarda recibe las rutas desde `PASOS`** (`PASOS_EXTRACCION`, derivado con `Filter`) en vez de repetirlas: dos listas de rutas se desincronizan solas.
2. **Las claves de caché sí viven en la guarda**, junto a `ruta_cache()`, porque no existe registro de claves y replicarlas ahí es más barato que inventarle uno al proyecto.
3. **`corte_declarado_por()` envuelve `leer_sellado()` en `tryCatch`** en vez de escribir un segundo lector de sello: aquí "no legible" ES la condición a diagnosticar, no un fallo.
4. **La guarda fuerza `camara.refrescar = FALSE` durante la regeneración** y restaura la opción con `on.exit`: el invariante de cero red no puede depender de cómo dejó la opción el operador.
5. **La guarda corre siempre, sin condicionar a qué pasos se van a ejecutar.** En un `run_all()` completo con desfase eso repite 32–36; el costo medido es ~1 s desde caché y la alternativa agrega una rama de decisión que hay que probar.
6. **El escenario 2 se cerró con `run_all(only = 39)`** en vez de llamar a la guarda suelta: es la invocación que P-62 encontró rota, así que es la que prueba el arreglo.
7. **Se actualizó `CLAUDE.md`** (sección "Últimos cambios"), por convención del repositorio; no lo pedía el encargo.

---

## 6. Documentación corregida

1. **`procedimiento_actualizacion.md`, "Verificación de reproducibilidad":** se retiró el paso manual que P-62 había agregado (`run_all(from = 32, to = 36)` antes de `run_all(only = 39)`) y se reemplazó por la descripción de la guarda: qué detecta, qué anuncia, que no genera tráfico y en qué caso falla ruidosamente. Queda **una sola instrucción** sobre regeneración.
2. **Sección "Pendiente 2 — Automatización con GitHub Actions (NO EJECUTAR AÚN)":** describía como pseudocódigo un workflow que corre desde el 2026-07-10. Se reescribió como descripción del workflow real (`.github/workflows/refresh-semanal.yml`), declarado operativo, con sus disparadores, el gate de conteos, y que el bot no escribe en `main` sino que abre PR (P-22). La observación al margen de P-62 §10 queda cerrada.
