# Encargo autónomo — A2: corrección de los cuatro defectos del panel

> **Destino:** `50_documentacion/andamios/50_encargo_s24_encargo_a2_correccion_panel.md`
> **Redactor:** asistente de análisis (Claude conversacional), sesión 24.
> **Ejecutor:** Claude Code, modo autónomo.
> **Continúa** el encargo A (`50_encargo_s24_encargo_a_derivacion_y_barrido.md`), en su misma rama `fix/encargo-a-derivacion-y-barrido`.
>
> **Qué pasó.** El panel de F3 devolvió NO PASA por partida doble, concordante, con control negativo superado, y el ejecutor reprodujo los cuatro defectos por su cuenta antes de reportarlos. Dos de ellos (D1, D2) son **regresiones frente a `main`**: el código nuevo detiene `run_all()` en casos que el viejo auditaba sin problema, y el disparador de D1 ya vive en el repo. P-101 y P-102 pasaron las dos revisiones y **no se tocan**.
>
> **Qué no es este encargo.** No es una segunda oportunidad para el mismo diseño. Los cuatro defectos comparten una raíz: código que ante una entrada que no sabe interpretar elige adivinar o callar, en vez de detenerse. La corrección es esa, y las cuatro decisiones de §4 están tomadas.

---

## §0. Contrato positivo

### 0.1 Respaldado (medido y reproducido por el ejecutor en la sesión 24)

| # | Premisa | Fuente |
|---|---|---|
| R1 | **D1:** `localizar_switch()` (`10_utils.R:738`) muere con `el argumento "hijo" está ausente` ante cualquier símbolo vacío en el AST. El `tryCatch` protege la extracción, que no falla; el error salta al forzar el valor en `is.null(hijo)` | reproducido por el ejecutor, esta sesión |
| R2 | **D1, disparador vivo:** `tramites[!fuera, , drop = FALSE]` en `37_extraer_tramitacion.R:190` produce esa forma. También la produce el fall-through `"32" = ,` del propio `switch` de `capturas_crudas_de_paso()`, que es la forma idiomática de que dos pasos compartan captura | reproducido por el ejecutor, esta sesión |
| R3 | **D2:** `base::switch()` no se reconoce, y el mensaje emitido (*revisa si esa funcion dejo de declarar sus capturas con un switch*) es específicamente falso. `main` audita ese cuerpo sin problema | reproducido por el ejecutor, esta sesión |
| R4 | **D3:** ante UTF-8 inválido, `nchar()` aborta el job sin nombrar el archivo, y `grepl(perl = TRUE)` sobre una cadena inválida devuelve `FALSE`: no la escanea | reproducido por el ejecutor, esta sesión |
| R5 | **D4:** un `.rds` ilegible produce `hallazgos=0 archivos=1 caracteres=0`. "No pude leerlo" es indistinguible de "está limpio" | reproducido por el ejecutor, esta sesión |
| R6 | `distrito` y `region` llegan al JSON publicado en 155 de 155 casos desde `20_insumos/territorio/`, que **no** está en `rutas_versionables_crudo()`: el comentario de cobertura que el encargo A puso en el YAML es más ancho que la cobertura real | verificado por el ejecutor, esta sesión |
| R7 | P-101 y P-102 pasaron las dos revisiones independientes: 28/28 rutas idénticas sobre tres cortes, 0 literales construyendo ruta de crudo | panel de F3 del encargo A, esta sesión |
| R8 | El alcance real de P-102 eran seis literales (no dos ni cinco), ya corregidos | F0.2 del encargo A, esta sesión |
| R9 | El arnés de los cinco patrones vivía en `/tmp/aud_medir2.R`, nunca commiteado, y sobrevivió por casualidad entre sesiones | F0.3 del encargo A, esta sesión |
| R10 | Los cuatro commits de A y su log están en la rama `fix/encargo-a-derivacion-y-barrido`, pusheada, sin PR abierto | F4 del encargo A, esta sesión |

### 0.2 Hipótesis (se resuelven en F0)

