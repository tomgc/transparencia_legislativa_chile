# Traspaso de cierre v03 — transparencia_legislativa_chile

## 1. Identificacion

- **Proyecto:** transparencia_legislativa_chile
- **Version del traspaso:** v03
- **Fecha:** 2026-07-10 (jornada de trabajo 2026-07-09, cierre 07-10)
- **Sesion:** 3 (CONTINUATION). Foco: construir la Fase 2 (dashboard estatico),
  hacer legible y trazable el contenido de proyectos y votos, saldar la deuda de
  la clave de cache e integrar todas las ramas a main.
- **Entorno:** Claude Code + claude.ai (Opus 4.8), macOS, R 4.5.2.
- **Archivos principales modificados:** `docs/index.html` (nuevo dashboard),
  `30_procesamiento/39_consolidar_json.R`, `30_procesamiento/36_extraer_detalle_proyectos.R`
  (nuevo), `30_procesamiento/{33,34,35}_extraer_*.R`, `10_utils/10_utils.R`,
  `00_run_all.R`, `docs/data/` + `docs/assets/fonts/` (publicacion), snapshots de
  `20_insumos/camara/` (renombrados a `_tope-inf`).
- **Registro de ejecucion detallado:** cinco logs en
  `50_documentacion/andamios/logs/` (ver §10 y §13); detalle paso a paso no
  reproducido aqui.

## 2. Resumen ejecutivo

Sesion larga de construccion con seis encargos autonomos a Claude Code, todos
verificados e integrados. Se construyo la Fase 2: un dashboard estatico de
archivo unico (`docs/index.html`, HTML/CSS/JS vanilla, sin CDN, carga perezosa,
hash routing) que consume el JSON, con hemiciclo por tendencia (grupo IND
explicito), filtros y vista de perfil. Se saldaron dos deudas del propio
dashboard (metricas resumen y `partido_nombre`/`sexo` en el indice). Un
diagnostico insumos-first descubrio que la API expone `tipo_iniciativa` y
`materias` por proyecto y un join estructurado voto->proyecto; sobre esa base se
agrego el paso 36 y se enriquecieron los bloques `proyectos` y `votaciones` de
los perfiles (cada voto de Proyecto de Ley enlaza a su proyecto legible; el
31,5% sin boletin queda con `proyecto:null` y tipo legible, hueco estructural).
Se corrigio la clave de `con_cache` para codificar el tope de extraccion
(pendiente 2 de v02). Finalmente se integraron las tres ramas vivas a main
(reconciliando el tope de 36) y se versionaron los logs. main (`71ff7c3`) queda
como fuente unica e integra. Sin push (no hay remoto aun). Emergio que la fecha
del sistema rodo a 07-10 y activo en la practica la limitacion de date-stamping:
el pipeline ya no se regenera hoy sin re-descargar y cambiar conteos, lo que
vuelve central el diseno del sistema de actualizacion.

## 3. Estado al cierre

**Funciona (ultima verificacion 2026-07-10 via only=39 desde intermedios congelados):**
- Dashboard `docs/index.html`: renderiza indice (155) + hemiciclo + filtros +
  perfil, con contenido legible y trazabilidad voto->proyecto. grep de red = 0.
- Pipeline: `run_all(only=39)` reproduce los 155 perfiles identicos (salvo
  timestamp) desde los intermedios congelados; indice 155; tendencia null=25;
  testigo 872 = 672 votos / 9 proyectos; split 460 con proyecto / 212 null.
- Clave de cache codifica el tope (`_tope-inf` en produccion); snapshots migrados.
- main integra las 3 ramas (`71ff7c3`).

**No funciona / no incluido (por alcance):**
- El pipeline NO se puede regenerar hoy sin re-descargar: la fecha rodo a 07-10 y
  `con_cache` codifica `Sys.Date()`, asi que los snapshots del 06/09-jul no dan
  cache-hit. Correr `only=36` o `run_all()` completo re-descargaria y cambiaria
  conteos (el corpus crecio 218->228 mociones). Es la limitacion de date-stamping,
  no un bug introducido.
