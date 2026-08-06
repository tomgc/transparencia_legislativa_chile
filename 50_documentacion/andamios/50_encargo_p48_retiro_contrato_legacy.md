# Encargo autónomo — P-48: retiro del contrato legacy de asistencia

> **Proyecto:** `transparencia_legislativa_chile` · **Sesión 15** · 2026-08-03
> **Patrón:** encargo autónomo dirigido por meta
> (`herramientas_dev/prompts/encargo_autonomo_claude_code_v1.md`, v1.1).
> **Redactor:** Claude conversacional. **Ejecutor:** Claude Code, modo autónomo.

---

## 1. Encabezado de contrato

### 1.1 Modo y disciplina

Modo autónomo, secuencial. Ejecuta **todas las fases posibles en este turno**, en
el orden estricto de la sección 4, sin pedir confirmación entre fases: la ruta ya
está aprobada por el titular. El titular **no está disponible en terminal durante
la ejecución**; todo lo que dependa de una respuesta suya se difiere, no se
adivina.

### 1.2 Regla de detención

Detente y reporta (sin revertir lo ya commiteado) SOLO si:

- **(a)** cumplir una instrucción de este encargo te obligaría a cruzar un 🔒 de
  la sección 3;
- **(b)** un dato real contradice una premisa de hecho de este encargo (están
  todas marcadas y son verificables; la sección 2.4 lista las que debes
  comprobar en la Fase 0);
- **(c)** llegas a un gate marcado **[GATE-TITULAR]**.

En los tres casos: deja el árbol en estado consistente, escribe el log parcial
(sección 6) y reporta. No improvises metodología, no inventes un supuesto de
reemplazo, no sigas "por aproximación".

### 1.3 Reglas canónicas heredadas (no se re-explican, se cumplen)

- **R es el único lenguaje.** Toda inspección de artefactos de datos (`.rds`,
  `.json`) se hace en R. Prohibido `jq`, `awk`, `python`, y prohibido `grep` /
  `sed` sobre artefactos de datos. Sobre archivos de **código fuente** puedes usar
  las herramientas de búsqueda del entorno.
- **Rutas absolutas siempre.** Todo comando de git lleva
  `git -C /Users/tomgc/Projects/transparencia_legislativa_chile`. Todo subcomando
  de `gh` que actúe sobre el repositorio lleva
  `-R tomgc/transparencia_legislativa_chile` (aprendizaje A51). Ningún comando
  asume `cd` previo ni estado de terminal heredado.
- **Prohibido `gh pr diff --name-only`** en este repositorio (A45): devuelve HTTP
  406 sobre PRs grandes y deja un `grep -c` contando sobre vacío, o sea un verde
  falso. Usa la API paginada de `/pulls/<n>/files` y declara el denominador.
- **`git add` siempre con ruta acotada.** Nunca `git add .` ni `git add -A`.
- **Sin fechas hardcodeadas.** Todo valor de corte se lee de
  `/Users/tomgc/Projects/transparencia_legislativa_chile/10_utils/10_configuracion.R`
  o de la API; jamás se escribe a mano.
- **Antes de cualquier corrida local, regenerar 32–36** (aprendizaje A34). No
  corras el 39 sobre intermedios de otra corrida.
- **Marcador de fuente en línea** (POLITICA §0.6) en el log: toda cifra que
  reportes lleva, en la misma línea, el comando o archivo del que salió, contado
  programáticamente en ese momento. Una cifra derivada de memoria o de aritmética
  mental no es una cifra.

### 1.4 Contrato de entorno

1. **ENTORNO:** filesystem local del titular vía Claude Code, en
   `/Users/tomgc/Projects/transparencia_legislativa_chile`. Hay red (API de la
   Cámara y GitHub), `gh` autenticado, R 4.5.2.
2. **INSUMOS:** todos los archivos que necesitas ya están en ese filesystem, en
   las rutas que este encargo declara. No hay ningún insumo "que se pasa aparte":
   si una ruta declarada no existe, es el caso (b) de la regla de detención.
3. **POSICIÓN:** toda ruta va completa desde
   `/Users/tomgc/Projects/transparencia_legislativa_chile`.

---

## 2. Contexto mínimo suficiente

### 2.1 Qué es el proyecto

