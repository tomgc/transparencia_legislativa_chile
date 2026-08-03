# traspaso_cierre_v13.md

## 1. Identificacion

- **Proyecto:** `transparencia_legislativa_chile`
- **Version:** v13
- **Fecha de cierre:** 2026-07-27
- **Sesion 13.** Foco: cerrar P-22 (el bot del refresh semanal deja de escribir en
  `main`, commitea en rama y abre PR) y saldar la higiene de ramas pendiente desde
  la sesion 9. La sesion abarco tres dias calendario (25, 26 y 27 de julio) porque
  la validacion final espero a la primera corrida desatendida por `schedule`.
- **Entorno:** Positron / macOS, R 4.5.2 (aarch64-apple-darwin20). Ejecucion via
  Claude Code sobre `/Users/tomgc/Projects/transparencia_legislativa_chile` y
  terminal del titular. Modelo: Opus 5.
- **Archivos principales modificados:** `.github/workflows/refresh-semanal.yml`
  (unico archivo de codigo tocado);
  `50_documentacion/activa/backlog_acumulativo.md`,
  `50_documentacion/activa/ESTADO.md`,
  `50_documentacion/traspasos/traspaso_cierre_v12.md` y
  `50_documentacion/estructura/` (cierre de la sesion 12, commiteado en esta).

## 2. Resumen ejecutivo

La sesion abrio con dos hechos de git sin verificar heredados de v12 y los resolvio
por lectura antes de afirmar nada: el commit del `timeout-minutes` si estaba en
produccion (`a045798`), pero el commit de consolidacion del backlog (`a527a95`)
nunca se habia pusheado y el cierre completo de la sesion 12 seguia sin commitear
en el arbol de trabajo. Se cerro y publico esa sesion (`46ed5df`) y recien entonces
se ataco P-22, que llevaba tres sesiones cobrando peaje. Se reescribio el workflow
semanal para que el bot cree una rama `refresh/<corte>`, commitee ahi y abra un PR
contra `main`, conservando sin cambio de semantica el gate de conteos, el commit
condicional, el `git add` acotado y el `timeout-minutes: 30`. El titular decidio
revision manual del PR en vez de automerge. La primera validacion fallo por una
configuracion del repositorio (`Allow GitHub Actions to create and approve pull
requests`, apagada por defecto) que el encargo no habia instrumentado; con el
interruptor activado, una corrida manual desde `main` dejo los cinco criterios en
verde, y dos dias despues la corrida desatendida del lunes 27 produjo
`refresh/2026-07-27` y el PR #2 sin intervencion, que es la prueba definitiva del
pendiente. Se podaron nueve ramas (seis integradas en `main`, tres subsumidas en
otra rama de trabajo) y quedaron cuatro. La sesion registro diez desviaciones del
asistente, cinco de ellas del mismo mecanismo (PAT-01), incluida una posterior a la
adopcion del marcador de fuente S-01 que la hace especialmente informativa para la
cartera.

## 3. Estado al cierre

**Que funciona.** Las tres capas en produccion, servidas desde GitHub Pages. El
refresh semanal automatizado con el flujo nuevo, verificado en corrida desatendida
real (run `schedule` del 2026-07-27, `success`, 11m48s; fuente: `gh run list` del
2026-07-27 09:51). `origin/main` = `15be859` (fuente: `git log --oneline -5
origin/main` del 2026-07-27). `CORTE_FECHA` = `2026-07-25` en el arbol
(`10_utils/10_configuracion.R:41`, fuente: `grep -n '^CORTE_FECHA'` del encargo de
poda); el bot lo reinyecta en cada corrida, de modo que el valor del repo es el del
ultimo PR mergeado, no el del ultimo refresh corrido.

**Que no funciona / que queda abierto.** Nada roto. Un PR de datos abierto sin
revisar: **#2, `refresh/2026-07-27` (`188e8e0`)**, con el corte del lunes (fuente:
`gh pr list --state open` y `ls-remote` del 2026-07-27 09:51). Mientras no se
mergee, `docs/` en produccion sigue con el corte del 25.

**Arbol de trabajo local:** sucio solo por el escaner del cierre (dos snapshots
`20260725_075818_*` borrados por poda, `20260727_094351_*` nuevos, aliases
modificados; fuente: `git status -sb` del 2026-07-27 09:49). Esos archivos, mas los
tres documentos de este cierre, son lo que falta commitear.

**Delta respecto a v12.**

| Dimension | v12 | v13 |
|---|---|---|
| Escrituras del bot | directas a `main` | rama + PR, `main` intacto |
| PRs del repo | ninguno (flujo sin PR) | #1 mergeado, #2 abierto |
| Ramas locales | 11 | 4 |
| Ramas remotas | `origin/main` | `origin/main` + `refresh/2026-07-27` |
| `CORTE_FECHA` | 2026-07-20 | 2026-07-25 |
| Commits sin publicar | 1 (`a527a95`) + cierre sin commitear | ninguno al abrir el cierre de v13 |
| Protocolo vigente | POLITICA v5.2 / SETTINGS v7 | POLITICA v5.4 / SETTINGS v12 |

## 4. Registro detallado de cambios

### 4.1 Cierre y publicacion de la sesion 12

- **Archivos:** `50_documentacion/traspasos/traspaso_cierre_v12.md` (nuevo),
  `50_documentacion/activa/ESTADO.md`, `50_documentacion/activa/backlog_acumulativo.md`,
  `50_documentacion/estructura/`.
- **Categoria tematica:** no aplica (operacion de git, no cambio de producto; ver
  §5 y el precedente de la sesion 9).
- **Que se hizo:** commit `46ed5df` path-scoped a esas cuatro rutas y push que
  arrastro tambien `a527a95`, que llevaba dos dias solo en local.
- **Por que:** SETTINGS §1.2.6 prohibe trabajo de feature sobre arbol sucio, y el
  cron del lunes escribiria sobre `main` en menos de dos dias.
- **Como se verifico:** diff completo de `ESTADO.md` y `backlog_acumulativo.md`
  leido antes de commitear para confirmar que las entradas 1-32 estaban intactas;
  verificador de numeracion corrido antes del commit; `git status` mostrado antes
  del commit; `rev-list --left-right --count` post-push = `0 0`.
