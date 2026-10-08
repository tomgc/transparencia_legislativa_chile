# Encargo — P-76 y P-77: consumo del escape y rastro de arranque

> **Versión 2.** Reemplaza a la v1. Cambios: las seis compuertas del §3 ya se
> corrieron y sus resultados quedan registrados; H3 y H4 resultaron **falsas**;
> el §4.2 se reescribe completo (el diseño A de la v1 es inimplementable y se
> reemplaza por el diseño D); el §5 ajusta C4, C5 y C6 y suma C13.
>
> **Destino:** `50_documentacion/andamios/50_encargo_p76_p77_escape_y_rastro.md`
> **Sesión:** 19. **Ejecutor:** Claude Code, modo autónomo.
> **Alcance:** un solo PR sobre `10_utils/10_utils.R` y `.gitignore`. Rama
> `fix/p76-p77-guarda-arranque`. Sin push a `main`. **`00_run_all.R` no se toca.**

---

## §0. Contrato positivo

### 0.1 Afirmaciones respaldadas

Fuentes: `10_utils/10_utils.R` y `50_documentacion/andamios/50_verificar_guarda_bot.R`,
leídos completos al redactar la v1; más las seis compuertas del §3, corridas por
Claude Code y registradas en §3.0. **Los números de línea de esta tabla ya
fueron reverificados contra `main` por G1**, con `git diff origin/main` vacío
sobre los tres archivos.

| # | Afirmación | Evidencia |
|---|---|---|
| A1 | El escape del contrato temporal se consume al usarse | `consumir_escape_captura()` en `10_utils.R:269` |
| A2 | Ese consumo se invoca en dos sitios, ambos dentro de funciones protegidas | `10_utils.R:292` (`guarda_captura_en_corte`) y `10_utils.R:328` (`verificar_cierre_de_descarga`) |
| A3 | El escape de la guarda de arranque **no** se consume | `descarga_inicial_autorizada()` en `10_utils.R:471`; invocada en `10_utils.R:579`; la rama devuelve en `10_utils.R:587` sin apagar la opción |
| A4 | Ambas opciones tienen default `FALSE` y no se leen del entorno | `OPCION_ESCAPE_CAPTURA` en `10_utils.R:254`, `OPCION_DESCARGA_INICIAL` en `10_utils.R:469` |
| A5 | La rama de primera corrida se decide solo por conteo de archivos | `rutas_intermedios` en `10_utils.R:538-539`, `n_en_disco` en `540`, `if (n_en_disco == 0)` en `541`, `return(invisible(FALSE))` en `549` (corregido por G1; la v1 citaba el rango 538-550) |
| A6 | Esa condición no distingue "nunca hubo" de "había y se borraron" | Ambos estados producen `n_en_disco == 0` y salen por la misma línea 549 |
| A7 | Con intermedios desalineados y capturas faltantes, la guarda ya se detiene con mensaje accionable | `10_utils.R:589-605`; escape autorizado en `579-588` |
| A8 | Con intermedios desalineados y capturas presentes, regenera sin red | `10_utils.R:625-649`, con `options(camara.refrescar = FALSE)` en `627` |
| A9 | Existe un arnés reutilizable con contador de red y comparación contra `HEAD` | `50_verificar_guarda_bot.R`, fases `compuertas` y `criterios`; `PROTEGIDAS` en su línea 234, 9 funciones |
| A10 | El arnés compara cuerpos contra la copia de `HEAD` en `$P74_TMP/utils_head_main.R` | `50_verificar_guarda_bot.R:217-219` |
| A11 | El mensaje de detención de la guarda instruye correr los extractores **sueltos** | `10_utils.R:595-603`: `source("<ruta del paso>")`, uno por línea |
| A12 | `escribir_atomico()` no crea el directorio de destino | `10_utils.R:51-57`: escribe el `.tmp` y hace `fs::file_move()`; el único `fs::dir_create()` de la ruta de caché está en `10_utils.R:432`, dentro de `con_cache()` |

