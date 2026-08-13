
# Traspaso de cierre v18 — transparencia_legislativa_chile

## §1. Identificación

| Campo | Valor |
|---|---|
| Proyecto | `transparencia_legislativa_chile` |
| Versión | v18 |
| Fecha de cierre | 2026-08-12 |
| Sesión | 18 |
| Foco | Cerrar el contrato temporal de la captura (P-74, en dos actos) y, a partir de un hallazgo de ese trabajo, reparar la guarda circular que tenía roto el refresh semanal automático desde el 2026-08-08. |
| Entorno | R 4.5.2 en Positron (macOS), pipe nativo, `dplyr >= 1.1`, `here::here()`. Claude Code como agente de ejecución. Modelo: Opus 5. |
| Protocolo usado | `POLITICA_PROYECTO.md` **v5.6** y `SETTINGS_Y_PROMPTS_OPERACIONALES.md` **v23**, leídos desde la knowledge base del Project (fuente: `project_knowledge_search` de la sesión 18). El traspaso v17 citaba SETTINGS v16: el delta se declara en §15, error 2. |
| Archivos principales modificados | `10_utils/10_utils.R`, `30_procesamiento/36_extraer_detalle_proyectos.R`, `00_run_all.R`, `CLAUDE.md`, más andamios y logs en `50_documentacion/andamios/`. |

## §2. Resumen ejecutivo

La sesión abrió con dos residuos de la 17 (el traspaso v17 sin commitear y el v16
sin archivar) y con P-74 como foco propuesto: la deuda temporal que la sesión 17
creó al rescatar el nodo `Votaciones`. P-74 se ejecutó en dos actos separados por
una decisión del titular. El acto (a) fue una medición read-only que encontró un
solo evento posterior al corte (1 de 723) y, sobre todo, encontró por qué: la
captura del paso 36 se descargó el 2026-08-08 bajo una clave que declaraba el corte
2026-08-03, cinco días antes, mientras las otras siete capturas del mismo corte se
bajaron el día que la clave dice. Eso movió el eje del problema desde el sello hacia
la ventana entre descarga y corte declarado, y abrió una tercera vía que ninguno de
los dos caminos previstos cubría. El titular eligió esa vía (C), con la contención
(A) como paliativo, y el acto (b) la implementó: una guarda que detiene la escritura
de cualquier captura cuya descarga caiga fuera del corte, un registro de la fecha
real de descarga adherido a cada captura nueva, un reporte de tres estados al cerrar
la corrida, y un filtro en el 36 que acota el nodo al corte emitiendo cuántos
eventos descarta. Al verificar ese trabajo contra el único camino desatendido del
proyecto apareció el hallazgo mayor de la sesión: el bot semanal estaba roto desde
el PR #6 por una guarda circular que exigía capturas que solo esa misma corrida
podía crear, y la corrida programada del lunes 2026-08-10 ya había fallado en
producción. Se reparó separando tres estados que la guarda colapsaba en uno, y la
reparación se verificó de punta a punta con un `workflow_dispatch` real que completó
los diez pasos y produjo el PR #10, ya mergeado. El proyecto cierra con el refresh
automático restituido, el contrato temporal operando con evidencia de producción (6
de 6 capturas `dentro_de_corte`) y sin bugs activos.

## §3. Estado al cierre

**`main` previo al commit de cierre:** `3f01124` (Merge pull request #10 from
tomgc/refresh/2026-08-12) (fuente: `git log --oneline -1 origin/main` tras `git
fetch`, sesión 18). El hash definitivo del cierre lo agrega Claude Code al eco de
reapertura; este traspaso no lo cita, por A69 y por SETTINGS §2.1.

**Qué funciona**

| Componente | Evidencia (fuente: sesión 18) |
|---|---|
| Refresh semanal automático | Corrida `31594962972` por `workflow_dispatch`, 10 de 10 pasos en verde, 10m11s, desde checkout fresco sobre `8027544` |
| Guarda del contrato temporal (P-74 vía C) | 6 de 6 capturas del corte 2026-08-12 con atributo, 6 de 6 `dentro_de_corte`, `escape = FALSE` en las 6 |
| Contención del nodo (P-74 vía A) | El 36 emitió su conteo en el runner: 0 de 737 eventos descartados, 0 de 119 boletines vaciados |
| Guarda de primera corrida (reparación de P-65) | El runner emitió el mensaje de la rama nueva: 0 de 6 archivos de intermedio en disco, los pasos 32-36 los crearán |
| Neutralidad del artefacto público | 156 de 156 idénticos en `40_salidas/json/` y 156 de 156 en `docs/data/`, excluido `metadatos.generado` |
| Regeneración sin red (P-65 en su caso original) | C4 del PR #9: `exit 0`, fusible sin disparar, 6 de 6 `cache hit`, intermedios regenerados al corte |

**Qué no funciona:** sin bugs activos al cierre.

**Delta respecto a v17**

- `CORTE_FECHA` pasó de `2026-08-03` a **`2026-08-12`**, inyectado por el bot y
  mergeado por el PR #10.
- `20_insumos/camara/` pasó de 44 a **50** capturas: las 6 del corte 2026-08-12 son
  las primeras del proyecto que llevan registro de su fecha real de descarga.
- El universo del nodo `Votaciones` pasó de 723 eventos en 115 boletines (corte
  08-03) a **737 eventos en 119 boletines** (corte 08-12). Toda cifra del acto (a)
  queda anclada a su corte y no se hereda al nuevo.
- El bot semanal pasó de roto (sin que nadie lo supiera) a verificado en producción.

## §4. Registro detallado de cambios

### 4.1 Cierre retroactivo de la sesión 17

**Archivos:** `50_documentacion/traspasos/` (archivado del v16 con `git mv`),
`traspaso_cierre_v17.md`, `backlog_acumulativo.md`, `ESTADO.md`,
`50_documentacion/estructura/`, `CLAUDE.md`. **Categoría:** documentación e
higiene de repositorio.

**Qué:** la sesión 17 cerró sin commitear. El traspaso v17 estaba sin trackear, el
v16 sin archivar (`vigentes = 2`) y `CLAUDE.md` registraba como "sin merge, gate del
titular" dos ramas que ya estaban en `main` por los PRs #6 y #7. Se archivó el v16,
se integró la tercera fila del §15 del v17 (más los campos `intentos_previos` y
`costo`, que faltaban en las dos filas existentes) y se corrigieron las dos entradas
de `CLAUDE.md`.

