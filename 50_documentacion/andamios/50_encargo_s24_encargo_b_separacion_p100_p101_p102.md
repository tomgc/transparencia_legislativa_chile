# Encargo autónomo — B: separar lo verificado de lo que no cerró, y auditar al redactor

> **Destino:** `50_documentacion/andamios/50_encargo_s24_encargo_b_separacion_p100_p101_p102.md`
> **Redactor:** asistente de análisis (Claude conversacional), sesión 24.
> **Ejecutor:** Claude Code, modo autónomo.
> **Cubre:** la salida a PR de P-100, P-101 y P-102, y la verificación de siete errores del redactor.
> **No cubre P-105.** Se queda donde está, intacto, para su propio encargo.
>
> **Por qué existe.** Dos rondas y dos paneles dejaron un resultado asimétrico: los cuatro defectos originales de P-100 están muertos y confirmados por dos panelistas calibrados, P-101 y P-102 pasaron limpios las dos revisiones, y los tres defectos nuevos están **los tres en el barrido**. Tres pendientes verificados están esperando a un cuarto que no cierra, y esa espera la causó el redactor al agruparlos.
>
> **Qué hace este encargo, además de separar.** Verifica, uno por uno y con medición, los siete errores que el redactor cometió en los encargos A y A2. No es contrición: cada error dejó una marca en el código o en un comentario, y varias de esas marcas viajarían al PR si nadie las busca. La lista está en §2bis y su cierre es criterio de éxito.

---

## §0. Contrato positivo

### 0.1 Respaldado (medido por el ejecutor y por los paneles, sesión 24)

| # | Premisa | Fuente |
|---|---|---|
| R1 | Los cuatro defectos originales del panel (D1–D4) están muertos, con antes/después, y los dos panelistas de segunda vuelta lo confirman tras superar su control negativo (4/4 reproducidos sobre `b897ec4`) | reporte de A2 §4, esta sesión |
| R2 | P-101 y P-102 pasaron las dos revisiones de la primera vuelta (28/28 rutas idénticas sobre tres cortes, 0 literales construyendo ruta) y A2 no tocó 0 líneas de su código | panel de A §5 y reporte de A2 §3, esta sesión |
| R3 | Los tres defectos nuevos del panel de segunda vuelta están los tres en el barrido: volumen cero declarado limpio (6 de 7 archivos con dato personal), asimetría de `do.call` con símbolo pelado, y compuerta con crudo vacío que sale en 0 | reporte de A2 §4, esta sesión |
| R4 | El alcance real de P-102 eran seis literales, ya corregidos, y hoy hay 0 construyendo ruta de crudo | F0.3 de A2, esta sesión |
| R5 | La rama `fix/encargo-a-derivacion-y-barrido` tiene los commits `05f154a`, `cb34726`, `25f6082`, `0551b9b`, `b897ec4`, `5e460bc`, `9b19cec`, `abb86f1`, `ff71730`, pusheada, sin PR abierto | reportes de A y A2, esta sesión |
| R6 | `main` está en `37e571c`, con P-99 dentro y el corte 2026-08-20 publicado | reporte de merge, esta sesión |
| R7 | Los commits de A2 mezclan en `10_utils.R` correcciones de P-100 y de P-105: la separación no es un `cherry-pick` limpio de los tres commits de A2 | reporte de A2 §2 (`10_utils.R` +187/−37 en una ronda que corrige ambos), esta sesión |
| R8 | El comentario de `10_utils.R:276` conserva *barrer el origen los cubre*, medido falso: 102 derivados disparan `digitos_9mas` por decimales de `tasa_presencia`, 0 del crudo | pendientes de A2, esta sesión |
| R9 | Sobre el corpus vigente (70 archivos trackeados, `territorio` incluido): limpio 70, hallazgos 0, ilegible 0, 103 827 065 caracteres | F1.10 de A2, esta sesión |

### 0.2 Hipótesis (se resuelven en F0)

| # | Hipótesis | Dónde |
|---|---|---|
| H1 | `main` sigue en `37e571c` y la rama de A sigue en `ff71730`, ambas sin divergencia con su remoto | F0.1 |
| H2 | Los commits `cb34726` (P-101) y `25f6082` (P-102) aplican sobre `main` sin conflicto y sin arrastrar código de P-105 | F0.2 |
| H3 | El estado final de las funciones de P-100 en la rama de A es extraíble sin arrastrar ninguna función, constante ni comentario de P-105 | F0.3 |
| H4 | El YAML de la rama de A contiene cambios de P-99 (ya en `main`) y de P-105 (que no sale): al separar, el YAML **no se toca en absoluto** | F0.4 |