Portal serverless de transparencia legislativa de la Cámara de Diputados de Chile
(155 diputados). Scripts en R consolidan la API pública en JSON estáticos que
consume un `docs/index.html` de una sola pieza, servido por GitHub Pages desde
`/docs`. No hay backend.

### 2.2 Los archivos que este encargo toca

| Ruta (desde la raíz) | Rol |
|---|---|
| `30_procesamiento/33_extraer_asistencia.R` | Extrae asistencia. Hoy tiene DOS bloques: bloque 1 legacy (agregado por diputado) y bloque 2 nominal (Capa 3). Se retira el bloque 1 |
| `30_procesamiento/39_consolidar_json.R` | Consolida los JSON publicados. Se retiran de su salida los campos legacy |
| `docs/index.html` | Frontend. Solo se corrige una glosa en prosa (L511), ningún consumo de dato |
| `10_utils/10_diff_conteos.R` | Insumo del gate de conteos del bot. **Lectura obligatoria** en Fase 0: si referencia campos que se retiran, hay que adaptarlo en la misma fase |
| `00_run_all.R` | Orquestador. Verificar si nombra `asistencia.rds` |
| `.github/workflows/` | Workflow del refresh semanal. **Solo lectura** en este encargo |

### 2.3 Qué se hizo antes (por qué este pendiente está maduro)

La Capa 3 de asistencia (serie nominal por sesión, con justificación y dos ámbitos
temporales) está publicada en el JSON desde la sesión 11. En la sesión 14 el
frontend migró a ella: el titular de asistencia del portal pasó a ser
`asistencia.periodo_vigente.tasa_presencia` (decisión D18) y el índice ordena por
`tasa_presencia`. Desde el commit `f55430d`, **ningún consumidor lee el contrato
legacy**. Ese era el único bloqueo de este pendiente.

### 2.4 Premisas de hecho, todas verificables (compruébalas en la Fase 0)

Estas premisas vienen de una medición corrida en esta sesión sobre el filesystem
del titular (`50_documentacion/andamios/50_medicion_p48_p52_p56.R`). Son la base
del encargo. **Si alguna es falsa, es el caso (b) de detención.**

1. `docs/index.html` no consume ninguno de los campos legacy: sus 10 ocurrencias
   de `n_asiste` / `n_no_asiste` / `n_sesiones` son sobre los objetos `pv` y `ej`
   (Capa 3), salvo **L511, que es prosa** y menciona `tasa_asistencia` para
   explicar la verificación de la sesión 14.
2. Los únicos archivos de **código** que nombran el contrato legacy son
   `30_procesamiento/33_extraer_asistencia.R` y
   `30_procesamiento/39_consolidar_json.R`. El resto de las 230 ocurrencias vive
   en traspasos, logs y escáneres, que son **registro histórico congelado y NO se
   editan**.
3. `10_utils/10_diff_conteos.R` **no** apareció entre los archivos con
   ocurrencias. Verifícalo leyéndolo entero de todos modos: la medición buscó
   nombres de campo, no la lógica del gate.
4. El `+0` de todos los conteos entre el corte del 25 y el del 27 es real, no una
   anomalía de captura: los siete cachés de ambos cortes son idénticos por `md5` y
   el nominal da 69 sesiones con `fecha_ultima = 2026-07-22` en los dos. **P-56
   queda cerrado con esto**; no lo re-investigues, solo regístralo en el log.

---

## 3. Invariantes (🔒)

- 🔒 **`main` no recibe escrituras directas de esta ejecución.** Todo el trabajo
  va a una rama y termina en un PR abierto, sin mergear. El merge es del titular.
- 🔒 **No mergees ningún PR**, ni el tuyo ni uno del bot. Hoy es lunes y el cron
  del bot corre los lunes: es posible que haya un PR `refresh/<corte>` abierto.
  Mergearlo exige leer su resumen de conteos y es decisión del titular.
- 🔒 **No dispares el workflow** por `workflow_dispatch` ni por ningún otro medio.
- 🔒 **`sin_registro` no se imputa**, ni en el dato ni en la presentación. Sigue
  siendo un tercer estado, nunca se pliega a "no asiste".
