# Encargo autónomo — P-93: guarda de sincronía del registro de pasos

> **Destino:** `50_documentacion/andamios/50_encargo_s23_p93_guarda_registro_pasos.md`
> **Redactor:** asistente de análisis (Claude conversacional), sesión 23.
> **Ejecutor:** Claude Code, modo autónomo.
> **Antecede:** `50_encargo_s23_panel_p86_diag_p91.md` (mismo día, ya ejecutado).

---

## §0. Contrato positivo: qué está respaldado y qué es hipótesis

### 0.1 Respaldado (fuente leída o ejecutada en la sesión 23)

| # | Premisa | Fuente |
|---|---|---|
| R1 | El registro de un paso vive en tres estructuras y nada obliga a sincronizarlas: `INTERMEDIOS_PIPELINE` y las ramas de `capturas_crudas_de_paso()` en `10_utils/10_utils.R`, y `PASOS_EXTRACCION` en `00_run_all.R`. P-66 agregó el paso 37 tocando sólo `PASOS` | traspaso v22 §6 bug 1 y §4.1, leído en la sesión |
| R2 | `regenerar_intermedios_si_desalineados(PASOS_EXTRACCION, ROOT)` se invoca en la entrada de `run_all()`, después de validar rutas y antes del bucle de pasos | `00_run_all.R:91-98` y `:112`, leído en la sesión |
| R3 | `capturas_crudas_de_paso()` hace `stop()` ante un id que no conoce | `00_run_all.R:54-57` (comentario de la deuda P-66), leído en la sesión |
| R4 | El mensaje del `stop()` de la guarda nombra el directorio `20_insumos/camara/` como literal fijo, también cuando la captura ausente vive en `senado/`. Literal en `10_utils/10_utils.R:750` en `main` y `:762` en `fix/p86-runner-paso37` | panel adversarial de F1 del encargo anterior: los dos agentes lo hallaron por separado y Claude Code lo verificó en el fuente, reportado en esta sesión |
| R5 | El defecto de R4 es preexistente y PR #16 no lo introduce | ídem R4 |
| R6 | En producción, la guarda contó `0 de 6` mientras el paso 39 validó `7 intermedios`, en el run verde del 2026-08-17 | log de CI leído en F2.3 del encargo anterior, reportado en esta sesión |
| R7 | Las cadenas "regenera los pasos 32-36" siguen vivas en `leer_sellado()` y `validar_corte()`, funciones marcadas 🔒 | traspaso v22 §11.2, leído en la sesión |

### 0.2 Hipótesis (se resuelven en F0, antes de escribir código)

| # | Hipótesis | Comando que la resuelve |
|---|---|---|
| H1 | PR #16, #17 y #18 están mergeados y `main == origin/main` | F0.1 |
| H2 | Con #16 mergeado, la discrepancia de R6 desaparece: la guarda cuenta 7, no 6 | F0.3 |
| H3 | `PASOS_EXTRACCION` en `main` ya incluye el 37 (`32:37` o equivalente), y no `32:36` | F0.2 |
| H4 | El literal de R4 sigue en `main` tras el merge, en una línea que no pertenece a `sellar()`, `leer_sellado()` ni `validar_corte()` | F0.4 |

**Si H1 es falsa, detente y reporta.** El encargo construye sobre la zona que #16 modifica; trabajar con el PR abierto es construir sobre una divergencia conocida.

---

## §1. Encabezado de contrato

**Modo:** autónomo, secuencial, todo en este turno.

**Regla de detención (los únicos tres casos):** (a) un invariante 🔒 te obligaría a violarlo; (b) un dato real contradice una premisa de §0.1; (c) un gate marcado como decisión del titular. Reporta y espera; no improvises metodología.

**ENTORNO:** filesystem local vía Claude Code. Raíz: `/Users/tomgc/Projects/transparencia_legislativa_chile`.

**INSUMOS:** todo vive en el repo. Ningún archivo llega "aparte".

**POSICIÓN:** ningún comando asume `cd`. `git` siempre con `-C /Users/tomgc/Projects/transparencia_legislativa_chile`; `gh` con `-R tomgc/transparencia_legislativa_chile` salvo `gh api`. Rutas de R absolutas o vía `here::here()`.

---

## §2. Contexto mínimo suficiente

