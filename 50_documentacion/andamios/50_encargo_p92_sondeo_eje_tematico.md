# Encargo autónomo — P-92: sondeo de las cuatro vías derivadas del eje temático

Sesión 22 · proyecto `transparencia_legislativa_chile`

---

## Encabezado de contrato

**MODO:** ejecución autónoma, secuencial, todo en este turno. No pidas
aclaraciones antes de empezar.

**NATURALEZA: sondeo de solo lectura.** No tocas `30_procesamiento/`, `10_utils/`,
`00_run_all.R`, `docs/` ni `40_salidas/`. No escribes un byte bajo
`20_insumos/`. No propones contrato de datos ni implementas nada. **Este encargo
mide y no construye.** Si al final de la medición el eje es viable, lo dirá el
documento, no el código.

**REGLA DE DETENCIÓN.** Te detienes y reportas, sin escribir nada más, solo en
estos tres casos:

1. Una hipótesis de §0.2 resulta falsa **y** su falsedad cambia el diseño de una
   fase posterior (no basta con que sea falsa: si es cosmética, la corriges, la
   declaras y sigues).
2. Un invariante de §2 te obligaría a hacer dos cosas incompatibles.
3. Una fase exige una decisión de **metodología o de clasificación** que este
   encargo no resolvió. La clasificación temática es autoridad del titular; tú
   mides, no decides qué es un tema.

**PRESUPUESTO DE RED: 300 llamadas HTTP.** Cuéntalas y repórtalas. Si llegas a
250, detente y reporta antes de gastar el resto.

**ENTORNO.** Filesystem local vía Claude Code.
Raíz: `/Users/tomgc/Projects/transparencia_legislativa_chile`.

**LENGUAJE.** R es el único lenguaje, en todo contexto, incluida la inspección de
solo lectura. Nada de `awk`, `jq`, `sed` ni Python. `git`, `gh`, `ls`, `grep` y
`wc` son herramientas de repositorio, no de datos.

**POSICIÓN.** Toda ruta completa desde la raíz. `git` con `-C <raíz>`, `gh` con
`-R tomgc/transparencia_legislativa_chile` salvo `gh api`, `git add` con ruta
acotada siempre.

---

## §0. Contrato positivo

### §0.1 Afirmaciones respaldadas

Ninguna es lectura del código ni de la API actual: el redactor no tuvo acceso al
filesystem. Son afirmaciones sobre lo que otros documentos declaran.

| # | Afirmación | Fuente |
|---|---|---|
| R1 | El catálogo `retornarMaterias` existe, tiene 8518 entradas con Id entero único, es plano y fue estable entre 2026-07-10 y 2026-08-07 | `50_catalogo_fuentes_camara.md`, tabla de `retornarMaterias` |
| R2 | El eslabón `proyecto → materia` cubre 5 de 381 boletines (1,31 %) al 2026-08-07, y 5 de 427 al 2026-08-12 | `50_veredicto_eje_tematico.md` §2 y `50_veredicto_fuentes_tematicas_bcn.md` §58 |
| R3 | LeyChile y `datos.bcn.cl` dan 0 de 422 boletines sin materia; P-68 cerró con NO | `50_veredicto_fuentes_tematicas_bcn.md` §1 |
| R4 | De 791 votaciones, 546 son de tipo `Proyecto de Ley`; el resto no enlaza a boletín | `50_veredicto_eje_tematico.md` §2 y §3 |
| R5 | 44 de 199 autores quedan fuera del padrón vigente por ser del período anterior; hay fuente histórica (`retornarDiputados`, 633 diputados) | `50_veredicto_eje_tematico.md` §2 |
| R6 | Existe un mapa partido → tendencia en el proyecto desde la sesión 2 | `backlog_acumulativo.md`, entrada 6 |
| R7 | El sitio `camara.cl` expone un buscador de votaciones con criterio "por Materia" implementado como postback ASP.NET (`link_PorMateria`), y el campo rotulado "Materia" en el listado y en el detalle **es el título del proyecto**, no un descriptor | `camara.cl/legislacion/sala_sesiones/votaciones.aspx` y `votacion_detalle.aspx?prmIdVotacion=89693`, leídas el 2026-08-13 |
| R8 | Los números de boletín llevan sufijo numérico: `16300-07`, `18030-12`, `18210-06`, `17012-14`, `18575-11` | las mismas dos páginas |
| R9 | Ninguno de los cuatro documentos de fuentes y veredictos menciona el sufijo del boletín, el HTML de `camara.cl` ni la clasificación propia como vía temática | `grep` sobre los cuatro archivos, 2026-08-13, 0 coincidencias |

