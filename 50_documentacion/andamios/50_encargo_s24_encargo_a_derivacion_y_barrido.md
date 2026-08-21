# Encargo autónomo — Encargo A: derivar lo que ya está declarado, y una compuerta que mire el contenido

> **Destino:** `50_documentacion/andamios/50_encargo_s24_encargo_a_derivacion_y_barrido.md`
> **Redactor:** asistente de análisis (Claude conversacional), sesión 24.
> **Ejecutor:** Claude Code, modo autónomo.
> **Cubre:** P-100, P-101, P-102 y P-105. Un solo PR, un solo panel adversarial.
>
> **Por qué van juntos.** P-100, P-101 y P-102 son el mismo defecto en tres sitios: un dato que el programa ya tiene, vuelto a escribir a mano. Los tres viven en la vecindad de `regenerar_intermedios_si_desalineados()` y `capturas_crudas_de_paso()`, así que separarlos obliga a revisar el mismo diff tres veces. P-105 entra porque toca la compuerta del job que P-99 acaba de instalar en `.github/workflows/refresh-semanal.yml`: hacerlo aparte significa un segundo panel sobre el mismo archivo, dos semanas después, con el contexto perdido.
>
> **Por qué el panel es uno y con foco.** P-100 invalida el veredicto del panel de P-93 sobre `verificar_registro_pasos()`, porque lo que ese panel aprobó es exactamente el código que este encargo cambia. El panel de aquí cubre los cuatro pendientes, pero su foco declarado es P-100: si la guarda degrada, `run_all()` se detiene en su entrada y con ella el cron.

---

## §0. Contrato positivo

### 0.1 Respaldado (medido en la sesión 24)

| # | Premisa | Fuente |
|---|---|---|
| R1 | `DIRECTORIOS_CRUDO <- c("camara", "senado")` vive en `10_utils/10_utils.R:249`, es declaración única en el repo y no incluye `territorio` | F0.3 del encargo de P-99, esta sesión |
| R2 | `reportar_estado_capturas()` (`10_utils.R:422`) **sí** deriva de la constante; `ruta_cache()` (`:239`) usa el literal `"camara"` y la rama del paso 37 de `capturas_crudas_de_paso()` (`:603`) escribe `"senado"` a mano | F0.4 del encargo de P-99, esta sesión |
| R3 | `rutas_versionables_crudo()` existe en `10_utils/10_utils.R`, devuelve `20_insumos/camara 20_insumos/senado`, y el paso de commit del workflow consume su salida (`refresh-semanal.yml:129`) | F1 y F2 del encargo de P-99 y reporte de merge, esta sesión |
| R4 | La compuerta del job valida **rutas**, no contenido: un archivo con datos personales y nombre plausible bajo `camara/` o `senado/` pasa las dos barreras | auto-auditoría §6.3 del encargo de P-99, esta sesión |
| R5 | La corrida real del 2026-08-20 terminó `success` con la guarda de P-93 en silencio en el runner: P-100 no se materializó, pero su modo de fallo sigue latente | F2.4 del encargo de P-99, esta sesión |
| R6 | Sobre `main` mergeado (`37e571c`), `20_insumos/` trackeado tiene camara 63, senado 5, territorio 2 | reporte de merge del ejecutor, esta sesión |
| R7 | La auditoría de gobernanza de P-99 dejó cinco patrones de detección de dato personal calibrados (5/5 señuelos sintéticos y un señuelo inyectado en el dato real detectados), en `50_documentacion/andamios/logs/20260819_auditoria_gobernanza_p99_log.md` §4 | F0.0 del encargo de P-99, esta sesión |

**Ninguno de estos números de línea se hereda.** El merge de #21 y de #20 movió el archivo. Todos los `:NNN` de arriba se re-miden en F0 antes de tocar nada, y el encargo reporta los de hoy.

### 0.2 Hipótesis (se resuelven en F0)

