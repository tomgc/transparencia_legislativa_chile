# Encargo autónomo — P-74, acto (a): medición del contrato temporal

> **Destino:** `50_documentacion/andamios/50_encargo_p74_medicion_contrato_temporal.md`
> **Modo:** Ultracode, dirigido por invariantes y criterios, no por fases prescritas.
> **Alcance:** medición **read-only**. Este encargo NO decide el contrato ni lo
> implementa: produce la evidencia con la que el titular decide en el acto (b).

---

## §0. Separación de lo respaldado y lo hipotético

El cuerpo de este encargo **no puede afirmar nada que no esté en esta tabla**. Si
necesitas un dato que no aparece aquí, es hipótesis y se mide en una compuerta antes
de usarlo. Esta regla existe porque el patrón de error más frecuente del proyecto
(`PAT-01`) es afirmar una ruta, un nombre de campo o una cifra desde un documento en
vez de desde el archivo que ese documento describe.

### Respaldado por lectura o comando de la sesión 18

| Afirmación | Fuente |
|---|---|
| `CORTE_FECHA <- "2026-08-03"` en `10_utils/10_configuracion.R:41` | `grep -n` ejecutado en la sesión 18 |
| `ANIO_PROCESO <- 2026L` en `10_utils/10_configuracion.R:27` | mismo comando |
| `main` en `a22a8da`, working tree limpio, 0 PRs abiertos | `git log` / `git status --porcelain` / `gh pr list` de la sesión 18 |
| Existen `10_utils/10_utils.R`, `10_utils/10_configuracion.R`, `10_utils/10_diff_conteos.R` | escáner del 2026-08-08 14:59:21, líneas 9-11 |
| `30_procesamiento/` contiene 32, 33, 34, 35, 36 y 39 | escáner del 2026-08-08 14:59:21, líneas 2453-2458 |
| Existe `20_insumos/camara/20260803_detalle_proyectos_xml_2026_tope-inf.rds` | escáner del 2026-08-08 14:59:21, línea 55 |

### Hipótesis heredadas del traspaso v17 (verificar antes de usar, nunca citar)

| Hipótesis | Cómo se verifica |
|---|---|
| El nodo `Votaciones` aporta 14 campos, 6 con atributo de dominio (código y glosa) | compuerta G1 |
| `proyectos_detalle.rds` tiene 20 columnas y una fila por boletín, con list-col de votaciones y escalar `n_votaciones` | compuerta G1 |
| El universo son 381 boletines y 723 nodos de votación | compuerta G4, con denominador propio |
| Existe al menos un evento posterior al corte (una votación del 2026-08-04 en la captura del corte `20260803`) | objetivo M1; es lo que este encargo debe cuantificar, no asumir |
| Hay seis intermedios sellados y `validar_corte()` pasa 6 de 6 | compuerta G3 |
| El nodo aún no se consume en ningún artefacto publicable | objetivo M5 |

**Los nombres exactos de columnas y campos son desconocidos para quien escribe este
encargo.** No hay ni una sola referencia a un nombre de columna en el cuerpo del
documento, y eso es deliberado: si aparece uno, es un error de redacción y debe
reportarse en vez de obedecerse.

---

## §1. Invariantes (violarlos invalida la corrida entera)

1. **Solo lectura.** Cero escrituras salvo el log de ejecución en
   `50_documentacion/andamios/logs/` y el script de medición en
   `50_documentacion/andamios/`. Nada en `20_insumos/`, `40_salidas/`, `docs/`,
   `30_procesamiento/` ni `10_utils/`.
2. **Cero red.** `camara.refrescar = FALSE`. Si algo intentara una llamada HTTP, es
   un defecto del script de medición: corrígelo, no lo justifiques.
3. **R exclusivamente**, en todo contexto. Sin `jq`, `awk`, `python`, ni `grep`/`sed`
   sobre artefactos de datos. Sin regex en `Rscript -e`: el script vive en un `.R`
   versionado y se prueba contra el insumo real.
4. **No se tocan** `sellar()`, `leer_sellado()` ni `validar_corte()`. Ni siquiera
   para "probar algo": si la medición parece exigirlo, esa exigencia es un hallazgo
   del acto (b) y se reporta.
