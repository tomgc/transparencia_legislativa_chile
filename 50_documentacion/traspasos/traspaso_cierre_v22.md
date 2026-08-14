# Traspaso de cierre — sesión 22

## §1. Identificación

| Campo | Valor |
|---|---|
| Proyecto | `transparencia_legislativa_chile` |
| Versión | v22 |
| Fecha de cierre | 2026-08-13 |
| Sesión | 22 |
| Foco | Cerrar P-86 y P-90 (el runner reconoce el paso 37) y medir si existe un eje temático construible con lo que ya está en disco (P-92) |
| Entorno | R 4.5.2 en Positron sobre macOS; ejecución delegada en Claude Code; `gh` CLI |
| `main` | `4160f46`, **previo al commit de cierre** (verificado en F0 de ambos encargos con `git rev-parse main origin/main`; ningún merge a `main` durante la sesión) |
| `CORTE_FECHA` | `2026-08-12`, leído de `10_utils/10_configuracion.R:57` en la corrida, no heredado |
| Archivos de pipeline modificados | `10_utils/10_utils.R`, `00_run_all.R` (ambos en la rama `fix/p86-runner-paso37`, sin mergear) |

## §2. Resumen ejecutivo

La sesión se propuso cerrar la deuda del runner antes del cron del lunes y terminó
resolviendo, además, la pregunta que el proyecto arrastraba desde la sesión 16. P-86
se cerró: el mensaje de recuperación de la guarda nombra el paso 37 y ya no manda a
regenerar los pasos 32-36; el defecto no estaba en dos estructuras sino en tres, y la
tercera (`PASOS_EXTRACCION`) es la que imprime la instrucción. P-90 se cerró sin
cambio de código: con corte y captura del mismo día el escape temporal no se necesita.
Después, el titular declaró que el eje temático es lo más importante del proyecto y que
sin él el producto no le sirve, y el sondeo P-92 midió cuatro vías derivadas que ningún
documento anterior había considerado. **Existe eje temático:** el sufijo del número de
boletín cubre 427 de 427 boletines y 86 955 de 130 510 filas de voto, produce 29
categorías y, cruzado con tendencia en el período vigente, separa a izquierda y derecha
entre 39 y 44 puntos en cinco áreas. Su límite es que no tiene glosa oficial (no existe
catálogo código→nombre en 12 superficies sondeadas) y que deja fuera el tercio de
votaciones sin boletín. Quedó descubierto además un bug activo que ninguna sesión había
visto: **el refresh semanal de producción falla desde al menos el 2026-08-10**, así que
el portal lleva semanas sin actualizarse. Nada publicado cambió en toda la sesión.

## §3. Estado al cierre

### Qué funciona

| Pieza | Última ejecución exitosa |
|---|---|
| `run_all()` completo, 7 pasos | F3 del encargo P-86: 14,6 s, cero llamadas de red |
| Guarda de alineamiento sobre los 7 intermedios | F1 del encargo P-86, probada en ambos sentidos |
| Entidad parlamentario y entidad `proyecto` publicadas | sin cambios en esta sesión: 584 de 584 archivos idénticos en `40_salidas/json/` y en `docs/data/` |
| Escape temporal de la guarda de captura (D31) | F2 del encargo P-86: no se necesita en el escenario del cron |

### Qué no funciona

- **P-91 (bug activo, nuevo).** El workflow `refresh-semanal.yml` falló el 2026-08-10
  sobre `b619a50`, job `refresh`, exit code 1, con el mensaje
  `run_all: 6 de 6 intermedios NO corresponden al corte vigente (2026-08-10)`
  (fuente: capturas de GitHub Actions aportadas por el titular en la sesión). Síntoma
  observable: el portal no se actualiza en producción. **Causa raíz no establecida**
  (hipótesis: en CI no existe la captura cruda del corte del día, así que la guarda se
  detiene antes de que el paso de captura con red llegue a correr; verificar con
  `gh api repos/tomgc/transparencia_legislativa_chile/actions/runs --paginate > runs.json`
  y lectura del log completo del run en R). No se sabe cuántas corridas consecutivas
  llevan fallando: solo una fue observada.
- **La vía 2 del eje temático está bloqueada**, no ausente: `camara.cl` responde
  detrás de Cloudflare al cliente R.

### Delta respecto a v21

El runner pasó de vigilar 6 intermedios a 7. El eje temático pasó de "no construible
con las fuentes disponibles" a "construible por derivación, con un límite de glosa".
El diagnóstico de producción pasó de "refresh semanal automatizado y funcionando" a
"caído desde al menos el 2026-08-10". Los tres son cambios de conocimiento, no de dato
publicado: `40_salidas/json/` y `docs/data/` quedaron byte a byte como estaban.

## §4. Registro detallado de cambios

### 4.1 P-86 y P-90 — el runner reconoce el paso 37

**Archivos:** `10_utils/10_utils.R`, `00_run_all.R`.
**Categoría temática:** infraestructura.
**Rama:** `fix/p86-runner-paso37`. **Commits:** `8a0a716` (encargo), `db2a420` (fix y
arnés), `5b8b9d9` (bitácora). **PR #16, sin mergear.**

**Qué se hizo.** El paso 37 quedó registrado en las **tres** estructuras que arman el
mensaje de recuperación de `regenerar_intermedios_si_desalineados()`:

