# Encargo autónomo — B2: revertir DE-2, restaurar lo perdido y versionar el arnés de P-100

> **Destino:** `50_documentacion/andamios/50_encargo_s24_encargo_b2_revertir_de2_y_arnes.md`
> **Redactor:** asistente de análisis (Claude conversacional), sesión 24.
> **Ejecutor:** Claude Code, modo autónomo.
> **Continúa** el encargo B, en su misma rama `fix/p100-p101-p102-derivacion`.
>
> **Qué pasó.** El panel devolvió NO PASA por dos cosas, y las dos son responsabilidad del redactor antes que del ejecutor. La primera: §2bis E4 mandaba corregir DE-2 en esta rama, y el panel midió lo que el redactor no midió — `capturas_crudas_de_paso()`, la única función auditada, tiene **0 `do.call`**, y el `do.call(rbind, ...)` que motivó DE-2 vivía en el barrido, que no cruza. La corrección compró un falso positivo inalcanzable pagando un falso negativo alcanzable, que es el peor intercambio posible en una guarda. La segunda: se perdió la corrección de un comentario, y la tabla de equivalencia que el encargo B exigió no podía verla, porque `deparse()` descarta comentarios por construcción.
>
> **Qué hace este encargo.** Tres cosas pequeñas y una que faltaba desde el principio: revertir, restaurar, medir con un método que vea lo que el anterior no veía, y darle a P-100 el arnés versionado que nunca tuvo.

---

## §0. Contrato positivo

### 0.1 Respaldado (medido por el ejecutor y los paneles, sesión 24)

| # | Premisa | Fuente |
|---|---|---|
| R1 | `capturas_crudas_de_paso()`, la única función auditada por la guarda, tiene **0 `do.call`**; el `do.call(rbind, ...)` que motivó DE-2 vive en el barrido, que no cruza a esta rama | panel de B, reproducido por el ejecutor, esta sesión |
| R2 | La corrección de DE-2 introdujo un falso negativo reproducido: la guarda **resuelve** un caso donde la rama A **detenía**, y audita el conjunto equivocado (declara ramas 32–37 cuando el despacho real declara 32–36) | panel de B, reproducido por el ejecutor, esta sesión |
| R3 | Cinco instancias más de la misma clase, todas reproducidas: el prepase entra en cuerpos de `function` mientras el recorrido no; `base::rbind` rechazado como expresión calculada; respaldo posicional de `do.call` con argumentos nombrados; `for`/`assign`/formales invisibles al prepase; `quote(switch(...))` contado como despacho, con un caso silencioso | panel de B, esta sesión |
| R4 | La única pérdida real de la separación son 2 líneas de comentario: `10_utils.R:245` dice `# Default "camara"` sobre una definición que en la 249 ya usa `CRUDO_CAMARA`; la rama A lo tenía corregido | verificación inversa del ejecutor, esta sesión |
| R5 | La tabla de equivalencia de F1.1 comparó definiciones vía `deparse()`, que descarta comentarios: era ciega exactamente donde ocurrió la pérdida, y dio 10/10 | auto-hallazgo del ejecutor, esta sesión |
| R6 | Salvo esas 2 líneas, todo lo que la rama A tiene y la nueva no es cuerpo de P-105 o el código de DE-2 reemplazado a propósito | medición inversa del ejecutor, esta sesión |
| R7 | `localizar_switch()` llegaría a `main` **sin ningún arnés versionado**: nunca existieron pruebas de P-100 en el repositorio. Lo señalan los dos panelistas | panel de B, esta sesión |
| R8 | Las once verificaciones de F1 pasaron: 19/19 formas de AST, 22/22 rutas, 131/131 líneas, 1 242/1 242 md5, 0 red, 0 intrusos, YAML en cero, 0 líneas de barrido en código | F1 de B, esta sesión |
| R9 | El corpus vigente está auditado: 70 archivos trackeados, 68 escanean texto, los 2 de cero caracteres son `.gitkeep` de 0 bytes; razón mediana caracteres/bytes 16,3 | Q2 de B, esta sesión |
| R10 | Q1, Q3 a Q7 contestadas: 0 bytes NUL en los `.txt` trackeados; 0 latin1 y 0 inválidas en 10 186 843 valores; el arnés de A2 tiene 0 referencias a P-100; `digitos_9mas` da 282 coincidencias sobre la mantisa de `tasa_presencia` (problema del patrón en ese alcance) | §5 de B, esta sesión |
| R11 | La rama `fix/encargo-a-derivacion-y-barrido` quedó intacta en `ff71730`, local y remoto | F3 de B, esta sesión |

