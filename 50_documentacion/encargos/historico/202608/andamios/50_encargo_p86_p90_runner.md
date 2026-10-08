# Encargo autónomo — P-86 y P-90: el runner conoce el paso 37

Sesión 22 · proyecto `transparencia_legislativa_chile`

---

## Encabezado de contrato

**MODO:** ejecución autónoma, secuencial, todo en este turno. No pidas
aclaraciones antes de empezar: si algo es ambiguo, este documento dice cómo
resolverlo o dice que te detengas.

**REGLA DE DETENCIÓN.** Te detienes y reportas, sin escribir nada más, solo en
estos tres casos:

1. Una hipótesis de §0.2 resulta falsa.
2. Un invariante de §2 te obligaría a hacer dos cosas incompatibles.
3. Una fase exige una decisión de metodología o de dato publicado que este
   encargo no resolvió.

Fuera de esos tres casos, resuelves con autonomía y lo dejas anotado en el log.

**ENTORNO.** Filesystem local vía Claude Code, en la máquina del titular.
Raíz del proyecto: `/Users/tomgc/Projects/transparencia_legislativa_chile`.

**INSUMOS.** Todos son archivos del propio repositorio, en las rutas de abajo.
Este encargo **no cita ningún documento que no esté en ese filesystem**: la
plantilla del log va incrustada en §6 de este documento y no se referencia por
ruta.

| Insumo | Ruta absoluta |
|---|---|
| Utilidades (guarda, sellos, caché) | `/Users/tomgc/Projects/transparencia_legislativa_chile/10_utils/10_utils.R` |
| Configuración y `CORTE_FECHA` | `/Users/tomgc/Projects/transparencia_legislativa_chile/10_utils/10_configuracion.R` |
| Orquestador | `/Users/tomgc/Projects/transparencia_legislativa_chile/00_run_all.R` |
| Extractor de tramitación | `/Users/tomgc/Projects/transparencia_legislativa_chile/30_procesamiento/37_extraer_tramitacion.R` |
| Crudo del SIL | `/Users/tomgc/Projects/transparencia_legislativa_chile/20_insumos/senado/` |
| Intermedios | `/Users/tomgc/Projects/transparencia_legislativa_chile/40_salidas/intermedios/` |
| Este encargo | `/Users/tomgc/Projects/transparencia_legislativa_chile/50_documentacion/andamios/50_encargo_p86_p90_runner.md` |

**POSICIÓN.** Toda ruta va completa desde la raíz. Ningún comando asume `cd`
previo ni estado de terminal heredado. `git` siempre con
`-C /Users/tomgc/Projects/transparencia_legislativa_chile`. `gh` siempre con
`-R tomgc/transparencia_legislativa_chile`, salvo `gh api`. `git add` siempre
con ruta acotada: nunca `git add .` ni `git add -A`.

**LENGUAJE.** R es el único lenguaje, en todo contexto, incluida la inspección
de solo lectura. Nada de `awk`, `jq`, `sed` ni Python sobre artefactos del
proyecto. `git`, `gh`, `ls`, `grep` y `wc` son herramientas de repositorio, no
de datos, y sí se usan. Prohibido `gh pr diff --name-only` (HTTP 406 en PR
grandes) y prohibido `gh --jq`: usa `gh api > archivo.json` y
`jsonlite::fromJSON()` en R.

---

## §0. Contrato positivo

### §0.1 Afirmaciones respaldadas

Cada fila trae la fuente que la respalda. **Ninguna es una lectura del código
actual**: el redactor de este encargo no tuvo acceso al filesystem. Son
afirmaciones sobre lo que otros documentos declaran, y como tales valen.