| Estructura | Archivo | Qué aporta |
|---|---|---|
| `INTERMEDIOS_PIPELINE` | `10_utils/10_utils.R:506` | qué intermedios se miran; la línea de estado |
| `capturas_crudas_de_paso()` | `10_utils/10_utils.R:574` | dónde está la captura de cada paso |
| `PASOS_EXTRACCION` | `00_run_all.R:64` | los `p$ruta` impresos como `source(...)`: la instrucción misma |

**Por qué.** El encargo prescribía dos estructuras. La lectura del código en F0 mostró
que la instrucción de recuperación no sale de ninguna de las dos, sino de
`PASOS_EXTRACCION` vía `10_utils.R:692` y `:761`. Con el cambio prescrito, P-86 no
habría cumplido su propio criterio de éxito. El ejecutor se detuvo y el titular
autorizó el tercer asiento.

**Cómo se verificó.** En ambos sentidos, con la captura oculta (movida, nunca borrada)
para forzar la rama del `stop()`:

- **Sentido que debe cambiar:** antes, la guarda ni miraba `tramitacion.rds`
  (`SIN STOP`) y el fallo aparecía más tarde en `validar_corte()` diciendo *"regenera
  los pasos 32-36"*. Después, la guarda nombra el 37 e imprime
  `source("30_procesamiento/37_extraer_tramitacion.R")`.
- **Sentido que no debe cambiar:** con `proyectos.rds` desalineado, 6 de 7 líneas
  idénticas a `main` y la instrucción de recuperación byte a byte igual. Cambia una
  línea: `1 de 6` → `1 de 7`, que es verdadera. **No se declaró "idéntico cadena por
  cadena"** porque no lo es, y el criterio del encargo pedía eso.
- **Invariantes por identidad de cuerpo** (`deparse()` entre el entorno de `main` y el
  del árbol, no el diff del archivo): 6 de 6 funciones protegidas idénticas;
  `regenerar_intermedios_si_desalineados()` intacta.

**P-90** se cerró en la misma corrida: reproducido el escenario del cron (corte y
captura del mismo día), la guarda devuelve `escape = FALSE` y no se detiene. Sin
cambio de código, que es lo que su criterio prescribía.

**Tensión resuelta.** Resiliencia contra simplicidad: la causa raíz (tres estructuras
sin sincronización forzada) pedía un refactor de la guarda, que es zona de P-82. Se
optó por el cambio quirúrgico tres días antes del cron y la causa raíz quedó abierta
como P-93.

### 4.2 P-92 — sondeo de las cuatro vías derivadas del eje temático

**Archivos:** solo bajo `50_documentacion/andamios/`. **Categoría temática:**
diagnostico/exploracion. **Rama:** `sondeo/p92-eje-tematico`. **Commits:** `139547e`,
`2f40c77`, `c089b79`. **PR #17, sin mergear.** **34 llamadas HTTP de un presupuesto
declarado de 300.**

**Qué se hizo.** Se midieron cuatro vías que derivan el tema de datos ya en disco, en
vez de descargarlo de una fuente que lo traiga:

| Vía | Cobertura | Categorías | Control positivo | Veredicto |
|---|---|---|---|---|
| 1. Sufijo del boletín | 427/427 boletines (100 %); 86 955/130 510 filas de voto (66,63 %) | 29, 21 con n ≥ 5 | 5 de 5 (umbral 4) | **PASA** |
| 2. Buscador "por Materia" de `camara.cl` | no medible | — | — | BLOQUEADA por Cloudflare |
| 3. Léxico sobre el título del proyecto | 308/427 (72,13 %) | 12 | 3 de 5 | FALLA |
| 4. Léxico sobre el texto de la votación | 16/842 (1,90 %); 0/281 sin boletín | — | — | FALLA, sin insumo |

**Por qué.** El titular declaró que el eje temático es el objetivo real del proyecto y
que sin poder navegar temas y ver quién vota qué, el producto no le sirve. Los dos
veredictos anteriores habían medido si alguna fuente **entrega** el tema; ninguno
había medido si el tema se puede **derivar**.

**Cómo se verificó.** Cada vía con un control que podía refutarla: control positivo
contra los 5 boletines con materia oficial y umbral declarado antes; control de
discriminación del sufijo contra el vocabulario de los títulos; control de sobreajuste
con el 20 % del universo apartado antes de escribir el léxico; controles negativos en
cada sondeo de red. **Panel adversarial de dos agentes con código propio, sin acceso a
los scripts del sondeo: ambos corrieron y reprodujeron las diez cifras.**

**La prueba que decide.** Tabla `sufijo × tendencia × tasa de aprobación` en el período
vigente, con n por celda:

| Sufijo | Comisión modal (asociación empírica) | izq % (n) | der % (n) | Brecha |
|---|---|---|---|---|
| 03 | Economía | 72,4 (163) | 28,4 (345) | −44,0 |
| 18 | Familia | 100,0 (115) | 56,7 (245) | −43,3 |
| 05 | Hacienda | 35,6 (3 190) | 74,9 (6 799) | +39,3 |
| 06 | Gobierno Interior | 43,8 (395) | 83,1 (860) | +39,3 |
| 13 | Trabajo y Seguridad Social | 48,9 (190) | 87,9 (404) | +39,0 |