### 0.2 Hipótesis (se resuelven en F0)

| # | Hipótesis | Dónde |
|---|---|---|
| H1 | Las dos ramas siguen donde el reporte de B las dejó (`885fc55` y `ff71730`), `main` en `37e571c`, sin divergencia | F0.1 |
| H2 | El estado de `localizar_switch()` en la rama A es transportable byte a byte a la rama nueva sin arrastrar nada de P-105 | F0.2 |
| H3 | Revertir DE-2 mata las seis instancias (R2 y R3) de una vez, porque las seis nacieron del prepase | F0.3 |
| H4 | Las 2 líneas de R4 son la única diferencia de comentarios entre las funciones que cruzan | F0.4 |

**Si H3 es falsa** (alguna de las seis sobrevive a la reversión, o existía ya en la rama A), **repórtala por separado**: sería un defecto heredado de A2 y no una consecuencia de la corrección de B, y su tratamiento es distinto.

---

## §1. Encabezado de contrato

**Modo:** autónomo, secuencial, todo en este turno.

**Regla de detención (los únicos tres casos):** (a) un invariante 🔒 te obligaría a violarlo; (b) un dato real contradice una premisa de §0.1; (c) un gate marcado como decisión del titular.

**ENTORNO:** filesystem local vía Claude Code. Raíz: `/Users/tomgc/Projects/transparencia_legislativa_chile`.

**POSICIÓN:** ningún comando asume `cd`. `git` con `-C /Users/tomgc/Projects/transparencia_legislativa_chile`; `gh` con `-R tomgc/transparencia_legislativa_chile` salvo `gh api`.

---

## §2. Contexto mínimo suficiente

La guarda de P-93 audita `capturas_crudas_de_paso()` leyendo su árbol sintáctico. El encargo B le pidió al ejecutor cerrar un falso positivo (DE-2) sin haber medido si ese falso positivo era alcanzable desde la función auditada. No lo es. El código que resultó cambia un fallo ruidoso e imposible por un silencio posible, y el silencio de una guarda es su único modo de fallo que nadie ve.

La reversión es la corrección. No hay que diseñar nada nuevo: hay que volver a un estado que dos paneles ya verificaron y agregarle lo que le faltaba desde el principio.

---

## §3. Invariantes (🔒)

- 🔒 **La rama `fix/encargo-a-derivacion-y-barrido` no se toca, no se rebasea y no se borra.**
- 🔒 **Nada de P-105 entra.** Ni función, ni patrones, ni paso del YAML, ni comentarios.
- 🔒 **El YAML no se modifica.** `git diff main -- .github/workflows/refresh-semanal.yml` en cero.
- 🔒 **Ningún comentario nuevo afirma una propiedad que este encargo no midió.** En particular, ninguno puede decir que DE-2 es inalcanzable: hoy lo es, y eso depende de código futuro.
- 🔒 P-101 y P-102 no se tocan: pasaron tres revisiones.
- 🔒 `sellar()`, `leer_sellado()` y `validar_corte()` no se tocan.
- 🔒 `10_utils/10_utils.R` no adquiere dependencias de paquetes. El arnés tampoco.
- 🔒 **No mergees ningún PR** ni hagas push a `main`. **Ninguna descarga**, ninguna corrida del workflow.
- 🔒 R es el único lenguaje para medir o contar. `bash` sólo para `git`, `gh` y `Rscript`.
- 🔒 `git add` siempre con ruta acotada; nunca `git add .` ni `git add -A`.
- 🔒 Ninguna cifra se reporta sin recontarla programáticamente en el mismo bloque que la reporta.
- 🔒 `50_documentacion/traspasos/paquete_cierre_v23.md`, sin trackear, no se toca ni se commitea.

---

## §4. Las cuatro decisiones (son del redactor, no tuyas)

### 4.1 DE-2 se revierte; no se vuelve a corregir

`localizar_switch()` vuelve **byte a byte** al estado de la rama A (`ff71730`). No es un rediseño ni una tercera versión: es el estado que dos paneles verificaron, menos el prepase que el encargo B introdujo.

