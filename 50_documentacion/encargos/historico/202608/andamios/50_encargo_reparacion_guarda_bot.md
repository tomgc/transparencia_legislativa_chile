# Encargo autónomo — reparación de la guarda circular del bot semanal

> **Destino:** `50_documentacion/andamios/50_encargo_reparacion_guarda_bot.md`
> **Modo:** Ultracode, dirigido por invariantes y criterios, no por fases prescritas.
> **Urgencia declarada:** el cron corre los lunes 11:00 UTC; el próximo es el
> **2026-08-10**. Es el único camino del proyecto que se ejecuta sin nadie mirando.
> **Base:** rama nueva desde `main` **después** de mergear el PR #8, no antes: ambos
> tocan `00_run_all.R` y `10_utils/10_utils.R`, y resolver eso como conflicto de PR
> obligaría a hacerlo por hunk sobre archivos de producción (A55).

---

## §0. Separación de lo respaldado y lo hipotético

El cuerpo de este encargo **no puede afirmar nada que no esté en esta tabla**. Quien
lo redacta **no ha leído `00_run_all.R`, `10_utils.R` ni el workflow en esta sesión**:
todo número de línea viene de tus propios reportes y se re-verifica en compuerta.

### Respaldado por ejecución de la sesión 18

| Afirmación | Fuente |
|---|---|
| Con los 6 intermedios ausentes y `CORTE_FECHA` inyectado como la línea 75 del workflow, `run_all()` se detiene en `00_run_all.R:84` con **0 de 6** pasos ejecutados y **0** llamadas HTTP | corrida de verificación del bot, sesión 18 |
| El mismo desenlace con `camara.refrescar = TRUE`: el `stop()` precede a todo intento de descarga | misma corrida |
| El mensaje del `stop()` enumera las **6** capturas crudas del corte nuevo que faltan, que son las que esa misma corrida iba a crear | misma corrida, salida literal |
| El workflow calcula el corte con `date +%Y-%m-%d` en el runner (línea 66) y lo inyecta con `sed` (línea 75), **antes** de correr el pipeline (línea 81) | lectura del workflow, sesión 18 |
| No hay `TZ` declarada en ningún `.yml` ni `.R`, ni `.Rprofile` ni `.Renviron` versionados | `grep -rn` y `ls`, sesión 18 |
| `refresh-semanal.yml` es el único workflow; commitea `20_insumos/camara` en su línea 115 | misma lectura |
| Los intermedios están gitignorados (`.gitignore:42`), así que el runner hace checkout sin ninguno | log del acto (b), C7 |
| El defecto entró en `b67a5c3`, mergeado por el PR #6 (`f1584b8`) | arqueología de commits, sesión 18 |
| `capturas_crudas_de_paso()` construye rutas con `ruta_cache()` → `corte_para_clave()`, que lee la global `CORTE_FECHA` y no el argumento `corte` de la función | tu reporte, sesión 18 |
| 44 capturas en `20_insumos/camara/`, 8 del corte vigente | log del acto (b), G3 |

### Hipótesis a verificar en compuerta (nunca a citar)

| Hipótesis | Compuerta |
|---|---|
| La guarda vive en `regenerar_intermedios_si_desalineados()`, invocada desde `00_run_all.R:84` | G1 |
| `corte_declarado_por()` devuelve `NA` cuando el intermedio no existe | G1 |
| El `stop()` es una sola rama y no varias con condiciones distintas | G1 |
| El workflow commitea también `40_salidas/` o `docs/` además de las capturas | G3 |

---

## §1. El defecto, y qué se repara

La guarda de P-65 exige que las capturas crudas del corte vigente **ya estén en
disco** para permitir que la corrida siga. En el runner eso nunca se cumple en la
primera corrida de un corte nuevo: checkout fresco, cero intermedios, cero capturas
de ese corte, y las capturas que la guarda exige son precisamente las que la corrida
iba a descargar. La guarda es circular en el único camino capaz de romper el ciclo.

Hay que separar tres estados que hoy colapsan en uno:

- **(1) Primera corrida.** No existe **ningún** intermedio. No hay desalineamiento
  que detectar: no hay nada con qué compararse. Debe seguir.
- **(2) Desalineado con capturas presentes.** El caso para el que P-65 se construyó:
  regenerar sin red. Debe seguir comportándose exactamente igual.