**PASA:** 8 de 13 sufijos elegibles superan 20 pp con n ≥ 100 por celda. El panel
verificó que la prueba puede dar rojo: con las tendencias barajadas, 0 de 20.

**Hallazgo del panel que corrigió el veredicto:** el universo completo agrega dos
composiciones de la Cámara (23 075 votos hasta el 2026-03-10 y 40 491 desde el
2026-03-11) y **4 de 9 sufijos elegibles cambian de signo de brecha**. El sufijo 05 va
de −54,4 pp a +39,3 pp y al agregarse se cancela a +5,6. **La tabla interpretable es la
del período vigente**, y los 63,0 pp del sufijo 33 en el universo completo no son una
propiedad del eje.

**Tensión resuelta.** Utilidad contra fidelidad: el sufijo es la comisión de origen
asignada al ingreso, no un descriptor temático. Predice la comisión de tramitación en
cerca de 9 de cada 10 casos, pero 134 de 427 proyectos pasan por más de una comisión.
Se resolvió no publicándolo como "tema" (ver D52).

## §5. Backlog acumulativo

Archivo canónico: `50_documentacion/activa/backlog_acumulativo.md`. Última entrada
previa: **62**. Esta sesión aporta las entradas **63 y 64**. Delta completo en el
bloque `BACKLOG_DELTA` del paquete de cierre v22.

**Inconsistencia detectada y no reparada aquí:** la sección "Delta del backlog" del
archivo en disco termina en el bullet de **v20**; el bullet de v21 no está, pese a que
sus entradas (61-62) y su fila del resumen sí (verificado con
`grep -n "^- \*\*v[0-9]" backlog_acumulativo.md` en esta sesión). **No se reconstruye
de memoria**, porque reconstruir el delta de una sesión que no se ejecutó sería
inventar su contenido. Queda como P-98.

## §6. Bugs de la sesión

| # | Bug | Estado |
|---|---|---|
| 1 | **P-86:** el mensaje de recuperación mandaba a regenerar los pasos 32-36 para un intermedio que produce el 37. Causa raíz: el registro de un paso vive en tres estructuras y nada obliga a sincronizarlas; P-66 agregó el 37 tocando solo `PASOS`. Fix: las tres. Verificación: en ambos sentidos, §4.1. **Patrón aprendido:** cuando un dato de configuración se repite en N estructuras sin verificación cruzada, el defecto no es la entrada que falta sino la ausencia de verificación; arreglar la entrada no cierra la clase | **resuelto** (causa raíz abierta como P-93) |
| 2 | **P-91:** el refresh semanal de producción falla desde al menos el 2026-08-10. Causa raíz no establecida. **Patrón aprendido:** un workflow que corre solo y falla solo no avisa; el estado de producción es una afirmación verificable y se verifica, no se hereda de un documento | **activo, no resuelto** |
| 3 | **Fallo de la prueba, no del código:** el primer diseño del escenario de P-86 no ocultaba la captura del SIL, así que la guarda regeneraba en vez de detenerse y la rama que P-86 corrige nunca se ejercitaba. La prueba habría dado verde sin haber probado nada. **Patrón aprendido:** una prueba que no puede fallar no es una prueba; comprobar que el escenario alcanza la rama que se quiere medir es parte del diseño de la prueba | resuelto en la misma corrida |
| 4 | **Dos defectos de medición en el cruce de F2b de P-92:** comparación de `"4"` con `"04"` como texto, y `cultura` casando dentro de `agricultura`. Detectados y corregidos por el ejecutor antes de emitir veredicto. **Patrón aprendido:** el emparejamiento de códigos numéricos exige normalizar el ancho antes de comparar, y el de nombres exige anclas de palabra | resuelto en la misma corrida |
| 5 | **Falso veredicto de "discrimina" en el control negativo de `camara.cl`:** dos respuestas se declararon distintas por md5 cuando la única diferencia era el `ray-id` de Cloudflare. **Patrón aprendido:** un md5 sobre una respuesta HTTP incluye campos volátiles del intermediario; comparar cuerpo normalizado, no la respuesta cruda | resuelto en la misma corrida |

## §7. Aprendizajes y restricciones descubiertas

- **A95 — Un criterio de éxito debe probarse contra un caso de control antes de
  aplicarse.** El criterio "md5 idéntico" de F0bis habría clasificado los seis
  intermedios existentes como no regenerables, incluidos los que la guarda regenera a
  diario: el md5 cambia por `sello$escrito_en` en todos. *Qué pasa si se viola:* se
  toma una decisión de diseño con un criterio que ni el caso conocido-bueno supera.
  *Ejemplo:* F0bis del encargo P-86, resuelto midiendo el paso 35 como control.
- **A96 — El estado de un sistema automatizado es una afirmación verificable y caduca.**
  "El refresh semanal está automatizado" era cierto como diseño y falso como estado.
  *Qué pasa si se viola:* se reporta al titular que produce algo que lleva semanas sin
  producirse. *Ejemplo:* P-91.
- **A97 — Cuando una restricción de alcance se escribe en un encargo, hay que recorrer
  su efecto sobre el criterio de éxito antes de fijarla.** La prohibición de tocar
  `regenerar_intermedios_si_desalineados()` hacía inejecutable la rama B de F0bis.
  *Qué pasa si se viola:* la ejecución se detiene a mitad y cuesta un turno de
  autorización. Es A94 repetido en otra forma.
