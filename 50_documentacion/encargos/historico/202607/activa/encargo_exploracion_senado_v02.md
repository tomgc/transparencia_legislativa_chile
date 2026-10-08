# Encargo — Exploracion API Senado v02 (cerrar huecos del diagnostico v01)

> **Instrumento de sesion.** Segundo encargo de exploracion insumos-first para
> transparencia_legislativa_chile. Continua el diagnostico v01
> (`exploracion_api_senado.md`, log `20260710_exploracion_api_senado_log.md`).
> Patron: `encargo_autonomo_claude_code_v1.md` (dirigido por meta).
>
> **Por que existe este encargo (contexto que el diagnostico v01 no tenia):**
> la sesion de diseno posterior verifico contra fuentes oficiales dos cosas que
> invalidan parcialmente los hallazgos de v01:
> 1. El Senado tiene **50 senadores** en el periodo vigente (LVII, iniciado el
>    11-mar-2026), NO 31. El endpoint `senadores_vigentes.php` que v01 uso
>    devolvio 31 → es un artefacto (endpoint desactualizado o filtrado), NO la
>    dotacion real. La fuente de roster de v01 no sirve para el periodo vigente.
> 2. La asistencia nominal SI existe (v01 la reporto como hueco total). Esta en
>    el sitio web del Senado (`senado.cl/actividad-legislativa/sala/asistencia`)
>    y posiblemente en un portal de datos abiertos del Congreso
>    (`opendata.congreso.cl`) que v01 NO exploro.
>
> Ademas, v01 dejo un riesgo de correctitud abierto: en `wspublico` los votos y
> autorias identifican al parlamentario por NOMBRE string (tres formatos
> distintos), sin id. Si existe una fuente con ids estables, cambia todo el
> diseno del pipeline.
>
> **Rama base (correccion v02.1):** este encargo se ramifica desde
> `explore/api-senado` (NO desde main), porque sus insumos de referencia (el
> diagnostico v01, su log y el script `31b`) viven en esa rama y NO estan
> mergeados a main (invariante 🔒 del traspaso v05). Ramificar desde main dejaria
> a Claude Code sin su punto de partida en el working tree. Consecuencia asumida:
> el arbol de v02 hereda los archivos de v01; el `git status` limpio se define en
> consecuencia (ver criterios de exito).

---

## Bloque para Claude Code

