# Traspaso de cierre — v11

## 1. Identificación

- **Proyecto:** `transparencia_legislativa_chile`
- **Versión:** v11
- **Fecha:** 2026-07-25
- **Sesión:** 11. Foco doble: **cerrar el gate de la Capa 2** (merge a `main` y publicación) y **construir la Capa 3** (asistencia simétrica, D2), abriendo por medición de la fuente antes de diseñar.
- **Entorno:** R 4.5.2 / Positron (macOS). Claude Code para ejecución autónoma. Repo público (Rama A). Producción: `https://tomgc.github.io/transparencia_legislativa_chile/`.
- **Archivos principales modificados:** `30_procesamiento/33_extraer_asistencia.R` (bloque nominal nuevo, de 5,18K a 22,07K); `30_procesamiento/39_consolidar_json.R` (tres bloques nuevos en el perfil + `tasa_presencia` en el índice); nuevos intermedios `40_salidas/intermedios/{asistencia_nominal.rds, asistencia_ambitos.rds}`; nueva clave de caché `20_insumos/camara/20260720_asistencia_nominal_2026_tope-inf.rds`; `CLAUDE.md`; JSON regenerados en `40_salidas/json/` y `docs/data/`. `docs/index.html` NO se tocó en la Capa 3 (verificado commit por commit).

## 2. Resumen ejecutivo

Sesión de dos tramos. El primero cerró el gate que la sesión 10 dejó abierto: se verificó empíricamente que el fix de copy del frontend estaba hecho (`830919f`, `__sindato__` = 0), se versionó el residuo documental del cierre anterior (`42910a3`) y, con divergencia 0/0 contra `origin/main`, se mergeó la Capa 2 con `--no-ff` (`ac177be`) y se pusheó: el territorio quedó en producción, 155/155 con distrito y región. El segundo tramo abrió la Capa 3 con la misma disciplina que salvó a la Capa 2: medición de solo lectura antes de diseñar. La medición refutó por exceso el supuesto de D2 — la fuente entrega un nodo `Justificacion` completo (código, glosa, dos rebajas) que el `33` descartaba entero, y la serie nominal ya viaja en el response que el script descargaba, así que extender el extractor no cuesta ni una llamada nueva. El factor limitante no resultó ser el peso sino dos decisiones metodológicas del titular, que se tomaron en sesión: dos ámbitos de denominador (`periodo_vigente`, común a los 155, y `en_ejercicio`, propio de cada diputado) y dos tasas que comparten denominador (`tasa_presencia` y `tasa_presencia_o_justificada`), con las rebajas persistidas pero fuera de toda fórmula mientras su semántica siga sin documentar. La implementación entregó la serie nominal publicada como espejo de `votaciones.votos[]`, sin alterar un solo campo legacy (verificado en 155/155 y por panel adversarial 4/4). Al redactar este traspaso corre el encargo de merge de la Capa 3 a `main`; su resultado NO está confirmado.

## 3. Estado al cierre

**Qué funciona:**
- **Capa 2 en producción.** `ac177be` mergeado y pusheado (`720f4ff..ac177be`). Divergencia post-push 0/0. Territorio 155/155 en índice y perfiles.
- **Capa 3 construida y verificada** en `feat/capa3-asistencia` (sobre `ac177be`): serie nominal de 8 718 entradas publicada, dos ámbitos, dos tasas, justificación con código y glosa, tercer estado `sin_registro`.
- Campos legacy intactos: `identical()` sobre los 5 campos de `asistencia` y sobre los bloques `perfil`, `votaciones` y `proyectos` completos, 155/155 contra `git show ac177be:`, 0 diferencias. Único cambio no aditivo: `metadatos.generado`.
- Panel adversarial 4/4 con re-derivación independiente desde la API.
- `validar_corte()` pasa sobre 7 intermedios al corte 2026-07-20; `run_all()` completo con cache hit en todos los pasos, 0 llamadas.

**Qué no funciona / pendiente:**
- Nada roto. **El merge de la Capa 3 a `main` estaba en curso al redactar este traspaso: su resultado no está verificado.** La primera acción de la sesión 12 es confirmar el estado real (`git log`, divergencia, campos legacy en producción), no asumirlo.
- El workflow de GitHub Actions no se había revisado aún contra la doble descarga de asistencia (PASO 0 del encargo de merge). Si el merge se completó sin ese reporte, revisarlo antes del lunes 27.

**Delta respecto a v10:**
- `CORTE_FECHA` sin cambios: **2026-07-20** (leída de `10_utils/10_configuracion.R:41`).
- Capa 2: de rama local a producción.
- Capa 3: de pendiente a construida, sin mergear (o recién mergeada, sin confirmar).
- Dos intermedios nuevos, una clave de caché nueva, un endpoint nuevo en uso (`WSLegislativo.asmx`).
- Peso de `docs/data/`: 40 024,6 KB → **42 367,6 KB** (+5,85 %).
- Escáner: 437 → **461 archivos** (2026-07-25 07:52:57, 23 carpetas).

