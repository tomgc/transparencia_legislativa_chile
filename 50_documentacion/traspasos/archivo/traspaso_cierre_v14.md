# traspaso_cierre_v14.md

## 1. Identificacion

- **Proyecto:** `transparencia_legislativa_chile`
- **Version:** v14
- **Fecha de cierre:** 2026-07-27
- **Sesion 14.** Foco: mergear el PR #2 abierto por el cron del lunes (P-46) y
  construir el frontend de la Capa 3 de asistencia (P-47), que llevaba tres
  sesiones esperando con el dato ya publicado en el JSON y sin mostrar.
- **Entorno:** Positron / macOS, R 4.5.2 (aarch64-apple-darwin20). Trabajo
  conversacional sobre `/Users/tomgc/Projects/transparencia_legislativa_chile`,
  ejecucion de terminal por el titular. Modelo: Opus 5. Sin Claude Code en esta
  sesion.
- **Archivos principales modificados:** `docs/index.html` (unico archivo de codigo
  tocado); `50_documentacion/activa/backlog_acumulativo.md`,
  `50_documentacion/activa/ESTADO.md`, `50_documentacion/traspasos/traspaso_cierre_v14.md`
  y `50_documentacion/estructura/` (este cierre, pendiente de commit).

## 2. Resumen ejecutivo

La sesion abrio con la knowledge base todavia en POLITICA v5.2 y SETTINGS v7 pese
a que el traspaso v13 declaraba v5.4 y v12, y se detuvo antes de la Fase A hasta
que el titular la actualizo: es exactamente la condicion que obligo a rehacer el
cierre de la s13 y esta vez se cazo en el primer turno. Cerrado P-46 (PR #2
mergeado con `--rebase --delete-branch`, gate de conteos leido antes de mergear,
318 archivos y 0 bajo `.github/`), `CORTE_FECHA` paso a `2026-07-27` y Pages
volvio a la frescura del dato. El grueso de la sesion fue P-47: la decision
metodologica P7, heredada sin resolver desde la medicion de la Capa 3, se tomo a
favor de `periodo_vigente.tasa_presencia` como titular del portal, con la tasa
que suma las justificadas como segunda lectura adyacente y `en_ejercicio`
relegado al universo declarado de la tabla de sesiones. Antes de escribir codigo
se verifico contra los 155 perfiles que el `tasa_presencia` del indice es el del
ambito `periodo_vigente` (0 diferencias), lo que dejo el cambio confinado al
frontend y sin tocar el `39`. La revision visual del titular sobre fichas reales
encontro dos defectos de la primera version (una frase sobre inasistencias
justificadas rendida con cero inasistencias, y una nota que afirmaba una
diferencia de denominadores inexistente para quien estuvo en ejercicio todo el
periodo); ambos se corrigieron y se re-verificaron antes del commit `f55430d`,
pusheado a `origin/main`. La sesion registro tres desviaciones del asistente, dos
de ellas del mismo mecanismo PAT-01 sobre reglas distintas, en la sesion
inmediatamente siguiente a aquella en que ese patron concentro cinco de diez
registros.

## 3. Estado al cierre

**Que funciona.** Las tres capas en produccion, servidas desde GitHub Pages, y
por primera vez la Capa 3 visible en la ficha. El refresh semanal automatizado
con rama y PR, ya probado en corrida desatendida (v13 §4.3). `origin/main` =
`f55430d` (fuente: salida de `git push origin main` del 2026-07-27 17:09).
`CORTE_FECHA` = `2026-07-27` (fuente: `grep -n '^CORTE_FECHA'
10_utils/10_configuracion.R` del 2026-07-27, corrido despues del `pull`).

**Que no funciona / que queda abierto.** Nada roto. Ningun PR abierto. Queda sin
verificar por lectura directa que Pages haya terminado de republicar el
`index.html` nuevo: el push se confirmo, la publicacion en el sitio en vivo no se
comprobo en esta sesion y es lo primero que conviene mirar al abrir la proxima.

**Arbol de trabajo local:** sucio por el escaner (snapshots `20260725_125633_*`
borrados por poda, `20260727_105331_*` y `20260727_171109_*` nuevos, aliases
modificados) y por `.claude/settings.local.json` sin trackear (fuente: `git
status -sb` del 2026-07-27 17:08, mas el escaner del cierre). Eso y los tres
documentos de este cierre son lo que falta commitear.

**Delta respecto a v13.**

| Dimension | v13 | v14 |
|---|---|---|
| Capa 3 en la ficha | dato publicado, no mostrado | dos ambitos visibles con glosa |
| Titular de asistencia del portal | `tasa_asistencia` (legacy) | `periodo_vigente.tasa_presencia` |
| Orden del indice | `tasa_asistencia` | `tasa_presencia` |
| Consumo de campos legacy en el frontend | si | **ninguno** (precondicion de P-48 cumplida) |
| `CORTE_FECHA` | 2026-07-25 | 2026-07-27 |
| PRs abiertos | #2 | ninguno |
| `origin/main` | `15be859` + cierre s13 | `f55430d` |
| P7 (decision metodologica) | abierta desde la s11 | **resuelta** |
| Protocolo vigente | v5.4 / v12 (solo en el cierre) | v5.4 / v12 en toda la sesion |

## 4. Registro detallado de cambios

### 4.1 Compuerta de protocolo antes de la Fase A

- **Categoria tematica:** no aplica (gobernanza de sesion).
- **Que se hizo:** se leyeron los encabezados de `POLITICA_PROYECTO.md` y
  `SETTINGS_Y_PROMPTS_OPERACIONALES.md` en la knowledge base antes de cualquier
  otra lectura; declaraban v5.2 y v7. La sesion se detuvo y pidio la
  actualizacion en un mensaje que contenia solo las dos lineas de pedido.
