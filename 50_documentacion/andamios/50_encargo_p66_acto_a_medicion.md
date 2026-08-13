# Encargo P-66 acto A — Medición del contrato de la entidad `proyecto` (solo lectura)

> **Destino en el repositorio:** `50_documentacion/andamios/50_encargo_p66_acto_a_medicion.md`
> **Proyecto:** `transparencia_legislativa_chile`
> **Sesión:** 21 (2026-08-13)
> **Naturaleza:** medición y diagnóstico. **Este encargo no construye la entidad
> `proyecto`, no escribe en `40_salidas/`, no escribe en `docs/` y no modifica
> ningún script de `30_procesamiento/`, `10_utils/` ni `00_run_all.R`.**

---

## §0. Contrato positivo del encargo

Esta sección separa lo que está respaldado por una lectura de esta sesión de lo
que es hipótesis. **Ninguna hipótesis se usa como premisa de una decisión: se
verifica en la compuerta que la nombra, y si falla, el encargo se detiene.**

### 0.1 Afirmaciones respaldadas (con su fuente)

| # | Afirmación | Fuente |
|---|---|---|
| R1 | El contrato propuesto de la entidad `proyecto` (llave `boletin`, bloques `tramitacion`, `autores`, `votaciones`, `materias`, `metadatos.cobertura_materias`) está redactado en `50_documentacion/activa/50_veredicto_eje_tematico.md` §5.2 | Documento leído íntegro en la apertura de la sesión 21 |
| R2 | Todas las cifras del veredicto están ancladas a intermedios sellados al **2026-07-27** y a un artefacto publicado del **2026-08-03**, y su universo es de **381 boletines** | `50_veredicto_eje_tematico.md` §2, encabezado de la tabla |
| R3 | El veredicto declara que la tramitación se resuelve vía SIL (`tramitacion.senado.cl/wspublico/tramitacion.php`) y que el catálogo de materias sale de `WSLegislativo.asmx/retornarMaterias` | `50_veredicto_eje_tematico.md` §2 y §7 |
| R4 | El veredicto declara que las métricas que gatean el refresh semanal son cuatro y que **ninguna cubre materias ni tramitación** | `50_veredicto_eje_tematico.md` §7, nota de compuerta |
| R5 | `30_procesamiento/` contiene `32`, `33`, `34`, `35`, `36` y `39`; `10_utils/` contiene `10_configuracion.R`, `10_diff_conteos.R`, `10_locale.R` y `10_utils.R`; `40_salidas/intermedios/` contiene seis `.rds` | `estructura_actual.md` del 2026-08-13 12:55, leído en la apertura |
| R6 | Existen en disco `50_documentacion/activa/50_catalogo_fuentes_camara.md`, `50_documentacion/activa/50_catalogo_fuentes_senado.md` y `50_documentacion/andamios/20260807_sondeo_fuentes.R` | mismo escáner |
| R7 | La sesión 20 no modificó el pipeline y cerró con `main` y la rama del sondeo con working tree limpio | `traspaso_cierre_v20.md` §3 y §11.3 |

### 0.2 Hipótesis (no son premisas; cada una tiene su compuerta)

| # | Hipótesis | Se verifica en |
|---|---|---|
| H1 | `CORTE_FECHA` vale `2026-08-12` | G1 |
| H2 | El universo del corte vigente es de 427 boletines, 422 sin materia, 336 de cohorte 2026 | G1 (se **remide**, no se hereda) |
| H3 | El nodo `Votaciones` de `retornarProyectoLey` quedó persistido tras P-63 y sus campos alcanzan el bloque `votaciones` del contrato | G2 |
| H4 | El SIL resuelve por boletín con la forma que usó el sondeo del 2026-08-07 | G3 |
| H5 | El SIL cubre el universo vigente con una tasa comparable al 381 de 381 del veredicto | G4 |
| H6 | La rama `sondeo/p68-fuentes-tematicas` fue mergeada y `50_veredicto_fuentes_tematicas_bcn.md` está en `main` | G0 |