## 4. Registro detallado de cambios

**Cambio 1 — Versionar el residuo documental de la sesión 10.** Categoría: documentación/git. Commit `42910a3`. Al abrir, el working tree tenía sin commitear el snapshot nuevo del escáner, los aliases modificados, la poda del `20260716_*` y `traspaso_cierre_v10.md` sin trackear. Se verificó primero que `6324a2c` (cuyo mensaje anuncia "traspaso v10") NO contenía ese archivo — `--stat` toca solo `50_documentacion/estructura/`, y `ls-files` confirmaba la serie versionada hasta v09. Sin duplicado ni conflicto. Staging path-scoped. **Segunda ocurrencia consecutiva** del mismo patrón: el cierre genera el traspaso y no lo commitea (la s10 arregló lo mismo para la s9).

**Cambio 2 — Merge y publicación de la Capa 2.** Categoría: git/publicación. Merge commit `ac177be`, push `720f4ff..ac177be`. Precondiciones verificadas en orden: fix de copy presente (`830919f`) con `__sindato__` = 0 en `docs/index.html`; revisión visual del titular; compuerta A32 con `fetch` inmediatamente antes del merge, divergencia `0 0`. Merge `--no-ff`, sin conflictos (estrategia `ort`, 346 archivos, +17 168 / −4 050). Verificación antes del push sobre el estado real de `main`: 155 ocurrencias de `"distrito"` en el índice, `__sindato__` = 0, working tree limpio. Rama `feat/territorio-crosswalk` conservada.

**Cambio 3 — Medición de la fuente de asistencia (encargo de solo lectura).** Categoría: diagnóstico/exploración. Rama `feat/capa3-medicion`, commit `ca406a8`. Informe en `50_documentacion/andamios/20260725_medicion_asistencia_capa3.md`. Hallazgo central: el `33` conservaba tres columnas (`33:51-57`) y descartaba entero el nodo `Justificacion` (código `@Valor`, glosa `Nombre`, `RebajaAsistencia`, `RebajaQuorum`), que viaja en el mismo response ya descargado; la fecha y el tipo de sesión también venían gratis. De 668 inasistencias, 598 justificadas y 70 sin justificar, hoy indistinguibles. 76 llamadas a la API (el caché del corte no alcanzaba: guarda solo las 3 columnas que el `33` conservaba). Sin catálogo oficial de justificaciones: `WSSala.asmx` publica 3 operaciones, el WSDL declara `Valor` como `s:int` sin enumeración, `WSComunes.asmx` no lo cubre. Se versionó el catálogo **observado** (13 códigos, 12–29 con huecos), etiquetado como observado. Peso proyectado: +3,4 % por perfil. 7 preguntas abiertas declaradas sin rellenar.

**Cambio 4 — Decisiones metodológicas del titular (en sesión).** Categoría: decisión de diseño. Ver §8. Dos ámbitos de denominador, dos tasas con denominador compartido, rebajas fuera de toda fórmula, empaquetado 1+2 (intermedio nominal + serie embebida en el perfil), alcance del "en ejercicio" acotado a 2026 y declarado en el JSON.

**Cambio 5 — `33`: serie nominal y agregados por ámbito.** Categoría: extracción. Commit `8434c6c`. Segundo bloque en el mismo script, con clave de caché propia (`asistencia_nominal_<anio>`), que parsea nueve campos y persiste `asistencia_nominal.rds` (8 718 filas) y `asistencia_ambitos.rds` (310 filas = 155 × 2 ámbitos). El bloque nominal filtra `Estado == Celebrada` **y** `FechaInicio <= CORTE_FECHA`; el legacy sigue filtrando solo por `Estado` en el instante de la descarga (arista P6). `Encoding() <- "UTF-8"` en las glosas, comprobado con `nchar()` caracteres vs bytes (A36), no con `validUTF8()`.

**Cambio 6 — Fecha de instalación del período, leída de la API.** Categoría: datos/metodología. El encargo prohibía hardcodearla y ofrecía dos caminos; se resolvió por el primero: `WSLegislativo.asmx` (14 operaciones) expone `retornarPeriodoLegislativoActual` → período `Id 11`, `2026-2030`, `FechaInicio 2026-03-11`. Se lee en cada corte y se cachea, nunca se fija en código. Evidencia convergente: hasta el 2026-03-05 solo 71 de los 155 vigentes tienen registro; el 2026-03-11 saltan a 154. Muestra versionada en `andamios/muestras/legislativo_retornarPeriodoLegislativoActual.xml`.