- **Por que:** la s13 ejecuto sus fases A a D contra las versiones viejas y tuvo
  que rehacer el cierre; el mensaje de reapertura de v13 lo puso como primera
  instruccion.
- **Como se verifico:** re-lectura de ambos encabezados tras el aviso del
  titular: v5.4 y v12.
- **Valor de la compuerta:** SETTINGS v12 §2.2.15 (diez campos y etiquetas
  `PAT-NN`) y §2.2.17 (fricciones) rigieron desde el primer registro de esta
  sesion, sin traduccion de taxonomia al cierre.

### 4.2 P-46: merge del PR #2

- **Archivos:** ninguno de codigo; el merge trajo `10_utils/10_configuracion.R`,
  siete `.rds` del corte del 27 y 310 JSON de datos.
- **Categoria tematica:** no aplica (corrida rutinaria del refresh ya
  automatizado; mismo criterio con que v13 excluyo el PR #1).
- **Que se hizo:** lectura del cuerpo del PR (resumen de conteos: 155 perfiles,
  96 397 votaciones, 1 625 mociones, 65 478 votos con proyecto y 30 919 sin
  proyecto, todos con diff `+0`), verificacion data-only por la API paginada
  (318 archivos, 0 bajo `.github/`) y `gh pr merge 2 --rebase --delete-branch`.
- **Por que:** `docs/` en produccion seguia con el corte del 25.
- **Como se verifico:** `git pull --ff-only` local con fast-forward
  `0004771`, y `grep` sobre `10_configuracion.R` mostrando `CORTE_FECHA <-
  "2026-07-27"`.
- **Observacion sobre el gate:** todos los conteos vinieron en `+0`. El gate
  detecta caidas de volumen, no cambios de sentido, y un `+0` en todas las lineas
  es compatible tanto con una semana sin actividad nueva registrada como con un
  problema de captura. No se investigo en esta sesion; ver P-56.

### 4.3 P-47: frontend de la Capa 3

- **Archivo:** `docs/index.html` (unico).
- **Categoria tematica:** interfaz/dashboard (entrada 36 del backlog).
- **Que se hizo:** ocho cambios sobre el frontend, todos de presentacion y
  ninguno de dato. (1) El orden del indice pasa de `tasa_asistencia` a
  `tasa_presencia` y la columna se renombra `Presencia` con `title` que declara
  el denominador comun. (2) El porcentaje grande de la ficha lee
  `rec.tasa_presencia` del indice, de modo que se rinde sin esperar al perfil.
  (3) Las mini-tarjetas leen `p.asistencia.periodo_vigente` y suman una cuarta,
  `Sin registro`, con `title` que declara que no se imputa. (4) Nueva segunda
  lectura `tasa_presencia_o_justificada`, adyacente y nunca titular. (5) Nueva
  glosa de `sin_registro` cuando lo hay. (6) Nueva `buildSesionesSection(p)`,
  espejo de `buildVotacionesSection`: barra apilada de los tres estados sobre
  `en_ejercicio`, tabla colapsada a 16 con boton de expansion, columnas fecha /
  sesion / estado / justificacion. (7) Estado `sesionesExpandidas` con su reset
  por navegacion y su evento `toggle-sesiones`. (8) Dos notas al pie de la tabla:
  la del ambito y la `nota` legible que ya viaja en `alcance_temporal`.
- **Por que:** el dato nominal y la justificacion estaban en el JSON desde la
  sesion 11 y el portal seguia mostrando solo los cinco campos legacy.
- **Como se verifico:** antes de escribir, `jq` sobre un perfil para la forma real
  del bloque `asistencia` y `jq -s` sobre los 155 para el dominio de
  `asistencia` (`asiste` / `no_asiste` / `sin_registro`) y la forma de
  `justificacion`; despues de escribir, `node --check` sobre el bloque `<script>`
  completo y un smoke test de `buildSesionesSection` con los tres estados y una
  justificacion real. Verificacion final: revision visual del titular sobre dos
  fichas reales servidas por HTTP.
- **Dependencias afectadas:** ninguna de backend. El `39` no se toco y los campos
  legacy siguen publicados en el JSON; lo que cambio es que el frontend dejo de
  consumirlos, que es la precondicion de P-48.
- **Tension declarada (B.1 metodologia vs. legibilidad):** la ficha muestra dos
  denominadores distintos a la vez (51 en la cabecera, 69 en la tabla para quien
  lleva mas tiempo). Se resolvio declarandolos en vez de unificarlos: unificar
  exigia elegir entre publicar un numero no comparable o esconder las sesiones
  previas a la instalacion del periodo, y las dos opciones pierden informacion
  que la fuente si entrega.

### 4.4 Decision P7 y las dos correcciones de la revision visual

- **Categoria tematica:** parte de la entrada 36; no se cuenta aparte.
- **Que se hizo:** se presentaron tres opciones al titular con recomendacion
  explicita y eligio la recomendada (ver §8, D18). Luego, sobre fichas reales,
  aparecieron dos defectos de la primera version que el smoke test no cubria (ver
  §6) y se corrigieron antes del commit.
- **Por que importa registrarlo:** los dos defectos son del mismo tipo, condiciones
  no atadas a un predicado observable, y los dos producian exactamente la lectura
  que la Capa 3 existe para evitar.

### 4.5 Registro de ejecucion detallado

Esta sesion no produjo log en `50_documentacion/andamios/logs/`: no hubo encargos
a Claude Code y toda la evidencia vive en los comandos de terminal reproducidos en
este traspaso y en la conversacion. Se declara para que una sesion futura no
busque un archivo inexistente.

## 5. Backlog acumulativo

Vive en `50_documentacion/activa/backlog_acumulativo.md` (archivo canonico,
POLITICA §10). **Delta de esta sesion:** 1 entrada nueva (36),
`interfaz/dashboard` 4->5, suma de la columna 36->37, porcentajes recalculados
sobre 37. Sin categorias nuevas, sin renumeracion ni reescritura de entradas 1-35.
Verificacion programatica del archivo actualizado: 36 entradas, maximo 36, sin
huecos ni duplicados (fuente: recuento sobre el archivo entregado en esta sesion).

**Lo que NO se conto**, declarado para evitar duplicacion futura: el merge del PR
#2 es una corrida rutinaria del refresh ya automatizado (mismo criterio de v13
para el PR #1); las dos correcciones de la revision visual son iteraciones dentro
de la entrada 36; y el `pull` y el push del cierre son operaciones de git
(precedente de la sesion 9).

**Discrepancia heredada, sigue abierta:** la columna de la clasificacion tematica
suma 37 contra 36 entradas numeradas. Mismo signo y misma unidad que arrastra
desde antes de v06. No se corrige en silencio. Nota nueva de esta edicion: los
porcentajes sobre 37 suman 99,9 por redondeo a un decimal, no por una entrada
faltante; queda declarado para que no se lea como una segunda discrepancia.

## 6. Bugs de la sesion

Dos, ambos en codigo escrito en esta misma sesion, ambos detectados por el titular
en revision visual antes del commit y ambos resueltos.

**B-14-01. La segunda lectura se rendia con cero inasistencias.**
*Sintoma observable:* en la ficha de Briones las tarjetas mostraban `0` en "No
asiste" y la linea "Contando las inasistencias justificadas" mostraba 98%, el
mismo valor que el titular. El 2% faltante lo producia el `sin_registro`.
*Causa raiz:* `docs/index.html`, construccion de `segundaLectura`: se rendia
incondicionalmente al cargar el perfil. La frase afirma algo sobre el conjunto de
inasistencias y ese conjunto puede estar vacio.
*Solucion exacta:* la construccion se condiciona a `pvj.n_no_asiste > 0`, y la
glosa de `sin_registro` pasa a ser un bloque independiente con su propia
condicion `pvj.n_sin_registro > 0`.
*Criterio de verificacion:* en una ficha con `n_no_asiste = 0` y
`n_sin_registro = 1` no aparece la linea de justificadas y si la glosa; en una con
`n_no_asiste = 1` y `n_sin_registro = 0`, al reves. Verificado en las fichas 1193
y 1165.
*Patron general aprendido:* ver A50.
*Principios:* B.1 (la presentacion es metodologica), B.4.
*Estado:* resuelto.

**B-14-02. La nota de ambitos afirmaba una diferencia inexistente.**
*Sintoma observable:* en Briones, cabecera y tabla mostraban ambas 51 y la nota
decia "los dos numeros no son intercambiables".
*Causa raiz:* `buildSesionesSection`, construccion de `notaAmbito`: texto unico,
redactado asumiendo el caso general (el diputado que asumio despues de la
instalacion). Para quien estuvo en ejercicio todo el periodo los dos
denominadores coinciden.
*Solucion exacta:* `notaAmbito` bifurca sobre `total !== nPv`, con texto propio
para el caso de coincidencia.
*Criterio de verificacion:* smoke test con los dos casos observados (51/51 y
69/51), que produce las dos notas correctas.
*Patron general aprendido:* ver A50.
*Principios:* B.1, B.4.
*Estado:* resuelto.

## 7. Aprendizajes y restricciones descubiertas

- **A50. Una glosa metodologica es una afirmacion y admite casos vacios.** Los dos
  bugs de esta sesion son el mismo mecanismo: un texto redactado para el caso
  general, rendido incondicionalmente, que en el caso degenerado (conjunto vacio,
  denominadores iguales) afirma algo falso. **Regla:** toda frase que interprete
  una cifra se condiciona al predicado que la hace verdadera, y el predicado se
  escribe explicito (`n_no_asiste > 0`, `total !== nPv`), no se asume por el
  contexto. Corolario para la verificacion: un smoke test de una funcion de render
  cubre los casos limite del **dominio**, no solo un caso tipico; el fixture de la
  primera version tenia inasistencias y denominadores distintos, y por eso los dos
  defectos pasaron. Principio: B.1 y B.4.
- **A51. `gh pr` infiere el repo del directorio; `gh api` lo recibe en la ruta.**
  Un mismo bloque de comandos puede tener la mitad de sus lineas dependientes del
  `cwd` sin que se note. **Regla:** todo subcomando de `gh` que actue sobre un
  repositorio lleva `-R <owner>/<repo>` explicito, igual que todo comando de git
  lleva `git -C <ruta absoluta>`. Principio: C.11 y GR-03.
- **A52. Escribir un archivo en el directorio de salida no es entregarlo.** La
  copia se puede confirmar con `wc -l` y aun asi el titular no ve nada. **Regla:**
  un artefacto esta entregado cuando aparece adjunto en el mismo turno que lo
  anuncia; declarar el destino no sustituye el adjunto. Principio: B.1.
- **A53. Un campo del indice con el mismo nombre que uno del perfil no garantiza
  el mismo ambito.** `tasa_presencia` existe en los dos y su ambito no esta en el
  nombre. Se comprobo comparando los 155 pares indice/perfil, no un caso.
  **Regla:** antes de repuntar un consumidor a un campo nuevo, verificar la
  correspondencia sobre el universo completo y declarar el denominador de esa
  verificacion. Principio: B.4 y A49 de v13.

## 8. Decisiones de diseno

**D18. El titular de asistencia del portal es `periodo_vigente.tasa_presencia`.**
*Alternativas:* (a) mantener el legacy `tasa_asistencia` como titular y poner los
dos ambitos nuevos en un panel secundario; (b) titular
`periodo_vigente.tasa_presencia`, con `tasa_presencia_o_justificada` como segunda
lectura adyacente y `en_ejercicio` relegado a la tabla de sesiones; (c) titular
`periodo_vigente.tasa_presencia_o_justificada`.
*Decision:* (b), tomada por el titular sobre recomendacion explicita del
asistente. Resuelve P7, abierta desde la medicion de la Capa 3.
*Justificacion:* `periodo_vigente` es el unico ambito con denominador comun a las
155 y los 155 y por lo tanto el unico comparable entre personas; el legacy no lo
es (su universo es el snapshot del momento de la descarga, 65 sesiones frente a
las 66 del nominal en el corte anterior) y era precisamente lo que la Capa 3 vino
a reemplazar. Se descarto (c) porque su mediana es 1 y su minimo 0,8958 en los
155: como titular no discrimina y ademas lava la inasistencia. Mostrar presencia
estricta con la justificada al lado publica el matiz sin perder poder
discriminante.
*Tension resuelta:* comparabilidad contra justicia individual. Publicar solo
presencia estricta trata igual una inasistencia justificada por mision oficial y
una sin justificar; publicar solo la tasa que las suma esconde la diferencia. Las
dos cifras conviven con jerarquia declarada.
*Implicancia:* el frontend deja de consumir los campos legacy, que es la
precondicion de P-48. El retiro del contrato ya no tiene bloqueo tecnico.

**D19. Los dos ambitos se declaran, no se unifican.**
*Alternativas:* (a) mostrar un solo denominador y esconder las sesiones previas a
la instalacion del periodo; (b) ofrecer un selector de ambito en la ficha; (c)
titular con `periodo_vigente` y tabla con `en_ejercicio`, con nota que declara la
diferencia.
*Decision:* (c).
*Justificacion:* (a) descarta dato que la fuente si entrega; (b) invita
exactamente a la comparacion invalida que la medicion advierte, porque dos
personas con selectores en posiciones distintas producen numeros que parecen
comparables y no lo son. La nota resuelve el riesgo sin perder informacion.
*Implicancia:* la ficha muestra dos denominadores y el lector necesita la nota
para entenderlos; por eso la nota es obligatoria y bifurca segun el caso (B-14-02).

**D20. `sin_registro` recibe tarjeta propia y glosa, no se pliega a "no asiste".**
*Alternativas:* (a) sumarlo a "no asiste" (es la lectura intuitiva); (b) omitirlo
de la cabecera y dejarlo solo en la tabla; (c) tarjeta propia con glosa explicita.
*Decision:* (c).
*Justificacion:* plegarlo a "no asiste" es imputar, que es exactamente lo que la
Capa 3 se nego a hacer al modelarlo como tercer estado. Omitirlo de la cabecera
lo vuelve invisible en la vista que mas se lee y deja sin explicacion la brecha
entre el porcentaje y 100.
*Implicancia:* la cabecera tiene cuatro tarjetas en 300px y la cuarta muestra `0`
en la mayoria de las fichas. Es el costo de que el tercer estado sea visible.

## 9. Constantes y parametros vigentes (por delta)

| Constante | Valor anterior | Valor nuevo | Archivo | Motivo |
|---|---|---|---|---|
| `CORTE_FECHA` | `2026-07-25` | `2026-07-27` | `10_utils/10_configuracion.R:41` | Lo reinyecto el bot en la corrida del lunes; llego al arbol con el merge del PR #2, no por edicion manual |

Constante nueva declarada en codigo de frontend, sin equivalente en R:
`LIMITE_COLAPSADO = 16` en `buildSesionesSection` de `docs/index.html`, igual al
de `buildVotacionesSection` a proposito (las dos tablas de la ficha colapsan al
mismo numero). El resto de las constantes del proyecto no cambio; las vigentes
viven en `10_utils/10_configuracion.R` y en `CLAUDE.md`.

## 10. Arquitectura de archivos

Escaner al cierre: `50_documentacion/estructura/estructura_actual.md`, snapshot
`20260727_171109` (23 carpetas, 477 archivos; fuente: cabecera del propio
escaner). La estructura no cambio: el unico archivo de codigo tocado ya existia.
El salto de 470 a 477 archivos lo explican los siete `.rds` del corte del 27 que
trajo el merge del PR #2. Desviaciones vigentes contra la estructura canonica,
todas heredadas y ninguna accionable en esta sesion:

1. `30_procesamiento/` parte en `32_` porque `31_explorar_api_camara.R` vive en
   `andamios/`. Hueco correlativo interno, no entre decenas.
2. `tests/` no existe (confirmado por busqueda acotada sobre el escaner de
   apertura). Pendiente de decision explicita del titular (P-49).
3. `50_documentacion/andamios/design_handoff_portal_transparencia/Portal
   Transparencia.dc.html` lleva espacio y mayusculas, contra POLITICA §2.
   **Excepcion permanente declarada** en v13 §10: la carpeta es un andamio
   congelado y su `README.md` lo referencia tres veces.

Elemento nuevo sin trackear: `.claude/settings.local.json` (fuente: `git status
-sb` del 2026-07-27 17:08). Ver P-55.

## 11. Pendientes y ruta sugerida

### 11.1 Inventario

**P-48. Retiro del contrato legacy de asistencia.**
*Contexto:* los cinco campos legacy del bloque `asistencia` y `tasa_asistencia`
del indice siguen publicados y, desde el commit `f55430d`, ningun consumidor los
lee. La precondicion que este pendiente esperaba desde la sesion 11 esta cumplida.
*Tipo:* deuda tecnica con vencimiento. *Impacto:* alto sobre la coherencia del
contrato publicado y sobre el costo de cada refresh (elimina la doble descarga de
asistencia del `33`, marcada `# REVISAR`). *Dependencias:* ninguna viva; encadenaba
a P-47, ya cerrado. *Complejidad:* media. *Principios:* B.1, C.11.
*Precauciones:* toca `33_extraer_asistencia.R` y `39_consolidar_json.R`, o sea
backend y contrato publicado a la vez; exige corrida local con regeneracion previa
de 32-36 (A34) y verificacion de que ningun campo sobreviviente cambia de valor.
El `n_sesiones` legacy y `en_ejercicio.n_sesiones` difieren en un punto por la
sesion 4801 (v13), asi que el retiro tambien cierra esa inconsistencia visible.
*Enfoque:* medir primero que consumidores quedan (buscar los cinco nombres en
`docs/`, `40_salidas/` y `CLAUDE.md`), despues editar el `39`, despues el `33`.
*Criterio de exito:* los campos desaparecen del JSON, el frontend sigue rindiendo
identico, y el refresh descarga la asistencia una sola vez.

**P-49. Decision explicita sobre `tests/`.** *Contexto:* confirmado inexistente
desde la s13. El protocolo admite el "no" declarado; lo que no admite es la
omision silenciosa. *Tipo:* deuda heredada. *Complejidad:* nula (es una decision,
no trabajo). *Criterio de exito:* la decision escrita en el traspaso o en
`CLAUDE.md`.

**P-50. `actions/checkout@v4` -> `@v5`.** *Contexto:* el run emite `Node.js 20 is
deprecated ... forced to run on Node.js 24`. No rompe nada hoy. *Tipo:* higiene.
*Complejidad:* baja. *Precaucion:* cualquier cambio al workflow se valida con una
corrida real, no solo con parseo de YAML (leccion de la s13), y una corrida cuesta
~11 minutos contra la API de la Camara.

**P-51. Discrepancia aritmetica del backlog (columna 37 vs 36 entradas).** *Tipo:*
deuda de memoria. *Precaucion:* exige reclasificar alguna entrada 1-23 con nota
explicita; prohibido corregir en silencio. *Complejidad:* baja en ejecucion, alta
en lectura (obliga a cruzar los traspasos v01-v06).

**P-52. Auditoria de apertura #3 sin verificar** (paquetes, rutas y constantes al
inicio de cada script). *Tipo:* deuda heredada. *Enfoque:* resolver en la sesion
que toque el `33` o el `39`, leyendo el codigo. **Nota:** P-48 toca los dos, asi
que conviene encadenarlo ahi y cerrar los dos de una vez.

