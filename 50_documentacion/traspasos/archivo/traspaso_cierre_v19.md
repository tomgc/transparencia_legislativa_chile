# Traspaso de cierre v19 — transparencia_legislativa_chile

## §1. Identificación

| Campo | Valor |
|---|---|
| Proyecto | `transparencia_legislativa_chile` |
| Versión | v19 |
| Fecha de cierre | 2026-08-13 |
| Sesión | 19 |
| Foco | Cerrar las dos deudas declaradas del PR #9 (P-76 y P-77, los dos huecos de la guarda de arranque) y, con la ruta aprobada, ratificar D31, resolver el destino de las capturas en cuarentena e instalar la guarda de locale UTF-8 (P-59). |
| Entorno | R 4.5.2 en Positron, macOS; Claude Code como agente de ejecución; runner Ubuntu para el refresh semanal |
| Protocolo | `POLITICA_PROYECTO.md` v5.6 y `SETTINGS_Y_PROMPTS_OPERACIONALES.md` v23, ambas verificadas contra la knowledge base en la Fase A |
| `main` | `97dab39` (**previo al commit de cierre**) |
| Archivos principales modificados | `10_utils/10_utils.R`, `10_utils/10_configuracion.R`, `10_utils/10_diff_conteos.R`, `10_utils/10_locale.R` (nuevo), `00_escanear_proyecto.R`, `.gitignore`, `50_documentacion/activa/decisiones/20260812_decision_contrato_temporal_captura.md` (nuevo), `50_documentacion/activa/50_locale_utf8.md` (nuevo) |

## §2. Resumen ejecutivo