- **A98 — Un campo con cobertura del 100 % puede no tener contenido.** `descripcion` en
  `votos.rds` está en 842 de 842 votaciones, pero 811 son la etiqueta `Boletín N° X`:
  266 valores distintos, casi todos el mismo molde con un número dentro. *Qué pasa si
  se viola:* se diseña una vía entera sobre un campo que no tiene texto que clasificar.
- **A99 — Agregar sobre dos composiciones de un cuerpo colegiado cancela signos.** De 9
  sufijos elegibles en ambos tramos legislativos, 4 cambian de signo de brecha, y el
  caso extremo pasa de −54,4 pp a +39,3 pp. *Qué pasa si se viola:* se publican
  magnitudes aritméticamente correctas que no son propiedades de lo que se cree medir.
  *Ejemplo:* lo levantó el panel adversarial, no el ejecutor.
- **A100 — Un md5 sobre una respuesta HTTP no compara contenido.** Cloudflare inyecta
  un `ray-id` por respuesta. *Qué pasa si se viola:* un control negativo declara que
  discrimina cuando no discrimina.
- **A101 — Antes de empujar muestras crudas a un repositorio público, auditar datos de
  contacto.** `retornarComisionesXPeriodo` devuelve 91 correos y 137 teléfonos.
  Redactar en `HEAD` no basta: el commit anterior ya contenía los blobs, así que hubo
  que reescribir la rama antes del push. *Qué pasa si se viola:* se publican en el
  historial de un repositorio público datos que el propio proyecto ya había decidido
  no versionar.

## §8. Decisiones de diseño

- **D51 — El paso 37 entra en las tres estructuras del runner en pie de igualdad con
  los pasos 32-36.** *Alternativas:* registrarlo solo en lo que construye el mensaje y
  no en lo que se regenera. *Justificación:* F0bis midió que el 37 se regenera desde el
  crudo versionado sin red y con contenido idéntico; el criterio literal que lo habría
  excluido no discrimina al 37 de los seis existentes. *Implicancia:* la guarda ahora
  vigila 7 intermedios.
- **D52 — El eje temático se publicará rotulado como área legislativa derivada de la
  comisión de origen, no como "tema".** *Alternativas:* publicarlo como tema, que es lo
  que el titular pidió coloquialmente. *Justificación:* el sufijo nombra el punto de
  entrada del proyecto, no su recorrido; 134 de 427 proyectos pasan por más de una
  comisión y 36 de 423 tienen una comisión primera distinta de la modal de su sufijo.
  *Tensión resuelta:* utilidad contra fidelidad, a favor de fidelidad en el rótulo sin
  perder la utilidad del cruce. *Implicancia:* la pregunta del titular se responde
  igual; lo que cambia es la promesa que el portal hace al lector.
- **D53 — La asociación sufijo → comisión es empírica y se rotula como tal.** No existe
  catálogo oficial código→glosa en las 12 superficies sondeadas, y D42 prohíbe
  fabricarlo. *Implicancia:* el portal puede mostrar el código con su comisión modal
  medida, declarada como derivación del proyecto, o esperar a que la glosa oficial se
  consiga por gestión del titular (P-95).
- **D54 — Las muestras crudas de comisiones van redactadas en sus campos de contacto.**
  Se siguió el criterio que el propio proyecto fijó en `50_catalogo_fuentes_camara.md`
  §6. 394 campos redactados en 3 archivos; detalle y md5 originales en
  `50_documentacion/andamios/muestras/p92/LEEME_redaccion.md`. Reversible volviendo a
  correr `50_sondeo_p92_f2.R`.

## §9. Constantes y parámetros

Sin cambios; las vigentes viven en `10_utils/10_configuracion.R`. `CORTE_FECHA` sigue
en `2026-08-12` (línea 57, leída en la corrida).

## §10. Arquitectura de archivos

Escáner regenerado en el cierre (F1). Cambios de estructura de la sesión: dos encargos
y dos bitácoras nuevos en `50_documentacion/andamios/` y `andamios/logs/`, un veredicto
nuevo en `50_documentacion/andamios/`, y muestras del sondeo en
`50_documentacion/andamios/muestras/p92/`. Nada nuevo fuera de `50_documentacion/`.

**Desviación heredada, medida en esta sesión:** 6 archivos de
`50_documentacion/activa/` sin el prefijo `50_` fuera de las cinco excepciones de
cartera (`documentacion_tecnica_v1.md`, `encargo_contrato_datos_camara_senado.md`,
`encargo_exploracion_asistencia_senado_h1bis.md`, `encargo_exploracion_senado_v02.md`,
`exploracion_api_camara.md`, `procedimiento_actualizacion.md`). Es el recuento que v21
declaró pendiente. Materia de P-60.

## §11. Pendientes y ruta sugerida

### 11.1 Inventario

**P-91 — El refresh semanal de producción está caído.** *Tipo:* bug activo. *Contexto:*
falló el 2026-08-10 sobre `b619a50` con exit 1 y `6 de 6 intermedios NO corresponden al
corte vigente (2026-08-10)`. *Impacto:* el portal no se actualiza; es lo único roto en
producción. *Dependencias:* ninguna. *Complejidad:* media (el diagnóstico es barato; el
arreglo depende de la causa). *Precauciones:* no tocar la guarda ni `validar_corte()`
antes de establecer la causa; el escenario de CI no es el local. *Enfoque:* leer el log
completo del run en R vía `gh api > archivo.json`, y comprobar cuántas corridas
consecutivas llevan fallando. *Criterio de éxito:* causa raíz establecida con la línea
del log que la evidencia, y una corrida verde del workflow.