**P-53. Capa 4** (P-13, P-7, P-9, P-10 del inventario historico). *Tipo:* decision
de alcance, sin tomar.

**P-54. Revision del contrato S-01 en sesion de cartera.** *Contexto:* el marcador
de fuente en linea se adopto el 2026-07-25; v13 §15 documento una afirmacion falsa
con marcador presente y bien formado, y esta sesion suma dos registros PAT-01 mas
sobre reglas distintas (entorno de comando y materializacion). *Tipo:* gobernanza
de cartera, fuera de este proyecto. *Enfoque:* llevarlo a
`slep_estado_proyectos_monitoreo` con la evidencia de v13 §15 y v14 §15.
*Precaucion:* §2.2.16 obliga a clasificar el tipo de falla antes de reformular; los
tres registros de esta sesion apuntan a forma del output y condicion ambigua, no a
disciplina.

**P-55. Decidir el regimen de `.claude/settings.local.json`.** *Contexto:* aparece
sin trackear en `git status`. *Tipo:* higiene / gobernanza de repo. *Impacto:* bajo,
salvo que el archivo contenga rutas o preferencias locales que no deban publicarse
(el repo es publico). *Complejidad:* nula. *Enfoque:* leerlo, y segun su contenido
versionarlo o agregarlo a `.gitignore`. *Criterio de exito:* `git status` limpio
sin archivos sin trackear tras el cierre.

