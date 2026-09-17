# Traspaso de cierre v24 — transparencia_legislativa_chile

## 1. Identificación

- **Proyecto:** `transparencia_legislativa_chile` (portal de transparencia legislativa del Congreso de Chile, serverless, GitHub Pages).
- **Versión:** v24. **Fecha de cierre:** 2026-09-17. **Sesión:** 24.
- **Foco:** cerrar P-99 (el bot no versionaba las capturas del Senado) y las tres deudas de derivación de literales (P-100, P-101, P-102), las cuatro en producción. P-105 (barrido de dato personal) quedó construido y rechazado por panel, en rama viva.
- **Entorno:** Claude conversacional (Opus 5) como redactor; Claude Code en modo autónomo como ejecutor, sobre macOS. Repositorio `tomgc/transparencia_legislativa_chile`, público, con Pages.
- **Normativos leídos en la sesión:** `> **Versión 5.8 — vigente.**` (POLITICA) y `> **Versión 37.**` (SETTINGS), ambos transcritos del encabezado en el turno. La knowledge base estaba en `> **Versión 34.**` hasta el cierre, cuando la compuerta F0.0b del ejecutor midió el desfase contra el kit y el titular la repropagó.
- **Archivos principales modificados:** `10_utils/10_utils.R`, `.github/workflows/refresh-semanal.yml`, `30_procesamiento/37_extraer_tramitacion.R`, `50_verificar_localizador_p100.R` (nuevo), `CLAUDE.md`.

## 2. Resumen ejecutivo

La sesión se propuso ejecutar P-99 y siguió con las tres deudas de derivación que el traspaso v23 dejaba agrupadas. P-99 cerró completo: el workflow dejó de enumerar rutas a mano y ahora se las pregunta a R (`rutas_versionables_crudo()` sobre `DIRECTORIOS_CRUDO`), con una compuerta que mata el job ante cualquier ruta staged no declarada; una corrida real desde la rama lo probó y el merge de su PR de refresh dejó, por primera vez, capturas del Senado versionadas por el bot en `main` (`senado` 3 → 5). En el camino se mergearon PR #19 (P-93, la guarda de sincronía del registro de pasos), #20 (el corte 2026-08-20) y #22 (P-100, P-101, P-102). P-105, el barrido de dato personal, no cerró: tres paneles adversariales lo rechazaron por defectos sucesivos, el último de ellos de diseño (seis de siete archivos con dato personal declarados limpios por confundir "no pude leerlo" con "está limpio"), y quedó aislado en su propia rama para un encargo propio. El error estructural de la sesión fue del redactor: agrupó P-105 con tres refactores de superficie distinta, y eso mantuvo tres pendientes verificados fuera de producción durante tres rondas. Un segundo error del redactor, más grave por su alcance, fue afirmar las versiones de los dos documentos normativos sin leerlas y arrastrarlas doce turnos, hasta pedir el reemplazo de una knowledge base que estaba al día. El proyecto queda con la promesa de P-65 cumplida (cualquier intermedio del paso 37 se regenera desde captura versionada), con arnés versionado para la guarda, y con P-94 (la entidad temática, objetivo declarado del proyecto) sin dependencias externas.

## 3. Estado al cierre

**Qué funciona.**

| Componente | Última ejecución exitosa |
|---|---|
| Pipeline completo (`run_all()`) | corrida de CI del corte 2026-08-20, `conclusion = success`, 9/9 pasos, 18,5 min |
| Refresh semanal automatizado | misma corrida; rama `refresh/2026-08-20` y PR #20, mergeado |
| Guarda de sincronía del registro de pasos (P-93) | primera corrida en el runner: silencio (0 incoherencias) |
| Guarda de autorregeneración (P-65) | misma corrida: habló correctamente (primera corrida del corte, 0 de 7 intermedios) |
| Compuerta de rutas del job (P-99) | misma corrida: 1 251 rutas staged, 1 251 declaradas, 0 intrusas |
| Arnés del localizador (P-100) | sobre `main` mergeado: estado de salida 0, 32 casos `[ok]`, 0 `[FALLA]` |

**Qué no funciona.**

| Síntoma observable | Dónde |
|---|---|
| El barrido de dato personal declara `limpio` archivos que no pudo leer (6 de 7 con señuelo dentro) | rama `fix/encargo-a-derivacion-y-barrido`, no en `main` |
| El barrido sale en 0 con crudo sin cambios y sólo derivados staged, y el job publica | misma rama |
| `do.call` con símbolo pelado marcado irresoluble, afirmando una causa no medida | misma rama |
| El localizador audita el conjunto equivocado ante `quote(switch(...))` junto al `switch` real (caso 6bis) | **en `main`**, heredado de A2, no alcanzable desde `capturas_crudas_de_paso()` hoy |
| `base::do.call("switch", ...)` y `(switch)(...)` con señuelo: falsos negativos | **en `main`**, heredados de `b897ec4` |
| Cuatro referencias de `CLAUDE.md` apuntan a normativos ausentes de un clon fresco | `main`, desde `c1e18fd` |

**Delta respecto a v23.** P-93 pasó de PR abierto a producción. P-99 pasó de encargo escrito a implementado, probado en CI y mergeado. P-100, P-101 y P-102 pasaron de inventario a producción, con arnés. P-105 nació y no cerró. Los normativos dejaron de versionarse. `20_insumos/` pasó de camara 57 / senado 3 / territorio 2 a camara 63 / senado 5 / territorio 2.

## 4. Registro detallado de cambios

**4.1 — El refresh deriva de R las rutas de crudo que versiona (P-99).**
*Archivos:* `.github/workflows/refresh-semanal.yml`, `10_utils/10_utils.R`. *Categoría:* automatización.
*Qué se hizo:* el paso de commit dejó de enumerar rutas (`git add ... 20_insumos/camara ...`) y pasó a consumir la salida de `rutas_versionables_crudo()`, helper nuevo que devuelve `file.path("20_insumos", DIRECTORIOS_CRUDO)`. Entre el `git add` y el `git commit` se agregó una validación en R que mata el job nombrando cualquier ruta staged no declarada, más el inventario de staged al log.
*Por qué:* la lista del YAML se quedó en el mundo anterior al paso 37 y omitía el Senado. Ampliar el `git add` al directorio completo (diseño v1, refutado) habría invertido el régimen de fallo de "sólo entra lo nombrado" a "entra todo lo no excluido", con el padrón del Senado (157 correos, 53 teléfonos) al otro lado de la línea, sostenido sólo por `.gitignore`.
*Cómo se verificó:* la validación falla cuando debe (ruta intrusa bajo `territorio/`, salida 1 nombrándola) y calla cuando debe; corrida real desde la rama con `conclusion = success`; sobre `origin/refresh/2026-08-20`, conteo por subdirectorio: camara 57 → 63, senado 3 → 5, territorio 2 → 2.
*Dependencias afectadas:* `DIRECTORIOS_CRUDO` pasa de decidir sólo qué vigila el contrato temporal de P-74 a decidir también qué versiona el bot; documentado en `CLAUDE.md`.
*Tensión resuelta:* régimen de fallo cerrado contra simplicidad del YAML. Ganó el primero.