- **Tension resuelta:** el conteo pre-push era `2 0` y el encargo asumia `1 0`. El
  criterio de exito estaba escrito sobre el lado derecho (el remoto), que era el
  que importaba, asi que la asimetria no invalido la compuerta. Leccion en §7.

### 4.2 P-22: el bot commitea en rama y abre PR

- **Archivo:** `.github/workflows/refresh-semanal.yml` (unico).
- **Categoria tematica:** automatizacion (entrada 35 del backlog).
- **Que se hizo:** `permissions` suma `pull-requests: write`; el ultimo step pasa
  de "commit y push a `main`" a "crear `refresh/<corte>` desde el HEAD checkouteado,
  commitear, `git push --force origin HEAD:refs/heads/<rama>`, y abrir PR con `gh pr
  create` salvo que ya exista uno abierto para esa rama"; la cabecera documenta el
  motivo, la consecuencia sobre Pages y el porque del force.
- **Por que:** el bot y el trabajo manual competian por `main` desde la sesion 9.
- **Como se verifico:** ver §4.3.
- **Dependencias afectadas:** GitHub Pages ya no republica al terminar el job sino
  al mergear el PR. Es el costo declarado de la revision manual.
- **Tension declarada (C.9 resiliencia vs B.2 simplicidad):** la reconstruccion de
  la rama en cada corrida se resolvio con `--force` acotado por refspec en vez de
  `--force-with-lease` + `fetch`, porque el checkout de Actions es superficial y la
  lease queda mal formada. Es seguro porque la rama es propiedad del bot y nace del
  HEAD de `main` en cada corrida.

### 4.3 Validacion de P-22 en dos etapas

- **Etapa 1 (fallida, 2026-07-25):** corrida manual desde `ci/p22-bot-en-rama`. El
  job llego entero hasta la ultima linea y fallo en `gh pr create` con
  `GraphQL: GitHub Actions is not permitted to create or approve pull requests`.
  `permissions: pull-requests: write` es necesario pero no suficiente: hay un
  interruptor de repositorio apagado por defecto. `main` quedo intacto igual, que
  era el invariante central.
- **Etapa 2 (exitosa, 2026-07-25):** con el interruptor activado y el workflow ya
  mergeado a `main` (`0168446`), corrida manual **desde `main`** con los cinco
  criterios en verde: `main` identico antes y despues
  (`01684465c8e50cee81f494909531ff7a45fc7bf2`), rama reconstruida (`00b6ee1` ->
  `670da69`, con `main` como padre), PR #1 abierto contra `main`, gate OK con todas
  las metricas al alza, y PR data-only (320 archivos, 0 bajo `.github/`).
- **Etapa 3 (desatendida, 2026-07-27):** el cron del lunes corrio solo y produjo
  `refresh/2026-07-27` (`188e8e0`) y el PR #2. Es la unica evidencia que prueba el
  pendiente en su modo de uso real.
- **Decision de disparar desde `main` y no desde la rama de trabajo:** en la etapa 1
  la rama de refresh nacio de `ci/p22-bot-en-rama` y por lo tanto arrastraba el
  cambio del workflow, mezclando dos cambios conceptuales en un PR de datos.
  Disparar desde `main` es lo que hizo el PR data-only.

### 4.4 Poda de ramas

- **Categoria tematica:** no aplica (operacion de git).
- **Que se hizo:** nueve ramas borradas. Seis por integracion en `main`
  (`feat/capa3-asistencia`, `feat/territorio-crosswalk`,
  `explore/contenido-proyectos-votos`, `feature/contenido-legible-trazabilidad`,
  `feature/dashboard-fase2`, `ci/p22-bot-en-rama`, esta ultima tambien en remoto) y
  tres por contencion en otra rama de trabajo (`explore/api-senado` y
  `explore/api-senado-v02` dentro de `explore/api-senado-v02-asistencia`;
  `explore/cobertura-camara` dentro de `explore/diagnostico-proposito`).
- **Como se verifico:** `git cherry -v` contra el `main` vigente en el momento del
  borrado (no contra el inventario del turno anterior), y `--contains` para la
  contencion. Ninguna se borro con `-D`.
- **Estado final:** cuatro locales (`main`, `explore/api-senado-v02-asistencia`,
  `explore/diagnostico-proposito`, `design/contrato-datos`) y dos remotas
  (`origin/main`, `origin/refresh/2026-07-27`).

### 4.5 Publicacion de la ola canonica S-01

`15be859` (`docs(canonico): propaga ola S-01`) llego al repo desde una sesion
BIBLIOTECA de cartera y estaba sin pushear. Se publico en esta sesion. Actualiza
las copias de `50_documentacion/activa/` a POLITICA v5.4 y SETTINGS v12. **No es un
cambio de producto de este proyecto** y no entra al backlog.

**Consecuencia de protocolo, importante para la proxima sesion:** las fases A a D
de esta sesion se ejecutaron contra POLITICA v5.2 y SETTINGS v7 (lo que exponia la
knowledge base al abrir). El cierre si se redacto contra v5.4 y v12, leidas al
final. Las diferencias que afectan a este traspaso: POLITICA §0.6 (marcador de
fuente en linea) y SETTINGS §1.2.6 (su contrato completo), §2.2.15 (diez campos, no
siete, y etiquetas `PAT-NN` en vez de taxonomia local) y §2.2.17 (registro de
fricciones).

### 4.6 Registro de ejecucion detallado

Esta sesion no produjo log de Claude Code en `50_documentacion/andamios/logs/`: los
encargos fueron cortos y su evidencia vive en los reportes del chat y en los
criterios verificados que este traspaso reproduce. Se declara para que una sesion
futura no busque un archivo inexistente.

## 5. Backlog acumulativo

Vive en `50_documentacion/activa/backlog_acumulativo.md` (archivo canonico, POLITICA
§10). **Delta de esta sesion:** 1 entrada nueva (35), `automatizacion` 2->3, suma de
la columna 35->36, porcentajes recalculados sobre 36. Sin categorias nuevas, sin
renumeracion ni reescritura de entradas 1-34. Verificacion programatica del archivo
actualizado: 35 entradas, maximo 35, sin huecos ni duplicados (fuente: recuento
sobre el archivo entregado en esta sesion).