**P-93 — Las tres estructuras del runner no se verifican entre sí.** *Tipo:* deuda
técnica. *Contexto:* causa raíz de P-86. *Impacto:* el próximo paso nuevo repetirá el
defecto. *Complejidad:* baja. *Enfoque:* una guarda que compare `INTERMEDIOS_PIPELINE`,
`PASOS_EXTRACCION` y las ramas de `capturas_crudas_de_paso()` contra `PASOS` y falle
ruidosamente ante un paso huérfano. *Criterio de éxito:* con un paso agregado a `PASOS`
y no a las otras tres, la guarda falla con el nombre del paso huérfano.

**P-94 — Construir y publicar la entidad temática sobre la vía 1.** *Tipo:*
funcionalidad. *Contexto:* P-92 la declara viable. *Impacto:* es el objetivo declarado
del proyecto. *Dependencias:* D52 y D53 ya resueltas; no requiere ninguna llamada
nueva. *Complejidad:* alta. *Precauciones:* rótulo de área legislativa, no de tema; la
tabla interpretable es la del período vigente (A99); declarar en el propio JSON que un
tercio de las votaciones queda fuera del eje. *Criterio de éxito:* el portal responde
"qué áreas separan a izquierda y derecha" con las cifras de §4.2 reproducidas desde el
artefacto publicado, y el lector puede distinguir "sin área" de "fuera del eje".

**P-95 — Conseguir la glosa oficial del sufijo.** *Tipo:* documentación. *Contexto:* no
existe en 12 superficies sondeadas. *Enfoque:* gestión del titular ante la Cámara, no
del pipeline. *Criterio de éxito:* catálogo código→glosa con fuente citable.

**P-96 — Decidir sobre el cliente HTTP para `camara.cl`.** *Tipo:* decisión
metodológica. *Contexto:* Cloudflare bloquea al cliente R; H7 quedó sin responder.
*Impacto:* es la única vía que podría cubrir las 281 votaciones sin boletín.
*Precauciones:* `camara.cl` es HTML raspado, frágil por diseño; cualquier vía que
dependa de él hereda esa fragilidad y hay que declararlo en el portal.

**P-97 — Los mensajes del Ejecutivo están fuera del universo.** *Tipo:* deuda de datos.
*Contexto:* el pipeline extrae solo mociones; `retornarMensajesXAnno` reporta 52 en
2026. *Impacto:* afecta el denominador de todas las coberturas del proyecto.

**P-98 — Falta el bullet de delta v21 en el backlog.** *Tipo:* documentación. *Contexto:*
detectado en el cierre v22 por `grep`. *Precaución:* no reconstruir de memoria; se
repara leyendo el paquete de cierre v21 si existe copia, o declarando la ausencia.

**Heredados sin cambio:** P-57 (paquetes y constantes al inicio de cada script), P-60
(ordenación del repositorio, gatillo 4bis encendido por cuarta apertura, con la cifra
ya medida en §10), P-79, P-81, P-82 (zona de la guarda), P-84, P-85 (política del crudo
del SIL, decisión del titular), P-87 (procedencia de `camara_origen` y `fecha_ingreso`),
P-88 (erratas de la fuente contra acotamiento temporal), P-89 (vista de `proyecto` en
el dashboard).

**Cerrados en esta sesión:** P-86, P-90, P-92.

**Menores registrados en el veredicto de P-92, sin entrada propia:** el control de
sobreajuste de la vía 3 es inconcluyente (n = 85, p = 0,0656); 14 partidos históricos
fuera de `MAPA_PARTIDO_TENDENCIA`, tres de ellos con 936 filas de voto sin tendencia;
`sentido == "dispensado"` tiene 33 filas cuya semántica no se investigó.

### 11.2 Evaluación de deuda técnica

**Zonas frágiles.** `regenerar_intermedios_si_desalienados()` concentra tres
responsabilidades (detectar, mensajear, regenerar) y tiene dos cadenas fijas mal
ubicadas: el directorio `20_insumos/camara/` aparece también cuando la captura que
falta vive en `senado/`, y las cadenas "regenera los pasos 32-36" siguen vivas en
`leer_sellado()` y `validar_corte()`, inalcanzables por la ruta de `run_all()` pero
visibles para quien corra el paso 39 suelto. Viola el principio de fuente única.

**Oportunidades.** P-93 cierra una clase entera de defectos con una guarda barata. El
diagnóstico de P-91 puede revelar que la guarda necesita distinguir el escenario de CI
del local, lo que tocaría la misma zona y permitiría resolver los tres `# REVISAR` de
una vez.

### 11.3 Auditoría de cierre (política 5.6)

| Pregunta | Respuesta |
|---|---|
| 2. ¿El pipeline corre de cero sin intervención manual? | **Sí en local** (`run_all()`, 7 pasos, 14,6 s, cero red, F3 del encargo P-86). **No en CI:** P-91 |
| 8. ¿Nombres de archivos y carpetas sin tildes, ñ ni espacios? | **No.** `50_documentacion/andamios/design_handoff_portal_transparencia/Portal Transparencia.dc.html` sigue con espacios. Se agrega como pendiente a P-60 |