**P-56. Verificar el `+0` de todos los conteos del PR #2.** *Contexto:* el gate del
corte del 27 reporto diferencia cero en las cinco metricas contra el corte del 25.
Es compatible con dos semanas sin actividad nueva registrada y tambien con un
problema de captura; no se distinguio. *Tipo:* diagnostico. *Impacto:* medio (si
fuera captura, el dato publicado envejece en silencio). *Complejidad:* baja.
*Enfoque:* comparar `sesiones_alcance` y `fecha_ultima` de `alcance_temporal` entre
los dos cortes; si tampoco se movieron, el `+0` es real. *Precaucion:* no disparar
el workflow para comprobarlo (los intermedios del 25 y del 27 estan ambos en
`20_insumos/`).

### 11.2 Evaluacion de deuda tecnica

Zona fragil unica y nueva: la ficha publica ahora dos denominadores distintos y su
correccion depende de dos condicionales de render (`n_no_asiste > 0`,
`total !== nPv`) que no tienen prueba automatica; su unica verificacion fue visual
y un smoke test manual. Si el `39` cambia la forma del bloque `asistencia`, el
frontend falla en silencio o vuelve a afirmar de mas. Mitigacion vigente: los dos
condicionales estan comentados en el codigo con su motivo. Oportunidad de mejora:
P-48 va a tocar el `39` y es el momento natural para re-verificar los dos casos
limite; hacerlo entonces cuesta un smoke test y no una sesion.