**A11 y A12 juntas son la razón por la que `.gitkeep` no se puede destrackear:**
la ruta de recuperación que la propia guarda imprime corre extractores sueltos,
y en un checkout fresco sin `.gitkeep` esos extractores escribirían en un
directorio inexistente.

### 0.2 Hipótesis, ya resueltas por las compuertas

| # | Hipótesis | Resultado |
|---|---|---|
| H1 | `10_utils.R` en `main` idéntico a la copia leída al redactar | **Confirmada** (G1) |
| H2 | `ruta_salidas()` y `ruta_insumos()` viven en `10_utils/10_configuracion.R` | **Confirmada** (G2): líneas 12 y 11, variádicas, así que `ruta_salidas("intermedios")` devuelve el directorio |
| H3 | Un checkout fresco **no** crea `40_salidas/intermedios/` | **FALSA** (G3): `40_salidas/intermedios/.gitkeep` está trackeado; `.gitignore:42` ignora `40_salidas/intermedios/*.rds`, no el directorio |
| H4 | Los extractores dejan el directorio creado tras una corrida exitosa | **FALSA** (G4): cero `dir.create`/`dir_create` cubre esa ruta; hoy el directorio existe solo por `.gitkeep` |
| H5 | El working tree local está en un corte anterior al de `main` | **Matizada** (G0): en git no hay desfase (0 ahead / 0 behind); el desfase es de datos (6 de 6 intermedios declaran `2026-08-03` y `CORTE_FECHA` es `2026-08-12`) |

---

## §1. Objetivo

Cerrar las dos deudas declaradas y no cerradas del PR #9, que viven en la misma
función:

- **P-76:** `camara.permitir_descarga_inicial` queda encendida después de
  usarse. Como `run_all()` corre los seis pasos con `source()` en la misma
  sesión, encenderla para un caso la deja encendida para todo lo que sigue. Es
  la asimetría exacta que el PR #8 corrigió para el otro escape.
- **P-77:** borrar los intermedios sin tener las capturas del corte entra por la
  rama de primera corrida y termina descargando el año completo, en vez de
  detenerse.

**Fuera de alcance:** P-79, P-81, P-59, P-60, y cualquier cambio a las nueve
funciones protegidas o a `00_run_all.R`.

---

## §2. Invariantes

Compuertas estructurales, no juicios del ejecutor (A72: toda regla que empieza
por "si detectas que…" delega en el juicio justo cuando está comprometido).

1. **Cero red.** Antes de `source("00_run_all.R")` en cualquier prueba se
   instala el fusible `quit(save = "no", status = 99L)` en la primera llamada de
   red (`50_fusible_red.R`, patrón A73), **en el proceso que corre el pipeline**.
   Un `stop()` no sirve: el paso 36 lo atrapa y lo degrada a `estado = error_red`.
   Una prueba que corra el pipeline sin fusible instalado incumple el encargo
   aunque no descargue nada.
2. **`20_insumos/camara/` inmutable.** md5 de todos sus `.rds` al abrir y al
   cerrar, comparados archivo por archivo. Ninguna captura se escribe, renombra
   ni borra.
3. **Las nueve funciones de `PROTEGIDAS` quedan idénticas a `HEAD`**, byte a
   byte, con el mecanismo de `50_verificar_guarda_bot.R:220-247`. Incluye
   `guarda_captura_en_corte` y `verificar_cierre_de_descarga`: el refactor de
   P-76 **no puede cambiar sus cuerpos**, así que el helper genérico se
   introduce por debajo de `consumir_escape_captura()`, conservando su nombre y
   su firma.
4. **El texto del log del escape de captura no cambia.** Se compara la línea
   emitida contra la de `HEAD`, literal.
5. **Ningún intermedio se versiona** (D24) y ningún artefacto de
   `40_salidas/json/` ni `docs/data/` entra al PR.
6. **`40_salidas/intermedios/.gitkeep` sigue trackeado.** Destrackearlo rompe la
   ruta de recuperación de A11.
7. **Todo intermedio que se mueva para construir un escenario se restaura** con
   `file.rename()` y se verifica por md5 antes de terminar la fase.