---

## §1. Encabezado de contrato

**Modo:** autónomo, secuencial, todo en este turno. No pidas confirmación entre
compuertas ya aprobadas.

**Regla de detención.** Detente y reporta **solo** ante: (a) un invariante 🔒 que
tendrías que cruzar; (b) un dato real que contradice una hipótesis de §0.2 de
forma que cambie el sentido de la medición; (c) una compuerta marcada
explícitamente como decisión del titular. En cualquier otro caso resuelve con
autonomía y regístralo en el log.

**Contrato de entorno.**

1. **ENTORNO:** filesystem local del titular, vía Claude Code, sobre
   `/Users/tomgc/Projects/transparencia_legislativa_chile`.
2. **INSUMOS:** todos viven en ese filesystem y se leen desde ahí. No hay
   insumos "que llegan aparte". Los que este encargo nombra son:
   - `10_utils/10_configuracion.R`
   - `10_utils/10_utils.R`
   - `10_utils/10_diff_conteos.R`
   - `20_insumos/camara/` (crudo, solo lectura)
   - `30_procesamiento/34_extraer_votaciones.R`, `35_extraer_proyectos.R`, `36_extraer_detalle_proyectos.R`, `39_consolidar_json.R`
   - `50_documentacion/activa/50_veredicto_eje_tematico.md`
   - `50_documentacion/activa/50_veredicto_fuentes_tematicas_bcn.md`
   - `50_documentacion/activa/50_catalogo_fuentes_camara.md`
   - `50_documentacion/activa/50_catalogo_fuentes_senado.md`
   - `50_documentacion/andamios/20260807_sondeo_fuentes.R` (arte previo, **no fuente de verdad**)
3. **POSICIÓN:** toda ruta completa desde la raíz. Ningún comando asume `cd`
   previo. `git` siempre con `-C /Users/tomgc/Projects/transparencia_legislativa_chile`.
   `gh` siempre con `-R tomgc/transparencia_legislativa_chile`, **salvo `gh api`**,
   que no acepta `-R`.

**Reglas canónicas heredadas.** `POLITICA_PROYECTO.md` v5.6 y
`SETTINGS_Y_PROMPTS_OPERACIONALES.md` v23. R es el único lenguaje, en todo
contexto: sin `jq`, sin `awk`, sin `python`, sin `grep`/`sed` sobre artefactos de
datos, sin regex en `Rscript -e`. Pipe nativo `|>`, `.by=`, `here::here()` dentro
de scripts.

---

## §2. Contexto mínimo suficiente

El portal publica hoy la entidad **parlamentario**. P-66 quiere publicar una
segunda entidad, **`proyecto`**, cuyo contenido de valor es la **tramitación**
(en qué etapa está cada proyecto y desde cuándo), no las materias: P-68 cerró la
vía temática y el veredicto de BCN fija ese alcance.

El contrato propuesto de esa entidad ya está escrito (R1). El problema es que
**todas sus cifras son de un universo que ya no existe** (R2): se midieron sobre
381 boletines, con intermedios sellados cuatro semanas antes del corte vigente.
Escribir el extractor sobre esas cifras repetiría el error de umbral que el §15
del traspaso v20 acaba de registrar.

Este encargo es el acto A: **medir**. El acto B (construir el extractor, el
artefacto y su compuerta) se redacta después, con la medición en mano.

---

## §3. Invariantes (🔒)

- 🔒 **Cero escrituras en `40_salidas/` y en `docs/`.** Ninguna fase de este
  encargo produce, regenera ni toca un intermedio ni un JSON publicado.
- 🔒 **Cero modificaciones a `30_procesamiento/`, `10_utils/` y `00_run_all.R`.**
  Se leen; no se editan. Si detectas un arreglo necesario, lo anotas como
  hallazgo, no lo aplicas.