**Lo que NO se conto**, declarado para evitar duplicacion futura: la poda de ramas y
los pushes son operaciones de git (precedente de la sesion 9); el merge del PR #1 es
una corrida rutinaria del refresh ya automatizado; y `15be859` publica trabajo de
otra sesion.

**Discrepancia heredada, sigue abierta:** la columna de la clasificacion tematica
suma 36 contra 35 entradas numeradas. Mismo signo y misma unidad que arrastra desde
antes de v06. No se corrige en silencio.

## 6. Bugs de la sesion

**Ninguno.** No se detecto ni corrigio ningun bug de codigo del proyecto. El unico
fallo de ejecucion (etapa 1 de la validacion de P-22) fue una precondicion de
configuracion del repositorio, no un defecto del pipeline ni del YAML: el mismo
archivo, sin cambios, funciono al reintentar con el interruptor activado. Los diez
registros de desviacion de esta sesion son del asistente y viven en §15.

## 7. Aprendizajes y restricciones descubiertas

- **A44. `permissions` del YAML no basta para que Actions abra PRs.** Existe un
  interruptor de repositorio (`Settings -> Actions -> General -> Workflow
  permissions -> Allow GitHub Actions to create and approve pull requests`) apagado
  por defecto. Es legible por API:
  `gh api repos/<owner>/<repo>/actions/permissions/workflow` devuelve
  `can_approve_pull_request_reviews`. **Regla:** toda precondicion binaria y
  consultable por API se instrumenta como compuerta del encargo, no se enuncia como
  instruccion al titular. Principio: B.1 y GR-03.
- **A45. `gh pr diff --name-only` falla sobre PRs de mas de 300 archivos**
  (`HTTP 406: PullRequest.diff too_large`), y al fallar dentro de un pipe deja al
  `grep -c` contando sobre vacio, que devuelve `0`: el mismo valor que el criterio de
  exito esperaba. **Regla:** un chequeo cuyo modo de fallo produce el valor de exito
  no es un chequeo. Todo criterio de conteo declara tambien el denominador. El
  reemplazo verificado es
  `gh api repos/<owner>/<repo>/pulls/<n>/files --paginate --jq '.[].filename'`.
  Principio: B.4 y GR-02.
- **A46. `git cherry -v <upstream> <rama>` y `git branch -d <rama>` responden
  preguntas distintas.** `cherry` compara patch-ids contra el upstream que se le
  pasa; `-d` comprueba ancestria contra `HEAD` o contra el upstream configurado de
  la rama, y no acepta `--merged` (es filtro de modo lista; `git branch -d --merged X
  A` sale con error de uso). Para borrar una rama contenida en otra rama de trabajo
  sin apagar la comprobacion, poner `HEAD` en la rama superior y borrar desde ahi.
  Principio: C.11.
- **A47. El exit code de un pipe lo da el ultimo comando.** Leer el resultado de un
  run de Actions del `exit 0` de un `gh run watch | tail` reporta exito sobre un job
  fallido. **Regla:** el resultado se lee de la fuente autoritativa
  (`gh run view <id> --json conclusion`), nunca de un proxy. Principio: B.4.
- **A48. Las llaves son metacaracteres en BRE.** `grep -n 'refresh/${CORTE}'`
  devuelve vacio sobre un archivo que si contiene la cadena; `grep -F` la encuentra.
  Un grep vacio no distingue "no esta" de "el patron esta mal escrito". **Regla:**
  todo grep de verificacion sobre cadenas con `{}`, `$`, `[]` o `*` usa `-F`, o
  declara por que no.
- **A49. Un marcador de fuente no valida el alcance de la fuente.** En esta misma
  sesion se afirmo, con marcador correctamente puesto, que el escaner mostraba
  insumos `20260727_*.rds`; el marcador citaba un `grep -o` sobre el archivo entero,
  donde `20260727` aparecia solo como nombre del snapshot del propio escaner. La
  afirmacion era falsa y el marcador estaba presente. **Regla:** cuando la
  afirmacion es sobre una seccion de un archivo, el comando citado debe estar acotado
  a esa seccion. Es materia de la proxima revision del contrato S-01 (ver §15).

## 8. Decisiones de diseno

**D15. Revision manual del PR del bot, no automerge.**
*Alternativas:* (a) automerge condicionado al gate de conteos, que mantiene la
frescura del dato sin intervencion; (b) revision manual del titular.
*Decision:* (b), tomada por el titular.
*Justificacion:* el problema que P-22 resuelve es que `main` se mueva sin
conocimiento del titular; el automerge lo reintroduce con mas pasos intermedios.
Ademas el gate de conteos detecta cambios de volumen, no cambios de sentido.
*Implicancia:* la frescura de `docs/` en produccion pasa a depender de la cadencia
de revision. Si el titular no revisa, los PRs se acumulan sin colisionar (una rama
por corte), pero el dato publicado envejece.

**D16. Rama `refresh/<corte>` con push forzado acotado por refspec.**
*Alternativas:* (a) nombre unico por corrida (`refresh/<corte>-<run_id>`), sin
colisiones pero con acumulacion de ramas; (b) `refresh/<corte>` con
`--force-with-lease`; (c) `refresh/<corte>` con `--force` acotado por refspec.
*Decision:* (c).
*Justificacion:* el checkout de Actions es superficial y la lease de (b) queda mal
formada sin un `fetch` extra; (a) acumula ramas sin aportar seguridad real. La rama
es propiedad del bot y se reconstruye desde el HEAD de `main` en cada corrida, asi
que forzarla es la semantica correcta y no puede perder trabajo humano. El refspec
`HEAD:refs/heads/refresh/<corte>` deja `main` fuera del alcance del force por
construccion, no por disciplina.
*Implicancia:* una re-corrida el mismo dia actualiza el PR abierto en vez de abrir
un segundo, que es el comportamiento deseado.

**D17. La validacion de un cambio de workflow se dispara desde `main`, no desde la
rama de trabajo.**
*Justificacion:* la rama de datos nace del HEAD del ref que dispara. Disparando
desde la rama de trabajo, el PR de datos arrastra tambien el cambio de
infraestructura y mezcla dos cambios conceptuales. Esto obliga a mergear el cambio
de workflow ANTES de la validacion definitiva, lo que parece invertido pero es
correcto: el YAML se prueba primero en una corrida desde la rama (que valida la
mecanica) y despues en una desde `main` (que valida el producto).