**Si H3 es falsa** (las funciones de P-100 llaman a algo que nació con P-105, o comparten helper), **detente y reporta**. Separar código acoplado a ojo es cómo se pierde una corrección sin que nadie lo note.

---

## §1. Encabezado de contrato

**Modo:** autónomo, secuencial, todo en este turno.

**Regla de detención (los únicos tres casos):** (a) un invariante 🔒 te obligaría a violarlo; (b) un dato real contradice una premisa de §0.1; (c) un gate marcado como decisión del titular.

**ENTORNO:** filesystem local vía Claude Code. Raíz: `/Users/tomgc/Projects/transparencia_legislativa_chile`.

**POSICIÓN:** ningún comando asume `cd`. `git` con `-C /Users/tomgc/Projects/transparencia_legislativa_chile`; `gh` con `-R tomgc/transparencia_legislativa_chile` salvo `gh api`.

---

## §2. Contexto mínimo suficiente

Tres pendientes están verificados por dos paneles y no pueden llegar a `main` porque comparten rama con un cuarto que lleva dos rondas sin cerrar. La separación los libera. La trampa está en cómo se separa: los commits de A2 tocan `10_utils.R` mezclando P-100 y P-105, así que un `cherry-pick` de commits no basta y una copia a ojo pierde correcciones en silencio.

Este encargo separa **por estado final verificado**, no por commits, y prueba la equivalencia programáticamente.

---

## §2bis. Los siete errores del redactor, y qué los cierra

Cada uno dejó una marca. La columna de la derecha es lo que hay que medir, no lo que hay que creer.

| # | Error del redactor | Dónde quedó la marca | Qué lo cierra |
|---|---|---|---|
| E1 | **Agrupó P-105 con tres refactores de derivación.** Superficies distintas: los tres primeros se prueban por equivalencia de rutas, el barrido se prueba contra un adversario | la rama compartida | Este encargo. Se cierra al abrir el PR sin P-105 |
| E2 | **Afirmó en A §4.4 que barrer el origen cubre los derivados.** Falso: `distrito` y `region` llegan al JSON publicado 155/155 desde `territorio/`, que no está en `rutas_versionables_crudo()` | comentario de `10_utils.R:276`, *barrer el origen los cubre* (R8) | Ese comentario **no puede viajar al PR**. Si la función que lo contiene se queda con P-105, verifica que no cruza; si cruza, corrígelo con la medición de R8 |
| E3 | **Pidió en A2 §4.2 tres estados sin exigir la reconciliación bytes ↔ caracteres**, que es la única comprobación que distingue "no lo pude leer" de "está limpio". Diseñó el criterio y omitió su prueba: el resultado fue 6 de 7 archivos con dato personal declarados limpios | el barrido, que no sale en este PR | Verifica que ninguna función que **sí** sale arrastra el mismo patrón: ¿hay en P-100/101/102 alguna rama que reporte un resultado sin haber podido examinar su entrada? Enumérala |
| E4 | **Redactó A2 §4.1.3 ("lo irresoluble se detiene") tan ancho que produjo DE-2**: `do.call(rbind, piezas)` con símbolo pelado es literal y decidiblemente no-`switch`, y el código lo marcó irresoluble afirmando una causa que no midió | el localizador, que **sí** sale en este PR | **Ésta es la marca más grave que cruza.** Si DE-2 sigue vivo en el estado final de P-100, se corrige aquí, con su prueba: símbolo pelado resoluble, `do.call` con variable irresoluble, y el mensaje nombrando sólo lo que midió |
| E5 | **No exigió que el arnés versionado ejercitara la clase del defecto central ni corriera en CI** | el arnés nuevo de A2 (+166) | Decide y reporta si el arnés se va con P-105 o se queda; si contiene pruebas de P-100, esas pruebas cruzan con él |
| E6 | **Resolvió la clasificación de las `function` anidadas pero no su gravedad**, y los dos panelistas divergieron exactamente ahí (falso negativo bloqueante o no) | el localizador, que sí sale | Resuelto en §4.3 de este encargo. Se prueba en las dos direcciones |
| E7 | **Diseñó en A §4.4 un alcance dinámico** ("las rutas staged que caen bajo `rutas_versionables_crudo()`"), que con crudo sin cambios da 0 archivos y EXIT=0 (DE-3) | el YAML, que **no** sale en este PR | Verifica que el YAML queda exactamente como está en `main` (H4). Si el PR toca el YAML, el alcance dinámico viaja con él y hay que detenerse |

