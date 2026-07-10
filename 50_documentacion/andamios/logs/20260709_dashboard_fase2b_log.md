# Log de ejecución — Dashboard Fase 2, continuación (sesión 3b)

**Proyecto:** transparencia_legislativa_chile
**Fecha:** 2026-07-09
**Entorno:** Claude Code, macOS, R 4.5.2, rama `feature/dashboard-fase2`.
**Naturaleza:** andamio congelado (registro de ejecución, no se actualiza).

## 1. Resumen

Continuación del encargo de la Fase 2, dirigida a saldar dos deudas
documentadas en `20260709_dashboard_fase2_log.md` §8: la constante
`PARTIDO_NOMBRES` embebida a mano en el JS y el subtítulo de fila con texto
neutro fijo ("Diputada/Diputado") en vez del género real. Ambas tenían el
mismo origen: el índice quedó restringido a 3 columnas nuevas en la Fase 0
original. Dos fases (A: enriquecer el índice en R; B: consumir esos campos en
el JS), dos commits atómicos, sin push.

## 2. Inventario de commits

| # | Hash | Tipo | Título |
|---|------|------|--------|
| 1 | `7bbd483` | feat | partido_nombre y sexo en indice |
| 2 | `83d293d` | refactor | servir partido_nombre y genero desde el indice |

## 3. Dominio real de `sexo` (inspeccionado en R)

```r
diputados <- readRDS("40_salidas/intermedios/diputados.rds")
table(diputados$sexo, useNA = "ifany")
#  Femenino Masculino
#        52       103
```

Sin `NA`. Dominio exacto: `{"Femenino", "Masculino"}`. Mapeo aplicado en el JS:
`SEXO_LABEL = {Femenino:'Diputada', Masculino:'Diputado'}`, con
`SEXO_LABEL_NEUTRO = 'Diputada/Diputado'` como fallback para cualquier valor
fuera de ese dominio (no observado en los datos actuales, pero el código no
asume que el dominio se mantenga cerrado para siempre).

## 4. Por cada cambio sustantivo

### 4.1 Índice enriquecido (`30_procesamiento/39_consolidar_json.R`)

**Qué:** el `transmute` del índice agrega `partido_nombre` (de
`d$partido_nombre`) y `sexo` (de `d$sexo`, sin traducir en R — la etiqueta la
arma el JS). **Por qué:** ambos campos ya existían en la tabla `diputados`
(se usan desde sesión 1 en el bloque de perfil); el índice simplemente no los
exponía por el alcance explícito de la Fase 0 original. **Cómo:** una línea
en el `transmute` existente, sin tocar joins ni validaciones. **Verificación:**
`run_all(only = 39)` (sin re-golpear la API, usa los intermedios `.rds`
cacheados); en R, sobre ambas rutas (`40_salidas/json/` y `docs/data/`): 155
entradas, `partido_nombre` no vacío en las 155, dominio de `sexo` confirmado,
`tendencia` null sigue en 25 (sin regresión).

### 4.2 Dashboard (`docs/index.html`)

**Qué:** eliminación de `PARTIDO_NOMBRES`; el chip/tooltip de partido (tabla y
ficha) y el panel de filtro Partido ahora leen `partido_nombre` desde cada fila
del índice real. Subtítulo de fila construido desde `SEXO_LABEL[r.sexo]` con
fallback neutro. **Cómo:** `computeStatic()` ahora captura `p.nombre` desde
`r.partido_nombre` al derivar la lista de partidos (antes solo capturaba
`sigla`, `tendencia`, `count`); `buildRows()` y `buildProfileView()` usan
`r.partido_nombre`/`rec.partido_nombre` en vez de la constante eliminada.
**Verificación:** ver sección 5.

## 5. Verificación en navegador (evidencia)

Sin errores de consola en ninguna prueba (servidor estático local, no toca el
invariante R-only: solo sirve archivos, sin lógica de datos).

- **Tabla, filas reales (viewport 1400px):** `Agustín Romero Leiva → sub:
  "Diputado", chip "PREP", tooltip "Partido Republicano"`; `Alejandra
  Valdebenito Torres → sub: "Diputada", chip "UDI", tooltip "Unión Demócrata
  Independiente"`. Confirmado por `querySelector` directo, no solo visual.
- **Grupo IND:** filtro por tendencia `sinclasificar` → filas con chip `IND` y
  tooltip real `"Independientes"` (no la sigla repetida), género real por fila
  (`Diputado`/`Diputada` según corresponda, no un texto fijo).
- **Fallback de género:** evaluado directamente contra la constante
  (`SEXO_LABEL['OtroValor'] || SEXO_LABEL_NEUTRO` y
  `SEXO_LABEL[null] || SEXO_LABEL_NEUTRO`) → ambos resuelven a
  `"Diputada/Diputado"`. No hay caso real en los datos actuales que dispare
  este camino (dominio cerrado, sección 3), pero el código está probado.
- **Ficha (id `1165`):** chip de partido `"PREPPartido Republicano"` (sigla +
  nombre completo real, sin la constante).
- **`grep -c "PARTIDO_NOMBRES" docs/index.html` → 0.**
- **`grep -nE "googleapis|gstatic|unpkg|jsdelivr|cdn|https?://" docs/index.html`
  → 0 coincidencias** (sin regresión del invariante sin-CDN).
- **Responsive:** el viewport por defecto del preview (666px) confirmó de paso
  el layout móvil (mobile-lbl visible, sub de género oculto por diseño en esa
  vista, tal como especifica el handoff).

## 6. Bugs encontrados y resueltos

Ninguno nuevo. Un contratiempo de herramienta (no de código): el preset
`desktop` del resize del preview no cambió `window.innerWidth` en la pestaña
ya abierta; se resolvió usando `width`/`height` explícitos (1400×900) y
disparando `resize` manualmente para sincronizar `state.vw`. No afecta al
dashboard en uso real (el listener de `resize` nativo del navegador funciona
normalmente; fue una particularidad del control remoto del preview).

## 7. Verificación de invariantes (🔒)

| Invariante | Estado | Evidencia |
|-----------|--------|-----------|
| R único lenguaje del pipeline y de toda verificación | PASA | Fase A e inspección del dominio de `sexo` en R puro; ninguna inspección en Python esta vez |
| Web estática autocontenida, sin CDN | PASA | grep de red = 0 tras el cambio |
| Llaves siempre string en JS | PASA | sin cambios en el manejo de `id`/`partido` |
| No fabricar datos (género real, fallback neutro si no resuelve) | PASA | `SEXO_LABEL` + `SEXO_LABEL_NEUTRO`, probado con valores desconocidos |
| No push, no PR | PASA | 2 commits solo locales en `feature/dashboard-fase2` |

## 8. Pendientes / `# REVISAR`

Ninguno nuevo. Los heredados de la sesión anterior (rol "Firmante" siempre,
`admisible` solo `"true"` observado, ~33% de votos sin boletín, huecos de
distrito/región/tramitación) no se tocaron en esta continuación.

## 9. Notas para el revisor

- Los dos commits de esta continuación son puramente aditivos sobre lo ya
  revisado en `20260709_dashboard_fase2_log.md`; no reabren decisiones previas.
- El único punto a revisar con detalle: `computeStatic()` ahora asume que
  todas las filas de un mismo `sigla` comparten el mismo `partido_nombre` (es
  el caso, por construcción del pipeline — un partido tiene un solo nombre),
  pero si en el futuro el índice permitiera nombres inconsistentes por sigla,
  `computeStatic` se queda con el del primer `r` que encuentra para esa sigla.