**4.2 — Merge de P-93 y devolución del dato fresco a producción.**
*Archivos:* ninguno propio. *Categoría:* integración/repo.
*Qué se hizo:* PR #19 mergeado (`f5b3869`), PR #20 mergeado (`37e571c`), `CLAUDE.md` actualizado.
*Cómo se verificó:* estado leído del endpoint propio de cada PR (`gh api .../pulls/<N>`), nunca de `gh pr list`; antes de mergear #20 se comprobó que los blobs de los tres archivos compartidos eran idénticos entre `origin/main` (con #21 dentro) y `origin/refresh/2026-08-20`, de modo que el merge no revertía nada.
*Por qué importa el orden:* la rama del bot nace del `HEAD` de la rama de trabajo, así que el PR de refresh arrastra el cambio de infraestructura; mergearlo primero habría metido ese cambio a `main` sin pasar por el PR que lo revisa.

**4.3 — Derivación de literales y localización del `switch` (P-100, P-101, P-102).**
*Archivos:* `10_utils/10_utils.R`, `30_procesamiento/37_extraer_tramitacion.R`, `50_verificar_localizador_p100.R`. *Categoría:* infraestructura.
*Qué se hizo:* `verificar_registro_pasos()` dejó de localizar el `switch` de `capturas_crudas_de_paso()` con `body(...)[[2]]` (indexado posicional) y pasó a recorrer el cuerpo; el mensaje de faltantes se generalizó a `20_insumos/` donde el vector está vacío por construcción; seis literales de subdirectorio pasaron a derivar de `DIRECTORIOS_CRUDO`.
*Por qué:* los tres son el mismo defecto (dato escrito a mano donde existe la declaración), y el primero detiene `run_all()` en su entrada si degrada.
*Cómo se verificó:* control conocido-bueno 131/131 líneas idénticas a `main`, 1 242/1 242 salidas con md5 idéntico, 7/7 cache hits, 0 red; los cinco escenarios de fallo de P-93; el escenario que P-100 arregla (con una línea insertada antes del `switch`, `main` declara 6 huérfanos y la rama calla); 19/19 formas de AST; equivalencia de rutas 22/22 y 28/28 sobre tres cortes.
*Líneas clave:* `DIRECTORIOS_CRUDO` (`10_utils.R:249` en la medición previa al cambio).

**4.4 — Arnés versionado del localizador.**
*Archivo:* `50_verificar_localizador_p100.R`. *Categoría:* infraestructura.
*Qué se hizo:* arnés corrible con `Rscript`, sin dependencias de paquetes, con 19 formas de AST, 3 casos sobre la función real, 3 de contorno y los 7 casos de regresión del panel, cada uno con su resultado esperado declarado. Sale con estado 1 cuando un caso falla.
*Por qué:* los dos panelistas coincidieron en que `localizar_switch()` llegaría a `main` sin ninguna prueba versionada. Nunca existieron pruebas de P-100 en el repositorio.
*Cómo se verificó:* se rompió un caso deliberadamente y el arnés salió en 1 nombrándolo; corrido contra el estado previo nombra exactamente las dos instancias que la reversión mató; sobre `main` mergeado, 32 casos `[ok]`, salida 0.

**4.5 — P-105 construido y rechazado (no incorporado).**
*Archivos:* rama `fix/encargo-a-derivacion-y-barrido`, `ff71730`. *Categoría:* automatización.
*Qué se hizo:* función de barrido de dato personal en R con los cinco patrones calibrados en la auditoría de P-99, más un paso del job que la invoca sobre el staged.
*Estado:* rechazado por panel en dos rondas, con tres defectos vivos. Ver §6.
*Qué sí quedó medido y sirve:* sobre el corpus vigente (70 archivos trackeados, `territorio` incluido) el barrido da limpio 70, hallazgos 0, ilegible 0, sobre 103 827 065 caracteres en 2,93 s; y el limpio sobrevive a la reconciliación bytes ↔ caracteres (68 escanean texto, los 2 de cero caracteres son los `.gitkeep` de 0 bytes; razón mediana 16,3).

**4.6 — Los normativos dejan de versionarse (decisión del titular).**
*Archivos:* `.gitignore`, `50_documentacion/activa/POLITICA_PROYECTO.md`, `50_documentacion/activa/SETTINGS_Y_PROMPTS_OPERACIONALES.md`. *Categoría:* documentación.
*Qué se hizo:* `c1e18fd` ("chore(gobernanza): los normativos dejan de versionarse; copia local via .gitignore", 2026-08-24) agrega dos líneas a `.gitignore` y da de baja 2 478 líneas del repositorio.
*Cómo entró:* dentro de PR #22, que es de código. Se midió antes de mergear: `c1e18fd` no da de baja ninguna regla de `.gitignore` (sólo agrega dos), y ningún archivo deja de estar ignorado (2 896/2 896 de `20_insumos/exploracion/` antes y después; los 40 que el barrido marca, 40/40, contados con `git check-ignore`).
*Consecuencia abierta:* `50_documentacion/activa/` quedó cubierta por `.gitignore`, de modo que la reparación automática del normativo desfasado que el cierre haría (F0.0b del instrumento) ya no entra a ningún commit: el desfase se repara en el árbol y no viaja. 36 archivos versionados citan los normativos, y `CLAUDE.md` lo hacía en cinco puntos como fuente de gobernanza. Se agregó una cláusula en su cabecera; las otras cuatro referencias siguen apuntando a archivos ausentes de un clon fresco.

## 5. Backlog acumulativo

Entradas 68-72 (numeración provisional; el ejecutor renumera desde disco). Última entrada en disco al abrir: 67. Ver `50_documentacion/activa/backlog_acumulativo.md`.

## 6. Bugs de la sesión