5. **Todo conteo declara su denominador en la misma línea**, y el denominador se
   cuenta programáticamente en la misma corrida. Una cifra derivada a mano no es una
   cifra.
6. **Fallo ruidoso.** `stop()` ante cualquier supuesto no cumplido. Sin `try(...,
   silent = TRUE)`, sin `suppressWarnings()`, sin defaults silenciosos, sin
   fallbacks. Un cero solo se reporta cuando se distingue de "no medido".
7. **`git` siempre con `-C <ruta absoluta>`**; `gh` siempre con
   `-R tomgc/transparencia_legislativa_chile`; `git add` siempre con ruta acotada,
   nunca `.` ni `-A`.
8. **Prohibido implementar.** Ningún filtro, ninguna aserción nueva en el pipeline,
   ninguna edición del 36. La medición termina en evidencia, no en código de
   producción.

---

## §2. Compuertas de precondición

Cada una se responde **con archivo y línea, o con la salida literal de la lectura**,
antes de tocar nada de lo que sigue. Una compuerta sin responder detiene la corrida;
una compuerta respondida "por lo que dice el traspaso" es una compuerta fallida.

- **G1. Forma real del intermedio del paso 36.** Lee el `.rds` que produce el paso 36
  y reporta: ruta absoluta, `nrow()`, `names()` completo, y para la columna que
  contenga las votaciones, la estructura de un elemento (`names()` y `class()` de
  cada campo). No asumas cuántos campos hay: cuéntalos.
- **G2. Campos de fecha del nodo.** De los campos de G1, identifica cuáles contienen
  fechas. Reporta por cada candidato: nombre, `class()`, formato observado y cinco
  valores reales de ejemplo. Si un campo parece fecha pero es `character` sin formato
  estable, dilo: eso cambia la vía de filtrado.
- **G3. Inventario de intermedios.** Enumera los intermedios sellados que el pipeline
  produce hoy, con ruta absoluta, `nrow()` y `names()` de cada uno. El número es un
  resultado de este barrido, no un dato de entrada.
- **G4. Universo y denominadores.** Cuenta programáticamente, en esta corrida: número
  de boletines, número total de eventos de votación en el nodo, y número de boletines
  con nodo no vacío. Cada uno con su denominador.
- **G5. Alcance temporal del crudo.** Verifica si el XML crudo capturado bajo la
  clave del paso 36 contiene fechas que el parser descarta. Responde sí o no con
  evidencia: determina si el exceso temporal nace en la captura o en la derivación,
  porque de eso depende cuál de las dos vías del acto (b) es siquiera posible.
- **G6. Fecha de corte efectiva.** Lee `CORTE_FECHA` desde
  `10_utils/10_configuracion.R` en el momento de la corrida (no desde este encargo) y
  reporta el valor leído. Si difiere de `2026-08-03`, no adaptes nada: repórtalo y
  sigue con el valor leído.

---

## §3. Objetivos de medición

- **M1. Exceso temporal en el nodo.** Por cada campo de fecha identificado en G2:
  número de eventos con fecha posterior a `CORTE_FECHA`, sobre el total de eventos
  (denominador de G4). Además, la fecha máxima observada y el número de boletines
  afectados, con su denominador.
- **M2. Barrido de los seis intermedios.** El mismo conteo para cada intermedio de
  G3 y cada uno de sus campos de fecha. **Distingue explícitamente tres estados por
  intermedio:** (i) sin ningún campo de fecha, (ii) con campo de fecha y cero eventos
  posteriores al corte, (iii) con eventos posteriores al corte y cuántos. Un
  intermedio sin campos de fecha y uno con cero excesos no son el mismo resultado, y
  colapsarlos sería el `PAT-02` de esta corrida.
- **M3. Veredicto de generalidad.** ¿El defecto es exclusivo del nodo rescatado en la
  sesión 17, o el sello deja pasar contenido posterior al corte en más de un
  intermedio? Veredicto explícito, contrastable en ambos sentidos, con la evidencia
  de M2 como respaldo.
- **M4. Costo de la vía "filtrar al derivar".** Cuántos eventos y cuántos boletines
  quedarían fuera si el paso 36 acotara el nodo a `CORTE_FECHA`, con denominador. Si
  el filtro dejara algún boletín con nodo vacío que hoy no lo está, cuéntalo aparte:
  es el efecto secundario que puede cambiar la decisión.