**Por qué (C.11):** el traspaso es el único puente entre sesiones; uno sin commitear
es un puente que existe solo en el disco de una máquina.

**Cómo se verificó (B.4):** `a22a8da` en `origin/main`, `git status --porcelain`
vacío, `ls traspasos/*.md | wc -l` = 1.

### 4.2 P-74 acto (a): medición del contrato temporal

**Archivos:** `50_documentacion/andamios/50_medir_p74_contrato_temporal.R` y su log.
**Categoría:** diagnóstico/exploración. **Commit:** `0a0a87c`.

**Qué:** medición read-only en tres fases (compuertas, pipeline, criterios). Seis
compuertas respondidas por lectura directa y seis objetivos medidos. Resultados
centrales, todos con denominador contado en la corrida: el nodo aporta **20** campos
(v16 hipotetizaba 14, el traspaso v17 lo corrigió a 20), **1** de ellos de fecha;
**1 de 723** eventos posterior al corte, en **1 de 115** boletines; **0
consumidores** del nodo (0 de 17 campos exclusivos en código fuera del productor, 0
de 17 en las 106 claves de 156 JSON); `validar_corte()` devuelve `TRUE` con el exceso
presente. Barrido de los seis intermedios en tres estados: 1 sin campo de fecha, 4
con fecha y cero excesos, 1 con exceso.

**Por qué (C.11):** P-74 era precondición declarada de P-66 y su costo crecía con
cada corte.

**Cómo se verificó (B.4):** 9 criterios, dos degradados a "CUMPLE con limitación
declarada" por hallazgos del propio panel; 0 llamadas HTTP; `10_utils.R` sin cambios
contra `HEAD`.

**Tensión resuelta:** el panel adversarial derribó dos afirmaciones del primer
borrador, una de ellas causalmente falsa (atribuir el exceso a la forma del
endpoint, cuando `34_extraer_votaciones.R:51` usa el mismo patrón por entidad). El
reemplazo no fue suavizar el texto sino medir la fecha de commit de cada captura,
que es lo que reveló la causa real.

### 4.3 P-74 acto (b): el contrato temporal de la captura

**Archivos:** `10_utils/10_utils.R`, `30_procesamiento/36_extraer_detalle_proyectos.R`,
`00_run_all.R`. **Categoría:** infraestructura. **PR #8**, commits `e58c87f` y
`fbebe45`, mergeado en `b619a50`.

**Qué (vía C, el contrato):**

| Pieza | Ubicación | Función |
|---|---|---|
| `escape_captura_declarado()` | `10_utils.R:253` | Lee `getOption`, **no** `Sys.getenv()`: una variable del shell no puede encender la excepción |
| `consumir_escape_captura()` | `10_utils.R:262` | Apaga el escape al usarlo (un solo uso) |
| `guarda_captura_en_corte()` | `10_utils.R:273` | Detiene la escritura de una captura cuya descarga cae fuera del corte, con mensaje accionable |
| `verificar_cierre_de_descarga()` | `10_utils.R:312` | Vuelve a mirar el reloj después de descargar, por si el bucle cruzó la medianoche |
| `registrar_captura()` | `10_utils.R:332` | Adhiere `descarga_fecha`, `descarga_inicio`, `descarga_fin`, `corte_fecha`, `escape` |
| `estado_temporal_captura()` | `10_utils.R:358` | Clasifica en `dentro_de_corte`, `fuera_de_corte`, `sin_registro` |
| `reportar_estado_capturas()` | `10_utils.R:378`, invocado en `00_run_all.R:131` | Reporta con denominador al cerrar la corrida |

**Qué (vía A, la contención):** `acotar_votaciones_al_corte()` en el 36 acota el nodo
a `fecha <= CORTE_FECHA` **antes** del `tibble()`, emitiendo cuántos eventos descarta
sobre cuántos y cuántos boletines quedarían vacíos.

**Por qué (C.11):** de las tres vías, (B) exigía que el sello validara contenido y
chocaba con el invariante que lo declara intocable; (A) sola contenía el síntoma en
un script sin impedir la reincidencia en otro paso; (C) ataca la causa medida (que
una clave declare un corte que su captura no honra) y es la única que generaliza.

**Cómo se verificó (B.4):** 14 criterios, todos CUMPLE, con los denominadores
medidos sobre la captura de la propia corrida y no heredados del acto (a). 44 de 44
capturas con md5 intacto; 156 de 156 artefactos neutros en ambos destinos; 0
llamadas HTTP contadas en el mismo proceso que corrió `run_all()`; las tres
funciones selladas idénticas a `HEAD`.

**Tensión resuelta (G4, la trampa del encargo):** el encargo pedía poner el filtro
"entre `n_votaciones` y el list-col". No existe tal lugar: son dos argumentos de la
misma llamada a `tibble()` alimentados por la misma expresión. Filtrar antes del
`tibble()` satisface la exigencia real (`n_votaciones` calculado sobre el nodo ya
acotado) y la validación preexistente del 36 lo ata.

**Cuatro hallazgos del panel que cambiaron el resultado**, registrados porque su
mecanismo es reutilizable: el escape quedaba pegajoso entre pasos de un mismo
`run_all()` (los seis pasos comparten sesión vía `source()`); si faltara la columna
`fecha` el filtro devolvía cero filas en silencio; el contador de HTTP certificaba
el proceso del verificador y no el que corría el pipeline; y un comentario afirmaba
tres tipos de objeto probados cuando la prueba había corrido sobre uno.

### 4.4 Reparación de la guarda circular del bot semanal

**Archivos:** `10_utils/10_utils.R`, más andamios y log. **Categoría:**
automatización. **PR #9**, commit `d43857b`, mergeado en `8027544`.

**Síntoma observable:** la corrida `schedule` del 2026-08-10 murió en 1m5s con
`exit code 1` y **0 de 6** pasos ejecutados.

**Causa raíz:** `regenerar_intermedios_si_desalineados()` exigía que las capturas
crudas del corte vigente estuvieran en disco para permitir continuar. En el runner
eso nunca se cumple en la primera corrida de un corte: checkout fresco, intermedios
gitignorados, y las capturas que la guarda exige son exactamente las que esa corrida
iba a descargar. La guarda era circular en el único camino capaz de romper el ciclo.