- 🔒 **`RebajaAsistencia` / `RebajaQuorum` se persisten pero no entran en ninguna
  fórmula ni en ningún conteo.** Su semántica reglamentaria no está documentada
  (pendiente P2). Este encargo no los toca.
- 🔒 **Ningún campo sobreviviente cambia de valor.** El retiro es una sustracción
  pura: los campos de Capa 3 (`alcance_temporal`, `periodo_vigente`,
  `en_ejercicio`, `sesiones[]`) y los bloques `perfil`, `votaciones`, `proyectos`
  deben quedar idénticos, valor a valor. La Fase 5 lo verifica y **condiciona el
  PR**.
- 🔒 **El gate de conteos del workflow, el commit condicional y la protección de
  escritura de `main` son intocables.** Si el retiro obliga a adaptar
  `10_diff_conteos.R`, se adapta su *lista de métricas*, nunca su condición de
  aborto.
- 🔒 **La numeración del backlog nunca se renumera ni se reescribe.** Este encargo
  no toca `50_documentacion/activa/backlog_acumulativo.md`: el backlog lo edita el
  asistente conversacional al cierre.
- 🔒 **No edites traspasos, logs ni escáneres.** Son andamios congelados.

---

## 4. Fases, en orden estricto

Cada fase: leer estado real → implementar → verificar con un chequeo observable →
commit atómico. **La verificación va entre la generación y el commit y lo
condiciona:** si el resultado esperado no se cumple, no commitees esa fase,
detente y reporta.

Todos los commits van a la rama de la Fase 0. Formato de mensaje: prefijo
convencional (`refactor:`, `fix:`, `docs:`, `chore:`) + una línea de qué hizo.

---

### Fase 0 — Estado real, rama de trabajo y comprobación de premisas

**Objetivo:** partir de un estado leído, no supuesto, y dejar la rama creada.

1. `git -C <raíz> fetch --all --prune` y luego `git -C <raíz> status -sb`. Declara
   en el log la rama actual, el estado respecto de `origin/main` y el árbol sucio.
2. Lee `10_utils/10_configuracion.R` completo. **Declara el valor de
   `CORTE_FECHA` citando el archivo.** Todo lo que sigue usa ese valor; no lo
   escribas a mano en ninguna parte.
3. Comprueba si existen los cachés de ese corte en `20_insumos/camara/` (patrón
   `<AAAAMMDD>_*.rds`, con la fecha derivada de `CORTE_FECHA`). Si existen, las
   regeneraciones de este encargo **no golpean la API**. Si NO existen, la
   corrida descargará desde la API y tomará varios minutos: está permitido,
   pero **decláralo en el log** antes de correr.
4. `gh -R tomgc/transparencia_legislativa_chile pr list --state open`. Si hay un
   PR del bot abierto: **no lo toques** (🔒), y anótalo en el log como condición
   heredada para el titular.
5. Si el árbol tiene cambios sin commitear que no sean del escáner ni de
   `.claude/`, **[GATE-TITULAR]**: detente y reporta; no vas a construir encima de
   trabajo ajeno sin que él lo vea.
6. Crea la rama desde `origin/main` actualizado:
   `git -C <raíz> switch -c retiro/contrato-legacy-asistencia origin/main`.
7. **Comprueba las cuatro premisas de la sección 2.4**, cada una por lectura
   directa, y registra el resultado en el log. En particular, lee entero
   `10_utils/10_diff_conteos.R` y entero el workflow de `.github/workflows/`, y
   determina si alguno de los dos depende de los campos que se van a retirar.
8. **Verifica Pages** (esto cierra la prioridad 1 de la sesión, que el titular no
   pudo comprobar): descarga con `curl` el `index.html` publicado y el
   `docs/index.html` del árbol en `origin/main`, y compara sus hashes en R. Si
   coinciden, Pages republicó. Si no, reporta la diferencia (no es bloqueante para
   el resto del encargo; es información).

**Criterio de éxito:** la rama existe, `CORTE_FECHA` está declarado con su fuente,
las cuatro premisas están comprobadas y el veredicto de Pages está registrado.
**Sin commit** (esta fase no modifica archivos).

---

### Fase 1 — Línea base del JSON publicado (antes de tocar nada)

