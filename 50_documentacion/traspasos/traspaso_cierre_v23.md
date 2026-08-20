# Traspaso de cierre v23 — transparencia_legislativa_chile

**Fecha:** 2026-08-19 · **Sesión:** 23 · **Modelo:** Opus 5

---

## 1. Identificación

- **Proyecto:** `transparencia_legislativa_chile` (portal de transparencia legislativa, Cámara de Diputados, R-only, JSON estático en GitHub Pages).
- **Versión del traspaso:** v23 (previo: v22).
- **Foco de la sesión:** cerrar los PR abiertos, establecer si P-91 (refresh caído) era real, instalar la guarda de sincronía del registro de pasos (P-93) y arreglar que el bot no versione las capturas del Senado (P-99). Los dos primeros se cumplieron; el tercero quedó en PR sin mergear; el cuarto quedó diseñado y medido, sin código.
- **Entorno:** Claude Code (macOS, R 4.5.2, Positron) como ejecutor autónomo; asistente conversacional como arquitecto y redactor de encargos.
- **Archivos principales modificados:** `10_utils/10_utils.R` y `00_run_all.R` (en la rama de PR #19, sin mergear); tres encargos y dos logs en `50_documentacion/andamios/`.
- **Estado de `main` previo al commit de cierre:** `origin/main` en `31ebafd` (fuente: `git ls-remote origin main` en la corrida de P-99, esta sesión); `main` local en `8d9e74f`, adelantado por commits documentales sin push (fuente: reporte del ejecutor, esta sesión).

---

## 2. Resumen ejecutivo

La sesión se propuso cerrar los PR abiertos, arreglar P-91 y construir la guarda de P-93. P-91 resultó no existir: la medición del historial de GitHub Actions mostró que la última corrida programada terminó verde el 2026-08-17 y que la racha de fallos era de cero; el fallo del 2026-08-10 corrió sobre un `head_sha` anterior al arreglo que ya estaba en `main`, y el portal no se actualizaba porque el PR de refresh esperaba merge, no porque el pipeline estuviera roto. El panel adversarial de PR #16, que la sesión 22 no alcanzó a correr, se ejecutó con dos agentes independientes y dio PASA concordante en las cuatro pruebas, con la calibración discriminando. Con eso, los tres PR abiertos (#18 refresh, #16 fix del runner, #17 sondeo temático) se mergearon por delegación acotada del titular, y el dato fresco volvió a producción. P-93 se construyó completo: `verificar_registro_pasos()` en `10_utils.R`, invocada en la entrada de `run_all()` antes de la guarda de P-65, con el registro obligatorio por defecto y una lista nominada de excepciones; cinco escenarios de fallo la detienen nombrando el paso huérfano y el control conocido-bueno pasa en silencio. Quedó en PR #19, sin mergear. P-99 (el workflow no versiona `20_insumos/senado/`, así que la promesa de P-65 de regenerar sin red no se cumple para el paso 37) se midió y se diseñó, pero su primera versión de diseño fue mala y el ejecutor la refutó con datos: `git add 20_insumos` invertía el régimen de fallo y dejaba el rechazo del padrón del Senado sostenido por una sola línea de `.gitignore`. El rediseño (derivar las rutas de `DIRECTORIOS_CRUDO` en R, con validación del staged que falla cerrado) quedó escrito y sin ejecutar. La sesión se cierra con cuatro pendientes nuevos y un PR sin mergear.

---

## 3. Estado al cierre

**Qué funciona.** El pipeline completo: `run_all()` con los siete pasos, 0 saltados, 16,6 s, exit 0, cero llamadas de red, sobre el corte 2026-08-12 (fuente: F1.4 del log de P-93, esta sesión). El refresh semanal en CI: última corrida verde el 2026-08-17 11:30 UTC (id 32025223500, evento `schedule`), 5 de 6 corridas programadas en verde y racha de fallos igual a cero (fuente: F2.2 del log de P-91, esta sesión). El portal en producción, con el refresh del 2026-08-17 ya mergeado (#18, `merged_at` 2026-08-19T14:28:07Z).

**Qué no funciona.** El bot no versiona las capturas del Senado: de nueve cortes, sólo `20260812` tiene captura en `senado/`, y la subió el titular a mano (`b4b0bcd`); 0 de 8 commits del bot tocaron ese directorio (fuente: F0 de P-99, esta sesión). Síntoma observable: sobre el árbol al corte vigente, `run_all()` se detiene con `falta la captura cruda de ese corte en 20_insumos/senado/`. La guarda de P-93 no está en producción (PR #19 abierto).

**Delta respecto a v22.**
- P-91 pasa de "bug activo, refresh caído desde al menos el 2026-08-10" a **refutado por medición**.
- P-86 pasa de "arreglado, sin panel" a **arreglado y validado por panel independiente**, y mergeado a `main`.
- P-92 pasa de "sondeo en rama sin mergear" a **mergeado**: `50_veredicto_vias_tematicas_derivadas.md` ya vive en el árbol (fuente: escáner del cierre).
- P-93 pasa de "no construido" a **construido, probado y en PR #19**.
- Aparece P-99, que no estaba en el inventario de v22 y es más grave que lo que P-93 arregla.

---

## 4. Registro detallado de cambios

### 4.1 Diagnóstico de P-91 y panel adversarial de PR #16

**Archivos:** ninguno de código. Log: `50_documentacion/andamios/logs/20260814_panel_p86_diagnostico_p91_log.md` (449 líneas).

**Categoría temática:** diagnostico/exploracion.

**Qué se hizo.** Se bajó el historial completo del workflow con `gh api ... --paginate > runs.json` y se leyó en R: 10 corridas, tabla de `conclusion` por `event` (5 verdes y 1 roja en `schedule`, 3 verdes y 1 roja en `workflow_dispatch`), última verde el 2026-08-17 11:30 UTC, racha de fallos consecutivos igual a 0. Se bajó el log del run fallido, se descomprimió con `utils::unzip()` y se citó la línea del `stop()`. En paralelo, dos agentes independientes en worktrees separados re-derivaron las tres afirmaciones críticas de PR #16 más un control de calibración.

**Por qué.** El traspaso v22 declaraba el refresh caído y ordenaba no creerle a ningún documento sobre el estado de un sistema automatizado (A96). La medición contradijo al documento.

**Cómo se verificó.** La hipótesis de la guarda circular (H1) quedó confirmada **para ese run concreto** y superada: el `head_sha` del run fallido (`b619a504`, 2026-08-09) es anterior a `5423541` (2026-08-12), el commit que le dio a la guarda la rama de primera corrida. El log del run verde lo prueba de forma independiente: `Primera corrida del corte 2026-08-17: 0 de 6 archivos ... sin rastro de arranque previo` y después `39_consolidar: Procedencia validada: 7 intermedios`.

**Dependencias afectadas:** ninguna. Fase de sólo lectura.

**Tensión resuelta.** Ese mismo log midió el defecto de P-86 en producción: la guarda decía `0 de 6` mientras el paso 39 validaba 7. Eso confirmó que PR #16 no era cosmético.

### 4.2 Integración de los tres PR abiertos

**Qué se hizo.** Por delegación acotada del titular, `gh pr merge --merge` sobre #18 (`refresh/2026-08-17`), #16 (`fix/p86-runner-paso37`) y #17 (`sondeo/p92-eje-tematico`), en ese orden, verificando cada uno por su endpoint propio (`gh api .../pulls/<N>`) y no por `gh pr list`.

**Por qué en ese orden.** #18 primero devuelve el dato fresco a producción (Pages republica `docs/` al mergear); #16 es la precondición sustantiva de P-93; #17 sólo toca andamios.

**Cómo se verificó.** `merged = TRUE` con `merged_at` y hash de merge para los tres: `77894647af`, `968a2368c2`, `31ebafd69b`. Tras el merge, `PASOS_EXTRACCION` pasó a `32:37` (`00_run_all.R:66`) e `INTERMEDIOS_PIPELINE` a 7 elementos (`10_utils.R:513`).

**Nota contable.** Siguiendo el precedente de la sesión 9 (las operaciones de git no son cambios de producto), esta integración no genera entrada de backlog propia.

### 4.3 P-93: guarda de sincronía del registro de pasos

**Archivos:** `10_utils/10_utils.R` (función nueva, líneas 608-708), `00_run_all.R` (constante `PASOS_SIN_INTERMEDIO`, campo `intermedios` en `PASOS`, invocación). Commits `61bc1b6` y `182661d`. Log `20260819_p93_guarda_registro_pasos_log.md` (572 líneas), commit `b91924f`. **PR #19, abierto.**

**Categoría temática:** infraestructura.

**Qué se hizo.** `verificar_registro_pasos(pasos, excepciones)` comprueba, para cada paso esperado, tres membresías (`PASOS_EXTRACCION`, `INTERMEDIOS_PIPELINE`, rama de `capturas_crudas_de_paso()`), tres sentidos inversos y dos de coherencia de excepciones. Se invoca en `run_all()` antes de `regenerar_intermedios_si_desalineados()`. Devuelve invisible y sin salida cuando todo está sincronizado.

**Por qué.** El registro de un paso vivía repartido en tres estructuras sin nada que forzara su sincronía; P-66 agregó el 37 tocando sólo `PASOS` y el defecto tardó dos sesiones en manifestarse. La regla fijada es que el registro es **obligatorio por defecto** y las exclusiones son una lista nominada (`PASOS_SIN_INTERMEDIO <- c(39L)`): una lista de incluidos deja al paso nuevo fuera en silencio, una de excepciones lo deja dentro y ruidoso.

**Cómo se verificó.** Control conocido-bueno: stdout 0, stderr 0, retorno invisible; `run_all(only = 39)` idéntico entre `main` y la rama (12 líneas, `identical = TRUE`); `run_all()` completo con 117 líneas idénticas en ambas ramas y 0 llamadas de red. Cinco escenarios de fallo (38, fantasma, 41, 37, 99), todos deteniendo y nombrando el elemento; con el 38 escrito de verdad, el `stop()` que sale es el de P-93 y no el de P-65, o sea el orden de las guardas es el correcto. Auto-auditoría con prueba corrida: reconstruido el estado pre-#16, la guarda habría atrapado el 37 en la primera corrida.

**Decisión de diseño no fijada por el encargo.** `INTERMEDIOS_PIPELINE` guarda nombres, no ids, y la correspondencia paso→intermedio no existía (ni es 1:1: el 33 produce dos). El ejecutor la declaró como campo `intermedios` **dentro de `PASOS`**, no como lista aparte, para no crear una quinta estructura desincronizable. Aprobada por el redactor: es la lectura correcta del criterio.

**Panel adversarial.** Dos agentes independientes, PASA concordante en las cuatro pruebas (calibración, silencio, paso huérfano nombrado, detección/regeneración idéntica a `main` por `deparse()`).

### 4.4 P-93 (segunda parte): el directorio del mensaje deja de estar escrito a mano

**Archivos:** `10_utils/10_utils.R`, commit `182661d`, dentro de PR #19.

**Categoría temática:** infraestructura (misma entrada de backlog que 4.3).

**Qué se hizo.** El literal `20_insumos/camara/` del mensaje del `stop()` de la guarda se sustituyó por el directorio derivado de la ruta real que devuelve `capturas_crudas_de_paso()`.

**Por qué.** El panel de PR #16 halló, por separado en los dos agentes, que el mensaje mandaba a `camara/` para una captura que vive en `senado/`. Defecto preexistente, no introducido por #16.

**Cómo se verificó.** Tres escenarios: falta la del 37 → dice `senado/` (en `main` decía `camara/`); falta una de la Cámara → sigue diciendo `camara/`, sin regresión; faltan ambas → nombra los dos directorios (en `main` sólo decía `camara/`). `deparse()` acota toda la divergencia a un bloque contiguo del mensaje: borrando las tres sentencias nuevas la rama vuelve a ser `main` byte a byte.

### 4.5 P-99: medición y auditoría de gobernanza (sin cambio de código)

**Archivos:** log `50_documentacion/andamios/logs/20260819_auditoria_gobernanza_p99_log.md` (284 líneas), commit `8d9e74f`, en `main` local sin push.

**Categoría temática:** diagnostico/exploracion.

**Qué se hizo.** Se estableció que `.github/workflows/refresh-semanal.yml:115` enumera rutas a mano y omite `20_insumos/senado`; se contó el contenido trackeado de `20_insumos/` (camara 57, senado 3, territorio 2); se auditó la captura del SIL versionada en busca de dato personal, con arnés calibrado; y se midió el efecto real que tendría `git add 20_insumos`.

**Por qué.** El pendiente salió del log de P-93: la promesa de P-65 (regenerar cualquier intermedio desalineado sin red) no se puede cumplir para el paso 37, porque su captura nunca llega al repositorio.

**Cómo se verificó.** Auditoría de dato personal: 3 271 894 caracteres barridos, 0 correos, 0 RUT, 0 teléfonos; 5 de 5 patrones vivos contra señuelos sintéticos y un señuelo inyectado en la columna `xml` de la captura real, detectado; 0 detectores ciegos tras corregir dos defectos del propio arnés (contadores que devolvían `NA` por no filtrar una columna, y un señuelo de RUT sin puntos que llevaba puntos). Controles estructurales: cero caracteres `@` y cero `+` en 3,26 M de caracteres, corrida de dígitos más larga igual a 5. Lo único personal son nombres de parlamentarios en rol público, que el portal ya publica.

**Tensión resuelta, y contra el redactor.** El diseño que el encargo fijaba (`git add 20_insumos` completo) fue refutado con datos: invierte el régimen de fallo de "sólo entra lo nombrado" a "entra todo lo no excluido", y al otro lado de esa línea está el material que `.gitignore:50-56` excluye (endpoints de padrón del Senado con 157 correos y 53 teléfonos nominales), sobre el que el proyecto ya deliberó y falló en contra. Además el argumento de que `20_insumos/senado` podría no existir en el runner era falso: `.gitkeep` está trackeado. El rediseño (D56) quedó escrito y sin ejecutar.

---

## 5. Backlog acumulativo

Vive en `50_documentacion/activa/backlog_acumulativo.md`. Esta sesión aporta las entradas **65 a 67**. El detalle de cada una va en el bloque de entradas del paquete de cierre; el conteo histórico se verifica contra ese archivo y no contra este traspaso.

---

## 6. Bugs de la sesión

### Bug 1 — El mensaje de recuperación de la guarda nombra el directorio equivocado

- **Síntoma observable:** ante una captura ausente del paso 37, el `stop()` decía `20_insumos/camara/` para un archivo que vive en `20_insumos/senado/`.
- **Causa raíz:** literal fijo en `10_utils/10_utils.R:750` (numeración de `main` previa al merge de #16), dentro de `regenerar_intermedios_si_desalineados()`.
- **Solución exacta:** derivar el directorio de la ruta real que devuelve `capturas_crudas_de_paso()` (commit `182661d`, PR #19).
- **Criterio de verificación:** los tres escenarios de 4.4.
- **Patrón general aprendido:** un dato que el programa ya tiene no se vuelve a escribir a mano en el mensaje de error; el mensaje de una guarda es parte de su contrato, no decoración.
- **Estado:** resuelto, en PR sin mergear. Queda una segunda coincidencia del literal (`:813` en la numeración post-merge), donde el vector de faltantes está vacío por construcción → P-101.

### Bug 2 — El refresh semanal no versiona las capturas del Senado

- **Síntoma observable:** `run_all()` sobre el árbol al corte vigente se detiene con `falta la captura cruda de ese corte en 20_insumos/senado/ (1 archivo(s))`.
- **Causa raíz:** `.github/workflows/refresh-semanal.yml:115` enumera `20_insumos/camara` y nada más; la lista es anterior al paso 37 (P-66) y nunca se actualizó.
- **Solución exacta:** diseñada, no implementada (D56).
- **Criterio de verificación:** la rama `refresh/<corte>` de una corrida nueva contiene al menos un archivo bajo `20_insumos/senado/` y ninguno bajo `20_insumos/territorio/`.
- **Patrón general aprendido:** una enumeración escrita a mano en un archivo de infraestructura envejece en silencio; si existe la declaración equivalente en código, el archivo de infraestructura debe derivar de ella y no repetirla.
- **Estado:** pendiente → P-99.

### Bug 3 — La guarda de P-93 depende de la forma sintáctica de la función que audita

- **Síntoma observable:** al insertar una sentencia antes del `switch` de `capturas_crudas_de_paso()`, `names(body(...)[[2]])` devuelve vacío y la guarda degrada a falso positivo.
- **Causa raíz:** `body(...)[[2]]` asume que el `switch` es la segunda expresión del cuerpo.
- **Solución exacta:** recorrer el cuerpo buscando la llamada, en vez de indexar por posición. No aplicada.
- **Criterio de verificación:** con una sentencia insertada antes del `switch`, la guarda sigue en silencio sobre el pipeline sincronizado.
- **Patrón general aprendido:** una guarda que lee código por posición sintáctica hereda la fragilidad del código que audita; el modo de fallo es ruidoso (nunca deja pasar un huérfano), pero un falso positivo detiene `run_all()` en su entrada, incluido el cron.
- **Estado:** pendiente → P-100. Hallado por los dos panelistas por separado y verificado por el ejecutor. No se arregló para no dejar el veredicto del panel sobre código distinto del auditado.

### Bug 4 — P-91 no era un bug

- **Síntoma reportado en v22:** `6 de 6 intermedios NO corresponden al corte vigente (2026-08-10)`, interpretado como refresh caído desde al menos esa fecha.
- **Causa raíz real:** el run del 2026-08-10 corrió sobre `b619a504`, anterior a `5423541`, que introdujo la rama de primera corrida en la guarda. Desde entonces todas las corridas programadas terminaron verdes; el dato no llegaba a producción porque el PR de refresh esperaba merge, que es el costo declarado en la cabecera del propio workflow.
- **Patrón general aprendido:** un documento que declara roto un sistema automatizado describe el estado del sistema **en el commit que corría entonces**, no hoy; el `head_sha` del run es parte del diagnóstico y no un metadato.
- **Estado:** cerrado por medición, sin cambio de código.

---

## 7. Aprendizajes y restricciones descubiertas

- **A102.** El estado de una corrida de CI se interpreta contra su `head_sha`, no contra el árbol actual. Principio: medición antes de implementación. Si se viola, se arregla un defecto ya arreglado y se pierde la sesión. Ejemplo: P-91.
- **A103.** `git add <directorio>` y `git add <ruta enumerada>` no son la misma operación con distinto alcance: son regímenes de fallo opuestos (abierto contra cerrado). Antes de ampliar un `add`, hay que preguntarse qué queda al otro lado de la línea y qué lo sostiene. Ejemplo: P-99, donde lo que quedaba al otro lado era el padrón del Senado sostenido sólo por `.gitignore`.
- **A104.** Las precondiciones de un encargo tienen que ser consistentes con sus propios pasos. Un encargo que ordena commitear en `main` y después exige `main == origin/main` se detiene a sí mismo. Ejemplo: encargo de P-93 v1.
- **A105.** Un `.gitkeep` trackeado garantiza que el directorio exista tras cualquier `checkout`; ese es el hecho que decide si una ruta puede abortar un `git add` en CI.
- **A106.** Un arnés de detección (dato personal, patrones, señuelos) se calibra antes de creerle un cero: con señuelos sintéticos **y** con un señuelo inyectado en el dato real. Dos defectos del arnés de esta sesión (contadores que devolvían `NA` por no filtrar una columna, señuelo de RUT mal construido) habrían producido un cero o un "ciego" falsos.
- **A107.** Una compuerta que depende de una acción humana fuera de banda (mergear un PR) no es una hipótesis del encargo: es un gate, y encadenar encargos detrás de ella los detiene a todos. Esta sesión perdió tres corridas por eso.
- **A108.** Cuando la sesión ya tuvo dos arneses que midieron mal antes de medir bien, la corrección correcta no es "más cuidado": es un control de volumen (¿cuántos caracteres vio realmente el barrido?) declarado en el mismo bloque que la cifra.

---

## 8. Decisiones de diseño

### D55 — El registro de un paso del pipeline es obligatorio por defecto

- **Decisión:** todo `id` de `PASOS` debe estar en `PASOS_EXTRACCION`, `INTERMEDIOS_PIPELINE` y `capturas_crudas_de_paso()`; las exclusiones viven en `PASOS_SIN_INTERMEDIO`, nominadas y comentadas.
- **Alternativa considerada:** una lista de incluidos (qué pasos vigila la guarda).
- **Justificación:** una lista de incluidos deja al paso nuevo fuera en silencio, que es exactamente cómo se perdió el 37. El defecto se paga en la primera corrida, no dos sesiones después.
- **Implicancia:** agregar un paso al pipeline obliga a registrarlo o a excluirlo explícitamente. No hay tercera vía silenciosa.

### D56 — La lista de rutas de crudo que versiona el bot se deriva de R, no se enumera en el YAML

- **Decisión:** el workflow obtiene las rutas con `Rscript -e 'cat(rutas_versionables_crudo())'`, helper que devuelve `file.path("20_insumos", DIRECTORIOS_CRUDO)`; y valida, entre el `git add` y el `git commit`, que el conjunto staged esté contenido en lo declarado, matando el job con `quit(status = 1)` ante cualquier ruta intrusa.
- **Alternativas consideradas:** (a) `git add 20_insumos` completo, descartada por invertir el régimen de fallo (A103); (b) enumerar `camara` y `senado` en el YAML más una guarda de coincidencia, descartada porque deja dos listas que pueden desincronizarse, que es el defecto que P-99 arregla.
- **Justificación:** `DIRECTORIOS_CRUDO <- c("camara", "senado")` ya existe en `10_utils/10_utils.R:249`, es declaración única en el repo y su propio comentario dice que existe para que agregar una fuente y olvidarse de sumarla no abra un punto ciego. El helper traduce esa declaración; no inventa ni descubre.
- **Tensión resuelta:** simplicidad contra gobernanza. La validación del staged cuesta unas líneas y convierte a `.gitignore` en la segunda línea de defensa en vez de la única.
- **Estado:** decidida, **no implementada**.

### D57 — Delegación acotada de autoridad de merge

- **Decisión:** el titular delegó, dentro de esta sesión, el merge de #18, #16, #17 y (después) #19, con `--merge`, sin `--squash`, sin `--rebase`, sin `--delete-branch`, y sin alcanzar a los PR que los propios encargos abrieran.
- **Justificación:** tres encargos consecutivos se detuvieron en la misma compuerta de merge. La delegación acotada mantiene la autoridad del titular sobre el alcance y elimina la detención en cadena.
- **Implicancia:** la delegación es por sesión y por número de PR. No se hereda al próximo traspaso.

---

## 9. Constantes y parámetros

| Constante | Valor anterior | Valor nuevo | Archivo | Motivo |
|---|---|---|---|---|
| `PASOS_SIN_INTERMEDIO` | no existía | `c(39L)` | `00_run_all.R` | Lista de excepciones de D55 |
| `CORTE_FECHA` | `2026-08-12` | `2026-08-17` | `10_utils/10_configuracion.R` | Llegó con el merge de #18 (refresh del bot), no se decidió en sesión |

Las vigentes se declaran en `10_utils/10_configuracion.R`. `DIRECTORIOS_CRUDO` (`10_utils/10_utils.R:249`) no cambió: D56 la consume, no la modifica.

---

## 10. Arquitectura de archivos

Escáner regenerado en el cierre; su sello es el que Claude Code deja en `50_documentacion/estructura/`. Sin cambios estructurales: los archivos nuevos de la sesión son tres encargos y dos logs en `50_documentacion/andamios/` (más el log de P-93, que viaja en PR #19).

`50_documentacion/traspasos/` tenía un solo archivo vigente (`traspaso_cierre_v22.md`) con el resto en `archivo/`: la regla 1.3.1 se cumplía al abrir esta sesión.

**Desviación estructural viva:** seis archivos de `50_documentacion/activa/` sin el prefijo `50_` (`documentacion_tecnica_v1.md`, `encargo_contrato_datos_camara_senado.md`, `encargo_exploracion_asistencia_senado_h1bis.md`, `encargo_exploracion_senado_v02.md`, `exploracion_api_camara.md`, `procedimiento_actualizacion.md`), más `andamios/design_handoff_portal_transparencia/Portal Transparencia.dc.html`, cuyo nombre tiene espacios. Es P-60, con el gatillo 4bis encendido por quinta apertura consecutiva.

---

## 11. Pendientes y ruta sugerida

### 11.1 Inventario

**P-99 — El refresh semanal no versiona las capturas del Senado.**
Tipo: bug activo. Contexto: `refresh-semanal.yml:115` enumera `20_insumos/camara` y omite `senado`; la promesa de P-65 de regenerar sin red no se cumple para el paso 37. Impacto: alto (rompe una garantía declarada del pipeline y deja el corte vigente sin captura del SIL). Dependencias: PR #19 mergeado (el encargo v3 lo mergea por delegación, que **caduca con esta sesión**: la próxima sesión debe re-delegar o mergear a mano). Complejidad: baja en código, media en verificación (exige una corrida real de CI). Principios: derivar en vez de repetir; régimen de fallo cerrado. Precauciones: no ampliar el `add` al directorio (A103); no commitear `20_insumos/territorio/` (D5). Enfoque: el encargo v3 ya escrito, en `50_documentacion/andamios/50_encargo_s23_p99_workflow_versiona_senado.md`. Criterio de éxito: la rama `refresh/<corte>` de una corrida nueva contiene al menos un archivo bajo `20_insumos/senado/` y ninguno bajo `territorio/`.

**P-100 — La guarda de P-93 indexa el cuerpo de la función por posición.**
Tipo: deuda técnica. Contexto: `body(...)[[2]]` asume que el `switch` es la segunda expresión de `capturas_crudas_de_paso()`. Impacto: medio (falso positivo que detiene `run_all()` en su entrada, incluido el cron; nunca deja pasar un huérfano). Dependencias: PR #19 mergeado. Complejidad: baja. Precauciones: cualquier cambio invalida el veredicto del panel de P-93 sobre esa función y exige re-correr el control conocido-bueno y los cinco escenarios. Criterio de éxito: con una sentencia insertada antes del `switch`, la guarda sigue en silencio sobre el pipeline sincronizado.

**P-101 — Segunda coincidencia del literal `20_insumos/camara` en la guarda.**
Tipo: deuda técnica. Contexto: en la segunda ocurrencia el vector de faltantes está vacío por construcción, así que el directorio no es derivable de la misma forma. Impacto: bajo. Complejidad: baja. Enfoque sugerido: generalizar a `20_insumos/` en vez de derivar. Criterio de éxito: ninguna cadena de directorio de captura escrita a mano queda en `regenerar_intermedios_si_desalineados()`.

**P-102 — Cinco literales `subdir=` no derivan de `DIRECTORIOS_CRUDO`.**
Tipo: deuda técnica. Contexto: `10_utils.R:239`, `:463`, `:603` y `37_extraer_tramitacion.R:280`, `:440` escriben `"camara"` o `"senado"` a mano, mientras `reportar_estado_capturas()` sí deriva de la constante. Impacto: bajo hoy, medio cuando llegue el pipeline del Senado. Complejidad: baja. Criterio de éxito: para cada paso, la ruta que produce el literal es idéntica a la que produce la constante, verificado programáticamente.

**P-103 — La knowledge base cita una versión anterior del instrumento de cierre.**
Tipo: documentación. Contexto: `SETTINGS_Y_PROMPTS_OPERACIONALES.md` §2.1 (v23) referencia `cierre_sesion_autonomo_cc_v7.md`, mientras el disco tiene v8, que volvió obligatorios dos campos de front matter (`settings_version`, `compuerta_dudas`). El redactor escribió el paquete contra v7 y el cierre se detuvo en F0.6. Impacto: bajo por evento, seguro por recurrencia (se repetirá en cada cierre hasta que se sincronice). Complejidad: baja. Enfoque: actualizar la referencia de §2.1 en la knowledge base y declarar ahí los campos obligatorios del front matter, para que el redactor no dependa de leer el instrumento (que por regla no es su insumo). Criterio de éxito: la lista de campos del front matter en SETTINGS §2.1 coincide con la que el instrumento verifica en F0.

**P-104 — El umbral del catálogo de rótulos del instrumento de cierre mide un proxy que no aplica a este repo.**
Tipo: documentación (instrumento de cartera, fuera de este repositorio). Contexto: la regla 7.3 de `cierre_sesion_autonomo_cc_v8.md` detiene el cierre cuando más de la mitad de los 12 rótulos canónicos tienen cero disparos, bajo la premisa de que eso indica un cambio de estructura del archivo. En este backlog 10 de 12 tienen cero disparos porque nunca existieron: no tiene rango en el encabezado, ni mapa de tramos, ni cabecera del resumen, ni nota de cierre. La premisa quedó falsada por medición en el cierre v23 (el log de cierres describe el mismo archivo con la misma forma en v22). Impacto: alto por recurrencia (detiene todos los cierres de este proyecto y de cualquier hermano cuyo backlog no lleve los 12 rótulos). Complejidad: baja. Enfoque sugerido: bajar el umbral a "cero disparos en el catálogo entero", que conserva la alarma de cambio estructural sin presuponer que los 12 rótulos son universales. Criterio de éxito: un cierre de este proyecto pasa F3 sin autorización manual, y un backlog al que se le borre un encabezado sigue deteniendo.

**P-94 — Construir y publicar la entidad temática sobre la vía 1.** (Heredado, sin cambios salvo que su insumo ya está en `main`.) Tipo: funcionalidad. Es el objetivo declarado del proyecto. Ya no tiene dependencias externas: `50_veredicto_vias_tematicas_derivadas.md` está en el árbol y el pipeline publica en producción. Complejidad: alta. Precauciones: el sufijo del boletín no se publica como "tema" ni se le fabrica glosa (D52, D53, D42); la tabla interpretable es sólo del período vigente, porque el universo completo agrega dos composiciones de la Cámara y cancela signos en 4 de 9 sufijos (A99). Criterio de éxito: la entidad temática publicada, con su rótulo empírico declarado y su corte de período explícito.

**P-60 — Ordenación del repositorio.** (Heredado; gatillo 4bis encendido por quinta apertura.) Tipo: deuda técnica. Cifra medida en esta sesión: seis archivos sin prefijo en `activa/` más un archivo con espacios en el nombre.

**P-54 — Formalizar el patrón PAT-01 en política.** (Heredado, sin avance.)

**Pipeline del Senado.** (Heredado.) Arquitectura diseñada (contrato simétrico D2, clave compuesta, capa de normalización D1); construcción no iniciada.

### 11.2 Evaluación de deuda técnica

Zona frágil principal: la vecindad de `regenerar_intermedios_si_desalineados()`, que ahora concentra la guarda de P-65, la de P-93, dos literales de directorio y la derivación del mensaje. Principio en tensión: resiliencia contra simplicidad. Oportunidad: P-100, P-101 y P-102 son tres cortes de la misma tela (datos escritos a mano donde existe la declaración) y caben en un solo PR con un solo panel.

### 11.3 Auditoría de cierre (política 5.6)

| # | Pregunta | Respuesta |
|---|---|---|
| 2 | ¿El pipeline corre de cero sin intervención manual? | **No.** Corre completo desde caché (7 pasos, 16,6 s, 0 red), pero desde cero necesita capturas que el bot no versiona (P-99) |
| 5 | ¿Los resultados son reproducibles desde los datos crudos? | **No, para el paso 37.** Su captura no está versionada en el corte vigente (P-99) |
| 6 | ¿Cada cifra publicada es trazable a su fuente? | **Sí.** Sello de procedencia validado en la corrida verde (`39_consolidar: Procedencia validada: 7 intermedios`) |
| 7 | ¿La documentación permite retomar sin contexto? | **Sí.** Traspaso, backlog, dos logs nuevos y tres encargos, todos en el repo |
| 8 | ¿Nombres sin tildes, ñ ni espacios? | **No.** `Portal Transparencia.dc.html` → P-60 |

### 11.4 Compuerta de dudas

| supuesto | predicado | medicion |
|---|---|---|
| El helper de D56 resuelve P-99 | La rama `refresh/<corte>` de una corrida nueva contiene ≥1 archivo bajo `20_insumos/senado/` | F2 del encargo de P-99 v3 |
| La guarda de P-93 no dispara falsos positivos en CI (sólo corrió en macOS local) | El log del primer refresh posterior al merge de #19 no contiene el `stop()` de `verificar_registro_pasos` y completa los 7 pasos | Leer el log del run con `gh api .../logs` y `utils::unzip()` |
| PR #19 mergea limpio pese a la deriva de `main` | `gh api .../pulls/19` devuelve `mergeable = MERGEABLE` y el merge termina sin conflicto | `gh api` y `gh pr merge` |
| Los cinco literales `subdir=` producen las mismas rutas que la constante | Para cada paso, `ruta_cache(<literal>)` es idéntica a la ruta derivada de `DIRECTORIOS_CRUDO` | Script de R que compara ambas listas |
| La validación del staged de D56 no mata el job por un falso positivo | La corrida de F2 termina en `success` y su inventario de staged contiene sólo rutas declaradas | La misma corrida de F2 |

### 11.5 Ruta sugerida para la próxima sesión

**Prioridad 1 — Mergear PR #19 y ejecutar P-99.** Bug activo (criterio 1) más un PR probado esperando. El encargo v3 ya está escrito; hay que re-delegar el merge o hacerlo a mano, porque la delegación de esta sesión caduca con ella. Criterio de éxito: el de P-99 en 11.1, más el primer refresh con la guarda de P-93 en producción y en silencio.

**Prioridad 2 — P-100, P-101 y P-102 en un solo PR.** Deuda técnica barata y de la misma familia. Criterio de éxito: los tres criterios de 11.1, con un panel único.

**Prioridad 3 — P-94, la entidad temática.** Es el objetivo declarado del proyecto y ya no tiene dependencias. Alta complejidad: merece la sesión completa una vez que P-99 esté cerrado.

**Diferir:** pipeline del Senado, P-54, y todo lo heredado sin cambio. **Ofrecido, no impuesto:** P-60.

---

## 12. Instrucciones específicas para la próxima sesión

- ⚠️ **NO** afirmar el estado de un sistema automatizado desde un documento: se verifica contra GitHub Actions, y la interpretación de un run se hace contra su `head_sha`, no contra el árbol de hoy (A96, A102).
- ⚠️ **NO** dar por vigente la delegación de merge: caducó con la sesión 23 (D57).
- ⚠️ **NO** ampliar un `git add` a un directorio sin declarar qué queda al otro lado de la línea y qué lo sostiene (A103).
- ⚠️ **NO** afirmar `CORTE_FECHA`, el sello de un intermedio ni el hash de `main` sin leerlos en el momento de afirmarlo.
- ⚠️ **NO** afirmar lo que dice un documento del proyecto sin haberlo leído en la sesión, ni para confirmarlo ni para contradecirlo.
- ⚠️ **NO** heredar el universo: 427 boletines, 842 votaciones y 130 510 filas de voto son del corte 2026-08-12 y se remiden.
- ⚠️ **NO** leer la tabla del universo completo como propiedad del eje temático: agrega dos composiciones de la Cámara y cancela signos (A99).
- ⚠️ **NO** publicar el sufijo del boletín como "tema" ni fabricar su glosa (D52, D53, D42).
- ⚠️ **NO** usar `gh pr diff --name-only` ni `gh --jq`: `gh api > archivo.json` y `jsonlite::fromJSON()`.
- ⚠️ **NO** verificar el estado de un PR con `gh pr list`: endpoint propio (`gh api .../pulls/<N>`), que ya mostró ser la fuente mejor.
- ✅ **ANTES** de creerle un cero a un arnés de detección, calibrarlo con señuelos sintéticos y con uno inyectado en el dato real, y declarar el volumen barrido en el mismo bloque (A106, A108).
- ✅ **ANTES** de escribir una compuerta en un encargo, recorrer su efecto sobre los pasos previos del propio encargo (A104).
- ✅ **ANTES** de encadenar un encargo detrás de una acción del titular, declararla como gate y no como hipótesis (A107).
- ✅ **ANTES** de aplicar un criterio de éxito, probarlo contra un caso de control conocido-bueno (A95).
- ✅ **ANTES** de empujar muestras crudas, auditar correos, teléfonos y RUT; redactar en `HEAD` no basta si el commit anterior ya los contiene (A101).
- 🔒 `sellar()`, `leer_sellado()` y `validar_corte()` no se tocan.
- 🔒 La guarda del contrato temporal (D31) no se afloja sin decisión explícita del titular.
- 🔒 Los intermedios no se versionan (D24); `40_salidas/intermedios/.gitkeep` sigue trackeado.
- 🔒 `20_insumos/territorio/` no lo commitea el bot: es insumo estático con revisión manual de diff (D5).
- 🔒 `10_utils/10_utils.R` no adquiere dependencias de paquetes.
- 🔒 Ninguna captura cruda ya escrita se modifica ni se borra.
- 🔒 `main` no recibe escrituras automáticas ni push directo del bot.
- 🔒 `sin_registro` no se imputa, ni en el dato ni en la presentación.
- 🔒 R es el único lenguaje, en todo contexto.
- 🔒 `git` siempre con `-C <ruta absoluta>`, `gh` siempre con `-R tomgc/...` salvo `gh api`, `git add` siempre con ruta acotada.
- 🔒 `proyectos_detalle.rds` mantiene una fila por boletín (D28).
- 🔒 Los campos con atributo de dominio se conservan con código y glosa (D29).

---

## 13. Fragmentos de código de referencia

Patrón nuevo de la sesión: la lista de excepciones nominadas de D55, que es el contrato que hace ruidoso al paso nuevo.

```r
# Pasos que NO producen intermedio sellado y por tanto NO se registran en las
# estructuras de la guarda. Es una lista de EXCEPCIONES: el registro es
# obligatorio por defecto, de modo que un paso nuevo falla ruidosamente hasta
# que alguien decida conscientemente excluirlo.
PASOS_SIN_INTERMEDIO <- c(39L)
```

La función completa `verificar_registro_pasos()` vive en `10_utils/10_utils.R` (PR #19) y no se re-copia aquí. Los patrones estables del proyecto viven en `50_documentacion/activa/documentacion_tecnica_v1.md` y en `CLAUDE.md`.

---

## 14. Reapertura

Tipo: CONTINUATION. El protocolo (`POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`) vive en la knowledge base del Project y se lee desde ahí; verifica las versiones contra la knowledge base, no contra ninguna otra fuente, antes de la Fase A.

Estado: la sesión 23 refutó P-91 (el refresh nunca estuvo caído: la última corrida programada terminó verde el 2026-08-17 y la racha de fallos era cero), corrió el panel adversarial pendiente de PR #16 con veredicto PASA concordante, mergeó los tres PR abiertos (#18, #16, #17) y devolvió el dato fresco a producción. P-93 quedó construido y probado en PR #19, sin mergear: guarda de sincronía del registro de pasos, con el registro obligatorio por defecto y `PASOS_SIN_INTERMEDIO` como única vía de exclusión. Apareció P-99, más grave que lo que P-93 arregla: el bot no versiona las capturas del Senado, así que la promesa de P-65 de regenerar sin red no se cumple para el paso 37.

No creas a este traspaso sobre `CORTE_FECHA`, sobre el hash de `main`, sobre el estado de ningún PR ni sobre ninguna cobertura: todas se remiden. La delegación de merge de la sesión 23 caducó: mergear PR #19 vuelve a ser gate del titular salvo que lo delegue de nuevo.

El foco propuesto es P-99: el encargo v3 ya está escrito en `50_documentacion/andamios/50_encargo_s23_p99_workflow_versiona_senado.md`, con su diseño validado contra `DIRECTORIOS_CRUDO`, y sólo espera que #19 esté dentro. Después, P-100, P-101 y P-102 en un solo PR (tres cortes de la misma tela: datos escritos a mano donde existe la declaración). Y luego P-94, la entidad temática, que es el objetivo declarado del proyecto y ya no tiene dependencias externas. Sigue encendido el gatillo 4bis (ordenación, P-60), ahora por quinta sesión consecutiva, con la cifra medida: seis archivos sin prefijo más uno con espacios en el nombre.

El §15 trae cuatro errores registrados, los cuatro del asistente conversacional, y dos de ellos son de la misma familia: afirmar el estado del repositorio o de un sistema automatizado sin medirlo en la sesión.

Documentos para la próxima sesión:

1. Protocolo en knowledge base (no se adjuntan; se listan para verificar que la knowledge base esté al día): `POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
2. Opcionales según el foco real: `CLAUDE.md` si la sesión correrá en Claude Code.
3. Específicos de la sesión: `traspaso_cierre_v23.md`; `.github/workflows/refresh-semanal.yml` (lo que P-99 toca); `50_documentacion/andamios/50_encargo_s23_p99_workflow_versiona_senado.md` (el encargo listo para ejecutar).

---

## 15. Errores del asistente

### Error 1

| Campo | Contenido |
|---|---|
| `momento` | Fase B (acuse de recibo), al listar los vigentes que condicionan la sesión |
| `disparador` | Asistente lo señaló espontáneamente al recibir la medición del ejecutor |
| `que_paso` | Declaró "Bugs activos: P-91 (refresh semanal caído...)" sin marca de hipótesis, tomándolo del traspaso v22 |
| `regla_violada` | Traspaso v22 §12, instrucción heredada A96: no afirmar el estado de un sistema automatizado desde un documento; `userPreferences`, marcador de fuente obligatorio para estado del repositorio |
| `causa_raiz` | El acuse reproduce el traspaso por diseño, y en esa sección el asistente trató la reproducción como cita en vez de como afirmación propia; la instrucción que lo prohibía estaba en el mismo documento que reproducía |
| `salvaguarda_presente` | SETTINGS (§1.2.3) y el propio traspaso v22 §12 |
| `patron` | PAT-01, sobre el estado de un sistema automatizado citado desde un documento |
| `gatillo_observable` | `afirmar-sin-leer`: se afirmó el estado de un workflow sin consultar GitHub Actions en el turno |
| `intentos_previos` | 0 |
| `costo` | Ninguno material: la ruta propuesta ponía el diagnóstico como primera tarea y la medición lo corrigió antes de tocar código |

### Error 2

| Campo | Contenido |
|---|---|
| `momento` | Redacción del encargo de P-93 v1, §F0 |
| `disparador` | Usuario lo señaló sin nombrarlo error (el ejecutor lo reportó como contradicción y siguió) |
| `que_paso` | El encargo ordenaba commitear el propio archivo en `main` (F0.0) y acto seguido exigía `main == origin/main` como compuerta (F0.1), condición que el paso anterior hacía imposible |
| `regla_violada` | SETTINGS §1.2.5 y plantilla de encargo §2: las precondiciones deben ser verificables y consistentes con los pasos del encargo |
| `causa_raiz` | La compuerta se copió de un encargo anterior donde el commit del propio archivo no existía; el asistente revisó cada sección contra su propósito, no contra el efecto de las secciones previas |
| `salvaguarda_presente` | SETTINGS y `encargo_autonomo_claude_code_v1.md` |
| `patron` | PAT-13, precondición que mide un proxy (divergencia remota) y no el riesgo (árbol sucio) |
| `gatillo_observable` | `encargos-premisas`: una precondición del encargo contradice un paso del mismo encargo |
| `intentos_previos` | 0 |
| `costo` | Ninguno material: el ejecutor resolvió correctamente y lo reportó; una línea de análisis en el reporte |

### Error 3

| Campo | Contenido |
|---|---|
| `momento` | Redacción del encargo de P-99 v1, §4 (decisión de metodología) |
| `disparador` | Usuario lo corrigió (el ejecutor lo midió y detuvo la fase) |
| `que_paso` | Justificó `git add 20_insumos` argumentando que `20_insumos/senado` podía no existir en el runner y abortar el `git add`; el directorio tiene `.gitkeep` trackeado y siempre se materializa |
| `regla_violada` | `userPreferences`, marcador de fuente: el estado del repositorio se afirma con "(fuente: comando corrido en esta sesión)" o se marca como hipótesis |
| `causa_raiz` | El asistente construyó un argumento de diseño y buscó respaldo en un hecho plausible del repositorio sin medirlo, porque el hecho servía al argumento; la verificación era un `git ls-tree` de un segundo |
| `salvaguarda_presente` | `userPreferences` y el propio §0 de la plantilla de encargo, que obliga a separar premisas verificadas de hipótesis |
| `patron` | PAT-01, sobre existencia de una ruta en el árbol |
| `gatillo_observable` | `estado-git`: se afirmó la existencia de un directorio en el checkout sin listarlo |
| `intentos_previos` | 0 |
| `costo` | Un encargo rehecho (v1 → v2) y una fase de ejecución detenida |

### Error 4

| Campo | Contenido |
|---|---|
| `momento` | Redacción del encargo de P-99 v1, §4 |
| `disparador` | Usuario lo corrigió (el ejecutor lo halló y lo documentó) |
| `que_paso` | Fijó `git add 20_insumos` sin evaluar qué material quedaba excluido sólo por `.gitignore`: endpoints de padrón del Senado con 157 correos y 53 teléfonos nominales, sobre los que el proyecto ya había fallado en contra |
| `regla_violada` | POLITICA §6.1 (los datos personales no entran al repositorio y la separación no es sólo de `.gitignore`) y traspaso v22, D54 |
| `causa_raiz` | El asistente optimizó el diseño contra el defecto que tenía delante (la enumeración que envejece) sin recorrer el efecto del cambio sobre la gobernanza ya decidida; la restricción existía en el repo y no se propagó al diseño |
| `salvaguarda_presente` | POLITICA §6.1 y el traspaso v22 (D54, A101) |
| `patron` | PAT-07, restricción de gobernanza leída en sesiones previas y no propagada al diseño |
| `gatillo_observable` | `restriccion-no-propagada`: un cambio de alcance de versionado no se contrastó con la regla de datos personales del proyecto |
| `intentos_previos` | 1 (el mismo encargo ya había sido rehecho por el Error 3) |
| `costo` | Compartido con el Error 3: un encargo rehecho y una fase detenida; sin consecuencia sobre el repositorio, porque la compuerta del propio encargo lo atajó |

### Fricciones

- `friccion: tres reenvíos de reportes ya procesados en el hilo → se propuso el cierre al segundo y se insistió al tercero, y la sesión se cerró ahí.`
- `friccion: la compuerta de merge detuvo tres encargos consecutivos → se pasó de pedir el merge al titular a delegación acotada por número de PR (D57).`
- `friccion: el paquete de cierre se reemitió una vez por dos campos de front matter que el instrumento v8 exige y la knowledge base (que cita v7) no declara → se registró como P-103 en vez de tratarlo como descuido del redactor.`
- `friccion: el cierre se detuvo en F3 por un umbral del instrumento cuya premisa este backlog falsa → se autorizó el paso por excepción y se registró la corrección del instrumento como P-104, para que la excepción no se vuelva la norma.`