- Sin push (no hay remoto configurado; `origin` no existe).
- Senado, BCN, GitHub Actions, estado de tramitacion: fuera de alcance.

**Delta respecto a v02:**
- Fase 2 (dashboard) de inexistente -> construida, integrada, verificada.
- Perfiles: de conteos agregados -> contenido legible (tipo_iniciativa, materias)
  y trazabilidad voto->proyecto (sub-objeto `proyecto` anidado).
- Indice: sumadas metricas resumen (asistencia, n_proyectos, n_votaciones) y
  `partido_nombre` + `sexo`.
- Clave de cache: de no codificar el tope -> lo codifica (`_tope-inf`/`_tope-<n>`).
- Repo: de una rama mergeada + trabajo suelto -> tres ramas integradas a main.

## 4. Registro detallado de cambios

Detalle paso a paso en los cinco logs (§13). En sintesis, seis encargos:

1. **Dashboard Fase 2** (5 commits en `feature/dashboard-fase2`): `docs/index.html`
   vanilla; metricas resumen en el indice (`39`); publicacion a `docs/data/`;
   fuentes autohospedadas; luego `partido_nombre`+`sexo` en el indice y eliminacion
   de la constante `PARTIDO_NOMBRES`. Log: `20260709_dashboard_fase2_log.md` y
   `..._fase2b_log.md`.
2. **Diagnostico de contenido legible** (rama `explore/...`, 2 commits): descubrio
   `tipo_iniciativa`, `materias` y el join `VotacionProyectoLey/Id`; cobertura del
   join 460/460 en Proyecto de Ley. Log/documento: `20260709_diagnostico_contenido_legible.md`.
3. **Contenido legible + trazabilidad** (rama `feature/contenido-legible-trazabilidad`,
   3 commits): paso 36 nuevo, `39` enriquece `proyectos[]` y `votos[]`, frontend
   muestra materias/titulo del proyecto votado. Log: `20260709_contenido_legible_log.md`.
4. **Fix clave de cache** (rama `fix/cache-key-tope`, 2 commits): `con_cache`
   codifica el tope; snapshots migrados a `_tope-inf`. Log: `20260709_fix_cache_key_log.md`.
5. **Integracion de ramas a main** (merges + fix-36 + docs): `71ff7c3`. Log:
   `20260709_integracion_ramas_log.md`.

## 5. Backlog acumulativo

Copiado integro del v02 y ampliado en este cierre:
**`50_documentacion/activa/backlog_acumulativo.md`**. Numeracion global continua;
entradas 1-8 previas (intactas), entradas 9-14 de la sesion 3. Ver ese archivo;
no se reproduce aqui.

## 6. Bugs de la sesion

Bugs de CODIGO encontrados y resueltos (detalle en los logs):

- **Foco perdido en el buscador del dashboard.** Sintoma: el `<input>` perdia
  foco/cursor al re-renderizar `innerHTML` completo por tecleo. Causa raiz:
  patron de full re-render sin reconciliacion de DOM (esperable sin framework).
  Solucion: guardar `activeElement` + `selectionStart/End` antes de reescribir y
  restaurarlos. Verificado interactivamente. Estado: resuelto.
- **Crecimiento del corpus al re-descargar.** Sintoma: enriquecer `35` con clave
  de cache nueva re-descargo la lista de mociones, que crecio 218->228 en 3 dias,
  descongelando conteos. Causa raiz: los responses crudos de `retornarProyectoLey`
  nunca se cachearon; re-correr `35` refresca la lista. Solucion: se revirtio `35`,
  se restauro `proyectos.rds` congelado, y todo el detalle se movio al paso 36 que
  lee boletines de intermedios congelados. Patron aprendido: para enriquecer sin
  descongelar, leer los boletines de los intermedios ya congelados y bajar solo el
  detalle estable. Estado: resuelto.
- **`[[` sobre vector nombrado lanza error** (no NULL) para llave ausente, en un
  script de auditoria. Solucion: `x %in% names(map)` antes de indexar. Estado: resuelto.

## 7. Aprendizajes y restricciones descubiertas