**Solución:** separar tres estados que colapsaban en uno. (1) Primera corrida: no
existe **ningún** archivo de intermedio, no hay desalineamiento posible, sigue. (2)
Desalineado con capturas presentes: regenera sin red, como antes. (3) Desalineado
con capturas ausentes y sin autorización de descarga: `stop()`, que era correcto.
Además, `capturas_crudas_de_paso()` pasó a resolver el corte de una sola forma: antes
evaluaba desalineamiento contra el argumento `corte` y existencia de capturas contra
la global `CORTE_FECHA` vía `ruta_cache()`.

**El hallazgo que salvó la reparación:** la condición inicial era
`all(is.na(declarados))`, y `corte_declarado_por()` devuelve `NA` por tres causas
distintas: archivo ausente, archivo presente sin sello, archivo presente corrupto.
Un repositorio con seis intermedios sin sello (que es corrupción, no arranque)
habría entrado por la rama de primera corrida y se habría puesto a descargar. La
condición pasó a `sum(file.exists(...)) == 0`, y el criterio C2b lo prueba.

**Cómo se verificó (B.4):** cinco escenarios con un **fusible** instalado (`quit(99)`
en la primera llamada de red, no un contador que reporte al final): C2 supera la
guarda y muere en el fusible; C3 la detención es el fusible y no la guarda; C4
`exit 0` con 6 de 6 `cache hit`; C5 `stop()` accionable; C5b con autorización
declarada, pasa. Un `stop()` no habría servido como fusible: el 36 lo atrapa y lo
degrada a `estado = error_red`.

**Cómo se verificó en producción:** `workflow_dispatch` sobre `main` con el PR #9
dentro. Corrida `31594962972`, 10 de 10 pasos, 10m11s, y el runner emitió el mensaje
de la rama nueva. Es la evidencia de punta a punta que el log del PR #9 declaraba
faltante.

### 4.5 Restitución del refresh en producción (no contado como cambio)

El PR #10 (`refresh/2026-08-12`, 319 de 319 archivos: 156 en `docs/data/`, 156 en
`40_salidas/json/`, 6 capturas nuevas y `10_utils/10_configuracion.R`) se revisó y
mergeó. **0** archivos de código en el PR del bot y **0** intermedios versionados
(D24 respetado). El recómputo independiente desde la captura del PR cuadra con lo
que el pipeline emitió: 737 eventos, 119 boletines con nodo, 0 con fecha posterior
al corte, máxima 2026-08-11.

## §5. Backlog acumulativo

Vive en `50_documentacion/activa/backlog_acumulativo.md`. Esta sesión agrega las
entradas **53 a 55** (última previa: 52). El delta completo, con los pares exactos
de reemplazo de la taxonomía y del resumen estadístico, viaja en el bloque
BACKLOG_DELTA del paquete de cierre.

## §6. Bugs de la sesión

### Bug 1 — La guarda de P-65 es circular en la primera corrida de un corte

- **Síntoma observable:** el workflow `refresh-semanal.yml` termina con `exit code 1`
  y 0 de 6 pasos ejecutados. Ocurrió en producción el 2026-08-10 (corrida
  `31385303604`).
- **Causa raíz:** ver §4.4.
- **Solución exacta:** `10_utils/10_utils.R`, separación de los tres estados en
  `regenerar_intermedios_si_desalineados()` y unificación de la resolución de corte
  en `capturas_crudas_de_paso()`. PR #9, commit `d43857b`.
- **Criterio de verificación:** C2 y C4 probados juntos (que el bot arranque no debe
  costar que P-65 deje de regenerar sin red), más la corrida real del runner.
- **Patrón general aprendido:** *una guarda que exige un estado que solo la acción
  guardada puede producir es circular, y su circularidad es invisible en la máquina
  donde ese estado ya existe.* El defecto vivió cuatro días sin detectarse porque en
  el disco local las capturas y los intermedios estaban ahí.
- **Principios:** aplica B.4 (validación por paso) y "fallo ruidoso"; el defecto
  original violaba la reproducibilidad desde cero (auditoría 5.6 pregunta 2).
- **Estado:** resuelto y verificado en producción.

### Bug 2 — El nodo `Votaciones` traía un evento posterior al corte declarado

- **Síntoma observable:** un evento de votación con fecha 2026-08-04 en una captura
  cuya clave declara el corte 2026-08-03, pasando las seis compuertas sin ruido.
- **Causa raíz:** la captura del paso 36 se descargó el 2026-08-08 bajo la clave del
  corte 2026-08-03; `corte_para_clave()` construye la clave desde `CORTE_FECHA` y no
  desde la fecha de descarga, así que nada relacionaba una con otra.
- **Solución exacta:** PR #8 (ver §4.3), vía C como contrato y vía A como contención.
- **Criterio de verificación:** 14 criterios del acto (b), más la evidencia de
  producción del corte 2026-08-12.
- **Patrón general aprendido:** *un identificador que declara una propiedad del dato
  no la garantiza; mientras nada compare la declaración con el hecho, la clave y el
  contenido divergen en silencio.*
- **Principios:** aplica C.11 (estabilidad del contrato) y el invariante de dato
  crudo inmutable (D24), que descartó reescribir las capturas existentes.
- **Estado:** resuelto. Queda declarado que el contrato no cubre las 44 capturas
  anteriores, que permanecen en `sin_registro`.

## §7. Aprendizajes y restricciones descubiertas

- **A72 — Una salvaguarda que exige previsión no es una compuerta.** El invariante 3
  del encargo del bot decía "si una prueba fuera a descargar, no se corre", y falló
  en el primer caso donde importaba: 3230 llamadas HTTP no solicitadas. El reemplazo
  estructural es el fusible (`quit(99)` en la primera llamada de red), que no
  requiere prever nada. *Contexto:* toda regla redactada como "no hagas X si
  detectas Y" delega en el juicio del ejecutor exactamente en el momento en que ese
  juicio está comprometido. *Principio:* POLITICA 0.5.
- **A73 — `stop()` no sirve como fusible cuando algún consumidor lo atrapa.** El 36
  captura errores y los degrada a `estado = error_red`, así que un `stop()` en la
  capa de red se convierte en una fila de estado y la corrida continúa. Un fusible
  debe usar `quit()`. *Contexto:* aplicable a cualquier instrumentación de
  verificación sobre este pipeline.
- **A74 — `NA` con más de una causa no puede sostener una rama de control.**
  `corte_declarado_por()` devuelve `NA` por ausencia, por falta de sello y por
  corrupción; ramificar sobre `is.na()` trata los tres como el mismo estado. La
  condición debe medir el hecho que importa (`file.exists()`), no su proxy.