- 🔒 `20_insumos/camara/` es crudo inmutable. Se lee. No se agrega ni se
  sobrescribe nada ahí. Las respuestas de red de este encargo van a
  `20_insumos/exploracion/<AAAAMMDD>/`, carpeta gitignorada, siguiendo el
  precedente de `20260807` y `20260813`.
- 🔒 No se persiste ninguna respuesta HTTP distinta de 200.
- 🔒 `main` no recibe push directo de este encargo. El trabajo va en rama y, si
  corresponde, a PR.
- 🔒 D26: el denominador de toda métrica temática es el subconjunto tipo
  `Proyecto de Ley`. Nunca el total de votaciones.
- 🔒 D28: `proyectos_detalle.rds` mantiene una fila por boletín. D29: los campos
  con atributo de dominio conservan código y glosa.
- 🔒 Toda cifra que reportes se recuenta programáticamente en el mismo momento en
  que la escribes. Ninguna cifra de este encargo, del veredicto ni del traspaso
  se hereda: si aparece en tu reporte, la contaste tú en esta corrida.

---

## §4. Presupuesto de red

**Máximo 600 llamadas HTTP en total**, repartidas así: hasta 20 en G3 (pruebas de
vida y controles) y hasta 560 en G4 (censo). Si el censo necesitara más, detente
y reporta: significa que el universo creció más de lo previsto y el costo por
refresh es una decisión del titular, no tuya.

Registra el conteo real de llamadas y repórtalo. Entre llamadas, pausa acorde al
patrón ya usado en el proyecto para no maltratar la fuente.

---

## §5. Compuertas, en orden estricto

Cada compuerta: **Paso 0 de lectura del estado real**, medición, criterio
observable de término. Si el criterio falla, detente y reporta.

### G0 — Estado del repositorio y sello del crudo

**Paso 0.** `git -C <raiz> status --porcelain`, `git -C <raiz> branch --show-current`,
`git -C <raiz> fetch` y luego `git -C <raiz> log -1 --format=%H` sobre `main`.
`gh pr list -R tomgc/transparencia_legislativa_chile --state all --limit 20`.

**Qué mide.**

1. Working tree limpio. Si no lo está, **detente y reporta** el detalle: la
   disposición del contenido sucio es del titular (precedente §4.2 del traspaso
   v20), no tuya.
2. Que `50_documentacion/activa/50_veredicto_fuentes_tematicas_bcn.md` exista en
   `main` (H6). Si no existe, **detente**: el veredicto que fija el alcance de
   P-66 no está en la rama sobre la que vas a medir.
3. Sello de `20_insumos/camara/`: número de archivos, bytes totales y md5
   agregado, calculado **en R**. Este sello se recalcula idéntico al cierre.

**Criterio de término.** Tree limpio, veredicto presente en `main`, sello
registrado con sus tres valores.

**Acción.** Crea y sitúate en la rama `medicion/p66-acto-a` desde `main`
actualizado.

---

### G1 — Universo y denominadores al corte vigente (offline)

**Paso 0.** Lee `10_utils/10_configuracion.R` y declara el valor literal de
`CORTE_FECHA` con el número de línea donde está. **No lo heredes de H1.**

**Cómo medir.** Sobre las **capturas crudas del corte vigente** en
`20_insumos/camara/`, no sobre los intermedios de `40_salidas/`. Motivo: los
intermedios pueden estar desalineados con `CORTE_FECHA` (estado normal entre
merges del bot) y tocarlos arriesga disparar la autorregeneración, que escribiría
en `40_salidas/` y cruzaría un 🔒.

**Qué mide, todo con su denominador declarado en la misma línea:**

1. Boletines totales del corte.
2. Boletines con al menos una materia, y sin ninguna.
3. Cohorte anual de los boletines, por año de `FechaIngreso`.
4. Votaciones totales y votaciones tipo `Proyecto de Ley` (D26).
5. Filas de voto totales y filas cuyo boletín es no vacío.
6. Boletines con al menos un autor, y filas autor-proyecto.
7. Autores distintos y cuántos de ellos están en el padrón vigente.