### §0.2 Hipótesis, con su comando de verificación

| # | Hipótesis | Verificación |
|---|---|---|
| H1 | El universo vigente de boletines es 427 y el de votaciones 842 | recuento en R sobre `40_salidas/intermedios/proyectos_detalle.rds` y `votos.rds`, leyendo su sello en el mismo turno |
| H2 | Todo boletín del universo tiene forma `NNNNN-NN` y el sufijo es extraíble sin ambigüedad | recuento de los que **no** matchean, con los casos listados |
| H3 | Existe un catálogo oficial código→glosa para ese sufijo, publicado por la Cámara o la BCN | sondeo de F2; **si no aparece, la vía 1 queda sin glosa y eso se declara, no se inventa (D42)** |
| H4 | El intermedio de votos trae un campo de texto descriptivo por votación (materia o artículo) con cobertura alta, también para las votaciones sin boletín | recuento por `is.na()` y por cadena vacía sobre `votos.rds`, con el denominador declarado |
| H5 | El padrón permite mapear cada votante a partido y a tendencia | recuento sobre `diputados.rds` y el mapa de R6, con los no mapeados listados |
| H6 | Existe una noción de bancada distinta de partido, con fuente | sondeo de F5; si no la hay, se trabaja con partido y tendencia y se declara |
| H7 | El buscador "por Materia" de `camara.cl` devuelve un catálogo cerrado de materias y no un campo de texto libre | F3; se responde ejecutando el postback, no leyendo el HTML estático |

**H3 y H7 no se resuelven por lectura ni por memoria: se resuelven consultando.**

---

## §1. La pregunta que este sondeo debe poder responder

Literal del titular, y es el criterio contra el cual se juzga todo lo demás:

> *¿qué temas importan más a qué partidos o facciones políticas (derecha-izquierda)?*

De ahí se sigue lo que **no** cuenta como éxito:

- Un eje que cubra proyectos pero no votos. La pregunta es sobre cómo se vota.
- Un eje que cubra solo los 546 proyectos de ley y deje fuera las resoluciones.
  Las resoluciones son donde las facciones se retratan con menos costo.
- Un eje con cobertura alta pero **degenerado**: si todas las tendencias votan
  igual en todos los temas, el eje no distingue nada aunque cubra el 100 %.

---

## §2. Invariantes (🔒)

- 🔒 **Solo lectura sobre el pipeline y sobre los datos publicados.** Nada bajo
  `20_insumos/`, `40_salidas/`, `docs/`, `30_procesamiento/`, `10_utils/` ni
  `00_run_all.R` se modifica. Todo lo que este encargo escriba vive bajo
  `50_documentacion/andamios/`.
- 🔒 **No se fabrica ningún catálogo código→glosa (D42).** Si no hay fuente
  oficial para la glosa de un código, el código se reporta desnudo y se dice que
  no tiene glosa. Inventar nombres de materia a partir de lo que parece razonable
  es el fallo exacto que D42 prohíbe.
- 🔒 **Toda cobertura se declara con su universo y su denominador en la misma
  línea**, contados programáticamente en el mismo turno. Sin excepción.
- 🔒 **Todo control positivo se declara antes de correrlo, con su umbral.** Una
  cobertura de 0 sin control positivo de la misma consulta no se reporta.