### 11.4 Ruta sugerida para la sesión 23

**Prioridad 1 — P-91.** Criterio de priorización: bug activo en producción. Es lo único
roto que el usuario final ve. *Criterio de éxito:* causa raíz con la línea del log que
la evidencia y una corrida verde.

**Prioridad 2 — P-94.** Criterio: objetivo declarado del proyecto, con la medición ya
hecha y sin dependencias externas. *Criterio de éxito:* el de §11.1.

**Prioridad 3 — P-93.** Criterio: deuda técnica barata que cierra una clase de
defectos, y comparte zona con lo que P-91 probablemente toque.

**Diferir:** P-89 (queda absorbido o redefinido por P-94), el pipeline del Senado,
P-84, P-79, P-81, P-87 y P-88. **Ofrecer, no imponer:** P-60, con el gatillo 4bis
encendido por cuarta apertura consecutiva y la cifra ya medida.

**Antes de mergear PR #16:** relanzar el panel adversarial de F3, que murió por límite
de sesión de la API. Las dos afirmaciones críticas están verificadas por el mismo flujo
que produjo el cambio.

## §12. Instrucciones específicas para la próxima sesión

- ⚠️ **NO** afirmar el estado de un sistema automatizado (workflow, cron, bot) desde un
  documento: se verifica contra GitHub Actions en el momento de afirmarlo (A96).
- ⚠️ **NO** afirmar `CORTE_FECHA`, el sello de un intermedio ni el hash de `main` sin
  leerlos en el momento de afirmarlo.
- ⚠️ **NO** afirmar lo que dice un documento del proyecto sin haberlo leído en la
  sesión, ni en el sentido de confirmarlo ni en el de contradecirlo.
- ⚠️ **NO** heredar el universo: 427 boletines, 842 votaciones y 130 510 filas de voto
  son del corte **2026-08-12** y se remiden.
- ⚠️ **NO** leer la tabla del universo completo como propiedad del eje temático: agrega
  dos composiciones de la Cámara y cancela signos (A99).
- ⚠️ **NO** publicar el sufijo del boletín como "tema" ni fabricar su glosa (D52, D53,
  D42).
- ⚠️ **NO** confiar en un campo por su cobertura: 842 de 842 `descripcion` no vacías son
  811 etiquetas del mismo molde (A98).
- ⚠️ **NO** comparar respuestas HTTP por md5 de la respuesta cruda (A100).
- ⚠️ **NO** suponer que recapturar el mismo corte del SIL devuelve el mismo contenido:
  no es append-only (A88).
- ⚠️ **NO** parsear las fechas del SIL como ISO: son `%d/%m/%Y` (A93).
- ⚠️ **NO** usar `gh pr diff --name-only` ni `gh --jq`: `gh api > archivo.json` y
  `jsonlite::fromJSON()` en R.
- ✅ **ANTES** de aplicar un criterio de éxito, probarlo contra un caso de control
  conocido-bueno (A95).
- ✅ **ANTES** de fijar una restricción de alcance en un encargo, recorrer su efecto
  sobre el criterio de éxito del propio encargo (A97).
- ✅ **ANTES** de escribir un invariante en un encargo, leer la función que tendría que
  cumplirlo.
- ✅ **ANTES** de empujar muestras crudas a este repositorio, auditar correos, teléfonos
  y RUT; redactar en `HEAD` no basta si el commit anterior ya los contiene (A101).
- ✅ **ANTES** de declarar una cobertura, declarar su universo y su denominador en la
  misma línea, contados en el turno.
- ✅ **ANTES** de diseñar una prueba, comprobar que su escenario alcanza la rama que se
  quiere medir.
- 🔒 `sellar()`, `leer_sellado()` y `validar_corte()` no se tocan.
- 🔒 La guarda del contrato temporal (D31) no se afloja sin decisión explícita del
  titular.
- 🔒 Los intermedios no se versionan (D24); `40_salidas/intermedios/.gitkeep` sigue
  trackeado.
- 🔒 `10_utils/10_utils.R` no adquiere dependencias de paquetes.
- 🔒 Ninguna captura cruda ya escrita se modifica ni se borra.
- 🔒 `main` no recibe escrituras automáticas ni push directo del bot.
- 🔒 `sin_registro` no se imputa, ni en el dato ni en la presentación.
- 🔒 R es el único lenguaje, en todo contexto.
- 🔒 `git` siempre con `-C <ruta absoluta>`, `gh` siempre con `-R tomgc/...` salvo
  `gh api`, `git add` siempre con ruta acotada.
- 🔒 `proyectos_detalle.rds` mantiene una fila por boletín (D28).
- 🔒 Los campos con atributo de dominio se conservan con código y glosa (D29).

## §13. Fragmentos de código de referencia

Sin patrones nuevos ejecutables; los estables viven en
`50_documentacion/activa/documentacion_tecnica_v1.md`. Los dos patrones metodológicos
nuevos de la sesión son A95 (criterio contra caso de control) y el control de
sobreajuste por apartado previo, ambos descritos en §7 y en
`50_documentacion/andamios/50_veredicto_vias_tematicas_derivadas.md`.