**Objetivo:** congelar la salida actual para poder probar, después, que el retiro
no cambió ningún valor sobreviviente. Sin esta base, la invariante 🔒 de "ningún
campo sobreviviente cambia" no es verificable.

1. Regenera desde cero, en orden, con R y desde la raíz del proyecto: `32`, `33`,
   `34`, `35`, `36`, `39` (aprendizaje A34; el orquestador `00_run_all.R` sirve si
   hace exactamente eso, léelo antes de usarlo).
2. Copia la salida recién generada a un directorio **fuera del repositorio**
   (por ejemplo `/tmp/p48_base/`): `40_salidas/json/indice_diputados.json` y
   `40_salidas/json/perfiles/`. **No** la commitees, **no** la dejes dentro del
   árbol de trabajo.
3. Verifica que la regeneración no cambió nada respecto de lo publicado:
   `git -C <raíz> status --porcelain -- docs/ 40_salidas/json/`. Lo esperado es
   **salida vacía**, porque estás regenerando el mismo corte con los mismos
   cachés. Si hay diferencias, **detente y reporta**: significa que la salida
   publicada no es reproducible desde el estado actual, que es un hallazgo mayor y
   cambia el encargo.

**Criterio de éxito:** `git status` limpio en `docs/` y `40_salidas/json/`, y la
base copiada fuera del repositorio con 1 índice + 155 perfiles (cuenta los
archivos programáticamente y declara el número). **Sin commit.**

---

### Fase 2 — Retiro del contrato legacy en `39_consolidar_json.R`

**Objetivo:** que los campos legacy desaparezcan del JSON publicado.

**Qué se retira, exhaustivamente:**

- Del bloque `asistencia` de cada perfil: `anio`, `n_sesiones`, `n_asiste`,
  `n_no_asiste`, `tasa_asistencia`. El bloque queda con `alcance_temporal`,
  `periodo_vigente`, `en_ejercicio` y `sesiones`.
  - `anio` se retira porque su valor ya viaja en
    `asistencia.alcance_temporal.anio_proceso`, con ámbito declarado. No se pierde
    información.
- De `indice_diputados.json`: el campo `tasa_asistencia`. `tasa_presencia` se
  queda y pasa a ser el único indicador de asistencia del índice.
- Del código del `39`: la lectura del intermedio `asistencia` (`leer("asistencia")`),
  su `stopifnot` de llave `character`, su llamada a `cobertura()`, el
  `resumen_asistencia` y su `left_join`. Deja de existir la variable `asistencia`
  en el script.
- **Ojo con `validar_corte()`**: recibe la lista de sellos de los intermedios
  leídos. Al leer uno menos, la lista pasa de 7 a 6 elementos. Comprueba leyendo
  `10_utils/10_utils.R` que `validar_corte()` no espera un número fijo de sellos
  ni un nombre de archivo concreto. Si lo espera, adáptalo con el mismo criterio
  (falla ruidosa, nunca silenciosa) y decláralo en el log.

**Qué NO se toca en esta fase:** el `33`. La separación es deliberada: esta fase
prueba el cambio de contrato con el resto del pipeline igual, y la siguiente
prueba que retirar la descarga duplicada no altera el resultado.

**Verificación (antes del commit):**

1. Corre solo el `39` (los intermedios de la Fase 1 siguen vigentes).
2. En R, sobre la salida nueva: comprueba que en los 155 perfiles el bloque
   `asistencia` **no** contiene ninguno de los cinco nombres retirados, y que el
   índice **no** contiene `tasa_asistencia`. Cuenta y declara: perfiles
   inspeccionados, perfiles con algún campo residual (esperado: 0).
3. En R, compara contra la base de la Fase 1 **todo lo que debe sobrevivir**:
   `perfil`, `votaciones`, `proyectos`, y dentro de `asistencia` los cuatro
   bloques de Capa 3. Deben ser idénticos valor a valor.
   **Excluye de la comparación `metadatos.generado`**, que es un timestamp de
   corrida y cambia siempre; declara explícitamente esa exclusión.
   Esperado: 0 diferencias sobre 155 perfiles + 155 entradas de índice.
4. Comprueba que la copia de `docs/data/` quedó consistente con
   `40_salidas/json/` (el propio `39` valida el conteo; verifica además que el
   índice de `docs/data/` no trae `tasa_asistencia`).

