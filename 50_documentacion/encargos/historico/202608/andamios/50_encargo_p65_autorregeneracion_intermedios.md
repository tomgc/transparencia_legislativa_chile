# Encargo — P-65: que el orquestador resuelva el desalineamiento de sello, no la memoria del operador

- **Destino en el repo:** `50_documentacion/andamios/50_encargo_p65_autorregeneracion_intermedios.md`
- **Proyecto:** `transparencia_legislativa_chile`
- **Raíz absoluta:** `/Users/tomgc/Projects/transparencia_legislativa_chile`
- **Repo:** `tomgc/transparencia_legislativa_chile`
- **Sesión:** 16. **Pendiente:** P-65.
- **Modo:** ejecución autónoma con compuertas. Te detienes SOLO donde el encargo lo dice.

---

## 1. Meta

P-62 dejó documentada la causa raíz: los intermedios están en `.gitignore` y el workflow no
los commitea, pero **sí** commitea el avance de `CORTE_FECHA`, así que **toda copia local
queda desalineada después de cada merge del bot** y una corrida de `39` falla (fuente:
`50_documentacion/andamios/logs/20260807_p62_sello_intermedios_log.md` §5).

El titular decidió **no versionar los intermedios**. La corrección es que el orquestador
detecte la condición y regenere `32`–`36` antes de seguir, en vez de que el operador tenga
que acordarse.

**Lo que NO es esta tarea.** No es hacer que el error desaparezca: es que el orquestador
haga, automáticamente y con aviso, exactamente lo que hoy el operador tiene que hacer a
mano. La distinción práctica es que la regeneración **sólo procede cuando puede hacerse
desde la captura cruda ya versionada, sin red**. Si no puede, el orquestador **falla
ruidosamente** con el diagnóstico. Un arreglo que descargue por su cuenta, o que degrade en
silencio, es peor que el problema.

---

## 2. Invariantes (🔒)

1. 🔒 **No se toca `validar_corte()`, ni `leer_sellado()`, ni `sellar()`.** La compuerta del
   `39` queda intacta y sigue haciendo `stop()`. Este encargo actúa **aguas arriba** de
   ella, nunca sobre ella.
2. 🔒 **No se toca `CORTE_FECHA`** ni el archivo de configuración, salvo lo que exija el
   propio banco de pruebas y siempre restaurándolo (§3, Fase 3).
3. 🔒 **La regeneración automática no baja nada de la red.** Procede sólo si la captura
   cruda del corte vigente ya está en `20_insumos/camara/`. Si falta, `stop()` con el
   diagnóstico y el comando exacto que el operador debe correr.
4. 🔒 **Nada silencioso.** Toda regeneración automática se anuncia por consola antes de
   ocurrir, diciendo qué detectó, qué va a hacer y por qué.
5. 🔒 **`20_insumos/camara/` es dato crudo inmutable.** Se lee, no se escribe. Se verifica
   por md5 antes y después.
6. 🔒 **R es el único lenguaje.** Prohibido `jq`, `awk`, `python`, y `grep`/`sed` sobre
   artefactos de datos.
7. 🔒 **git con `-C /Users/tomgc/Projects/transparencia_legislativa_chile`**; `gh pr` con
   `-R tomgc/transparencia_legislativa_chile`. `git add` siempre con ruta acotada, nunca
   `git add .`. No dispares el workflow.
8. 🔒 **No republiques.** `docs/` y `40_salidas/json/` deben quedar sin cambios al final. Si
   una prueba los modifica, se verifica archivo por archivo que la única diferencia es
   `metadatos.generado` (volátil por construcción) y **recién entonces** se restauran.
9. 🔒 **Toda cifra se cuenta programáticamente en el turno en que se escribe**, con su
   denominador.

---

## 3. Fases y compuertas

### Fase 0 — Leer antes de escribir

Sin escrituras. Lee completos: `00_run_all.R`, `10_utils/10_utils.R` y
`10_utils/10_configuracion.R`. Responde, cada respuesta con archivo y línea:

- Cómo `00_run_all.R` recibe y resuelve `from`, `to` y `only`, y en qué orden ejecuta.
- Dónde encaja un chequeo previo sin romper ninguna de esas formas de invocación.
- Cómo se resuelve la ruta de la captura cruda de cada extractor (el nombre lleva el corte:
  necesitas saber cómo se construye, no suponerlo).
- Si ya existe alguna utilidad de verificación de sello reutilizable, para no escribir una
  segunda.

**Compuerta 0.** Si `00_run_all.R` no tiene un punto único por donde pasen todas las
invocaciones, **detente y reporta** con las alternativas: meter el chequeo en varios lugares
es la clase de parche que se desincroniza solo.

---

### Fase 1 — Implementar la guarda

Una función nueva en `10_utils/10_utils.R` (o donde la Fase 0 indique que corresponde),
invocada desde `00_run_all.R` **antes** de ejecutar cualquier paso.

**Comportamiento, en este orden:**

1. Lee el sello de los 6 intermedios de `40_salidas/intermedios/`.
2. **Si los 6 declaran el corte vigente:** no hace nada y no imprime ruido. Idempotente.
3. **Si falta algún intermedio o alguno declara un corte distinto:**
   a. Comprueba que la captura cruda del corte vigente exista en `20_insumos/camara/` para
      los 5 extractores.
   b. **Si existe:** anuncia por consola qué detectó (qué artefactos, qué corte declaran,
      cuál es el vigente) y que va a regenerar `32`–`36` desde caché, sin red. Regenera.
      Vuelve a verificar los sellos y hace `stop()` si después de regenerar siguen
      desalineados.
   c. **Si no existe:** `stop()` con un mensaje que diga qué falta, por qué no puede
      regenerarse sin red, y el comando exacto a correr.
4. **Nunca** modifica `CORTE_FECHA`, ni escribe sellos a mano, ni salta la validación.

**Sobre el alcance de la guarda:** actúa en `00_run_all.R`, no dentro del `39`. El `39`
sigue fallando si lo invocas suelto con intermedios desalineados, y eso es correcto: la
guarda es una conveniencia del orquestador, no un reemplazo de la compuerta.

**Compuerta 1.** El código está escrito y `00_run_all.R` lo invoca desde un punto único.

---

### Fase 2 — Banco de pruebas, con la condición real

Tres escenarios. Antes de empezar, **respalda los 6 `.rds`** para poder restaurar.

| # | Escenario | Cómo se induce | Qué debe pasar |
|---|---|---|---|
| **1** | Sellos alineados | Estado actual | La guarda no hace nada, no regenera, no imprime aviso |
| **2** | Sello desalineado, caché presente | Lee los 6 objetos, altera `attr(x, "sello")$corte_fecha` a un valor antiguo y reescríbelos **sin** pasar por `escribir_atomico()` | La guarda avisa, regenera desde caché sin red, y termina con los 6 sellos al corte vigente |
| **3** | Intermedio ausente | Mueve uno de los 6 a un temporal | La guarda lo trata como desalineado y lo regenera |

El escenario 2 es el que importa: reproduce exactamente la condición que P-62 encontró en
producción. **Induce el desalineamiento tocando el atributo, no `CORTE_FECHA`** (🔒 2).

Si además puedes inducir el escenario de caché ausente sin borrar nada de
`20_insumos/camara/` (por ejemplo, apuntando la comprobación a un corte inexistente en un
entorno de prueba), verifica que el `stop()` sale con su diagnóstico. Si no puedes inducirlo
sin violar el 🔒 5, **no lo fuerces**: decláralo como no probado y di por qué.

**Compuerta 2.** Los tres escenarios con su resultado observado, y `20_insumos/camara/`
idéntico antes y después por md5, con el denominador declarado.

---

### Fase 3 — Verificación de no regresión

1. `00_run_all.R` corre completo, de punta a punta, sin error.
2. Los JSON regenerados se comparan contra los publicados: **156 artefactos** (155 perfiles
   más el índice), **excluido `metadatos.generado`, que es volátil por construcción**, y la
   exclusión se declara en el mismo enunciado. `corte_fecha` **no** es volátil y sí se
   compara.