El workflow semanal sigue siendo la otra zona fragil (v13 §11.2), sin cambios y
con una corrida desatendida mas de evidencia acumulada.

### 11.3 Auditoria de cierre (POLITICA 5.6)

| # | Pregunta | Respuesta |
|---|---|---|
| 2 | ¿El pipeline corre de cero sin intervencion manual? | **Si**, sin cambio: esta sesion no toco el pipeline; la evidencia sigue siendo la corrida desatendida del 27 |
| 5 | ¿Cada transformacion critica tiene check de validacion? | **Si** para el pipeline. **Parcial** para el frontend: los dos condicionales de render solo tienen verificacion manual. No se agrega pendiente nuevo porque queda encadenado a P-48 (§11.2) |
| 6 | ¿Los outputs son reproducibles e idempotentes? | **Si**, sin cambio: el frontend es una funcion pura del JSON y no persiste estado |
| 7 | ¿Decisiones metodologicas como constantes nombradas? | **Si.** D18 y D20 viven como eleccion de campo y condicionales explicitos, comentados con su motivo; `LIMITE_COLAPSADO` esta nombrada |
| 8 | ¿Nombres sin tildes, ñ ni espacios? | **Si, con una excepcion declarada** (§10, punto 3) |

Ninguna respuesta "no": no se agregan pendientes por esta via. La respuesta
"parcial" de la #5 queda documentada en §11.2 y encadenada a P-48.