| # | Afirmación | Fuente |
|---|---|---|
| R1 | El traspaso v21 declara que `capturas_crudas_de_paso()` e `INTERMEDIOS_PIPELINE` no conocen el paso 37, y que la consecuencia es una ruta de recuperación falsa, no un dato falso | `traspaso_cierre_v21.md` §3, "Qué no funciona", punto 2 |
| R2 | El criterio de éxito de P-86 fijado por el traspaso es: el mensaje de recuperación nombra el paso correcto, probado en subproceso con el intermedio desalineado a propósito | `traspaso_cierre_v21.md` §11.1, entrada P-86 |
| R3 | El criterio de P-90 es verificar que en el cron, donde corte y captura son del mismo día, el escape temporal **no** se necesite | `traspaso_cierre_v21.md` §11.1, entrada P-90 |
| R4 | El crudo del SIL quedó versionado bajo `20_insumos/senado/`, sin entrada de `.gitignore` | `traspaso_cierre_v21.md` §10 |
| R5 | El paso 37 quedó integrado en `00_run_all.R` en la sesión 21 | `backlog_acumulativo.md`, entrada 62 |
| R6 | El backlog declara `regenerar_intermedios_si_desalineados()` en `10_utils/10_utils.R:294`, invocada desde un punto único en `00_run_all.R:84`, y que fuerza `camara.refrescar = FALSE` restaurándolo con `on.exit` | `backlog_acumulativo.md`, entrada 50 |
| R7 | El backlog declara que la sesión 18 unificó en `capturas_crudas_de_paso()` la resolución de corte | `backlog_acumulativo.md`, entrada 55 |
| R8 | El SIL no es append-only: recapturar el mismo corte puede devolver contenido distinto | `traspaso_cierre_v21.md` §7, A88 |
| R9 | El commit de cierre de la sesión 21 es `4160f46` y quedó pendiente de push al abrir esta sesión | mensaje de reapertura de la sesión 22 |

### §0.2 Hipótesis, con su comando de verificación

Ninguna de estas se da por cierta. **F0 las verifica todas antes de escribir una
sola línea.** Si alguna resulta falsa, te detienes (regla de detención, caso 1).

| # | Hipótesis | Comando de verificación |
|---|---|---|
| H1 | `INTERMEDIOS_PIPELINE` existe como constante y enumera los intermedios sin incluir `tramitacion.rds` | leer `10_utils/10_utils.R` y `10_utils/10_configuracion.R`; localizar la definición con `grep -n "INTERMEDIOS_PIPELINE"` sobre ambos, y **leer la definición completa**, no la coincidencia |
| H2 | `capturas_crudas_de_paso()` mapea número de paso a sus capturas crudas y no tiene rama para el 37 | `grep -n "capturas_crudas_de_paso" 10_utils/10_utils.R 00_run_all.R` y lectura del cuerpo completo de la función |
| H3 | El mensaje de recuperación que imprime el `stop()` de la guarda se construye a partir de esas dos estructuras, de modo que agregar el 37 corrige el mensaje | lectura del cuerpo de `regenerar_intermedios_si_desalineados()` y del `stop()` que emite |
| H4 | La ubicación declarada en R6 (`10_utils.R:294`, `00_run_all.R:84`) sigue siendo la actual | `grep -n "regenerar_intermedios_si_desalineados" 10_utils/10_utils.R 00_run_all.R` |
| H5 | `37_extraer_tramitacion.R` puede regenerar `tramitacion.rds` desde el crudo ya versionado en `20_insumos/senado/` **sin una sola llamada de red** | medición de F0bis, abajo; no se responde por lectura |
| H6 | `main` local y `origin/main` coinciden (el titular pusheó `4160f46` antes de lanzar este encargo) | `git -C <raíz> fetch origin && git -C <raíz> rev-parse main origin/main` |
| H7 | El árbol está limpio salvo por este encargo | `git -C <raíz> status --porcelain` |

**H5 es la hipótesis que decide el diseño de F1.** No la respondas leyendo
código: se responde ejecutando, con el fusible armado, y el resultado manda.

---

## §1. Contexto mínimo suficiente

El proyecto publica un portal serverless de transparencia legislativa. R
consolida datos públicos del Congreso en JSON estáticos servidos por GitHub
Pages. El pipeline corre en siete pasos desde `00_run_all.R`; los intermedios
(`40_salidas/intermedios/*.rds`) no se versionan (D24) y llevan un sello de
procedencia que `validar_corte()` contrasta contra `CORTE_FECHA`. Cuando el
sello se desalinea, `regenerar_intermedios_si_desalineados()` regenera los
intermedios desde la **captura cruda versionada**, sin red, o falla con un
`stop()` diagnóstico que le dice al operador qué correr.