3. Cualquier diferencia fuera de `generado`: **detente y repórtala antes de commitear**.
4. `docs/` y `40_salidas/json/` restaurados, `git status` acotado a esas rutas en 0 líneas.
5. `10_utils/10_utils.R`: `validar_corte()`, `leer_sellado()` y `sellar()` **sin cambios**
   respecto de `HEAD`, comprobado por diff acotado a esas funciones.
6. `10_utils/10_configuracion.R` idéntico a `HEAD`.

**Compuerta 3.** Los seis puntos, cada uno con su cifra.

---

### Fase 4 — Documentación y cierre

1. Actualiza `50_documentacion/activa/procedimiento_actualizacion.md`: la sección de
   verificación de reproducibilidad ahora debe decir que el orquestador regenera solo, y en
   qué caso falla ruidosamente. **Retira el paso manual que P-62 agregó**, para que no
   queden dos instrucciones compitiendo.
2. **De paso, y esto sí está en alcance:** ese mismo documento tiene una sección
   *"Pendiente 2 — Automatización con GitHub Actions (NO EJECUTAR AÚN)"* que describe como
   pseudocódigo un workflow que existe y corre desde el 2026-07-10 (fuente:
   `20260807_p62_sello_intermedios_log.md` §10). Corrígela para que describa el workflow
   real, o márcala como histórica sin ambigüedad. Un procedimiento que instruye no ejecutar
   algo que lleva un mes corriendo es una trampa para quien lo lea.
3. **Log** en `50_documentacion/andamios/logs/<AAAAMMDD>_p65_autorregeneracion_log.md`: el
   punto de inserción con archivo y línea, los tres escenarios con su resultado, las
   verificaciones de la Fase 3, y las decisiones tomadas en autonomía, una línea cada una.
4. Rama `fix/autorregeneracion-intermedios`, commits atómicos con ruta acotada, **PR abierto
   y no mergeado**. Este encargo toca el orquestador y `10_utils/`: entra por PR revisable,
   no por push a `main`.
5. **Reporte final al chat**, compacto: dónde quedó la guarda, los tres escenarios, si
   `00_run_all.R` corre completo, y la URL del PR.

---

## 4. Criterios de éxito (contrastables)

| # | Criterio | Medida |
|---|---|---|
| 1 | La guarda se invoca desde un punto único del orquestador | Archivo y línea; 1 sitio de invocación |
| 2 | Idempotente con sellos alineados | Escenario 1: 0 regeneraciones, 0 avisos |
| 3 | Regenera con sello desalineado y caché presente | Escenario 2: 6 de 6 sellos al corte vigente después |
| 4 | Regenera con intermedio ausente | Escenario 3: 6 de 6 presentes y sellados después |
| 5 | Cero red en la regeneración automática | Cache hit en 5 de 5 extractores, 0 llamadas a la API |
| 6 | Falla ruidosamente sin caché | `stop()` con diagnóstico y comando; o declarado no probado, con el motivo |
| 7 | La compuerta no fue debilitada | `validar_corte()`, `leer_sellado()` y `sellar()` idénticos a `HEAD` |
| 8 | `CORTE_FECHA` intacto | `10_utils/10_configuracion.R` idéntico a `HEAD` |
| 9 | `20_insumos/camara/` inmutable | md5 idénticos antes y después, denominador declarado |
| 10 | El dato publicado no cambió | 156 de 156 idénticos, excluido `metadatos.generado` |
| 11 | `00_run_all.R` corre completo | Sin error, con el tiempo declarado |
| 12 | El procedimiento no tiene instrucciones en conflicto | 1 sola instrucción sobre regeneración; la sección "Pendiente 2" corregida o marcada como histórica |
| 13 | PR abierto y no mergeado | URL, y `main` sin commits nuevos de este encargo |

---

## 5. Qué NO hace este encargo

- No versiona los intermedios (decisión ya tomada: no se versionan).
- No modifica el workflow de GitHub Actions.
- No republica `docs/`.
- No toca el contrato de datos.
- No aborda P-63 (nodo `Votaciones`) ni P-59 (locale).