- **A75 — La fecha de commit de un archivo versionado es evidencia sobre el dato.**
  Comparar `git log -1 --format=%ad` de cada captura contra el corte que su clave
  declara fue lo que reveló la causa de P-74, después de que dos explicaciones
  plausibles resultaran falsas. *Contexto:* aplicable a todo `20_insumos/` versionado.
- **A76 — Un contador que reporta al final certifica el proceso donde vive.** El
  criterio C11 del acto (b) contaba llamadas HTTP en el proceso del verificador, no
  en el que corría `run_all()`, y el "0" resultante era cierto e irrelevante.
- **A77 — Una premisa fáctica de un encargo, aunque venga de un log propio, es
  hipótesis hasta contarla.** El §0 del encargo del acto (b) afirmaba "las 8 capturas
  existentes"; el directorio tenía 44, de las cuales 8 eran del corte vigente. Ver
  §15, error 1.

## §8. Decisiones de diseño

### D31 — Qué afirma una captura sobre su propio alcance temporal

**Decisión.** Desde P-74, una captura de `20_insumos/camara/` afirma sobre sí misma
en qué fecha real se descargó y si esa descarga cayó dentro del corte que su clave
declara. El pipeline se detiene antes de escribir una captura nueva cuya descarga
caiga fuera de ese corte, salvo excepción declarada de un solo uso que queda marcada
en el propio registro. Lo que una captura **sigue sin afirmar**: que su contenido
quepa dentro del corte (eso se acota al derivar, solo en el paso 36 y solo por el
borde superior), y nada sobre las capturas anteriores al contrato, que quedan en
`sin_registro`, un tercer estado que no es conformidad.

**Alternativas consideradas.** (A) Filtrar al derivar, sin contrato: contenía el
síntoma en un script y no impedía la reincidencia en otro paso. (B) Que el sello
validara contenido: exigía ensanchar `validar_corte()`, hoy invariante, con un mapeo
explícito intermedio → campo temporal que no puede ser genérico (`diputados` tiene un
campo de fecha que no se compara con el corte).

**Justificación.** (C) ataca la causa medida y no el síntoma, y es la única de las
tres que generaliza a los seis pasos sin tocar el gate compartido.

**Tensión resuelta.** A67 declaraba que el sello valida el corte declarado y no el
contenido, lo que sugería (B). La medición mostró que el exceso no lo producía el
sello sino la ventana entre descarga y corte: A67 sigue siendo cierto y deja de ser
la causa.

**Implicancia.** Las 44 capturas previas quedan permanentemente en `sin_registro`,
porque el crudo no se reescribe (D24). El reporte no distingue "no sabemos" de
"sabemos que está mal", y una de esas 44 está medida como descargada cinco días
tarde. Cerrar esa distinción exige un registro lateral (pendiente).

**Estado:** pendiente de ratificación del titular.

### D32 — Qué distingue una primera corrida de un estado corrupto

**Decisión.** La rama de primera corrida se decide por `sum(file.exists(...)) == 0`
sobre los archivos de intermedio, no por `all(is.na(corte_declarado_por(...)))`. Un
intermedio presente pero sin sello o corrupto **no** es una primera corrida: recibe
`stop()` con los archivos nombrados.

**Alternativas consideradas.** Detectar el entorno de CI (`Sys.getenv("CI")`),
descartada explícitamente por el criterio C6 del encargo: haría que el pipeline se
comportara distinto según dónde corre, que es lo contrario de la reproducibilidad.

**Justificación.** La condición debe medir el hecho (hay o no hay archivos) y no un
proxy que confunde tres causas.

**Implicancia.** Queda un camino declarado y no cerrado: quien borre sus intermedios
por accidente sin tener capturas del corte ahora descarga en vez de recibir un
`stop()` útil.

**Estado:** implementada y verificada (C2, C2b, C4, C5).

## §9. Constantes y parámetros

| Constante | Valor anterior | Valor nuevo | Archivo | Motivo |
|---|---|---|---|---|
| `CORTE_FECHA` | `"2026-08-03"` | `"2026-08-12"` | `10_utils/10_configuracion.R:41` | Inyectada por el workflow (línea 75) en la corrida del 2026-08-12; llegó a `main` con el merge del PR #10 |

Constantes **nuevas** introducidas por el contrato temporal, declaradas en
`10_utils/10_utils.R:246-248`: `ATRIBUTO_CAPTURA`, `OPCION_ESCAPE_CAPTURA` y
`ESTADOS_CAPTURA` (los tres estados). La opción de escape del contrato es
`camara.permitir_captura_fuera_de_corte`; la de la guarda de primera corrida es
`camara.permitir_descarga_inicial`. Ambas apagadas por defecto.

`ANIO_PROCESO` sin cambios (`2026L`, `10_utils/10_configuracion.R:27`). La fuente
canónica de las vigentes sigue siendo `10_utils/10_configuracion.R`.

## §10. Arquitectura de archivos

El escáner de cierre lo regenera Claude Code (`sello_escaner: regenerar` en el
paquete). Cambios estructurales de la sesión, todos dentro de convención:

- `50_documentacion/andamios/` suma tres encargos y dos scripts de verificación.
- `50_documentacion/andamios/logs/` suma tres logs de ejecución.
- `50_documentacion/traspasos/` queda con un solo archivo vigente tras el archivado
  del v16 (`vigentes = 1`, verificado en la sesión).
- `20_insumos/camara/` pasa de 44 a 50 archivos.

**Deuda estructural heredada, sin cambios:** siete archivos de
`50_documentacion/activa/` sin el prefijo `50_` que POLITICA §2 exige y que no están
en la lista cerrada de excepciones; huecos de numeración 31, 37 y 38 en
`30_procesamiento/`; y `50_documentacion/andamios/design_handoff_portal_transparencia/Portal Transparencia.dc.html`,
único nombre del repositorio con un espacio. Todo es materia de P-60.

## §11. Pendientes y ruta sugerida

### 11.1 Inventario