- 🔒 **HTTP 200 no es prueba de nada.** El SIL devolvió 200 con cuerpo de 24 bytes
  en los controles negativos. Verifica el cuerpo, no el código.
- 🔒 **Presencia de nodo no es presencia de dato.** Cuenta por contenido no vacío.
- 🔒 **R único lenguaje.** `git` con `-C`, `gh` con `-R` salvo `gh api`.
- 🔒 **`main` sin push directo. No mergeas.**
- 🔒 **La clasificación temática es autoridad del titular.** Puedes construir un
  léxico de prueba para **medir** si la vía funciona; no puedes declarar cuál es
  el conjunto de temas del portal.

---

## §3. Fases

### F0 — Arranque, commit del propio encargo, universo real

**Este bloque incluye su propio commit**, porque el encargo llega sin trackear y
bloquea la compuerta de árbol limpio de su propia ejecución.

1. `git -C <raíz> checkout -b sondeo/p92-eje-tematico`
2. `git -C <raíz> add 50_documentacion/andamios/50_encargo_p92_sondeo_eje_tematico.md`
   y commit `docs(p92): encargo del sondeo tematico`.
3. `git -C <raíz> fetch origin`, `rev-parse main origin/main`, `status --porcelain`.
   **Nota:** puede existir la rama `fix/p86-runner-paso37` con PR #16 sin mergear.
   Ramifica desde `main`, no desde ella.
4. `CORTE_FECHA` leído de `10_utils/10_configuracion.R`, con su línea.
5. Universo: H1, H2, H4, H5 verificadas con recuento propio y denominador
   declarado. Lista explícita de los boletines que **no** matchean `NNNNN-NN`.
6. Fusible de red armado (`quit(99)`) para todo lo que no sea una llamada
   contabilizada del presupuesto de §0.

**Criterio de éxito:** las seis hipótesis medibles aquí con veredicto, evidencia
de archivo y línea, y el universo contado, no heredado.

### F1 — Vía 1: el sufijo del boletín

1. **Cobertura estructural:** cuántos de los boletines del universo tienen sufijo
   extraíble. Distribución de frecuencias por sufijo, número de categorías
   distintas, y el tamaño de la categoría más grande como fracción del total (una
   vía que manda el 60 % a una sola categoría no discrimina).
2. **Control positivo, declarado antes de correrlo:** los 5 boletines que sí
   traen materia oficial son el patrón de oro. **Umbral: el sufijo debe ser
   coherente con la materia oficial en al menos 4 de 5.** Reporta los 5 casos con
   su sufijo, su materia oficial y tu juicio de coherencia, **caso por caso y con
   el texto de ambos a la vista**, para que el titular pueda revisarlo.
3. **Control de discriminación:** cruza sufijo contra las palabras del título del
   proyecto. Si el sufijo es informativo, los títulos de una misma categoría
   comparten vocabulario más que los de categorías distintas. Mídelo con un
   estadístico simple y declara cuál usaste y por qué.
4. **Prueba de estabilidad semántica:** el sufijo es asignado al ingreso y refleja
   la comisión de origen, que puede no ser la que tramita. Mide en cuántos casos
   la comisión que aparece en la tramitación del SIL difiere de lo que el sufijo
   sugiere. Esto acota la validez de la vía y es el hallazgo más importante de F1.

**Criterio de éxito, contrastable en ambos sentidos:** la vía 1 pasa si cubre más
del 95 % del universo, produce al menos 10 categorías no degeneradas y supera el
control positivo 4 de 5. **Falla si cualquiera de las tres condiciones no se
cumple**, y se reporta como fallo, no como matiz.

### F2 — La glosa del sufijo: ¿existe catálogo oficial?

Un código sin glosa no es un eje navegable: nadie busca "tema 07".