**Bug 1 — El localizador muere ante un símbolo vacío en el AST (D1).**
*Síntoma:* `ERROR: el argumento "hijo" está ausente, sin valor por omisión` al auditar cualquier cuerpo con `m[, 1]`, `df[, "col"]` o el fall-through `"32" = ,`.
*Causa raíz:* `nodo[[k]]` sobre un argumento vacío devuelve el símbolo vacío sin error, así que el `tryCatch` que envolvía la extracción no protegía nada: el fallo se disparaba al forzarlo en `is.null(hijo)`.
*Solución:* detección por identidad (`identical(x, quote(expr = ))`) antes de forzar el valor.
*Criterio de verificación:* el fall-through real del `switch` de `capturas_crudas_de_paso()` se audita sin error, y `tramites[!fuera, , drop = FALSE]` (`37:190`) también.
*Patrón general:* envolver en `tryCatch` la operación que no falla no protege de la que sí. La guarda se pone donde nace el error, no donde se lee el código.
*Estado:* resuelto, en `main`.

**Bug 2 — `base::switch()` no se reconocía (D2).** *Síntoma:* la guarda emitía "revisa si esa funcion dejo de declarar sus capturas con un switch" sobre un cuerpo que sí lo declaraba. *Causa raíz:* comparación del head de la llamada por nombre simple. *Patrón general:* un mensaje de error que afirma una causa que el código no midió es peor que no emitir mensaje. *Estado:* resuelto, en `main`.

**Bug 3 — UTF-8 inválido aborta sin nombrar el archivo (D3).** *Síntoma:* `nchar()` aborta el job; `grepl(perl = TRUE)` sobre cadena inválida devuelve `FALSE` sin escanearla. *Estado:* resuelto en la rama de P-105, no en `main`.

**Bug 4 — "No pude leerlo" indistinguible de "está limpio" (D4).** *Síntoma:* un `.rds` ilegible produce `hallazgos = 0, archivos = 1, caracteres = 0`. *Solución adoptada:* tres estados (limpio / hallazgos / ilegible), con `ilegible` tratado como fallo por el llamador. *Estado:* **reincidente**, ver Bug 5.

**Bug 5 — El estado por archivo sin reconciliación de volumen (defecto central del panel).**
*Síntoma:* 6 de 7 archivos con el mismo señuelo dentro declarados `limpio`; `atributo.rds` 177 bytes y 0 caracteres escaneados, `nul.bin` 59 bytes y 2 caracteres.
*Causa raíz:* se añadió estado por archivo pero nunca la única comprobación que distingue los dos ceros: caracteres escaneados contra bytes en disco.
*Patrón general:* un `NA` con más de una causa no puede gobernar el control de flujo, y declarar el estado no equivale a poder determinarlo. La comprobación que separa las causas es parte del diseño, no un detalle de implementación.
*Estado:* **pendiente**, en la rama de P-105.

**Bug 6 — Falso negativo introducido al corregir un falso positivo (DE-2 y su corrección).**
*Síntoma:* la guarda resuelve y audita el conjunto equivocado (declara ramas 32-37 cuando el despacho real declara 32-36) en un caso donde antes detenía.
*Causa raíz:* la instrucción del redactor mandó corregir DE-2 sin medir si era alcanzable desde la función auditada. No lo es: `capturas_crudas_de_paso()` tiene 0 `do.call`.
*Solución:* reversión byte a byte, no re-corrección.
*Patrón general:* antes de cerrar un falso positivo en una guarda, medir si el código que audita puede producirlo. Un falso positivo inalcanzable que falla ruidosamente es preferible a un falso negativo alcanzable.
*Estado:* resuelto por reversión; DE-2 vuelve a estar vivo, registrado y sin comentario en el código que afirme su inalcanzabilidad.

## 7. Aprendizajes y restricciones descubiertas

**A109 — `.gitignore` no protege del `checkout`.** Un archivo ignorado pero presente en el árbol se sobrescribe sin aviso cuando un `checkout` trae una versión versionada del mismo path, y un `rebase` posterior sobre un commit que la borra lo elimina del disco. *Contexto:* así se perdieron las copias locales de los dos normativos. *Regla:* antes de un `checkout` que cruce un commit que versiona o desversiona un path, verificar si hay copia local ignorada en ese path.

**A110 — El respaldo del propio proyecto puede ser el respaldo equivocado.** El respaldo bajo el directorio del proyecto tenía la versión vieja (777/1 701 líneas); el canónico estaba en los otros diez proyectos de la cartera, idéntico byte a byte. *Regla:* al restaurar un normativo compartido, identificar el canónico por md5 mayoritario en la cartera, no por proximidad.

**A111 — `deparse()` no ve comentarios.** Una comparación de equivalencia por `deparse()` da idéntico sobre dos funciones que difieren en un comentario. *Contexto:* la única pérdida de la separación fue una corrección de comentario, y la tabla de equivalencia dio 10/10 sin verla. *Regla:* la equivalencia de código se mide sobre el texto fuente (`parse(keep.source = TRUE)` + `getParseData()`, o el rango de líneas por `srcref`), y sobre el archivo completo, no sólo sobre los cuerpos de las funciones.

**A112 — Un arnés que sólo detecta lo que su autor imaginó no es un arnés.** Los tres paneles encontraron defectos que el ejecutor no; en dos de los tres, el defecto estaba en el arnés de detección, no en el código. *Regla:* todo panel adversarial debe incluir una prueba construida por el panelista, no por quien escribió el código.

**A113 — La hipótesis de agrupación de defectos se mide, no se supone.** El encargo B2 dio por hecho que las seis instancias nacían del prepase; sólo dos lo hacían. Cerrarlas "todas" sin medir habría dado por resueltos cuatro defectos vivos. *Regla:* cuando un encargo afirma que un conjunto de defectos comparte causa, esa afirmación es una hipótesis con su propia medición en F0, con detención si resulta falsa.

**A114 — Un `on.exit()` fuera de una función no dispara en `Rscript`.** Un arnés que restaura estado así corre sus escenarios sobre el mismo estado y produce salidas engañosamente iguales. *Regla:* la igualdad sospechosa entre escenarios que deberían diferir es señal de arnés roto, no de código correcto.

**A115 — Agrupar por afinidad temática no es agrupar por superficie de verificación.** Tres refactores que se prueban por equivalencia de rutas y una compuerta que se prueba contra un adversario no pertenecen al mismo encargo, aunque compartan archivo y sesión. *Regla:* el criterio de agrupación es cómo se verifica cada pendiente, no de qué trata.

## 8. Decisiones de diseño