**Cambio 7 — Tercer estado `sin_registro` (desviación justificada del encargo).** Categoría: modelado de datos. La matriz no es densa: 5 pares (diputado, sesión) no tienen fila en la fuente (`1074` en las sesiones 4755–4758 de marzo; `1193` en la 4800, pese a tener fila en la 4805 del mismo día). La identidad de verificación que el encargo exigía (`n_asiste + n_no_asiste == n_sesiones`) es **incompatible** con un denominador común para esos dos diputados, y forzarla exigía imputar dato o romper el denominador. El ejecutor añadió `n_sin_registro` y verificó `n_asiste + n_no_asiste + n_sin_registro == n_sesiones`, que se cumple 155/155 en ambos ámbitos. Nada imputado; la discrepancia con el encargo se reportó, no se escondió.

**Cambio 8 — El legacy conserva su propia descarga (deuda declarada).** Categoría: deuda técnica consciente. Derivar el agregado legacy del barrido nominal habría sido lo natural (una descarga, un universo), pero el universo determinista incluye la sesión **4801** (nº 45, 2026-07-20 17:00), que el snapshot legacy no alcanzó a ver marcada como celebrada: derivarlo habría sumado una sesión a los 155 y cambiado `n_sesiones` y `tasa_asistencia` publicados, violando el invariante 1. Se mantuvieron los dos caminos. **Costo asumido:** mientras el portal consuma el contrato legacy, cada refresh descarga asistencia dos veces. Marcado `# REVISAR` en la cabecera del bloque 1 del `33`. Se paga solo cuando el frontend migre.

**Cambio 9 — `39`: publicación de la Capa 3.** Categoría: consolidación. Commit `c53dfa6`. Al bloque `asistencia` del perfil se **añaden**, después de los cinco campos legacy: `alcance_temporal` (con nota legible que impide leer el acumulado como carrera completa), `periodo_vigente`, `en_ejercicio` y `sesiones[]` (espejo de `votaciones.votos[]`, ordenada por fecha, con `justificacion` anidada o `null` y marca de pertenencia al período vigente). El índice gana `tasa_presencia` **como último campo**, para no alterar el orden que el cliente recorre. El alcance viaja como atributo del intermedio (lo fija el `33` con el dato de la API); el `39` no lo re-deriva ni lo hardcodea y hace `stop()` diagnóstico si falta.

**Cambio 10 — Regeneración al corte vigente (A34).** Categoría: pipeline. Commit `11d9b0d`. `run_all()` completo, 6 pasos, **todos cache hit, 0 llamadas**. `validar_corte()` sobre 7 intermedios. Votos nominales (88 802) y proyectos (1 435) sin cambio, como corresponde a una capa que no los toca.

**Cambio 11 — Log de ejecución y `CLAUDE.md`.** Commits `a6fb735` y `ede49b2`. Log en `50_documentacion/andamios/logs/20260725_capa3_asistencia_log.md`.

**Cambio 12 (EN CURSO) — Merge de la Capa 3 a `main`.** Encargo corriendo al redactar este traspaso, con revisión previa del workflow de GitHub Actions contra la doble descarga (PASO 0), compuerta A32, merge `--no-ff`, verificación de campos legacy en 155/155 contra `ac177be` antes del push. **Resultado no confirmado: verificar al abrir la sesión 12.**

## 5. Backlog acumulativo

Vive en `50_documentacion/activa/backlog_acumulativo.md`. **Sin cambios respecto de v10: la consolidación se pospuso por decisión explícita del titular.** El canónico sigue cerrado en v06 (23 entradas); las entradas 24-26 de la s7 siguen en `backlog_entradas_sesion_7.md`; s8, s9 y s10 sin consolidar. **Delta de la sesión 11:** dos entradas nuevas corresponden (merge y publicación de la Capa 2 territorial; Capa 3 de asistencia simétrica con serie nominal, justificación y dos ámbitos). La deuda de memoria crece a cinco sesiones. Para ejecutar la consolidación en una sesión futura hacen falta, adjuntos: `backlog_acumulativo.md`, `backlog_entradas_sesion_7.md` y los traspasos v08 y v09 (las entradas de esas sesiones no pueden reconstruirse sin ellos, y fabricarlas no es opción).

## 6. Bugs de la sesión