### 11.4 Ruta sugerida para la sesion 15

1. **Verificar Pages** con el `index.html` nuevo en el sitio en vivo. Dos minutos;
   es lo unico de la sesion 14 que quedo sin comprobar por lectura directa.
   *Criterio:* la ficha en `tomgc.github.io` muestra las cuatro tarjetas y la
   tabla de sesiones.
2. **P-48** (retiro del contrato legacy), sesion dedicada. Es prioridad 1 real por
   los criterios de 1.2.4: no hay bugs activos ni bloqueantes, y es deuda tecnica
   con vencimiento que ya no tiene precondiciones. *Criterio:* el definido en su
   ficha. Encadenar **P-52** en la misma sesion, que toca los mismos dos scripts.
3. **P-56** (verificar el `+0`) antes o durante P-48: usa los intermedios ya
   descargados y no cuesta corridas.
4. **P-55 y P-49** al final si sobra sesion (dos decisiones, sin trabajo).

**Conviene diferir:** P-50 (exige una corrida real de 11 minutos que no conviene
mezclar con un cambio de contrato), P-51, P-53 y P-54. Ninguno bloquea nada.

## 12. Instrucciones especificas para la proxima sesion

- ⚠️ **NO** afirmar el estado de `CORTE_FECHA` sin leer
  `10_utils/10_configuracion.R`: el bot lo reescribe en cada corrida y cada merge
  de PR lo cambia en `main`.
- ⚠️ **NO** mergear un PR del bot sin leer el resumen de conteos de su cuerpo: el
  gate detecta caidas de volumen, no cambios de sentido, y un `+0` en todas las
  lineas tampoco es por si mismo una senal de que todo esta bien (P-56).
- ⚠️ **NO** usar `gh pr diff --name-only` sobre PRs de este proyecto (A45); usar la
  API paginada de `/pulls/<n>/files` y declarar el denominador.
- ⚠️ **NO** disparar el workflow por `workflow_dispatch` para comprobar algo que se
  puede leer por API o en los intermedios ya descargados: cada corrida cuesta ~11
  minutos y golpea la API de la Camara.
- ⚠️ **NO** emitir un subcomando `gh pr` sin `-R tomgc/transparencia_legislativa_chile`
  (A51), igual que ningun comando de git va sin `git -C <ruta absoluta>`.
- ✅ **ANTES** de cualquier corrida local, regenerar 32-36 (A34).
- ✅ **ANTES** de tocar el workflow, leer el archivo completo: es el unico mecanismo
  automatico que escribe hacia produccion.
- ✅ **ANTES** de afirmar que algo aparece o no en el escaner, acotar el grep a la
  seccion sobre la que se afirma (A49).
- ✅ **ANTES** de repuntar un consumidor a un campo nuevo, verificar la
  correspondencia sobre el universo completo y declarar el denominador (A53).
- ✅ **ANTES** de dar por entregado un artefacto, comprobar que quedo adjunto en el
  mismo turno que lo anuncia (A52).
- ✅ **ANTES** de escribir una glosa que interprete una cifra, atarla al predicado
  que la hace verdadera y probar el caso vacio (A50).
- 🔒 El gate de conteos aborta el job sin publicar rama ni PR. Intocable.
- 🔒 El commit condicional: sin cambios, sin rama y sin PR. Intocable.
- 🔒 `main` no recibe escrituras automaticas del bot.
- 🔒 El `--force` del workflow vive acotado por refspec a `refresh/*`. Nunca a `main`.
- 🔒 `sin_registro` no se imputa: ni en el dato ni en la presentacion. Rebajas
  publicadas pero fuera de toda formula y de todo conteo mientras P2 siga abierta.
  Territorio como insumo estatico auditado. El backlog nunca se renumera.
- 🔒 El titular de asistencia del portal es `periodo_vigente.tasa_presencia` (D18).
  Cambiarlo es rehacer P7, no un ajuste de interfaz.

## 13. Fragmentos de codigo de referencia

Solo lo nuevo o corregido en esta sesion. Los patrones estables viven en
`CLAUDE.md` y en v11 §13; el verificador de numeracion del backlog, en v13 §13.

**Verificar que un campo del indice y uno del perfil son el mismo ambito** (A53;
el nombre del campo no lleva el ambito):