```
MODO: EJECUCION AUTONOMA. Encargo de DIAGNOSTICO/EXPLORACION insumos-first para
ejecutar AHORA en este repositorio (transparencia_legislativa_chile). Continua un
diagnostico previo. NO construyes pipeline, NO consolidas JSON, NO tocas nada del
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
- RAMA BASE: este encargo se ramifica desde explore/api-senado (NO desde main).
  Sus insumos de referencia (diagnostico v01, log, 31b) viven en esa rama y no
  estan en main. Ver FASE 0.
- INSUMOS de referencia (leelos del filesystem antes de empezar; estan en la rama
  explore/api-senado, que es la base de trabajo):
    /Users/tomgc/Projects/transparencia_legislativa_chile/50_documentacion/activa/exploracion_api_senado.md
    /Users/tomgc/Projects/transparencia_legislativa_chile/50_documentacion/andamios/logs/20260710_exploracion_api_senado_log.md
    /Users/tomgc/Projects/transparencia_legislativa_chile/30_procesamiento/31b_explorar_api_senado.R
    /Users/tomgc/Projects/transparencia_legislativa_chile/50_documentacion/activa/exploracion_api_camara.md
  El diagnostico v01 ya mapeo wspublico (tramitacion.senado.cl/wspublico): NO
  repitas ese trabajo salvo para lo que este encargo pide re-verificar.

═══════════════════════════════════════════════════════════════════════
REGLAS CANONICAS HEREDADAS (🔒)
═══════════════════════════════════════════════════════════════════════
- R como UNICO lenguaje, sin excepcion (toda inspeccion de datos en R: nada de
  Python, nada de curl+jq en bash para "mirar rapido"). Bash solo para git.
- httr2 para las llamadas HTTP; xml2 para XML; para JSON usa jsonlite. Parsea
  HTML (si una fuente solo esta en HTML) con rvest o xml2::read_html EN R.
- here::here() dentro de scripts; sin rutas absolutas hardcodeadas en codigo R.
- Naming sin tildes/ñ/espacios; snake_case.
- Identificadores SIEMPRE como character.
- Trabajas en la rama explore/api-senado-v02 (nueva, ramificada desde
  explore/api-senado). NO push, NO PR, NO merge. Si quedaron cambios sin
  commitear de otra sesion en el working tree, NO los toques ni los incluyas.

═══════════════════════════════════════════════════════════════════════
META DEL ENCARGO
═══════════════════════════════════════════════════════════════════════
Cerrar los tres huecos que el diagnostico v01 dejo abiertos, para poder decidir
en una sesion posterior cual es la fuente CORRECTA y COMPLETA del Senado antes de
disenar su pipeline:

  (H1) ASISTENCIA nominal: v01 la dio por hueco total en wspublico. Existe fuera
       de wspublico. Localizar la fuente real, traer muestra, documentar formato.
  (H2) ROSTER de 50: senadores_vigentes.php devolvio 31 (incorrecto para el
       periodo vigente LVII). Encontrar la fuente del roster real de 50 senadores
       en ejercicio.
  (H3) PORTAL opendata.congreso.cl: v01 no lo exploro. Evaluar si expone las
       cuatro entidades (senadores, asistencia, votaciones, proyectos) de forma
       mas limpia que wspublico — en particular, si trae IDENTIFICADORES ESTABLES
       de parlamentario (resolviendo el gap de identidad-por-nombre de v01).

═══════════════════════════════════════════════════════════════════════
INVARIANTES (🔒)
═══════════════════════════════════════════════════════════════════════
- NO modificar ningun archivo existente del pipeline ni el 31b de v01. Este
  encargo solo AGREGA archivos nuevos (un 31c y docs/muestras nuevas).
- NO tocar 20_insumos/, 40_salidas/, docs/.
- NO agregar scripts a run_all()/PASOS.
- NO inventar cobertura: si una fuente no existe o no expone algo, se reporta como
  hueco, nunca se fabrica (B.1).
- NO asumir que opendata.congreso.cl reemplaza a wspublico sin evidencia: puede
  estar incompleto, desactualizado o vacio. Verifica con muestra real, no supongas.

═══════════════════════════════════════════════════════════════════════
FASES (orden estricto)
═══════════════════════════════════════════════════════════════════════
FASE 0 — Preparacion (rama base explore/api-senado, con verificacion)
- git -C /Users/tomgc/Projects/transparencia_legislativa_chile checkout explore/api-senado
- Verifica el estado antes de ramificar (si hay cambios sin commitear heredados de
  otra sesion, NO los incluyas ni los descartes; solo constatalos):
    git -C /Users/tomgc/Projects/transparencia_legislativa_chile status
- Confirma que los cuatro insumos de referencia EXISTEN en el working tree de esta
  rama (test de presencia en R, no supongas):
    file.exists() sobre las cuatro rutas del bloque INSUMOS.
  Si alguno NO existe, PARA y reporta (caso de detencion #4): el encargo depende
  de ellos y ramificar desde la rama equivocada dejaria el diagnostico ciego.
- git -C /Users/tomgc/Projects/transparencia_legislativa_chile checkout -b explore/api-senado-v02
- Lee los insumos de referencia. Entiende que ya mapeo v01 para no repetir.

FASE 1 (H3 primero, porque puede resolver H1 y H2 de una vez) — opendata.congreso.cl
- Explora el portal opendata.congreso.cl en R. Descubre que expone: endpoints,
  protocolo (REST/JSON, XML, descargas CSV/bulk), y si cubre Senado o solo Camara
  o ambos.
- Pregunta critica a responder con evidencia: ¿trae un identificador estable de
  parlamentario (id numerico/string) que aparezca CONSISTENTE en roster, votos y
  autorias? Este es el punto que decide si el pipeline del Senado puede evitar el
  fuzzy name matching. Trae muestra real que lo demuestre o lo descarte.
- Para cada una de las cuatro entidades, si el portal la expone: muestra real +
  nota de si es mas limpia que la fuente wspublico equivalente de v01.

FASE 2 (H2) — Roster real de 50 senadores
- Encuentra la fuente del roster vigente de 50 senadores en ejercicio (periodo
  LVII, desde 11-mar-2026). Candidatos a probar en R, en este orden:
  (a) opendata.congreso.cl si la Fase 1 mostro que lo expone;
  (b) el listado del sitio senado.cl (parseo HTML en R si no hay endpoint);
  (c) re-examinar senadores_vigentes.php con parametros de periodo/legislatura
      por si el 31 vino de un default de periodo anterior.
- Objetivo: una muestra con 50 senadores y, si existe, su id estable. Si ninguna
  fuente da 50, reporta el numero real que cada fuente entrega y cual es la mas
  confiable — NO fuerces 50 si el dato no lo respalda (puede haber vacancias).

FASE 3 (H1) — Asistencia nominal
- Localiza la fuente de asistencia nominal (por senador, por sesion). Candidatos:
  (a) opendata.congreso.cl si la expone;
  (b) senado.cl/actividad-legislativa/sala/asistencia (parseo HTML/tabla en R, o
      descubrir el endpoint que alimenta esa pagina — inspecciona si hace una
      llamada XHR a un .php/.json que puedas consumir directo);
  (c) el Diario de Sesiones si la asistencia solo vive alli.
- Trae muestra real de la asistencia de al menos una sesion, con el detalle
  nominal (que senador asistio/ausento/justifico). Documenta el formato y como se
  cruza con el roster (¿por id o por nombre?).
- Si tras exploracion real la asistencia nominal NO resulta accesible de forma
  estructurada (solo PDF escaneado, o inexistente), reporta ESO como hallazgo
  (materializa caso de detencion #3, ver abajo) — pero solo despues de agotar los
  tres candidatos.

FASE 4 — Script + doc + comparacion de fuentes
- Escribe 30_procesamiento/31c_explorar_api_senado_v02.R: script R reproducible
  que ejecuta las exploraciones de las fases 1-3 y regenera las muestras. Header
  banner segun convencion del proyecto; auto-instalacion; library(); funciones;
  flujo. NO se agrega a run_all.
- Guarda las muestras en:
  50_documentacion/andamios/exploracion_api_senado_v02/<fuente>_<entidad>_muestra.<ext>
- Escribe 50_documentacion/activa/exploracion_api_senado_v02.md con:
  * Estado de cada hueco (H1, H2, H3): resuelto / parcial / sigue hueco, con la
    fuente localizada.
  * Tabla comparativa de FUENTES por entidad: [entidad | wspublico (v01) |
    opendata.congreso.cl | sitio senado.cl | fuente recomendada | trae id estable?].
  * Recomendacion de fuente primaria para el pipeline del Senado y por que.
  * El estado del gap de identidad-por-nombre: ¿resuelto por alguna fuente con id,
    o persiste?

═══════════════════════════════════════════════════════════════════════
CRITERIOS DE EXITO VERIFICABLES (B.4)
═══════════════════════════════════════════════════════════════════════
- Respuesta explicita y con evidencia (muestra real) a: ¿existe asistencia nominal
  estructurada? ¿donde? ¿cual es la fuente del roster de 50? ¿opendata.congreso.cl
  trae ids estables de parlamentario?
- Muestra real guardada por cada fuente/entidad que exista; huecos declarados.
- 31c corre de cero sin intervencion y regenera las muestras (o reporta que fuente
  fallo).
- Auto-auditoria: cada muestra abierta en R y confirmada parseable (no pagina de
  error), con conteo reportado.
- git status: limpio salvo (a) los archivos nuevos declarados de este encargo (31c,
  doc v02, muestras v02, log v02) y (b) los archivos heredados de la rama
  explore/api-senado (31b, doc v01, muestras v01, log v01), que son la base de la
  que se ramifico v02 y por tanto ya forman parte del arbol. NO deben aparecer
  archivos del pipeline de la Camara ni de docs/ como modificados.

═══════════════════════════════════════════════════════════════════════
CASOS DE DETENCION (PARA y reporta; no improvises)
═══════════════════════════════════════════════════════════════════════
1. opendata.congreso.cl exige autenticacion / API key / registro que no tienes.
2. La asistencia nominal solo existe como PDF no estructurado o no existe en
   ninguna de las tres fuentes tras exploracion real (reportar, no abortar el
   resto del encargo — las otras fases se completan igual).
3. Un dato real contradice un supuesto estructural del diseno (p. ej. ninguna
   fuente da ids estables y el fuzzy name matching resulta inevitable): reportalo
   como el hallazgo #1, porque define el pipeline.
4. Alguno de los cuatro insumos de referencia NO existe en el working tree de la
   rama base explore/api-senado (FASE 0): PARA y reporta cual falta. Significa que
   la rama base es la equivocada o que el estado local no coincide con el traspaso;
   no ramifiques ni ejecutes a ciegas.

═══════════════════════════════════════════════════════════════════════
AUTO-AUDITORIA Y CIERRE
═══════════════════════════════════════════════════════════════════════
- Antes de reportar, abre cada muestra en R y confirma contenido parseable con
  conteo. Para el roster, reporta el numero real de senadores que entrega cada
  fuente (el punto es 50 vs 31).
- Escribe log honesto en
  50_documentacion/andamios/logs/AAAAMMDD_exploracion_api_senado_v02_log.md
  (plantilla encargo_autonomo_claude_code_v1.md §4).
- Commits atomicos en explore/api-senado-v02, mensajes en espanol. NO push.

REPORTE FINAL AL CHAT:
- Estado de H1/H2/H3 (resuelto/parcial/hueco) con la fuente de cada uno.
- Tabla comparativa de fuentes resumida.
- Respuesta directa: ¿hay ids estables? ¿se evita el fuzzy name matching?
- Fuente primaria recomendada para el pipeline del Senado.
- Hashes de commits (locales, sin push) y ruta del log.
```