| # | Hipótesis | Comando |
|---|---|---|
| H1 | `main` local está al día con `origin/main`, sin conflicto y sin commits sin publicar | F0.1 |
| H2 | El alcance real de P-102 son **dos** literales de subdirectorio en `10_utils.R` y no cinco en cinco sitios: el inventario del traspaso v23 §11.1 incluye `37_extraer_tramitacion.R:280` y `:440`, que F0.4 de P-99 no midió | F0.2 |
| H3 | Los cinco patrones de R7 están escritos en el log de forma reutilizable (expresiones regulares literales, no prosa), de modo que P-105 los adopta en vez de reinventarlos | F0.3 |
| H4 | El barrido de contenido sobre el corpus vigente completo (68 archivos de crudo, R6) da cero hallazgos y corre en tiempo compatible con un paso de CI | F3.1 |

**Si H3 es falsa** (el log describe los patrones pero no los deja en forma ejecutable), **no los reconstruyas de memoria**: extráelos del arnés que la corrida de P-99 usó si sigue en el árbol, y si no está, **detente y reporta**. Un arnés de detección reconstruido de oído es el caso exacto de A106.

---

## §1. Encabezado de contrato

**Modo:** autónomo, secuencial, todo en este turno.

**Regla de detención (los únicos tres casos):** (a) un invariante 🔒 te obligaría a violarlo; (b) un dato real contradice una premisa de §0.1; (c) un gate marcado como decisión del titular.

**ENTORNO:** filesystem local vía Claude Code. Raíz: `/Users/tomgc/Projects/transparencia_legislativa_chile`.

**POSICIÓN:** ningún comando asume `cd`. `git` con `-C /Users/tomgc/Projects/transparencia_legislativa_chile`; `gh` con `-R tomgc/transparencia_legislativa_chile` salvo `gh api`, que no acepta `-R`.

---

## §2. Contexto mínimo suficiente

P-99 dejó el workflow preguntándole a R qué rutas versionar. Quedaron tres sitios donde el mismo dato sigue escrito a mano (P-101, P-102) y una guarda que lee el código que audita por posición sintáctica (P-100). Y quedó una pregunta que la compuerta nueva no contesta: valida que ninguna ruta intrusa entre, pero no mira lo que hay dentro de las rutas legítimas (P-105).

Los cuatro son el mismo tipo de trabajo: hacer que el programa use lo que ya sabe, en vez de repetirlo, y cerrar el hueco que queda cuando la verificación se hace por nombre y no por contenido.

---

## §3. Invariantes (🔒)

- 🔒 `sellar()`, `leer_sellado()` y `validar_corte()` no se tocan.
- 🔒 `10_utils/10_utils.R` **no adquiere dependencias de paquetes**. Los patrones de P-105 son expresiones regulares de R base.
- 🔒 **No mergees ningún PR** ni hagas push a `main`. Todo vive en la rama de este encargo.
- 🔒 Ninguna captura cruda ya escrita se modifica ni se borra. El barrido de P-105 **lee**; no reescribe, no redacta, no mueve nada.
- 🔒 `DIRECTORIOS_CRUDO` no cambia de contenido. Este encargo la consume; no la amplía.
- 🔒 `20_insumos/territorio/` sigue fuera de lo que el bot versiona.
- 🔒 R es el único lenguaje para medir o contar. `bash` sólo para `git`, `gh` y `Rscript`.
- 🔒 `git add` siempre con ruta acotada; nunca `git add .` ni `git add -A`, ni en el YAML ni en tus commits.
- 🔒 **Ninguna descarga.** Este encargo no corre el workflow ni toca la red salvo `gh api` de estado y el push de la rama. El corpus para calibrar P-105 es el que ya está versionado.
- 🔒 Ninguna cifra se reporta sin recontarla programáticamente en el mismo bloque que la reporta.
- 🔒 El archivo `50_documentacion/traspasos/paquete_cierre_v23.md`, sin trackear en el árbol, no se toca ni se commitea.

---

## §4. Las cuatro decisiones de metodología (son del redactor, no tuyas)

### 4.1 P-100 — La guarda busca la llamada, no la posición

`verificar_registro_pasos()` localiza el `switch` de `capturas_crudas_de_paso()` con `body(...)[[2]]`, que asume que es la segunda expresión del cuerpo. **Recorre el cuerpo buscando la llamada a `switch`** (recursivamente si hace falta) y opera sobre la que encuentre.