- **`sellar()` cambia los bytes del `.rds` aunque el dato sea idéntico** (resuelto por método de verificación). Síntoma: comparar `asistencia.rds` por md5 daba falso positivo de cambio. Causa raíz: el sello lleva `escrito_en` (timestamp). Fix: comparar con `identical()` sobre el data.frame sin el atributo. Mismo efecto en los JSON (`metadatos.generado` cambia siempre), por lo que la comparación legacy se hizo bloque a bloque, no por hash de archivo. **Patrón general:** en este proyecto, la igualdad de datos NO se verifica por hash de artefacto sellado; se verifica sobre el contenido, excluyendo los campos de procedencia.
- **Primer `39` sin el atributo de alcance** (resuelto). Síntoma: el diseño inicial derivaba el alcance en el `39` a partir de la serie, lo que habría dado la fecha de la primera *sesión* del período en vez de la fecha de *instalación*. Coinciden en este corte (ambas 2026-03-11) pero no tienen por qué. Fix: el dato se movió al `33` como atributo del intermedio; hubo que re-ejecutar el `33` antes del `39`. **Patrón general:** un valor que la fuente publica no se re-deriva aguas abajo por conveniencia, aunque coincida hoy.

## 7. Aprendizajes y restricciones descubiertas

- **A38 — La matriz de asistencia no es densa: existe la sesión sin fila.** Regla: la fuente puede no publicar fila para un par (diputado, sesión) sin que eso signifique asistencia ni inasistencia. Se modela como tercer estado explícito (`sin_registro`), nunca se imputa. Contexto: 5 casos al corte; forzar la identidad de dos estados obliga a fabricar dato o a romper el denominador común. Principio: B.1, C.8.
- **A39 — Una simulación de peso es orden de magnitud, no dato.** Regla: la cifra que se publica es la recontada después del cambio, no la proyectada antes. Contexto: la medición proyectó +3,6 % en `docs/data/` y el resultado fue **+5,85 %**, porque la simulación no modelaba tres campos por entrada ni el bloque `alcance_temporal` repetido en los 155 perfiles. La estimación sirvió para decidir (el orden de magnitud era correcto y descartó el peso como factor limitante), no para reportar. Principio: B.4, C.11.
- **A40 — El universo de un caché no es función pura de `CORTE_FECHA` si el filtro se evalúa al descargar.** Regla: un filtro por estado mutable (`Estado == Celebrada`) evaluado en el instante de la descarga hace que el contenido dependa de la hora de la corrida, no solo del corte. Contexto: la sesión 4801 (del propio día del corte) está en el universo determinista y no en el snapshot legacy; por eso el legacy vive sobre 65 sesiones y el nominal sobre 66. Corolario: todo diseño que fije un universo debe decidir explícitamente si filtra por estado observado o por fecha. Principio: C.2 (reproducibilidad).
- **A41 — Antes de dar por equivalentes dos denominadores, comparar el universo, no la fórmula.** Regla: dos agregados pueden compartir la forma (`n()` sobre las filas propias) y no ser intercambiables si operan sobre universos distintos. Contexto: el supuesto de que el `n_sesiones` legacy "ya era" un `en_ejercicio` quedó refutado en parte por esta vía. Principio: B.1.

## 8. Decisiones de diseño

- **D6 — Dos ámbitos de denominador, no dos filtros del mismo.** `periodo_vigente`: las 48 sesiones desde 2026-03-11 hasta el corte, denominador **común a los 155**; es el único comparable entre diputados y el que ordena el índice. `en_ejercicio`: por diputado, las sesiones del alcance desde su primer registro (48 para 84 diputados, 66 para 71). Alternativas descartadas: (a) mantener solo el denominador actual, que produce valores de 47 a 66 según el diputado e incluye para los reelectos 18 sesiones del período 2022-2026, de modo que `n_sesiones` no significa lo mismo en dos perfiles; (b) publicar solo el común, que perdería la lectura de la oportunidad real de asistir de cada persona. Implicancia: el índice ordena por `tasa_presencia` del período vigente.
- **D7 — Alcance del "en ejercicio" acotado al pipeline (2026) y declarado en el JSON.** Un "en ejercicio" verdadero para un reelecto abarcaría 2022-2025, años que hoy no se descargan ni se cachean (territorio de P-10, biblioteca histórica). Se acota y se publica `alcance_temporal` con nota legible, para que el frontend no pueda rotularlo como carrera completa. Ampliarlo queda ligado a P-10.
- **D8 — Dos tasas con denominador compartido.** `tasa_presencia = n_asiste / n_sesiones` (la fórmula actual, sin cambio) y `tasa_presencia_o_justificada = (n_asiste + n_justificadas) / n_sesiones`. Al compartir denominador, la diferencia entre ambas **es exactamente el peso de las ausencias justificadas**, y lo que queda bajo la segunda son las faltas sin justificar: dos números sobre la misma base, con una brecha que significa una sola cosa. Alternativa descartada: sacar las justificadas del denominador, que produce tasas sobre bases distintas, no comparables entre sí ni entre diputados, y con denominadores diminutos para quien tuvo licencia larga. Se publica además `n_injustificadas` como conteo propio.
- **D9 — Las rebajas se persisten y se publican, pero no entran en ninguna fórmula.** Mientras P2 siga sin resolverse (la fuente no documenta qué significa `RebajaAsistencia`), usarlas sería inventar la regla reglamentaria. Verificado por prueba discriminante: `n_justificadas` coincide con el conteo sin filtrar por rebaja y no con el filtrado, y ambos difieren de verdad en 24/155 y 32/155.
- **D10 — Sin `DOMINIO_JUSTIFICACION` cerrado.** La fuente no publica catálogo (P1) y los códigos observados tienen huecos. Se usa la glosa del propio nodo; un código nuevo emite `warning()` y continúa, nunca `stop()`. Contrasta deliberadamente con `DOMINIO_VOTO`, que sí es cerrado porque la fuente lo acota.
- **D11 — Empaquetado 1+2: intermedio nominal + serie embebida en el perfil.** Descartada la opción 4 (catálogo compartido + matriz compacta), que ahorraba 1,3 % de peso a cambio de que el cliente resolviera dos fuentes y de depender de un mapa de glosas que no existe. Con el perfil ya en 337 KB por los votos, el ahorro no justificaba la complejidad.
- **Los campos legacy no se migran en esta capa.** Se conservan intactos porque el portal en vivo los consume y el frontend es sesión aparte; lo nuevo se agrega. Implicancia: durante la transición conviven `n_sesiones` legacy (65 sesiones) y `en_ejercicio.n_sesiones` (66), con un punto de diferencia visible.

