# Encargo — Exploracion asistencia nominal por sesion del Senado (H1-bis)

> **Instrumento de sesion.** Tercer encargo de exploracion insumos-first para
> transparencia_legislativa_chile. Cierra un sub-hueco que el diagnostico v02
> (`exploracion_api_senado_v02.md`, rama `explore/api-senado-v02`) dejo abierto sin
> saberlo. Patron: `encargo_autonomo_claude_code_v1.md` (dirigido por meta).
>
> **Por que existe este encargo (lo que v02 no probo):**
> v02 confirmo que `web-back.senado.cl/api/sessions/attendance?id_legislatura=<id>`
> da asistencia **agregada por senador por legislatura** (asistio 92/105, etc.), con
> `ID_PARLAMENTARIO` estable. v02 se detuvo en ese endpoint y concluyo que el Senado
> solo tiene asistencia agregada, NO nominal por sesion (a diferencia de la Camara,
> que si tiene nominal por sesion en `33_extraer_asistencia.R`).
>
> Verificacion posterior contra fuentes oficiales mostro que el dato nominal por
> sesion SI existe y v02 no lo agoto:
> 1. La UI `senado.cl/actividad-legislativa/sala/asistencia` tiene selector por
>    **legislatura Y por sesion** (campos "Legislatura", "Total de sesiones"). Esa
>    UI corre sobre el MISMO backend `web-back.senado.cl`. Es muy probable que el
>    endpoint `attendance` (o uno hermano) acepte un parametro de **sesion**
>    (`id_sesion`/`id_reunion`/similar) que devuelva el detalle nominal de esa
>    sesion. v02 no probo ese parametro.
> 2. Existe una segunda via independiente NO explorada por v02:
>    `tramitacion.senado.cl/appsenado/index.php?mo=comisiones&ac=asist_x_senador`
>    ("asistencia por senador"), otro sistema distinto del backend.
>
> Este es el mismo patron que el roster de 31 vs 50: "un endpoint que responde no
> es el endpoint completo". El objetivo es NO diseñar el contrato de datos del
> pipeline del Senado sobre el supuesto (posiblemente falso) de que solo hay
> agregado.
>
> **Rama base:** `explore/api-senado-v02` (NO main, NO explore/api-senado v01),
> porque `31c` y las muestras del backend viven ahi y son el punto de partida; este
> encargo continua ese mapeo del backend sin re-descubrirlo.

---

## Bloque para Claude Code