La sesión se propuso cerrar P-76 y P-77 en un solo PR, y lo hizo con 14 de 14
criterios medidos. P-76 era una asimetría conocida (el escape de arranque no se
apagaba al usarse, a diferencia del escape del contrato temporal); P-77 era el
estado que la guarda no sabía distinguir: "nunca hubo intermedios" y "había y
los borraron" producían el mismo conteo, así que borrar los intermedios sin
tener capturas del corte terminaba descargando el año completo en vez de
detenerse. El diseño que el encargo proponía murió en su propia compuerta:
`40_salidas/intermedios/.gitkeep` está trackeado, así que el directorio existe
en todo checkout y no discrimina nada. La medición forzó un tercer diseño, el
rastro propio escrito por la guarda, que resuelve lo mismo sin tocar el
orquestador. Con esa ruta cerrada, la sesión ratificó D31 y la materializó como
archivo, resolvió descartar las 6 capturas en cuarentena del corte 2026-08-09, e
instaló la guarda de locale UTF-8 en cuatro puntos de arranque tras descartar,
también por medición, el punto que parecía obvio. Quedan dos PR abiertos y
completos (#11 y #12), ninguno mergeado, y un pendiente nuevo (P-82) que el
propio panel adversarial levantó y que se decidió no arreglar dentro del
alcance. El proyecto cierra sin bugs activos y con los dos gatillos de protocolo
en distinto estado: 4ter apagado, 4bis todavía encendido.

## §3. Estado al cierre

**Qué funciona.** El pipeline completo, verificado en producción en la sesión
anterior (corrida del bot con 10 de 10 pasos) y no vuelto a correr entero en
esta. `CORTE_FECHA` es `2026-08-12` (fuente: G6 de la corrida de P-76/P-77). Los
6 intermedios existen y ninguno declara el corte vigente, estado normal entre
merges del bot; las 6 capturas exigidas del corte vigente están presentes, así
que la próxima corrida local regenera desde caché sin red.

**Qué no funciona.** Nada activo. Los dos PR de esta sesión están completos y
sin mergear:

| PR | Rama | Contenido | Criterios | Último commit |
|---|---|---|---|---|
| #11 | `fix/p76-p77-guarda-arranque` | P-76, P-77 y la corrección de la primera línea del `stop()` | 14 de 14 CUMPLE | `c072d1e` |
| #12 | `chore/p59-locale-utf8` | Guarda de locale UTF-8 en cuatro puntos | 9 de 9 CUMPLE | `9af1a9c` |

El #11 va primero: `CLAUDE.md` espera su merge para que la entrada de P-59 no
choque.

**Delta respecto a v18.** El escape de arranque pasó de permanente a un solo
uso. La guarda distingue por primera vez el arranque legítimo del borrado de
intermedios. El proyecto tiene una guarda de locale que antes no tenía y el
gatillo 4ter queda apagado con marcador. D31 dejó de vivir solo en el traspaso.
Las 6 capturas en cuarentena dejan de ser una pregunta abierta.

## §4. Registro detallado de cambios

### 4.1 P-76 — El escape de arranque se consume al usarse

**Archivos:** `10_utils/10_utils.R`. **Categoría:** automatización.

`camara.permitir_descarga_inicial` se leía con `getOption()` y nunca se apagaba.
Como `run_all()` corre los seis pasos con `source()` en la misma sesión de R,
encenderla para un caso la dejaba encendida para todo lo que seguía. Se extrajo
el consumo a un helper genérico, `consumir_escape(opcion, nota, origen)`, con
`consumir_escape_captura()` convertido en envoltorio que conserva nombre, firma
y texto de log byte a byte, y un `consumir_descarga_inicial()` nuevo que la rama
autorizada invoca antes de devolver.

**Verificación (B.4):** C1 (la opción queda en `FALSE` tras usarse), C2 (dos
pasadas en la misma sesión: la primera pasa, la segunda se detiene), C3 (la
línea de log del escape de captura idéntica a la de `HEAD`), C8 (9 de 9
funciones protegidas idénticas a `HEAD`).

**Tensión resuelta:** el refactor tocaba una función invocada desde dos
funciones protegidas. Se resolvió introduciendo el helper *por debajo* del
nombre existente, en vez de reescribir los sitios de invocación.

### 4.2 P-77 — Distinguir el arranque del borrado de intermedios

**Archivos:** `10_utils/10_utils.R`, `.gitignore`. **Categoría:**
automatización.

La rama de primera corrida se decidía solo por `n_en_disco == 0`, que es
verdadero tanto en un checkout fresco como después de un `rm *.rds`. El segundo
caso terminaba descargando el año completo. Ahora la rama exige además que un
rastro no exista: `40_salidas/intermedios/arranque_registrado.txt`, gitignorado,
escrito por la propia guarda al tomar la rama de arranque. Con rastro presente y
0 intermedios, el flujo cae en la lógica de desalineados, que ya hacía lo
correcto: regenera sin red si las capturas del corte están, y se detiene con
mensaje accionable si faltan.

**Por qué (C.11):** el estado ambiguo no se adivina, se mide contra un rastro en
disco; y el rastro debía existir sin depender de qué haga cada extractor, porque
la compuerta G4 midió que ninguno crea ese directorio.

**Verificación (B.4):** C4 (estado runner: la guarda no se detiene y el proceso
muere en el fusible, no en la guarda), C5 (6 de 6 `cache hit`, exit 0, fusible
sin disparar), C6 (`stop()` con mensaje que nombra el caso), C7 (con
autorización declarada pasa y deja la opción apagada), C13 (`.gitkeep` sigue
trackeado, mismo blob que `origin/main`).

**Adopción retroactiva.** Con un solo punto de escritura, el rastro solo nacería
en copias que pasen por un arranque, y una instalación con intermedios ya en
disco nunca pasa por ahí: P-77 habría quedado abierto en la copia del titular.
La guarda escribe el rastro también cuando hay intermedios y no hay rastro. Es
decisión del titular de esta sesión, no una desviación del encargo.

### 4.3 Corrección de la primera línea del `stop()` de la guarda

**Archivos:** `10_utils/10_utils.R`. **Categoría:** automatización.

Detectada por el panel adversarial del propio PR y puesta en alcance por el
titular. Ver §6.

### 4.4 D31 materializada como archivo de decisión (P-78)

**Archivos:** `50_documentacion/activa/decisiones/20260812_decision_contrato_temporal_captura.md`.
**Categoría:** documentación. **Commit:** `97dab39` en `main`.

La decisión operaba en el código desde el PR #8 pero vivía solo en el traspaso.
El archivo registra qué afirma y qué **no** afirma una captura sobre su alcance
temporal, las dos alternativas descartadas, la tensión con A67, las siete piezas
de la implementación y los dos pendientes que la decisión abre (P-79, P-81).

### 4.5 P-59 — Guarda de locale UTF-8 en cuatro puntos de arranque

**Archivos:** `10_utils/10_locale.R` (copia byte a byte de la plantilla),
`10_utils/10_configuracion.R`, `10_utils/10_diff_conteos.R`,
`00_escanear_proyecto.R`, `50_documentacion/andamios/medir_fuente_territorio.R`,
`50_documentacion/activa/50_locale_utf8.md`. **Categoría:** infraestructura.

El gatillo 4ter llevaba dos aperturas encendido. La instalación no fue mecánica:
la compuerta G3 midió que `10_utils/10_configuracion.R` cubre 19 de 28 archivos
`.R` y deja fuera al escáner y a `10_diff_conteos.R`, cuyo texto termina en el
mensaje de commit y en el cuerpo del PR del bot, es decir, en el historial
público. La compuerta G6 descartó el punto más ancho (`10_utils.R`, 21 de 28)
porque resolver la ruta del helper desde ahí exige `here::` o `rprojroot::`
justo en el archivo que define `instalar_si_falta()` y que `00_run_all.R` carga
tres líneas antes de llamarla: circularidad de arranque, medida con
`.libPaths(character(0))`.

**Verificación (B.4):** C1 (md5 idéntico origen y copia), C2 (el gatillo se
apaga con sus dos evidencias, no con un proxy), C4 en tres mitades (con
`LC_ALL=C LANG=C` la guarda corrige y lo declara; sin candidatas viables aborta;
con `LANG=es_ES.UTF-8` pasa sin corregir), C5 (0 silenciadores), C6 (6 de 6
cadenas con tildes y `ñ` vuelven `identical()`), C9 (0 huérfanos sobre los 13
archivos alcanzables desde las 3 raíces).

**Tensión resuelta:** cobertura contra restricción de arranque. Se prefirió
repetir una línea legible en cuatro archivos que ya resuelven `ROOT` por su
cuenta, antes que introducir en `10_utils.R` un mecanismo (`ofile` del frame de
`source()`) que ningún otro archivo del proyecto usa.

## §5. Backlog acumulativo

Vive en `50_documentacion/activa/backlog_acumulativo.md`. El delta de esta
sesión va en el bloque BACKLOG_DELTA de este paquete: 3 entradas nuevas (56-58).

## §6. Bugs de la sesión

**Bug 1 — La primera línea del `stop()` de la guarda contaba archivos
inexistentes.**

| Campo | Contenido |
|---|---|
| Síntoma observable | Con 0 intermedios en disco, el mensaje afirmaba "6 de 6 intermedios NO corresponden al corte vigente": un conteo mayor que el número de archivos que existen |
| Causa raíz | `desalineados` agrega dos estados distintos (el intermedio existe y declara otro corte; el intermedio no existe) en una sola cifra, y el mensaje leía esa cifra como si solo describiera el primero |
| Solución | `10_utils/10_utils.R`, primera línea del `stop()` de `regenerar_intermedios_si_desalineados()`: tres formas según el hecho (solo desalineados presentes, solo ausentes, mixto). Ninguna otra línea del mensaje se tocó |
| Verificación | C14, en los dos sentidos: con 0 en disco la frase vieja **no** aparece; con los 6 presentes y desalineados la frase vieja aparece literal |
| Patrón aprendido | Una cifra que agrega dos estados distintos miente en el caso en que solo uno de los dos ocurre. Es la misma forma de A74 (medir el hecho, no el proxy), aplicada a un mensaje en vez de a una condición |
| Principios | Fallo ruidoso; B.4 |
| Estado | **Resuelto** en el PR #11, pendiente de merge |

Bugs activos heredados: ninguno.

## §7. Aprendizajes y restricciones descubiertas

- **A78.** Un archivo trackeado dentro de un directorio (`.gitkeep`) convierte la
  existencia de ese directorio en una constante del repositorio, no en una señal.
  Antes de usar `dir.exists()` como discriminante, medir qué trackea git ahí:
  `git ls-files <dir>`. *Contexto:* el diseño A del encargo de P-76/P-77 murió
  exactamente aquí, y de haberse implementado habría detenido al runner en cada
  corrida, reintroduciendo P-65 en forma invertida.
- **A79.** Un helper sin dependencias no es un helper instalable en cualquier
  parte: lo que puede romper la restricción del anfitrión es cómo se **resuelve
  su ruta**, no lo que el helper hace. *Contexto:* el helper de locale no usa
  ningún paquete, pero cargarlo desde `10_utils.R` exigía `here::` o
  `rprojroot::` en el archivo que define `instalar_si_falta()`.
- **A80.** Una prueba de guarda de entorno corrida en una máquina que ya cumple
  el invariante no distingue "la guarda funciona" de "no hacía falta". Se prueba
  en subproceso con el entorno forzado, y en las dos direcciones.
- **A81.** Un criterio de cobertura necesita declarar su universo antes que su
  numerador. "0 huérfanos" sobre todos los `.R` del repositorio obligaba a
  instalar guardas en reproductores congelados; sobre los alcanzables desde las
  raíces declaradas, mide lo que importa. El universo se calcula por cierre
  transitivo desde raíces nombradas, no por lista a mano.
- **A82.** Un escape de un solo uso y otro permanente en la misma función son
  una asimetría que sobrevive a las pruebas, porque cada uno pasa las suyas. La
  simetría entre guardas hermanas se verifica explícitamente, no se supone.

## §8. Decisiones de diseño

**D33 — El rastro de arranque es un archivo propio escrito por la guarda.**

- *Decisión:* `40_salidas/intermedios/arranque_registrado.txt`, gitignorado,
  escrito por `regenerar_intermedios_si_desalineados()` al tomar la rama de
  arranque y también, retroactivamente, cuando hay intermedios sin rastro.
- *Alternativas:* (A) usar `dir.exists()` del directorio de intermedios,
  descartada porque `.gitkeep` lo hace existir siempre; (B) un ledger escrito al
  término de `run_all()`, descartada por exigir tocar el orquestador; (C)
  destrackear `.gitkeep`, descartada porque la ruta de recuperación que la propia
  guarda imprime corre extractores sueltos y `escribir_atomico()` no crea
  directorios.
- *Justificación:* logra lo mismo que (B) sin ampliar la superficie, y es el
  único rastro que no depende de qué haga cada extractor.
- *Limitaciones declaradas:* `rm -rf` del directorio completo vuelve a leerse
  como arranque (mismo estado que un clon fresco, y además borra `.gitkeep`, lo
  que sí es visible en `git status`); una primera corrida que muera después de
  escribir el rastro y antes de escribir intermedios exigirá la opción declarada
  en el intento siguiente; y en una copia preexistente el rastro nace en la
  primera corrida posterior al merge, no antes.
- *Implicancia:* el pipeline no detecta el entorno de CI, consistente con D32.

**D34 — La guarda de locale se instala en cuatro puntos explícitos, no en
`10_utils.R`.**

- *Decisión:* `10_utils/10_configuracion.R`, `10_utils/10_diff_conteos.R`,
  `00_escanear_proyecto.R` y `50_documentacion/andamios/medir_fuente_territorio.R`,
  cada uno resolviendo la ruta como ya lo hace hoy.
- *Alternativas:* `10_utils.R` con `ofile` del frame de `source()` (base R puro,
  pero mecanismo inédito en el proyecto y en el archivo más cargado); solo
  `10_configuracion.R` (dejaba fuera el camino cuyo texto llega al historial
  público).
- *Justificación:* cero mecanismos nuevos; la restricción de cero dependencias de
  `10_utils.R` queda intacta.
- *Tensión resuelta:* cobertura contra legibilidad a seis meses. Ganó repetir una
  línea conocida cuatro veces.

**D35 — La cobertura de la guarda de locale se mide sobre el universo
alcanzable.**

- *Decisión:* el denominador son los archivos `.R` alcanzables por cierre
  transitivo desde tres raíces (`00_run_all.R`, `refresh-semanal.yml`,
  `00_escanear_proyecto.R`): 13 de 30. Los cuatro reproductores congelados de
  `20_insumos/exploracion/20260807/` quedan excluidos, nombrados uno por uno con
  su razón y la fecha de su auditoría, en el marcador y en el log.
- *Alternativas:* sumarlos como puntos 5 a 8, descartada porque instala guarda en
  código congelado que por definición no se vuelve a correr.
- *Implicancia:* si alguno de esos cuatro se corre a mano, corre sin la guarda, y
  el marcador lo dice.

**D31 — Ratificada** (sesión 19) y materializada en
`50_documentacion/activa/decisiones/20260812_decision_contrato_temporal_captura.md`.
Cierra P-78.

**P-80 resuelto — Las 6 capturas del corte 2026-08-09 en cuarentena se
descartan.** Están bien formadas y fueron las primeras con registro del contrato,
pero son producto de una descarga no solicitada y su corte nunca fue el vigente.
Conservarlas obligaría a explicar en un repositorio público un corte que nadie
publicó, y no aportan dato que las capturas del corte 2026-08-12 no tengan. El
borrado de la carpeta de cuarentena, fuera del repositorio, es tarea manual del
titular.

## §9. Constantes y parámetros

| Constante | Valor anterior | Valor nuevo | Archivo | Motivo |
|---|---|---|---|---|
| `RASTRO_ARRANQUE` | no existía | `"arranque_registrado.txt"` | `10_utils/10_utils.R` | Nombre del rastro de D33, constante nombrada en vez de literal repartido |

`CORTE_FECHA` no cambió en esta sesión: sigue en `2026-08-12` y su fuente
canónica es `10_utils/10_configuracion.R`.

## §10. Arquitectura de archivos

Escáner regenerado en el cierre; su sello queda en el log de cierres. Cambios de
estructura: un archivo nuevo en `10_utils/` (`10_locale.R`), uno en
`50_documentacion/activa/` (`50_locale_utf8.md`), uno en
`50_documentacion/activa/decisiones/`, y tres en `50_documentacion/andamios/`
(dos encargos y un arnés) más dos logs. Todos respetan la política §2
(snake_case, sin tildes, sin espacios). Las desviaciones heredadas siguen
abiertas y son materia de P-60: siete archivos de `50_documentacion/activa/` sin
prefijo `50_`, huecos 31, 37 y 38 en `30_procesamiento/`, y un archivo con
espacio en el nombre bajo `andamios/design_handoff_portal_transparencia/`.

## §11. Pendientes y ruta sugerida

### 11.1 Inventario

**P-68 — Sondear LeyChile y `datos.bcn.cl` como fuentes temáticas.**
*Tipo:* funcionalidad. *Impacto:* alto; es lo único capaz de dar vuelta el
veredicto del eje temático y condiciona el alcance de P-66. *Dependencias:*
ninguna. *Complejidad:* media. *Precauciones:* reproductor que no persista
respuestas distintas de 200; fusible de red en toda prueba; el denominador de
cobertura se cuenta en el turno, no se hereda del corte 2026-08-03.
*Criterio de éxito:* veredicto cerrado con denominador contado en la corrida.

**P-66 — Publicar la entidad `proyecto` con tramitación legislativa.**
*Tipo:* funcionalidad. *Dependencias:* el resultado de P-68 define su alcance.
*Complejidad:* alta. *Precaución:* la cobertura temática no se publica sobre el
denominador total de votaciones (D26).

**P-82 — El agregado de "desalineados" sobrevive en una línea de log fuera del
`stop()` (nuevo).** `"Intermedios desalineados con el corte vigente (%s): %d de
%d"`, en la rama que sí puede regenerar: con 0 intermedios en disco dice "6 de 6"
sobre archivos que no existen. *Tipo:* deuda técnica. *Impacto:* bajo; no induce
a acción errada porque esa rama regenera y sigue. *Complejidad:* baja.
*Criterio de éxito:* la misma prueba de C14, aplicada a la línea de log.

**P-83 — Entrada de P-59 en `CLAUDE.md` (nuevo).** Se omitió a propósito en el
PR #12 para no chocar con el PR #11, que ya modifica la lista de "Últimos
cambios". *Tipo:* documentación. *Dependencia:* merge del PR #11.

**P-79 — `sin_registro` no distingue "no sabemos" de "sabemos que está mal".**
*Tipo:* deuda técnica. *Dependencia:* D31 (ratificada).

**P-81 — La contención del borde superior cubre solo el paso 36 y solo
`Votaciones`.** *Tipo:* deuda técnica.

**P-60 — Ordenación del repositorio (gatillo 4bis encendido).** *Tipo:* deuda
heredada. *Evidencia del gatillo:* no existe
`50_documentacion/activa/50_ordenacion_repositorio.md`.

**P-57 — Constantes nombradas al inicio de cada script.** *Tipo:* deuda técnica.

**P-75 — El campo `§3` que pedía el hash de `main` es estructuralmente
autodestructivo.** Mitigado por SETTINGS v20 (el traspaso cita el hash previo y
Claude Code agrega el definitivo); queda como registro.

**Borde inferior del nodo `Votaciones`.** 176 de 723 eventos anteriores a
`ANIO_PROCESO` en 29 de 115 boletines, medidos al corte 2026-08-03 y **no
remedidos** al corte vigente. *Tipo:* decisión pendiente del titular.

**Arquitectura del pipeline del Senado.** *Tipo:* funcionalidad mayor. Sin
avance en esta sesión.

### 11.2 Deuda técnica

Zonas frágiles: `regenerar_intermedios_si_desalineados()` pasó de 130 a 198
líneas y concentra cuatro guardas; es la función con más superficie del proyecto
y la que ha producido tres bugfixes en tres sesiones consecutivas. Oportunidad:
cuando P-82 se toque, evaluar si el mensaje de estado merece salir a una función
propia en vez de crecer dentro de la guarda.

### 11.3 Auditoría de cierre (política 5.6)

| Pregunta | Respuesta |
|---|---|
| ¿Los datos crudos siguen aislados e inmutables? | **Sí.** 50 de 50 capturas con md5 idéntico entre apertura y cierre en las dos corridas de verificación |
| ¿El pipeline corre de cero sin intervención manual? | **Sí**, con la reserva de que no se corrió entero en esta sesión: la última evidencia completa es la corrida del bot de la sesión 18 |
| ¿Paquetes, rutas y constantes al inicio de cada script? | **Parcial.** P-57 sigue abierto |
| ¿La estructura respeta la política? | **No.** Deuda heredada, materia de P-60 |
| ¿Nombres sin tildes, ñ ni espacios? | **No.** Un archivo bajo `andamios/design_handoff_portal_transparencia/` |
| ¿Todo cambio quedó verificado con criterio explícito? | **Sí.** 14 de 14 en el PR #11, 9 de 9 en el PR #12 |
| ¿Quedó algo sin commitear? | **No.** Ambas ramas con working tree limpio y todo empujado |

### 11.4 Ruta sugerida para la sesión 20

**Prioridad 1 — P-68, sondeo de LeyChile y `datos.bcn.cl`.** Criterio de
priorización: es la única tarea capaz de cambiar un veredicto de producto, y
bloquea el alcance de P-66. *Criterio de éxito:* veredicto cerrado con
denominador contado en la corrida y reproductor que no cachee errores.

**Prioridad 2 — P-66, según lo que P-68 devuelva.** *Criterio de éxito:* entidad
`proyecto` publicada con su cobertura declarada sobre el denominador correcto.

**Prioridad 3 — P-82 y P-83, ambos baratos.** *Criterio de éxito:* la prueba de
C14 aplicada a la línea de log; y `CLAUDE.md` con la entrada de P-59 después del
merge del #11.

**Conviene diferir:** P-60 (mueve demasiados archivos para competir con trabajo
de datos), el pipeline del Senado, P-79 y P-81 (consecuencias de D31, mejor
después de P-66), y el borde inferior, que espera decisión y no trabajo técnico.

## §12. Instrucciones específicas para la próxima sesión

- ⚠️ **NO** afirmar `CORTE_FECHA`, el sello de un intermedio ni el hash de `main`
  sin leerlos en el momento de afirmarlo.
- ⚠️ **NO** heredar las cifras del nodo `Votaciones` (723 eventos, 115 boletines,
  176 del borde inferior): están ancladas al corte 2026-08-03.
- ⚠️ **NO** dar por mergeados los PR #11 y #12: al cierre de esta sesión ambos
  estaban abiertos. Verificar con `gh pr view <n> -R tomgc/transparencia_legislativa_chile --json state,mergedAt`.
- ⚠️ **NO** correr ninguna prueba que ejercite el pipeline sin el fusible
  instalado (`quit(99)` en la primera llamada de red, en el proceso que corre el
  pipeline). Un `stop()` no basta: el 36 lo atrapa y lo degrada a
  `estado = error_red`.
- ⚠️ **NO** usar `gh pr diff --name-only` (HTTP 406 en PRs grandes) ni pasarle
  rutas con `--`: `gh pr diff` acepta un solo argumento. Para listar archivos de
  un PR, `gh api` paginado sobre `/repos/<owner>/<repo>/pulls/<n>/files`; `gh api`
  **no** acepta `-R`.
- ⚠️ **NO** publicar cobertura temática sobre el denominador total de votaciones:
  el correcto es el subconjunto tipo `Proyecto de Ley` (D26).
- ⚠️ **NO** hacer join entre Cámara y Senado por identificador numérico solo: 5
  colisiones activas.
- ⚠️ **NO** tratar `<Materias/>` ni `<Votaciones/>` como nodos ausentes: vienen
  presentes y autocerrados.
- ⚠️ **NO** usar `senadores_vigentes.php` como padrón, ni
  `/api/sessions/attendance?id_legislatura=`.
- ⚠️ **NO** tratar un comentario de código como fuente sobre quién consume una
  función (A70).
- ✅ **ANTES** de usar la existencia de un directorio como señal, medir qué
  trackea git dentro (A78).
- ✅ **ANTES** de declarar una cobertura, declarar su universo y su denominador en
  la misma línea, contados en el turno (A81).
- ✅ **ANTES** de probar una guarda de entorno, forzar el entorno en subproceso y
  probar las dos direcciones (A80).
- ✅ **ANTES** de instalar un helper en un archivo, comprobar qué exige resolver
  su ruta desde ahí, no solo qué exige el helper (A79).
- ✅ **ANTES** de ramificar sobre `NA`, enumerar sus causas: si son más de una, la
  condición debe medir el hecho y no el proxy (A74).
- ✅ **ANTES** de dar por probada una guarda, probar el caso en que **no** debe
  dispararse.
- ✅ **ANTES** de dar por entregado un artefacto, comprobar que quedó adjunto en el
  mismo turno que lo anuncia (A52).
- ✅ **ANTES** de aceptar una cifra que coincide con un denominador conocido,
  medirla desde el otro lado (A71).
- 🔒 `sellar()`, `leer_sellado()` y `validar_corte()` no se tocan.
- 🔒 La guarda del contrato temporal (D31) y su registro no se aflojan sin decisión
  explícita del titular.
- 🔒 `40_salidas/intermedios/.gitkeep` sigue trackeado: la ruta de recuperación que
  la guarda imprime corre extractores sueltos y `escribir_atomico()` no crea
  directorios.
- 🔒 `10_utils/10_utils.R` no adquiere dependencias de paquetes: `00_run_all.R` lo
  carga antes de llamar a `instalar_si_falta()`.
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

Sin patrones nuevos que no vivan ya en el código. Los dos patrones que esta
sesión consolidó (escape de un solo uso vía helper genérico; rastro en disco como
discriminante de estado de arranque) viven en `10_utils/10_utils.R`, y el patrón
de prueba de guardas por escenario en subproceso con fusible vive en
`50_documentacion/andamios/50_verificar_guarda_bot.R` y
`50_documentacion/andamios/50_verificar_locale_p59.R`.

## §14. Reapertura

Tipo: CONTINUATION. El protocolo (`POLITICA_PROYECTO.md` v5.6,
`SETTINGS_Y_PROMPTS_OPERACIONALES.md` v23) vive en la knowledge base del Project
y se lee desde ahí; verifica las versiones contra la knowledge base, no contra
ninguna otra fuente, antes de la Fase A.
Estado: la sesión 19 cerró P-76, P-77 y P-59, ratificó D31 y resolvió el destino
de las capturas en cuarentena. Dejó **dos PR abiertos y sin mergear**: el #11
(guarda de arranque, 14 de 14 criterios) y el #12 (locale UTF-8, 9 de 9). No des
por hecho que siguen abiertos ni que fueron mergeados: verifica con
`gh pr view 11 -R tomgc/transparencia_legislativa_chile --json state,mergedAt` y
lo mismo para el 12. Tampoco creas a este traspaso sobre `CORTE_FECHA`, sobre el
hash de `main` ni sobre ninguna cifra del nodo `Votaciones`: las de aquí son del
corte 2026-08-03 y hay que remedirlas.
Advertencia operativa: si borras `40_salidas/intermedios/*.rds` en una copia que
todavía no corrió el pipeline después del merge del #11, el rastro de arranque no
existe aún y ese borrado se sigue leyendo como primera corrida.
El foco propuesto es P-68: sondear LeyChile y `datos.bcn.cl`, lo único capaz de
dar vuelta el veredicto del eje temático, que además define el alcance de P-66.
Encadenado: P-82 y P-83, ambos baratos, el segundo dependiente del merge del #11.
Sigue encendido el gatillo 4bis (ordenación, P-60); el 4ter quedó apagado con
marcador esta sesión.
El §15 trae tres errores registrados, los tres del asistente conversacional, y
dos de ellos son la misma forma: afirmar una cifra o una firma de comando sin
medirla en el turno.
Documentos para la próxima sesión:

1. Protocolo en knowledge base (no se adjuntan; se listan para verificar que la
   knowledge base esté al día): `POLITICA_PROYECTO.md`,
   `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
2. Opcionales según el foco real: `CLAUDE.md` si la sesión correrá en Claude Code.
3. Específicos de la sesión: `traspaso_cierre_v19.md`.

## §15. Errores del asistente

**Error 1.**

| Campo | Contenido |
|---|---|
| Momento | Fase B, acuse de apertura |
| Disparador | Auditoría de apertura, pregunta 4 (¿la estructura respeta la política?) |
| Qué pasó | Afirmé "siete archivos de `50_documentacion/activa/` sin prefijo `50_`" contando a ojo sobre el árbol del escáner |
| Regla violada | Marcador de fuente, tipo 3: toda cifra comunicada admite solo conteo programático del mismo turno |
| Causa raíz | La cifra parecía verificable por simple lectura, y esa apariencia es justo la que la regla trata como no confiable |
| Salvaguarda presente | El marcador de fuente estaba en las preferencias y se citó el escáner como fuente, pero la fuente respalda la existencia de los archivos, no el conteo |
| Detección | Al redactar el traspaso, revisando qué cifras del acuse tenían conteo detrás |
| Corrección | El §10 de este traspaso repite la cifra citando la misma fuente; queda para la sesión 20 recontarla programáticamente si P-60 se toca |
| Impacto | Bajo; no cambió ninguna decisión |
| Patrón | PAT-01 (`catalogo_patrones_errores_v4.md`) |

**Error 2.**

| Campo | Contenido |
|---|---|
| Momento | Después de la primera medición de C12 del PR #11 |
| Disparador | Querer revisar solo el diff de `CLAUDE.md`, el único archivo del PR sin criterio que lo cubriera |
| Qué pasó | Entregué `gh pr diff 11 -R ... -- CLAUDE.md`, una firma que no existe: el comando acepta un solo argumento y falló |
| Regla violada | Marcador de fuente, tipo 4: toda premisa fáctica se declara con su fuente o como hipótesis con su comando de verificación |
| Causa raíz | Trasladé la forma de `git diff -- <ruta>` a `gh pr diff` por analogía, sin marcar la firma como hipótesis |
| Salvaguarda presente | El propio traspaso v18 traía una restricción sobre `gh pr diff` (el HTTP 406), lo que probablemente reforzó la falsa sensación de conocer el comando |
| Detección | El titular corrió el comando y devolvió el error |
| Corrección | Se entregó la forma correcta en el turno siguiente; queda como restricción ⚠️ en el §12 |
| Impacto | Bajo; un turno perdido |
| Patrón | PAT-01, variante "firma de herramienta" |

**Error 3.**

| Campo | Contenido |
|---|---|
| Momento | Redacción del encargo v1 de P-76 y P-77 |
| Disparador | Citar la anatomía de la rama de primera corrida |
| Qué pasó | Cité el rango `10_utils.R:538-550` como si fuera una unidad; las líneas reales son 538-539 (rutas), 540 (conteo), 541 (condición) y 549 (retorno) |
| Regla violada | Marcador de fuente, tipo 1 y 3 |
| Causa raíz | Leí el archivo, pero comprimí un rango al citarlo en vez de nombrar las líneas que importaban |
| Salvaguarda presente | El propio encargo obligaba a reverificar las líneas contra `main` en la compuerta G1, y esa compuerta lo detectó |
| Detección | G1, por Claude Code, con `git diff origin/main` vacío y relocalización por búsqueda |
| Corrección | El encargo v2 corrigió la cita y declaró el delta |
| Impacto | Nulo. La compuerta hizo exactamente lo que estaba diseñada para hacer |
| Patrón | PAT-01, atrapado por precondición estructural. Registra el caso positivo: la salvaguarda estructural funcionó donde la disciplina no |