**La prueba de que la reversión está completa** es que las seis instancias (R2, R3) dejan de reproducirse, cada una con su antes y su después, y que el caso de R2 vuelve a **detener** en vez de resolver.

### 4.2 DE-2 queda registrado, y el código calla sobre él

DE-2 es un falso positivo que **falla ruidosamente** y que hoy es inalcanzable desde la función auditada (R1). Ésa es la dirección correcta de fallo para una guarda: detenerse ante algo que no entiende es su trabajo.

Se registra como pendiente en el log y en el PR, con el número que corresponda al backlog. **No se escribe ningún comentario en el código que afirme que es inalcanzable**, porque esa propiedad depende de que `capturas_crudas_de_paso()` no adquiera un `do.call` mañana, y un comentario que afirma lo que no puede saber es exactamente la clase E4/E2 que esta sesión lleva tres rondas produciendo.

### 4.3 La equivalencia se mide con un método que vea los comentarios

`deparse()` los descarta (R5). El método nuevo compara el **texto fuente** de cada función: `parse(keep.source = TRUE)` con `getParseData()`, o extracción directa del rango de líneas por `srcref`, y hash del texto normalizado sólo en espacios en blanco de borde.

**Corre el método viejo al lado**, sobre el mismo par de estados, y muestra que da 10/10 mientras el nuevo detecta la diferencia. Es el control negativo del propio método: sin él, el reporte afirma que la medición mejoró sin haberlo demostrado.

Y aplica el método al **archivo completo**, no sólo a las funciones que cruzan: la pérdida de R4 fue en una línea de comentario adyacente a una definición, no dentro de ella.

### 4.4 P-100 sale con arnés versionado o no sale

Un archivo de arnés en el repositorio, corrible con `Rscript`, sin dependencias de paquetes, que ejercite como mínimo:

- las **19 formas de AST** de A2, con su resultado esperado declarado en el propio arnés;
- el **fall-through `"32" = ,`** del `switch` real de `capturas_crudas_de_paso()`;
- `tramites[!fuera, , drop = FALSE]` (`37:190`);
- las **condiciones de contorno**: cero llamadas, más de una, `switch` sólo dentro de una `function` anidada (que cuenta como cero y falla ruidosamente, §4.3 del encargo B);
- **los seis casos revertidos** de R2 y R3, con el comportamiento de la rama A como esperado. Son las pruebas de regresión de este encargo: sin ellas, la próxima corrección de DE-2 vuelve a romper lo mismo en silencio.

El arnés **falla con estado distinto de cero** si algún caso no da lo esperado. Un arnés que informa y sale en cero no es un arnés.

Que corra o no en CI **no** se decide en este encargo: se registra como pendiente.

---

## §5. Fases

### F0 — Estado y reproducción