## 9. Constantes y parámetros vigentes

| Constante | Valor | Archivo | Nota |
|---|---|---|---|
| `CORTE_FECHA` | **2026-07-20** | `10_utils/10_configuracion.R:41` | Sin cambios desde v10. Fuente canónica: el archivo (A21). |
| Período legislativo vigente | Id 11, `2026-2030`, inicio **2026-03-11** | API `WSLegislativo.asmx/retornarPeriodoLegislativoActual` | Se lee y cachea por corte. **Jamás hardcodear.** |
| Alcance temporal del pipeline | 66 sesiones, 2026-01-05 a 2026-07-20 | atributo del intermedio nominal | Lo fija el `33`; el `39` no lo re-deriva. |
| Denominador `periodo_vigente` | **48** sesiones, común a los 155 | `asistencia_ambitos.rds` | Desde 2026-03-11. |
| Denominador `en_ejercicio` | 48 (84 dip.) o 66 (71 dip.) | `asistencia_ambitos.rds` | No comparable entre diputados por diseño. |
| Serie nominal publicada | 8 718 entradas | `docs/data/perfiles/*.json` | 8 236 asiste, 477 no asiste, 5 sin registro. |
| Justificaciones en la serie | 447, 12 códigos | idem | 434 sobre inasistencia, 13 sobre asistencia registrada (P3). |
| Catálogo de justificaciones | 13 códigos **observados** (12–19, 21, 23, 25, 28, 29) | `andamios/muestras/tabla_catalogo_justificacion.md` | Observado, no oficial. Sin dominio cerrado (D10). |
| Crosswalk territorial | 155 filas | `20_insumos/territorio/20260724_crosswalk_distrito_diputado.csv` | Sin cambios. |
| Catálogo distrito→región | 28 filas | `20_insumos/territorio/catalogo_distrito_region.csv` | Sin cambios. |
| Peso de `docs/data/` | **42 367,6 KB** | `docs/data/` | Desde 40 024,6 KB (+5,85 %). Perfil 1017: 354,4 KB. |
| `LIMITE_COLAPSADO` | 16 | `docs/index.html` | Capa 1. Sin cambios. |

## 10. Arquitectura de archivos

Escáner al cierre: `50_documentacion/estructura/estructura_actual.md`, fechado **2026-07-25 07:52:57** (23 carpetas, **461 archivos**; eran 437 al abrir). Nuevos: dos intermedios de asistencia, una clave de caché nominal, el informe de medición, el log de la Capa 3 y las muestras del período legislativo. `33_extraer_asistencia.R` pasó de 5,18K a 22,07K. La estructura respeta la política. **A25:** al cierre, el trabajo vivía en `feat/capa3-asistencia`; el encargo de merge estaba en curso, de modo que **la rama en que quedó el repo no está confirmada**: verificar con `git -C <raiz> branch --show-current` al abrir.

**Registro de ejecución detallado:** `50_documentacion/andamios/logs/20260725_capa3_asistencia_log.md` (log de la sesión de Claude Code; detalle paso a paso no reproducido aquí). Medición: `50_documentacion/andamios/20260725_medicion_asistencia_capa3.md`.

## 11. Pendientes y ruta sugerida

**Inventario:**