**D58 — El YAML no enumera rutas de captura: se las pregunta a R.**
*Alternativas:* (a) `git add 20_insumos` completo; (b) enumerar las dos rutas en el YAML; (c) derivar de `DIRECTORIOS_CRUDO` vía helper.
*Justificación:* (a) invierte el régimen de fallo y deja el rechazo del padrón sostenido por una línea de `.gitignore`; (b) deja dos listas que pueden desincronizarse, que es el defecto que P-99 arregla.
*Tensión resuelta:* régimen de fallo cerrado contra simplicidad del YAML.
*Implicancia:* ampliar `DIRECTORIOS_CRUDO` amplía lo que el bot versiona, sin tocar el YAML. Documentado en `CLAUDE.md`.

**D59 — La compuerta del job valida el conjunto staged contra lo declarado, y falla cerrado.**
*Justificación:* convierte `.gitignore` en segunda línea de defensa en vez de la única. Es mecánica: no pide criterio a nadie en el momento en que el criterio estaría comprometido.
*Implicancia:* valida **rutas, no contenido**. Un archivo con datos personales y nombre plausible bajo `camara/` o `senado/` pasa las dos barreras. Ése es P-105.

**D60 — Un `switch` dentro de una `function` anidada no es la declaración de capturas, y si es el único del cuerpo la guarda falla ruidosamente.**
*Alternativas:* tomarlo como declaración; tratarlo como falso negativo tolerable.
*Justificación:* si el único `switch` está fuera de alcance, la guarda no puede auditar, y no poder auditar no es lo mismo que no encontrar problemas.
*Origen:* los dos panelistas de la primera vuelta divergieron aquí y la divergencia quedó sin resolver hasta que el redactor la decidió.

**D61 — DE-2 se revierte, no se re-corrige, y el código calla sobre él.**
*Justificación:* es un falso positivo que falla ruidosamente y hoy es inalcanzable desde la función auditada (0 `do.call`). Ésa es la dirección correcta de fallo para una guarda.
*Por qué ningún comentario lo declara inalcanzable:* esa propiedad depende de que `capturas_crudas_de_paso()` no adquiera un `do.call` mañana, y un comentario que afirma lo que no puede saber es la clase de defecto que esta sesión produjo tres veces.

## 9. Constantes y parámetros

Sin cambios de valor. `DIRECTORIOS_CRUDO` conserva `c("camara", "senado")` y cambia de alcance: desde esta sesión decide también qué versiona el bot, además de qué vigila el contrato temporal de P-74. Las vigentes viven en `10_utils/10_configuracion.R` y `10_utils/10_utils.R`.

## 10. Arquitectura de archivos

El escáner se regenera en este cierre (`sello_escaner: regenerar`); su retrato es la referencia. Cambio de estructura: un archivo nuevo en la raíz, `50_verificar_localizador_p100.R` (arnés del localizador). Dos archivos salen del versionado por `c1e18fd`: `50_documentacion/activa/POLITICA_PROYECTO.md` y `50_documentacion/activa/SETTINGS_Y_PROMPTS_OPERACIONALES.md`, que pasan a vivir como copia local ignorada. Verificación contra la política: pendiente, y es parte de P-60 (ver §11).

## 11. Pendientes y ruta sugerida

### 11.1 Inventario

**P-105 — El barrido de dato personal no cierra.**
*Contexto:* tres defectos vivos en `fix/encargo-a-derivacion-y-barrido` (`ff71730`): volumen cero declarado limpio (6 de 7 archivos con señuelo), asimetría de `do.call`, y compuerta que sale en 0 con crudo sin cambios y sólo derivados staged.
*Tipo:* deuda técnica (gobernanza de datos). *Impacto:* alto; es la única barrera que mira contenido, y hoy no existe en `main`. *Dependencias:* ninguna. *Complejidad:* alta (el defecto central es de diseño). *Principios:* un `NA` con más de una causa no gobierna el control de flujo; un cero sin volumen no es un cero.
*Precauciones:* la rama `ff71730` es el insumo y no se rebasea ni se borra. No ajustar un patrón para silenciar un hallazgo.
*Enfoque sugerido:* rediseñar con la reconciliación bytes ↔ caracteres como invariante de la función, no como comprobación añadida; alcance fijo declarado (no dinámico sobre el staged).
*Criterio de éxito:* un archivo ilegible, uno con UTF-8 inválido y uno con NUL producen `ilegible` y matan el job; con crudo sin cambios la compuerta no sale en 0 en silencio; un panelista construye su propio señuelo y el arnés lo detecta.

**P-107 — Falsos negativos heredados en el localizador, ya en `main`.**
*Contexto:* el caso 6bis (`quote(switch(...))` junto al `switch` real: audita 97/98/99 mientras el despacho declara 32/33), `base::do.call("switch", ...)` y `(switch)(...)` con señuelo. Los tres existen desde A2 y son idénticos en las cuatro versiones del código.
*Tipo:* deuda técnica. *Impacto:* medio; ninguno alcanzable desde `capturas_crudas_de_paso()` hoy, y la guarda es lo único que separa un registro desincronizado de una corrida que lo ignora. *Complejidad:* media.
*Precauciones:* el arnés versionado es la herramienta que los fija; toda corrección entra con su caso en el arnés antes que en el código.
*Criterio de éxito:* los tres casos en el arnés, fallando antes del cambio y pasando después, sin que ninguno de los 32 casos vigentes cambie de veredicto.

**P-108 — DE-2 vivo como falso positivo ruidoso.**
*Contexto:* `do.call` con función no literal detiene la guarda. Inalcanzable hoy (0 `do.call` en la función auditada), sin comentario en el código que lo afirme.
*Tipo:* deuda técnica. *Impacto:* bajo. *Dependencias:* se resuelve junto a P-107.
*Criterio de éxito:* `do.call(rbind, piezas)` con símbolo pelado resuelve; `do.call(f, ...)` con `f` indeterminable detiene nombrando sólo lo que midió.

**P-109 — `argumento_vacio()` inerte y no fijado por el arnés.**
*Contexto:* borrarlo deja el arnés en salida 0 y el fall-through sigue resolviendo; lo que arregló D1 fue quitar el binding, no el salto.
*Tipo:* deuda técnica. *Impacto:* bajo, pero es código muerto que aparenta ser una guarda.
*Criterio de éxito:* o el arnés tiene un caso que falla al borrarlo, o el helper se elimina.

**P-110 — El arnés del localizador no corre en CI.**
*Tipo:* automatización. *Impacto:* medio; un arnés que nadie corre caduca en silencio.
*Criterio de éxito:* el arnés corre en el workflow y su salida distinta de cero detiene el job.