- **El date-stamping de la clave de cache es el bloqueante real de la
  regeneracion, no el tope.** `con_cache` codifica `Sys.Date()`: los snapshots de
  un dia no dan cache-hit en dias siguientes. El fix del tope (necesario y
  correcto) resuelve la reutilizacion silenciosa con tope distinto EL MISMO DIA,
  pero no habilita regenerar coherentemente entre dias. Regla: un sistema que
  necesite un corte temporal estable no puede depender de `Sys.Date()` en la
  clave; el corte debe ser un parametro explicito y versionado. Es el nucleo del
  pendiente 1.
- **Enriquecer sin descongelar** (ver bug 6.2): leer boletines de intermedios
  congelados y bajar solo detalle estable, en un paso aparte, en vez de re-correr
  el extractor que refresca la lista.
- **Honestidad de la clave de cache en 36.** 36 no aplica cap propio (procesa toda
  la union congelada), asi que su tope honesto es `Inf`, no `MAX_PROYECTOS_DETALLE`.
  Regla: la clave codifica el parametro REAL que altera el contenido, no uno
  prestado que suene plausible.
- **El 31,5% de votos sin boletin es estructural, no perdida de parseo.** Son
  Proyectos de Acuerdo/Resolucion/Otros que no tienen boletin por naturaleza. El
  regex tiene recall 100% sobre votaciones de Proyecto de Ley. Cierra un # REVISAR
  arrastrado desde la Fase 2.

## 8. Decisiones de diseno

- **Dashboard: archivo unico vanilla, carga perezosa, hash routing.** Alternativa:
  React/bundle. Justificacion: invariante de web estatica autocontenida sin CDN;
  el indice carga instantaneo y los perfiles on-demand. Implicancia: sin build step.
- **Grupo IND "sin clasificar" explicito** en indice, hemiciclo, leyenda y perfil.
  Alternativa: excluirlos del eje. Justificacion: 25 de 155 son una porcion real;
  ocultarlos falsea totales.
- **Materias vacias = hueco explicito** (`[]` en JSON, "Sin materias registradas"
  en UI). Alternativa: ocultar el campo. Justificacion: la mayoria de mociones
  2026 no trae materias; ocultarlo pareceria bug. Coherente con el trato de otros
  huecos (distrito/region "sin dato").
- **Trazabilidad: sub-objeto `proyecto` anidado en cada voto** (null si no hay
  boletin). Alternativa: campos aplanados. Justificacion: agrupa lo que viene del
  join y distingue "voto sin proyecto" por ausencia del objeto.
- **Detalle de proyectos en un solo paso 36** (autorados + votados unidos).
  Alternativa: dos intermedios separados (Fase A en 35 + Fase B en 36).
  Justificacion: evita re-correr 35 (que descongela el corpus) y simplifica 39.
- **Clave de cache: tope centralizado en `con_cache`** (parametro `tope`), no
  repetido en cada call-site. Token `_tope-inf` / `_tope-<n>`. Justificacion:
  la regla "la clave codifica todo parametro que altera el contenido" vive en un
  solo lugar.
- **Orden de integracion: cache-fix -> contenido-legible -> explore.**
  Justificacion: el fix de infraestructura como base; la reconciliacion de 36 se
  hace contra un `con_cache` ya corregido.

## 9. Constantes y parametros vigentes

Fuente canonica: `10_utils/10_configuracion.R`. Sin cambios de valor esta sesion
(los topes siguen en `Inf`, produccion). Cambio estructural: `con_cache` ahora
recibe `tope` y lo codifica en la clave.

| Constante | Valor | Archivo | Nota |
|-----------|-------|---------|------|
| `MAX_VOTACIONES_DETALLE` | `Inf` | 10_configuracion.R | produccion; ahora en la clave (`_tope-inf`) |
| `MAX_PROYECTOS_DETALLE` | `Inf` | 10_configuracion.R | idem |
| `MAX_SESIONES_DETALLE` | `Inf` | 10_configuracion.R | idem |
| `MAPA_PARTIDO_TENDENCIA` | 17 clasificados + IND `NA` | 10_configuracion.R | sin cambios |