Dos condiciones de contorno que el código nuevo debe resolver explícitamente, no por accidente:
- **ninguna llamada a `switch`** en el cuerpo ⇒ la guarda **falla ruidosamente** nombrando la función, no degrada a silencio. Una guarda que no puede auditar no está diciendo que todo esté bien.
- **más de una** ⇒ también falla, nombrando cuántas encontró. Elegir la primera sería adivinar.

### 4.2 P-101 — El directorio se generaliza donde no se puede derivar

En la segunda coincidencia del literal `20_insumos/camara`, el vector de faltantes está vacío por construcción, así que no hay ruta real de la cual derivar el directorio. **Generaliza a `20_insumos/`**, que es cierto para todos los casos, en vez de nombrar un subdirectorio que puede ser el equivocado. El mensaje de una guarda es parte de su contrato: prefiere ser menos específico a ser específicamente falso.

### 4.3 P-102 — Los literales derivan, y la equivalencia se prueba

Cada literal de subdirectorio pasa a derivarse de `DIRECTORIOS_CRUDO`, por nombre y no por posición en el vector (`DIRECTORIOS_CRUDO[1]` es tan frágil como el literal que reemplaza: usa una constante nominada o un `match.arg()`).

**La prueba no es opcional:** para cada paso del pipeline, la ruta que producía el literal y la que produce la derivación se comparan programáticamente y deben ser idénticas, con la tabla completa en el reporte. Un refactor de rutas que no se prueba por equivalencia es un cambio de comportamiento disfrazado.

### 4.4 P-105 — El barrido es función de R, y el job la llama

**La forma:** una función en `10_utils/10_utils.R` (nombre sugerido, `barrido_datos_personales(rutas)`), que recibe rutas de archivo, las barre con los cinco patrones de R7 y devuelve los hallazgos con archivo, patrón y conteo. El paso del job la invoca sobre el conjunto staged; cualquier hallazgo **mata el job** con `quit(status = 1)` nombrando archivo y patrón, nunca el texto encontrado.

**Por qué función y no bloque en el YAML:** el crudo entra al repositorio por dos caminos, y hasta hoy el que se usó fue el manual (`b4b0bcd`, la única captura del Senado antes de ayer). Una función sirve a los dos; un bloque en el YAML sólo al bot.

**El alcance del barrido son las rutas de crudo, no todo el staged.** Es decir, las que caen bajo `rutas_versionables_crudo()`. Motivo: `40_salidas/json` y `docs/data` son derivados de ese crudo, así que barrer el origen los cubre, y barrer 1 242 archivos derivados en cada corrida compra tiempo de CI sin comprar garantía. **Declara este alcance en el comentario de la función**, para que el próximo lector no crea que el barrido cubre todo lo que se commitea.

**Y se calibra antes de creerle un cero (A106, A108):** cinco señuelos sintéticos, un señuelo inyectado en una copia desechable de un archivo real de crudo, y el volumen barrido (caracteres, no archivos) declarado en el mismo bloque que la cifra de hallazgos. Un cero sin volumen no es un cero.

**Falsos positivos:** si el barrido encuentra algo en el corpus vigente, **detente y reporta**. No ajustes el patrón para que calle: o el hallazgo es real (y es un problema mucho mayor que este encargo), o el patrón está mal y esa es una decisión del titular, no tuya.

---

## §5. Fases

### F0 — Estado y medición