La sesión 21 agregó un paso nuevo, el `37`, que produce `tramitacion.rds` a
partir del SIL del Senado, con su crudo versionado en `20_insumos/senado/`. Ese
paso quedó fuera de las dos estructuras que la guarda consulta. Nada se publica
mal por esto: lo que falla es la instrucción de recuperación, que manda a
regenerar los pasos equivocados. El refresh semanal corre el lunes.

---

## §2. Invariantes (🔒)

Cada uno con su porqué cuando no es obvio.

- 🔒 **`sellar()`, `leer_sellado()` y `validar_corte()` no se tocan.** Son la
  compuerta de procedencia; su estabilidad es lo que hace comparables los cortes
  entre sesiones.
- 🔒 **Cero llamadas de red en toda la ejecución de este encargo**, con el
  fusible armado antes de la primera prueba que ejercite el pipeline. El fusible
  es un `quit(99)` mecánico, no un aviso: nada de reglas de la forma "si
  detectas que va a descargar".
- 🔒 **Ninguna captura cruda ya escrita se modifica ni se borra**, ni en
  `20_insumos/camara/` ni en `20_insumos/senado/`. Si una prueba necesita un
  estado distinto, se induce en copia o en subproceso, y se restaura con md5
  idéntico verificado.
- 🔒 **Los intermedios no se versionan (D24)**, y
  `40_salidas/intermedios/.gitkeep` sigue trackeado.
- 🔒 **`10_utils/10_utils.R` no adquiere dependencias de paquetes.**
- 🔒 **Ningún dato publicado cambia en este encargo.** `40_salidas/json/` y
  `docs/data/` quedan byte a byte como estaban; lo compruebas al cierre.
- 🔒 **No se recaptura el SIL.** R8: recapturar el mismo corte puede dar
  contenido distinto, así que una recaptura convertiría un encargo de runner en
  un cambio de dato silencioso.
- 🔒 **`main` no recibe push directo desde este encargo.** El trabajo va en rama
  y termina en un PR abierto. **No mergeas**: la autoridad de merge no está
  delegada en esta sesión.
- 🔒 **R es el único lenguaje**, en todo contexto.
- 🔒 **Ninguna cifra se reporta sin recuento programático en el mismo turno en
  que se reporta.** Aritmética manual, cifra heredada de un documento y memoria
  no son fuentes.

---

## §3. Fases, en orden estricto

### F0 — Arranque, commit del propio encargo y verificación del estado real

**Este bloque incluye su propio commit.** El encargo llega al repositorio como
archivo no trackeado y, si no se commitea primero, bloquea la compuerta de árbol
limpio de su propia ejecución. Esto pasó tres veces en la sesión 21.

1. Rama de trabajo:
   `git -C <raíz> checkout -b fix/p86-runner-paso37`
2. Commit del encargo, con ruta acotada:
   `git -C <raíz> add 50_documentacion/andamios/50_encargo_p86_p90_runner.md`
   y commit `docs(p86): encargo de la sesion 22`.
3. **Estado del repositorio, con `git fetch` dentro de la propia compuerta:**
   `git -C <raíz> fetch origin`, luego
   `git -C <raíz> rev-parse main origin/main` y
   `git -C <raíz> log --oneline -3 main`. Verifica H6 y H7. Si `main` local está
   adelante de `origin/main`, **detente y reporta**: significa que el commit de
   cierre `4160f46` no se pusheó y el PR arrastraría el cierre de la sesión
   anterior.
4. **`CORTE_FECHA` leído, no heredado:** léelo de
   `10_utils/10_configuracion.R` y repórtalo con su número de línea. No lo
   afirmes desde ningún documento.
5. **Lectura del estado real** de `INTERMEDIOS_PIPELINE`,
   `capturas_crudas_de_paso()` y `regenerar_intermedios_si_desalineados()`:
   cuerpo completo, no la línea de la coincidencia. Verifica H1 a H4 y reporta
   cada una con archivo y línea.