- **M5. Superficie de consumo actual.** ¿Consume hoy algún script del pipeline, o
  algún artefacto de `40_salidas/json/`, los campos del nodo? Determínalo leyendo los
  scripts y las claves reales del JSON, no un comentario de código (A70). Si la
  respuesta es "ninguno", esa es la razón por la que P-74 todavía es barato, y hay
  que decirlo con evidencia.
- **M6. Comportamiento del sello ante el exceso.** Sin modificar nada, documenta qué
  hace hoy `validar_corte()` frente a un intermedio con contenido posterior al corte:
  qué compara exactamente y por qué el exceso no produce ruido. Es la evidencia que
  el acto (b) necesita para elegir entre acotar al derivar y validar contenido.

---

## §4. Criterios de éxito (contrastables, no silenciosamente aprobables)

Cada criterio se reporta como CUMPLE o NO CUMPLE **con la cifra que lo sostiene**.
"No se encontraron problemas" no es un resultado: el criterio debe poder fallar.

| # | Criterio | Cómo falla |
|---|---|---|
| C1 | Las seis compuertas están respondidas con lectura directa, cada una con ruta y salida | Alguna se respondió citando el traspaso v17 |
| C2 | Todo campo de fecha del nodo tiene su conteo de exceso con denominador contado en la corrida | Un campo quedó sin medir "porque no parecía relevante" |
| C3 | Los intermedios de G3 están clasificados en los tres estados de M2, sin colapsar (i) con (ii) | Un intermedio reportado como "0" sin decir si tiene campo de fecha |
| C4 | El veredicto de M3 se afirma en ambos sentidos y no solo en el que confirma la hipótesis heredada | El veredicto solo cita evidencia a favor |
| C5 | M4 reporta el costo del filtro con denominador y cuenta aparte los boletines que quedarían vacíos | Se reporta un total sin descomponer |
| C6 | M5 se resuelve leyendo scripts y claves reales del JSON | Se resolvió leyendo un comentario o el traspaso |
| C7 | Cero escrituras fuera de `andamios/` y `andamios/logs/`, verificado con `git status --porcelain` al terminar | Aparece cualquier otra ruta modificada |
| C8 | Cero llamadas HTTP en toda la corrida, contadas | El conteo no se instrumentó |
| C9 | `sellar()`, `leer_sellado()` y `validar_corte()` idénticos a `HEAD`, verificado por diff | Hay diferencia, aunque sea un comentario |

---

## §5. Panel adversarial (cuatro agentes, antes de dar por cerrada la corrida)

1. **El que duda del denominador.** Toma cada cifra del reporte y pregunta sobre qué
   se contó. Cualquier cifra cuyo denominador no esté en la misma línea vuelve.
2. **El que busca el falso verde.** Revisa cada CUMPLE y construye el escenario en
   que ese criterio pasaría estando el sistema roto. Si lo encuentra, el criterio
   está mal escrito y se reescribe antes de responderlo.
3. **El que defiende la vía contraria.** Argumenta que filtrar al derivar es un error
   y que el corte debería ser propiedad del contenido validado por el sello. Su
   trabajo es dejar la decisión del acto (b) genuinamente abierta, no ratificar la
   preferencia del encargo.
4. **El que revisa el §0.** Barre el reporte buscando afirmaciones que vengan del
   traspaso v17 y no de una lectura de la corrida. Cada una que encuentre se degrada
   a hipótesis o se mide.

---

## §6. Entregable

Un log en `50_documentacion/andamios/logs/AAAAMMDD_p74_medicion_log.md` con: las seis
compuertas respondidas, los seis objetivos con sus tablas de cifras, los nueve
criterios con CUMPLE o NO CUMPLE y su cifra, el resultado de los cuatro agentes, y
una sección final de **tres a cinco líneas** que diga qué decisión queda habilitada y
qué queda todavía indeterminado. El script de medición queda versionado junto al log.

**No propongas la decisión del acto (b).** Si al terminar te parece obvia, esa
impresión va en una línea al final del log, marcada como opinión, y nada más.