```bash
R=/Users/tomgc/Projects/transparencia_legislativa_chile
jq -r '.[] | "\(.id) \(.tasa_presencia)"' "$R/docs/data/indice_diputados.json" | sort > /tmp/idx.txt
for f in "$R"/docs/data/perfiles/*.json; do
  echo "$(basename "$f" .json) $(jq -r '.asistencia.periodo_vigente.tasa_presencia' "$f")"
done | sort > /tmp/pv.txt
echo "indice: $(wc -l < /tmp/idx.txt) | perfiles: $(wc -l < /tmp/pv.txt) | difieren: $(diff /tmp/idx.txt /tmp/pv.txt | grep -c '^<')"
```

**Leer la forma de un bloque del perfil sin volcar la serie completa** (util
cuando el bloque trae un arreglo largo):

```bash
jq '.asistencia | del(.sesiones) + {sesiones: (.sesiones[0:2])}' \
  /Users/tomgc/Projects/transparencia_legislativa_chile/docs/data/perfiles/1165.json
```

**Comprobar el dominio real de un campo sobre los 155 perfiles antes de escribir
el `switch` que lo consume:**

```bash
R=/Users/tomgc/Projects/transparencia_legislativa_chile
jq -s '[.[].asistencia.sesiones[].asistencia] | unique' "$R"/docs/data/perfiles/*.json
```

**Chequeo de sintaxis del bloque `<script>` de un HTML de una sola pieza**, antes
de entregarlo (no requiere navegador):

```bash
python3 - <<'EOF'
import re
s=open('index.html').read()
open('check.js','w').write(re.search(r'<script>\n(.*)</script>', s, re.S).group(1))
EOF
node --check check.js && echo "SINTAXIS OK"; rm -f check.js
```

**Comandos de `gh` sobre un repo, con destino explicito** (A51):

```bash
gh -R tomgc/transparencia_legislativa_chile pr view <n> --json body --jq .body
gh -R tomgc/transparencia_legislativa_chile pr merge <n> --rebase --delete-branch
```

## 14. Reapertura

**Mensaje de apertura pre-armado:**

> Tipo: CONTINUATION. El protocolo (`POLITICA_PROYECTO.md` v5.4,
> `SETTINGS_Y_PROMPTS_OPERACIONALES.md` v12) vive en la knowledge base del Project
> y se lee desde ahi; verifica que esten en esas versiones antes de la Fase A.
> Estado: las tres capas en produccion y la Capa 3 ya visible en la ficha
> (`f55430d` pusheado a `origin/main`), P7 resuelta a favor de
> `periodo_vigente.tasa_presencia` como titular del portal, sin PRs abiertos y sin
> bugs activos. Lo unico de la sesion 14 que quedo sin comprobar por lectura
> directa es que Pages haya republicado el `index.html` nuevo: verificalo primero.
> `CORTE_FECHA` cambia con cada merge de PR del bot, asi que confirmalo en
> `10_utils/10_configuracion.R` antes de afirmarlo. El foco propuesto es P-48, el
> retiro del contrato legacy de asistencia, que quedo sin precondiciones al cerrar
> P-47, encadenando P-52 y P-56 en la misma sesion. Adjunto:
> `traspaso_cierre_v14.md`, `estructura_actual.md`.

**Documentos para la sesion 15:**

1. *Protocolo en knowledge base* (NO adjuntar; verificar que este al dia):
   `POLITICA_PROYECTO.md` v5.4, `SETTINGS_Y_PROMPTS_OPERACIONALES.md` v12.
2. *Opcionales segun el foco real:* `CLAUDE.md` si el trabajo corre en Claude Code;
   `33_extraer_asistencia.R` y `39_consolidar_json.R` si se aborda P-48 (son los
   archivos que se van a leer y reescribir, imprescindibles en ese caso);
   `docs/index.html` si el retiro obliga a re-verificar el frontend;
   `10_utils/10_configuracion.R` para el valor vigente de `CORTE_FECHA`;
   `backlog_acumulativo.md` solo si se aborda P-51;
   `encargo_autonomo_claude_code_v1.md` si P-48 se delega a Claude Code.
3. *Si se adjuntan:* `traspaso_cierre_v14.md`; `estructura_actual.md`.

**Nota final obligatoria:** si algun archivo listado cambio entre sesiones,
adjuntar la version mas actualizada al abrir y avisarlo en el mensaje de apertura.
En particular, `10_utils/10_configuracion.R` habra cambiado si se mergeo un PR del
bot, y `estructura_actual.md` si se volvio a correr el escaner.

## 15. Errores del asistente (POLITICA 0.5, SETTINGS §2.2.15)

Tres registros, todos del asistente conversacional. Formato de diez campos
(SETTINGS v12), etiquetas del catalogo
`herramientas_dev/gobernanza/catalogo_patrones_errores_v2.md`. A diferencia de
v13, esta sesion opero contra v12 desde el primer turno, asi que no hay traduccion
de taxonomia.

---

**E-14-01**

| Campo | Contenido |
|---|---|
| `momento` | Turno de apertura de P-46, bloque de comandos de terminal |
| `disparador` | usuario lo corrigio (los dos comandos fallaron con `not a git repository`) |
| `que_paso` | Prescribio `gh pr view` y `gh pr merge` sin `-R <owner>/<repo>`, dependientes del `cwd`, en el mismo bloque donde los `gh api` si llevaban el repo explicito |
| `regla_violada` | SETTINGS §1.2.6 (ningun comando asume el entorno de ejecucion); `userPreferences`, edicion de codigo: ruta completa desde la raiz del proyecto en todo comando de terminal |
| `causa_raiz` | Trato `gh` como un binario uniforme respecto del repo destino: los subcomandos de API lo reciben en la ruta y los de `pr` lo infieren del remoto del `cwd`. La asimetria estaba dentro del propio bloque emitido y no se leyo |
| `salvaguarda_presente` | SETTINGS + userPreferences + A46 de v13 (misma familia: el instrumento no comprueba lo que se supone) |
| `patron` | PAT-01, sobre premisa acerca del entorno de ejecucion de un comando dada por verdadera |
| `gatillo_observable` | `comando-entorno`: emitir un comando cuyo repositorio destino se infiere del directorio de trabajo en vez de declararse |
| `intentos_previos` | 1 (E-13-07 de la sesion 13, mismo mecanismo sobre `git branch -d`, cerrado como A46 el dia anterior) |
| `costo` | un turno; ninguna accion destructiva ocurrio (el merge no se ejecuto) y la verificacion data-only si devolvio dato valido |

