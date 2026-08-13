# Traspaso de cierre v20 — transparencia_legislativa_chile

## §1. Identificación

| Campo | Valor |
|---|---|
| Proyecto | `transparencia_legislativa_chile` |
| Versión | v20 |
| Fecha de cierre | 2026-08-13 |
| Sesión | 20 |
| Foco | Cerrar P-83 (entrada de P-59 en `CLAUDE.md`, desbloqueada por el merge del #11) y ejecutar P-68: sondear LeyChile y `datos.bcn.cl` como fuentes temáticas alternativas, lo único capaz de dar vuelta el veredicto del eje temático. |
| Entorno | R 4.5.2 en Positron, macOS; Claude Code como agente de ejecución (Opus 5; Fable 5 no disponible por saturación de capacidad) |
| Protocolo | `POLITICA_PROYECTO.md` v5.6 y `SETTINGS_Y_PROMPTS_OPERACIONALES.md` v23, ambas verificadas contra la knowledge base en la Fase A |
| `main` | `0ecb44e` (**previo al commit de cierre**) |
| Rama de la sesión | `sondeo/p68-fuentes-tematicas`, último commit `2e85afb`, sin push |
| Archivos principales modificados | `CLAUDE.md` (en `main`), `50_documentacion/andamios/50_encargo_p68_sondeo_leychile_bcn.md` (nuevo), `50_documentacion/activa/50_veredicto_fuentes_tematicas_bcn.md` (nuevo), `50_documentacion/andamios/logs/20260813_p68_sondeo_log.md` (nuevo), `20_insumos/exploracion/20260813/` (gitignorado) |

## §2. Resumen ejecutivo

La sesión abrió verificando el estado real de los dos PR que la sesión 19 dejó
abiertos: ambos aparecieron mergeados (#11 a las 13:33:17 UTC, #12 a las
13:33:23 UTC), lo que desbloqueó P-83 y activó la advertencia operativa del
traspaso anterior sobre el rastro de arranque. Con P-83 cerrado en `main`, la
sesión ejecutó P-68 completo.

El sondeo cerró con **NO**: ninguna de las dos fuentes de la BCN entrega
descriptores temáticos en cantidad capaz de dar vuelta el veredicto. LeyChile
queda cerrada por techo medido (4,27 % de los boletines sin materia llegó a ser
ley, y 1,19 % en la cohorte 2026); `datos.bcn.cl` queda cerrada por dos razones
independientes, que importa no confundir: el control positivo falla (3 de 5 con
el criterio de 5 de 5) y, medido por el portador correcto sobre el universo
completo, la cobertura es **0 de 422**.

El valor de la sesión no está solo en el veredicto sino en tres hallazgos que el
veredicto vigente no podía ver. Primero, el universo se movió: 427 boletines al
corte 2026-08-12 contra los 381 del 2026-08-03, y **336 de los 422 sin materia
son cohorte 2026** (79,62 %), así que cualquier fuente que cubra "lo legislado"
choca contra esa concentración antes que contra nada más. Segundo, la cobertura
dentro de este universo no es un gradiente sino binaria: 5 de 5 en 2016-2018, 0
de 422 desde 2020. Tercero, `tieneMateria` cuelga sobre todo de secciones,
tramitaciones y mociones, y `ProyectoDeLey` es apenas la 12ª clase portadora, así
que el camino que el control positivo usó primero no era el principal: medir por
el correcto costó cuatro consultas más y no rescató la cobertura.

El sondeo gastó 43 de 500 llamadas autorizadas, no persistió ninguna respuesta
distinta de 200, y dejó `20_insumos/camara/` intacto (51 archivos, md5 agregado
idéntico entre apertura y cierre).

## §3. Estado al cierre

**Qué funciona.** El pipeline completo, sin cambios en esta sesión: P-68 fue un
sondeo de solo lectura contra fuentes externas y no tocó `30_procesamiento/`,
`10_utils/`, `00_run_all.R` ni `docs/`. `CORTE_FECHA` es `2026-08-12` (fuente:
`10_utils/10_configuracion.R:57`, leído por Claude Code en G1).

**Qué no funciona.** Nada activo. Un estado que conviene no confundir con un
fallo: los 6 intermedios declaran sello `2026-08-03` contra `CORTE_FECHA`
`2026-08-12`. Es el estado normal entre merges del bot y la guarda de
autorregeneración lo resuelve sin red; G1 lo esquivó midiendo sobre la captura
cruda del corte vigente, precisamente para no escribir en `40_salidas/`.

**PR de la sesión 19, verificados en esta sesión:**

| PR | Rama | Estado | Merge |
|---|---|---|---|
| #11 | `fix/p76-p77-guarda-arranque` | `MERGED` | 2026-08-13T13:33:17Z |
| #12 | `chore/p59-locale-utf8` | `MERGED` | 2026-08-13T13:33:23Z |

**Delta respecto a v19.** El eje temático deja de tener una vía no explorada: las
dos fuentes alternativas que el veredicto vigente señalaba como "la vía más
prometedora, ninguna de las dos probada" quedan probadas y cerradas. P-66 pasa de
alcance indefinido a alcance acotado. `CLAUDE.md` documenta P-59. El gatillo 4ter
sigue apagado; el 4bis sigue encendido.

## §4. Registro detallado de cambios

### 4.1 P-83 — Entrada de P-59 en `CLAUDE.md`

**Archivos:** `CLAUDE.md`. **Categoría:** documentación. **Commit:** `0ecb44e` en
`main`.

Se omitió a propósito en el PR #12 para no chocar con el PR #11, que también
modifica la lista de "Últimos cambios". Con ambos mergeados, la entrada entra
como cambio 1 de esa lista, la de P-76/P-77 pasa a 2 y declara su merge, y la
entrada más antigua (Capa 2, 2026-07-24) sale por el tope de cinco. Se agregó
además `10_utils/10_locale.R` a "Estructura de archivos relevantes": sin eso,
P-59 quedaba documentado en el historial pero invisible donde se buscan las
rutas.

**Decisión declarada:** no se tocó el "12 de 13 criterios" de la entrada de
P-76/P-77, pese a que el traspaso v19 registra 14 de 14. La cifra del traspaso no
se midió en el turno que la habría escrito, y una cifra heredada no es fuente.
Queda como corrección disponible para una sesión que la recuente.

**Vía:** commit directo a `main` sin PR, siguiendo el precedente de `97dab39` (D31
materializada). Es documentación, no código de pipeline.

### 4.2 Higiene de repositorio previa al sondeo

**Categoría:** integración/repo (no se cuenta como cambio; ver §5 del backlog).

G0 bloqueó con tres de cuatro comprobaciones en rojo. Disposición aprobada por el
titular: (a) el `CLAUDE.md` sucio se commiteó como P-83; (b) el encargo sin
trackear se commiteó en la rama del sondeo; (c) `stash@{0}`
(`On design/contrato-datos: wip-sesion6`, 2026-07-10, 6 salidas del escáner) se
preservó como rama `wip-sesion6` y recién entonces se soltó.

**Por qué preservar y no dejar intacto:** dejar el stash convertía G0 en una
compuerta con excepción autorizada, que es justo la forma de guarda que este
proyecto ya decidió no tener. Claude Code verificó que `git show --stat
wip-sesion6` listara los 6 archivos **antes** de `git stash drop`, con
instrucción explícita de detenerse si no.

### 4.3 P-68 — Sondeo de LeyChile y `datos.bcn.cl`

**Archivos:** `50_documentacion/andamios/50_encargo_p68_sondeo_leychile_bcn.md`,
`50_documentacion/activa/50_veredicto_fuentes_tematicas_bcn.md`,
`50_documentacion/andamios/logs/20260813_p68_sondeo_log.md`,
`20_insumos/exploracion/20260813/` (reproductor, manifiesto y 21 respuestas;
carpeta gitignorada por completo, igual que el precedente `20260807`).
**Categoría:** diagnóstico/exploración.

**Compuertas, en el orden en que corrieron:**

| Compuerta | Qué midió | Resultado |
|---|---|---|
| G0 | Estado del repo y sello md5 de `20_insumos/camara/` | Bloqueó y se resolvió (§4.2). Sello: 51 archivos, 1.533.938 bytes, md5 agregado `687f75a88122472aa2f7d1b6dae9d285` |
| G1 | Universo, con fusible de red armado | Exit 0, fusible sin disparar. 427 boletines, 5 con materia, 422 sin |
| G2 | ¿Responde `datos.bcn.cl`? | HTTP 200, `application/sparql-results+json`, forma de resultado SPARQL. Rama abierta |
| G3 | ¿Responde LeyChile? | HTTP 200, `text/xml`, raíz `<Norma>`. Rama abierta |
| G4 | Techo de LeyChile | 18 de 422 (4,27 %) llegó a ser ley; 4 de 336 (1,19 %) en cohorte 2026. **Rama cerrada, sin extractor** |
| G5 | Control positivo y negativo del grafo | Positivo 2 de 5 (luego 3 de 5 con Q4); negativo 0 de 7 falsos positivos. **Rama cerrada** |
| Q1-Q5 | Lote de verificación adversarial posterior | Ver §4.4 |

**Cohorte anual de los 422 sin materia** (año de `FechaIngreso`, medido offline
sobre la captura cruda): 2020:1, 2021:2, 2022:6, 2023:7, 2024:32, 2025:38,
2026:336. Los 5 con materia son 2016 (3) y 2018 (2).

**Fracción que llegó a ser ley, por cohorte:** 2020 100 %, 2021 0 %, 2022 33,33 %,
2023 14,29 %, 2024 15,62 %, 2025 13,16 %, 2026 1,19 %.

### 4.4 El lote Q — cuatro consultas de estructura que corrigieron la evidencia

Antes de dar el veredicto por cerrado, el titular pidió revisar lo que quedaba
dudando. Se ordenaron cuatro consultas de estructura sobre un grafo ya abierto, y
después una quinta.

- **Q1 (P5 del panel):** `tieneTerminoLibre`, la propiedad con más tripletas del
  grafo (24 840), devuelve 1 de 5 y 0 por id, texto o slug. La refutación
  candidata se corrió y **no refuta**.
- **Q2:** los sujetos de `tieneMateria` son, por volumen, `SeccionRecurso`
  (85 924), `Participacion` (38 324), `IntervencionPeticionDeOficio` (16 841),
  `SeccionProyectoDeLey` (13 308), `TramitacionProyectoDeLey` (12 975),
  `MocionParlamentaria` (9 817) y `ProyectoDeLey` (5 830, 12ª). **G5 midió por el
  sujeto minoritario.**
- **Q3:** la clase dominante de `leychileCode` es `Document`/`Norm`, lo esperado:
  el portador natural de un identificador de norma es la norma. **Q3c** dio el
  confirmador independiente que faltaba: los 4 códigos resuelven a `<Norma>` real
  con número y fecha (Leyes 21813, 21814, 21821, 21824), 4 de 4. `leychileCode`
  deja de ser un proxy sin confirmar.
- **Q4:** el control positivo por camino directo **o a un salto** sube de 2 de 5 a
  **3 de 5**. Sigue fallando el criterio (se exigían 5 de 5), así que la rama
  sigue cerrada, pero **cambia la evidencia**, y por eso Claude Code se detuvo sin
  reescribir el veredicto.
- **Q5:** cobertura por los tres portadores (`MocionParlamentaria`,
  `TramitacionProyectoDeLey`, `SeccionProyectoDeLey`) sobre el universo:
  **0 de 422 y 0 de 336**, y 0 en las siete cohortes. El hallazgo estructural de
  Q2 era real y aun así no rescata la cobertura.

**El control positivo de la propia consulta de Q5.** Un 0 sobre 422 admite dos
explicaciones incompatibles (cobertura nula o consulta rota), así que se corrió la
misma consulta contra los 5 boletines con materia: devolvió 2 temas para
`10634-29` vía `MocionParlamentaria`. La consulta está viva; el cero es medición.

## §5. Decisiones de diseño

**D36 — El umbral de una compuerta se calibra contra el piso real, no contra el
estado publicado.** El encargo fijó el criterio de cierre de G4 como "menor que la
cobertura que el portal ya tiene". Con el piso medido en 1,17 %, ese umbral no
discrimina nada: casi cualquier resultado lo supera. Se sustituyó, con G1 ya
medido, por la cohorte 2026 (336 de 422). *Implicancia:* un umbral escrito antes
de conocer el piso es una hipótesis sobre el piso, y hay que marcarlo como tal.

**D37 — Un cero absoluto no se reporta sin control positivo de la consulta que lo
produjo.** Una cobertura de 0 sobre 422 y una consulta rota son indistinguibles
en la salida. El control es correr la misma consulta contra casos que **sí** deben
devolver. *Origen:* Q5. *Alcance:* toda medición de cobertura de este proyecto.

**D38 — En un endpoint que omite los sujetos ausentes, el denominador es la lista
pedida, nunca el resultado.** Virtuoso no emite fila para un `?s` de `VALUES` que
no está en el grafo. La primera corrida del censo de G4 agregó sobre lo devuelto y
perdió 150 boletines: reportó 4 de 186 (2,15 %) en vez de 4 de 336 (1,19 %),
numerador correcto y denominador encogido. *Instrumento:* `stopifnot()` de cuadre
contra la lista pedida en cada agregación. Apareció **tres veces** en la sesión y
las tres las atrapó el cuadre, ninguna la inspección.

**D39 — La rama `datos.bcn.cl` se cierra por dos razones independientes, y la
distinción se conserva.** El control positivo fallido solo autoriza declarar la
cobertura *inverificable*; la medición por el portador correcto sobre el universo
la *mide*. El veredicto se apoya en la segunda. Colapsarlas habría dejado el "no"
más débil de lo que es.

## §6. Bugs de la sesión

Sin bugs de código: la sesión no modificó ningún script del pipeline. Los tres
defectos corregidos fueron del reproductor del sondeo, dentro de la misma corrida
y sin costo de red:

| Defecto | Dónde | Cómo se detectó | Arreglo |
|---|---|---|---|
| Agregación sobre lo devuelto en vez de lo pedido | censo de G4 | `stopifnot()` de cuadre (272 ≠ 422) | Reconciliación contra la lista pedida, 0 llamadas |
| Comparación con `==` contra etiquetas `NA` y conteo de filas en vez de URIs distintas | cotejo de G5 | Revisión del propio agente antes de reportar | `%in%`, `unique()` y `stopifnot()` que prohíbe `NA` en el cotejo |
| `LIMIT 2000` alcanzado: contar filas truncadas | Q4 v1 | El límite se alcanzó | `COUNT(DISTINCT ?tema)` agregado en el servidor más cuadre |

## §7. Aprendizajes y restricciones

**A82 — Un endpoint SPARQL que responde 200 no es un endpoint SPARQL.** La página
del buscador también responde 200. La compuerta exige **forma de resultado**
(`head.vars`, `results.bindings`), no código de estado.

**A83 — La URI del recurso puede ser la llave.** En `datos.bcn.cl` el boletín no
existe como literal (0 bindings para los 5 valores reales); vive en la URI
(`.../recurso/cl/proyecto-de-ley/9085-01`). Buscar la llave como literal y
concluir "no está" es un falso negativo.

**A84 — Un control negativo con identificadores bien formados es lo que permite
leer la ausencia.** La URI se construye desde el boletín, así que un boletín falso
produce una URI impecable. Con 0 de 7 falsos positivos queda establecido que "sin
fila" significa "el recurso no existe", no "existe y no tiene materia". Sin ese
control, el techo por presencia no sería interpretable.

**A85 — La propiedad más poblada no es la más relevante.** `tieneTerminoLibre`
tiene más tripletas que `tieneMateria` y rinde menos (1 de 5 contra 2 de 5).

**A86 — Coincidencia de concepto no es coincidencia de llave.** El grafo cubre 6
de 6 materias de los boletines que sí responden, pero 0 de 11 por id: enteros de
un catálogo de 8518 contra URIs con slug. Origen editorial común, sistemas de
identificación distintos. Es peor que una discrepancia de contenido, porque invita
a un join por texto que el propio catálogo ya rompe (etiquetas del mismo tema en
cuatro grafías).

**A87 — Medir el techo antes de construir el extractor.** G4 cerró la rama
LeyChile con una consulta agregada. El plan B (422 llamadas al SIL) no se gastó.

## §8. Estado de decisiones previas

**D26 vigente y reforzada:** el denominador de toda métrica temática es el
subconjunto tipo `Proyecto de Ley`. El veredicto nuevo declara los tres
denominadores (427 boletines / 737 votaciones / 122 605 filas de voto) y elige
boletines, con la salvedad de que las filas de voto vienen de `votos.rds` con
sello 2026-08-03, declarado.

**Hipótesis B del veredicto del eje temático — confirmada desde el otro lado, no
refutada.** Si la materia llega con la tramitación y no con el tiempo, una fuente
de normas cubre "lo legislado" y no "lo que se vota este año". LeyChile hace
exactamente eso: 100 % en 2020 y 1,19 % en 2026.

**Serie diacrónica extendida:** los 46 boletines nuevos del refresh recibieron 0
materias (0 de 110 nuevos acumulados desde el 2026-07-06).

## §9. Constantes y parámetros

Sin cambios. `CORTE_FECHA` sigue en `2026-08-12` y su fuente canónica es
`10_utils/10_configuracion.R`.

## §10. Arquitectura de archivos

Escáner regenerado en el cierre; su sello queda en el log de cierres. Cambios de
estructura: tres archivos nuevos versionados (un encargo y un log en
`50_documentacion/andamios/`, un veredicto en `50_documentacion/activa/`) y una
carpeta nueva gitignorada (`20_insumos/exploracion/20260813/`). Una rama nueva de
preservación, `wip-sesion6`.

Las desviaciones heredadas siguen abiertas y son materia de P-60. **La cifra de
"siete archivos de `50_documentacion/activa/` sin prefijo `50_`" que v19 arrastra
sigue sin recuento programático** y esta sesión tampoco lo hizo: el veredicto
nuevo agrega un archivo más a esa carpeta, así que la cifra, sea cual sea, cambió.
Recontarla es parte de P-60.

## §11. Pendientes y ruta sugerida

### 11.1 Inventario

**P-66 — Publicar la entidad `proyecto` con tramitación legislativa.**
*Tipo:* funcionalidad. *Impacto:* alto; es lo que el veredicto del eje temático
declara construible hoy (tramitación 381 de 381 en su medición). *Dependencias:*
ninguna: P-68 cerró y su resultado **acota** el alcance (sin bloque de materias;
`cobertura_materias` explícito). *Complejidad:* alta. *Precauciones:* la cobertura
temática no se publica sobre el denominador total de votaciones (D26); el
denominador de tramitación se recuenta al corte vigente, no se hereda del 381.
*Criterio de éxito:* entidad `proyecto` publicada con su cobertura declarada sobre
el denominador correcto, contado en la corrida.

**P-82 — El agregado de "desalineados" sobrevive en una línea de log fuera del
`stop()`.** *Tipo:* deuda técnica. *Impacto:* bajo. *Complejidad:* baja.
*Criterio de éxito:* la misma prueba de C14, aplicada a la línea de log.

**P-84 — 46 de las 49 clases portadoras de `tieneMateria` sin medir (nuevo).**
Q5 midió tres portadores (`MocionParlamentaria`, `TramitacionProyectoDeLey`,
`SeccionProyectoDeLey`) y dio 0 de 422. Los demás no se interrogaron. *Tipo:*
deuda de medición. *Impacto:* bajo; es la refutación posible del veredicto, ya
anotada en su §7.2. *Complejidad:* baja. *Criterio de éxito:* o se mide y el "no"
se confirma, o aparece un portador con cobertura y el veredicto se revisa.

**P-60 — Ordenación del repositorio (gatillo 4bis encendido).** *Tipo:* deuda
heredada. *Evidencia del gatillo:* no existe
`50_documentacion/activa/50_ordenacion_repositorio.md` (verificado con `ls` en la
Fase A de esta sesión). Incluye el recuento programático pendiente del §10.

**P-79 — `sin_registro` no distingue "no sabemos" de "sabemos que está mal".**
*Tipo:* deuda técnica. *Dependencia:* D31 (ratificada).

**P-81 — La contención del borde superior cubre solo el paso 36 y solo
`Votaciones`.** *Tipo:* deuda técnica.

**P-57 — Constantes nombradas al inicio de cada script.** *Tipo:* deuda técnica.

**P-75 — El campo `§3` que pedía el hash de `main` es estructuralmente
autodestructivo.** Mitigado por SETTINGS v20; queda como registro.

**Borde inferior del nodo `Votaciones`.** 176 de 723 eventos anteriores a
`ANIO_PROCESO` en 29 de 115 boletines, medidos al corte 2026-08-03 y **no
remedidos**. Esta sesión tampoco los remidió. *Tipo:* decisión pendiente del
titular.

**Arquitectura del pipeline del Senado.** *Tipo:* funcionalidad mayor. Sin avance.

**Rama `sondeo/p68-fuentes-tematicas` sin mergear.** Cinco commits, sin push.
Decisión del titular si entra a `main`; su contenido es documentación y un
reproductor en carpeta gitignorada.

### 11.2 Deuda técnica

Zonas frágiles: sin cambio respecto a v19.
`regenerar_intermedios_si_desalineados()` sigue con 198 líneas y cuatro guardas, y
sigue siendo la función con más superficie del proyecto; P-82 la toca. Oportunidad
nueva: el patrón de "cuadre contra la lista pedida" (D38) apareció tres veces en
una sola sesión escrito a mano cada vez; si vuelve a aparecer, merece helper.

### 11.3 Auditoría de cierre (política 5.6)

| Pregunta | Respuesta |
|---|---|
| ¿Los datos crudos siguen aislados e inmutables? | **Sí.** 51 archivos de `20_insumos/camara/` con md5 agregado idéntico entre G0 y el cierre, línea por línea |
| ¿El pipeline corre de cero sin intervención manual? | **Sin evidencia nueva.** La sesión no corrió el pipeline; la última evidencia completa sigue siendo la corrida del bot de la sesión 18 |
| ¿Paquetes, rutas y constantes al inicio de cada script? | **Parcial.** P-57 sigue abierto |
| ¿La estructura respeta la política? | **No.** Deuda heredada, materia de P-60 |
| ¿Nombres sin tildes, ñ ni espacios? | **No.** Un archivo bajo `andamios/design_handoff_portal_transparencia/` |
| ¿Todo cambio quedó verificado con criterio explícito? | **Sí.** 11 de 11 criterios en P-68, con C10 declarado con salvedad (no se rehízo la corrida completa contra la red desde cero) |
| ¿Quedó algo sin commitear? | **No.** `main` y la rama del sondeo con working tree limpio. La rama del sondeo sin push, por decisión |

### 11.4 Ruta sugerida para la sesión 21

**Prioridad 1 — P-66, entidad `proyecto` con tramitación.** Criterio de
priorización: es la funcionalidad de mayor impacto pendiente, su bloqueo se
levantó esta sesión, y el veredicto del eje temático ya dejó escrito su contrato
propuesto. *Criterio de éxito:* entidad publicada con cobertura declarada sobre
denominador contado en la corrida y `cobertura_materias` explícito por proyecto.

**Prioridad 2 — P-82**, barato y con criterio de éxito ya definido.

**Prioridad 3 — P-84**, una consulta, cierra la única refutación abierta del
veredicto de P-68.

**Conviene diferir:** P-60 (mueve demasiados archivos para competir con trabajo de
datos, aunque el gatillo lleva dos sesiones encendido), el pipeline del Senado,
P-79 y P-81 (consecuencias de D31, mejor después de P-66), y el borde inferior,
que espera decisión y no trabajo técnico.

## §12. Instrucciones específicas para la próxima sesión

- ⚠️ **NO** afirmar `CORTE_FECHA`, el sello de un intermedio ni el hash de `main`
  sin leerlos en el momento de afirmarlo.
- ⚠️ **NO** heredar el universo de este traspaso: 427 boletines, 422 sin materia y
  336 de cohorte 2026 son del corte **2026-08-12** y se remiden.
- ⚠️ **NO** heredar las cifras del nodo `Votaciones` (723 eventos, 115 boletines,
  176 del borde inferior): están ancladas al corte 2026-08-03.
- ⚠️ **NO** agregar sobre lo que un endpoint devuelve cuando puede omitir sujetos
  ausentes: el denominador es la lista pedida, con `stopifnot()` de cuadre (D38).
- ⚠️ **NO** reportar una cobertura de 0 sin control positivo de la misma consulta
  (D37).
- ⚠️ **NO** aceptar un HTTP 200 como prueba de que un endpoint es lo que dice ser:
  exigir forma de resultado (A82).
- ⚠️ **NO** correr ninguna prueba que ejercite el pipeline sin el fusible
  instalado (`quit(99)`). Un `stop()` no basta: el 36 lo atrapa y lo degrada a
  `estado = error_red`.
- ⚠️ **NO** usar `gh pr diff --name-only` (HTTP 406 en PRs grandes) ni pasarle
  rutas con `--`. Para listar archivos de un PR, `gh api` paginado sobre
  `/repos/<owner>/<repo>/pulls/<n>/files`; `gh api` **no** acepta `-R`.
- ⚠️ **NO** publicar cobertura temática sobre el denominador total de votaciones:
  el correcto es el subconjunto tipo `Proyecto de Ley` (D26).
- ⚠️ **NO** hacer join entre Cámara y Senado por identificador numérico solo: 5
  colisiones activas.
- ⚠️ **NO** tratar `<Materias/>` ni `<Votaciones/>` como nodos ausentes: vienen
  presentes y autocerrados.
- ⚠️ **NO** hacer join temático contra `datos.bcn.cl` por texto: 0 de 11 por id, y
  el mismo tema aparece en cuatro grafías.
- ⚠️ **NO** usar `senadores_vigentes.php` como padrón, ni
  `/api/sessions/attendance?id_legislatura=`.
- ⚠️ **NO** tratar un comentario de código como fuente sobre quién consume una
  función (A70).
- ✅ **ANTES** de escribir el umbral de una compuerta, medir el piso contra el que
  discrimina; si no está medido, el umbral es hipótesis (D36).
- ✅ **ANTES** de declarar que una llave no está en una fuente, buscarla también en
  la URI del recurso, no solo como literal (A83).
- ✅ **ANTES** de medir cobertura por una propiedad, preguntar de qué clases son
  sus sujetos: la clase obvia puede ser minoritaria (Q2).
- ✅ **ANTES** de construir un extractor, medir el techo de la fuente (A87).
- ✅ **ANTES** de declarar una cobertura, declarar su universo y su denominador en
  la misma línea, contados en el turno (A81).
- ✅ **ANTES** de usar la existencia de un directorio como señal, medir qué
  trackea git dentro (A78).
- ✅ **ANTES** de dar por entregado un artefacto, comprobar que quedó adjunto en el
  mismo turno que lo anuncia (A52).
- 🔒 `sellar()`, `leer_sellado()` y `validar_corte()` no se tocan.
- 🔒 La guarda del contrato temporal (D31) y su registro no se aflojan sin decisión
  explícita del titular.
- 🔒 `40_salidas/intermedios/.gitkeep` sigue trackeado.
- 🔒 `10_utils/10_utils.R` no adquiere dependencias de paquetes.
- 🔒 Los intermedios no se versionan (D24). `20_insumos/camara/` es crudo
  inmutable.
- 🔒 `main` no recibe escrituras automáticas ni push directo del bot. El bot abre
  PR.
- 🔒 `sin_registro` no se imputa, ni en el dato ni en la presentación.
- 🔒 El titular de asistencia del portal es
  `asistencia.periodo_vigente.tasa_presencia` (D18).
- 🔒 R es el único lenguaje, en todo contexto. Sin `jq`, `awk`, `python`, ni
  `grep`/`sed` sobre artefactos de datos; sin regex en `Rscript -e`.
- 🔒 `git` siempre con `-C <ruta absoluta>`, `gh` siempre con `-R tomgc/...`
  **salvo `gh api`**, `git add` siempre con ruta acotada.
- 🔒 `proyectos_detalle.rds` mantiene una fila por boletín (D28).
- 🔒 Los campos con atributo de dominio se conservan con código y glosa (D29).

## §13. Fragmentos de código de referencia

Dos patrones nuevos, ambos en
`20_insumos/exploracion/20260813/20260813_sondeo_p68.R` (carpeta gitignorada: si
se necesitan fuera del sondeo, hay que promoverlos a `10_utils/`).

**1. Cuadre contra la lista pedida (D38).** Aplicable a toda agregación sobre una
fuente que puede omitir sujetos ausentes.

```r
# `pedidos` es el vector de llaves solicitadas; `devueltos` lo que la fuente emitió.
# La reconciliacion se hace SIEMPRE contra `pedidos`, y el cuadre lo prueba.
resultado <- data.frame(
  llave     = pedidos,
  presente  = pedidos %in% devueltos,
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(resultado) == length(pedidos),
  sum(resultado$presente) == length(unique(intersect(pedidos, devueltos)))
)
```

**2. Control positivo de la propia consulta (D37).** Antes de reportar un cero
sobre un universo, correr la misma consulta contra casos que sí deben devolver.

```r
# `consultar` es la funcion que produjo el cero sobre el universo.
control <- consultar(llaves_que_deben_devolver)
if (nrow(control) == 0)
  stop("La consulta no devuelve ni para los controles positivos: el cero del ",
       "universo no es medicion, es una consulta rota.", call. = FALSE)
```

El fusible de red (`50_documentacion/andamios/50_fusible_red.R`) y el patrón de
prueba de guardas por escenario en subproceso siguen donde estaban.

## §14. Reapertura

Tipo: CONTINUATION. El protocolo (`POLITICA_PROYECTO.md` v5.6,
`SETTINGS_Y_PROMPTS_OPERACIONALES.md` v23) vive en la knowledge base del Project y
se lee desde ahí; verifica las versiones contra la knowledge base, no contra
ninguna otra fuente, antes de la Fase A.
Estado: la sesión 20 cerró P-83 y P-68. P-68 cerró con **NO**: ni LeyChile ni
`datos.bcn.cl` entregan materias en cantidad capaz de dar vuelta el veredicto del
eje temático, y ese "no" **acota** P-66 sin cancelarlo. Los PR #11 y #12 de la
sesión 19 aparecieron mergeados al abrir esta sesión.
No creas a este traspaso sobre `CORTE_FECHA`, sobre el hash de `main`, sobre el
universo de boletines (427 / 422 / 336 son del corte 2026-08-12) ni sobre ninguna
cifra del nodo `Votaciones`: todas se remiden. Queda una rama sin mergear,
`sondeo/p68-fuentes-tematicas`, con los artefactos del sondeo; verifica su estado
antes de suponer nada, con
`gh pr list -R tomgc/transparencia_legislativa_chile --state all` y
`git -C <raiz> branch -a`.
El foco propuesto es P-66: publicar la entidad `proyecto` con tramitación, cuyo
contrato ya está redactado en `50_documentacion/activa/50_veredicto_eje_tematico.md`
§5.2 y cuyo alcance quedó fijado por el veredicto nuevo. Encadenado: P-82 y P-84,
ambos baratos. Sigue encendido el gatillo 4bis (ordenación, P-60), ahora por
segunda sesión consecutiva.
El §15 trae tres errores registrados, los tres del asistente conversacional, y dos
de ellos son del encargo mismo: un umbral que no discriminaba y una instrucción
que contradijo el encargo que yo había escrito.
Documentos para la próxima sesión:

1. Protocolo en knowledge base (no se adjuntan; se listan para verificar que la
   knowledge base esté al día): `POLITICA_PROYECTO.md`,
   `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
2. Opcionales según el foco real: `CLAUDE.md` si la sesión correrá en Claude Code.
3. Específicos de la sesión: `traspaso_cierre_v20.md`;
   `50_documentacion/activa/50_veredicto_eje_tematico.md` (trae el contrato
   propuesto de la entidad `proyecto` en su §5.2, insumo directo de P-66);
   `50_documentacion/activa/50_veredicto_fuentes_tematicas_bcn.md` (fija el
   alcance).

## §15. Errores del asistente

**Error 1.**

| Campo | Contenido |
|---|---|
| Momento | Redacción del encargo de P-68, criterio de cierre de G4 |
| Disparador | Claude Code reportó G1 con el piso de cobertura medido en 1,17 % |
| Qué pasó | Escribí el umbral de G4 como "menor que la cobertura que el portal ya tiene", que con un piso de 1,17 % no discrimina: casi cualquier resultado lo supera |
| Regla violada | SETTINGS §1.2.4 y estructura de encargo: los criterios de éxito deben ser verificables y contrastables; un criterio que todo resultado aprueba no lo es |
| Causa raíz | Redacté el umbral **antes** de que el piso estuviera medido, tratando como conocido un valor que era hipótesis (el 1,31 % heredado del veredicto del corte 2026-08-03) |
| Salvaguarda presente | El propio encargo ordenaba no heredar denominadores del corte anterior, y esa regla protegió las cifras del sondeo pero no el umbral que yo mismo escribí con una de ellas |
| `gatillo_observable` | Un umbral de compuerta cuya cifra de referencia no aparece en ninguna medición del mismo documento |
| Detección | Al recibir G1, en el mismo turno en que aprobé G2 |
| Corrección | Umbral sustituido por la cohorte 2026 (336 de 422) y registrado como enmienda al encargo en la bitácora; queda como D36 |
| `intentos_previos` | Ninguno para este patrón específico |
| `costo` | Nulo: se corrigió antes de que G4 corriera |
| Impacto | Nulo. Si no se hubiera corregido, G4 habría dejado abierta la rama LeyChile con un 4,27 % que no aporta |
| Patrón | PAT-01 (`catalogo_patrones_errores_v4.md`), variante "cifra heredada usada como referencia normativa" |

**Error 2.**

| Campo | Contenido |
|---|---|
| Momento | Mensaje a Claude Code que ordenaba escribir el panel adversarial y el veredicto |
| Disparador | Redactar la instrucción de la pregunta P5 del panel |
| Qué pasó | Escribí "si es barata, dilo; no la corras", contradiciendo el encargo que yo mismo había redactado, cuyo §7 punto 5 dice "si es barata, córrela" |
| Regla violada | Instrucción explícita ya dada en la sesión (el encargo es la fuente autoritativa y así lo declara su mensaje de arranque) |
| Causa raíz | Optimicé por cerrar el entregable en vez de por cumplir el instrumento; el encargo estaba escrito y no lo releí antes de instruir sobre una de sus secciones |
| Salvaguarda presente | El mensaje de arranque declara que si algo contradice el encargo, manda el encargo. La salvaguarda existía y apuntaba a Claude Code, no a mí |
| `gatillo_observable` | Una instrucción al agente que fija una conducta ya normada por el encargo vigente, sin citarlo |
| Detección | El titular pidió revisar lo que quedara dudando, y la primera duda fue esa misma medición |
| Corrección | P5 se corrió en el lote Q (Q1): `tieneTerminoLibre`, 1 de 5, no refuta. El veredicto pasa de "no medido" a "medido y no aporta" |
| `intentos_previos` | Ninguno |
| `costo` | Un turno del titular y una llamada de red |
| Impacto | Bajo, pero habría dejado publicado un veredicto con su propia refutación candidata sin correr |
| Patrón | PAT-06 (instrucción que contradice instrumento vigente del mismo autor) |

**Error 3.**

| Campo | Contenido |
|---|---|
| Momento | Primer mensaje de la sesión, bloque de comandos de verificación de la Fase A |
| Disparador | El titular respondió "dame bien los comandos, carajo" |
| Qué pasó | Entregué ocho comandos en un bloque sin etiquetar, de modo que la salida quedó imposible de atribuir línea a línea |
| Regla violada | `userPreferences`, marcador de fuente tipo 2: el estado del repositorio se afirma con el comando que lo produjo, y una salida no atribuible no permite cumplirlo |
| Causa raíz | Optimicé el bloque para que fuera corto de pegar, no para que su salida fuera legible |
| Salvaguarda presente | Ninguna: no existe regla sobre la **forma** de un bloque de verificación, solo sobre la atribución de lo que se afirma con él |
| `gatillo_observable` | Un bloque con más de dos comandos cuya salida no lleva separador ni eco del comando |
| Detección | El titular lo señaló, sin nombrarlo error |
| Corrección | Se entregó la forma con `printf '===== %s\n'` y eco de exit code; la salida original alcanzó igual para leer los ocho valores |
| `intentos_previos` | Ninguno |
| `costo` | Un turno |
| Impacto | Bajo |
| Patrón | PAT-04 (forma del entregable degrada su verificabilidad) |

### Fricciones

friccion: el bloque de verificación de la Fase A llegó sin etiquetas y obligó a
contar líneas para atribuir salidas → se adoptó eco del comando con separador y
exit code por comando.