- **Confirmar el estado del merge de la Capa 3 — inmediato, bloqueante de todo lo demás.** El encargo corría al cierre. Verificar: rama actual, `git log --oneline -3`, divergencia contra `origin/main`, campos legacy intactos en producción, `docs/index.html` sin cambios respecto de `ac177be`. Criterio de éxito: producción sirve los campos nuevos sin que ningún campo legacy haya cambiado de valor. Precaución: NO asumir que el merge se completó.
- **Revisión del workflow contra la doble descarga — alto, antes del lunes 27.** La Capa 3 introduce una segunda descarga de asistencia por refresh. Verificar cadencia, timeout declarado y si alguna parte del workflow asume un único barrido. El bot corre los lunes; si el timeout no absorbe el barrido duplicado, el refresh del 27 falla.
- **Frontend de asistencia — siguiente feature, alta complejidad.** Los campos están publicados y sin consumir. Decisiones que la interfaz debe tomar: cuál tasa se muestra por defecto y cómo se explica la diferencia (P7, decisión metodológica del titular, no resuelta), cómo se presentan los dos ámbitos sin inducir comparaciones inválidas, cómo se muestra la justificación (glosa por entrada) y el estado `sin_registro`. Prerequisito: nada; es sesión de dominio propio.
- **Retiro del contrato legacy — deuda que se paga sola.** Cuando el frontend migre a los campos nuevos, retirar el agregado legacy elimina la doble descarga (Cambio 8) y la discrepancia de un punto entre `n_sesiones` legacy (65 sesiones) y `en_ejercicio` (66). Encadenar con la sesión de frontend.
- **Consolidación del backlog — deuda de memoria, cinco sesiones.** Ver §5. Requiere adjuntar `backlog_acumulativo.md`, `backlog_entradas_sesion_7.md` y los traspasos v08 y v09.
- **Discrepancia menor de conteo (P3):** la medición contó 14 justificaciones sobre sesiones con asistencia registrada; la serie publicada, 13. La explicación probable es el filtro al roster vigente (la medición contaba los 239 ids), **no verificada**. Cerrarla en la sesión de frontend, que es donde P3 importa.
- **Vigilar los 5 `sin_registro` entre cortes.** Si el número crece, deja de ser una arista y pasa a ser un problema de cobertura de la fuente.
- **P1, P2, P4, P5 heredadas de la medición:** catálogo inexistente, semántica de las rebajas, Senado no medido, `TipoTitularAsistencia` vacío. Ninguna bloquea; P2 es la que impediría publicar una "tasa oficial".
- **P-22 (bot vs. trabajo manual) — gobernanza de flujo.** Recomendación vigente: bot en rama + PR. Sesión dedicada. Gana urgencia con dos capas nuevas en `main`.
- **Capa 4: P-13 (contrato Cámara↔Senado), P-7 (pipeline Senado), P-9 (crosswalk partido→tendencia, paralelizable), P-10 (biblioteca histórica).** El RUT sigue anotado como llave nacional para el cruce entre cámaras. P-10 además desbloquearía el "en ejercicio" plurianual (D7).
- **`# REVISAR` ajenos:** estado de tramitación de proyectos (`NA`, proxy `admisible`); rol autor/coautor (`Orden=0` para todos los firmantes).
- **Commit del traspaso como último paso verificado del cierre — proceso, nuevo.** Falló en s9 y s10. El correctivo no es recordarlo: es que el commit del traspaso sea un paso explícito del protocolo de cierre, confirmado con `git status`.
- **Verificación de ramas remotas — administrativo, bajo.** Confirmar con `git branch -r` si las ramas borradas en la s9 tienen contraparte en `origin`. Se suma la decisión de borrar `feat/territorio-crosswalk` y `feat/capa3-asistencia` una vez confirmada la publicación.

**Evaluación de deuda técnica:** la Capa 3 quedó limpia y auditada, con su única deuda declarada por escrito y con fecha de vencimiento conocida (la doble descarga muere con la migración del frontend). La deuda que se acumula sin atenderse es de memoria (backlog, cinco sesiones) y de proceso (P-22, y el commit del traspaso al cerrar).

**Auditoría de cierre (POLITICA 5.6):**
- #2 (pipeline de cero sin intervención manual): sí; regeneración completa con cache hit y 0 llamadas.
- #5 (cada transformación crítica con validación): sí; identidades de conteo verificadas 155/155 en ambos ámbitos, tasas en rango, panel adversarial independiente.
- #6 (outputs reproducibles e idempotentes): sí; `validar_corte()` sobre 7 intermedios al corte 2026-07-20. Salvedad conocida: el universo del caché legacy no es función pura del corte (A40).
- #7 (decisiones metodológicas como constantes/insumos nombrados): sí; la fecha de instalación se lee de la API y viaja como atributo, no como número mágico.
- #8 (nombres sin tildes/ñ/espacios): sí.

