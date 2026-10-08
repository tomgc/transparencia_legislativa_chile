# Encargo autónomo — P-74, acto (b): contrato temporal, vía (C) con (A) de contención

> **Destino:** `50_documentacion/andamios/50_encargo_p74_acto_b_contrato_temporal.md`
> **Modo:** Ultracode, dirigido por invariantes y criterios, no por fases prescritas.
> **Decisión del titular (sesión 18):** vía **(C)** como contrato, con la vía **(A)**
> como contención inmediata. La vía (B) queda descartada en esta sesión.
> **Precede:** el acto (a), cuyo log es
> `50_documentacion/andamios/logs/20260808_p74_medicion_log.md` (commit `0a0a87c`).

---

## §0. Separación de lo respaldado y lo hipotético

El cuerpo de este encargo **no puede afirmar nada que no esté en esta tabla**. Si
necesitas un dato que no aparece aquí, es hipótesis y se mide en una compuerta antes
de usarlo. En particular: quien redacta este encargo **no ha leído `10_utils.R` ni
`36_extraer_detalle_proyectos.R` en esta sesión**; todo número de línea que aparezca
abajo viene del log del acto (a) y se re-verifica en las compuertas.

### Respaldado por medición del acto (a) o comando de la sesión 18

| Afirmación | Fuente |
|---|---|
| `main` en `0a0a87c`, sincronizado con `origin/main`, working tree limpio | `git push` / `git log -2` / `git status --porcelain` de la sesión 18 |
| `CORTE_FECHA <- "2026-08-03"`, `ANIO_PROCESO <- 2026L` | `grep -n` sobre `10_utils/10_configuracion.R`, sesión 18 |
| El nodo aporta **20** campos (no 14), uno solo de fecha (`fecha`, `character`, ISO, ancho 19, 723 de 723) | log acto (a), G1 y G2 |
| **1 de 723** eventos posterior al corte; boletín `16569-25`, `votacion_id 89587`, `2026-08-04T13:05:07` | log acto (a), M1 |
| Filtrar por corte deja **722 de 723** eventos y **0 de 115** boletines vacíos | log acto (a), M4 |
| **0** consumidores del nodo: 0 de 17 campos exclusivos en código fuera del productor y 0 de 17 en las 106 claves de 156 JSON | log acto (a), M5 |
| `validar_corte()` solo referencia `$corte_fecha` y devuelve `TRUE` con el exceso presente | log acto (a), M6 |
| 7 de 8 capturas del corte `20260803` se commitearon el 2026-08-03 13:53; la del XML del 36, el 2026-08-08 13:07 | log acto (a), M3, con `git log -1 --format=%ad` por archivo |
| **176 de 723** eventos anteriores a 2026-01-01, en 29 de 115 boletines | log acto (a), M1, hallazgo lateral |

### Hipótesis a verificar en compuerta (nunca a citar)

| Hipótesis | Compuerta |
|---|---|
| `con_cache()` es el único punto donde el pipeline descarga y persiste captura | G1, G2 |
| `corte_para_clave()` construye la clave desde `CORTE_FECHA` y no desde `Sys.Date()`, por decisión de diseño declarada en un comentario | G1 |
| Las 8 capturas existentes no llevan ningún registro de su fecha de descarga | G3 |
| El paso 36 calcula `n_votaciones` como escalar derivado del list-col | G4 |
| `escribir_atomico()` preserva atributos de R al persistir | G5 |

---

## §1. Qué se construye

**(C) El contrato.** Una captura debe poder demostrar que se tomó dentro del corte
que su clave declara. Dos piezas:

- **C-guarda de escritura.** En el momento en que el pipeline va a descargar y
  persistir una captura nueva, si la fecha de esa descarga es **posterior** a
  `CORTE_FECHA`, la corrida se detiene con `stop()` y un mensaje accionable (avanzar
  `CORTE_FECHA` o declarar explícitamente la excepción). Esto es exactamente lo que
  no existía el 2026-08-08 y por lo que la captura del 36 quedó fuera de su corte.
- **C-registro.** Toda captura nueva persiste su fecha real de descarga junto al
  dato. Las 8 capturas existentes **no se reescriben** (`20_insumos/camara/` es crudo
  inmutable, D24) y por lo tanto quedan como `sin_registro`, que **no se imputa ni se
  interpreta como cumplimiento**: es un tercer estado, no un cero.
- **C-reporte.** `run_all()` emite, al terminar, el estado temporal de cada captura:
  `dentro_de_corte`, `fuera_de_corte` o `sin_registro`, con su denominador. Reportar
  no es lo mismo que detener: `fuera_de_corte` en una captura ya existente se reporta
  ruidosamente; solo la escritura nueva se detiene.