**P-76 — El escape de la guarda de primera corrida no se consume al usarse.**
*Contexto:* `camara.permitir_descarga_inicial` queda encendida tras usarse, a
diferencia de `camara.permitir_captura_fuera_de_corte`, que el PR #8 hizo de un solo
uso precisamente porque `run_all()` corre los seis pasos en la misma sesión vía
`source()`. *Tipo:* deuda técnica. *Impacto:* medio; encenderla para un paso la deja
encendida para los cinco siguientes. *Dependencias:* ninguna. *Complejidad:* baja.
*Principios:* consistencia con D31. *Precauciones:* el patrón ya existe en el
proyecto (`consumir_escape_captura()`); replicarlo, no inventar otro. *Enfoque:*
extraer el consumo a un helper común. *Criterio de éxito:* una prueba análoga a C4b
del PR #8, con la segunda invocación deteniéndose.

**P-77 — Borrar los intermedios sin tener capturas del corte ahora descarga.**
*Contexto:* declarado y no cerrado en el log del PR #9. Quien limpie
`40_salidas/intermedios/` por accidente entra por la rama de primera corrida.
*Tipo:* deuda técnica. *Impacto:* medio; el modo de falla es una descarga completa no
solicitada, que ya ocurrió una vez en esta sesión por otra vía. *Complejidad:* baja a
media. *Precauciones:* la solución no puede reintroducir la circularidad de P-65;
distinguir "no hay nada" de "había algo y ya no" exige un rastro que hoy no existe.
*Criterio de éxito:* el caso se distingue del arranque legítimo con evidencia en
disco, y ambos escenarios se prueban juntos.

**P-78 — Ratificación de D31.** *Tipo:* documentación. *Complejidad:* baja.
*Criterio de éxito:* D31 replicada como archivo en
`50_documentacion/activa/decisiones/` según SETTINGS §2.2 punto 8.

**P-79 — `sin_registro` no distingue "no sabemos" de "sabemos que está mal".**
*Contexto:* 44 de 50 capturas están en `sin_registro`, y al menos una (la del 36 del
corte 08-03) está medida como descargada cinco días tarde. *Tipo:* deuda técnica.
*Impacto:* medio. *Precauciones:* el crudo no se reescribe (D24), así que exige un
registro lateral. *Criterio de éxito:* el reporte distingue tres estados de
conocimiento sin tocar ninguna captura existente.

**P-80 — Las 6 capturas del corte 2026-08-09 siguen en cuarentena fuera del repo.**
*Contexto:* producto de la descarga no solicitada (§15, error 3). Están bien formadas
y fueron las primeras en llevar el registro del contrato. *Tipo:* decisión pendiente.
*Complejidad:* baja. *Criterio de éxito:* destino resuelto explícitamente
(conservar como captura legítima de ese corte o descartar), no por omisión.

**P-81 — La contención (A) cubre solo el paso 36 y solo el nodo `Votaciones`.**
*Contexto:* los demás campos que viajan en la misma respuesta (`nombre`,
`tipo_iniciativa`, `materias`) no tienen contención de contenido, y el paso 34 no
tiene ninguna. *Tipo:* deuda técnica. *Impacto:* bajo mientras la guarda de D31
funcione; la contención es el segundo anillo. *Criterio de éxito:* decisión explícita
sobre si el segundo anillo se generaliza o se declara innecesario.

**Pendientes heredados que siguen vigentes:** el borde inferior del nodo (eventos
anteriores a `ANIO_PROCESO`: 176 de 723 medidos al corte 08-03, sin decisión del
titular); **P-68** (sondear LeyChile y `datos.bcn.cl` como fuente temática
alternativa); **P-66** (publicar la entidad `proyecto`, cuya precondición P-74 quedó
cerrada, y cuyo diseño ya tiene el reemplazo estructural del regex de
`34_extraer_votaciones.R:26-29` medido con 0 discrepancias); **P-59** (locale UTF-8,
gatillo 4ter encendido: `grep -rl asegurar_locale_utf8 10_utils | wc -l` = 0);
**P-60** (ordenación, gatillo 4bis encendido, ahora con dos hallazgos nuevos);
**P-57**; **P-75**; y la arquitectura del pipeline del Senado.

### 11.2 Evaluación de deuda técnica

**Zonas frágiles.** La primera es el propio conjunto de guardas: el proyecto tiene
ahora cuatro (`validar_corte()`, la de P-65 reparada, la de D31 y la contención del
36) y esta sesión demostró dos veces que una guarda puede pasar sus pruebas y aun así
tener un camino abierto. La segunda es la asimetría entre los dos escapes (P-76): dos
mecanismos con la misma función y semántica distinta invitan a usar el equivocado. La
tercera es que `sin_registro` agrupa 44 de 50 capturas, lo que hace que el reporte de
D31 sea informativo sobre 6 y mudo sobre el resto.

**Oportunidades.** El fusible construido en el PR #9 es reutilizable como
instrumento estándar de toda prueba que corra el pipeline, y conviene promoverlo
desde el andamio a `10_utils/`. El patrón de "probar la guarda en ambos sentidos"
(C2 con C4) debería ser exigencia fija de todo encargo que toque una guarda.

### 11.3 Auditoría de cierre (política 5.6, preguntas "Cierre")

| # | Pregunta | Respuesta |
|---|---|---|
| 2 | ¿El pipeline corre de cero sin intervención manual? | **Sí**, y por primera vez demostrado en producción: corrida `31594962972`, 10 de 10 pasos desde checkout fresco. Hasta esta sesión la respuesta real era "no". |
| 5 | ¿Cada transformación crítica tiene check de validación? | **Parcial.** Lo construido esta sesión sí (el filtro valida esquema, formato de ambos operandos y emite conteos; `identical()` ata `n_votaciones` al list-col). El paso 34 sigue sin contención de contenido → **P-81**. |
| 6 | ¿Los outputs son reproducibles e idempotentes? | **Sí.** 156 de 156 idénticos en `40_salidas/json/` y 156 de 156 en `docs/data/`, excluido `metadatos.generado`, verificado contra línea base propia. |
| 7 | ¿Decisiones metodológicas como constantes nombradas? | **Parcial.** Las nuevas sí (`ATRIBUTO_CAPTURA`, `OPCION_ESCAPE_CAPTURA`, `ESTADOS_CAPTURA`). P-57 sigue abierto para el resto. |
| 8 | ¿Nombres sin tildes, ñ ni espacios? | **No.** `Portal Transparencia.dc.html` contiene un espacio → materia de **P-60**. |

### 11.4 Ruta sugerida para la sesión 19