**Ruta sugerida para la sesión 12:** confirmar el estado del merge y del workflow (bloqueante, antes del lunes 27), y abrir la sesión de frontend de asistencia, que es donde se decide P7 y donde muere la deuda del contrato legacy. Diferir P-22 a sesión de gobernanza y el Senado a después. La consolidación del backlog conviene tomarla como sesión propia y corta, con los cuatro documentos adjuntos.

## 12. Instrucciones específicas para la próxima sesión

- ⚠️ NO asumir que la Capa 3 quedó mergeada: el encargo corría al cierre. Leer el estado real (rama, `log`, divergencia) antes de cualquier afirmación.
- ⚠️ NO dejar pasar el lunes 27 sin revisar el workflow contra la doble descarga de asistencia.
- ⚠️ NO afirmar un valor verificable (cifra de conteo, denominador, `CORTE_FECHA`, distrito) sin leerlo de la fuente. A21 acumula **nueve** ocurrencias; la novena es de esta sesión (§15).
- ⚠️ NO correr `run_all(only=39)` local sin regenerar 32-36 al corte vigente (A34).
- ✅ ANTES de comparar dos agregados, comparar sus universos, no sus fórmulas (A41).
- ✅ ANTES de verificar igualdad de datos en artefactos sellados, comparar contenido sin los campos de procedencia; el hash siempre difiere (§6).
- ✅ ANTES de cualquier push, `git fetch origin` dentro de la compuerta de divergencia (A32); el bot corre los lunes.
- ✅ ANTES de cerrar la sesión, commitear el traspaso y confirmarlo con `git status`. Falló en s9 y s10.
- 🔒 R-only en todo contexto (excepto `docs/index.html`, HTML/JS single-file sin CDN).
- 🔒 Los campos legacy de `asistencia` y del índice no cambian de nombre, fórmula ni valor mientras el portal los consuma.
- 🔒 `RebajaAsistencia` / `RebajaQuorum` se publican pero no entran en ninguna fórmula mientras P2 siga abierta.
- 🔒 Sin `DOMINIO_JUSTIFICACION` cerrado: código nuevo emite `warning()`, nunca `stop()`.
- 🔒 La fecha de instalación del período se lee de la API, jamás se hardcodea.
- 🔒 `sin_registro` no se imputa a asistencia ni a inasistencia.
- 🔒 El territorio es insumo estático auditado (D5); `distrito`/`region` jamás fabricados.
- 🔒 `CORTE_FECHA` sin default silencioso; el sello de procedencia no se rompe.
- 🔒 La clasificación de tendencia no se altera autónomamente; `IND = NA_character_` es intencional.

## 13. Fragmentos de código de referencia

Las dos tasas comparten denominador; esa es la decisión y no se altera:

```r
# n_sesiones es el denominador del ambito (comun a los 155 en periodo_vigente).
# La diferencia entre ambas tasas ES el peso de las ausencias justificadas.
tasa_presencia               <- n_asiste / n_sesiones
tasa_presencia_o_justificada <- (n_asiste + n_justificadas) / n_sesiones
# Identidad verificada 155/155 en ambos ambitos (A38):
# n_asiste + n_no_asiste + n_sin_registro == n_sesiones
```

Verificar igualdad de datos en artefactos sellados (el hash siempre difiere):

```r
# md5 sobre un .rds sellado da falso positivo: el sello lleva escrito_en.
identical(datos_nuevos, datos_previos)   # comparar el data.frame, no el archivo
# En los JSON, metadatos$generado cambia siempre: comparar bloque a bloque.
```

Prueba discriminante de que un campo NO entra en una fórmula (D9):

```r
# No basta con inventariar apariciones: la prueba debe poder fallar.
# n_justificadas coincide con el conteo SIN filtrar por rebaja y NO con el
# filtrado, y ambos difieren de verdad en 24/155 y 32/155. Si coincidieran,
# la prueba no discriminaria.
```

## 14. Reapertura