**Escape declarado, no default.** Debe existir una forma explícita de capturar fuera
de corte (opción nombrada, apagada por defecto, jamás inferida del entorno). Cuando
se usa, la captura queda marcada como tal en su registro, para que la excepción sea
visible aguas abajo en vez de indistinguible.

**(A) La contención.** El paso 36 acota el nodo `Votaciones` a `fecha <= CORTE_FECHA`
al derivar, y **reporta cuántos eventos descartó sobre cuántos**. Un descarte
silencioso sería justo el defecto que este encargo corrige: el conteo de descartados
se emite y queda en el log de la corrida. `n_votaciones` se recalcula después del
filtro, nunca antes.

**Fuera de alcance, explícitamente.** El borde inferior (176 de 723 eventos
anteriores a `ANIO_PROCESO`) **no se toca en este encargo**: no hay decisión del
titular sobre él y acotarlo por iniciativa propia cambiaría el dato sin mandato. Si
la implementación lo hace más fácil o más difícil de abordar después, dilo en el log.

---

## §2. Invariantes (violarlos invalida la corrida entera)

1. **No se tocan** `sellar()`, `leer_sellado()` ni `validar_corte()`. La vía (B) fue
   descartada; si la implementación parece exigirlas, esa exigencia es un hallazgo y
   se reporta en vez de ejecutarse.
2. **`20_insumos/camara/` es crudo inmutable.** Ninguna de las 8 capturas existentes
   se reescribe, se renombra ni se borra. Verificado por md5 al abrir y al cerrar.
3. **Cero red.** `camara.refrescar = FALSE` en toda la corrida. La regeneración parte
   de la captura ya versionada. Si algo intenta un HTTP, es un defecto: corrígelo.
4. **R exclusivamente**, en todo contexto. Sin `jq`, `awk`, `python`, ni `grep`/`sed`
   sobre artefactos de datos. Sin regex en `Rscript -e`.
5. **Fallo ruidoso.** `stop()` ante supuesto no cumplido. Sin `try(..., silent =
   TRUE)`, sin `suppressWarnings()`, sin defaults silenciosos, sin fallbacks. Ningún
   descarte de datos sin su conteo con denominador.
6. **`sin_registro` no se imputa**, ni en el dato ni en la presentación. Una captura
   sin fecha de descarga no es una captura conforme.
7. **Trabajo en rama y PR.** Rama `feat/contrato-temporal-p74`; PR abierto, **sin
   merge**: el merge es del titular. `git` siempre con `-C <ruta absoluta>`, `gh`
   siempre con `-R tomgc/transparencia_legislativa_chile`, `git add` siempre con ruta
   acotada, nunca `.` ni `-A`.
8. **`gh pr diff --name-only` está prohibido** (HTTP 406 en PRs grandes). Usar
   `gh api` paginado sobre `/pulls/<n>/files` y declarar el denominador.

---

## §3. Compuertas de precondición

Cada una se responde **con archivo, línea y salida literal de la lectura**, antes de
escribir código. Una compuerta respondida citando el log del acto (a), este encargo o
el traspaso v17 es una compuerta fallida.

- **G1. Anatomía de `con_cache()`.** Reporta su rango de líneas, su firma exacta, el
  punto donde ocurre la descarga y el punto donde ocurre la escritura, y si esos dos
  puntos están o no en la misma función. La guarda de (C) tiene que colgar del punto
  de descarga; si están separados, dilo antes de elegir dónde va.
- **G2. Todos los llamadores.** Enumera con `list.files()` + lectura (no a mano) cada
  invocación de `con_cache()` en el pipeline, con archivo y línea. La guarda debe
  cubrirlos a todos o declarar cuáles quedan fuera y por qué.
- **G3. Estado de las 8 capturas.** Para cada `.rds` de `20_insumos/camara/`: `md5`,
  `names()` y `attributes()`. Confirma programáticamente que ninguna trae hoy un
  registro de fecha de descarga; si alguna lo trajera, el diseño de (C) cambia y hay
  que reportarlo antes de seguir.
- **G4. Punto de derivación del nodo.** Ubica, con archivo y línea, dónde el paso 36
  construye el list-col de votaciones y dónde calcula `n_votaciones`. El filtro de
  (A) va entre ambos; si `n_votaciones` se calcula antes, dilo: es la trampa de este
  encargo.
- **G5. Persistencia de atributos.** Determina empíricamente si el mecanismo de
  escritura que usa el proyecto conserva atributos de R al persistir y releer. Si no
  los conserva, el registro de (C) no puede ser un atributo y hay que elegir otra
  forma; decídelo con la prueba, no con la expectativa.