- **(3) Desalineado con capturas ausentes.** Aquí el `stop()` es correcto **solo si
  la corrida no está autorizada a descargar**. Si sí lo está, faltar las capturas es
  el estado inicial esperado y no un error: el pipeline las creará, y la guarda de
  P-74 se encargará de que la fecha de descarga honre el corte declarado.

**Aflojar una guarda es más peligroso que apretarla**, y por eso este encargo pide
más evidencia de lo que su tamaño sugiere: hay que demostrar que (2) sigue intacto,
no solo que (1) y (3) pasan.

**Se repara además**, en el mismo PR, la resolución de corte de
`capturas_crudas_de_paso()`: hoy evalúa desalineamiento contra el argumento `corte` y
existencia de capturas contra la global `CORTE_FECHA`. Mientras coincidan nadie lo
nota; cuando no coincidan, compara dos cortes distintos sin ruido.

**Fuera de alcance, explícitamente:** no se toca el contrato temporal de P-74, no se
toca el borde inferior, no se cambia lo que el workflow commitea, y no se ejecuta una
extracción real contra la API.

---

## §2. Invariantes (violarlos invalida la corrida entera)

1. **No se tocan** `sellar()`, `leer_sellado()` ni `validar_corte()`, ni la guarda de
   P-74 introducida por el PR #8.
2. **`20_insumos/camara/` es crudo inmutable.** Ninguna de las 44 capturas se
   reescribe, renombra ni borra. Verificado por md5 al abrir y al cerrar.
3. **Cero red.** `camara.refrescar = FALSE` salvo en las pruebas que exigen
   explícitamente el caso contrario, y aun ahí **cero llamadas HTTP reales**: el
   contador se instala y se reporta. Si una prueba fuera a descargar, no se corre.
4. **R exclusivamente**, en todo contexto. Sin `jq`, `awk`, `python`, ni `grep`/`sed`
   sobre artefactos de datos. Sin regex en `Rscript -e`.
5. **Fallo ruidoso.** El `stop()` que se conserve debe seguir siendo `stop()`, con
   mensaje accionable. Ninguna rama nueva puede degradar un error a `warning` ni a
   silencio. Aflojar la guarda significa **acotar cuándo aplica**, no bajarle el tono.
6. **Los intermedios que se muevan para probar se restauran**, y su md5 se verifica
   contra la línea base. Mover con `mv`, nunca `rm`.
7. **Trabajo en rama y PR.** Rama `fix/guarda-bot-primera-corrida` desde `main` ya
   con el PR #8 mergeado. PR abierto, **sin merge**. `git` con `-C <ruta absoluta>`,
   `gh` con la ruta completa del endpoint (no acepta `-R`), `git add` con ruta
   acotada, nunca `.` ni `-A`.

---

## §3. Compuertas de precondición

Cada una se responde con **archivo, línea y salida literal**. Una compuerta
respondida citando este encargo o un reporte anterior es una compuerta fallida.

- **G1. Anatomía de la guarda.** Rango de líneas de la función que contiene el
  `stop()`, su firma, y **cada rama condicional** que puede terminar en detención,
  enumeradas. Reporta qué devuelve `corte_declarado_por()` cuando el intermedio no
  existe, medido y no supuesto.
- **G2. Resolución de corte.** Muestra, con línea, dónde `capturas_crudas_de_paso()`
  usa el argumento `corte` y dónde termina usando la global vía `ruta_cache()`.
  Construye un caso donde ambos difieran y reporta qué compara hoy.
- **G3. Lo que el workflow commitea.** Enumera las rutas del `git add` de la línea
  115 y de cualquier otro paso que escriba en el repo. Si commitea `40_salidas/` o
  `docs/`, dilo: cambia qué se considera "estado limpio" tras una corrida del bot.
- **G4. Línea base de comportamiento, antes de tocar nada.** Con la condición del
  runner reproducida (6 intermedios movidos fuera, corte inyectado, sin red),
  registra la salida literal actual. Es contra esto que se compara después.
- **G5. Línea base de integridad.** md5 de las 44 capturas, de los 6 intermedios y de
  los 156 artefactos de `40_salidas/json/` y los 156 de `docs/data/`, con su
  denominador.