1. Sondea, con presupuesto acotado y contando llamadas: los servicios `.asmx` ya
   catalogados en `50_catalogo_fuentes_camara.md` (usa ese documento como mapa, no
   redescubras), el sitio de comisiones permanentes de la Cámara, y la BCN.
2. **Control negativo obligatorio:** una consulta que no debería devolver nada.
   Si devuelve algo, el sondeo no discrimina y su resultado no vale.
3. **Si no aparece catálogo oficial:** dilo. La vía 1 queda usable como agrupador
   pero sin nombre publicable, y eso es una limitación de producto que el titular
   debe conocer antes de elegir. **No inventes glosas (D42).**

**Criterio de éxito:** veredicto sí/no sobre la existencia de catálogo oficial,
con la fuente exacta si existe y con la lista de lo intentado si no.

### F3 — Vía 2: el buscador "por Materia" de `camara.cl`

Es HTML, no API, y eso importa: una fuente raspada es frágil y hay que decirlo.

1. Ejecuta el postback `link_PorMateria` de
   `https://www.camara.cl/legislacion/sala_sesiones/votaciones.aspx`. Es ASP.NET
   WebForms: requiere `__VIEWSTATE`, `__EVENTVALIDATION` y `__EVENTTARGET`.
   Cuenta cada llamada contra el presupuesto.
2. **La pregunta a responder es H7:** ¿devuelve un `select` con catálogo cerrado
   de materias, o un campo de texto libre? Si es catálogo cerrado, **¿cuántas
   entradas tiene y coinciden con las 8518 de `retornarMaterias`?**
3. Si es catálogo cerrado y consultable, mide: para 3 materias distintas
   escogidas al azar y declaradas antes, cuántas votaciones devuelve y si esas
   votaciones están en nuestro universo.
4. **Control negativo:** una materia inexistente debe devolver vacío, no un
   listado. Verifica el cuerpo, no el 200.

**Criterio de éxito:** H7 respondida con evidencia del cuerpo de la respuesta, no
del código HTTP; y si el catálogo es cerrado, su tamaño y su intersección con el
de 8518, contados.

### F4 — Vías 3 y 4: clasificación propia sobre texto

**Vía 3** clasifica el título del **proyecto**; **vía 4** clasifica el texto de la
**votación**, que existe también donde no hay boletín. Se miden por separado y no
se mezclan: mezclarlas produce una cobertura agregada que tapa cuál la aporta.

1. Cobertura de texto disponible en cada vía, con denominador: cuántos proyectos
   tienen título no vacío; cuántas votaciones tienen texto descriptivo no vacío,
   **desagregado entre las que tienen boletín y las que no**.
2. Construye un **léxico de prueba** de entre 8 y 12 temas gruesos, con términos
   en español y sin acentos dependientes de locale. Es un instrumento de medición,
   **no una propuesta de taxonomía**: dilo explícitamente en el reporte.
3. Mide, para cada vía: fracción del universo que cae en al menos un tema;
   fracción que cae en más de uno (ambigüedad); fracción que no cae en ninguno.
4. **Control positivo:** los 5 boletines con materia oficial deben caer en un tema
   coherente con ella. Umbral declarado antes: 4 de 5.
5. **Control de sobreajuste:** aparta el 20 % del universo **antes** de escribir el
   léxico y no lo mires hasta el final. Si la cobertura en el apartado cae mucho
   respecto del resto, el léxico se ajustó a lo que viste.

**Criterio de éxito:** las cuatro cifras por vía con su denominador, el control
positivo con su umbral, y el resultado del apartado. Una vía sin control de
sobreajuste no se reporta como viable.

### F5 — La prueba que decide: ¿responde la pregunta del titular?

Esta fase es la razón de ser del sondeo. Se corre para **la vía con mejor
resultado en F1-F4**, y se declara cuál y por qué antes de correrla.

1. Verifica H5 y H6: mapeo votante → partido → tendencia, y si existe bancada
   como fuente distinta. Reporta los no mapeados con nombre.