**P-111 — Consecuencias de `c1e18fd` en la documentación.**
*Contexto:* 36 archivos versionados citan los normativos; cuatro referencias de `CLAUDE.md` apuntan a archivos ausentes de un clon fresco (la quinta ya tiene cláusula).
*Tipo:* documentación. *Impacto:* medio; alguien que clone el repo no encuentra la gobernanza que el repo dice seguir.
*Criterio de éxito:* 0 referencias a rutas de normativos que no existan en un clon fresco, medido sobre un clon real.

**P-103 — Desfase entre la knowledge base y el instrumento de cierre.**
*Contexto:* **el diagnóstico de esta sesión quedó anulado**: se hizo contra un número de versión que el redactor afirmó sin leer (ver §15). No se ha remedido contra `> **Versión 37.**`, que sí resuelve el instrumento por versión máxima y sí declara `settings_version` y `compuerta_dudas` en el front matter.
*Tipo:* documentación. *Impacto:* bajo.
*Criterio de éxito:* una comparación explícita entre lo que §2.1 de SETTINGS exige y lo que el instrumento vigente en disco hace, con la línea de encabezado de ambos transcrita.

**P-112 — La Clasificación temática del backlog arrastra +1 desde v06, y eso bloquea el cierre.**
*Contexto:* la columna N de la tabla suma una unidad más que las entradas numeradas del Detalle cronológico (declarado en el propio archivo desde v06). El invariante I2bis del instrumento de cierre lo mide y bloquea, de modo que `recuento_tematico: vigente` es estructuralmente inalcanzable en este repositorio hasta que alguien lo resuelva; este cierre sale con `diferido`. Hay además una divergencia de redacción: SETTINGS §2.1 licencia `diferido` sólo cuando la tabla declara una población **menor** que la del archivo, y aquí declara una mayor.
*Tipo:* deuda heredada. *Impacto:* medio; obliga a `diferido` en cada cierre y hace que un campo pensado como excepción sea la norma.
*Dependencias:* resolverlo exige reclasificar alguna de las entradas 1-23, y §2.2.5 prohíbe reescribirlas en silencio: la corrección va como entrada nueva con nota explícita.
*Enfoque sugerido:* auditar la clasificación de las entradas 1-23 contra los traspasos v01-v06 (pendiente ya declarado en el backlog), y reportar a la cartera la divergencia de redacción entre §2.1 y I2bis.
*Criterio de éxito:* la columna N iguala el número de entradas del Detalle, e I2bis pasa con `recuento_tematico` ausente.

**P-60 — Ordenación del repositorio.** Gatillo 4bis, séptima apertura consecutiva. Cifra de la sesión 23, no remedida: seis archivos sin prefijo en `activa/` más uno con espacios (`Portal Transparencia.dc.html`). *Tipo:* deuda heredada. *Criterio de éxito:* auditoría de apertura #4 y #8 en "sí".

**Gatillo 4ter — Invariante de locale UTF-8.** Nunca verificado en esta sesión. *Criterio de éxito:* `50_documentacion/activa/50_locale_utf8.md` existe y `asegurar_locale_utf8()` está en los puntos de arranque declarados.

**P-94 — Entidad temática.** Objetivo declarado del proyecto, sin dependencias externas desde P-92. *Tipo:* funcionalidad. *Complejidad:* alta. *Criterio de éxito:* el que fije su propio encargo; no se hereda de aquí.

**P-106 — Trámite descartado por año implausible.** 25/05/2626, boletín 18232-25; 1 de 5 078, error de la fuente. *Tipo:* deuda de datos. *Criterio de éxito:* regla explícita de tratamiento (descartar, corregir o marcar) aplicada en el paso 37 y visible en el JSON.

**Diferidos sin cambio:** P-2 (`RebajaAsistencia`/`RebajaQuorum`), P-54 (PAT-01 como precondición estructural), pipeline del Senado, P-104 (vive fuera de este repositorio).

### 11.2 Evaluación de deuda técnica

*Zonas frágiles.* El localizador del `switch` concentra cinco pendientes (P-107 a P-110) y es lo único que separa un registro de pasos desincronizado de una corrida que lo ignora; su arnés existe pero no corre solo. El barrido de dato personal no existe en `main`, así que la única barrera de contenido sigue siendo `.gitignore` (principio violado: la barrera no debería depender de que alguien nombre el patrón correcto). La documentación del repositorio cita gobernanza que ya no viaja con él.

*Oportunidades.* `DIRECTORIOS_CRUDO` demostró ser una buena declaración única; el patrón "el YAML le pregunta a R" es replicable a cualquier otra lista que hoy viva en el workflow.

### 11.3 Auditoría de cierre (política 5.6, preguntas "Cierre")

| # | Pregunta | Respuesta |
|---|---|---|
| 5 | ¿Cada transformación crítica tiene check de validación? | **Parcial.** La guarda de P-93 y la compuerta de rutas sí; el contenido de las capturas, no (P-105) |
| 6 | ¿Los outputs son reproducibles e idempotentes? | **Sí**, medido: 1 242/1 242 salidas con md5 idéntico entre rama y `main`, 0 red |
| 7 | ¿Decisiones metodológicas como constantes nombradas? | **Sí**, y mejoró: seis literales de subdirectorio pasaron a derivar de `DIRECTORIOS_CRUDO` |
| 4 | ¿La estructura respeta la política? | **No** → P-60 |
| 8 | ¿Nombres sin tildes, ñ ni espacios? | **No** → P-60 |

### 11.4 Compuerta de dudas (SETTINGS §2.1)

Seis dudas registradas, ninguna cerrada en sesión (ninguna cumple el criterio estrecho de cierre: ninguna antecede a una operación irreversible ni a una cifra publicada).