**Commit:** `git add` acotado a `30_procesamiento/39_consolidar_json.R`,
`40_salidas/json/`, `docs/data/` (y `10_utils/10_utils.R` solo si lo adaptaste).
Mensaje: `refactor: retirar campos legacy de asistencia del JSON publicado (P-48)`.

---

### Fase 3 — Retiro del bloque 1 de `33_extraer_asistencia.R`

**Objetivo:** eliminar la segunda descarga de asistencia, que es el costo
recurrente que este pendiente venía pagando en cada refresh.

1. Retira del `33` el **bloque 1 completo**: `extraer_asistencia_long()`, su
   llamada, la validación de dominio de ese bloque, el agregado por diputado, su
   validación de integridad y la escritura de
   `40_salidas/intermedios/asistencia.rds`. Retira también el comentario
   `# REVISAR` que anunciaba justamente este retiro, y actualiza el encabezado del
   archivo (propósito, insumos y salidas) para que describa lo que el script hace
   ahora: una sola granularidad, la nominal.
2. El bloque 2 (nominal, Capa 3) queda **intacto en fórmula y en valor**. No lo
   refactorices, no lo "aproveches para mejorar": este encargo es una sustracción.
3. Borra el intermedio huérfano `40_salidas/intermedios/asistencia.rds` del árbol
   de trabajo y del repositorio (`git rm`), si está trackeado. Comprueba antes,
   con `git -C <raíz> ls-files`, si lo está.
4. **La clave de caché `asistencia_long_<anio>` deja de usarse.** Los `.rds` ya
   descargados en `20_insumos/camara/` **NO se borran**: son datos crudos, y la
   gobernanza del proyecto los trata como inmutables. Solo deja de leerlos.
5. Comprueba si `00_run_all.R` o `10_utils/10_diff_conteos.R` nombran
   `asistencia.rds` o la métrica legacy. Si sí, adáptalos en esta misma fase con
   el mismo criterio de falla ruidosa.

**Verificación (antes del commit):**

1. Regenera `32`–`36` y `39` completos.
2. En R, compara la salida contra la de la **Fase 2** (no contra la Fase 1):
   deben ser **idénticas**, campo a campo, excluyendo `metadatos.generado`.
   Esperado: 0 diferencias. Esto es lo que prueba que retirar la descarga
   duplicada no cambia el dato publicado.
3. Comprueba en el log de la corrida que la asistencia se descargó (o se leyó de
   caché) **una sola vez**: debe aparecer una sola invocación del barrido de
   sesiones. Declara la evidencia textual.

**Commit:** `git add` acotado a `30_procesamiento/33_extraer_asistencia.R`, el
`git rm` del intermedio, y los archivos que hayas adaptado en el punto 5. Mensaje:
`refactor: eliminar la extracción legacy de asistencia y su descarga duplicada (P-48)`.

---

### Fase 4 — Glosa del frontend y encabezados

**Objetivo:** que ninguna prosa del portal describa un campo que ya no existe.

1. Lee `docs/index.html` alrededor de **L511** y reescribe la glosa para que no
   mencione `tasa_asistencia` como campo vigente. La frase describe una
   verificación de la sesión 14 contra un campo que a partir de este commit no se
   publica: dejarla es afirmar algo falso sobre el contrato (mismo mecanismo del
   aprendizaje A50). **Cambio de prosa únicamente**: no toques ninguna expresión
   que lea datos.
2. Verifica que sigue sin haber consumo de dato legacy: en el `<script>` no debe
   quedar ninguna lectura de `tasa_asistencia` ni de `n_*` fuera de los objetos
   `pv` / `ej` / `a.periodo_vigente` / `a.en_ejercicio`.
3. Chequeo de sintaxis del bloque `<script>` sin navegador, extrayéndolo con R y
   corriendo `node --check` sobre el archivo extraído. Debe pasar limpio.
4. Sirve el sitio localmente y comprueba en dos fichas reales que siguen
   apareciendo las cuatro mini-tarjetas y la tabla de sesiones. Usa una ficha con
   `n_no_asiste = 0` y otra con `n_no_asiste > 0` (búscalas en R sobre los JSON
   nuevos, no las adivines): son los dos casos límite que produjeron los bugs
   B-14-01 y B-14-02, y esta es la re-verificación que el traspaso v14 §11.2 dejó
   encadenada a este pendiente.