6. **Ficha de F0 en el log**, con las siete hipótesis y su veredicto.

**Criterio de éxito de F0:** las siete hipótesis con veredicto y evidencia de
archivo y línea; ninguna afirmación sin fuente leída en la misma corrida.

### F0bis — ¿Es el 37 regenerable sin red? (medición, no juicio)

Esta medición decide el diseño de F1 y por eso va antes.

1. Arma el fusible de red (`quit(99)`).
2. En **subproceso**, con `40_salidas/intermedios/tramitacion.rds` movido a una
   ruta temporal (no borrado), corre solo el paso 37 y observa: (a) si termina;
   (b) si el fusible dispara; (c) si el `.rds` producido tiene el mismo md5 que
   el original.
3. Restaura `tramitacion.rds` y verifica md5 idéntico al de antes de la prueba.

**Resultado A — el 37 regenera sin red y con md5 idéntico:** el paso 37 entra en
las dos estructuras en pie de igualdad con el 32-36, y la guarda podrá
regenerarlo igual que a los demás.

**Resultado B — el 37 no puede regenerarse sin red, o el md5 difiere:** el paso
37 entra **solo** en lo que construye el mensaje de recuperación, y **no** en la
lista de lo que la guarda regenera automáticamente. Un md5 distinto sin red es
señal de no determinismo del parser y se reporta como hallazgo propio.

En ambos casos el resultado se escribe en el log con la evidencia de los tres
puntos, y el diseño de F1 se sigue del resultado. No elijas por criterio
estético cuál te gusta más.

**Criterio de éxito de F0bis:** veredicto A o B con las tres observaciones, y
`tramitacion.rds` restaurado con md5 idéntico al inicial, comprobado.

### F1 — P-86: registrar el paso 37

1. Agrega el paso 37 a `capturas_crudas_de_paso()` y a `INTERMEDIOS_PIPELINE`
   según el resultado de F0bis, con el cambio más pequeño que corrija el
   mensaje. **Cambio quirúrgico:** cada línea modificada se traza a P-86. No
   refactorices `regenerar_intermedios_si_desalineados()`: esa función es zona
   de P-82 y entrar a rediseñarla tres días antes del cron mezcla dos cambios en
   el punto más frágil del runner.
2. **Prueba en subproceso con el intermedio desalineado a propósito**, que es el
   criterio que el traspaso fijó (R2): desalinea el sello de `tramitacion.rds`
   en copia, corre la guarda y captura el mensaje literal del `stop()` o del
   aviso de regeneración.
3. **Contraprueba:** repite con un intermedio de la Cámara desalineado y
   comprueba que su mensaje **no cambió** respecto de `HEAD`. La retro
   compatibilidad se demuestra comparando cadenas, no contando líneas del diff.
4. **Invariantes protegidos por identidad:** comprueba que `sellar()`,
   `leer_sellado()` y `validar_corte()` son idénticas a `HEAD` comparando
   `deparse()` del cuerpo entre el entorno de `HEAD` y el del árbol, no el diff
   del archivo.
5. Commit atómico: `fix(p86): el runner reconoce el paso 37`.

**Criterio de éxito de F1, contrastable en ambos sentidos:** con
`tramitacion.rds` desalineado, el mensaje nombra el paso 37 y **no** nombra los
pasos 32-36 como si fueran el remedio; con un intermedio de Cámara desalineado,
el mensaje es idéntico cadena por cadena al de `HEAD`. Si el criterio no puede
fallar en la prueba, la prueba está mal y se endurece antes de commitear.

### F2 — P-90: el escape temporal en el escenario del cron

Solo medición y, si corresponde, documentación. **No toques la guarda del
contrato temporal (D31): aflojarla es decisión del titular.**

1. Reproduce en subproceso el escenario del cron: corte y captura del mismo día.
2. Observa si el escape temporal se necesita, y regístralo con la evidencia
   literal de lo que la guarda imprime.
3. **Si el escape no se necesita:** P-90 se cierra con esa evidencia y una nota
   en el log. Sin cambio de código.
