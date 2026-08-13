# Traspaso de cierre v21 — transparencia_legislativa_chile

## §1. Identificación

| Campo | Valor |
|---|---|
| Proyecto | `transparencia_legislativa_chile` |
| Versión | v21 |
| Fecha de cierre | 2026-08-13 |
| Sesión | 21 |
| Foco | P-66: medir el contrato de la entidad `proyecto` contra el corte vigente (acto A) y construirla y publicarla con tramitación desde el SIL (acto B). |
| Entorno | R 4.5.2 en Positron, macOS; Claude Code como agente de ejecución (Opus 5) |
| Protocolo | `POLITICA_PROYECTO.md` v5.6 y `SETTINGS_Y_PROMPTS_OPERACIONALES.md` v23, ambas verificadas contra la knowledge base en la Fase A |
| `main` | `cbc29b5` (**previo al commit de cierre**) |
| Ramas de la sesión | `medicion/p66-acto-a` (PR #14, mergeado) y `construccion/p66-acto-b` (PR #15, mergeado); ninguna borrada |
| Archivos principales modificados | `30_procesamiento/37_extraer_tramitacion.R` (nuevo), `30_procesamiento/39_consolidar_json.R`, `10_utils/10_utils.R`, `10_utils/10_diff_conteos.R`, `00_run_all.R`, `20_insumos/senado/` (nuevo), `40_salidas/json/proyectos/` (nuevo), `docs/data/proyectos/` (nuevo), tres encargos y dos bitácoras en `50_documentacion/andamios/` |

## §2. Resumen ejecutivo

La sesión cerró P-66 completo, en dos actos separados por una decisión del
titular. El acto A midió, sin escribir una línea de pipeline, el contrato §5.2
del veredicto del eje temático contra el corte vigente, y encontró que sus
cifras eran de un universo que ya no existe: 427 boletines contra los 381 sobre
los que se redactó. La medición estableció que la tramitación es construible y
sale completa (el SIL resuelve 427 de 427), que `etapa` y `estado` llegan sin
código de dominio, y que `ley_numero` cubre 28 de 427. Su hallazgo mayor no
estaba en el encargo: **el SIL entrega el estado al momento de la llamada, no al
corte declarado**, la misma asimetría que P-74 (A) cerró para el nodo
`Votaciones`.

El titular resolvió los diez gates abiertos y el acto B construyó sobre esas
decisiones. Entró un extractor nuevo (`37`), el destino de caché pasó a ser
parametrizable para que el crudo del SIL no se mezclara con el de la Cámara, el
`39` emite 427 JSON de la entidad `proyecto` con su índice, el diff aprendió una
métrica nueva y `00_run_all.R` corre siete pasos de punta a cabo sin red. Los
155 perfiles de diputado quedaron sin una sola diferencia real de dato,
verificado por un panelista independiente con `git hash-object` sobre 312
archivos.

El acto B se detuvo una vez, con razón: la hipótesis H1 del encargo
(`con_cache()` sirve a otra fuente sin modificarse) contradecía un invariante del
mismo encargo. La contradicción era del redactor y se resolvió por enmienda,
extendiendo `ruta_cache()`, `con_cache()` y `reportar_estado_capturas()` con un
parámetro de destino, sin tocar `sellar()`, `leer_sellado()` ni
`validar_corte()`.

Dos hallazgos de la corrida quedan como pendientes con consecuencia. El SIL
**no es append-only**: entre dos capturas del mismo día reescribió trámites de
fechas ya pasadas en `18431-31`. Y el acotamiento temporal, aritméticamente
correcto, es semánticamente ciego: descarta por errata de la fuente el trámite
terminal de un proyecto que ya es ley.

## §3. Estado al cierre

**Qué funciona.** El pipeline completo, con siete pasos: `00_run_all.R` corre de
punta a cabo en 15,7 s con cero llamadas de red (fusible armado, sin disparar).
La entidad `proyecto` está publicada: 427 JSON en `40_salidas/json/proyectos/` y
427 en `docs/data/proyectos/`, con paridad de 427 de 427 md5 entre canónico y
publicado. La entidad parlamentario sigue intacta: 155 perfiles sin diferencia
real de dato e `indice_diputados.json` idéntico byte a byte
(`a570af9ecd9df02b1c9389bb1f5c87e4`). `CORTE_FECHA` es `2026-08-12`
(`10_utils/10_configuracion.R:57`, leído en la sesión).

**Qué no funciona.** Nada activo. Tres estados que conviene no confundir con
fallos:

1. La captura del SIL queda marcada `fuera_de_corte` (descarga 2026-08-13,
   escape `TRUE`) en cada corrida futura, porque solo podía tomarse el día
   siguiente al corte. La guarda de P-74 se disparó correctamente, gastó cero
   llamadas y el escape que ella misma ofrece quedó consumido.
2. `capturas_crudas_de_paso()` e `INTERMEDIOS_PIPELINE` no conocen el paso 37.
   El dato nunca se publica mal, pero si `tramitacion.rds` se desalinea,
   `validar_corte()` detiene con un mensaje que manda a regenerar los pasos
   equivocados. Ruta de recuperación falsa, no dato falso.
3. `camara_origen` y `fecha_ingreso` se publican con procedencia del SIL y no de
   la Cámara, que es la fuente autoritativa de sus propios proyectos.

**PR de la sesión, todos verificados y mergeados:**

| PR | Rama | Estado | Commit de merge |
|---|---|---|---|
| #13 | `sondeo/p68-fuentes-tematicas` | `MERGED` | `4f187be` |
| #14 | `medicion/p66-acto-a` | `MERGED` | `15d2a53` |
| #15 | `construccion/p66-acto-b` | `MERGED` | `cbc29b5` |

**Delta respecto a v20.** El portal pasa de una entidad publicada a dos. El
veredicto del eje temático deja de ser una propuesta y pasa a ser un artefacto.
Los intermedios, que llevaban dos sesiones desalineados, quedaron regenerados al
corte vigente sin red. El gatillo 4ter sigue apagado; el **4bis sigue encendido,
por tercera sesión consecutiva**.

## §4. Registro detallado de cambios

**Registro de ejecución detallado:**
`50_documentacion/andamios/logs/20260813_p66_acto_a_log.md` y
`50_documentacion/andamios/logs/20260813_p66_acto_b_log.md` (logs de las sesiones
de Claude Code; detalle paso a paso no reproducido aquí).

### 4.1 P-66 acto A — Medición del contrato (solo lectura)

**Archivos:** `50_documentacion/andamios/50_encargo_p66_acto_a_medicion.md`,
`50_documentacion/andamios/50_medicion_p66_acto_a.md`, su bitácora, y
`20_insumos/exploracion/20260813/` (gitignorada). **Categoría:**
diagnóstico/exploración. **Commits:** `45accf6`, `e35fbff`; encargo en `f80772c`.

Ocho compuertas, todas CUMPLEN, con 437 de 600 llamadas autorizadas y el sello
del crudo de la Cámara idéntico entre apertura y cierre (51 archivos,
`8bf1b0b4765a99e8b15ce7747de2609e`, 51 de 51 md5 coincidentes).

Lo que midió, en una línea cada uno: universo 427 boletines (422 sin materia,
336 de cohorte 2026); votaciones 561 de 842 tipo `Proyecto de Ley`; autoría 314
boletines con autor y 155 de 199 autores en el padrón; contrato §5.2 campo por
campo, con los cuatro campos de `tramitacion` en 0 de 427 tras barrer diez rutas
candidatas; SIL 427 de 427 con 4 799 trámites; costo 370,4 s y 3,13 MB.

**El panel cambió el reporte.** P1 estableció por camino propio que el universo
es **derivado** (`union(314, 119) == 427`, identidad exacta) y resolvió la brecha
737 contra 561 del nodo `Votaciones`. P2 objetó que "parseable" no es "válida"; el
recuento propio del agente encontró **dos** fechas fuera de rango, no una, y la
segunda es la que importa (A88). P3 aportó `ctime` sobre `mtime`, porque el
proyecto usa `Sys.setFileTime()` y el `mtime` es falsificable.

### 4.2 P-66 acto B — Construcción y publicación

**Archivos:** los del §1. **Categoría:** consolidación/salida. **Commits:**
`2f21166`, `9c35e2d`, `b4b0bcd`, `a55d06d`, `9e369bd`, `e9dd097`, `da72568`,
`e998315`, `801db81`, `18501a2`; encargo en `6a929cf`.

Siete fases, todas CUMPLEN:

| Fase | Qué hizo | Verificación |
|---|---|---|
| F0 | Lectura del estado real | Seis puntos con archivo y línea; **detuvo por H1 falsa** |
| F0bis | Destino de caché parametrizable (enmienda 1) | 20 de 20 rutas idénticas a `HEAD`; 6 de 6 funciones protegidas idénticas por `deparse()` |
| F1 | `37_extraer_tramitacion.R` | Parser reproduce la ficha del acto A en 7 de 7 cifras; cuadre D38 427 = 427 |
| F2 | Guardas por escenario | 8 de 8 escenarios más E9; captura restaurada con md5 idéntico tras la prueba destructiva |
| F3 | La entidad `proyecto` | 427 JSON; 0 flags nulos; 0 `autores[].camara`; spot-check 1:1 sobre tres boletines distintos |
| F4 | Compuerta `proyectos_con_tramitacion` | No gatea sin corte anterior y dice por qué; gatea con dos cortes; FAIL ante caída 427 a 423 |
| F5 | Integración y publicación | `run_all()` 7 pasos, 15,7 s, cero red; perfiles 155 de 155 sin diferencia real |

**Un falso verde propio, atrapado y corregido.** El arnés de F2 contaba como
conforme cualquier salida no vacía en los escenarios sin `stop()`. El defecto
estaba en la prueba, no en el `37`, y el agente lo endureció antes de commitear.

**El panel volvió a cambiar el artefacto.** P1 y P2 llegaron por separado al
mismo defecto: `18232-25` está `Publicado` con Ley N° 21.825, así que su trámite
terminal ocurrió antes del corte, y el filtro lo descartaba como "posterior" por
una errata de la fuente (año 2626). Se corrigió en observabilidad (`e998315`),
separando las dos causas del descarte con el mismo criterio con que el `36` no
colapsa `no_reconocido` con `error_red`.

### 4.3 Higiene de repositorio y publicación

**Categoría:** integración/repo (no cuenta como cambio).

El cierre de la sesión 20 nunca se había pusheado: `origin/main` estaba cuatro
commits atrás, y por eso toda verificación del PR #13 medía un remoto atrasado.
Se pushearon los cuatro y se mergearon los tres PR. Los intermedios, que
declaraban corte `2026-08-03` con universo 381, se regeneraron desde el crudo ya
versionado con el fusible armado, sin que disparara: ahora declaran 427.

## §5. Decisiones de diseño

Los diez gates que el acto A dejó abiertos fueron resueltos por el titular y
quedan numerados en la serie del proyecto:

| # | Decisión | Fundamento |
|---|---|---|
| **D40** | La tramitación entra **con caché por corte**, no en llamada directa del cron | Respeta `con_cache()` y no acopla el refresh semanal a un servicio de otro poder del Estado |
| **D41** | El contrato se rehace sobre el universo del corte vigente, contado en la corrida | Un contrato con cifras de otro corte ya costó una sesión |
| **D42** | `etapa` y `estado` se publican **solo como glosa**, con `trimws()` | La fuente trae 0 atributos XML: construir un catálogo código→glosa sería fabricar el dato |
| **D43** | `ley_numero` lleva flag `cobertura_ley` | Con 28 de 427, sin flag el lector no distingue "no es ley" de "no lo sabemos" |
| **D44** | `autores[].camara` se retira del contrato; `metadatos.autoria_cubre` lo reemplaza | El parser ignora autores Senador, así que el campo habría sido constante y habría tapado esa exclusión |
| **D45** | El padrón histórico queda fuera de alcance | Abre identidad de parlamentarios; merece acto propio |
| **D46** | La compuerta nueva es `proyectos_con_tramitacion`, sola | `tramites_totales` habría oscilado sin que nada estuviera roto (ver A88) |
| **D47** | La tramitación se **acota al corte**, con descarte contado y emitido por log | Doctrina ya adoptada y probada en `acotar_votaciones_al_corte()` |
| **D48** | El universo derivado se **declara en `metadatos`** | El corpus son los boletines tocados por un diputado del roster, no los proyectos ingresados en el año |
| **D49** | Los eventos de votación anteriores a `ANIO_PROCESO` **se conservan**, con `detalle_nominal: false` por evento | La entidad `proyecto` es donde la historia completa del boletín corresponde; lo que falta es el desglose nominal, y eso se declara, no se imputa ni se borra |

**D50 — El destino del crudo es parte del contrato de caché, no del origen.**
`con_cache()` es agnóstica al origen (`fn_descarga` es un closure arbitrario) pero
no al destino: `ruta_cache()` fijaba `20_insumos/camara/`. `ruta_cache()` y
`con_cache()` ganan `subdir = "camara"`, retrocompatible por defecto, y
`reportar_estado_capturas()` barre también el directorio nuevo. *Por qué esto
último no era opcional:* si el crudo del SIL quedaba fuera de su barrido, el
contrato temporal de P-74 quedaba ciego justo sobre la fuente que entrega eventos
posteriores al corte, y D47 perdía su compuerta. *Alternativa descartada:* meter
el crudo del SIL en `camara/`, que no rompe ninguna función pero mezcla orígenes
en un directorio nombrado por host.

## §6. Bugs de la sesión

Sin bugs de código en el pipeline publicado. Tres defectos corregidos dentro de
la misma corrida:

| Defecto | Dónde | Cómo se detectó | Arreglo |
|---|---|---|---|
| Criterio de éxito que aceptaba cualquier salida no vacía | arnés de F2, escenario E3 | El escenario falló de verdad y el arnés lo contó conforme | Criterio endurecido; E3 vuelve a fallar donde debe |
| El descarte por acotamiento colapsaba dos causas distintas | `37_extraer_tramitacion.R` | Panel adversarial, P1 y P2 por separado | Separación de causas: posterior al corte contra año implausible, nombrado con su fecha |
| `%||%` del proyecto no está vectorizado y revienta con una lista de trámites | `10_diff_conteos.R` | Prueba de la compuerta en sus tres estados | Comprobación explícita en vez del operador |

## §7. Aprendizajes y restricciones

**A88 — El SIL no es append-only: reescribe historia de fechas ya pasadas.**
Entre las 14:41 y las 17:52 del mismo día, `18431-31` ganó dos trámites y perdió
uno, todos con fecha anterior al corte. La clave de caché fija la fecha, no el
contenido: **el crudo capturado es el único registro de qué decía la fuente ese
día**. Valida a posteriori D46.

**A89 — Un acotamiento aritméticamente correcto puede ser semánticamente
ciego.** El filtro de D47 descarta el trámite terminal de `18232-25`, que es ley
publicada, porque la fuente lo fechó en 2626. La regla es correcta; el efecto,
una pérdida silenciosa hasta que el panel la nombró.

**A90 — Presencia de nodo no es presencia de dato, otra vez.** `leynro` está
presente en 427 de 427 y vacío en 399: contar por presencia da 427 en vez de 28,
error de 15,2 veces. Es A62 reapareciendo en otra fuente.

**A91 — La vista de archivos de un PR queda anclada a su `base.sha`.** El PR #13
mostró cuatro archivos durante todo su ciclo, sin recalcularse en doce sondeos.
Lo que un merge aplicaría se mide con `git merge-tree --write-tree`, no con la
vista. `merge_commit_sha` en un PR abierto es un merge **especulativo** y no
prueba nada.

**A92 — Un cierre no pusheado envenena toda verificación posterior.** Cuatro
turnos de esta sesión se gastaron midiendo un remoto que estaba cuatro commits
atrás del local.

**A93 — Las fechas del SIL son `%d/%m/%Y`.** Parsearlas como ISO da 0 de 4 799
sin error visible.

**A94 — Una restricción de alcance puede mover la procedencia de un dato.** La
instrucción "un helper insuficiente se reporta, no se extiende" evitó deriva de
arquitectura y, sin proponérselo, hizo que dos campos publicados vinieran de la
fuente secundaria.

## §8. Estado de decisiones previas

**D26 vigente:** ninguna cobertura se publicó sobre el total de votaciones; el
denominador declarado es 561 de 842.

**D31 y el contrato temporal:** la guarda se disparó donde debía, gastó cero
llamadas y su escape quedó consumido y visible en cada corrida futura. El
mecanismo funcionó exactamente como fue diseñado.

**D28 y D29:** `proyectos_detalle.rds` intacto; D29 no tiene código que conservar
en esta fuente, y así se reportó en vez de fabricarlo.

**Borde inferior del nodo `Votaciones`:** D49 lo resuelve **solo para la entidad
`proyecto`**. Para la entidad parlamentario sigue siendo decisión pendiente.

## §9. Constantes y parámetros

`CORTE_FECHA` sigue en `2026-08-12`. Nuevo: `ruta_cache()` y `con_cache()`
aceptan `subdir`, con default `"camara"`. `METRICAS_GATE` suma
`proyectos_con_tramitacion`, que no gatea mientras no exista corte anterior
comparable.

## §10. Arquitectura de archivos

Escáner regenerado en el cierre; su sello queda en el log de cierres. Cambios de
estructura: un directorio de crudo nuevo y versionado (`20_insumos/senado/`), un
script nuevo (`30_procesamiento/37_extraer_tramitacion.R`), dos directorios de
salida nuevos (`40_salidas/json/proyectos/` y `docs/data/proyectos/`, 427
archivos cada uno) y cinco documentos nuevos en `50_documentacion/andamios/`.

`20_insumos/senado/` se versiona sin entrada de `.gitignore`: la regla del repo
excluye solo `exploracion/`, y por una razón que aquí no aplica (datos de
contacto nominales del sondeo, que el SIL no trae).

Las desviaciones heredadas siguen abiertas y son materia de P-60. **La cifra de
archivos de `50_documentacion/activa/` sin prefijo `50_` sigue sin recuento
programático**, y esta sesión tampoco lo hizo.

## §11. Pendientes y ruta sugerida

### 11.1 Inventario

**P-86 — El paso 37 es desconocido para `capturas_crudas_de_paso()` e
`INTERMEDIOS_PIPELINE`.** *Tipo:* deuda técnica. *Impacto:* alto por su
oportunidad, no por su gravedad: si `tramitacion.rds` se desalinea,
`validar_corte()` detiene con una instrucción de recuperación equivocada, y el
cron corre el lunes. *Complejidad:* baja. *Criterio de éxito:* el mensaje de
recuperación nombra el paso correcto, probado en subproceso con el intermedio
desalineado a propósito.

**P-85 — El SIL no es append-only (nuevo).** *Tipo:* decisión pendiente del
titular. *Impacto:* alto. Un corte deja de ser reproducible desde la fuente:
recapturar el mismo corte puede dar un contenido distinto. Hay que decidir si la
captura es inmutable una vez tomada (y entonces qué pasa con las correcciones de
la fuente) o si se recaptura y se versiona la diferencia. *Complejidad:* media.
*Criterio de éxito:* política escrita y una guarda que la haga observable.

**P-88 — El acotamiento pierde el trámite terminal de `18232-25` (nuevo).**
*Tipo:* deuda de datos. *Impacto:* bajo en volumen (1 de 4 800), alto en
semántica: el proyecto se publica sin su trámite de ley. *Complejidad:* baja.
*Criterio de éxito:* las erratas de la fuente se tratan por una vía distinta del
acotamiento temporal, contadas y visibles.

**P-87 — `camara_origen` y `fecha_ingreso` vienen del SIL (nuevo).** *Tipo:*
deuda de datos. *Dependencia:* extender `parsear_contenido_proyecto()`, que la
Cámara sí expone con código y glosa. *Complejidad:* baja. *Criterio de éxito:*
ambos campos con procedencia de la Cámara y su atributo conservado (D29).

**P-89 — Acto C: la vista de la entidad `proyecto` en el dashboard (nuevo).**
*Tipo:* funcionalidad. *Impacto:* alto: hoy los 427 JSON se sirven pero
`docs/index.html` no los muestra. *Complejidad:* alta.

**P-90 — El escape temporal del SIL en la corrida del bot (nuevo).** *Tipo:*
deuda técnica. Hay que verificar que en el cron, donde corte y captura son del
mismo día, el escape **no** se necesite. Un escape que se vuelve rutina deja de
ser escape. *Complejidad:* baja.

**P-84 — 46 de las 49 clases portadoras de `tieneMateria` sin medir.** Sin
avance en esta sesión.

**P-82 — El agregado de "desalineados" sobrevive fuera del `stop()`.** Sin
avance.

**P-60 — Ordenación del repositorio (gatillo 4bis encendido, tercera sesión).**
*Tipo:* deuda heredada. *Evidencia del gatillo:* no existe
`50_documentacion/activa/50_ordenacion_repositorio.md`.

**P-79, P-81, P-57, P-75.** Sin cambio.

**Borde inferior del nodo `Votaciones` para la entidad parlamentario.** D49 lo
resolvió solo para `proyecto`.

**Arquitectura del pipeline del Senado.** Sin avance.

### 11.2 Deuda técnica

Zona frágil nueva: `37_extraer_tramitacion.R` nace con 442 líneas y es el único
extractor que habla con un servicio de otro poder del Estado. Zona frágil
persistente: `regenerar_intermedios_si_desalineados()`, que P-82 y P-86 tocan por
lados distintos. Oportunidad: el patrón de cuadre contra la lista pedida (D38) ya
apareció en tres corridas seguidas escrito a mano; merece helper.

### 11.3 Auditoría de cierre (política 5.6)

| Pregunta | Respuesta |
|---|---|
| ¿El pipeline corre de cero sin intervención manual? | **Sí.** `run_all()` completo, 7 pasos, 15,7 s, cero red |
| ¿Cada transformación crítica tiene check de validación? | **Sí** para lo nuevo: cuadre D38, acotamiento contado, compuerta en sus tres estados |
| ¿Los outputs son reproducibles e idempotentes? | **Parcial.** Idempotentes salvo `metadatos.generado` (`Sys.time()`, anterior a este encargo). Reproducibles desde el crudo, **no** desde la fuente: ver A88 |
| ¿Decisiones metodológicas como constantes nombradas? | **Parcial.** P-57 sigue abierto |
| ¿Nombres sin tildes, ñ ni espacios? | **No.** Un archivo bajo `andamios/design_handoff_portal_transparencia/` |
| ¿Quedó algo sin commitear? | **No.** Árbol limpio; los tres PR mergeados y `main` en `cbc29b5` |

### 11.4 Ruta sugerida para la sesión 22

**Prioridad 1 — P-86**, la ruta de recuperación falsa del paso 37. Criterio de
priorización: instrucción explícita heredada y ventana temporal (el cron corre el
lunes). Barato.

**Prioridad 2 — P-88 y P-87**, ambos baratos, ambos de calidad del dato recién
publicado, mejor corregidos antes de que alguien consuma el artefacto.

**Prioridad 3 — P-85**, que es decisión antes que código y conviene tomarla con
el hallazgo fresco.

**Conviene diferir:** P-89 (acto C, sesión dedicada), P-60 (aunque el gatillo
lleva tres sesiones), el pipeline del Senado, P-79, P-81 y P-84.

## §12. Instrucciones específicas para la próxima sesión

- ⚠️ **NO** afirmar `CORTE_FECHA`, el sello de un intermedio ni el hash de `main`
  sin leerlos en el momento de afirmarlo.
- ⚠️ **NO** heredar el universo de este traspaso: 427 boletines, 4 800 trámites y
  561 de 842 votaciones son del corte **2026-08-12** y se remiden.
- ⚠️ **NO** suponer que recapturar el mismo corte del SIL devuelve el mismo
  contenido: no es append-only (A88).
- ⚠️ **NO** tratar un descarte por acotamiento temporal como si todos tuvieran la
  misma causa: una errata de la fuente no es un evento posterior (A89).
- ⚠️ **NO** contar por presencia de nodo cuando el nodo puede venir vacío (A90).
- ⚠️ **NO** creerle a la vista de archivos de un PR: mide el merge real con
  `git merge-tree --write-tree` (A91).
- ⚠️ **NO** tomar `merge_commit_sha` de un PR abierto como prueba de merge: es
  especulativo (A91).
- ⚠️ **NO** dar por pusheado un cierre sin verificarlo: un remoto atrasado
  envenena toda verificación posterior (A92).
- ⚠️ **NO** parsear las fechas del SIL como ISO: son `%d/%m/%Y` (A93).
- ⚠️ **NO** agregar sobre lo que un endpoint devuelve cuando puede omitir sujetos
  ausentes: el denominador es la lista pedida, con `stopifnot()` de cuadre (D38).
- ⚠️ **NO** reportar una cobertura de 0 sin control positivo de la misma consulta
  (D37).
- ⚠️ **NO** aceptar un HTTP 200 como prueba de que un endpoint es lo que dice
  ser: los controles negativos del SIL devolvieron 200 con cuerpo de 24 bytes
  (A82).
- ⚠️ **NO** correr ninguna prueba que ejercite el pipeline sin el fusible
  instalado (`quit(99)`).
- ⚠️ **NO** usar `gh pr diff --name-only` (HTTP 406 en PRs grandes) ni `gh --jq`:
  `gh api > archivo.json` y `jsonlite::fromJSON()` en R.
- ⚠️ **NO** publicar cobertura temática sobre el denominador total de votaciones
  (D26).
- ⚠️ **NO** hacer join entre Cámara y Senado por identificador numérico solo.
- ⚠️ **NO** hacer join temático contra `datos.bcn.cl` por texto.
- ⚠️ **NO** tratar un comentario de código como fuente sobre quién consume una
  función (A70).
- ✅ **ANTES** de escribir un invariante en un encargo, leer la función que
  tendría que cumplirlo: un 🔒 más fuerte que la norma real bloquea la ejecución
  (enmienda 1 de esta sesión).
- ✅ **ANTES** de declarar que un helper es insuficiente y no extenderlo,
  comprobar que la restricción no mueve la procedencia de un dato publicado
  (A94).
- ✅ **ANTES** de medir cobertura por una propiedad, preguntar de qué clases son
  sus sujetos.
- ✅ **ANTES** de construir un extractor, medir el techo de la fuente (A87).
- ✅ **ANTES** de declarar una cobertura, declarar su universo y su denominador en
  la misma línea, contados en el turno (A81).
- ✅ **ANTES** de dar por entregado un artefacto, comprobar que quedó adjunto en
  el mismo turno que lo anuncia (A52).
- 🔒 `sellar()`, `leer_sellado()` y `validar_corte()` no se tocan.
- 🔒 La guarda del contrato temporal (D31) y su registro no se aflojan sin
  decisión explícita del titular.
- 🔒 `40_salidas/intermedios/.gitkeep` sigue trackeado.
- 🔒 `10_utils/10_utils.R` no adquiere dependencias de paquetes.
- 🔒 Los intermedios no se versionan (D24). El crudo es inmutable **en el sentido
  correcto**: ninguna captura ya escrita se modifica ni se borra, y cada fuente
  vive en su propio directorio por host.
- 🔒 `main` no recibe escrituras automáticas ni push directo del bot.
- 🔒 `sin_registro` no se imputa, ni en el dato ni en la presentación.
- 🔒 El titular de asistencia del portal es
  `asistencia.periodo_vigente.tasa_presencia` (D18).
- 🔒 R es el único lenguaje, en todo contexto.
- 🔒 `git` siempre con `-C <ruta absoluta>`, `gh` siempre con `-R tomgc/...`
  **salvo `gh api`**, `git add` siempre con ruta acotada.
- 🔒 `proyectos_detalle.rds` mantiene una fila por boletín (D28).
- 🔒 Los campos con atributo de dominio se conservan con código y glosa (D29).

## §13. Fragmentos de código de referencia

**1. Retrocompatibilidad demostrada, no inspeccionada.** Patrón nuevo de F0bis,
aplicable a toda extensión de una firma existente.

```r
# `llaves` es la bateria de casos reales; `ruta_en_head` corre en subproceso
# sobre el HEAD anterior. La comparacion es cadena por cadena, no por conteo.
antes   <- vapply(llaves, ruta_en_head,  character(1))
despues <- vapply(llaves, ruta_en_arbol, character(1))
stopifnot(
  length(antes) == length(llaves),
  identical(antes, despues)
)
```

**2. Función protegida por invariante, comprobada por identidad y no por tamaño
del diff.**

```r
# `protegidas` son las funciones que el invariante prohibe tocar.
# deparse() compara el cuerpo real, no el diff del archivo.
for (fn in protegidas) {
  stopifnot(identical(deparse(get(fn, envir = env_head)),
                      deparse(get(fn, envir = env_arbol))))
}
```

Los patrones estables (fusible de red, cuadre contra la lista pedida, control
positivo de la propia consulta) siguen donde estaban.

## §14. Reapertura

Tipo: CONTINUATION. El protocolo (`POLITICA_PROYECTO.md` v5.6,
`SETTINGS_Y_PROMPTS_OPERACIONALES.md` v23) vive en la knowledge base del Project y
se lee desde ahí; verifica las versiones contra la knowledge base, no contra
ninguna otra fuente, antes de la Fase A.
Estado: la sesión 21 cerró P-66 completo. La entidad `proyecto` está publicada
con tramitación, 427 de 427 boletines resueltos por el SIL, y la entidad
parlamentario quedó intacta hasta el byte de su índice. Los PR #13, #14 y #15
están mergeados y `main` quedó en `cbc29b5` antes del commit de cierre.
No creas a este traspaso sobre `CORTE_FECHA`, sobre el hash de `main`, sobre el
universo (427 boletines, 4 800 trámites, 561 de 842 votaciones son del corte
2026-08-12) ni sobre ninguna cobertura: todas se remiden. Y no supongas que
recapturar el mismo corte del SIL devuelve el mismo contenido: no es append-only.
El foco propuesto es P-86: el paso 37 es desconocido para
`capturas_crudas_de_paso()` e `INTERMEDIOS_PIPELINE`, así que un
`tramitacion.rds` desalineado detiene la corrida con una instrucción de
recuperación equivocada, y el cron corre el lunes. Encadenados y baratos: P-88 y
P-87, ambos de calidad del dato recién publicado. Sigue encendido el gatillo 4bis
(ordenación, P-60), ahora por tercera sesión consecutiva.
El §15 trae seis errores registrados, los seis del asistente conversacional, y
cuatro de ellos son del encargo mismo: dos premisas afirmadas sin leer la fuente,
un invariante escrito más fuerte que la norma real, y una restricción de alcance
que terminó moviendo la procedencia de un dato publicado.
Documentos para la próxima sesión:

1. Protocolo en knowledge base (no se adjuntan; se listan para verificar que la
   knowledge base esté al día): `POLITICA_PROYECTO.md`,
   `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
2. Opcionales según el foco real: `CLAUDE.md` si la sesión correrá en Claude Code.
3. Específicos de la sesión: `traspaso_cierre_v21.md`;
   `30_procesamiento/37_extraer_tramitacion.R` (lo que P-86, P-87 y P-88 tocan);
   `50_documentacion/andamios/50_medicion_p66_acto_a.md` (la medición sobre la
   que se construyó todo lo publicado).

## §15. Errores del asistente

**Error 1.**

| Campo | Contenido |
|---|---|
| Momento | Redacción del encargo del acto A, contrato de INSUMOS y mandato del log |
| Disparador | Claude Code no encontró el archivo al ir a escribir la bitácora |
| Qué pasó | Cité `encargo_autonomo_claude_code_v1.md` §4 como plantilla del log sin verificar que existiera en el filesystem: vive en la knowledge base, no en el repositorio |
| Regla violada | El propio §1 del encargo: todo insumo con ruta verificada en ese entorno o incrustado, sin tercera opción. Es además el primer antipatrón que ese mismo documento nombra |
| Causa raíz | Confundí "documento que conozco" con "archivo accesible para el agente"; el documento estaba leído, pero en otro entorno |
| Salvaguarda presente | La regla existía y la escribí yo en el mismo documento que la incumplió |
| `gatillo_observable` | Un encargo que cita un documento por ruta sin que esa ruta aparezca en su propia lista de INSUMOS verificados |
| Detección | Claude Code lo reportó al llegar al entregable |
| Corrección | Se usó como plantilla de facto el log más reciente; el encargo del acto B ya lo declara así |
| `intentos_previos` | Ninguno para esta variante |
| `costo` | Nulo en cifras; una decisión de formato tomada por el agente |
| Impacto | Bajo |
| Patrón | PAT-01, variante "documento leído en otro entorno tratado como archivo accesible" |

**Error 2.**

| Campo | Contenido |
|---|---|
| Momento | Redacción del encargo del acto A, tabla de afirmaciones respaldadas, R4 |
| Disparador | La medición de G6 |
| Qué pasó | Declaré como respaldado que las cuatro métricas de compuerta se declaran en `10_diff_conteos.R:57`; la línea real es la 68 y en la 57 se abren las cinco que se cuentan |
| Regla violada | `userPreferences`, marcador de fuente tipo 1 y 4: el contenido de un archivo no leído es hipótesis, y una cita heredada de otro documento no es fuente |
| Causa raíz | Tomé la línea del veredicto del eje temático y la promoví de cita ajena a afirmación propia al pasarla a la tabla de respaldadas |
| Salvaguarda presente | La tabla §0.1 exige fuente por fila; puse una fuente que hablaba del hecho, no que lo verificara |
| `gatillo_observable` | Una fila de "afirmación respaldada" cuya fuente es otro documento y no una lectura del artefacto que describe |
| Detección | Claude Code lo corrigió en la ficha, con la precisión explícita |
| Corrección | La ficha del acto A lo deja escrito; el encargo del acto B ya cita ambas líneas |
| `intentos_previos` | Recurrente: misma familia que los errores 1 de v20 y de v18 |
| `costo` | Nulo |
| Impacto | Nulo: el número "cuatro" era correcto |
| Patrón | PAT-01, variante "cifra heredada promovida a afirmación propia" |

**Error 3.**

| Campo | Contenido |
|---|---|
| Momento | Redacción del encargo del acto B, §0.2 H1 contra §3 invariantes |
| Disparador | F0 de Claude Code |
| Qué pasó | El encargo pedía a la vez usar `con_cache()` sin modificarla y sacar el crudo del SIL de `20_insumos/camara/`, cosas incompatibles porque `ruta_cache()` fija el directorio. Además el 🔒 afirmaba que a `camara/` "no se le agrega nada", que el bot desmiente cada semana |
| Regla violada | SETTINGS §1.2.6: la fuente primaria de una estructura es su inspección. Escribí un invariante sobre una función sin leerla |
| Causa raíz | Redacté el invariante desde el principio general (crudo inmutable) sin contrastarlo contra la conducta real del sistema que lo implementa |
| Salvaguarda presente | La regla de detención por hipótesis falsa, que funcionó: costó cero escrituras y cero red |
| `gatillo_observable` | Un 🔒 que prohíbe una operación que el pipeline ya ejecuta de forma rutinaria |
| Detección | Claude Code, con las dos proposiciones enfrentadas en tabla |
| Corrección | Enmienda 1 del encargo: H1 reformulada, 🔒 reescrito, fase F0bis con retrocompatibilidad demostrada |
| `intentos_previos` | Ninguno para este patrón |
| `costo` | Un turno del titular; cero escrituras |
| Impacto | Nulo en el artefacto; la detención fue correcta y el resultado, mejor |
| Patrón | PAT-01, variante "invariante escrito más fuerte que la norma que protege" |

**Error 4.**

| Campo | Contenido |
|---|---|
| Momento | Mensaje de lanzamiento del acto B, nota de alcance |
| Disparador | Claude Code lo reportó al llegar a F3 |
| Qué pasó | Escribí "un helper insuficiente se reporta, no se extiende por analogía"; la restricción, pensada contra la deriva de arquitectura, hizo que `camara_origen` y `fecha_ingreso` se publicaran con procedencia del SIL en vez de la Cámara |
| Regla violada | Ninguna existente: es un hueco. La restricción de alcance no excluyó de su ámbito la procedencia de un dato publicado |
| Causa raíz | Redacté una restricción por su riesgo (deriva) sin recorrer sus efectos sobre el contenido del artefacto |
| Salvaguarda presente | Ninguna. El agente hizo lo correcto: reportó en vez de extender |
| `gatillo_observable` | Una restricción de alcance cuyo cumplimiento cambia de dónde sale un campo publicado |
| Detección | Claude Code lo declaró y ofreció la extensión como decisión del titular |
| Corrección | Queda como P-87 |
| `intentos_previos` | Ninguno |
| `costo` | Dos campos publicados con procedencia secundaria hasta que P-87 se resuelva |
| Impacto | Bajo pero real: afecta el dato, no solo el proceso |
| Patrón | Nuevo candidato: restricción de alcance con efecto sobre el contenido |

**Error 5.**

| Campo | Contenido |
|---|---|
| Momento | Mensaje de arranque tras el PR #13 |
| Disparador | Claude Code midió el remoto |
| Qué pasó | Escribí "El titular mergeó el PR #13. Verifica y sigue" cuando el merge no había ocurrido |
| Regla violada | `userPreferences`, marcador de fuente tipo 2: el estado del repositorio se afirma con el comando que lo produjo |
| Causa raíz | Traté una instrucción dada como un hecho consumado, sin marcarla como premisa a verificar |
| Salvaguarda presente | El paso 1 de mi propio mensaje pedía verificar, y eso salvó la corrida |
| `gatillo_observable` | Una afirmación sobre el remoto en un mensaje que a la vez ordena verificarla |
| Detección | Claude Code, que además descartó el `merge_commit_sha` especulativo |
| Corrección | El mensaje siguiente delegó el merge con autorización explícita |
| `intentos_previos` | Misma familia que el error 7 de esta tabla |
| `costo` | Un turno |
| Impacto | Bajo |
| Patrón | PAT-01 |

**Error 6.**

| Campo | Contenido |
|---|---|
| Momento | Tres veces: encargo del acto A, encargo del acto B, y la instrucción del `mv` |
| Disparador | La primera compuerta de cada encargo |
| Qué pasó | Entregué artefactos que llegaron sin trackear al repositorio y bloquearon G0 o la precondición 1; y en un caso ordené un `mv` cuya premisa (el archivo está en la raíz) era falsa, leída de una tabla en vez del disco |
| Regla violada | `userPreferences`, entrega materializada, y marcador de fuente tipo 1 para el `mv` |
| Causa raíz | El encargo se entrega como archivo pero su llegada al repositorio no forma parte del propio encargo, así que siempre queda como estado sucio en la primera compuerta |
| Salvaguarda presente | La compuerta de árbol limpio, que funcionó las tres veces |
| `gatillo_observable` | Un encargo cuya primera compuerta se detiene por el propio encargo |
| Detección | Claude Code, las tres veces |
| Corrección | Estructural, adoptada para el próximo encargo: el bloque de arranque del encargo incluye su propio commit, en vez de dejar la disposición como decisión repetida |
| `intentos_previos` | Dos, en esta misma sesión |
| `costo` | Tres turnos |
| Impacto | Bajo por vez, alto por acumulación |
| Patrón | PAT-04 (forma del entregable degrada su ejecución) |

### Desvíos del agente de ejecución (autorreportados)

Claude Code declaró tres, ninguno con efecto en las cifras: un uso de `awk`
sobre un fuente `.R`; un `grep` con escape en `Rscript -e` que abortó, exactamente
como la regla anticipa; y `gh --jq` antes de G0, sustituido por
`gh api > archivo.json` más `jsonlite::fromJSON()` al notarlo. También corrigió,
por iniciativa propia, un hash que había escrito de memoria en su bitácora.

### Fricciones

friccion: cuatro turnos de la sesión se gastaron verificando merges contra un
remoto que estaba cuatro commits atrás, porque el cierre de la sesión 20 nunca se
pusheó → el push del cierre pasa a verificarse en la apertura, no en el cierre
siguiente.