| # | `supuesto` | `predicado` | `medicion` |
|---|---|---|---|
| 1 | Los tres falsos negativos heredados (P-107) siguen sin ser alcanzables desde la función auditada tras el merge de #22 y el commit `81345d5` | `capturas_crudas_de_paso()` en `main` contiene 0 `do.call`, 0 `(switch)(...)` y 0 `quote(switch(...))` | recuento en R sobre el AST de la función leída desde `main` |
| 2 | El arnés sigue en verde sobre `main` después del commit documental `81345d5`, que tocó `37_extraer_tramitacion.R` | `Rscript 50_verificar_localizador_p100.R` sale en 0 con 32 casos `[ok]` sobre el `HEAD` actual de `main` | correr el arnés sobre `main` al día |
| 3 | GitHub Pages republicó `docs/` al mergear #20 y el portal muestra el corte 2026-08-20 | el `CORTE_FECHA` servido por Pages es `2026-08-20` | lectura del JSON publicado y comparación con `40_salidas/json` en `main` |
| 4 | `ventana_insumos: ./20_insumos` describe de dónde lee realmente el pipeline | `20_insumos/` dentro del repositorio contiene todos los insumos que el pipeline abre, y ninguno vive fuera | inventario en R de las rutas que los pasos 31-39 abren para lectura, contrastado con la ventana declarada |
| 6 | El proyecto no tiene `50_documentacion/andamios/logs/auditorias_log.md`, por lo que la subsección "Auditoría de cifras" del traspaso se omite (SETTINGS §2.2 punto 11) | el archivo no existe en el repositorio | `ls 50_documentacion/andamios/logs/auditorias_log.md` |
| 5 | Las cuatro referencias restantes de `CLAUDE.md` a los normativos son el total de referencias rotas del repositorio | en un clon fresco, 0 rutas citadas en archivos versionados apuntan a un archivo inexistente, salvo esas cuatro | clon en directorio temporal y verificación programática de existencia de cada ruta citada |

### 11.5 Ruta sugerida para la próxima sesión

Los pendientes quedan organizados en cuatro encargos autónomos, agrupados por **cómo se verifica cada uno**, no por tema (A115).

| Encargo | Pendientes | Por qué juntos | Panel |
|---|---|---|---|
| **E — Gobernanza documental** | P-111, P-103, P-60, gatillo 4ter | Ninguno toca el pipeline; todos se verifican por inspección y `grep` sobre un clon fresco | No |
| **C — El barrido, rediseñado** | P-105 | Superficie propia; se verifica contra un adversario que construye sus señuelos | Sí, obligatorio |
| **D — El localizador, cerrado** | P-107, P-108, P-109, P-110 | Los cuatro tocan `localizar_switch()` y su arnés; el arnés es la herramienta que los fija a los cuatro | Sí |
| **F — La entidad temática** | P-94, P-106 | P-106 es dato de tramitación, insumo del eje temático | Sí |

**Prioridad 1: encargo E.** Criterio: descarga cuatro gatillos encendidos (uno de ellos por séptima sesión), no necesita panel, y deja el terreno limpio. Criterio de éxito: auditoría de apertura #4 y #8 en "sí", 0 referencias rotas en un clon fresco, y P-103 remedido contra la línea de encabezado transcrita.

**Prioridad 2: encargo C.** Criterio: es lo único que quedó a medio camino con rama viva, y la rama caduca como contexto. Criterio de éxito: el de P-105 en §11.1.

**Prioridad 3: encargo D.** Criterio: deuda acotada con herramienta ya construida.

**Conviene diferir:** el encargo F a una sesión propia (alta complejidad, es el objetivo declarado del proyecto y no merece ser el relleno del final de una sesión); el pipeline del Senado y P-54, sin cambio.

**No mezclar C y D en una sesión:** los dos exigen panel, y esta sesión midió que tres paneles en un hilo degradan el contexto del redactor.

## 12. Instrucciones específicas para la próxima sesión

- ⚠️ **NO** afirmar la versión de un documento normativo sin transcribir su línea de encabezado leída en el turno (SETTINGS §2.1, regla de forma). Ocurrió en esta sesión y sobrevivió doce turnos.
- ⚠️ **NO** dar por vigente ninguna cifra de este traspaso: `CORTE_FECHA`, hashes, conteos de `20_insumos/`, estado de PR y cobertura se remiden.
- ⚠️ **NO** agrupar pendientes por afinidad temática: el criterio es cómo se verifica cada uno (A115).
- ⚠️ **NO** cerrar un falso positivo de una guarda sin medir antes si el código que audita puede producirlo (Bug 6).
- ⚠️ **NO** medir equivalencia de código con `deparse()`: no ve comentarios (A111).
- ⚠️ **NO** afirmar que un conjunto de defectos comparte causa sin medirlo: en esta sesión sólo 2 de 6 la compartían (A113).
- ⚠️ **NO** usar `gh pr list` para el estado de un PR: endpoint propio (`gh api .../pulls/<N>`).
- ⚠️ **NO** hacer `checkout` cruzando un commit que versiona o desversiona un path sin verificar si hay copia local ignorada ahí (A109).
- ✅ **ANTES** de creerle un cero a un arnés de detección, calibrarlo con señuelos sintéticos y uno inyectado en el dato real, y declarar el volumen barrido en el mismo bloque (A106, A108).
- ✅ **ANTES** de aceptar un veredicto de panel, verificar que el panelista superó su control negativo.
- ✅ **ANTES** de mergear un PR de código, medir qué más arrastra su rama (en esta sesión un PR de código traía una decisión de gobernanza de 2 478 líneas).
- ✅ **ANTES** de restaurar un normativo compartido, identificar el canónico por md5 mayoritario en la cartera (A110).
- 🔒 `fix/encargo-a-derivacion-y-barrido` queda en `ff71730`: no se rebasea, no se borra, es el insumo del encargo C.
- 🔒 `sellar()`, `leer_sellado()` y `validar_corte()` no se tocan.
- 🔒 `10_utils/10_utils.R` no adquiere dependencias de paquetes.
- 🔒 `DIRECTORIOS_CRUDO` es declaración única: ampliarla amplía lo que el bot versiona.
- 🔒 `20_insumos/territorio/` no lo commitea el bot (D5).
- 🔒 Los intermedios no se versionan (D24).
- 🔒 `main` no recibe escrituras automáticas ni push directo del bot.
- 🔒 Ninguna captura cruda ya escrita se modifica ni se borra.
- 🔒 `sin_registro` no se imputa, ni en el dato ni en la presentación.
- 🔒 R es el único lenguaje, en todo contexto.
- 🔒 `git` siempre con `-C <ruta absoluta>`, `gh` siempre con `-R tomgc/...` salvo `gh api`, `git add` siempre con ruta acotada.

## 13. Fragmentos de código de referencia

Patrón nuevo de la sesión: **el YAML le pregunta a R qué rutas versionar**, en vez de enumerarlas.

```bash
# en el paso de commit del workflow, antes del git add
RUTAS_CRUDO=$(Rscript -e 'source("10_utils/10_utils.R"); cat(rutas_versionables_crudo(), sep=" ")')
[ -z "$RUTAS_CRUDO" ] && { echo "rutas_versionables_crudo() vacio"; exit 1; }
git add 10_utils/10_configuracion.R $RUTAS_CRUDO 40_salidas/json docs/data
```