8. **R es el único lenguaje.** Sin `jq`, `awk`, `python`, ni `grep`/`sed` sobre
   artefactos de datos; sin regex en `Rscript -e`. `git` siempre con
   `-C <ruta absoluta>`; `gh` siempre con `-R tomgc/transparencia_legislativa_chile`,
   **salvo `gh api`**, donde el repositorio va en la ruta del endpoint;
   `git add` siempre con ruta acotada.
9. **Todo conteo se emite con su denominador contado en la misma corrida.**

---

## §3. Compuertas

### 3.0 Resultados ya obtenidos (no se repiten)

| # | Resultado |
|---|---|
| G0 | `origin/main` = `7c18143`, `HEAD` local el mismo, 0 ahead / 0 behind, working tree limpio salvo el propio encargo sin trackear. Nada que sincronizar |
| G1 | `regenerar_intermedios_si_desalineados()` en `10_utils.R:521-650` (130 líneas). Rama de arranque: 538-539, 540, 541, 549. `descarga_inicial_autorizada()` def. 471, invocada 579, retorno sin apagar 587. `consumir_escape_captura()` def. 269, invocada 292 y 328. `git diff origin/main` vacío sobre los tres archivos |
| G2 | `ruta_insumos` en `10_utils/10_configuracion.R:11`, `ruta_salidas` en `:12`; ambas variádicas |
| G3 | `.gitkeep` trackeado en `40_salidas/intermedios/` (1 de 157 archivos bajo `40_salidas/`, blob `e69de29` en `origin/main`); `.gitignore:42` ignora `40_salidas/intermedios/*.rds` |
| G4 | Cero `dir.create`/`dir_create` cubre `40_salidas/intermedios/`. Guarda invocada en `00_run_all.R:84`, tras el bucle de validación de rutas (73) y antes del de ejecución (98) |
| G5 | Línea base en `$P74_TMP/guarda_linea_base.rds`: 50 capturas (29 md5 distintos), 6 intermedios, 156 `40_salidas/json/`, 156 `docs/data/` |
| G6 | `CORTE_FECHA` = `2026-08-12`. 6 de 6 intermedios existen, 0 de 6 declaran el corte vigente. 6 de 6 capturas exigidas del corte presentes; 6 de 50 `.rds` con prefijo `20260812`. Directorio de intermedios: 7 entradas, incluida `.gitkeep` |

### 3.1 Compuerta nueva, antes de escribir código

**G7 — Qué commitea el bot bajo `40_salidas/`.** Leer el `git add` de
`.github/workflows/refresh-semanal.yml` y enumerar sus rutas, contadas. La
pregunta exacta: **¿alguna de esas rutas puede arrastrar el archivo de rastro
que introduce el §4.2?** Si la respuesta es sí, detenerse y reportar: el rastro
jamás debe llegar a `main`. Es el mismo mecanismo del G3 del PR #9
(`50_verificar_guarda_bot.R:164-177`); reutilizarlo, no reescribirlo.

---

## §4. Implementación

### 4.1 P-76 — El escape de arranque se consume al usarse

Extraer el consumo a un helper genérico y dejar que las dos opciones lo usen.
El patrón ya existe en el proyecto: se replica, no se inventa otro.

- Nuevo `consumir_escape(opcion, nota, origen)`: apaga la opción con
  `options(stats::setNames(list(FALSE), opcion))` y registra en `WARN` el
  nombre de la opción y la `nota` recibida.
- `consumir_escape_captura(origen = "contrato")` pasa a ser un envoltorio que lo
  llama con la nota que hoy emite, **literal**. Nombre, firma y texto del log no
  cambian (invariantes 3 y 4).
- Nuevo `consumir_descarga_inicial(origen = "guarda_intermedios")`, análogo, con
  la nota propia de este escape: que es de un solo uso y que la corrida
  siguiente vuelve a detenerse.
- La rama autorizada de la guarda lo invoca **antes** de devolver, en el mismo
  sitio donde hoy registra la autorización (`10_utils.R:579-588`).