**Prioridad 1 — P-76 y P-77 en un solo PR.** *Por qué:* son la deuda declarada y no
cerrada del PR #9, viven en el mismo archivo y en la misma guarda, y el criterio de
priorización 5 (deuda técnica en la zona donde acaban de aparecer bugfixes
recurrentes) pide cerrarlas antes de construir encima. *Complejidad:* baja a media.
*Criterio de éxito:* el escape de primera corrida se consume al usarse, verificado
con una prueba análoga a C4b; y el caso "intermedios borrados sin capturas" se
distingue del arranque legítimo, con ambos escenarios probados juntos y sin
reintroducir la circularidad de P-65.

**Prioridad 2 — P-68: sondeo de LeyChile y `datos.bcn.cl`.** *Por qué:* sigue siendo
lo único capaz de dar vuelta el veredicto del eje temático, y ese veredicto
condiciona el alcance de P-66, que es el siguiente paso grande del proyecto y cuya
precondición (P-74) quedó cerrada esta sesión. *Complejidad:* media. *Criterio de
éxito:* veredicto cerrado con denominador declarado, y un reproductor que no persista
respuestas distintas de 200.

**Prioridad 3 — P-59, locale UTF-8 (gatillo 4ter).** *Por qué:* barata, con helper
que se copia idéntico desde `herramientas_dev/plantillas/10_locale.R`, y el gatillo
lleva dos aperturas encendido. *Complejidad:* baja. *Criterio de éxito:*
`grep -rl asegurar_locale_utf8 10_utils` devuelve 1 o más y existe
`50_documentacion/activa/50_locale_utf8.md`.

**Qué conviene diferir.** P-66 hasta tener el resultado de P-68. P-60 (gatillo 4bis):
sigue ofrecido y sigue sin recomendarse, ahora con dos hallazgos más que documentar;
mueve demasiados archivos para competir con trabajo de datos. Los pendientes del
Senado. El borde inferior, que espera decisión del titular y no trabajo técnico.

## §12. Instrucciones específicas para la próxima sesión

- ⚠️ **NO** afirmar `CORTE_FECHA`, el sello de un intermedio ni el hash de `main` sin
  leerlos en el momento de afirmarlo. `CORTE_FECHA` cambia con cada merge de PR del
  bot y hoy es `2026-08-12`, no `2026-08-03`.
- ⚠️ **NO** heredar las cifras del acto (a) de P-74 (723 eventos, 115 boletines, 176
  del borde inferior): están ancladas al corte 2026-08-03. Al corte 2026-08-12 el
  universo es 737 en 119, y el borde inferior no se ha vuelto a medir.
- ⚠️ **NO** correr `run_all()` en local sin sincronizar antes con `main`: el working
  tree quedó en el corte 2026-08-03 y la guarda reparada lo leerá como primera
  corrida del corte nuevo y **descargará**.
- ⚠️ **NO** correr ninguna prueba que ejercite el pipeline sin el fusible instalado
  (`quit(99)` en la primera llamada de red). Un `stop()` no basta: el 36 lo atrapa y
  lo degrada a `estado = error_red` (A73).
- ⚠️ **NO** publicar cobertura temática sobre el denominador total de votaciones: el
  correcto es el subconjunto tipo `Proyecto de Ley` (D26), y su cifra debe medirse al
  corte vigente, no heredarse.
- ⚠️ **NO** publicar un bloque `materias` ni vista temática mientras la cobertura sea
  marginal; la cifra vigente es del corte 08-03 y hay que remedirla.
- ⚠️ **NO** hacer join entre Cámara y Senado por identificador numérico solo: 5
  colisiones activas, 5 de 5 personas distintas (D25).
- ⚠️ **NO** tratar un comentario de código como fuente sobre quién consume una
  función (A70).
- ⚠️ **NO** usar `gh pr diff --name-only`: HTTP 406 en PRs grandes. Usar `gh api`
  paginado sobre `/repos/<owner>/<repo>/pulls/<n>/files`; `gh api` **no** acepta `-R`,
  el repositorio va en la ruta del endpoint.
- ⚠️ **NO** tratar `<Materias/>` ni `<Votaciones/>` como nodos ausentes: vienen
  presentes y autocerrados.
- ⚠️ **NO** usar `senadores_vigentes.php` como padrón; la ruta confiable es
  `/api/parlamentarios?vigentes=1&limit=300` filtrando `CAMARA=="S"`.
- ⚠️ **NO** usar `/api/sessions/attendance?id_legislatura=`: devuelve un agregado sin
  dimensión de sesión. Solo `?id_sesion=` satisface D2.
- ✅ **ANTES** de calcular cualquier tasa de asistencia del Senado, aplicar la
  detección de sesiones centinela (3 de 54 devuelven las 50 filas en `Ausente`).
- ✅ **ANTES** de declarar una cobertura, declarar su denominador en la misma línea y
  contarlo programáticamente en ese turno.
- ✅ **ANTES** de escribir una salvaguarda en un encargo, comprobar que no exige
  previsión del ejecutor: si empieza por "si detectas que...", es juicio y no
  compuerta (A72).
- ✅ **ANTES** de ramificar sobre `NA`, enumerar sus causas: si son más de una, la
  condición debe medir el hecho y no el proxy (A74).
- ✅ **ANTES** de dar por probada una guarda, probar el caso en que **no** debe
  dispararse, no solo aquel en que sí.
- ✅ **ANTES** de commitear cualquier caché de exploración, evaluar si contiene dato
  personal (A63). El repositorio es público.
- ✅ **ANTES** de dar por entregado un artefacto, comprobar que quedó adjunto en el
  mismo turno que lo anuncia (A52).
- ✅ **ANTES** de aceptar una cifra que coincide con un denominador conocido, medirla
  desde el otro lado (A71).
- 🔒 `sellar()`, `leer_sellado()` y `validar_corte()` no se tocan.
- 🔒 La guarda del contrato temporal (D31) y su registro no se aflojan sin decisión
  explícita del titular.
- 🔒 Los intermedios no se versionan (D24). `20_insumos/camara/` es crudo inmutable:
  ninguna captura existente se reescribe, renombra ni borra.
- 🔒 `main` no recibe escrituras automáticas ni push directo. El bot abre PR.
- 🔒 `sin_registro` no se imputa, ni en el dato ni en la presentación.
- 🔒 El titular de asistencia del portal es
  `asistencia.periodo_vigente.tasa_presencia` (D18); el corte vive en
  `asistencia.alcance_temporal.corte_fecha`.