- **G6. Línea base de neutralidad.** Registra el md5 de los 156 artefactos de
  `40_salidas/json/` **antes** de tocar nada, para poder comparar al cerrar. Declara
  el denominador.

---

## §4. Criterios de éxito (contrastables, no silenciosamente aprobables)

Cada criterio se reporta como CUMPLE o NO CUMPLE **con la cifra que lo sostiene**.
Un criterio que no pueda fallar está mal escrito y se reescribe antes de responderlo.

| # | Criterio | Cómo falla |
|---|---|---|
| C1 | Las seis compuertas están respondidas con lectura directa, con archivo, línea y salida | Alguna se respondió citando el log del acto (a) |
| C2 | La guarda de escritura se dispara: con `CORTE_FECHA` retrocedido en un escenario de prueba aislado, un intento de captura nueva termina en `stop()` con mensaje accionable | La prueba no se hizo, o se hizo sobre un mock que no ejerce el camino real |
| C3 | La guarda **no** se dispara cuando la descarga cae dentro del corte | No se probó el caso negativo, así que C2 podría estar deteniendo todo |
| C4 | El escape explícito existe, está apagado por defecto y deja marca en el registro de la captura | Está encendido por defecto, o se infiere del entorno, o no deja rastro |
| C5 | Las 8 capturas existentes conservan su md5 exacto | Cualquier md5 cambió |
| C6 | El reporte de `run_all()` clasifica las capturas en tres estados y las 8 actuales salen `sin_registro`, no `dentro_de_corte` | Una captura sin fecha aparece como conforme |
| C7 | El filtro de (A) descarta **1 de 723** eventos y deja **722**, con el conteo emitido en la corrida | El conteo no se emite, o el número no coincide con M4 del acto (a) |
| C8 | `n_votaciones` se recalcula post-filtro y cuadra con las filas del list-col | Suma 723 en vez de 722 |
| C9 | **0 de 115** boletines quedan con nodo vacío tras el filtro | Alguno quedó vacío y no se contó aparte |
| C10 | Neutralidad del artefacto público: los 156 JSON idénticos a la línea base de G6, excluido `metadatos.generado`, y 0 claves nuevas | Cambió cualquier otra cosa; M5 medía 0 consumidores, así que un cambio aquí significa que M5 estaba mal |
| C11 | `run_all()` completo sin error y `validar_corte()` 6 de 6, con la red cortada y 0 llamadas HTTP contadas | No se instrumentó el contador |
| C12 | `sellar()`, `leer_sellado()` y `validar_corte()` idénticos a `HEAD`, verificado por diff con `-C <ruta absoluta>` y código de salida citado | Hay diferencia, aunque sea un comentario |
| C13 | PR abierto y **sin merge**, con el conteo de archivos obtenido por `gh api` paginado y su denominador declarado | Se mergeó, o se usó `gh pr diff --name-only` |

---

## §5. Panel adversarial (cuatro agentes, antes de dar por cerrada la corrida)

1. **El que duda del denominador.** Toma cada cifra del reporte y pregunta sobre qué
   se contó. Cualquier cifra sin denominador en la misma línea vuelve.
2. **El que busca el falso verde.** Por cada CUMPLE, construye el escenario en que
   ese criterio pasaría estando el sistema roto. Presta atención especial a C2 y C3:
   una guarda que no se probó en ambos sentidos no está probada.
3. **El que ataca la guarda.** Su trabajo es encontrar el camino por el que una
   captura fuera de corte llega igual a disco: un llamador de `con_cache()` no
   cubierto, un reintento, el bot semanal de GitHub Actions, o el escape explícito
   usado sin dejar marca. Cada camino que encuentre se cierra o se declara.
4. **El que revisa el §0.** Barre el reporte buscando afirmaciones que vengan de este
   encargo o del log del acto (a) y no de una lectura de esta corrida. Cada una se
   degrada a hipótesis o se mide.

---

## §6. Entregable

Un log en `50_documentacion/andamios/logs/AAAAMMDD_p74_acto_b_log.md` con: las seis
compuertas respondidas, la descripción de lo construido con archivo y línea, los
trece criterios con CUMPLE o NO CUMPLE y su cifra, el resultado de los cuatro agentes
y el número del PR abierto. Más una sección final de **tres a cinco líneas** con lo
que quedó indeterminado.

Redacta además, para que el titular las ratifique en el cierre, la decisión de
arquitectura **D31** en una o dos oraciones: qué afirma ahora una captura sobre su
propio alcance temporal, y qué sigue sin afirmar.
