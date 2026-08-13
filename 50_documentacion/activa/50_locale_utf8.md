# Guarda de locale UTF-8 — instalada

> **Fecha de instalación:** 2026-08-12. **Sesión:** 19. **Pendiente:** P-59.
> **Norma:** `POLITICA_PROYECTO.md` §5.2bis. **Gatillo:** SETTINGS §1.2.2 paso 4ter.
> Este archivo es el marcador que apaga el gatillo 4ter en las aperturas futuras.
> Cada línea sale de una medición de la corrida que lo escribió
> (`50_documentacion/andamios/50_verificar_locale_p59.R`, fase única).

## Qué invariante garantiza

Ningún proceso de R de este proyecto escribe texto acentuado con una locale de
caracteres no UTF-8. Si la locale no es UTF-8, la guarda intenta corregirla en
caliente y avisa; si no puede, **aborta con diagnóstico** en vez de seguir
escribiendo `<c3><a1>` sin error visible.

## Dónde está el helper

| Dato | Valor (medido) |
|---|---|
| Instalado en | `10_utils/10_locale.R` |
| Copiado de | `/Users/tomgc/Projects/herramientas_dev/plantillas/10_locale.R` |
| md5 (origen y copia, iguales) | `dc900c1b0d2d252c9e5730875be5d632` |
| Tamaño (origen y copia, iguales) | 11.769 bytes, 220 líneas |
| Editado por este proyecto | **No.** El contrato prohíbe editarlo (POLITICA 6.2) |

## Los cuatro puntos de arranque

No hay un punto único: `10_utils/10_utils.R` declara cero dependencias de
paquetes y se carga **antes** de que `instalar_si_falta()` corra, así que
resolver ahí la ruta del helper con `here::` o `rprojroot::` lo volvería
dependiente de un paquete no garantizado. Medido en la compuerta G6: ambas
variantes fallan con solo la biblioteca base visible, mientras que el
`10_utils.R` de hoy carga con exit 0. Por eso son cuatro, y cada uno resuelve
la ruta como ya lo hacía.

| Punto | Resuelve la ruta con | `source()` | Llamada |
|---|---|---|---|
| `10_utils/10_configuracion.R` | `here::here()` | línea 23 | línea 24 |
| `10_utils/10_diff_conteos.R` | `rprojroot::find_root()` | líneas 34-35 | línea 36 |
| `00_escanear_proyecto.R` | su propio `ROOT` | línea 44 | línea 45 |
| `50_documentacion/andamios/medir_fuente_territorio.R` | su propio `RAIZ` | línea 32 | línea 33 |

Los cuatro invocan la guarda **antes** de su primera escritura de texto: 4 de 4,
medido comparando el número de línea de la llamada contra el de la primera
escritura, sobre líneas de código (los comentarios no cuentan).

## Sobre qué universo hay cobertura (no "total" a secas)

La cobertura es **total sobre el universo alcanzable, y ese universo tiene
denominador**: los **13** archivos `.R` a los que se llega, por cierre transitivo
sobre líneas de código, desde las tres raíces por las que este proyecto arranca —
`00_run_all.R`, `.github/workflows/refresh-semanal.yml` y
`00_escanear_proyecto.R`. Sobre esos 13: **9 escriben algún artefacto, 3 escriben
texto, y 0 lo hacen sin pasar por uno de los cuatro puntos.**

El repositorio tiene 30 archivos `.R` en total; los 17 restantes no son
alcanzables desde ninguna raíz. La exclusión que importa va nombrada abajo.

## Qué se midió para escribir este marcador

- **La guarda actúa:** subproceso con `LC_ALL=C LANG=C --vanilla` que carga
  `10_utils/10_configuracion.R` — arranca en `C` (`UTF-8: FALSE`), la guarda
  corrige a `es_ES.UTF-8` y lo dice; termina en `UTF-8: TRUE`, exit 0.
- **La guarda aborta:** mismo subproceso con las candidatas sustituidas por una
  inexistente (sin editar el helper) — **exit 1**, con el diagnóstico
  `[ locale ] ABORTADO`, `LC_CTYPE actual : C` y el remedio.
- **La guarda no es el entorno:** el reverso, con `LANG=es_ES.UTF-8`, pasa sin
  emitir corrección alguna. Sin esta mitad, la prueba no distinguiría la guarda
  de una máquina que ya estaba bien configurada.
- **Sin silenciadores:** 0 de 5 archivos revisados (helper más los 4 puntos)
  envuelven `Sys.setlocale()` o la llamada en `try(..., silent)` o
  `suppressWarnings()`.
- **Texto ida y vuelta:** 6 de 6 cadenas con tildes y `ñ`, escritas por la misma
  ruta que usa el 39 (`toJSON` → `escribir_atomico` → `writeLines(enc2utf8,
  useBytes = TRUE)`) y releídas, vuelven `identical()`; 14 bytes no ASCII en el
  archivo y cero secuencias `<c3>`.

## Lo que esta guarda NO cubre (medido, no supuesto)

### Cuatro reproductores congelados, excluidos por decisión del titular

Escriben texto y no pasan por la guarda. Son reproductores de la **auditoría de
fuentes del 2026-08-07**, guardados como procedencia dentro de
`20_insumos/exploracion/20260807/`, congelados y no alcanzables desde ninguna de
las tres raíces:

| Archivo | Razón |
|---|---|
| `20_insumos/exploracion/20260807/20260807_sondeo_eje_tematico_senado.R` | Congelado, no alcanzable. Auditoría 2026-08-07 |
| `20_insumos/exploracion/20260807/d2_reproductor_asistencia_senado.R` | Congelado, no alcanzable. Auditoría 2026-08-07 |
| `20_insumos/exploracion/20260807/reproductor_universo_operaciones_camara.R` | Congelado, no alcanzable. Auditoría 2026-08-07 |
| `20_insumos/exploracion/20260807/senado_sondeo_reproductor.R` | Congelado, no alcanzable. Auditoría 2026-08-07 |

Son diagnósticos de una sola vez contra APIs externas: no corren en ningún
refresh y nadie los invoca desde el pipeline. **Exclusión declarada (sesión 19),
no descuido.** Si alguno volviera a correrse a mano, corre sin esta guarda.

Otros dos grupos quedan fuera por la misma razón estructural (no alcanzables), y
se anotan para que la exclusión esté completa y no solo la parte cómoda: **3**
archivos más de esa misma auditoría que escriben solo binario, y **6** andamios y
arneses de medición de `50_documentacion/andamios/` — estos últimos **no** son de
esa auditoría: son de sesiones distintas y se corren a mano.

### Límites del helper

Por su propia cabecera (**no medido aquí**): no cubre la **lectura**, que falla
en silencio (H4); y `writeLines()` no escapa aunque el proceso corra en `C` (H1)
— el efecto medible en esa ruta es el **orden de colación** (H2).