### 4.2 P-77 — Diseño D: rastro propio, escrito por la guarda

G3 mató el diseño A de la v1: `.gitkeep` garantiza que el directorio existe en
**todo** checkout, incluido el del runner, así que `dir.exists()` no discrimina
nada y la rama de arranque nunca se tomaría. Eso reintroduce exactamente la
circularidad de P-65.

El rastro pasa a ser un archivo propio, **dentro** del directorio de
intermedios y gitignorado:

- **Constante nombrada** para el nombre del rastro (junto a
  `INTERMEDIOS_PIPELINE`, `10_utils.R:459`), no una cadena literal repartida por
  el archivo.
- **Discriminante:** la rama de arranque exige `n_en_disco == 0` **y** que el
  rastro no exista. Se mide con `file.exists()`, nunca con el sello ni con
  ningún proxy (A74, D32).
- **Escritura:** al tomar la rama de arranque, la guarda escribe el rastro con
  el corte vigente y el instante, antes de devolver. El rastro no depende de qué
  haga cada extractor, que es el punto del arreglo (G4 midió que ninguno crea ni
  toca ese directorio).
- **Estado "borrados":** rastro presente y 0 intermedios ya **no** es arranque.
  Cae en la lógica normal de desalineados, donde el comportamiento correcto ya
  existe y no hay que escribirlo: capturas del corte presentes → regenera sin
  red (`10_utils.R:625-649`); capturas ausentes → `stop()` accionable
  (`589-605`) o el escape ahora consumible. El mensaje de ese `stop()` suma una
  línea que nombra este caso y lo distingue del arranque.
- **`.gitignore`** suma una línea para el rastro, junto a la de `:42`. El
  invariante 6 sigue en pie: `.gitkeep` no se toca.

**Limitaciones declaradas, que van al traspaso.** (1) `rm -rf` del directorio
completo vuelve a leerse como arranque; es el mismo estado que un clon fresco y
además rompe `.gitkeep`, así que ya era un caso degradado. (2) Una primera
corrida que muera después de escribir el rastro y antes de escribir intermedios
exigirá la opción declarada en el intento siguiente. Ninguna de las dos
descarga en silencio, y ese es el criterio.

**Descartadas, con su evidencia:**

- *Diseño B (ledger escrito al término de `run_all()`).* Funciona, pero exige
  tocar `00_run_all.R`; el rastro escrito por la guarda logra lo mismo sin
  ampliar la superficie.
- *Diseño C (destrackear `.gitkeep` para volver H3 verdadera).* Rompe la ruta
  de recuperación que la propia guarda imprime (A11 más A12).
- *Detección de entorno de CI* (`Sys.getenv("CI")` o variantes). Descartada por
  C6 del encargo del PR #9 y por D32: el pipeline no se comporta distinto según
  dónde corre.

---

## §5. Criterios de éxito

Todos verificables, todos con denominador contado en la corrida, todos con el
fusible instalado. Se extiende `50_verificar_guarda_bot.R` con una fase nueva
(`p76p77`), no un arnés paralelo.