| # | Hipótesis | Comando |
|---|---|---|
| H1 | La rama `fix/encargo-a-derivacion-y-barrido` sigue en `b897ec4`, sin divergencia con su remoto, y `main` no se movió por debajo | F0.1 |
| H2 | Los cuatro defectos siguen reproduciéndose hoy sobre esa rama, con los arneses del panel | F0.2 |
| H3 | Ningún otro sitio del árbol construye una ruta de crudo con literal, tras P-102 | F0.3 |

---

## §1. Encabezado de contrato

**Modo:** autónomo, secuencial, todo en este turno.

**Regla de detención (los únicos tres casos):** (a) un invariante 🔒 te obligaría a violarlo; (b) un dato real contradice una premisa de §0.1; (c) un gate marcado como decisión del titular.

**ENTORNO:** filesystem local vía Claude Code. Raíz: `/Users/tomgc/Projects/transparencia_legislativa_chile`.

**POSICIÓN:** ningún comando asume `cd`. `git` con `-C /Users/tomgc/Projects/transparencia_legislativa_chile`; `gh` con `-R tomgc/transparencia_legislativa_chile` salvo `gh api`.

---

## §2. Contexto mínimo suficiente

La guarda de P-93 audita el código del pipeline leyendo su árbol sintáctico. El encargo A cambió cómo localiza el `switch` que declara las capturas, y al hacerlo introdujo dos formas de AST que el localizador no sabe interpretar y ante las cuales muere sin decir quién es ni por qué. Como la guarda corre en la entrada de `run_all()`, eso no degrada un chequeo: detiene el pipeline y con él el cron.

El barrido de dato personal tiene el problema simétrico. Ante un archivo que no puede leer, informa cero hallazgos, que es la respuesta que un archivo limpio también produce. Una compuerta que confunde "no sé" con "está bien" no es una compuerta.

---

## §3. Invariantes (🔒)

- 🔒 **P-101 y P-102 no se tocan.** Pasaron las dos revisiones (R7). Si un cambio de este encargo los roza, se detiene y se reporta.
- 🔒 `sellar()`, `leer_sellado()` y `validar_corte()` no se tocan.
- 🔒 `10_utils/10_utils.R` **no adquiere dependencias de paquetes**.
- 🔒 **No mergees ningún PR** ni hagas push a `main`. Todo vive en la misma rama de A.
- 🔒 Ninguna captura cruda ya escrita se modifica ni se borra. El barrido lee.
- 🔒 `DIRECTORIOS_CRUDO` no cambia de contenido.
- 🔒 R es el único lenguaje. `bash` sólo para `git`, `gh` y `Rscript`.
- 🔒 `git add` siempre con ruta acotada; nunca `git add .` ni `git add -A`.
- 🔒 **Ninguna descarga.** No se corre el workflow. El corpus de calibración es el versionado.
- 🔒 Ningún patrón se ablanda para silenciar un hallazgo.
- 🔒 Ninguna cifra se reporta sin recontarla programáticamente en el mismo bloque que la reporta.
- 🔒 `50_documentacion/traspasos/paquete_cierre_v23.md`, sin trackear, no se toca ni se commitea.

---

## §4. Las cuatro decisiones (son del redactor, no tuyas)

### 4.1 D1 y D2 — El localizador reconoce, y lo que no reconoce lo grita

Tres requisitos, y el tercero es el que importa:

1. **Símbolo vacío detectado por identidad, antes de forzarlo.** `identical(x, quote(expr = ))` o equivalente, evaluado sin que el valor se fuerce. `tryCatch` alrededor de la extracción no sirve, porque la extracción no falla (R1): el error nace después. La prueba de que está resuelto es el fall-through `"32" = ,` del propio `switch` de capturas (R2), no un caso inventado.
2. **`switch` se reconoce en sus tres formas escribibles:** `switch(...)`, `base::switch(...)` y `do.call("switch", ...)` con literal de cadena.
3. **Lo irresoluble se detiene.** `do.call` con una variable, un head que no se puede resolver, cero llamadas encontradas, más de una: **todos fallan ruidosamente**, nombrando la guarda, la función auditada y qué fue lo que no pudo interpretar. Ninguna de esas ramas puede terminar en silencio, y ninguna puede emitir un mensaje que afirme una causa que no midió (R3: el mensaje viejo aseguraba que la función *dejó de declarar sus capturas con un switch*, cuando el `switch` estaba ahí).