---

## §3. Invariantes (🔒)

- 🔒 **La rama `fix/encargo-a-derivacion-y-barrido` no se toca, no se rebasea y no se borra.** Es el insumo del encargo de P-105.
- 🔒 **Nada de P-105 entra en la rama nueva:** ni la función de barrido, ni sus patrones, ni el paso del YAML, ni sus comentarios. El `git diff` contra `main` debe poder enumerarse entero y ninguna línea puede pertenecer al barrido.
- 🔒 **El YAML no se modifica.** `git diff main -- .github/workflows/refresh-semanal.yml` en cero (H4).
- 🔒 `sellar()`, `leer_sellado()` y `validar_corte()` no se tocan.
- 🔒 `10_utils/10_utils.R` no adquiere dependencias de paquetes.
- 🔒 `DIRECTORIOS_CRUDO` no cambia de contenido.
- 🔒 **No mergees ningún PR** ni hagas push a `main`.
- 🔒 Ninguna captura cruda se modifica ni se borra. **Ninguna descarga**, ninguna corrida del workflow.
- 🔒 R es el único lenguaje para medir o contar. `bash` sólo para `git`, `gh` y `Rscript`.
- 🔒 `git add` siempre con ruta acotada; nunca `git add .` ni `git add -A`.
- 🔒 Ninguna cifra se reporta sin recontarla programáticamente en el mismo bloque que la reporta.
- 🔒 `50_documentacion/traspasos/paquete_cierre_v23.md`, sin trackear, no se toca ni se commitea.

---

## §4. Las decisiones de metodología (son del redactor, no tuyas)

### 4.1 Se separa por estado final, y la equivalencia se prueba

Rama nueva desde `main`. Encima: `cherry-pick` de `cb34726` (P-101) y `25f6082` (P-102), que no tocan P-105 (R2). Para P-100, **no** se hace `cherry-pick` de los commits de A/A2 (R7): se transporta el **estado final verificado** de las funciones involucradas.

**La prueba de que no se perdió nada es programática, no visual.** Para cada función que cruza, compara su definición entre la rama de A y la rama nueva, en R, por `deparse()` normalizado o por hash del cuerpo, y reporta la tabla completa función por función. Ojo con lo que enseña A92: `git diff` es simétrico y direccionalmente ciego; para verificar transporte de commits usa `git cherry` con patch-id, y para el estado final usa la comparación de definiciones.

**Y la prueba de que no cruzó nada de más:** enumera en R **todos** los objetos que la rama nueva agrega o modifica respecto de `main`, y clasifica cada uno como P-100, P-101, P-102 o intruso. Un intruso detiene el encargo.

### 4.2 DE-2 se corrige aquí (E4)

Es el único de los tres defectos nuevos que vive en código que sale en este PR. La condición correcta:

- `do.call("switch", ...)` con literal de cadena ⇒ es un `switch`.
- `do.call(rbind, piezas)` con **símbolo pelado** ⇒ es decidiblemente **no**-`switch`, resoluble, no detiene.
- `do.call(f, ...)` donde `f` es una variable cuyo valor no se puede determinar sintácticamente ⇒ **irresoluble**, detiene, y el mensaje dice exactamente eso y nada más.

El mensaje de la rama irresoluble **no puede afirmar** que la función dejó de declarar sus capturas con un `switch`, porque eso no se midió. Nombra la guarda, la función auditada y la forma que no pudo decidir.

### 4.3 La divergencia del panel, resuelta (E6)

Un `switch` dentro de una `function` anidada no es la declaración de capturas, y el localizador no entra en cuerpos de `function`. Sobre la gravedad, que es lo que quedó sin decidir: **si el único `switch` del cuerpo está dentro de una `function` anidada, eso cuenta como cero llamadas y la guarda falla ruidosamente.** No es un falso negativo tolerable: es exactamente el caso en que la guarda no puede auditar y por tanto no puede afirmar que todo está bien.