## 10. Arquitectura de archivos

Escaner al cierre: `50_documentacion/estructura/estructura_actual.md`
(2026-07-10 07:10; 21 carpetas, 380 archivos). Cambios estructurales respecto a
v02: nuevo `30_procesamiento/36_extraer_detalle_proyectos.R`; nuevo arbol `docs/`
(index.html + `data/` con indice + 155 perfiles + `assets/fonts/` con 10 woff2);
nuevo intermedio `40_salidas/intermedios/proyectos_detalle.rds`; snapshots de
`20_insumos/camara/` renombrados a `_tope-inf`; andamios/logs poblados. Verificado
contra la politica: estructura por decenas respetada; `36` sigue el correlativo de
`30_procesamiento/`.

**Registro de ejecucion detallado:** cinco logs en
`50_documentacion/andamios/logs/` (dashboard fase2, fase2b, contenido legible,
fix cache key, integracion de ramas) — detalle paso a paso no reproducido aqui.

## 11. Pendientes y ruta sugerida

### Inventario de pendientes
1. **Diseno del sistema de actualizacion + versionado del corte temporal**
   (PRINCIPAL, vuelto urgente). El date-stamping impide regenerar sin drift.
   Definir: fuente y endpoints de lo incremental, procedimiento de deteccion de lo
   nuevo, canal de ejecucion (Positron manual o GitHub Actions, NO Claude Code por
   turno para no gastar tokens), periodicidad, como se versiona el corte (corte
   explicito en vez de `Sys.Date()`), re-consolidacion y re-publicacion a `docs/`.
   Entrelaza con el # REVISAR de la dependencia aguas-arriba de 36. Tipo: diseno
   (no construccion). Complejidad: media-alta. Criterio de exito: un procedimiento
   documentado que refresque el corpus de forma coherente y reproducible sin drift
   silencioso.
2. **Migracion a GitHub.** No hay `origin`; proyecto 100% publico (Rama A, sin
   datos sensibles). Crear repo, `git remote add origin`, primer push, activar
   Pages sobre `/docs`. Protocolo SETTINGS 4.3. Habilita ademas el canal Actions
   para el pendiente 1. Complejidad: media.
3. **Fase 3 — Senado.** El proyecto es el Congreso completo. Fuente y pipeline
   nuevos, modelo que unifique/segmente ambas camaras. Complejidad: alta.
4. **Etapa de tramitacion por votacion.** `VotacionProyectoLey/TramiteConstitucional`
   y `TramiteReglamentario` estan disponibles (via el detalle que 36 ya baja) y no
   incorporados. Mostraria "en que tramite estaba el proyecto al votarse".
   Complejidad: baja.
5. **Housekeeping de ramas.** Las ramas mergeadas (`fix/cache-key-tope`,
   `feature/contenido-legible-trazabilidad`, `explore/contenido-proyectos-votos`,
   `feature/dashboard-fase2`) siguen sin borrar (decision del titular). Evaluar
   borrado tras confirmar el estado de main.
6. **Huecos de fuente heredados** (diferidos, no son deuda de codigo): materias
   ralas (solo 5/317 boletines las traen; la fuente no las puebla en mociones
   2026), resumen/idea matriz y enlace al texto (no en la API WServices; requeririan
   BCN u otra fuente), estado de tramitacion vigente, rol autor/coautor (Orden=0
   para todos), asistencia con transicion de periodo (ene-mar 2026 del periodo
   previo).

### Evaluacion de deuda tecnica
Zona fragil: el date-stamping de la clave de cache (pendiente 1) es ahora la deuda
critica; convierte cualquier regeneracion en un evento que cambia conteos. La
dependencia aguas-arriba de 36 (su conjunto de boletines depende de los topes de
34/35, no codificados en el snapshot de 36) es un edge no critico documentado.

### Auditoria de cierre (POLITICA 5.6, preguntas "Cierre")
- ¿Pipeline corre de cero sin intervencion manual? **Parcial** — corre, pero un
  refresh hoy re-descarga y cambia conteos (date-stamping); pendiente 1 lo aborda.