**La divergencia del panel la resuelvo aquí, no la delibera nadie más:** un `switch` dentro del cuerpo de una `function` anidada **no** es la declaración de capturas. El localizador **no entra en cuerpos de `function`**. Se prueba en las dos direcciones: un `switch` anidado en una anónima no se toma por la declaración, y si es el único que hay, eso cuenta como cero llamadas y falla ruidosamente.

### 4.2 D3 y D4 — El barrido tiene tres estados, no dos

`barrido_datos_personales()` deja de devolver un conteo y pasa a devolver, por archivo, uno de tres estados: **limpio**, **hallazgos**, **ilegible**. La categoría `ilegible` cubre el archivo que no se puede abrir, el `.rds` que no deserializa, y la cadena con UTF-8 inválido (`validUTF8()` falso), que **no se escanea callando**: se marca.

**El llamador trata `ilegible` como fallo.** El paso del job muere con `quit(status = 1)` nombrando el archivo y el motivo, igual que ante un hallazgo. Es la aplicación directa de la regla del proyecto: un `NA` con más de una causa no puede gobernar el control de flujo.

El reporte de la función declara siempre **volumen barrido en caracteres** y **archivos por estado**, y los tres números tienen que cuadrar con el total de entrada. Un cero sin volumen no es un cero (A108).

### 4.3 R6 — La cobertura declarada es la cobertura real

El comentario que el encargo A puso en el YAML es falso para `distrito` y `region`, que llegan al JSON publicado desde `20_insumos/territorio/` (R6). Es mi error de redacción, no una decisión pendiente del titular.

- **En el YAML:** el comentario dice exactamente qué barre el paso (las rutas de `rutas_versionables_crudo()`) y **qué no** (`20_insumos/territorio/`, que el bot no commitea y que se revisa a mano por D5). Nada más ancho que eso.
- **En la función:** su alcance por defecto para uso local es **todo `20_insumos/`**, territorio incluido, porque el camino manual es por donde entró la única captura del Senado anterior al bot (`b4b0bcd`).

Que el bot no commitee territorio no es lo mismo que que territorio no llegue a producción. Llega.

### 4.4 R9 — El arnés se versiona

Los cinco patrones y su calibración viven en el repositorio, no en `/tmp`. Un archivo de arnés bajo `50_documentacion/andamios/`, con los cinco señuelos sintéticos y el procedimiento de inyección en copia desechable, corrible con `Rscript`. Que §0.2 del encargo A haya dependido de que nadie limpiara el disco es el hallazgo, no el detalle.

---

## §5. Fases

### F0 — Estado y reproducción

**F0.1 — Punto de partida (H1).**

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile fetch --all --prune
git -C /Users/tomgc/Projects/transparencia_legislativa_chile status --porcelain
git -C /Users/tomgc/Projects/transparencia_legislativa_chile log --oneline -6
git -C /Users/tomgc/Projects/transparencia_legislativa_chile log --oneline main..fix/encargo-a-derivacion-y-barrido
```

Confirma la rama, su HEAD, y que `main` no se movió. **Detente ante divergencia o conflicto.**

**F0.2 — Los cuatro defectos, hoy (H2).** Reprodúcelos sobre la rama, uno por uno, con salida literal, **antes de tocar código**. Este es el control negativo de tus propias correcciones: sin él no puedes demostrar después que arreglaste algo.

**F0.3 — El estado de lo que sobrevive (H3).** `grep` de literales de crudo en todo el árbol, clasificado en R. Debe dar cero construyendo ruta. Reporta también el comentario obsoleto `# Default "camara"` (`10_utils.R:245` en la medición de A) para corregirlo con el resto.

---

### F1 — Las correcciones

Commits atómicos, en la misma rama, uno por decisión de §4.

**Verificación, con salida literal:**