**Criterio de término.** Una tabla de siete filas, cada una con numerador,
denominador y la ruta del artefacto de donde salió. Si alguna cifra coincide
exactamente con la del veredicto o la del traspaso, dilo explícitamente: la
coincidencia es un resultado, no una confirmación de que heredaste bien.

---

### G2 — Inventario de lo ya persistido contra el contrato §5.2 (offline)

**Paso 0.** Lee `50_veredicto_eje_tematico.md` §5.2 completo, y lee
`30_procesamiento/35_extraer_proyectos.R`, `36_extraer_detalle_proyectos.R`,
`34_extraer_votaciones.R` y la función de parseo de contenido de proyecto en
`10_utils/10_utils.R`.

**Qué mide.** Campo por campo del contrato §5.2, una fila por campo:

| Campo del contrato | ¿Existe hoy en disco? | Artefacto y columna exactos | Cobertura sobre el universo de G1 | Qué falta |

Incluye explícitamente: `boletin`, `nombre`, `tipo_iniciativa`, `camara_origen`,
`fecha_ingreso`; el bloque `tramitacion` completo (`etapa_actual`, `estado`,
`ley_numero`, `tramites[]`); `autores[]` con `parlamentario_id`; `votaciones[]`
con `votacion_id`, `fecha`, `tipo`, `tramite_constitucional`, `articulo`,
`resultado`; `materias[]`; y `metadatos.cobertura_materias`.

**Verificación específica de H3.** Comprueba **leyendo el artefacto**, no el
código ni un comentario (A70), si el nodo `Votaciones` de `retornarProyectoLey`
quedó persistido tras P-63 y qué campos trae. Declara la cobertura del bloque
`votaciones` sobre el universo de G1.

**Criterio de término.** La tabla completa, sin celdas vacías. Todo campo que hoy
no tenga fuente en disco queda marcado como dependiente del SIL o como faltante
sin fuente conocida.

---

### G3 — Prueba de vida del SIL y sus controles (red, hasta 20 llamadas)

**Paso 0.** Lee `50_catalogo_fuentes_senado.md` y `20260807_sondeo_fuentes.R`
para reconstruir la forma de la llamada. Trata el script como arte previo y no
como fuente de verdad: si su forma no funciona hoy, la que manda es la que
responde.

**Qué mide.**

1. **Forma de resultado, no código de estado (A82).** Un 200 no basta: exige la
   estructura XML esperada, con el nombre de nodo raíz y los nodos de trámite
   explicitados en tu reporte.
2. **Control positivo (D37):** 5 boletines tomados del universo de G1 que
   existen con certeza. Deben devolver trámites.
3. **Control negativo (A84):** 5 boletines **falsos pero bien formados** (misma
   serie, número inexistente). Debes poder distinguir "no existe" de "existe sin
   trámites". Si no puedes distinguirlos, dilo: cambia la interpretación de todo
   el censo de G4.
4. **Búsqueda de la llave también en la URI o atributo del recurso, no solo como
   literal (A83)**, antes de declarar cualquier ausencia.

**Criterio de término.** Control positivo 5 de 5 y control negativo 0 falsos
positivos. Si el positivo no da 5 de 5, **detente y reporta**: un censo sobre una
consulta que no aprueba su propio control no es medición.

---

### G4 — Censo del SIL sobre el universo completo (red, hasta 560 llamadas)

**Paso 0.** Construye la lista de boletines **pedidos** desde el universo de G1, y
guárdala antes de llamar.

**Qué mide, con cuadre obligatorio (D38).** La reconciliación se hace **siempre
contra la lista pedida**, nunca contra lo devuelto, y el cuadre lo prueba con
`stopifnot()`:

1. Boletines resueltos sobre boletines pedidos.
2. Trámites totales y distribución por boletín (mínimo, mediana, máximo).
3. Trámites con fecha parseable, sobre trámites totales.
4. Boletines con `etapa` no vacía; con `estado` no vacío; con `ley_numero` no
   vacío. Cada uno sobre el denominador de boletines resueltos **y** sobre el
   universo pedido: son dos cifras distintas y ambas importan.
