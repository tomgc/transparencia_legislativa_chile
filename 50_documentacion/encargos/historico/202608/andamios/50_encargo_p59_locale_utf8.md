# Encargo — P-59: invariante de locale UTF-8 (gatillo 4ter)

> **Destino:** `50_documentacion/andamios/50_encargo_p59_locale_utf8.md`
> **Sesión:** 19. **Ejecutor:** Claude Code, modo autónomo.
> **Alcance:** instalar la guarda de arranque de locale UTF-8 que la POLITICA
> v5.6 §5.2bis declara en norma, y apagar el gatillo 4ter. Rama
> `chore/p59-locale-utf8`. Sin push a `main`, sin merge.

---

## §0. Contrato positivo

### 0.1 Afirmaciones respaldadas

| # | Afirmación | Evidencia |
|---|---|---|
| A1 | El gatillo 4ter está encendido: no existe `50_documentacion/activa/50_locale_utf8.md` | Escáner del 2026-08-12 21:59:28 (`estructura_actual.md`), rama `50_documentacion/activa/`, leída en la sesión que redacta este encargo |
| A2 | El proyecto **sí** tiene `10_utils/10_configuracion.R`, así que el gatillo no está bloqueado | Mismo escáner; y la compuerta G2 del encargo de P-76/P-77 midió `ruta_insumos` en su línea 11 y `ruta_salidas` en la 12 |
| A3 | La norma vive en `POLITICA_PROYECTO.md` §5.2bis y el gatillo en `SETTINGS_Y_PROMPTS_OPERACIONALES.md` §1.2.2 paso 4ter | Ambos leídos desde la knowledge base del Project en esta sesión (POLITICA v5.6, SETTINGS v23) |
| A4 | El helper se copia **idéntico** desde `herramientas_dev/plantillas/10_locale.R` y no se edita por proyecto | SETTINGS §1.2.2 paso 4ter, leído en esta sesión |
| A5 | La norma prohíbe explícitamente envolver `Sys.setlocale()` en `try(..., silent = TRUE)` o `suppressWarnings()` | Encabezado de `POLITICA_PROYECTO.md` v5.6, registro de cambios respecto de v5.5, leído en esta sesión |
| A6 | El defecto que originó la norma escribió escapado todo el texto acentuado de una corrida, en otro proyecto de la cartera | Mismo encabezado |

### 0.2 Hipótesis

| # | Hipótesis | Compuerta |
|---|---|---|
| H1 | `herramientas_dev/plantillas/10_locale.R` existe y es accesible desde esta máquina | G1 |
| H2 | El grep del gatillo devuelve 0 hoy (`grep -rl asegurar_locale_utf8 10_utils \| wc -l`) | G2 |
| H3 | `10_utils/10_configuracion.R` es el punto de arranque efectivo del pipeline, es decir, todo camino de entrada lo carga | G3 |

---

## §1. Objetivo

Que ninguna corrida de este proyecto pueda escribir texto acentuado escapado
por una locale no UTF-8, y que el fallo, si ocurre, sea **ruidoso**.

**Fuera de alcance:** cualquier otro pendiente, cualquier reescritura de
artefactos ya publicados, y toda edición del helper.

---

## §2. Invariantes

1. **El helper se copia idéntico.** Si algo del helper no calza con este
   proyecto, se detiene y se reporta; no se adapta.
2. **Sin silenciadores.** `Sys.setlocale()` no se envuelve en
   `try(..., silent = TRUE)` ni en `suppressWarnings()` (A5). Si la locale no se
   puede fijar, la corrida se detiene con diagnóstico.
3. **Cero red y cero recomputación.** Este encargo no corre el pipeline
   completo. Si alguna prueba lo ejercitara, va con el fusible `quit(99)`
   instalado en el proceso que lo corre (A73).
4. **Ningún artefacto de `40_salidas/json/`, `docs/data/` ni
   `20_insumos/camara/` cambia.** Se verifica por md5 al abrir y al cerrar, con
   denominador.
5. **R es el único lenguaje.** `git` con `-C <ruta absoluta>`; `gh` con
   `-R tomgc/transparencia_legislativa_chile`, salvo `gh api`; `git add` con
   ruta acotada.
6. **Todo conteo con su denominador contado en la corrida.**

---

## §3. Compuertas

**G0 — Punto de partida.** `git -C <raíz> fetch` y `git -C <raíz> status
--porcelain`. Reportar hash de `origin/main`, hash local, y si el PR #11 ya está
mergeado. **Si el PR #11 sigue abierto, la rama de este encargo sale de `main`
igual**, y se reporta que hay dos ramas vivas sobre la misma zona del
repositorio (ninguna toca `10_utils/10_utils.R` en las mismas líneas, pero eso
se afirma solo después de mirarlo).

**G1 — Localizar el helper.** Buscar `10_locale.R` bajo la carpeta de usuario,
sin asumir una ruta fija. Reportar la ruta encontrada, su tamaño y sus primeras
líneas. Si no aparece, **detenerse**: el helper no se reescribe de memoria.