## 9. Constantes y parametros vigentes (por delta)

| Constante | Valor | Archivo | Nota |
|---|---|---|---|
| `CORTE_FECHA` | `2026-07-25` | `10_utils/10_configuracion.R:41` | **Cambio.** Era `2026-07-20`. Lo reinyecta el bot en cada corrida via `sed` sobre la unica linea de asignacion; el valor del repo es el del ultimo PR mergeado |
| `timeout-minutes` | `30` | `.github/workflows/refresh-semanal.yml` | Sin cambio (entrada 33) |
| `permissions` | `contents: write` + `pull-requests: write` | idem | **Nuevo.** El segundo es necesario y no suficiente (A44) |
| rama del bot | `refresh/<corte>` | idem | **Nueva** |
| cron | `0 11 * * 1` | idem | Sin cambio. 11:00 UTC = 07:00 Chile |

El resto de las constantes del proyecto no cambio; viven en v11 §9 y en
`CLAUDE.md`.

## 10. Arquitectura de archivos

Escaner al cierre: `50_documentacion/estructura/estructura_actual.md`, snapshot
`20260727_094351` (23 carpetas, 469 archivos; fuente: cabecera del propio escaner).
La estructura no cambio: el unico archivo de codigo tocado vive en `.github/`, que
el escaner no cubre por ser carpeta oculta (POLITICA §7.2). Desviaciones vigentes
contra la estructura canonica, todas declaradas como deuda heredada y ninguna
accionable en esta sesion:

1. `30_procesamiento/` parte en `32_` porque `31_explorar_api_camara.R` vive en
   `andamios/`. Hueco correlativo interno, no entre decenas.
2. `tests/` no existe (confirmado por `ls` en esta sesion). Pendiente de decision
   explicita del titular.
3. `50_documentacion/andamios/design_handoff_portal_transparencia/Portal
   Transparencia.dc.html` lleva espacio y mayusculas, contra POLITICA §2. **Se
   declara como excepcion permanente**, no como deuda a saldar: la carpeta es un
   andamio congelado (POLITICA §1.3.7 y §1.6, las rutas internas de un andamio no se
   reescriben jamas) y el `README.md` de esa misma carpeta lo referencia tres veces.
   Renombrarlo obligaria a editar un registro historico congelado. La auditoria de
   cierre #8 pasa a "si, con excepcion declarada".

## 11. Pendientes y ruta sugerida

### 11.1 Inventario

**P-46. Mergear el PR #2 (corte del 2026-07-27).**
*Contexto:* abierto por la corrida desatendida del lunes; `main` sigue con el corte
del 25. *Tipo:* funcionalidad (operacion rutinaria). *Impacto:* alto sobre la
frescura del dato publicado, nulo sobre el codigo. *Dependencias:* ninguna.
*Complejidad:* baja. *Precauciones:* revisar el resumen de conteos del cuerpo del PR
antes de mergear; caidas o saltos anomalos son la senal que el gate no cubre.
*Enfoque:* `gh pr merge 2 --rebase --delete-branch`. *Criterio de exito:* `origin/main`
con el commit de datos y Pages republicado.

**P-47. Frontend de la Capa 3 (asistencia simetrica).**
*Contexto:* el dato nominal y la justificacion estan en el JSON desde la sesion 11;
el dashboard aun no los muestra. *Tipo:* funcionalidad. *Impacto:* es el trabajo
grande pendiente del producto. *Dependencias:* decidir P7 (como presentar dos
ambitos sin inducir comparaciones invalidas) y la glosa de `sin_registro`, que no se
imputa. *Complejidad:* alta. *Principios:* B.1 (la decision de presentacion es
metodologica, no estetica), A19 (referencia aprobada antes de iterar). *Precauciones:*
el contrato legacy sigue vivo mientras el portal lo consuma; no retirarlo antes.
*Criterio de exito sugerido:* la vista de perfil muestra los dos ambitos con su glosa
y ningun numero publicado cambia de valor respecto del JSON.

**P-48. Retiro del contrato legacy de asistencia.** *Tipo:* deuda tecnica con
vencimiento. *Dependencias:* encadena a P-47, nunca antes. *Complejidad:* media.

**P-49. Decision explicita sobre `tests/`.** *Contexto:* confirmado inexistente. El
protocolo admite el "no" declarado; lo que no admite es la omision silenciosa.
*Tipo:* deuda heredada. *Complejidad:* nula (es una decision, no trabajo).

**P-50. `actions/checkout@v4` -> `@v5`.** *Contexto:* el run emite
`Node.js 20 is deprecated ... forced to run on Node.js 24`. No rompe nada hoy.
*Tipo:* higiene. *Complejidad:* baja. *Precaucion:* cualquier cambio al workflow se
valida con una corrida real, no solo con parseo de YAML (leccion de esta sesion).

**P-51. Discrepancia aritmetica del backlog (columna 36 vs 35 entradas).** *Tipo:*
deuda de memoria. *Precaucion:* exige reclasificar alguna entrada 1-23 con nota
explicita; prohibido corregir en silencio.

**P-52. Auditoria de apertura #3 sin verificar** (paquetes, rutas y constantes al
inicio de cada script). *Tipo:* deuda heredada. *Enfoque:* resolver en la sesion que
toque el `33` o el `39`, leyendo el codigo.

**P-53. Capa 4** (P-13, P-7, P-9, P-10 del inventario historico). *Tipo:* decision de
alcance, sin tomar.

**P-54. Revision del contrato S-01 en sesion de cartera.** *Contexto:* ver §15. El
marcador de fuente se adopto el 2026-07-25 y en esta sesion se produjo una
afirmacion falsa **con marcador presente y bien formado**. *Tipo:* gobernanza de
cartera, fuera de este proyecto. *Enfoque:* llevarlo a
`slep_estado_proyectos_monitoreo` con la evidencia de §15.

### 11.2 Evaluacion de deuda tecnica