- ¿Cada transformacion critica tiene check de validacion? **Si** (stopifnot en 39,
  auto-auditorias en R por encargo).
- ¿Outputs reproducibles e idempotentes? **Si desde los intermedios congelados**
  (only=39 reproduce identico salvo timestamp); no desde la API en vivo (drift).
- ¿Decisiones metodologicas como constantes nombradas? **Si**.
- ¿Nombres sin tildes/ñ/espacios? **Si**.

### Ruta sugerida para la proxima sesion
Prioridad 1: sesion de DISENO (conversacional con el titular, no encargo a Claude
Code) del sistema de actualizacion y del versionado del corte temporal; de ahi
sale el encargo de construccion. Prioridad 2: migracion a GitHub (protocolo 4.3),
que ademas habilita Actions como canal candidato del pendiente 1. Alternativa de
orden: migrar a GitHub PRIMERO y luego disenar la actualizacion sabiendo ya que
infraestructura hay. Diferir: Senado, tramitacion por votacion, huecos de fuente.

## 12. Instrucciones especificas para la proxima sesion

- ⚠️ NO correr `run_all()` completo ni `only=36`/`only=34`/`only=35` sin decision
  explicita: hoy re-descargan (date-stamping) y cambian conteos (corpus crecio
  218->228). Para verificar consolidacion, usar `only=39` (lee intermedios
  congelados).
- ⚠️ NO publicar (push) sin visto bueno del titular. Ademas: aun no hay remoto.
- ⚠️ NO alterar la clasificacion de tendencia por criterio propio (IND=NA a proposito).
- ✅ ANTES de cambiar un tope, la clave ya lo codifica: un tope nuevo genera
  snapshot nuevo (ya no reutiliza el viejo el mismo dia). El date-stamping sigue
  siendo el limite entre dias.
- ✅ ANTES de reportar cifras, recontar programaticamente en R sobre el JSON.
- ✅ ANTES de disenar la actualizacion, tratar el corte temporal como parametro
  explicito, no como `Sys.Date()`.
- 🔒 R unico lenguaje: pipeline Y verificacion/auditoria. Nada de Python en ningun
  contexto (incluida inspeccion de solo lectura).
- 🔒 Llaves de identificacion siempre `character`.
- 🔒 El navegador solo lee JSON precomputado; web estatica autocontenida sin CDN;
  fuentes autohospedadas; grep de red en `docs/index.html` debe seguir en 0.
- 🔒 El canal de operacion rutinaria (actualizacion) debe ser sin consumo de
  tokens (Positron manual o GitHub Actions), reservando Claude Code para desarrollo.

## 13. Fragmentos de codigo de referencia

Sin patrones nuevos que reproducir aqui; los estables viven en `CLAUDE.md`,
`documentacion_tecnica_v1.md` y `10_utils/10_utils.R`. Patrones clave de esta
sesion, documentados en sus logs:
- `con_cache(nombre, fn, tope = ..., origen = ...)` con `sufijo_tope()` — clave que
  codifica el tope (`10_utils/10_utils.R`).
- `parsear_contenido_proyecto(doc)` — parser compartido de `retornarProyectoLey`
  (titulo, tipo_iniciativa, materias) usado por 36 (`10_utils/10_utils.R`).
- Enriquecer sin descongelar: leer boletines de intermedios congelados y bajar
  solo detalle estable (`36_extraer_detalle_proyectos.R`).

Registro de ejecucion detallado de la jornada:
`50_documentacion/andamios/logs/20260709_{dashboard_fase2,dashboard_fase2b,contenido_legible,fix_cache_key,integracion_ramas}_log.md`.

## 14. Reapertura

**Nombre del chat:** `Transparencia Legislativa, sesion 4 (Opus 4.8)`

**Mensaje de apertura pre-armado (copiar al abrir la proxima sesion):**