```
MODO: EJECUCION AUTONOMA. Encargo de DIAGNOSTICO/EXPLORACION insumos-first para
ejecutar AHORA en este repositorio (transparencia_legislativa_chile). Continua el
diagnostico v02. NO construyes pipeline, NO consolidas JSON, NO tocas nada del
flujo existente. Solo AGREGAS archivos nuevos. Ejecuta las fases en orden y de
forma autonoma; te detienes solo en los casos de detencion declarados.

═══════════════════════════════════════════════════════════════════════
CONTRATO DE ENTORNO
═══════════════════════════════════════════════════════════════════════
- ENTORNO: filesystem local via Claude Code, repo en
  /Users/tomgc/Projects/transparencia_legislativa_chile (Rama A, repo publico).
- POSICION: toda ruta completa desde la raiz del proyecto. Ningun comando asume
  cd previo. Usa git -C /Users/tomgc/Projects/transparencia_legislativa_chile ...
  en cada comando git.
- RAMA BASE: este encargo se ramifica desde explore/api-senado-v02 (NO main). El
  mapeo del backend web-back.senado.cl y las muestras del roster/asistencia/votos
  viven en esa rama; son el punto de partida.
- INSUMOS de referencia (leelos del filesystem antes de empezar; estan en la rama
  base explore/api-senado-v02):
    /Users/tomgc/Projects/transparencia_legislativa_chile/50_documentacion/activa/exploracion_api_senado_v02.md
    /Users/tomgc/Projects/transparencia_legislativa_chile/30_procesamiento/31c_explorar_api_senado_v02.R
    /Users/tomgc/Projects/transparencia_legislativa_chile/50_documentacion/andamios/exploracion_api_senado_v02/
    /Users/tomgc/Projects/transparencia_legislativa_chile/30_procesamiento/33_extraer_asistencia.R
  El 33 de la Camara es la referencia del formato NOMINAL POR SESION que se busca
  replicar (o descartar) para el Senado.

═══════════════════════════════════════════════════════════════════════
REGLAS CANONICAS HEREDADAS (🔒)
═══════════════════════════════════════════════════════════════════════
- R como UNICO lenguaje, sin excepcion (toda inspeccion de datos en R: nada de
  Python, nada de curl+jq en bash para "mirar rapido"). Bash solo para git.
- httr2 para las llamadas HTTP; jsonlite para JSON; xml2/rvest para HTML EN R.
- here::here() dentro de scripts; sin rutas absolutas hardcodeadas en codigo R.
- Naming sin tildes/ñ/espacios; snake_case.
- Identificadores SIEMPRE como character (ID_PARLAMENTARIO, PARLID, id de sesion).
- Trabajas en la rama explore/api-senado-v02-asistencia (nueva, ramificada desde
  explore/api-senado-v02). NO push, NO PR, NO merge. Si hay cambios sin commitear
  heredados en el working tree, NO los toques ni los incluyas.

═══════════════════════════════════════════════════════════════════════
META DEL ENCARGO
═══════════════════════════════════════════════════════════════════════
Responder con EVIDENCIA (muestra real), una sola pregunta y sus derivadas:

  ¿Existe asistencia NOMINAL POR SESION del Senado (quien asistio / se ausento /
  justifico en CADA sesion individual), accesible de forma estructurada y cruzable
  por ID_PARLAMENTARIO?

  Si SI: cual es el endpoint/fuente, que formato tiene, y como se cruza con el
  roster (por id). Traer muestra de al menos 2 sesiones distintas.
  Si NO: confirmar que solo existe el agregado por legislatura (el de v02), tras
  agotar las dos vias candidatas. Reportarlo como hallazgo firme, no como supuesto.

Esto define si el contrato de datos del pipeline del Senado puede ser SIMETRICO con
la Camara (nominal por sesion en ambas) o debe ser ASIMETRICO (agregado en Senado).

═══════════════════════════════════════════════════════════════════════
INVARIANTES (🔒)
═══════════════════════════════════════════════════════════════════════
- NO modificar ningun archivo existente (ni 31c, ni 33, ni el pipeline). Solo
  AGREGAS archivos nuevos (un 31d y docs/muestras nuevas).
- NO tocar 20_insumos/, 40_salidas/, docs/.
- NO agregar scripts a run_all()/PASOS.
- NO inventar cobertura: si el nominal por sesion no existe, se declara hueco tras
  agotar las vias, nunca se fabrica (B.1).
- NO forzar volumen: basta muestra de 2 sesiones para probar el formato; no barrer
  las 105 sesiones (esto es exploracion, no extraccion).

═══════════════════════════════════════════════════════════════════════
FASES (orden estricto)
═══════════════════════════════════════════════════════════════════════
FASE 0 — Preparacion (rama base explore/api-senado-v02, con verificacion)
- git -C /Users/tomgc/Projects/transparencia_legislativa_chile checkout explore/api-senado-v02
- git -C /Users/tomgc/Projects/transparencia_legislativa_chile status
  (constata cambios heredados; NO los toques).
- Confirma en R con file.exists() que existen: exploracion_api_senado_v02.md,
  31c_explorar_api_senado_v02.R, y la carpeta de muestras v02. Si falta alguno,
  PARA y reporta (caso de detencion #4): rama base equivocada.
- git -C /Users/tomgc/Projects/transparencia_legislativa_chile checkout -b explore/api-senado-v02-asistencia
- Lee los insumos. Recupera del doc v02 la firma exacta del endpoint attendance y
  el id_legislatura usado (504), y un ID_PARLAMENTARIO conocido para cruzar
  (p. ej. 1110 = Araya).

FASE 1 (via primaria) — parametro de sesion en el backend web-back.senado.cl
- Objetivo: descubrir si attendance (o un endpoint hermano) devuelve nominal por
  sesion. Estrategia empirica en R (httr2), en este orden:
  (a) Inspecciona que llamada XHR hace la UI de asistencia por sesion. Trae en R el
      HTML/JS de senado.cl/actividad-legislativa/sala/asistencia y de una sesion de
      sala concreta (p. ej. las paginas /sesiones-de-sala/<id>), y busca en el
      markup/JS las URLs de api que consume (patron /api/... o web-back). No asumas
      el nombre del parametro: descubrelo.
  (b) Prueba variantes del endpoint attendance con parametro de sesion:
      /api/sessions/attendance con id_sesion / id_reunion / id / session_id, y
      /api/sessions?id_legislatura=504 para listar las sesiones y obtener sus ids
      reales, luego attendance por una de esas sesiones.
  (c) Sonda endpoints hermanos plausibles del backend (p. ej. /api/sessions/<id>,
      /api/attendance, /api/sala/asistencia) — SIEMPRE con muestra real que
      confirme si traen detalle nominal {asistio/ausente/justificado} por senador
      con ID_PARLAMENTARIO, no solo el total.
- Criterio de exito de la fase: o bien una muestra JSON de UNA sesion con la lista
  nominal de senadores y su estado, cruzable por id; o bien evidencia de que el
  backend NO expone ese detalle (solo agregado).

FASE 2 (via secundaria, solo si Fase 1 no resolvio) — tramitacion.senado.cl
- Explora en R tramitacion.senado.cl/appsenado/index.php?mo=comisiones&ac=asist_x_senador
  y las rutas hermanas de ese sistema (mo=sesionsala u similares). Puede ser HTML
  (parsea con rvest) o exponer un endpoint de datos.
- OJO: distingue asistencia a SALA de asistencia a COMISIONES. El contrato del
  dashboard es asistencia a sala (equivalente al 33 de la Camara). Si esta via solo
  da comisiones, dilo explicitamente y no la confundas con sala.
- Trae muestra real que muestre el detalle nominal por sesion y como se identifica
  al senador (id o nombre). Si es por nombre, nota si el formato cruza con
  NOMBRE_COMPLETO_POR_APELLIDOS del roster (cruce determinista, sin fuzzy).

FASE 3 — Script + doc
- Escribe 30_procesamiento/31d_explorar_asistencia_senado.R: script R reproducible
  que ejecuta las sondas de las fases 1-2 y regenera las muestras. Header banner
  segun convencion; auto-instalacion; library(); funciones; flujo. NO se agrega a
  run_all.
- Guarda muestras en:
  50_documentacion/andamios/exploracion_asistencia_senado/<fuente>_sesion_<id>_muestra.<ext>
- Escribe 50_documentacion/activa/exploracion_asistencia_senado.md con:
  * Veredicto: ¿existe nominal por sesion? SI (con fuente y formato) / NO (solo
    agregado, vias agotadas).
  * Si SI: endpoint exacto, parametro de sesion, formato del detalle, campo de id,
    y como se lista el universo de sesiones de una legislatura.
  * Implicancia para el contrato: ¿simetrico (nominal ambas camaras) o asimetrico
    (agregado en Senado)?
  * Tabla: [via | responde? | nominal por sesion? | id estable? | sala o comision?].

═══════════════════════════════════════════════════════════════════════
CRITERIOS DE EXITO VERIFICABLES (B.4)
═══════════════════════════════════════════════════════════════════════
- Respuesta explicita SI/NO a "¿existe asistencia nominal por sesion del Senado?"
  respaldada por muestra real (si SI) o por evidencia de agotamiento de ambas vias
  (si NO).
- Si SI: muestra de al menos 2 sesiones distintas, cada una con lista nominal y el
  ID_PARLAMENTARIO cruzado contra el roster (verificar que un id conocido, p. ej.
  1110, aparece).
- 31d corre de cero sin intervencion y regenera las muestras (o reporta que via
  fallo y por que).
- Auto-auditoria: cada muestra abierta en R, parseable (no pagina de error), con
  conteo de senadores por sesion reportado.
- git status: limpio salvo (a) los archivos nuevos de este encargo (31d, doc,
  muestras) y (b) los heredados de explore/api-senado-v02 (31c, doc v02, muestras
  v02). NO deben aparecer archivos del pipeline de la Camara ni de docs/ tocados.

═══════════════════════════════════════════════════════════════════════
CASOS DE DETENCION (PARA y reporta; no improvises)
═══════════════════════════════════════════════════════════════════════
1. Alguna via exige autenticacion / API key / registro que no tienes.
2. El nominal por sesion solo existe como PDF no estructurado (p. ej. solo en el
   Diario de Sesiones) o no existe en ninguna via tras exploracion real: reporta
   ESO como veredicto (es un hallazgo valido, no un fracaso), tras agotar Fase 1 y
   Fase 2.
3. Un dato real contradice un supuesto del encargo (p. ej. el backend da nominal
   pero SIN id, solo por nombre en formato que no cruza): reportalo, porque cambia
   la implicancia para el contrato.
4. Falta un insumo de referencia en la rama base (FASE 0): PARA, no ramifiques a
   ciegas.

═══════════════════════════════════════════════════════════════════════
AUTO-AUDITORIA Y CIERRE
═══════════════════════════════════════════════════════════════════════
- Antes de reportar, abre cada muestra en R y confirma contenido parseable con
  conteo de senadores por sesion. Cruza un id conocido contra el roster v02.
- Escribe log honesto en
  50_documentacion/andamios/logs/AAAAMMDD_exploracion_asistencia_senado_log.md
  (plantilla encargo_autonomo_claude_code_v1.md §4).
- Commits atomicos en explore/api-senado-v02-asistencia, mensajes en espanol.
  NO push.

REPORTE FINAL AL CHAT:
- Veredicto SI/NO con la fuente.
- Si SI: endpoint + parametro de sesion + formato + campo de id, y muestra de 2
  sesiones con conteo.
- Implicancia para el contrato del pipeline: simetrico o asimetrico.
- Tabla de vias resumida.
- Hashes de commits (locales, sin push) y ruta del log.
```