Zona fragil unica: el workflow semanal es ahora el punto de contacto entre la
automatizacion y produccion, y su unica prueba es una corrida real de ~11 minutos
contra la API de la Camara. No hay forma barata de probarlo. Mitigacion vigente: el
gate de conteos y el hecho de que un fallo ya no puede tocar `main`. Oportunidad de
mejora: no hay ninguna que justifique tocarlo ahora; el flujo lleva una corrida
desatendida exitosa y conviene acumular evidencia antes de refactorizar.

### 11.3 Auditoria de cierre (POLITICA 5.6)

| # | Pregunta | Respuesta |
|---|---|---|
| 2 | ¿El pipeline corre de cero sin intervencion manual? | **Si.** La corrida desatendida del 27 lo prueba end to end (con la salvedad heredada A34 para corridas locales parciales) |
| 5 | ¿Cada transformacion critica tiene check de validacion? | **Si**, sin cambio: el gate de conteos cubre el unico paso que esta sesion toco |
| 6 | ¿Los outputs son reproducibles e idempotentes? | **Si.** La corrida del 25 y la del 27 produjeron ramas distintas sobre el mismo mecanismo, sin residuo |
| 7 | ¿Decisiones metodologicas como constantes nombradas? | **Si**, sin cambio en esta sesion |
| 8 | ¿Nombres sin tildes, ñ ni espacios? | **Si, con una excepcion declarada** (§10, punto 3) |

Ninguna respuesta "no": no se agregan pendientes por esta via.

### 11.4 Ruta sugerida para la sesion 14