> Tipo: CONTINUATION. El protocolo (POLITICA_PROYECTO.md,
> SETTINGS_Y_PROMPTS_OPERACIONALES.md) vive en la knowledge base del Project y se
> lee desde ahi. Adjunto: `traspaso_cierre_v03.md`, `estructura_actual.md`,
> `backlog_acumulativo.md`. Estado: Fase 2 (dashboard) construida, integrada y
> verificada; perfiles con contenido legible y trazabilidad voto->proyecto; clave
> de cache codifica el tope; main (`71ff7c3`) es fuente unica, sin push (no hay
> remoto). Limitacion activa: el date-stamping impide regenerar hoy sin
> re-descargar y cambiar conteos. Foco propuesto: sesion de DISENO del sistema de
> actualizacion y del versionado del corte temporal (conversacional, no encargo a
> Claude Code); alternativa, migrar a GitHub primero (protocolo 4.3) y disenar
> despues.

**Documentos para la proxima sesion:**
1. *Protocolo en knowledge base (no se adjunta, solo verificar que este al dia):*
   `POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
2. *Opcionales segun foco:* `CLAUDE.md` (si corre en Claude Code);
   `documentacion_tecnica_v1.md`; `encargo_autonomo_claude_code_v1.md` (si el
   diseno deriva en un encargo); protocolo 4.3 de SETTINGS (si se migra a GitHub).
3. *Especificos de la sesion (adjuntar):* `traspaso_cierre_v03.md`;
   `estructura_actual.md`; `backlog_acumulativo.md`.

**Nota final:** si algun archivo listado cambio entre sesiones, adjuntar la
version mas actualizada al abrir y avisarlo.

## 15. Errores del asistente (registro obligatorio, POLITICA 0.5)

| momento | disparador | que_paso | regla_violada | causa_raiz | salvaguarda_presente | patron |
|---------|-----------|----------|---------------|------------|----------------------|--------|
| Tras evaluar el log de la Fase 2b, antes de que el titular pidiera cerrar | usuario lo corrigio | El asistente propuso generar el traspaso v03 y ofrecio opciones de cierre sin instruccion explicita del titular | userPreferences (Autonomy: no decidir por el usuario; no cierre autonomo de sesion) + SETTINGS §1.2 (el cierre requiere instruccion) | El asistente equiparo "trabajo verificado" con "la sesion debe cerrar", en vez de esperar la instruccion | userPreferences + SETTINGS | REINCIDENTE cross-cartera: mismo patron registrado en Mundial v03 y v05 |
| Al terminar dos respuestas seguidas (registro del patron Python->R y confirmacion de la regla de no-cierre) | usuario lo corrigio | El asistente cerro con "¿Como seguimos?" / filler que empuja un turno mas | userPreferences (Brevity: sin filler de cierre, sin openers; decir exactamente lo necesario) | Reflejo de cerrar pidiendo la siguiente instruccion en vez de detenerse | userPreferences (Brevity) | REINCIDENTE cross-cartera: mismo filler corregido en Mundial sesiones 3-4 |
| Al inspeccionar el perfil de muestra (872.json) en el entorno de analisis | asistente lo senalo espontaneamente | El asistente intento evitar `view`/`grep` invocando una "autocorreccion R-only", aplicando el invariante R-only a su propio entorno de analisis (donde no aplica: R-only cubre el pipeline y la verificacion del proyecto, no la lectura de un archivo por el asistente conversacional) | Aplicacion incorrecta de un invariante (invariante R-only, alcance) — el error es de sobre-aplicacion, no de violacion | El asistente sobre-corrigio por la memoria de que Python->R fue error recurrente, extendiendo la regla mas alla de su alcance real | — (ninguna regla exigia esa autocorreccion; fue una mala interpretacion del alcance) | nuevo (variante inversa del patron Python->R: aqui se sobre-aplico la regla, no se violo) |

> Los tres errores se registraron como provisionales en el historial de la
> conversacion en el momento en que ocurrieron (POLITICA 0.5). Los dos primeros son
> reincidentes cross-cartera: su aparicion en dos o mas proyectos (Transparencia +
> Mundial) es, segun SETTINGS §2.2.15, evidencia de que la salvaguarda actual no
> basta y debe reformularse, no solo repetirse. Candidato a tratarse en una sesion
> BIBLIOTECA o de `slep_estado_proyectos_monitoreo`.