---

## §4. Criterios de éxito (contrastables, no silenciosamente aprobables)

| # | Criterio | Cómo falla |
|---|---|---|
| C1 | Las cinco compuertas respondidas con lectura directa, con archivo, línea y salida | Alguna citó un reporte previo |
| C2 | **Estado (1):** con los 6 intermedios ausentes y el corte inyectado, `run_all()` **supera** la línea de la guarda y alcanza el paso 32 | No lo alcanza, o lo alcanza por haber borrado la guarda entera |
| C3 | En ese mismo escenario, la detención que ocurre después es atribuible a la **ausencia de red**, citando su mensaje literal, y no a la guarda de P-65 | El mensaje no se cita, o proviene de la misma función de G1 |
| C4 | **Estado (2) intacto:** con los 6 intermedios presentes pero desalineados y las capturas del corte presentes, la regeneración sin red sigue funcionando y produce los 6 intermedios sellados al corte | El caso no se probó, que es el modo de falla más caro de este encargo |
| C5 | **Estado (3) conservado:** desalineado, capturas ausentes y corrida **no** autorizada a descargar → sigue habiendo `stop()`, con mensaje accionable | Se volvió permisivo en el caso en que el `stop()` sí era correcto |
| C6 | La distinción entre (1) y (3) se decide por una condición **medida en disco**, no por una heurística sobre el nombre del entorno ni por detectar si se corre en CI | Se agregó algo tipo `if (Sys.getenv("CI") != "")` |
| C7 | `capturas_crudas_de_paso()` resuelve corte de una sola forma, y el caso construido en G2 lo demuestra | Se cambió sin una prueba que distinga el antes del después |
| C8 | 44 de 44 capturas con md5 idéntico a G5, y 6 de 6 intermedios restaurados con md5 idéntico | Cualquiera cambió |
| C9 | Neutralidad del artefacto público: 156 de 156 idénticos en ambos destinos, excluido `metadatos.generado`, y 0 claves nuevas | Cambió algo: este encargo no debía tocar el dato |
| C10 | Cero llamadas HTTP contadas **en el mismo proceso** que corrió cada escenario | El contador se instaló en otro proceso |
| C11 | `sellar()`, `leer_sellado()`, `validar_corte()` y la guarda de P-74 idénticos a `HEAD`, por diff con `-C <ruta absoluta>` y código de salida citado | Hay diferencia, aunque sea un comentario |
| C12 | PR abierto y **sin merge**, con el conteo de archivos por `gh api` paginado sobre `/pulls/<n>/files` contra `changed_files`, con denominador | Se mergeó, o se usó `gh pr diff --name-only` (HTTP 406) |

---

## §5. Panel adversarial (cuatro agentes, antes de cerrar)

1. **El que duda del denominador.** Cada cifra sin denominador en su misma línea
   vuelve.
2. **El que busca el falso verde.** Por cada CUMPLE, construye el escenario en que
   pasaría estando el sistema roto. Atención a C2 y C4: son el par que hay que probar
   junto, porque satisfacer uno rompiendo el otro es el desenlace natural de este
   cambio.
3. **El que ataca la guarda aflojada.** Su trabajo es encontrar el estado en que el
   pipeline ahora **sobrescribe o regenera algo que no debía**: un intermedio válido
   descartado, una captura del corte anterior tratada como del vigente, una corrida
   local que ahora descarga sin que el operador lo pidiera. Cada camino se cierra o
   se declara.
4. **El que revisa el §0.** Cada afirmación del reporte que venga de este encargo o
   de un reporte anterior en vez de una lectura de esta corrida se degrada a
   hipótesis o se mide.

---

## §6. Entregable

Un log en `50_documentacion/andamios/logs/AAAAMMDD_reparacion_guarda_bot_log.md` con:
las cinco compuertas, la descripción de lo cambiado con archivo y línea, los doce
criterios con CUMPLE o NO CUMPLE y su cifra, el resultado de los cuatro agentes, el
número del PR y tres a cinco líneas de lo que quedó indeterminado.

Incluye una línea explícita sobre lo que **este encargo no puede probar**: que el
workflow real funcione de punta a punta, porque eso exige una corrida contra la API
en el runner. Di qué evidencia falta y qué la daría.