El fusible de vacío no es decorativo: un `git add` con la variable vacía degradaría el conjunto en silencio. Los patrones estables del proyecto viven en `CLAUDE.md`.

## 14. Reapertura

**Mensaje de apertura pre-armado:**

Tipo: CONTINUATION. El protocolo (`POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`) vive en la knowledge base del Project y se lee desde ahí; verifica las versiones transcribiendo la línea de encabezado de cada uno, no contra ninguna otra fuente, antes de la Fase A.

Estado: la sesión 24 cerró P-99 (el bot versiona las capturas del Senado: `senado` 3 → 5 en `main`, primera vez), mergeó P-93 (#19), el corte 2026-08-20 (#20) y P-100/P-101/P-102 (#22), y dejó el localizador del registro de pasos con arnés versionado en verde. P-105, el barrido de dato personal, no cerró: tres paneles adversariales lo rechazaron y quedó aislado en `fix/encargo-a-derivacion-y-barrido` (`ff71730`), que no se toca. Los dos documentos normativos dejaron de versionarse (`c1e18fd`) y 36 archivos del repo todavía los citan.

No creas a este traspaso sobre `CORTE_FECHA`, sobre hashes, sobre el estado de ningún PR ni sobre ningún conteo: todas se remiden. Tampoco sobre la versión de los normativos: en la sesión 24 el redactor afirmó dos versiones sin leerlas y el error sobrevivió doce turnos hasta pedir el reemplazo de una knowledge base que estaba al día.

El foco propuesto es el **encargo E** (gobernanza documental: P-111, P-103, P-60 y el gatillo 4ter), que no necesita panel y descarga cuatro gatillos, uno de ellos por séptima sesión consecutiva. Después, el encargo C (rediseño del barrido, P-105) y el encargo D (cierre del localizador). El encargo F (P-94, la entidad temática, objetivo declarado del proyecto) merece sesión propia. C y D no van en la misma sesión: los dos exigen panel.

El §15 trae ocho errores registrados, los ocho del asistente conversacional, y seis de ellos son de la misma familia: afirmar sin medir, o fijar un criterio que mide un proxy y no el riesgo.

**Documentos para la próxima sesión:**

1. Protocolo en knowledge base (no se adjuntan; se listan para verificar que la knowledge base esté al día): `POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
2. Opcionales según el foco real: `CLAUDE.md` si la sesión correrá en Claude Code.
3. Específicos de la sesión: `traspaso_cierre_v24.md`.

**Nota final:** si algún archivo listado cambió entre sesiones, adjuntar la versión más actualizada al abrir y avisarlo en el mensaje de apertura.

## 15. Errores del asistente

**Error 1**

| Campo | Contenido |
|---|---|
| `momento` | Fase A (acuse de recibo), y arrastrado hasta el turno del cierre |
| `disparador` | usuario lo corrigió ("no, revisa nuevamente") |
| `que_paso` | Declaró `POLITICA v5.6` y `SETTINGS v28` como versiones de la knowledge base, cuando eran v5.8 y v34, y sobre esa base diagnosticó P-103 y pidió reemplazar los dos archivos de la knowledge base |
| `regla_violada` | SETTINGS §2.1, "Cita de versión de documento normativo": la versión se cita transcribiendo la línea de encabezado leída en el turno, nunca con el número suelto |
| `causa_raiz` | Citó con número suelto en vez de transcribir, y el número suelto es indistinguible de un número recordado; una vez escrito en el acuse, se reusó como premisa en todos los turnos siguientes sin volver al archivo |
| `salvaguarda_presente` | SETTINGS (§2.1, regla de forma explícita, con este modo de fallo documentado), userPreferences (marcador de fuente obligatorio) |
| `patron` | PAT-01, sobre versión de documento normativo |
| `gatillo_observable` | `afirmar-sin-leer`: se afirmó la versión de un archivo de la knowledge base sin transcribir su encabezado en el turno |
| `intentos_previos` | 0 |
| `costo` | Un diagnóstico de P-103 anulado, una petición indebida de reemplazo de la knowledge base, y un turno de corrección |

**Error 2**

| Campo | Contenido |
|---|---|
| `momento` | Redacción del encargo A |
| `disparador` | asistente lo señaló espontáneamente tras el primer NO PASA del panel |
| `que_paso` | Agrupó P-105 (compuerta de contenido, se verifica contra un adversario) con P-100, P-101 y P-102 (refactores, se verifican por equivalencia), en un encargo y un panel |
| `regla_violada` | SETTINGS §2.2 punto 11 y criterios de agrupación de encargos: el pendiente se caracteriza por su complejidad y su criterio de éxito, no por su tema |
| `causa_raiz` | El criterio de agrupación usado fue la vecindad en el archivo y la eficiencia de revisión, no la superficie de verificación de cada pendiente |
| `salvaguarda_presente` | SETTINGS |
| `patron` | PAT-13, sobre criterio de agrupación |
| `gatillo_observable` | `otro`: un encargo agrupa pendientes cuyos criterios de éxito se miden con métodos distintos |
| `intentos_previos` | 0 |
| `costo` | Tres pendientes verificados retenidos fuera de producción durante tres rondas y tres paneles |

**Error 3**

| Campo | Contenido |
|---|---|
| `momento` | Encargo A, §4.4 (alcance del barrido) |
| `disparador` | usuario lo señaló sin nombrarlo error (vía el hallazgo del panelista 1) |
| `que_paso` | Afirmó que barrer el crudo cubre los derivados, y ese comentario se escribió en el YAML; es falso para `distrito` y `region`, que llegan al JSON publicado 155/155 desde `20_insumos/territorio/` |
| `regla_violada` | userPreferences, marcador de fuente: toda premisa factual de un encargo lleva fuente leída en la sesión o marca de hipótesis |
| `causa_raiz` | Se dedujo la cobertura del grafo de datos que el redactor suponía, en vez de medirla; la afirmación se escribió además como comentario en el código, donde queda como verdad para el siguiente lector |
| `salvaguarda_presente` | userPreferences, POLITICA |
| `patron` | PAT-01, sobre cobertura de una compuerta |
| `gatillo_observable` | `encargos-premisas`: una premisa de alcance se escribió sin medición y se materializó como comentario |
| `intentos_previos` | 0 |
| `costo` | Un comentario falso en el YAML y un hallazgo de panel |

**Error 4**

| Campo | Contenido |
|---|---|
| `momento` | Encargo A2, §4.2 (los tres estados del barrido) |
| `disparador` | usuario lo señaló sin nombrarlo error (vía el defecto central del panel de segunda vuelta) |
| `que_paso` | Exigió tres estados (limpio / hallazgos / ilegible) sin exigir la reconciliación bytes ↔ caracteres, que es la única comprobación que los distingue |
| `regla_violada` | SETTINGS §2.1, compuerta de dudas, campo `medicion`: un criterio sin su medición ejecutable no es un criterio |
| `causa_raiz` | Se diseñó la taxonomía del resultado y se dio por hecho que la implementación encontraría cómo determinarla; el encargo nombró el estado sin nombrar su evidencia |
| `salvaguarda_presente` | SETTINGS |
| `patron` | PAT-13, sobre criterio sin medición |
| `gatillo_observable` | `otro`: un criterio de aceptación nombra un estado sin nombrar la observación que lo decide |
| `intentos_previos` | 1 (la primera formulación del barrido, en el encargo A, ya había fallado por lo mismo en su forma binaria) |
| `costo` | Una ronda completa de encargo y un panel adversarial |

**Error 5**

| Campo | Contenido |
|---|---|
| `momento` | Encargo B, §2bis E4 (instrucción de corregir DE-2 en la rama de separación) |
| `disparador` | usuario lo señaló sin nombrarlo error (vía el panel de B) |
| `que_paso` | Ordenó cerrar un falso positivo sin medir si era alcanzable desde la función auditada; el resultado fue un falso negativo alcanzable y cinco instancias más de su clase |
| `regla_violada` | POLITICA y SETTINGS: una precondición debe medir el riesgo y no un proxy; toda premisa de un encargo lleva fuente o marca de hipótesis |
| `causa_raiz` | Se trató "existe un falso positivo" como equivalente a "hay un riesgo que cerrar", sin preguntar por su alcanzabilidad, que era medible con un recuento de `do.call` en la función auditada |
| `salvaguarda_presente` | POLITICA, SETTINGS |
| `patron` | PAT-13, sobre precondición que mide un proxy |
| `gatillo_observable` | `encargos-premisas`: un encargo manda corregir un modo de fallo sin medir si el código afectado puede producirlo |
| `intentos_previos` | 0 |
| `costo` | Una ronda de encargo (B2) y un panel; una regresión introducida en una guarda y revertida |

**Error 6**

| Campo | Contenido |
|---|---|
| `momento` | Encargo B, §4.1 (método de verificación de la equivalencia) |
| `disparador` | asistente lo señaló espontáneamente (el ejecutor, al medirlo tras el panel) |
| `que_paso` | Exigió verificar la equivalencia "definición por definición, en R", método que en la práctica se implementó con `deparse()` y es ciego a comentarios, que es exactamente donde ocurrió la única pérdida de la separación |
| `regla_violada` | SETTINGS §2.2 punto 11: el criterio de éxito debe ser el predicado observable del riesgo; el riesgo era "se perdió algo", no "se perdió código" |
| `causa_raiz` | Se especificó el método por su nombre ("definición por definición") sin comprobar qué observa ese método; el encargo heredó la ceguera de la herramienta que no nombró |
| `salvaguarda_presente` | SETTINGS |
| `patron` | PAT-13, sobre método de verificación que no cubre el riesgo |
| `gatillo_observable` | `otro`: un criterio de equivalencia se define por la herramienta y no por lo que debe detectar |
| `intentos_previos` | 0 |
| `costo` | Una corrección de comentario perdida y detectada por el panel, no por la verificación |

**Error 7**

| Campo | Contenido |
|---|---|
| `momento` | Encargo B2, §0.2 (H3) y el mensaje de chat que lo acompañó |
| `disparador` | usuario lo señaló sin nombrarlo error (vía la medición de F0.3 del ejecutor) |
| `que_paso` | Afirmó en el chat que revertir "mata el falso negativo y las cinco instancias de §5.3 de una vez, porque todas nacieron del prepase"; sólo dos de las seis nacían ahí |
| `regla_violada` | userPreferences, marcador de fuente: toda premisa factual de un encargo lleva fuente o marca de hipótesis |
| `causa_raiz` | La misma afirmación se escribió dos veces con estatus distinto: como hipótesis con detención dentro del encargo (correcto) y como hecho en el chat (incorrecto). El encargo se salvó; la afirmación del chat no |
| `salvaguarda_presente` | userPreferences |
| `patron` | PAT-01, sobre causa común de un conjunto de defectos |
| `gatillo_observable` | `afirmar-sin-leer`: se afirmó el origen de seis defectos sin medirlo en las dos ramas |
| `intentos_previos` | 0 |
| `costo` | Ninguno material (la hipótesis del encargo lo atajó); registrado por ser el mismo mecanismo del Error 1 |

**Error 8**

| Campo | Contenido |
|---|---|
| `momento` | Turno de recomendación de merge de PR #22 |
| `disparador` | usuario lo corrigió (la compuerta del ejecutor detectó que #22 arrastraba `c1e18fd`) |
| `que_paso` | Recomendó mergear #22 describiendo su contenido ("lo que #22 lleva a `main`") sin haber medido qué más arrastraba la rama; traía una decisión de gobernanza de 2 478 líneas |
| `regla_violada` | userPreferences, marcador de fuente, tipo 2 (estado del repositorio) |
| `causa_raiz` | Se tomó el reporte del encargo como inventario completo de la rama, cuando el reporte describía lo que el encargo produjo y no lo que la rama contenía |
| `salvaguarda_presente` | userPreferences, POLITICA |
| `patron` | PAT-01, sobre contenido de una rama |
| `gatillo_observable` | `estado-git`: se describió el contenido de un PR sin leer su lista de commits |
| `intentos_previos` | 0 |
| `costo` | Un turno de compuerta del ejecutor; ningún daño, porque la compuerta existió |

### Fricciones (SETTINGS §2.2.17)

friccion: respuestas largas sostenidas durante la fase de ejecución, hasta que el titular pidió el estado "en una línea" → se bajó al techo de prosa y se mantuvo en los turnos siguientes.

friccion: el asistente esperó pasivamente mientras corría el CI y el titular tuvo que pedir "¿qué necesitas? lista pendientes y traza ruta" → la lista de pendientes y la ruta pasan a ofrecerse sin que se pidan cuando hay una espera larga.

friccion: el paquete de cierre se entregó una primera vez contra un esquema desfasado y hubo que reemitirlo → antes de redactar el paquete se transcribe la línea de encabezado de SETTINGS del kit, no la de la knowledge base.