**E-14-02**

| Campo | Contenido |
|---|---|
| `momento` | Cierre del turno de ejecucion de P-47 y turno siguiente |
| `disparador` | usuario lo corrigio ("no me has entregado nada") |
| `que_paso` | Declaro el destino del `index.html` y describio sus cambios sin adjuntar el archivo, y en el turno siguiente le pidio al titular moverlo |
| `regla_violada` | `userPreferences`, materializacion: todo artefacto persistente se entrega COMO ARCHIVO; POLITICA §0.6 tipo 1 (contenido o ruta de un archivo no leido) |
| `causa_raiz` | Tomo la escritura en el directorio de salida como equivalente a la entrega. El paso que hace visible el archivo al titular no estaba en la cadena verificada: la copia se confirmo con `wc -l` y esa confirmacion se leyo como prueba de entrega |
| `salvaguarda_presente` | userPreferences (materializacion) |
| `patron` | PAT-01, sobre acto de entrega dado por cumplido al haberlo declarado |
| `gatillo_observable` | `entrega-sin-destino-o-nombre`: afirmar un destino de archivo sin que el archivo haya sido adjuntado en el mismo turno |
| `intentos_previos` | 1 (E-14-01 de esta misma sesion: mismo mecanismo, premisa dada por verdadera sin comprobarla) |
| `costo` | dos turnos, uno de ellos con instrucciones de verificacion sobre un archivo inexistente |

**E-14-03**

| Campo | Contenido |
|---|---|
| `momento` | Verificacion de la primera version del frontend, antes de la revision visual del titular |
| `disparador` | usuario lo señalo sin nombrarlo error (mostro dos capturas y pregunto si se veian bien) |
| `que_paso` | Declaro el frontend verificado citando `node --check` y un smoke test cuyo fixture tenia inasistencias y denominadores distintos, o sea ninguno de los dos casos limite que despues fallaron (B-14-01 y B-14-02) |
| `regla_violada` | SETTINGS §1.2.6 (generar-verificar-consumar: el paso de verificacion debe condicionar el consumidor) y B.4 (criterio contrastable) |
| `causa_raiz` | Construyo el fixture copiando la forma del perfil que habia inspeccionado (1165, con una inasistencia y 69 vs 51), en vez de derivarlo del dominio de los campos que el render condiciona. El caso tipico se tomo como cobertura suficiente |
| `salvaguarda_presente` | SETTINGS + A45 de v13 (un chequeo que no discrimina no es un chequeo) |
| `patron` | PAT-02, sobre verificacion que no cubre el dominio del predicado que condiciona la salida |
| `gatillo_observable` | `iteracion-sin-criterio`: declarar verificado un render condicional habiendo probado un solo punto del dominio de sus condiciones |
| `intentos_previos` | 0 |
| `costo` | dos defectos llegaron a la revision visual del titular; ninguno llego al commit ni a produccion, y el costo real fue un ciclo de correccion y re-entrega |

---

### Analisis de patron y clasificacion §2.2.16

**PAT-01 concentra dos de los tres registros** (E-14-01 y E-14-02), en la sesion
inmediatamente siguiente a aquella en que el mismo patron concentro cinco de diez.
Lo relevante para la cartera no es la frecuencia sino que las dos ocurrencias son
sobre **reglas distintas** (entorno de un comando, materializacion de un
artefacto) y ninguna de las dos es del tipo que S-01 vigila: el marcador de fuente
cubre afirmaciones sobre archivos, repo, cifras y premisas de encargo, y aqui lo
que se dio por verdadero fue **un acto propio** (el comando funcionara, el archivo
quedo entregado). El mecanismo comun es tratar como consumado algo que solo fue
declarado.

**Clasificacion de la falla (SETTINGS §2.2.16), para la sesion de cartera y no
para legislar aqui:**

- E-14-01 es de **condicion ambigua**: la regla de no asumir el entorno existe,
  pero no esta atada a un predicado observable por familia de comando. El arreglo
  adecuado es un condicional explicito ("si el comando actua sobre un repo,
  declara el repo"), no una prohibicion mas enfatica.
- E-14-02 es de **forma del output**: el contrato de materializacion define que el
  artefacto se entrega como archivo, pero no define que el adjunto sea parte
  verificable del turno. El arreglo adecuado es una receta positiva del turno de
  entrega, no un recordatorio.
- E-14-03 es de **omision**: falta un elemento de algo que el asistente ya
  produce (el fixture existe; le faltan los casos limite del dominio). El arreglo
  adecuado es un slot obligatorio en el plan de verificacion, no una regla nueva.

Ninguno de los tres es de disciplina. Endurecer las prohibiciones existentes
contaria como reformulacion fallida en el proximo ciclo. Ver P-54.

### Fricciones (SETTINGS §2.2.17)

- `friccion: un bloque de comandos mezclo la puesta en marcha de http.server con comandos posteriores, que quedaron sin ejecutar porque el servidor toma el primer plano → los comandos que bloquean la terminal se emiten solos y se avisa que el resto va en otra pestaña.`
- `friccion: se ofrecio una URL con la ruta de hash equivocada (#/perfil/) sin leer parseHash → la ruta se leyo del archivo entregado antes de emitirla.`