**F0.1 (H1).**

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile fetch --all --prune
git -C /Users/tomgc/Projects/transparencia_legislativa_chile status --porcelain
git -C /Users/tomgc/Projects/transparencia_legislativa_chile log --oneline -3 main
git -C /Users/tomgc/Projects/transparencia_legislativa_chile log --oneline main..fix/p100-p101-p102-derivacion
git -C /Users/tomgc/Projects/transparencia_legislativa_chile log --oneline -1 fix/encargo-a-derivacion-y-barrido
```

**Detente ante divergencia o conflicto.**

**F0.2 (H2).** Extrae el texto de `localizar_switch()` en `ff71730` y verifica que no referencia ningún objeto de P-105. **Detente si lo hace.**

**F0.3 (H3).** Reproduce **las seis instancias** (R2 y R3) sobre la rama actual, con salida literal, **antes de tocar nada**, y comprueba cuáles reproducían ya en la rama A. Es el control negativo de la reversión.

**F0.4 (H4).** Aplica el método de §4.3 al archivo completo entre las dos ramas y reporta **todas** las diferencias de comentario, no sólo las 2 conocidas.

---

### F1 — La reversión, la restauración y el arnés

Commits atómicos, en la misma rama: reversión de DE-2; restauración del comentario de R4; arnés.

**Verificación, con salida literal:**

1. **Las seis instancias muertas**, con antes y después, y el caso de R2 volviendo a detener.
2. **`localizar_switch()` idéntico byte a byte** al de `ff71730`, por el método de §4.3.
3. **El método viejo al lado del nuevo** (§4.3), demostrando la ceguera del primero.
4. **Diferencias de comentario en cero** entre las dos ramas, para los objetos que cruzan.
5. **Los cuatro defectos originales, todavía muertos**: fall-through `"32" = ,` en el `switch` real y `tramites[!fuera, , drop = FALSE]`.
6. **Las 19 formas de AST**, ahora desde el arnés versionado.
7. **El arnés falla cuando debe:** rompe deliberadamente un caso esperado y comprueba que sale con estado distinto de cero nombrándolo.
8. **Control conocido-bueno completo:** `run_all()`, stdout y stderr contra `main`, md5 de las 1 242 salidas, cache hits, 0 red.
9. **Los cinco escenarios de P-93** y **los tres mensajes de P-101**.
10. **Equivalencia de rutas de P-102**, re-corrida.
11. **YAML en cero** y **0 líneas de barrido en código**, con el `git diff main...` enumerado archivo por archivo.

---

### F2 — Panel adversarial, tercera vuelta

Dos panelistas independientes, en worktrees separados, sin tu reporte ni tus logs.

**Control negativo, triple, y sin él su veredicto no cuenta:**
- los cuatro defectos originales sobre `b897ec4`;
- el falso negativo de R2 sobre `885fc55`;
- la ceguera de `deparse()` frente al comentario de R4.

**Su pregunta central:** ¿queda alguna diferencia entre `localizar_switch()` en esta rama y en la rama A, de cualquier naturaleza, incluidos comentarios y espacios significativos? Que lo contesten con su propia medición.

Además, cada panelista intenta **una forma de AST propia** contra el localizador y **un caso propio** contra el arnés, y reporta si el arnés lo cubre.

Veredicto por panelista: PASA / NO PASA, con desacuerdos explícitos. **Discordancia o NO PASA ⇒ detente y reporta, sin arreglar sobre la marcha.**

---

### F3 — Log, PR y cierre

Amplía `50_documentacion/andamios/logs/<AAAAMMDD de hoy>_encargo_b_separacion_log.md` con la ronda B2 (no crees log nuevo: es el mismo trabajo). Commit acotado, push.

**Con PASA concordante:** PR único contra `main` con P-100, P-101 y P-102, citando: el antes/después de las seis instancias, la equivalencia por el método nuevo con el viejo al lado, el arnés y su prueba de fallo, y los dos veredictos con su control negativo triple. En el cuerpo del PR, **la lista de pendientes que viajan con él**: DE-2 como falso positivo ruidoso e inalcanzable hoy, el arnés sin correr en CI, el comentario `# subdir = "senado"` de `37:254`, y `formals()` de literal a símbolo.

**No mergees:** gate del titular.

**Con cualquier NO PASA:** no abras PR. Reporta.

Árbol como lo encontraste, con el único `?? paquete_cierre_v23.md`. La rama A intacta en `ff71730`.

---

## §6. Auto-auditoría antes de reportar

1. Toda cifra proviene de un bloque de R ejecutado en esta corrida.
2. ¿Queda alguna diferencia entre `localizar_switch()` aquí y en `ff71730`? Contéstalo con el método de §4.3, no con `deparse()`.
3. ¿Algún comentario que este encargo escribe afirma una propiedad que no midió? Cítalos todos, literales (🔒).
4. ¿El arnés cubre las seis instancias revertidas? Enumera caso por caso, no lo afirmes en bloque.
5. ¿Qué encuentra el arnés si mañana alguien vuelve a introducir el prepase? Contéstalo corriéndolo contra `885fc55`, no de memoria.

---

## §7. Reporte final al chat

1. F0.1 a F0.4, crudas, con las seis instancias reproducidas antes de tocar nada.
2. La equivalencia por el método nuevo, con el viejo al lado.
3. Las once verificaciones de F1.
4. Veredicto del panel por panelista, con su control negativo triple.
5. `git diff main...` enumerado, archivo por archivo, con cada uno justificado.
6. Hashes, número del PR si lo hubo, ruta del log, y confirmación de que la rama A quedó en `ff71730`.
7. Pendientes abiertos, incluidos los que viajan en el cuerpo del PR, y marcas `# REVISAR`.