- **Nombre del chat:** `transparencia_legislativa_chile, sesión 12 (Claude Opus 5)`.
- **Mensaje de apertura pre-armado:** "Tipo: CONTINUATION. El protocolo (`POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`) vive en la knowledge base del Project y se lee desde ahí. La Capa 2 (territorio) está en producción desde `ac177be`. La Capa 3 (asistencia simétrica) quedó construida, verificada y con panel adversarial 4/4 en `feat/capa3-asistencia`, y el encargo de merge a `main` corría al cerrar la sesión 11: **su resultado no está confirmado, hay que leerlo antes de afirmar nada**. Pendiente urgente: revisar el workflow de GitHub Actions contra la doble descarga de asistencia antes del refresh del lunes 27. `CORTE_FECHA` = 2026-07-20 al cierre (confirmar en `10_configuracion.R`). Adjunto: `traspaso_cierre_v11.md`, `estructura_actual.md` (re-escanear e indicar rama, A25)."
- **Documentos para la sesión 12:**
  1. *Protocolo (knowledge base, NO adjuntar, solo verificar que esté al día):* `POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
  2. *Opcionales según el foco real:* `CLAUDE.md` si el trabajo corre en Claude Code; `10_configuracion.R` para el valor vigente de `CORTE_FECHA`; `docs/index.html` y el log `20260725_capa3_asistencia_log.md` si la sesión es de frontend; `backlog_acumulativo.md`, `backlog_entradas_sesion_7.md`, `traspaso_cierre_v08.md` y `traspaso_cierre_v09.md` si la sesión es de consolidación del backlog.
  3. *Sí se adjuntan:* `traspaso_cierre_v11.md`; `estructura_actual.md` (re-escaneado, con rama declarada).
- **Nota final:** si `CORTE_FECHA` cambió (el bot corre cada lunes; el 27 es el próximo), adjuntar `10_configuracion.R` actualizado y avisarlo. Antes de cualquier corrida local, regenerar 32-36 (A34). Verificar en qué rama quedó el repo (A25): al cierre corría un merge, así que la rama no está confirmada.

## 15. Errores del asistente (POLITICA 0.5)

| momento | disparador | que_paso | regla_violada | causa_raiz | salvaguarda_presente | patron |
|---|---|---|---|---|---|---|
| Sesión 11, encargo de implementación de la Capa 3 (criterio de verificación de las Fases 1 y 2) | El ejecutor lo detectó al chocar contra el dato real: 5 pares (diputado, sesión) sin fila en la fuente | El asistente fijó como identidad de verificación `n_asiste + n_no_asiste == n_sesiones`, afirmando implícitamente que la matriz de asistencia es densa. No lo es: la identidad correcta requiere un tercer estado. El ejecutor añadió `sin_registro` en vez de imputar dato o romper el denominador común, y reportó la discrepancia | SETTINGS §1.2.6 (no operar sobre estado supuesto); B.1 (sin supuestos implícitos); B.4 (criterio de éxito verificable definido sobre una propiedad no verificada de los datos) | El informe de medición estaba disponible y decía "la matriz **no** es densa" con las cifras (10 225 filas vs 155 × 66 = 10 230); el asistente lo leyó, lo citó al recomendar el diseño, y aun así redactó una identidad que presupone densidad. No fue desconocimiento del dato sino falta de propagación del dato al criterio de éxito | POLITICA 5.1 / B.1 + SETTINGS §1.2.6 + el propio informe de medición de esta sesión + el registro acumulado de A21 en v07-v10 | **Novena ocurrencia de A21.** Variante idéntica en forma a la octava (v10): el valor no verificado estaba otra vez en el CRITERIO DE ÉXITO del encargo, no en prosa, y otra vez lo atajó la disciplina del ejecutor de ir a la fuente. Agrava la lectura de v10: esta vez el dato correcto **estaba en un documento que el propio asistente había leído y citado en el mismo turno**, de modo que el fallo no es de acceso a la fuente sino de propagación de lo leído al criterio |

**Nota de patrón para análisis cruzado de cartera (SETTINGS §2.2.15):** novena ocurrencia de A21 en cinco sesiones (cuatro en v08, tres en v09, una en v10, una en v11). La v10 concluyó que el correctivo real no es la disciplina del redactor sino que Claude Code verifique contra la fuente en su Fase 0, y esta sesión lo confirma por segunda vez consecutiva: el mecanismo funcionó, el trabajo salió correcto, y el error del redactor quedó absorbido sin costo de re-trabajo. Pero esta ocurrencia aporta un ángulo que las anteriores no tenían: **el dato correcto no estaba en una fuente remota ni en un archivo no leído, sino en el informe de medición que el propio asistente había leído íntegro y citado en el mismo turno para fundamentar la recomendación de diseño**. Eso descarta "no tenía acceso a la fuente" como causa y aísla la causa real: al redactar los criterios de éxito, el asistente los escribe desde su modelo mental del dominio ("asistencia es asiste o no asiste") en vez de derivarlos del documento que acaba de leer. La salvaguarda a formular no es "verifica antes de afirmar" (ya existe y no basta), sino una regla de derivación: **todo criterio de éxito de un encargo debe citar la línea o cifra del insumo del que se deriva, o marcarse explícitamente como supuesto a verificar en Fase 0**. Un criterio sin procedencia es un supuesto disfrazado de hecho. Candidata madura para la próxima sesión BIBLIOTECA de `slep_estado_proyectos_monitoreo`: nueve ocurrencias, mecanismo correctivo identificado y ahora una causa raíz precisa que las salvaguardas actuales no direccionan.
