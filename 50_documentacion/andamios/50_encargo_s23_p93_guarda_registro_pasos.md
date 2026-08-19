# Encargo autónomo — P-93: guarda de sincronía del registro de pasos (v2)

> **Destino:** `50_documentacion/andamios/50_encargo_s23_p93_guarda_registro_pasos.md`
> **Reemplaza** a la v1 del mismo día, en la misma ruta. **Sobrescribe el archivo, no agregues un segundo encargo al lado.**
> **Redactor:** asistente de análisis (Claude conversacional), sesión 23.
> **Ejecutor:** Claude Code, modo autónomo.
> **Cambios respecto a v1:** (a) nueva **F0.1bis**, los merges de #18, #16 y #17 delegados por el titular en esta sesión; (b) la compuerta de F0.1 deja de detenerse por PR abiertos y pasa a detenerse por divergencia remota o árbol sucio; (c) §3 acota la autoridad de merge; (d) F0.1ter resuelve la divergencia local sin escribir en `origin/main`. La metodología de §4 y las fases F1 a F4 no cambian.

---

## §0. Contrato positivo: qué está respaldado y qué es hipótesis

### 0.1 Respaldado (fuente leída o ejecutada en la sesión 23)

| # | Premisa | Fuente |
|---|---|---|
| R1 | El registro de un paso vive en tres estructuras y nada obliga a sincronizarlas: `INTERMEDIOS_PIPELINE` (`10_utils/10_utils.R:506`) y las ramas de `capturas_crudas_de_paso()` (`10_utils/10_utils.R:574`), y `PASOS_EXTRACCION` (`00_run_all.R:64`) | F0.2 de la corrida de detención, reportada en esta sesión |
| R2 | En `main`: `PASOS` tiene 7 ids (32-37, 39), `PASOS_EXTRACCION` tiene 5 (32-36), `INTERMEDIOS_PIPELINE` tiene 6 (sin `tramitacion`), y `capturas_crudas_de_paso(37)` hace `stop()` | F0.3 de la corrida de detención, medido en R |
| R3 | Instalar la guarda de §4 sobre `main` **hoy** declararía huérfano al paso 37 y detendría `run_all()` en su entrada, incluido el refresh del lunes | consecuencia directa de R2, medida por el ejecutor en la detención |
| R4 | El literal `20_insumos/camara/` del mensaje del `stop()` está en `10_utils/10_utils.R:750` y `:801`, ambas dentro de `regenerar_intermedios_si_desalineados()`; 0 coincidencias dentro de `sellar()`, `leer_sellado()` o `validar_corte()` | F0.4 de la detención, asignación función-por-offset hecha en R |
| R5 | `origin/main` está en `2b5b3b7`; los tres PR abiertos son `MERGEABLE` y ninguno está integrado (3, 3 y 1 commits ausentes respectivamente) | F0.1 remedida con `git ls-remote` y `gh api /pulls/<n>`, tres fuentes independientes |
| R6 | El `main` local está adelantado por tres commits documentales del día, sin push, y `main..origin/main` está vacío | ídem |

### 0.2 Autorización vigente de esta sesión

**El titular delegó la autoridad de merge sobre los PR #16, #17 y #18** (mensaje del titular, sesión 23, opción B). La delegación es acotada: esos tres números, con `--merge`, en esta sesión. No alcanza al PR que este encargo abrirá.

### 0.3 Hipótesis (se resuelven en F0, antes de escribir código)

| # | Hipótesis | Comando que la resuelve |
|---|---|---|
| H1 | Los tres PR mergean limpio, sin conflicto y sin intervención | F0.1bis |
| H2 | Con #16 mergeado, `INTERMEDIOS_PIPELINE` pasa a 7 y `PASOS_EXTRACCION` incluye el 37 | F0.3 |
| H3 | El literal de R4 sigue en el mismo lugar tras los merges | F0.4 |

---

## §1. Encabezado de contrato

**Modo:** autónomo, secuencial, todo en este turno.

**Regla de detención (los únicos tres casos):** (a) un invariante 🔒 te obligaría a violarlo; (b) un dato real contradice una premisa de §0.1; (c) un gate marcado como decisión del titular. Reporta y espera; no improvises metodología.

**ENTORNO:** filesystem local vía Claude Code. Raíz: `/Users/tomgc/Projects/transparencia_legislativa_chile`.

**INSUMOS:** todo vive en el repo. Ningún archivo llega "aparte".

**POSICIÓN:** ningún comando asume `cd`. `git` siempre con `-C /Users/tomgc/Projects/transparencia_legislativa_chile`; `gh` con `-R tomgc/transparencia_legislativa_chile` salvo `gh api`. Rutas de R absolutas o vía `here::here()`.

---

## §2. Contexto mínimo suficiente