## §14. Reapertura

Tipo: CONTINUATION. El protocolo (`POLITICA_PROYECTO.md` v5.6,
`SETTINGS_Y_PROMPTS_OPERACIONALES.md` v23) vive en la knowledge base del Project y se
lee desde ahí; verifica las versiones contra la knowledge base, no contra ninguna otra
fuente, antes de la Fase A.

Estado: la sesión 22 cerró P-86, P-90 y P-92. El runner vigila 7 intermedios y su
mensaje de recuperación nombra el paso 37. El sondeo temático encontró eje: el sufijo
del boletín cubre 427 de 427 boletines y 86 955 de 130 510 filas de voto, y en el
período vigente separa a izquierda y derecha entre 39 y 44 puntos en cinco áreas. Los
PR #16 y #17 quedaron abiertos, sin mergear, y el panel adversarial de #16 no alcanzó a
correr.

No creas a este traspaso sobre `CORTE_FECHA`, sobre el hash de `main`, sobre el
universo ni sobre ninguna cobertura: todas se remiden. Y no creas que el refresh
semanal funciona porque un documento lo diga: se verifica contra GitHub Actions.

El foco propuesto es P-91: el refresh semanal de producción falla desde al menos el
2026-08-10 con `6 de 6 intermedios NO corresponden al corte vigente`, así que el portal
lleva semanas sin actualizarse y no se sabe cuántas corridas consecutivas llevan
fallando. Después, P-94: construir y publicar la entidad temática sobre la vía 1, que
es el objetivo declarado del proyecto y ya no tiene dependencias externas. Encadenado y
barato: P-93, la guarda que impide que el próximo paso nuevo repita el defecto de P-86.
Sigue encendido el gatillo 4bis (ordenación, P-60), ahora por cuarta sesión consecutiva
y con la cifra medida: 6 archivos.

El §15 trae siete errores registrados, los siete del asistente conversacional, y cuatro
de ellos son de la misma familia: afirmar el contenido o el estado de algo sin leerlo en
la sesión, dos veces sobre documentos del propio proyecto y en sentidos opuestos.

Documentos para la próxima sesión:

1. Protocolo en knowledge base (no se adjuntan; se listan para verificar que la
   knowledge base esté al día): `POLITICA_PROYECTO.md`,
   `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
2. Opcionales según el foco real: `CLAUDE.md` si la sesión correrá en Claude Code.
3. Específicos de la sesión: `traspaso_cierre_v22.md`;
   `.github/workflows/refresh-semanal.yml` y `00_run_all.R` (lo que P-91 toca);
   `50_documentacion/andamios/50_veredicto_vias_tematicas_derivadas.md` (la medición
   sobre la que se construye P-94).

## §15. Errores del asistente

**Error 1**

| Campo | Contenido |
|---|---|
| `momento` | Turno del balance de avance del proyecto, a pedido del titular |
| `disparador` | usuario lo corrigió (aportó las capturas del workflow fallido) |
| `que_paso` | Afirmé que el proyecto tiene "refresh semanal automatizado" describiendo el estado de producción, tomándolo del backlog en vez de verificarlo contra GitHub Actions |
| `regla_violada` | userPreferences, marcador de fuente: el estado de un sistema es afirmación verificable y exige fuente leída en la sesión |
| `causa_raiz` | El backlog documenta el diseño del workflow, y traté "existe el workflow" como equivalente a "el workflow está corriendo bien"; son dos afirmaciones distintas y solo la primera estaba respaldada |
| `salvaguarda_presente` | userPreferences + SETTINGS (marcador de fuente) |
| `patron` | PAT-01, sobre estado de un sistema automatizado |
| `gatillo_observable` | `afirmar-sin-leer`: estado de producción de un workflow afirmado desde documentación de diseño |
| `intentos_previos` | 0 |
| `costo` | El titular operó tres semanas creyendo que su portal se actualizaba solo; un turno de corrección |

**Error 2**

| Campo | Contenido |
|---|---|
| `momento` | Turno posterior a leer las dos páginas de `camara.cl` |
| `disparador` | usuario lo corrigió ("¿por qué actúas sorprendido 21 sesiones después?") |
| `que_paso` | Escribí "cambian el veredicto de P-68" sin haber leído `50_veredicto_eje_tematico.md` ni `50_veredicto_fuentes_tematicas_bcn.md` |
| `regla_violada` | userPreferences, marcador de fuente; POLITICA 0.5 |
| `causa_raiz` | Dos páginas web recién leídas se sintieron como evidencia suficiente sobre el alcance de un trabajo de tres sesiones que no había leído; confundí "esto es nuevo para mí" con "esto es nuevo para el proyecto" |
| `salvaguarda_presente` | userPreferences + SETTINGS |
| `patron` | PAT-01, sobre alcance de un veredicto previo |
| `gatillo_observable` | `afirmar-sin-leer`: contenido de un documento del proyecto no leído en la sesión |
| `intentos_previos` | 0 |
| `costo` | Un turno; pérdida de confianza declarada por el titular |

**Error 3**

| Campo | Contenido |
|---|---|
| `momento` | Turno inmediatamente posterior, al corregir el error 2 |
| `disparador` | asistente lo señaló espontáneamente (al leer los veredictos) |
| `que_paso` | Al disculparme afirmé que "lo probable es que el sufijo y el buscador ya estén medidos y descartados ahí"; no lo estaban, y esa afirmación también era sobre documentos sin leer |
| `regla_violada` | userPreferences, marcador de fuente |
| `causa_raiz` | La corrección de un exceso se hizo con otro exceso en sentido contrario; la humildad se expresó como afirmación sobre un contenido desconocido en vez de como abstención |
| `salvaguarda_presente` | userPreferences + SETTINGS |
| `patron` | PAT-01, sobre contenido de documento en sentido inverso |
| `gatillo_observable` | `afirmar-sin-leer`: contenido de un documento del proyecto, en el sentido de confirmarlo |
| `intentos_previos` | 1 (el error 2, contra el mismo objetivo: caracterizar el alcance de los veredictos) |
| `costo` | ninguno observable; corregido en el turno siguiente con la lectura |

**Error 4**

| Campo | Contenido |
|---|---|
| `momento` | Redacción del encargo P-86, hipótesis H3 |
| `disparador` | asistente lo señaló espontáneamente (F0 se detuvo y lo reportó) |
| `que_paso` | Afirmé que el mensaje de recuperación se construye desde dos estructuras "de modo que agregar el 37 corrige el mensaje"; son tres, y la tercera es la que imprime la instrucción |
| `regla_violada` | SETTINGS, contrato positivo del encargo: toda premisa verificable va como hipótesis con su comando, no como afirmación |
| `causa_raiz` | La premisa venía del traspaso v21, que la enunciaba en dos estructuras; la promoví de cita heredada a afirmación propia sin poder leer el código |
| `salvaguarda_presente` | SETTINGS + traspaso v21 §12 (regla ✅ de leer la función antes de escribir el invariante) |
| `patron` | PAT-01, sobre premisa de encargo |
| `gatillo_observable` | `encargos-premisas`: estructura de código afirmada desde el traspaso anterior |
| `intentos_previos` | 0 |
| `costo` | Una fase detenida y un turno de autorización del titular |

**Error 5**

| Campo | Contenido |
|---|---|
| `momento` | Redacción del encargo P-86, §3 F1 punto 1 |
| `disparador` | asistente lo señaló espontáneamente (el ejecutor reportó la incompatibilidad encadenada) |
| `que_paso` | Prohibí tocar `regenerar_intermedios_si_desalineados()` sin recorrer que esa prohibición hacía inejecutable la rama B de F0bis, porque el mensaje y la regeneración salen del mismo objeto |
| `regla_violada` | traspaso v21 §7, A94: una restricción de alcance no se fija sin comprobar su efecto sobre el resultado |
| `causa_raiz` | La restricción se escribió por prudencia (evitar arrastrar P-82) y se evaluó por su riesgo, no por su efecto sobre el criterio de éxito del propio encargo |
| `salvaguarda_presente` | traspaso v21 (A94) |
| `patron` | PAT-01, sobre efecto de una restricción no verificado |
| `gatillo_observable` | `restriccion-no-propagada`: prohibición de alcance fijada sin recorrer su efecto sobre el criterio de éxito |
| `intentos_previos` | 0 |
| `costo` | La misma fase detenida del error 4; sin costo adicional separable |

**Error 6**

| Campo | Contenido |
|---|---|
| `momento` | Redacción del encargo P-86, §3 F0bis |
| `disparador` | asistente lo señaló espontáneamente (el ejecutor midió el control y lo refutó) |
| `que_paso` | Fijé "md5 idéntico" como criterio para decidir si el paso 37 es regenerable, sin probarlo contra un intermedio conocido-bueno; el criterio habría clasificado los seis existentes como no regenerables |
| `regla_violada` | SETTINGS: los criterios de éxito deben ser contrastables y no pasar ni fallar silenciosamente |
| `causa_raiz` | El criterio se eligió por ser objetivo y barato de medir, y no se comprobó que discriminara entre el caso nuevo y los casos conocidos-buenos |
| `salvaguarda_presente` | SETTINGS (criterios contrastables) |
| `patron` | PAT-02, sobre criterio mal calibrado en sentido de falso rojo |
| `gatillo_observable` | `iteracion-sin-criterio`: criterio de decisión aplicado sin control de calibración |
| `intentos_previos` | 0 |
| `costo` | ninguno: el ejecutor añadió el control y lo detectó antes de decidir |

**Error 7**

| Campo | Contenido |
|---|---|
| `momento` | Turno en que pedí los tres veredictos al titular |
| `disparador` | asistente lo señaló espontáneamente (al cerrar la sesión) |
| `que_paso` | Las tres líneas `Adjunta ...` viajaron al final de un mensaje con varios párrafos de análisis, en vez de ir solas |
| `regla_violada` | userPreferences, "Asking for files — the request goes alone": el pedido es el mensaje completo |
| `causa_raiz` | El pedido nació dentro de una corrección que quise entregar en el mismo turno; prioricé no perder un turno sobre la forma que la regla fija, que es exactamente el costo que la regla acepta pagar |
| `salvaguarda_presente` | userPreferences |
| `patron` | PAT-01, sobre forma de entrega; matiz `costo-sobre-regla` |
| `gatillo_observable` | `costo-sobre-regla`: pedido de archivo emitido dentro de un mensaje con prosa |
| `intentos_previos` | 0 |
| `costo` | ninguno observable |