1. **P-46** (mergear el PR #2). Diez minutos, desbloquea la frescura del dato.
   *Criterio:* Pages con el corte del 27.
2. **P-47** (frontend de la Capa 3), sesion dedicada. Es prioridad 1 real por los
   criterios de 1.2.4: no hay bugs ni bloqueantes, y es la funcionalidad de mayor
   valor pendiente. *Criterio:* el definido arriba.
3. **P-49 y P-50** encadenables al final si sobra sesion (decision + higiene).

**Conviene diferir:** P-48 (encadena a P-47), P-51, P-52, P-53 y P-54. Ninguno
bloquea nada y todos compiten por el foco del frontend.

## 12. Instrucciones especificas para la proxima sesion

- ⚠️ **NO** afirmar el estado de `CORTE_FECHA` sin leer `10_utils/10_configuracion.R`:
  el bot lo reescribe en cada corrida y cada merge de PR lo cambia en `main`.
- ⚠️ **NO** mergear un PR del bot sin leer el resumen de conteos de su cuerpo: el
  gate detecta caidas de volumen, no cambios de sentido.
- ⚠️ **NO** usar `gh pr diff --name-only` sobre PRs de este proyecto (A45); usar la
  API paginada de `/pulls/<n>/files` y declarar el denominador.
- ⚠️ **NO** disparar el workflow por `workflow_dispatch` para comprobar algo que se
  puede leer por API: cada corrida cuesta ~11 minutos y golpea la API de la Camara.
- ✅ **ANTES** de cualquier corrida local, regenerar 32-36 (A34).
- ✅ **ANTES** de tocar el workflow, leer el archivo completo: es el unico mecanismo
  automatico que escribe hacia produccion.
- ✅ **ANTES** de afirmar que algo aparece o no en el escaner, acotar el grep a la
  seccion sobre la que se afirma (A49).
- ✅ **ANTES** de borrar una rama, `git cherry -v` contra el `main` vigente en ese
  momento, no contra un inventario de un turno anterior.
- 🔒 El gate de conteos aborta el job sin publicar rama ni PR. Intocable.
- 🔒 El commit condicional: sin cambios, sin rama y sin PR. Intocable.
- 🔒 `main` no recibe escrituras automaticas del bot. Es el objeto entero de P-22.
- 🔒 El `--force` del workflow vive acotado por refspec a `refresh/*`. Nunca a `main`.
- 🔒 Campos legacy de `asistencia` e indice congelados mientras el portal los
  consuma. Rebajas publicadas pero fuera de toda formula mientras P2 siga abierta.
  `sin_registro` no se imputa. Territorio como insumo estatico auditado. El backlog
  nunca se renumera.

## 13. Fragmentos de codigo de referencia

Solo lo nuevo o corregido en esta sesion. Los patrones estables viven en `CLAUDE.md`
y en v11 §13.

**Verificador de numeracion del backlog (corrige el fragmento de v12 §13, que estaba
defectuoso).** El patron de v12 extraia bien el numero pero no filtraba los anos, y
la linea de prosa `2026. Fase 1 cubre solo la Camara...` lo hacia reportar 35
entradas, maximo 2026 y ~1991 huecos falsos sobre un archivo correcto. v12 no se
edita (D13); la correccion viaja hacia adelante:

```r
ruta   <- here::here("50_documentacion", "activa", "backlog_acumulativo.md")
x      <- readLines(ruta, warn = FALSE)
lineas <- grep("^(\\*\\*)?[0-9]+\\.", x, value = TRUE)
n      <- as.integer(sub("^(\\*\\*)?([0-9]+)\\..*$", "\\2", lineas))
n      <- n[n < 1900]   # descarta "2026. Fase 1 cubre..." (prosa, no entrada)
cat("entradas:", length(n), "| max:", max(n),
    "| huecos:", paste(setdiff(seq_len(max(n)), n), collapse = ","),
    "| duplicados:", paste(n[duplicated(n)], collapse = ","), "\n")
```

**Verificar que un PR del bot es data-only** (reemplaza `gh pr diff --name-only`,
que rompe sobre 300 archivos; A45):

```bash
gh api repos/tomgc/transparencia_legislativa_chile/pulls/<n>/files \
  --paginate --jq '.[].filename' > /tmp/pr_files.txt
echo "total: $(wc -l < /tmp/pr_files.txt)"          # denominador, obligatorio
echo "en .github/: $(grep -c '^\.github/' /tmp/pr_files.txt)"   # esperado 0
```

**Leer el resultado de un run de Actions de la fuente autoritativa** (A47):

```bash
gh run view <run_id> --json conclusion,headBranch --jq '{conclusion,headBranch}'
```

**Compuerta del interruptor de PRs de Actions** (A44):

```bash
gh api repos/tomgc/transparencia_legislativa_chile/actions/permissions/workflow
# leer can_approve_pull_request_reviews; false => la corrida fallara en gh pr create
```

**Borrar una rama contenida en otra rama de trabajo sin apagar la comprobacion**
(A46; `-d` compara contra `HEAD`, y `--merged` no es combinable con `-d`):

```bash
git -C <raiz> checkout <rama_superior>
git -C <raiz> branch -d <rama_inferior>
git -C <raiz> checkout main
```

## 14. Reapertura

**Mensaje de apertura pre-armado:**

> Tipo: CONTINUATION. El protocolo (`POLITICA_PROYECTO.md` v5.4,
> `SETTINGS_Y_PROMPTS_OPERACIONALES.md` v12) vive en la knowledge base del Project y
> se lee desde ahi; verifica que esten en esas versiones, porque la sesion 13 abrio
> contra v5.2 y v7 y eso obligo a rehacer el cierre. Estado: las tres capas en
> produccion, P-22 cerrado y probado en corrida desatendida (`refresh/2026-07-27` y
> PR #2 abiertos por el cron del lunes sin intervencion), nueve ramas podadas,
> `origin/main` en `15be859` mas lo que agregue el cierre de la s13. El PR #2 sigue
> abierto: mergearlo es lo primero. `CORTE_FECHA` cambia con cada merge de PR del
> bot, asi que confirmalo en `10_utils/10_configuracion.R` antes de afirmarlo. El
> foco propuesto es P-47, el frontend de la Capa 3 de asistencia (dos ambitos, glosa
> de `sin_registro`, decision P7), en sesion dedicada. Adjunto:
> `traspaso_cierre_v13.md`, `estructura_actual.md`.

**Documentos para la sesion 14:**

1. *Protocolo en knowledge base* (NO adjuntar; verificar que este al dia):
   `POLITICA_PROYECTO.md` v5.4, `SETTINGS_Y_PROMPTS_OPERACIONALES.md` v12.
2. *Opcionales segun el foco real:* `CLAUDE.md` si el trabajo corre en Claude Code;
   `docs/index.html` y `20260725_capa3_asistencia_log.md` si se aborda P-47 (son los
   archivos que se van a leer y reescribir, imprescindibles en ese caso);
   `10_utils/10_configuracion.R` para el valor vigente de `CORTE_FECHA`;
   `backlog_acumulativo.md` solo si se aborda P-51;
   `encargo_autonomo_claude_code_v1.md` si el frontend se delega a Claude Code.
3. *Si se adjuntan:* `traspaso_cierre_v13.md`; `estructura_actual.md`.

**Nota final obligatoria:** si algun archivo listado cambio entre sesiones, adjuntar
la version mas actualizada al abrir y avisarlo en el mensaje de apertura. En
particular, `10_utils/10_configuracion.R` habra cambiado si se mergeo el PR #2.

## 15. Errores del asistente (POLITICA 0.5, SETTINGS §2.2.15)

Diez registros: nueve del asistente conversacional, uno de Claude Code. Formato de
diez campos (SETTINGS v12). Etiquetas del catalogo
`herramientas_dev/gobernanza/catalogo_patrones_errores_v2.md`.

**Nota de traduccion de taxonomia.** Durante la sesion estos errores se etiquetaron
con la taxonomia local del proyecto (`A21` y sus variantes) porque la sesion operaba
contra SETTINGS v7. Al cerrar contra v12 se traducen a `PAT-NN`. La numeracion
ordinal que se emitio en el chat ("undecima ocurrencia", "decimoquinta") **no es
confiable**: se asigno de memoria, se repitio un ordinal y no se reconcilio contra
v12 §15. Se descarta y no se propaga; el conteo por patron vive en el catalogo de
cartera, no aqui. Ese descarte es el registro E-13-08.

---

**E-13-01**

| Campo | Contenido |
|---|---|
| `momento` | Fase B de la apertura, auditoria #8 |
| `disparador` | asistente lo señalo espontaneamente |
| `que_paso` | Propuso renombrar `Portal Transparencia.dc.html` por la regla de naming, sin cruzarla con el regimen de la carpeta que lo contiene (andamio congelado) |
| `regla_violada` | POLITICA §1.3.7 y §1.6 (los andamios se congelan; sus rutas no se reescriben); §2 (excepcion declarada para heredados) |
| `causa_raiz` | Evaluo el nombre contra la regla de nomenclatura de forma aislada. La politica se habia leido completa en la Fase A, asi que no fue falta de fuente: fue falta de traslado de una restriccion leida al diseno de la propuesta |
| `salvaguarda_presente` | POLITICA (tres secciones del mismo documento) |
| `patron` | PAT-07, sobre regimen de carpeta no propagado a una propuesta de renombre |
| `gatillo_observable` | `restriccion-no-propagada`: proponer una accion sobre un archivo bajo `andamios/` sin citar el regimen de congelamiento |
| `intentos_previos` | 0 |
| `costo` | ninguno (la precaucion del `grep` acompañaba la propuesta y la desarmo antes de ejecutarla) |

**E-13-02**

| Campo | Contenido |
|---|---|
| `momento` | Encargo de cierre de la s12, Fase 1 |
| `disparador` | usuario lo corrigio (via el reporte de Claude Code) |
| `que_paso` | Prescribio un verificador de numeracion cuyo patron matchea prosa (`2026. Fase 1 cubre...`), reportando 35 entradas, maximo 2026 y ~1991 huecos falsos sobre un backlog correcto |
| `regla_violada` | SETTINGS §1.2.6 (generar-verificar-consumar); A42 del propio proyecto (probar el verificador contra una linea real antes de prescribirlo) |
| `causa_raiz` | Copio el fragmento canonico de v12 §13 confiando en su etiqueta de "forma correcta". La procedencia canonica del fragmento fue la razon activa de no probarlo: un artefacto sellado por el corpus se trato como verificado |
| `salvaguarda_presente` | SETTINGS + traspaso v12 §7 y §12 (A42 enunciada dos veces) |
| `patron` | PAT-01, sobre instrumento heredado del corpus no probado |
| `gatillo_observable` | `encargos-premisas`: prescribir un verificador con regex sin haberlo corrido contra una linea real del archivo destino |
| `intentos_previos` | 0 |
| `costo` | un turno de diagnostico del ejecutor; el fragmento defectuoso queda en v12 §13 y solo se corrige hacia adelante |

**E-13-03**

| Campo | Contenido |
|---|---|
| `momento` | Mismo encargo, redaccion de la regla de detencion de la Fase 1 |
| `disparador` | asistente lo señalo espontaneamente al leer el reporte |
| `que_paso` | Escribio "si difiere, DETENTE" para una verificacion cuyo fallo podia ser del propio instrumento, contradiciendo D14 del traspaso v12 |
| `regla_violada` | Traspaso v12 §8, D14 (los errores de instrumento del asistente no son causal de detencion del ejecutor) |
| `causa_raiz` | Redacto la regla de detencion desde la forma generica de la plantilla de encargo, sin cruzarla con la decision vigente que gobierna ese escenario exacto y que se habia leido en la Fase A |
| `salvaguarda_presente` | traspaso v12 (adjunto y leido en esta sesion) |
| `patron` | PAT-07, sobre decision de proceso no propagada a la regla de detencion |
| `gatillo_observable` | `restriccion-no-propagada`: escribir una regla de detencion generica existiendo una decision del traspaso sobre ese mismo caso |
| `intentos_previos` | 0 |
| `costo` | ninguno (el ejecutor aplico D14 correctamente por su cuenta) |

**E-13-04**

| Campo | Contenido |
|---|---|
| `momento` | Encargo de re-validacion, Fase 0 |
| `disparador` | usuario lo señalo sin nombrarlo error (via el reporte del ejecutor) |
| `que_paso` | Prescribio `grep -n 'refresh/${CORTE}'` sin `-F`; las llaves son metacaracteres en BRE y el grep salio vacio sobre un archivo que si contenia la linea |
| `regla_violada` | SETTINGS §1.2.6 (ningun comando asume el entorno: sintaxis del binario destino) |
| `causa_raiz` | Escribio el patron desde la forma del texto buscado, sin considerar como lo interpreta la herramienta. Segundo instrumento mal probado en la misma sesion, despues de E-13-02 |
| `salvaguarda_presente` | SETTINGS |
| `patron` | PAT-03, subfamilia entorno de la maquina destino (sintaxis) |
| `gatillo_observable` | `comando-entorno`: emitir un grep de verificacion sobre una cadena con metacaracteres sin `-F` |
| `intentos_previos` | 1 (E-13-02, mismo mecanismo de instrumento no probado, en el turno anterior) |
| `costo` | un paso de diagnostico del ejecutor; casi produce un falso "archivo faltante" que habria detenido el encargo |

**E-13-05**

| Campo | Contenido |
|---|---|
| `momento` | Encargo de validacion de P-22, Fase 0 |
| `disparador` | usuario lo corrigio (el job fallo y el ejecutor diagnostico la causa) |
| `que_paso` | Puso la activacion del interruptor de Actions como instruccion en prosa al titular en vez de como compuerta verificable del encargo, existiendo API para leerlo |
| `regla_violada` | `encargo_autonomo_claude_code_v1.md` §2.1 (contrato de entorno: toda precondicion verificada EN ese entorno); SETTINGS §1.2.6 |
| `causa_raiz` | Trato una precondicion binaria y consultable como tarea derivada al titular, y dio por cumplido su cumplimiento al haberla comunicado. Comunicar una precondicion no es verificarla |
| `salvaguarda_presente` | encargo_autonomo + SETTINGS |
| `patron` | PAT-01, sobre premisa de encargo dada por cumplida al haberla comunicado |
| `gatillo_observable` | `encargos-premisas`: emitir un encargo cuya viabilidad depende de un estado remoto consultable por API sin leerlo en la Fase 0 |
| `intentos_previos` | 0 |
| `costo` | una corrida real de 11m25s contra la API de la Camara, desperdiciada, mas un ciclo completo de encargo y reporte |

**E-13-06**

| Campo | Contenido |
|---|---|
| `momento` | Encargo de re-validacion, criterio de exito 5 |
| `disparador` | asistente lo señalo espontaneamente tras el reporte del ejecutor |
| `que_paso` | Prescribio `gh pr diff --name-only \| grep -c '^\.github/'`, que sobre PRs de mas de 300 archivos falla con HTTP 406 y deja al `grep` contando sobre vacio: devuelve `0`, exactamente el valor de exito esperado |
| `regla_violada` | SETTINGS §1.2.6 (generar-verificar-consumar: el paso de verificacion debe condicionar el consumidor) y B.4 (criterio contrastable) |
| `causa_raiz` | Derivo el comando de la forma general del problema sin considerar la escala real del artefacto, que el propio proyecto documenta (155 perfiles duplicados en `docs/data` y `40_salidas/json`). No se pregunto que devuelve el chequeo cuando falla |
| `salvaguarda_presente` | SETTINGS |
| `patron` | PAT-02, sobre chequeo cuyo modo de fallo produce el valor de exito. Mecanismo secundario PAT-03 (limite de 300 archivos de la API destino, no verificado) |
| `gatillo_observable` | `encargos-premisas`: declarar un criterio de conteo sin denominador, de modo que `0 de 0` y `0 de 320` sean indistinguibles |
| `intentos_previos` | 0 |
| `costo` | ninguno material (el ejecutor lo cazo y re-midio por dos vias); el riesgo evitado era publicar un falso verde sobre gobernanza de un PR |

**E-13-07**

| Campo | Contenido |
|---|---|
| `momento` | Encargo de poda de ramas, Fase 3 |
| `disparador` | usuario lo corrigio (los tres `-d` fueron rechazados y el ejecutor diagnostico) |
| `que_paso` | Prescribio `git branch -d` contra `main` para tres ramas contenidas en otra rama de trabajo, no en `main` |
| `regla_violada` | SETTINGS §1.2.6 (ningun comando asume el entorno; semantica del binario destino) |
| `causa_raiz` | Trato `git cherry -v <superior> <inferior>` y `git branch -d` como si respondieran la misma pregunta. La verificacion de contencion era correcta; el instrumento de borrado comprobaba otra cosa |
| `salvaguarda_presente` | SETTINGS |
| `patron` | PAT-01, sobre premisa acerca de la semantica de un comando |
| `gatillo_observable` | `encargos-premisas`: prescribir un borrado cuya comprobacion interna no es la misma que la verificacion previa realizada |
| `intentos_previos` | 0 |
| `costo` | un turno; tres borrados rechazados. Ademas el remedio propuesto por el ejecutor (`branch -d --merged X A`) tampoco era valido, y hubo que probarlo empiricamente antes de emitirlo |

**E-13-08**

| Campo | Contenido |
|---|---|
| `momento` | A lo largo de la sesion, en los registros provisionales del chat |
| `disparador` | asistente lo señalo espontaneamente al redactar el cierre |
| `que_paso` | Emitio ordinales de reincidencia ("undecima ocurrencia", "decimoquinta") desde memoria, asignando el mismo ordinal dos veces y sin reconciliar contra v12 §15 |
| `regla_violada` | POLITICA §0.6 y SETTINGS §1.2.6, tipo 3 (toda cifra o conteo comunicado lleva marcador y admite solo recuento programatico del mismo turno) |
| `causa_raiz` | La regla estaba adoptada en el repo (`15be859`) pero no en la knowledge base que la sesion leyo al abrir, y el habito de la taxonomia local del proyecto (`A21`) invitaba a contar ordinalmente sin fuente |
| `salvaguarda_presente` | POLITICA v5.4 + SETTINGS v12 (vigentes en el repo desde el 2026-07-25, no en la knowledge base al abrir la sesion) |
| `patron` | PAT-01, sobre cifra ordinal emitida desde memoria |
| `gatillo_observable` | `cifras-datos`: comunicar un ordinal de reincidencia sin recuento programatico contra el registro previo |
| `intentos_previos` | 0 |
| `costo` | la numeracion ordinal del chat queda inutilizable y se descarta en este traspaso |

**E-13-09**

| Campo | Contenido |
|---|---|
| `momento` | Turno previo al cierre, al pedir el estado de git del lunes |
| `disparador` | asistente lo señalo espontaneamente al verificar |
| `que_paso` | Afirmo que el escaner traia insumos `20260727_*.rds`, **con marcador de fuente presente y bien formado**; el `grep -o` citado barria el archivo entero y `20260727` aparecia solo como nombre del snapshot del propio escaner (linea 310) |
| `regla_violada` | POLITICA §0.6 y SETTINGS §1.2.6 (el marcador exige una fuente que sostenga la afirmacion emitida) |
| `causa_raiz` | El comando citado era real y se ejecuto en la sesion, pero su alcance era mas amplio que el de la afirmacion. El slot se lleno correctamente y aun asi la afirmacion resulto falsa: el marcador hace observable la omision de fuente, no la falta de correspondencia entre fuente y afirmacion |
| `salvaguarda_presente` | POLITICA v5.4 §0.6 + SETTINGS v12 §1.2.6 (leidas en este mismo cierre, es decir, con la regla ya en contexto) |
| `patron` | PAT-01, sobre fuente citada de alcance mayor que la afirmacion |
| `gatillo_observable` | `afirmar-sin-leer`: afirmar sobre una seccion de un archivo citando un comando no acotado a esa seccion |
| `intentos_previos` | 0 |
| `costo` | un turno; indujo ademas una hipotesis equivocada sobre el estado del refresh del lunes |

**E-13-10 (Claude Code)**

| Campo | Contenido |
|---|---|
| `momento` | Validacion de P-22, espera del run |
| `disparador` | asistente ejecutor lo señalo espontaneamente y se corrigio en el mismo turno |
| `que_paso` | Reporto "el job paso" leyendo el `exit 0` de un pipe cuyo estado lo daba el `tail`, no `gh run watch`; el run habia terminado en `failure` |
| `regla_violada` | SETTINGS §1.2.6 (generar-verificar-consumar; el resultado se lee de la fuente autoritativa) |
| `causa_raiz` | Uso un proxy (exit code de un pipe) en lugar del campo autoritativo (`--json conclusion`), sin advertir que el pipe reasigna el estado |
| `salvaguarda_presente` | SETTINGS |
| `patron` | PAT-01, sobre resultado de ejecucion leido de un proxy |
| `gatillo_observable` | `afirmar-sin-leer`: reportar la conclusion de un run desde el exit code de un pipe |
| `intentos_previos` | 0 |
| `costo` | un turno de reporte incorrecto, corregido antes de que el titular actuara sobre el |

---

### Analisis de patron y clasificacion §2.2.16

**PAT-01 concentra cinco de los diez registros** (E-13-02, 05, 07, 08, 09) y aparece
ademas como mecanismo del unico error del ejecutor (E-13-10). Consistente con su
43,5% en el corpus de la cartera. Los cinco comparten un mecanismo mas fino que
"afirmar sin fuente primaria": **tratar como verificado un artefacto o un estado por
su procedencia** (un fragmento sellado como canonico, una precondicion comunicada al
titular, la semantica supuesta de un comando, un ordinal recordado, una fuente de
alcance mayor que la afirmacion).

**Clasificacion de la falla (SETTINGS §2.2.16), para la sesion de cartera y no para
legislar aqui:** E-13-09 es el registro decisivo y **no es de disciplina**. El slot
S-01 estaba disponible, se aplico, y la afirmacion salio falsa igual. Es una falla de
**forma del output**: el contrato define que el marcador debe existir y cuales son sus
dos formas legales, pero no define que la fuente citada deba estar **acotada al
alcance de la afirmacion**. La correccion adecuada, por lo tanto, no es endurecer la
prohibicion ni repetir la regla: es ampliar el contrato del marcador con una
condicion de correspondencia (si la afirmacion es sobre una seccion, el comando
citado se acota a esa seccion). Endurecer S-01 sin esa ampliacion contaria como
reformulacion fallida en el proximo ciclo.

Este hallazgo es material para la cartera porque S-01 se adopto el 2026-07-25 y
E-13-09 es de las primeras evidencias prospectivas de su comportamiento real. Ver
P-54.

### Fricciones (SETTINGS §2.2.17)

- `friccion: la respuesta a un reporte largo del ejecutor no dejo ver que se habia leido entero ("esto lo leiste?") → los turnos siguientes abrieron confirmando la lectura y citando hallazgos especificos del reporte antes de proponer.`
- `friccion: un encargo entregado se pidio "revisar y reforzar" al reutilizarlo, señal de que la primera version no era suficiente por si sola → el encargo siguiente se reescribio con las precondiciones instrumentadas y un criterio adicional, en vez de reenviarse igual.`