Un paso del pipeline está registrado en cuatro lugares: `PASOS` (lista maestra, `00_run_all.R`), `PASOS_EXTRACCION` (derivada por filtro, mismo archivo), `INTERMEDIOS_PIPELINE` (`10_utils/10_utils.R`) y las ramas de `capturas_crudas_de_paso()` (mismo archivo). P-66 agregó el paso 37 tocando sólo la primera. El síntoma tardó dos sesiones en aparecer y costó P-86.

P-93 no arregla ese caso (lo hace PR #16): **impide que el próximo paso nuevo lo repita**. Por eso el orden importa y por eso este encargo mergea antes de construir: sobre `main` sin #16, la guarda correcta detiene el pipeline correcto por la razón correcta (R3).

El defecto de R4 entra en el mismo encargo porque vive en el mismo mensaje y pertenece a la misma clase: un dato que debería derivarse está escrito a mano.

---

## §3. Invariantes (🔒)

- 🔒 **Autoridad de merge, acotada.** Estás autorizado a mergear **#18, #16 y #17, en ese orden, con `--merge`**. Nada más. Sin `--squash` ni `--rebase` (reescribirían los hashes que el traspaso v22 cita), sin `--admin`, sin `--delete-branch`, y sin tocar ningún otro PR presente o futuro. **El PR que abras en F4 no se mergea.**
- 🔒 **No hagas push a `main`.** Los merges los ejecuta GitHub del lado del servidor; el `main` local se pone al día leyendo, no escribiendo (F0.1ter).
- 🔒 `sellar()`, `leer_sellado()` y `validar_corte()` no se tocan, ni siquiera para corregir cadenas obsoletas que vivan dentro.
- 🔒 La lógica de detección y de regeneración de `regenerar_intermedios_si_desalineados()` no cambia. En F2 se toca **sólo** la construcción del mensaje, y hay que probar que el comportamiento es idéntico antes y después.
- 🔒 La nueva guarda es **estructural y estática**: lee objetos de R en memoria. No toca el filesystem, no lee sellos, no hace red, no depende del corte. Si tu diseño la obliga a leer un archivo, el diseño está mal: detente y reporta.
- 🔒 `10_utils/10_utils.R` no adquiere dependencias de paquetes.
- 🔒 R es el único lenguaje, en todo contexto. `bash` sólo para `git`, `gh` y `Rscript`.
- 🔒 `git add` siempre con ruta acotada; nunca `git add .` ni `git add -A`.
- 🔒 Ninguna captura cruda se borra: para forzar escenarios se mueve y se restituye en un `on.exit(add = TRUE)`.
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

**Por qué así y no al revés:** una lista de incluidos deja al paso nuevo fuera en silencio, que es exactamente lo que ocurrió con el 37. Una lista de excepciones lo deja dentro y ruidoso. El defecto se paga en la primera corrida, no dos sesiones después.

---

## §5. Fases, en orden estricto

### F0 — Estado real y apertura de la compuerta

**F0.0 — El encargo, en su ruta y commiteado.** Este archivo reemplaza a la v1 en `50_documentacion/andamios/50_encargo_s23_p93_guarda_registro_pasos.md`. Sobrescríbelo (no crees un `_v2` en el repo) y commitea:

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile add 50_documentacion/andamios/50_encargo_s23_p93_guarda_registro_pasos.md
git -C /Users/tomgc/Projects/transparencia_legislativa_chile commit -m "docs: encargo P-93 v2 (merges delegados y compuertas revisadas)"
```

**F0.1 — Compuerta de partida (revisada).**

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile fetch --all --prune
git -C /Users/tomgc/Projects/transparencia_legislativa_chile rev-parse main origin/main
git -C /Users/tomgc/Projects/transparencia_legislativa_chile status --porcelain
git -C /Users/tomgc/Projects/transparencia_legislativa_chile log --oneline main..origin/main
```

**Detente y reporta si:** `status --porcelain` trae algo que no sean los commits documentales ya hechos, o `main..origin/main` trae commits (alguien más movió el remoto: el escenario cambió y la delegación se dio sobre otro estado). **Que los tres PR estén abiertos ya no detiene nada:** abrirlos es el trabajo de F0.1bis.

**F0.1bis — Merges delegados.** En este orden exacto, uno a uno, verificando cada uno antes de pasar al siguiente:

1. **#18** (`refresh/2026-08-17`), primero: devuelve el dato fresco a producción y GitHub Pages republica `docs/` al mergear.
2. **#16** (`fix/p86-runner-paso37`), segundo: es la precondición sustantiva de P-93 (R3).
3. **#17** (`sondeo/p92-eje-tematico`), tercero: sólo toca `50_documentacion/andamios/`, y trae el veredicto que P-94 necesita.

```bash
gh pr merge 18 -R tomgc/transparencia_legislativa_chile --merge
gh pr merge 16 -R tomgc/transparencia_legislativa_chile --merge
gh pr merge 17 -R tomgc/transparencia_legislativa_chile --merge
```

Tras **cada** merge, verifica con su endpoint propio (no con `gh pr list`, que ya mostró ser una fuente peor):

```bash
gh api repos/tomgc/transparencia_legislativa_chile/pulls/<N> > /tmp/pr_<N>.json
```

y lee en R `state`, `merged` y `merged_at`. **Si un merge falla por conflicto, detente ahí mismo:** reporta el conflicto y qué archivos lo producen, no lo resuelvas. Los ya mergeados quedan mergeados; eso es correcto y no se revierte.

**F0.1ter — Poner al día el `main` local sin escribir en el remoto.** El `main` local tiene commits documentales sin push (R6) y el remoto acaba de avanzar. Reconcilia rebasando lo local sobre lo remoto:

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile fetch origin
git -C /Users/tomgc/Projects/transparencia_legislativa_chile rebase origin/main
git -C /Users/tomgc/Projects/transparencia_legislativa_chile log --oneline -8
```

**Consecuencia asumida, decláralas en el reporte:** el rebase reescribe los hashes de los commits documentales del día (`f9302a6`, `5e655c1` y el de F0.0 cambian de hash; el contenido no). Reporta los hashes nuevos, porque el traspaso los citará. Si el rebase entra en conflicto, **detente**: no lo resuelvas.

**F0.2 — Releer las cuatro estructuras, ya con #16 dentro.** Con número de línea: `PASOS` y `PASOS_EXTRACCION` (`grep -n` sobre `00_run_all.R`); `INTERMEDIOS_PIPELINE` y `capturas_crudas_de_paso()` completa (`grep -n` sobre `10_utils/10_utils.R`).

**F0.3 — Compuerta sustantiva (H2).** Carga los objetos en R (`source` de `10_utils.R`, lectura de `00_run_all.R` sin ejecutar `run_all()`) y reporta: `length(INTERMEDIOS_PIPELINE)`, los ids de `PASOS`, los ids de `PASOS_EXTRACCION`, y el resultado de `tryCatch(capturas_crudas_de_paso(37))`.

**Detente y reporta si el paso 37 sigue huérfano en cualquiera de las tres estructuras.** Sería que #16 no hace lo que su PR dice, y eso es un hallazgo mayor, no un obstáculo a sortear.

**F0.4 — Relocalizar el literal de R4.** `grep -n '20_insumos/camara'` sobre `10_utils/10_utils.R` y, para cada coincidencia, determina en R (no a ojo, por offsets de las definiciones) dentro de qué función cae. **Si alguna de las dos que importan cayó dentro de `sellar()`, `leer_sellado()` o `validar_corte()` tras el merge, F2 no se ejecuta:** se declara como pendiente y sigues con F3.

**Criterio de éxito de F0:** los tres PR con `merged = TRUE` y su `merged_at`, el `main` local al día, y H2 y H3 resueltas con su salida.

---

### F1 — La guarda (`verificar_registro_pasos()`)

**Rama**, desde el `main` ya al día:

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile checkout -b fix/p93-guarda-registro-pasos main
```

**Qué construir.** En `10_utils/10_utils.R`, una función pura:

```r
verificar_registro_pasos(pasos, excepciones = PASOS_SIN_INTERMEDIO)
```

- Recibe la lista `PASOS` completa y la lista de excepciones.
- Para cada `id` esperado (todo `id` de `pasos` menos las `excepciones`), comprueba tres membresías: que esté en `PASOS_EXTRACCION`, que tenga entrada en `INTERMEDIOS_PIPELINE`, y que `capturas_crudas_de_paso(id)` no falle. Esta última se prueba con `tryCatch()`: capturar ese `stop()` **es** la prueba de membresía, no un error a silenciar.
- Comprueba el sentido inverso: un id registrado en cualquiera de las tres estructuras que **no** exista en `pasos` es igual de huérfano y se reporta.
- Ante cualquier huérfano, `stop()` con: el `id`, en qué estructuras falta y en cuáles está, y qué archivo y qué estructura hay que editar. Un mensaje que no nombre el paso no sirve.
- Con todo sincronizado, **devuelve invisible y no imprime nada**. Una guarda que habla cuando todo está bien se vuelve ruido y se deja de leer.

**Dónde se invoca.** En `run_all()`, **antes** de `regenerar_intermedios_si_desalineados()`: un pipeline mal registrado no debe llegar siquiera a mirar los sellos. Declara `PASOS_SIN_INTERMEDIO` junto a `PASOS`, con el comentario de §4 literal.

**Verificación, entre la construcción y el commit, en este orden:**

1. **Control conocido-bueno (A95).** Con el pipeline tal como está, `verificar_registro_pasos(PASOS)` no dice nada y `run_all(only = 39)` corre igual que antes. Si el control falla, la guarda tiene un falso rojo y no se commitea.
2. **La prueba que puede fallar.** En un arnés temporal (copia en `/tmp`, **no** editando el archivo del repo), agrega un paso ficticio 38 sólo a `PASOS` y comprueba que la guarda se detiene **nombrando el 38** y las tres estructuras que le faltan. Cita la salida literal.
3. **La prueba inversa.** Registra un id ficticio sólo en `INTERMEDIOS_PIPELINE` y comprueba que también se detiene.
4. **Idempotencia:** `run_all()` completo, con tiempo y conteo de pasos, más `git status --porcelain` acotado a `40_salidas/` para verificar que la corrida no dejó nada versionable colgando.

**Commit atómico:**

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
1. Escenario de captura ausente que viva en `senado/` (moviendo la captura a un temporal, nunca borrándola, restitución en `on.exit(add = TRUE)`): el mensaje debe nombrar `senado/`.
2. Escenario equivalente con una captura de `camara/`: el mensaje debe seguir diciendo `camara/`. La corrección no puede cambiar el caso que ya estaba bien.
3. `deparse()` para probar que la lógica de detección y regeneración quedó idéntica salvo la construcción del mensaje; cita el diff.

**Commit atómico aparte:** `fix: el directorio del stop de la guarda se deriva de la captura, no se escribe a mano`.

---

### F3 — Panel adversarial (obligatorio antes de abrir el PR)

Dos agentes de sólo lectura, con arnés propio, en worktrees separados, sin acceso al código de verificación de F1 y F2. Cada uno re-deriva:

- **A.** Con el pipeline tal como queda, la guarda no emite salida y `run_all()` corre completo.
- **B.** Con un paso agregado sólo a `PASOS`, la guarda se detiene nombrando ese paso.
- **C.** El comportamiento de detección y regeneración de `regenerar_intermedios_si_desalineados()` es idéntico a `main` (identidad de cuerpo por `deparse()` sobre las partes no tocadas, más el escenario del intermedio desalineado corrido en ambas ramas y comparado línea a línea).
- **D.** Sólo si F2 se ejecutó: el mensaje nombra el directorio correcto en los dos escenarios.

Cada agente emite PASA/FALLA por afirmación con su salida literal. **Discrepancia entre agentes = FALLA**, y se reporta, no se arbitra. Retira los worktrees y comprueba que ninguna captura quedó movida (`file.exists()` en R sobre las rutas tocadas, más `git diff --stat HEAD -- 20_insumos`).

---

### F4 — Log, PR y cierre

Log en
`/Users/tomgc/Projects/transparencia_legislativa_chile/50_documentacion/andamios/logs/20260819_p93_guarda_registro_pasos_log.md`,
plantilla fija de `encargo_autonomo_claude_code_v1.md` §4 (diez secciones), honesto sobre lo que costó. **Incluye en la sección 7 (decisiones del usuario) la delegación de merge de §0.2, con su alcance acotado.** Commitea sólo el log, con ruta acotada.

Push de la rama y apertura del PR contra `main`, con el cuerpo citando el control conocido-bueno, las dos pruebas que pueden fallar y el veredicto del panel:

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile push -u origin fix/p93-guarda-registro-pasos
```

**Este PR no se mergea:** la delegación de §0.2 no lo alcanza.

---

## §6. Auto-auditoría antes de reportar

1. Toda cifra del reporte proviene de un bloque de R ejecutado en esta corrida.
2. Ninguna afirmación sobre el estado del repositorio se apoya en este encargo: el documento es la hipótesis, el comando es la fuente.
3. Si la guarda que construiste hubiera existido en la sesión de P-66, ¿habría atrapado el paso 37? Contéstalo con la prueba corrida, no con un razonamiento.

---

## §7. Reporte final al chat

1. Los tres merges: PR, `merged`, `merged_at`, hash del merge commit.
2. Hashes nuevos de los commits documentales tras el rebase de F0.1ter.
3. Salidas de F0.2 a F0.4, crudas.
4. La función nueva completa, tal como quedó en el archivo.
5. Salida literal del control conocido-bueno y de las dos pruebas de fallo.
6. Tabla del panel: afirmación × agente 1 × agente 2 × PASA/FALLA.
7. Si F2 se ejecutó: los dos mensajes, antes y después, en los dos escenarios. Si no: por qué, con la línea de F0.4 que lo impidió.
8. Hashes de los commits, número del PR nuevo y ruta del log.
9. Pendientes abiertos y marcas `# REVISAR`, **sin numerar como P-NN**: la numeración la asigna el asistente en el cierre (P-95 ya está tomado por la glosa oficial del sufijo).