Un paso del pipeline está registrado en cuatro lugares: `PASOS` (la lista maestra, `00_run_all.R`), `PASOS_EXTRACCION` (derivada por filtro, mismo archivo), `INTERMEDIOS_PIPELINE` (`10_utils/10_utils.R`) y las ramas de `capturas_crudas_de_paso()` (mismo archivo). P-66 agregó el paso 37 tocando sólo la primera. El síntoma tardó dos sesiones en aparecer y costó P-86: el mensaje de recuperación mandaba a regenerar los pasos 32-36 para un intermedio que produce el 37.

P-93 no arregla ese caso (ya lo hizo PR #16): **impide que el próximo paso nuevo lo repita**, con una guarda que falla ruidosamente ante un paso huérfano.

El defecto de R4 entra en el mismo encargo porque vive en el mismo mensaje de error y pertenece a la misma clase: un dato que debería derivarse está escrito a mano.

---

## §3. Invariantes (🔒)

- 🔒 `sellar()`, `leer_sellado()` y `validar_corte()` **no se tocan**, ni siquiera para corregir las cadenas de R7. Eso queda como pendiente declarado, no como aprovechamiento del turno.
- 🔒 La lógica de detección y de regeneración de `regenerar_intermedios_si_desalineados()` no cambia. En F2 se toca **sólo** la construcción del mensaje, y hay que probar que el comportamiento (qué detecta, qué regenera, cuándo se detiene) es idéntico antes y después.
- 🔒 La nueva guarda es **estructural y estática**: lee objetos de R en memoria. No toca el filesystem, no lee sellos, no hace red, no depende del corte. Si tu diseño la obliga a leer un archivo, el diseño está mal: detente y reporta.
- 🔒 `10_utils/10_utils.R` no adquiere dependencias de paquetes.
- 🔒 R es el único lenguaje, en todo contexto. `bash` sólo para `git`, `gh` y `Rscript`.
- 🔒 `git add` siempre con ruta acotada; nunca `git add .` ni `git add -A`.
- 🔒 No mergees ningún PR ni hagas push a `main`. El PR se abre; el merge es del titular.
- 🔒 Ninguna cifra se reporta sin recontarla programáticamente en el mismo bloque que la reporta.
- 🔒 Los intermedios no se versionan (D24).

---

## §4. La decisión de metodología (es del redactor, no tuya)

La guarda necesita saber **qué pasos deben estar registrados**. No es derivable de `PASOS` sin una regla, porque el paso 39 (consolidar) no produce intermedio sellado y no debe estarlo.

**Regla fijada, y no se sustituye por criterio propio:**

- **El registro es obligatorio por defecto.** Todo `id` de `PASOS` debe aparecer en `PASOS_EXTRACCION`, en `INTERMEDIOS_PIPELINE` y en `capturas_crudas_de_paso()`.
- **Las excepciones son explícitas y nominadas**, en una constante nueva declarada junto a `PASOS`, con su porqué en comentario:

```r
# Pasos que NO producen intermedio sellado y por tanto NO se registran en las
# estructuras de la guarda. Es una lista de EXCEPCIONES: el registro es
# obligatorio por defecto, de modo que un paso nuevo falla ruidosamente hasta
# que alguien decida conscientemente excluirlo.
PASOS_SIN_INTERMEDIO <- c(39L)
```

**Por qué así y no al revés:** una lista de incluidos deja al paso nuevo fuera en silencio, que es exactamente lo que ocurrió con el 37. Una lista de excepciones deja al paso nuevo dentro y ruidoso. El defecto se paga en la primera corrida, no dos sesiones después.

---

## §5. Fases, en orden estricto

### F0 — Estado real (lectura; nada se escribe)

**F0.0 — Commit del propio encargo** (llega untracked y bloquearía la compuerta de limpieza):

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile add 50_documentacion/andamios/50_encargo_s23_p93_guarda_registro_pasos.md
git -C /Users/tomgc/Projects/transparencia_legislativa_chile commit -m "docs: encargo P-93 (guarda de registro de pasos)"
```

**F0.1 — Compuerta de partida (H1).**

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile fetch --all --prune
git -C /Users/tomgc/Projects/transparencia_legislativa_chile rev-parse main origin/main
git -C /Users/tomgc/Projects/transparencia_legislativa_chile status --porcelain
gh pr list -R tomgc/transparencia_legislativa_chile --state open --json number,title,headRefName > /tmp/prs_p93.json
```

Lee el JSON en R. **Detente y reporta si:** #16, #17 o #18 siguen abiertos, o si `main..origin/main` trae commits que no están en local. Con `main` adelantado sólo por el commit de F0.0, continúa (ese es el estado esperado, y así se resuelve la contradicción que el encargo anterior tenía entre F0.0 y su propia compuerta).

**F0.2 — Leer las cuatro estructuras en `main` (H3).** Sin editarlas. Reporta, con número de línea:
- la definición de `PASOS` y la de `PASOS_EXTRACCION` (`grep -n` sobre `00_run_all.R`);
- la definición de `INTERMEDIOS_PIPELINE` y la de `capturas_crudas_de_paso()` completa (`grep -n` sobre `10_utils/10_utils.R`).

**F0.3 — Comprobar H2 sin correr el pipeline.** Carga los objetos en una sesión de R (`source` de `10_utils.R` y lectura de `00_run_all.R` sin ejecutar `run_all()`) y reporta la longitud de `INTERMEDIOS_PIPELINE` y de `PASOS_EXTRACCION`. Si no son 7 y 6 respectivamente (o lo que las definiciones de F0.2 impliquen), reporta la discrepancia: es un hallazgo, no un obstáculo.

**F0.4 — Localizar el literal de R4 (H4).** `grep -n '20_insumos/camara'` sobre `10_utils/10_utils.R`, y para cada coincidencia, determina en R (no a ojo) dentro de qué función cae, usando los offsets de las definiciones. **Si cae dentro de `sellar()`, `leer_sellado()` o `validar_corte()`, F2 no se ejecuta:** se declara como pendiente y se sigue con F3.

**Criterio de éxito de F0:** H1 a H4 resueltas con su salida, y la lista de líneas exactas que F1 y F2 van a tocar.

---

### F1 — La guarda (`verificar_registro_pasos()`)

**Rama:** créala desde `main` limpio:

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile checkout -b fix/p93-guarda-registro-pasos main
```

**Qué construir.** En `10_utils/10_utils.R`, una función pura:

```r
verificar_registro_pasos(pasos, excepciones = PASOS_SIN_INTERMEDIO)
```

- Recibe la lista `PASOS` completa y la lista de excepciones.
- Para cada `id` esperado (todo `id` de `pasos` menos las `excepciones`), comprueba tres membresías: que esté en `PASOS_EXTRACCION`, que tenga entrada en `INTERMEDIOS_PIPELINE`, y que `capturas_crudas_de_paso(id)` no falle. Esta última se prueba con `tryCatch()`, porque R3 dice que hace `stop()` ante un id desconocido: capturar ese `stop()` **es** la prueba de membresía, no un error a silenciar.
- Comprueba también el sentido inverso: un id registrado en cualquiera de las tres estructuras que **no** exista en `pasos` es igual de huérfano y se reporta.
- Ante cualquier huérfano, `stop()` con: el `id`, en qué estructuras falta y en cuáles está, y la instrucción de qué archivo y qué estructura editar. Un mensaje que no nombre el paso no sirve.
- Con todo sincronizado, **devuelve invisible y no imprime nada**. Una guarda que habla cuando todo está bien se vuelve ruido y se deja de leer.

**Dónde se invoca.** En `run_all()`, en `00_run_all.R`, **antes** de `regenerar_intermedios_si_desalineados()` (R2): un pipeline mal registrado no debe llegar siquiera a mirar los sellos. Declara `PASOS_SIN_INTERMEDIO` junto a `PASOS`, con el comentario de §4 literal.

**Verificación, entre la construcción y el commit, en este orden:**

1. **Control conocido-bueno (A95).** Con el pipeline tal como está, `verificar_registro_pasos(PASOS)` no dice nada y `run_all(only = 39)` sigue corriendo igual que antes. Si el control falla, la guarda tiene un falso rojo y no se commitea.
2. **La prueba que puede fallar.** En un arnés temporal (una copia en `/tmp`, **no** editando el archivo del repo), agrega un paso ficticio 38 sólo a `PASOS` y comprueba que la guarda se detiene **nombrando el 38** y nombrando las tres estructuras que le faltan. Cita la salida literal.
3. **La prueba inversa.** Registra un id ficticio sólo en `INTERMEDIOS_PIPELINE` y comprueba que también se detiene.
4. **Idempotencia del pipeline:** `run_all()` completo, con la salida de tiempo y el conteo de pasos, y `git status --porcelain` acotado a `40_salidas/` para verificar que la corrida no dejó nada versionable colgando.

**Commit atómico** (sólo estas dos rutas):

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile add 10_utils/10_utils.R 00_run_all.R
git -C /Users/tomgc/Projects/transparencia_legislativa_chile commit -m "fix: guarda de sincronia del registro de pasos (P-93)"
```

**Criterio de éxito de F1:** el control conocido-bueno pasa en silencio, las dos pruebas de fallo se detienen nombrando el paso huérfano, y `run_all()` completo termina como antes.

---

### F2 — El directorio del mensaje deja de estar escrito a mano (R4)

**Sólo si F0.4 lo autorizó.**

El literal `20_insumos/camara/` del mensaje se sustituye por el directorio derivado de la ruta que `capturas_crudas_de_paso()` devuelve para ese paso (`dirname()` sobre la ruta real). Nada más: ni el texto restante, ni la lógica, ni el orden de las comprobaciones.

**Verificación antes del commit:**
1. Reproduce el escenario de una captura ausente que viva en `senado/` (moviendo la captura a un temporal, **nunca borrándola**, con la restitución en `on.exit(add = TRUE)`) y comprueba que el mensaje nombra `senado/`.
2. Reproduce el escenario equivalente con una captura de `camara/` y comprueba que el mensaje sigue diciendo `camara/`: la corrección no debe cambiar el caso que ya estaba bien.
3. Comprueba con `deparse()` que la lógica de detección y regeneración quedó idéntica salvo la construcción del mensaje, y cita el diff.

**Commit atómico aparte**, con mensaje propio (`fix: el directorio del stop de la guarda se deriva de la captura, no se escribe a mano`).

---

### F3 — Panel adversarial (obligatorio antes de abrir el PR)

Dos agentes de sólo lectura, con arnés propio, en worktrees separados, sin acceso al código de verificación de F1 y F2. Cada uno re-deriva:

- **A.** Con el pipeline tal como queda, la guarda no emite salida y `run_all()` corre completo.
- **B.** Con un paso agregado sólo a `PASOS`, la guarda se detiene nombrando ese paso.
- **C.** El comportamiento de detección y regeneración de `regenerar_intermedios_si_desalineados()` es idéntico a `main` (identidad de cuerpo por `deparse()` sobre las partes no tocadas, más el escenario del intermedio desalineado corrido en ambas ramas y comparado línea a línea).
- **D.** Sólo si F2 se ejecutó: el mensaje nombra el directorio correcto en los dos escenarios.

Cada agente emite PASA/FALLA por afirmación con su salida literal. **Discrepancia entre agentes = FALLA**, y se reporta, no se arbitra. Retira los worktrees al terminar y comprueba que ninguna captura quedó movida (`file.exists()` en R sobre las rutas tocadas, más `git diff --stat HEAD -- 20_insumos`).

---

### F4 — Log, PR y cierre

Log en
`/Users/tomgc/Projects/transparencia_legislativa_chile/50_documentacion/andamios/logs/20260819_p93_guarda_registro_pasos_log.md`,
plantilla fija de `encargo_autonomo_claude_code_v1.md` §4 (diez secciones), honesto sobre lo que costó. Commitea sólo el log, con ruta acotada.

Push de la rama y apertura del PR contra `main`, con el cuerpo del PR citando: el control conocido-bueno, las dos pruebas que pueden fallar, y el veredicto del panel.

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile push -u origin fix/p93-guarda-registro-pasos
```

**No mergees.** El merge es del titular.

---

## §6. Auto-auditoría antes de reportar

1. Toda cifra del reporte proviene de un bloque de R ejecutado en esta corrida.
2. Ninguna afirmación sobre el estado del repositorio se apoya en este encargo: el documento es la hipótesis, el comando es la fuente.
3. Si la guarda que construiste hubiera existido en la sesión de P-66, ¿habría atrapado el paso 37? Contéstalo con la prueba corrida, no con un razonamiento.

---

## §7. Reporte final al chat

1. Salidas de F0.1 a F0.4, crudas.
2. La función nueva completa, tal como quedó en el archivo.
3. Salida literal del control conocido-bueno y de las dos pruebas de fallo.
4. Tabla del panel: afirmación × agente 1 × agente 2 × PASA/FALLA.
5. Si F2 se ejecutó: los dos mensajes, antes y después, en los dos escenarios. Si no se ejecutó: por qué, con la línea de F0.4 que lo impidió.
6. Hashes de los commits, número del PR y ruta del log.
7. Pendientes abiertos y marcas `# REVISAR`, **sin numerar como P-NN**: la numeración la asigna el asistente en el cierre (P-95 ya está tomado por la glosa oficial del sufijo).