| # | Criterio | Cómo se prueba |
|---|---|---|
| C1 | El escape de arranque se apaga al consumirse | Encender la opción, invocar la rama autorizada, comprobar que `descarga_inicial_autorizada()` devuelve `FALSE` después. Análogo a C4b del PR #8 |
| C2 | La segunda invocación en la misma sesión se detiene | Con la opción encendida una sola vez, dos pasadas por el estado que la requiere: la primera pasa, la segunda hace `stop()` |
| C3 | El escape de captura no cambió de comportamiento | Sigue siendo de un solo uso y su línea de log es idéntica a la de `HEAD`, comparada literal |
| C4 | Arranque legítimo sigue pasando (no se reintroduce P-65) | Escenario tipo runner: `.gitkeep` presente, rastro ausente, 0 intermedios. La guarda no se detiene, escribe el rastro, y la corrida muere en el fusible, no en la guarda |
| C5 | Intermedios borrados con capturas del corte presentes: regenera sin red | Rastro presente, 0 intermedios: 6 de 6 `cache hit`, `exit 0`, fusible sin disparar. Es el caso original de P-65 y **debe seguir funcionando**: probar la guarda en el sentido en que **no** debe dispararse, no solo en el que sí |
| C6 | Intermedios borrados sin capturas del corte: se detiene | Rastro presente, 0 intermedios, capturas del corte movidas fuera: `stop()` con mensaje que nombra el caso, lo distingue del arranque y da el comando exacto. Cero llamadas de red |
| C7 | Ese mismo caso, con la autorización declarada, pasa | Y deja la opción apagada al salir (enlaza con C1) |
| C8 | Las 9 funciones protegidas idénticas a `HEAD` | Mecanismo de `50_verificar_guarda_bot.R:220-247`, con la copia de `HEAD` en `$P74_TMP` |
| C9 | Cero llamadas HTTP en todos los escenarios | Fusible `quit(99)`, no contador: el contador certifica el proceso donde vive (A76) |
| C10 | `20_insumos/camara/` intacto | md5 de apertura contra md5 de cierre, archivo por archivo, con denominador. Las capturas movidas en C6 se restauran y se verifican |
| C11 | Intermedios movidos, restaurados | md5 de cada uno contra la línea base de G5 |
| C12 | El PR no trae intermedios, ni el rastro, ni `40_salidas/json/`, ni `docs/data/` | `gh api` paginado sobre `/repos/tomgc/transparencia_legislativa_chile/pulls/<n>/files`. **No usar `gh pr diff --name-only`:** HTTP 406 en PRs grandes |
| C13 | `40_salidas/intermedios/.gitkeep` sigue trackeado y sin cambios | `git ls-files` más comparación del blob contra `origin/main` |

Un criterio que no se pueda medir se declara **NO MEDIDO**; no se degrada a
CUMPLE con una medición vecina.

---

## §6. Panel adversarial

Antes de abrir el PR, un pase adversarial sobre el propio trabajo. Cada
pregunta se responde con evidencia de una corrida, no con lectura de código:

1. ¿Existe algún estado en que el arreglo de P-77 detenga al runner? Si el único
   argumento es "en el runner no pasa", eso es una hipótesis sobre el entorno, y
   la circularidad de P-65 era invisible exactamente así.
2. ¿El rastro sobrevive a las operaciones que un operador hace de verdad?
   Enumerar al menos cuatro (`rm *.rds` dentro del directorio, `rm -rf` del
   directorio, `git clean -xdf`, y un checkout fresco) y decir qué hace el
   pipeline en cada una.
3. ¿El rastro puede llegar a `main` por alguna vía (el `git add` del bot, un
   `git add` acotado del operador, un `git clean` que no lo alcance)? G7
   responde la primera; las otras dos se responden aquí.
4. ¿El helper genérico de P-76 cambió alguna línea dentro de una función
   protegida? Verificar por comparación, no por recuerdo de lo editado.
5. ¿Algún criterio se declaró CUMPLE con una medición que certifica otro proceso
   u otro conjunto? (A76 y el error 1 del §15 del traspaso v18.)
6. ¿Algún escenario se probó solo en el sentido en que la guarda **sí** debe
   dispararse?
7. ¿Quedó alguna opción encendida al terminar una fase, que contamine la
   siguiente?

Los hallazgos del panel se registran aunque no cambien el resultado.

---

## §7. Entrega

1. Rama `fix/p76-p77-guarda-arranque` desde `main`. **Nunca sobre `main`.**
2. Log en `50_documentacion/andamios/logs/AAAAMMDD_p76_p77_log.md` con:
   resultado de G7, tabla de los 13 criterios con su medición, hallazgos del
   panel, y las dos limitaciones declaradas del §4.2 redactadas para el
   traspaso.
3. PR abierto con `gh -R tomgc/transparencia_legislativa_chile`, cuerpo que cite
   los criterios medidos. **Sin merge:** el merge es del titular.
4. Reportar en el mensaje de cierre, en una línea cada uno: hash del commit,
   número del PR, y cualquier criterio NO MEDIDO.