Se prueba en las dos direcciones, con las dos pruebas en el reporte.

### 4.4 El arnés (E5)

Si el arnés versionado de A2 contiene pruebas de P-100, esas pruebas cruzan a la rama nueva, en un archivo propio y corrible con `Rscript`. Lo que sea del barrido se queda. Si el archivo es indivisible, **repórtalo y déjalo con P-105**: no partas un arnés a la mitad para cumplir con una regla de reparto.

---

## §5. Fases

### F0 — Estado y separabilidad

**F0.1 (H1).**

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile fetch --all --prune
git -C /Users/tomgc/Projects/transparencia_legislativa_chile status --porcelain
git -C /Users/tomgc/Projects/transparencia_legislativa_chile log --oneline -3 main
git -C /Users/tomgc/Projects/transparencia_legislativa_chile log --oneline main..fix/encargo-a-derivacion-y-barrido
```

**Detente ante divergencia o conflicto.**

**F0.2 (H2).** Verifica en un worktree desechable que `cb34726` y `25f6082` aplican sobre `main` sin conflicto, y reporta las rutas que tocan.

**F0.3 (H3).** Inventaria, en R, todas las funciones y constantes que la rama de A agrega o modifica en `10_utils.R` respecto de `main`, y clasifica cada una: P-100, P-105, o ambas. Reporta el grafo de llamadas entre ellas. **Detente si alguna de P-100 llama a alguna de P-105.**

**F0.4 (H4).** `git diff main..fix/encargo-a-derivacion-y-barrido -- .github/workflows/refresh-semanal.yml`, clasificando cada hunk como P-99 (ya en `main`) o P-105. Confirma que la rama nueva no necesita tocar el YAML.

**F0.5 — La marca de E2.** Localiza el comentario *barrer el origen los cubre* con su línea de hoy y determina si la función que lo contiene cruza al PR. Si cruza, corrígelo con la medición de R8 (102 derivados disparan `digitos_9mas`, 0 del crudo).

**F0.6 — La marca de E4.** Reproduce DE-2 sobre la rama de A, con salida literal, **antes de corregirlo**. Es el control negativo de §4.2.

---

### F1 — La rama nueva

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile checkout -b fix/p100-p101-p102-derivacion main
```

Commits atómicos: P-101, P-102, P-100 (estado final), corrección de DE-2, arnés si cruza (§4.4).

**Verificación, con salida literal:**

1. **Equivalencia de definiciones** (§4.1), tabla completa por función.
2. **Inventario de lo que cruza**, clasificado, con cero intrusos.
3. **DE-2 muerto:** los tres casos de §4.2, con el antes de F0.6 al lado.
4. **Las `function` anidadas**, en las dos direcciones (§4.3).
5. **Los cuatro defectos originales, todavía muertos** sobre la rama nueva: no basta con que lo estuvieran en la rama vieja. En particular el fall-through `"32" = ,` del `switch` real y `tramites[!fuera, , drop = FALSE]` (`37:190`).
6. **Las 19 formas de AST** de A2, re-corridas sobre la rama nueva.
7. **Control conocido-bueno completo:** `run_all()`, stdout y stderr contra `main`, md5 de las 1 242 salidas, cache hits, 0 red.
8. **Los cinco escenarios de P-93** y **los tres mensajes de P-101**.
9. **Equivalencia de rutas de P-102**, re-corrida.
10. **El YAML en cero** (🔒): `git diff main -- .github/workflows/refresh-semanal.yml` vacío.
11. **Ninguna línea de barrido:** `git diff main...` completo, enumerado, con cada archivo justificado.

---

### F2 — Panel adversarial

Dos panelistas independientes, en worktrees separados, sin tu reporte ni tus logs.

**Su control negativo es doble, y sin él su veredicto no cuenta:**
- reproducir los cuatro defectos originales sobre `b897ec4`;
- reproducir DE-2 sobre la rama de A.

**Su pregunta central es la de este encargo:** ¿se perdió algo en la separación, o cruzó algo que no debía? Que lo contesten con su propia medición de equivalencia, no leyendo la tuya.

Además, cada panelista intenta una forma de AST propia que el localizador no haya visto.

Veredicto por panelista: PASA / NO PASA, con desacuerdos explícitos. **Discordancia o NO PASA ⇒ detente y reporta, sin arreglar sobre la marcha.**

---