**F0.1 — Punto de partida (H1).**

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile fetch --all --prune
git -C /Users/tomgc/Projects/transparencia_legislativa_chile status --porcelain
git -C /Users/tomgc/Projects/transparencia_legislativa_chile log --oneline origin/main..main
git -C /Users/tomgc/Projects/transparencia_legislativa_chile log --oneline -5
```

Reporta divergencia y árbol. **Detente si hay conflicto o si `main` tiene commits sin publicar** que no sean el `paquete_cierre_v23.md` sin trackear (que no se toca).

**F0.2 — El inventario real de P-102 (H2).** Busca en **todo el árbol de código**, no sólo en las dos funciones ya conocidas, los literales de subdirectorio de crudo:

```bash
grep -rn '"camara"\|"senado"' /Users/tomgc/Projects/transparencia_legislativa_chile/10_utils /Users/tomgc/Projects/transparencia_legislativa_chile/30_scripts /Users/tomgc/Projects/transparencia_legislativa_chile/00_run_all.R
```

Clasifica cada ocurrencia en R: literal que construye una ruta de crudo (entra al encargo), literal de otra naturaleza (glosa, comparación, nombre de columna: no entra), o derivación ya existente. **Reporta la tabla completa con número de línea de hoy** y declara si el alcance de P-102 son dos, cinco u otro número. Si el recuento difiere del traspaso v23, el número de hoy manda y el otro se registra como corregido.

**F0.3 — Los patrones (H3).** Localiza los cinco patrones en `50_documentacion/andamios/logs/20260819_auditoria_gobernanza_p99_log.md` §4 y reporta cada uno **literal**. Si no están en forma ejecutable, aplica la regla de §0.2.

**F0.4 — Re-medición de los sitios.** Números de línea de hoy para `DIRECTORIOS_CRUDO`, `rutas_versionables_crudo()`, `verificar_registro_pasos()`, `regenerar_intermedios_si_desalineados()` y `capturas_crudas_de_paso()`, y la línea del `git add` del workflow.

**Criterio de éxito de F0:** H1 a H3 resueltas con su salida, y el alcance de P-102 fijado por medición de hoy.

---

### F1 — Los tres refactores (P-100, P-101, P-102)

Rama:

```bash
git -C /Users/tomgc/Projects/transparencia_legislativa_chile checkout -b fix/encargo-a-derivacion-y-barrido main
```

Commits atómicos separados, uno por pendiente.

**Verificación obligatoria, antes de pasar a F2:**

1. **Control conocido-bueno de P-93, re-corrido** (el panel anterior queda invalidado por P-100): `run_all()` completo desde la rama, stdout y stderr comparados línea a línea con `main`, 0 llamadas de red. La guarda debe seguir en silencio.
2. **Los cinco escenarios de fallo de P-93**, re-corridos sobre el código nuevo: paso 38 huérfano, paso fantasma, 41, 37, 99. Los cinco deben detener nombrando el elemento.
3. **El escenario que P-100 arregla:** inserta una sentencia antes del `switch` de `capturas_crudas_de_paso()` en un worktree desechable y comprueba que la guarda **sigue en silencio** sobre el pipeline sincronizado (con `main` daba falso positivo). Sin esta prueba, P-100 no está arreglado: está reescrito.
4. **Las dos condiciones de contorno de §4.1:** cuerpo sin `switch` y cuerpo con dos, ambos fallando ruidosamente.
5. **La tabla de equivalencia de P-102** (§4.3), completa.
6. **P-101:** los tres escenarios de mensaje del log de P-93 §4.4 (falta la del 37, falta una de la Cámara, faltan ambas), comprobando que ninguna cadena de subdirectorio escrita a mano sobrevive en `regenerar_intermedios_si_desalineados()`.

---

### F2 — La compuerta de contenido (P-105)

**En `10_utils/10_utils.R`:** la función de §4.4, con los patrones de F0.3, sin dependencias de paquetes, y el comentario que declara su alcance.

**En `.github/workflows/refresh-semanal.yml`:** un paso o bloque que la invoque sobre las rutas staged que caen bajo `rutas_versionables_crudo()`, después de la validación de rutas de P-99 y antes del `git commit`, con `quit(status = 1)` nombrando archivo y patrón. **Nunca imprimas el texto detectado**: un log de CI es público.

**Calibración y pruebas (todas con salida literal en el reporte):**

1. **Cinco señuelos sintéticos**, uno por patrón, cada uno detectado por el suyo.
2. **Un señuelo inyectado en una copia desechable** de un archivo real de crudo, detectado. La copia se borra; el original no se toca (🔒).
3. **Cero hallazgos sobre el corpus vigente completo** (los 68 archivos de crudo de R6, recontados hoy), con **volumen barrido en caracteres** declarado en el mismo bloque y el tiempo de corrida. Si hay hallazgos, **detente** (§4.4).
4. **La compuerta mata el job cuando debe:** en un worktree desechable, staged un archivo bajo `20_insumos/senado/` con un señuelo, y el bloque del YAML extraído literal sale con estado 1 nombrando archivo y patrón.
5. **La compuerta calla cuando debe:** con el conjunto legítimo staged, sale en cero.
6. **Prueba de interacción:** la compuerta de rutas de P-99 y la de contenido conviven sin que una tape a la otra. Un staged con ruta intrusa **y** contenido sucio debe fallar, y el reporte debe decir cuál de las dos habló primero.

**Nota de entorno:** el YAML corre en `bash` en el runner. Si pruebas un bloque extraído en macOS, invoca `bash` explícitamente (`zsh` no hace word splitting y el arnés mentiría). Registrado en el reporte de P-99.

---

### F3 — Panel adversarial

**Obligatorio antes de abrir el PR.** Dos agentes independientes, en worktrees separados, estructuralmente separados del agente que construyó: no reciben tu reporte, no leen tus logs de verificación, reciben el diff y las preguntas.

**Foco declarado: P-100.** Las cuatro pruebas del panel:

1. **Calibración (control negativo):** reconstruido el estado previo al encargo, ¿el panel detecta el falso positivo de P-100? Si un panelista no distingue el código viejo del nuevo, su veredicto sobre el resto no vale.
2. **Silencio:** sobre el pipeline sincronizado, `run_all()` no emite nada de la guarda, y su salida es idéntica a `main`.
3. **Robustez sintáctica:** el panelista intenta romper la localización del `switch` por su cuenta (envolverlo, anidarlo, precederlo, duplicarlo) y reporta si consigue un falso positivo o un falso negativo.
4. **La compuerta de contenido:** el panelista construye su propio señuelo, con un patrón que él elija, y comprueba si pasa. Un arnés que sólo detecta los señuelos de quien lo escribió no es un arnés.

Veredicto por panelista: PASA / NO PASA, con el desacuerdo explícito si lo hay. **Discordancia ⇒ detente y reporta**, sin arreglar sobre la marcha.

---

### F4 — Log, PR y cierre

Log en `50_documentacion/andamios/logs/20260820_encargo_a_derivacion_y_barrido_log.md`, plantilla de `encargo_autonomo_claude_code_v1.md` §4. Commit acotado, push a la rama.

PR único contra `main`, citando: la tabla de equivalencia de P-102, el escenario 3 de F1 (el que demuestra que P-100 está arreglado y no sólo reescrito), el cero con volumen de F2.3, y el veredicto del panel con su calibración.

**No mergees.** Es gate del titular.

Árbol como lo encontraste: `git status --porcelain` con el único `?? paquete_cierre_v23.md` que ya estaba, `git worktree list` en una línea, `git diff --stat HEAD -- 20_insumos` en cero.

---

## §6. Auto-auditoría antes de reportar

1. Toda cifra proviene de un bloque de R ejecutado en esta corrida.
2. El `git diff` no contiene ninguna línea no autorizada por §3 y §4.
3. ¿Queda alguna cadena `"camara"` o `"senado"` construyendo una ruta de crudo en el árbol? Contéstalo con el `grep` de hoy, no de memoria.
4. Si mañana alguien deja un archivo con datos personales bajo `20_insumos/senado/` con nombre plausible, ¿qué lo detiene? Nombra la compuerta y la prueba de F2 que demuestra que funciona.
5. ¿Qué NO cubre el barrido? Dilo explícitamente: es la pregunta que P-105 existía para contestar y su respuesta nueva no puede quedar implícita.

---

## §7. Reporte final al chat

1. F0.1 a F0.4, crudas, con el alcance de P-102 fijado por medición de hoy.
2. `git diff` completo, por archivo.
3. Las verificaciones de F1: control conocido-bueno, cinco escenarios, el escenario 3, las dos condiciones de contorno, la tabla de equivalencia, los tres mensajes de P-101.
4. Las seis pruebas de F2, con salida literal, incluido el cero con volumen en caracteres y tiempo.
5. Veredicto del panel por panelista, con su calibración y sus desacuerdos.
6. Hashes, número del PR, ruta del log.
7. Pendientes abiertos y marcas `# REVISAR`, sin numerar como P-NN.