**G2 — Estado del gatillo, medido.** `grep -rl asegurar_locale_utf8 10_utils |
wc -l` y la existencia de `50_documentacion/activa/50_locale_utf8.md`. Reportar
ambos.

**G3 — Puntos de entrada.** Enumerar todo camino por el que este proyecto
arranca (`00_run_all.R`, los scripts 32-39 corridos sueltos, el workflow
`refresh-semanal.yml`) y, para cada uno, si carga `10_utils/10_configuracion.R`
antes de escribir cualquier cosa. **La pregunta exacta:** ¿existe algún camino
que escriba texto sin haber pasado por el punto donde se instalará la guarda? Si
lo hay, reportarlo antes de instalar: puede exigir un segundo punto de arranque,
y eso es decisión del titular.

**G4 — Línea base de integridad.** md5 de `20_insumos/camara/*.rds`,
`40_salidas/json/*.json` y `docs/data/*.json`, guardado fuera del repositorio.
Reutilizar el mecanismo de `50_verificar_guarda_bot.R:47-51`.

**G5 — Locale actual de esta máquina.** `Sys.getlocale()` completo, y qué
devuelve `l10n_info()`. Es el contexto que hace falta para interpretar el
resultado de la guarda cuando se pruebe.

---

## §4. Implementación

1. Copiar el helper a `10_utils/10_locale.R`, **byte a byte**, sin editar.
   Verificar por md5 contra el origen.
2. Invocar `asegurar_locale_utf8()` en el punto de arranque que G3 confirme, lo
   más arriba posible y **antes** de cualquier escritura o lectura de texto.
3. Crear `50_documentacion/activa/50_locale_utf8.md` (marcador del gatillo 4ter)
   con: qué invariante garantiza, dónde está instalado el helper, de dónde se
   copió, el md5 que prueba que es idéntico, y la fecha. Es el archivo que apaga
   el gatillo en todas las aperturas futuras: si miente, el gatillo queda
   apagado sobre una guarda inexistente.

**Prohibido:** editar el helper; envolver la llamada en un silenciador; instalar
la guarda en un punto que G3 no haya confirmado como universal.

---

## §5. Criterios de éxito

| # | Criterio | Cómo se prueba |
|---|---|---|
| C1 | El helper en el repositorio es idéntico al de `herramientas_dev` | md5 de ambos, iguales |
| C2 | El gatillo 4ter queda apagado con evidencia real, no con un proxy | `grep -rl asegurar_locale_utf8 10_utils \| wc -l` devuelve 1 o más, **y** existe el marcador. Las dos cosas, no una |
| C3 | La guarda se ejecuta en el arranque | Corrida limpia de R que cargue el punto de arranque y muestre `Sys.getlocale()` antes y después |
| C4 | La guarda falla ruidosamente | Forzar una locale inválida y comprobar que la corrida se detiene con diagnóstico, no que continúa en silencio |
| C5 | Ningún silenciador en el camino | Búsqueda de `try(`, `silent`, `suppressWarnings` en el helper instalado y en su punto de invocación: 0 apariciones que envuelvan `Sys.setlocale()` |
| C6 | Texto acentuado ida y vuelta | Escribir y releer una cadena con tildes y `ñ` a través de la ruta de escritura del proyecto; `identical()` con el original |
| C7 | Nada más cambió | md5 de apertura contra el de cierre en los tres directorios de G4, con denominador |
| C8 | El PR no trae artefactos de datos | `gh api` paginado sobre `/repos/tomgc/transparencia_legislativa_chile/pulls/<n>/files`. **No usar `gh pr diff --name-only`** (HTTP 406); `gh api` no acepta `-R` |

Un criterio que no se pueda medir se declara **NO MEDIDO**.

---

## §6. Panel adversarial

1. ¿Existe un camino de entrada que escriba texto sin pasar por la guarda? G3 lo
   pregunta; aquí se responde con la lista completa de caminos, contada.
2. ¿La guarda cambia de comportamiento según la máquina (macOS local contra el
   runner de GitHub Actions)? Si la respuesta solo se puede dar leyendo, decirlo
   así en vez de afirmarla.
3. ¿C4 probó la detención de verdad, o solo que la función existe?
4. ¿El marcador del §4.3 afirma algo que no se midió en esta corrida? Es el
   archivo que apaga un gatillo permanente: cada línea suya necesita fuente.

---

## §7. Entrega

1. Rama `chore/p59-locale-utf8` desde `main`. Nunca sobre `main`.
2. Log en `50_documentacion/andamios/logs/AAAAMMDD_p59_locale_log.md` con las
   cinco compuertas, los ocho criterios y los hallazgos del panel.
3. PR abierto, sin merge. Reportar hash, número de PR y todo criterio NO MEDIDO,
   una línea cada uno.