- 🔒 R es el único lenguaje, en todo contexto. Sin `jq`, `awk`, `python`, ni
  `grep`/`sed` sobre artefactos de datos; sin regex en `Rscript -e`.
- 🔒 `git` siempre con `-C <ruta absoluta>`, `gh` siempre con `-R tomgc/...` **salvo
  `gh api`**, `git add` siempre con ruta acotada.
- 🔒 `proyectos_detalle.rds` mantiene una fila por boletín (D28).
- 🔒 Los campos con atributo de dominio se conservan con código y glosa (D29).

## §13. Fragmentos de código de referencia

**Fusible de red para pruebas que ejercitan el pipeline** (patrón nuevo de esta
sesión, A73). Se instala antes de `source("00_run_all.R")` y mata el proceso en la
primera llamada, en vez de contarlas y reportar al final:

```r
# Fusible: quit(99), no stop(). El paso 36 atrapa stop() y lo degrada a
# estado = error_red, de modo que un stop() dejaria continuar la corrida.
instalar_fusible_red <- function() {
  matar <- function(...) {
    message("FUSIBLE: intento de llamada de red durante una prueba sin red.")
    quit(save = "no", status = 99L)
  }
  for (fn in c("GET", "POST", "RETRY")) {
    if (exists(fn, envir = asNamespace("httr"))) {
      suppressMessages(trace(fn, where = asNamespace("httr"),
                             tracer = matar, print = FALSE))
    }
  }
  suppressMessages(trace("curl_fetch_memory", where = asNamespace("curl"),
                         tracer = matar, print = FALSE))
  invisible(TRUE)
}
```

Los patrones estables del proyecto viven en `CLAUDE.md` y en
`50_documentacion/activa/documentacion_tecnica_v1.md`; este traspaso no los re-copia.

## §14. Reapertura

Tipo: CONTINUATION. El protocolo (`POLITICA_PROYECTO.md` v5.6,
`SETTINGS_Y_PROMPTS_OPERACIONALES.md` v23) vive en la knowledge base del Project y se
lee desde ahí; verifica las versiones contra la knowledge base, no contra ninguna
otra fuente, antes de la Fase A. Ojo con esto: el traspaso v17 citaba SETTINGS v16 y
la sesión 18 afirmó en su acuse que coincidían "sin delta" cuando la knowledge base
ya tenía la v23, que cambia el canal de cierre completo. Verifícalo de nuevo.

Estado: la sesión 18 cerró P-74 en dos actos y, a partir de un hallazgo del acto (a),
reparó una guarda circular que tenía roto el refresh semanal desde el PR #6. El bot
está verificado en producción (corrida `31594962972`, 10 de 10 pasos) y su PR #10 ya
está mergeado, así que `CORTE_FECHA` es `2026-08-12` y no `2026-08-03`. Hay 50
capturas en `20_insumos/camara/`, de las cuales 6 llevan registro de su fecha real de
descarga y 44 quedan en `sin_registro`. Sin bugs activos.

No le creas a este traspaso sobre ninguna cifra del nodo `Votaciones`: 723 eventos y
115 boletines son del corte 2026-08-03 y hoy el universo es 737 en 119. Tampoco sobre
`CORTE_FECHA` ni sobre el hash de `main`: léelos con `grep` y `git log` en el momento
de afirmarlos.

Advertencia operativa: el working tree local quedó en el corte 2026-08-03. Si corres
`run_all()` sin sincronizar con `main`, la guarda reparada lo leerá como primera
corrida del corte nuevo y descargará el año completo.

El foco propuesto es P-76 y P-77 en un solo PR: el escape de la guarda de primera
corrida no se consume al usarse (asimétrico con el de D31, que sí) y borrar los
intermedios sin tener capturas del corte ahora descarga en vez de detenerse. Son la
deuda declarada y no cerrada del PR #9, viven en la misma guarda, y conviene cerrarlas
antes de construir encima. Encadenado: P-68, sondear LeyChile y `datos.bcn.cl`, que
sigue siendo lo único capaz de dar vuelta el veredicto del eje temático y condiciona
el alcance de P-66, cuya precondición quedó cerrada esta sesión.

Dos decisiones esperan ratificación: D31 (qué afirma una captura sobre su alcance
temporal) y el destino de las 6 capturas del corte 2026-08-09 que quedaron en
cuarentena fuera del repositorio.

Dos gatillos de protocolo siguen encendidos: 4bis (ordenación, P-60) y 4ter (locale
UTF-8, P-59).

El §15 trae cuatro errores registrados, tres de ellos del asistente conversacional y
uno de instrumento; el tercero produjo 3230 llamadas HTTP no solicitadas y su causa
raíz está en cómo fue redactada una salvaguarda del encargo, no en la ejecución.

Documentos para la próxima sesión:

1. *Protocolo en knowledge base* (no se adjuntan; se listan para verificar que la
   knowledge base esté al día): `POLITICA_PROYECTO.md`,
   `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
2. *Opcionales según el foco real:* `CLAUDE.md` si la sesión correrá en Claude Code.
3. *Específicos de la sesión:* `traspaso_cierre_v18.md`.

## §15. Errores del asistente

| Campo | Error 1 | Error 2 | Error 3 | Error 4 |
|---|---|---|---|---|
| `momento` | Fase C, al redactar el §0 del encargo de P-74 acto (b) | Fase A, al declarar las versiones de protocolo verificadas contra la knowledge base | Redacción del encargo de reparación de la guarda del bot, §2 invariante 3 | Turno de recomendación tras la revisión del PR #8, antes de proponer el merge |
| `disparador` | Claude Code lo detectó al responder la compuerta G3 y lo declaró como premisa que no verifica | El titular pidió leer la knowledge base al cerrar; la lectura mostró v23 donde el acuse había afirmado v16 sin delta | Claude Code lo reportó tras ejecutar la prueba: la corrida descargó de verdad | El asistente lo detecta aquí, al redactar este registro |
| `que_paso` | El §0 afirmó "las 8 capturas existentes" y lo propagó al invariante 2 y al criterio C5. El directorio tenía 44; 8 eran del corte vigente. La cifra se tomó de la tabla de M3 del log del acto (a), que listaba las 8 del corte, y se generalizó a todo el directorio sin contarlo | El acuse de la Fase A afirmó que `POLITICA` v5.6 y `SETTINGS` v16 "coinciden con lo citado en el §1 del traspaso, sin delta". La knowledge base tenía SETTINGS **v23** | El invariante se redactó como "si una prueba fuera a descargar, no se corre". No previó que arreglar la guarda es precisamente lo que permite al pipeline alcanzar los extractores, así que la prueba de C2 se convirtió en un refresh completo no solicitado | Se recomendó no mergear el PR #8 por un supuesto desfase de huso entre el corte calculado por el workflow y `Sys.Date()` en el runner, sin haber leído el workflow: ambos leen el mismo reloj del mismo runner |
| `regla_violada` | POLITICA 0.6 (S-01) tipo 4: premisa fáctica de un encargo. Y tipo 3: cifra comunicada sin recuento programático | POLITICA 0.6 tipos 1 y 3, y SETTINGS §1.2.2 paso 3, que exige verificar la versión vigente contra la knowledge base | POLITICA 0.5 y el propio §2 del encargo. La regla no fue violada por el ejecutor: fue mal construida por el redactor | POLITICA 0.6 (S-01) tipo 1: contenido de un archivo no leído en la sesión (`refresh-semanal.yml`) |
| `causa_raiz` | Un log propio de la misma sesión se sintió fuente primaria. Lo es sobre lo que midió (las capturas del corte), no sobre lo que no midió (el directorio completo). El salto fue de un subconjunto medido a un universo no contado, y la coincidencia del sustantivo ("capturas") lo hizo invisible | Se verificó `POLITICA` (que sí coincidía) y se extendió la conclusión al segundo documento sin comprobarlo. La estructura "leí la knowledge base" se sintió cumplida por haber leído *algo* de ella. El costo es alto porque el delta v16→v23 cambia el canal de cierre completo | La salvaguarda se redactó como condicional sobre el juicio del ejecutor en vez de como compuerta estructural. Toda regla de la forma "no hagas X si detectas Y" delega justo en el momento en que el juicio está comprometido, que aquí era el momento en que la guarda recién arreglada abría el camino | Se construyó una hipótesis plausible (CI corre en UTC) y se le dio peso de bloqueo antes de leer el archivo que la resolvía. La hipótesis era razonable; convertirla en recomendación de no mergear, no |
| `salvaguarda_presente` | POLITICA 0.6, SETTINGS §1.2.6, `userPreferences` — tres documentos | POLITICA 0.6, SETTINGS §1.2.2 paso 3, §1.2.3 (el acuse pide declarar si las versiones difieren) — tres | POLITICA 0.5 y §1.2.6 (fuente primaria); ninguna cubre la *construcción* de salvaguardas en encargos, que es el hueco | POLITICA 0.6, SETTINGS §1.2.6, `userPreferences` — tres |
| `patron` | `PAT-01`, variante "subconjunto medido generalizado a universo no contado". **Etiqueta pendiente de verificación:** `catalogo_patrones_errores_v4.md` (citado por SETTINGS v23 §2.2.15) no está en la knowledge base y no se leyó | `PAT-01`, variante "verificación parcial declarada como total" | Patrón nuevo propuesto: **salvaguarda de juicio donde correspondía compuerta**. No se etiqueta con un `PAT-NN` existente porque el error no está en ejecutar mal una regla sino en escribirla mal. Sujeto a verificación contra el catálogo v4 | `PAT-01`, variante "hipótesis promovida a bloqueo sin leer la fuente que la resolvía" |
| `gatillo_observable` | "Estoy escribiendo una cifra sobre un conjunto y la tomé de un documento que midió otro conjunto" | "Estoy declarando dos o más versiones verificadas y solo abrí una" | "Estoy escribiendo una regla que empieza por 'si detectas que...'" | "Estoy recomendando bloquear algo por un escenario que un archivo del repositorio confirmaría o descartaría en una lectura" |
| `intentos_previos` | 0 en esta variante; `PAT-01` acumula reincidencia en todas las sesiones registradas | 0 en esta variante | 0 | 0 |
| `costo` | Una premisa falsa en un encargo ejecutado; Claude Code la declaró y midió sobre 44, sin retrabajo | Un canal de cierre construido sobre la versión equivocada hasta que el titular pidió releer la knowledge base; el cierre se rehízo con el formato correcto (paquete de cierre) sin pérdida de contenido | 3230 llamadas HTTP no solicitadas, 329 s de corrida, 6 capturas y 312 artefactos escritos; todo restaurado y verificado por md5 (6 de 6 intermedios, 156 de 156 y 156 de 156 artefactos, 44 de 44 capturas). Las 6 capturas quedaron en cuarentena (P-80) | Un turno de verificación (que resultó valioso por otra vía: encontró que el bot estaba roto) y una recomendación revertida en el turno siguiente |

**Nota de patrón.** Los errores 1, 2 y 4 son la misma falla con tres disfraces:
tratar como verificado algo que se leyó parcialmente, por analogía o desde un
documento vecino. El gatillo común es barato: *si no abrí la fuente exacta de esta
afirmación en este turno, no la afirmo*. El error 3 es de otra clase y no debe
fundirse con ellos: la regla existía, era clara, y **el defecto estuvo en su
redacción**, no en su cumplimiento. Su tratamiento correcto es estructural (el
fusible de A73 reemplaza el juicio por una compuerta) y no disciplinario. Es la
segunda vez en dos sesiones que un error del asistente se corrige con una precondición
mecánica en vez de con énfasis, lo que confirma la lectura de PAT-01 registrada en el
v17.

## §16. Fricciones

- El límite semanal de subagentes se agotó a mitad del PR #9, de modo que el panel
  adversarial de esa reparación lo condujo Claude Code sobre su propio trabajo. Está
  declarado en el log: es una diferencia real de independencia, y aun así ese pase
  encontró el hueco de las tres causas de `NA`.
- `gh api` no acepta `-R`; el repositorio va en la ruta del endpoint. Costó un
  intento fallido. Registrado en las instrucciones del §12.
- Un backtick en un mensaje de commit fue interpretado por `zsh` como sustitución de
  comando y se comió una palabra. Se corrigió con `--amend` desde archivo antes del
  push.
- El paquete de cierre se redacto con delimitadores `# BEGIN`/`# END` en vez de
  los `<<<...>>>` que exige el §2 de `cierre_sesion_autonomo_cc_v4.md`: el asistente
  nunca leyo ese instrumento, que vive en el repositorio y no en la knowledge base,
  y dedujo el formato. Sin ambiguedad de destino, asi que el cierre no se detuvo.
  Para la proxima sesion: pedir el instrumento antes de redactar el paquete.