2. Construye la tabla `tema × tendencia × resultado`: para cada tema y cada
   tendencia, la tasa de voto a favor, con el **número de votos en cada celda**.
   Ninguna celda se reporta sin su n.
3. **Prueba de no degeneración, declarada antes de correrla:** el eje sirve si
   existe al menos un tema donde la diferencia de tasa de aprobación entre las dos
   tendencias extremas supere los 20 puntos porcentuales, con al menos 100 votos
   por celda. **Si ningún tema lo logra, el eje es temáticamente real pero
   políticamente mudo, y eso hay que decirlo con todas sus letras.**
4. Repite la tabla **incluyendo y excluyendo** las votaciones sin boletín, para
   mostrar cuánto aporta la vía 4.

**Criterio de éxito:** la tabla completa con n por celda, el veredicto de la
prueba de no degeneración, y la comparación con y sin resoluciones. Si la prueba
falla, el criterio se cumple igual: un no medido es un resultado.

### F6 — Veredicto, panel adversarial, PR

1. Escribe `50_documentacion/andamios/50_veredicto_vias_tematicas_derivadas.md`
   con: veredicto por vía; la tabla de F5; las limitaciones de cada vía
   (fragilidad del raspado, validez semántica del sufijo, autoría del léxico); y
   **una recomendación al titular con las opciones abiertas**, no una decisión.
2. **Panel adversarial de dos agentes de solo lectura**, con código propio, que
   re-deriven: (a) la cobertura de la vía ganadora sobre las filas de voto; (b) la
   prueba de no degeneración de F5. **Si los agentes no pueden correr por límite
   de API o por cualquier otra causa, NO declares las afirmaciones como
   verificadas por panel: repórtalas como verificación de primera parte y déjalo
   en primer plano del reporte.** Esto pasó en el encargo anterior.
3. Log según §5, en `50_documentacion/andamios/logs/<AAAAMMDD>_p92_sondeo_log.md`,
   fecha desde `Sys.Date()`, nunca hardcodeada.
4. Muestras crudas del sondeo bajo `50_documentacion/andamios/muestras/`, nunca
   bajo `20_insumos/`.
5. Push de la rama y `gh pr create -R tomgc/transparencia_legislativa_chile`.
   **No mergeas.**

---

## §4. Auto-auditoría antes de reportar

- **Falso verde por criterio blando.** Antes de aceptar un verde, comprueba que el
  criterio **puede** dar rojo con los datos que tienes.
- **Falso verde por comando que falla hacia el éxito.** `grep -c` sobre salida
  vacía devuelve una cifra creíble.
- **Cobertura sin denominador.** Cada porcentaje con su fracción explícita.
- **La tentación de esta sesión en particular:** el titular quiere que el eje
  temático funcione y lo dijo. Un sondeo que le entrega el resultado que espera
  sin haberlo medido con controles que puedan refutarlo es peor que un no. Si las
  cuatro vías fallan, el reporte dice que fallan.

---

## §5. Plantilla del log (incrustada)

Diez secciones: (1) resumen; (2) inventario de commits; (3) cada medición con qué,
por qué, cómo se verificó; (4) auditoría de diagnóstico por vía; (5) hallazgos y
sorpresas; (6) verificación de invariantes 🔒 con PASA/FALLA y evidencia;
(7) decisiones en compuertas; (8) pendientes abiertos con `# REVISAR`;
(9) estado de cifras críticas y presupuesto de red gastado; (10) notas para el
revisor, con lo que hay que mirar con ojo crítico en primer lugar.

---

## §6. Reporte final al chat

En este orden: veredicto de las hipótesis de §0.2; una tabla de una fila por vía
con cobertura, categorías y control positivo; el veredicto de F2 sobre la glosa;
la tabla `tema × tendencia` de F5 con su prueba de no degeneración; el estado de
cada 🔒; llamadas HTTP gastadas de 300; hashes, número de PR y ruta del veredicto
y del log; y todo lo que quedó abierto.