5. Distribución de valores de `etapa` y `estado`: cuántos valores distintos, y
   si vienen con código y glosa o solo con texto libre (D29).

**Persistencia.** Respuestas 200 a `20_insumos/exploracion/<AAAAMMDD>/`, con
manifiesto y reproductor. Ninguna respuesta distinta de 200 se persiste.

**Criterio de término.** El cuadre pasa, y cada cifra del listado anterior viene
con numerador y denominador contados en esta corrida.

---

### G5 — Costo por refresh (medición, no decisión)

**Qué mide.** Duración total del censo, latencia mediana y máxima por llamada,
tasa de respuestas no 200, tamaño agregado de lo descargado, y la proyección: qué
significaría correr esto dentro del cron semanal.

**Criterio de término.** Las cinco cifras, medidas. **La decisión de si la
tramitación entra al cron semanal, entra con caché por corte o entra como paso
manual es del titular: repórtala como gate abierto, no la tomes.**

---

### G6 — La compuerta ausente (lectura, sin implementar)

**Paso 0.** Lee `10_utils/10_diff_conteos.R` completo.

**Qué mide.** Cuántas métricas gatean hoy el refresh y cuáles son, con el número
de línea donde se declaran (R4 dice cuatro; verifícalo, no lo heredes). Propón
por escrito qué métrica de tramitación habría que agregar y contra qué se
compararía. **No la implementes:** es acto B.

---

### G7 — Panel adversarial

Antes de escribir el reporte, lanza agentes de solo lectura que **re-deriven con
código propio e independiente** las tres afirmaciones de mayor riesgo:

- **P1.** El universo y el denominador tipo `Proyecto de Ley` de G1, reconstruidos
  desde el crudo por otro camino.
- **P2.** La cobertura de tramitación de G4, recontada contra la lista pedida sin
  reutilizar tu objeto de resultados.
- **P3.** Que ninguna ruta bajo `40_salidas/` ni `docs/` fue escrita durante la
  corrida, comprobado por mtime y por `git status`.

Si un panelista contradice tu cifra, **manda el panelista**: detente, reporta
ambas y no publiques la tuya como buena.

---

## §6. Entregables

1. **Ficha de medición:** `50_documentacion/andamios/50_medicion_p66_acto_a.md`,
   con las tablas de G1, G2, G4, G5 y G6, cada cifra con universo y denominador
   en la misma línea (A81), y una sección final de **gates abiertos para el
   titular**.
2. **Log de ejecución:** `50_documentacion/andamios/logs/<AAAAMMDD>_p66_acto_a_log.md`,
   según la plantilla fija de `encargo_autonomo_claude_code_v1.md` §4, honesto:
   incluye lo que costó, no solo lo que salió bien.
3. **Reproductor y manifiesto** en `20_insumos/exploracion/<AAAAMMDD>/`
   (gitignorada).
4. **Commits** en `medicion/p66-acto-a`, atómicos y con `git add` de ruta
   acotada, nunca `git add .`. Sin push salvo instrucción explícita del titular.

---

## §7. Reporte final al chat

En un solo mensaje, y en este orden:

1. Valor literal de `CORTE_FECHA` con su línea, y el sello md5 de
   `20_insumos/camara/` de apertura y de cierre, uno al lado del otro.
2. La tabla de G1 completa.
3. La tabla de G2 completa.
4. Las cifras de G4 con sus dos denominadores.
5. Las cinco cifras de costo de G5.
6. Resultado del panel adversarial, panelista por panelista, con PASA/FALLA.
7. Estado de cada 🔒 de §3, con su evidencia.
8. Llamadas de red gastadas contra las 600 autorizadas.
9. Gates abiertos para el titular, listados como decisiones, no como sugerencias.
10. Rutas de la ficha y del log, y hashes de los commits.