**Commit:** `git add` acotado a `docs/index.html`. Mensaje:
`docs: corregir la glosa que citaba el campo legacy retirado (P-48)`.

---

### Fase 5 — Panel adversarial

**Objetivo:** que la afirmación central del encargo ("ningún campo sobreviviente
cambió") esté verificada por código independiente del que produjo el cambio.

Lanza agentes de **solo lectura** que re-deriven desde cero, con código propio y
sin reutilizar los checks de las fases anteriores:

1. **Invarianza de valores.** Tomando `/tmp/p48_base/` (Fase 1) y la salida final,
   re-derivar de forma independiente que todo lo que no está en la lista de
   retirados es idéntico. Debe declarar su propio denominador (cuántos perfiles,
   cuántas claves comparadas) y la exclusión de `metadatos.generado`.
2. **Completitud del retiro.** Re-derivar que ninguno de los cinco nombres
   aparece en ninguna parte de los 155 perfiles ni del índice, incluyendo claves
   anidadas a cualquier profundidad. Un `n_sesiones` dentro de `periodo_vigente`
   **sí debe seguir existiendo**: el agente debe distinguir el nivel, no buscar el
   nombre a ciegas.
3. **Coherencia interna de la Capa 3.** Re-derivar sobre los 155 que
   `n_asiste + n_no_asiste + n_sin_registro == n_sesiones` y que
   `n_justificadas + n_injustificadas == n_no_asiste` en los dos ámbitos, y que el
   denominador de `periodo_vigente` es común a los 155.
4. **Contrato del índice.** Re-derivar que el `tasa_presencia` del índice coincide
   con `asistencia.periodo_vigente.tasa_presencia` del perfil en los 155 casos
   (esta es la comprobación de la sesión 14, aprendizaje A53; ahora es el único
   indicador del índice y conviene reafirmarla tras el cambio).

**Si cualquier agente reporta una diferencia:** detente, **no abras el PR**, y
reporta con la evidencia. Un hallazgo aquí invalida el retiro tal como está
construido.

---

### Fase 6 — Higiene: P-55 y registro de P-52

1. **P-55** (`.claude/settings.local.json`, hoy sin trackear): léelo. El
   repositorio es **público**.
   - Si contiene rutas absolutas del titular, credenciales, tokens o cualquier
     dato local o sensible → agrégalo a `.gitignore` y **no lo versiones**.
   - Si contiene solo configuración genérica reutilizable → igual va a
     `.gitignore`: es configuración *local* por nombre y por convención de la
     herramienta.
   - En ambos casos, deja `git status` sin archivos sin trackear al terminar, y
     declara en el log qué contenía **en términos genéricos** (nunca copies su
     contenido al log: el log se commitea y el repo es público).
2. **P-52** (auditoría de apertura #3: paquetes, rutas y constantes al inicio de
   cada script): ya está medido y el resultado es **conforme** (once scripts, cero
   rutas absolutas escritas a mano). Regístralo en el log con esa evidencia y
   añade **un solo hallazgo abierto**, sin corregirlo:
   `CODIGOS_JUSTIFICACION_OBSERVADOS` está declarada dentro de
   `30_procesamiento/33_extraer_asistencia.R` y es una constante metodológica, no
   una derivada de la corrida; su lugar natural es
   `10_utils/10_configuracion.R`. **No la muevas en este encargo**: mezclarla con
   el retiro del contrato ensucia el diff. Queda como pendiente para el titular.
3. **P-56**: cerrado por la medición de la sección 2.4, punto 4. Regístralo con su
   evidencia; no lo re-investigues.

**Commit:** `git add` acotado a `.gitignore`. Mensaje:
`chore: ignorar la configuración local de Claude Code (P-55)`.
Si no hubo cambio en `.gitignore`, no hay commit en esta fase.

---

### Fase 7 — Log, push y PR

1. Escribe el log en
   `50_documentacion/andamios/logs/<AAAAMMDD>_p48_retiro_legacy_log.md`, con la
   fecha derivada de la fecha real de ejecución, siguiendo la plantilla de la
   sección 6. Honesto: incluye lo que costó, no solo lo que salió bien.
2. Commit del log aparte: `docs: log de ejecución del retiro del contrato legacy (P-48)`.
3. `git -C <raíz> fetch origin` y comprueba divergencia contra `origin/main`
   **antes** de empujar (regla A32). Si `main` avanzó (posible: el bot corre los
   lunes), **no rebasees ni mergees**: reporta la divergencia y empuja igual tu
   rama; el PR mostrará el conflicto y lo resuelve el titular.
4. Empuja la rama y abre el PR con
   `gh -R tomgc/transparencia_legislativa_chile pr create`. **No lo mergees** (🔒).
5. **Cuerpo del PR**, obligatorio y con cifras contadas programáticamente:
   - qué campos se retiraron, del perfil y del índice;
   - la tabla de verificación de invarianza (denominadores declarados);
   - el veredicto de cada agente del panel adversarial;
   - el número de archivos que cambia el PR, obtenido por la **API paginada** de
     `/pulls/<n>/files`, con el denominador declarado (recuerda: `gh pr diff
     --name-only` está prohibido);
   - una línea que diga explícitamente que este PR **cambia el contrato de datos
     publicado** y que el merge es decisión del titular.

**Criterio de éxito:** PR abierto, no mergeado, con cuerpo completo; la rama
empujada; el log escrito y commiteado; `main` intacto.

---

## 5. Criterios de éxito del encargo (B.4)

| # | Condición | Cómo se comprueba |
|---|---|---|
| 1 | Los cinco campos legacy no existen en ningún perfil publicado | Recorrido en R de los 155 perfiles, a cualquier profundidad, distinguiendo nivel (Fase 5.2) |
| 2 | `tasa_asistencia` no existe en el índice | Lectura en R de `indice_diputados.json` |
| 3 | Ningún campo sobreviviente cambió de valor | Comparación 1:1 contra la base de la Fase 1, excluida `metadatos.generado`, 0 diferencias sobre 155 perfiles |
| 4 | La asistencia se descarga una sola vez por corrida | Evidencia textual del log de la corrida de la Fase 3 |
| 5 | El frontend rinde idéntico, incluidos los dos casos límite | `node --check` limpio + revisión en dos fichas con `n_no_asiste` = 0 y > 0 |
| 6 | El panel adversarial no reporta diferencias | Los cuatro veredictos en el log |
| 7 | `main` intacto y PR abierto sin mergear | `git -C <raíz> log origin/main -1` y `gh pr list` |

---

## 6. Log de cierre (plantilla fija, obligatoria)

Ruta: `50_documentacion/andamios/logs/<AAAAMMDD>_p48_retiro_legacy_log.md`.

1. **Resumen de la ejecución:** qué entró, en cuántas fases, estado final.
2. **Inventario de commits:** todos, en orden, hash corto, tipo, título, una línea
   de qué hizo cada uno.
3. **Por cada cambio sustantivo:** qué, por qué, archivos tocados, cómo se
   verificó, decisiones tomadas en autonomía.
4. **Estado de las cuatro premisas** de la sección 2.4: confirmada o refutada,
   con la evidencia.
5. **Veredicto de Pages** (Fase 0.8).
6. **Bugs encontrados y resueltos:** síntoma, causa raíz, fix, verificación.
7. **Verificación de invariantes:** cada 🔒 de la sección 3 con PASA / FALLA y su
   evidencia.
8. **Panel adversarial:** los cuatro agentes, con su denominador y su veredicto.
9. **Estado de cifras críticas:** la tabla de invarianza, con denominadores.
10. **Pendientes abiertos:** P-52 (la constante que no se movió), P-55 (qué se
    decidió), P-56 (cerrado, con evidencia), y todo `# REVISAR` que sobreviva.
11. **Notas para el revisor:** qué mirar con ojo crítico antes de mergear el PR.

---

## 7. Reporte final al chat

Cuando termines, devuelve al chat, en formato compacto:

- rama y URL del PR;
- inventario de commits con hash corto;
- la tabla de invarianza con sus denominadores;
- los cuatro veredictos del panel adversarial;
- el veredicto de Pages;
- qué quedó pendiente y por qué;
- la ruta del log.

No repitas el log completo en el chat: el log es el detalle, el reporte es el
índice.