4. **Si el escape se necesita:** te detienes y reportas (regla de detención,
   caso 3). Un escape que se vuelve rutina deja de ser escape, y esa es decisión
   del titular, no tuya.
5. Si hubo cambio documental, commit `docs(p90): escenario del cron verificado`.

**Criterio de éxito de F2:** veredicto con evidencia literal de la salida de la
guarda en el escenario reproducido, no una lectura del código que lo predice.

### F3 — Auditoría, log, PR

1. **Panel adversarial de dos agentes de solo lectura**, con código propio, que
   re-deriven de forma independiente las dos afirmaciones de mayor riesgo: (a)
   que el mensaje de recuperación nombra el paso 37 y no manda a regenerar lo
   equivocado; (b) que nada publicado cambió, por md5 sobre `40_salidas/json/` y
   `docs/data/` contra `HEAD`. Un check escrito por el mismo flujo que produjo
   el cambio hereda sus puntos ciegos.
2. Corrida completa de `run_all()` con el fusible armado, reportando pasos,
   duración y llamadas de red (que deben ser cero).
3. Log según §6, en
   `50_documentacion/andamios/logs/<AAAAMMDD>_p86_p90_log.md`, con la fecha
   tomada de `Sys.Date()` en la corrida. **No hardcodees la fecha.**
4. Push de la rama y `gh pr create -R tomgc/transparencia_legislativa_chile`.
   **No mergeas.**

**Criterio de éxito de F3:** panel con veredicto y código propio de cada agente;
`run_all()` completo con cero red; PR abierto con su número reportado.

---

## §4. Auto-auditoría antes de reportar

Antes de reportar nada como hecho, comprueba el estado real, no el supuesto.
Tres trampas que este proyecto ya pisó y que aplican aquí:

- **Falso verde por criterio blando.** Un criterio que acepta cualquier salida
  no vacía cuenta como conforme un escenario que falló de verdad. Antes de
  aceptar un verde, comprueba que el criterio **puede** dar rojo.
- **Falso verde por comando que falla hacia el éxito.** Un `grep -c` sobre una
  salida vacía devuelve una cifra perfectamente creíble.
- **Presencia de nodo no es presencia de dato.** Si cuentas por existencia de un
  campo o de una entrada, comprueba que no viene vacío.

---

## §5. Reporte final al chat

Devuelve, en este orden: veredicto de las siete hipótesis de §0.2; el resultado
A o B de F0bis con sus tres observaciones; el mensaje literal del `stop()` antes
y después del cambio; el veredicto de P-90 con su evidencia; el estado de cada
🔒 con PASA o FALLA y su evidencia; los hashes de los commits; el número del PR;
la ruta del log; y todo lo que quedó abierto, con marcas `# REVISAR` si las hay.

---

## §6. Plantilla del log (incrustada; no vive en el filesystem)

Diez secciones, en este orden:

1. **Resumen de la sesión:** qué entró, en cuántas fases, estado final.
2. **Inventario de commits:** todos, en orden, hash corto, tipo, título y una
   línea de qué hizo cada uno, agrupados por fase.
3. **Por cada cambio sustantivo:** qué, por qué, archivos tocados, cómo se
   verificó, decisiones o tensiones resueltas. Causa raíz, no síntoma.
4. **Auditoría de diagnóstico:** veredicto, hallazgos con severidad, y si
   cambian cifras.
5. **Bugs encontrados y resueltos:** síntoma, causa raíz, fix, verificación.
6. **Verificación de invariantes:** la lista de 🔒 de §2, cada uno con PASA o
   FALLA y su evidencia.
7. **Decisiones registradas** en compuertas, para que queden trazables.
8. **Pendientes abiertos:** lo que no se cerró y por qué; marcas `# REVISAR`.
9. **Estado de cifras y datos críticos:** confirmación de que lo intocable quedó
   intacto, con md5 antes y después.
10. **Notas para el revisor:** qué mirar con ojo crítico, qué quedó como deuda.

El log es un andamio: registro congelado de la ejecución, honesto sobre lo que
costó, no solo sobre lo que salió bien. Va commiteado como `docs()` atómico.