1. **Los cuatro defectos, muertos:** cada arnés de F0.2 re-corrido sobre el código nuevo, con el antes y el después uno junto al otro.
2. **El fall-through real:** `"32" = ,` en el `switch` de capturas, auditado sin error. No un caso equivalente: ése.
3. **`tramites[!fuera, , drop = FALSE]`** (`37:190`) auditado sin error.
4. **Las tres formas de `switch`** reconocidas, y las cuatro formas irresolubles de §4.1.3 fallando ruidosamente con su mensaje.
5. **La anónima anidada, en las dos direcciones** (§4.1).
6. **Los tres estados del barrido**, con un caso construido para cada uno: `.rds` ilegible, UTF-8 inválido, archivo limpio. Los tres estados cuadran con el total.
7. **La compuerta mata el job ante `ilegible`**, con el bloque del YAML extraído literal y ejecutado bajo `bash` (no `zsh`).
8. **No regresión:** control conocido-bueno completo (`run_all()`, stdout y stderr comparados con `main`, 0 red, md5 de salidas), los cinco escenarios de P-93, y los tres mensajes de P-101. La guarda en silencio sobre el pipeline sincronizado.
9. **P-101 y P-102 intactos:** `git diff` de los commits de este encargo no toca sus líneas (🔒).
10. **Barrido sobre el corpus vigente**, ahora incluyendo `20_insumos/territorio/`: hallazgos, estados y volumen en caracteres. Si hay hallazgos, **detente**.

---

### F2 — Panel adversarial, segunda vuelta

**Obligatorio.** Dos panelistas independientes, en worktrees separados, sin tu reporte y sin tus logs.

**Su control negativo son los cuatro defectos de F0.2:** un panelista que no los reproduce sobre el estado previo no está calibrado y su veredicto no cuenta. Dilo en su encargo.

Además de verificar las correcciones, cada panelista debe intentar **una forma de AST propia** que el localizador no haya visto, y **un señuelo propio y un archivo ilegible propios** contra el barrido. Un arnés que sólo resiste lo que su autor imaginó no es un arnés (es lo que este mismo encargo está corrigiendo).

Veredicto por panelista: PASA / NO PASA, con el desacuerdo explícito. **Discordancia o NO PASA ⇒ detente y reporta, sin arreglar sobre la marcha.**

---

### F3 — Log, PR y cierre

Amplía `50_documentacion/andamios/logs/20260820_encargo_a_derivacion_y_barrido_log.md` con una sección de esta ronda (no crees un log nuevo: es el mismo trabajo). Commit acotado, push.

**Con PASA concordante:** abre el PR único contra `main`, citando el antes/después de los cuatro defectos, el cero con volumen y estados de F1.10, y los dos veredictos con su calibración. **No mergees:** gate del titular.

**Con cualquier NO PASA:** no abras PR. Reporta.

Árbol como lo encontraste, con el único `?? paquete_cierre_v23.md`.

---

## §6. Auto-auditoría antes de reportar

1. Toda cifra proviene de un bloque de R ejecutado en esta corrida.
2. ¿Queda alguna rama del localizador que pueda terminar en silencio o emitir una causa que no midió? Recórrelas una por una y contéstalo por enumeración, no de memoria.
3. ¿Queda alguna entrada que el barrido no pueda leer y reporte como limpia? Idem.
4. El comentario del YAML, ¿describe la cobertura que las pruebas de F1.10 demuestran, ni más ancha ni más angosta? Cítalo literal junto a la medición.
5. ¿Tocaste alguna línea de P-101 o P-102? Contéstalo con `git diff`.

---

## §7. Reporte final al chat

1. F0.1 a F0.3, crudas, con los cuatro defectos reproducidos antes de tocar nada.
2. `git diff` completo de esta ronda, por archivo.
3. Las diez verificaciones de F1, con antes y después.
4. Veredicto del panel por panelista, con su calibración sobre los cuatro defectos y sus formas propias.
5. Hashes, número del PR si lo hubo, ruta del log.
6. Pendientes abiertos y marcas `# REVISAR`, sin numerar como P-NN.