### F3 — Log, PR y cierre

Log nuevo en `50_documentacion/andamios/logs/<AAAAMMDD de hoy, del sistema>_encargo_b_separacion_log.md`, plantilla de `encargo_autonomo_claude_code_v1.md` §4, con una sección propia para §2bis: los siete errores del redactor y qué midió cada uno. Commit acotado, push.

**Con PASA concordante:** PR contra `main` citando la tabla de equivalencia, el inventario sin intrusos, el antes/después de DE-2 y los dos veredictos. **No mergees:** gate del titular.

**Con cualquier NO PASA:** no abras PR. Reporta.

Árbol como lo encontraste, con el único `?? paquete_cierre_v23.md`. La rama de A intacta y pusheada.

---

## §6. Dudas del redactor — verifícalas y contéstalas

No son retóricas. Cada una puede cambiar el encargo de P-105 o el contenido del PR, y ninguna la puedo contestar yo sin medir.

| # | Duda | Cómo se contesta |
|---|---|---|
| Q1 | ¿Los dos `.txt` trackeados en `20_insumos/senado/` contienen bytes NUL? El panel dijo que "el caso del NUL está vivo hoy", y si es así, el corpus vigente tiene archivos que el barrido actual no puede mirar | conteo de bytes NUL en R sobre los archivos trackeados, con `readBin` |
| Q2 | El limpio de R9 (70 archivos, 0 hallazgos), ¿sobrevive a la reconciliación bytes ↔ caracteres? Es decir: de esos 70, ¿cuántos tienen caracteres escaneados desproporcionados respecto de sus bytes en disco? **Si el limpio no sobrevive, el corpus vigente no está auditado y eso es mucho más urgente que P-105** | tabla archivo / bytes / caracteres escaneados / estado, sobre los 70 |
| Q3 | ¿`validUTF8()` marcaría ilegible alguna cadena latin1 declarada del corpus real? A2 reportó 0 casos hoy, pero las capturas del Senado son la fuente más probable | recuento por archivo de crudo, declarando el volumen |
| Q4 | ¿El arnés versionado de A2 es divisible entre P-100 y P-105, o es un solo archivo indivisible? | lectura del archivo y clasificación de sus bloques |
| Q5 | ¿Queda en el árbol algún otro comentario, además del de `10_utils.R:276`, que afirme una cobertura que no se midió? Es la clase de E2, y fue el redactor quien la escribió | `grep` de comentarios en `10_utils.R` y el YAML que hagan afirmaciones de cobertura, clasificados |
| Q6 | Con P-100 en `main` y P-105 fuera, ¿queda el workflow en un estado coherente, o hay un paso que dependa de algo que no llegó? | lectura del YAML de `main` y del grafo de llamadas |
| Q7 | ¿`digitos_9mas` con 102 falsos positivos sobre derivados es un problema del patrón o del alcance? No lo decido aquí, pero el encargo de P-105 necesita el dato | medición sobre los derivados, separando patrón por patrón |

Contéstalas todas, aunque la respuesta sea "no aplica". Una duda sin contestar vuelve como premisa heredada tres sesiones después.

---

## §7. Auto-auditoría antes de reportar

1. Toda cifra proviene de un bloque de R ejecutado en esta corrida.
2. Enumera cada archivo del `git diff main...` y justifica por qué está. ¿Alguno pertenece al barrido?
3. ¿Alguna función que cruza tiene una rama que reporte un resultado sin haber podido examinar su entrada? Enumera las ramas, no lo afirmes (E3).
4. ¿Algún mensaje de error del código que cruza afirma una causa que no midió? Cítalos todos, literales (E4).
5. Las siete dudas de §6, ¿están las siete contestadas con medición?

---

## §8. Reporte final al chat

1. F0.1 a F0.6, crudas, con DE-2 reproducido antes de corregirlo.
2. La tabla de equivalencia de definiciones y el inventario clasificado, con cero intrusos.
3. Las once verificaciones de F1.
4. Veredicto del panel por panelista, con su control negativo doble.
5. **Las siete respuestas de §6**, cada una con su medición.
6. **Los siete errores de §2bis**, con qué los cerró o por qué siguen abiertos.
7. Hashes, número del PR si lo hubo, ruta del log, y confirmación de que la rama de A quedó intacta.
8. Pendientes abiertos y marcas `# REVISAR`, sin numerar como P-NN.
