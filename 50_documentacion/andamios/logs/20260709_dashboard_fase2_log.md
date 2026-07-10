# Log de ejecución — Dashboard Fase 2 (sesión 3)

**Proyecto:** transparencia_legislativa_chile
**Fecha:** 2026-07-09
**Entorno:** Claude Code, macOS, R 4.5.2, npm 11.12.1, rama `feature/dashboard-fase2`.
**Naturaleza:** andamio congelado (registro de ejecución, no se actualiza).

## 1. Resumen de la sesión

Encargo autónomo dirigido por meta: construir la Fase 2 (dashboard estático)
consumiendo el JSON real ya producido en sesiones anteriores, reconstruyendo
con alta fidelidad el handoff de diseño entregado
(`50_documentacion/andamios/design_handoff_portal_transparencia/`). Cinco
fases: (0) métricas resumen en el índice, (1) publicación a `docs/data/`,
(2) el dashboard HTML/CSS/JS vanilla, (3) fuentes autohospedadas, (4)
auto-auditoría independiente. Cuatro commits atómicos en rama de trabajo,
verificados en navegador (preview local) sin errores de consola. Sin push,
sin PR — decisión del titular.

## 2. Inventario de commits

| # | Hash | Tipo | Título | Qué hizo |
|---|------|------|--------|----------|
| 1 | `9a2b8a5` | feat | métricas resumen en índice + publicar json a docs/data | Índice con `tasa_asistencia`/`n_proyectos`/`n_votaciones` (left_join sobre roster); copia a `docs/data/` en R |
| 2 | `11cb21e` | feat | dashboard estático fase 2 | `docs/index.html`: vanilla JS, fetch+hash routing, hemiciclo, tabla, ficha |
| 3 | `bf97168` | chore | fuentes autohospedadas | 10 `.woff2` vía `@fontsource/*`, sin CDN |
| 4 | (este log) | docs | log de la sesión | — |

## 3. Por cada cambio sustantivo

### 3.1 Métricas resumen en el índice (`30_procesamiento/39_consolidar_json.R`)

**Qué:** el índice ahora trae `tasa_asistencia`, `n_proyectos`, `n_votaciones`
por diputado. **Por qué:** el diseño los necesita en la tabla del índice sin
tener que fetchear cada perfil. **Cómo:** `left_join` (nunca `inner_join`)
sobre el roster con tablas resumen de `asistencia`/`votos`/`proyectos`;
`coalesce(..., 0L)` para conteos, `NA` se conserva en `tasa_asistencia` si no
hay fila. **Verificación:** re-corrida vía `run_all(only = 39)` (no reprocesa
la API, usa los intermedios `.rds` ya cacheados de la sesión 2); en R,
`fromJSON` sobre el índice regenerado confirmó 155 filas, columnas numéricas,
0 NA (asistencia cubre 155/155), rango `n_proyectos` 0–26, `n_votaciones`
360–672.

### 3.2 Publicación a `docs/data/` (mismo script, mismo commit)

**Qué:** copia fiel del índice + 155 perfiles a `docs/data/` (GitHub Pages
sirve desde `/docs`). **Por qué:** el dashboard necesita el JSON por ruta
relativa dentro de `/docs`. **Cómo:** en R, al final de `39_consolidar_json.R`,
`fs::file_copy` desde `40_salidas/json/` (canónico); limpia
`docs/data/perfiles/` antes de copiar (idempotente). **Verificación:** conteo
programático 155 = 155 en ambas rutas; ids idénticos (auditoría Fase 4).

### 3.3 El dashboard (`docs/index.html`)

**Qué:** archivo único autocontenido (HTML+CSS+JS inline), sin frameworks ni
build step, que reconstruye el handoff de diseño con datos reales. **Por qué:**
invariante 🔒 de web estática autocontenida; el encargo pidió vanilla, no
React (el README del handoff sugería React solo como opción si no había
entorno; aquí el proyecto ya es HTML/CSS/JS estático puro por invariante de
proyecto, así que vanilla es la opción correcta, no una desviación).
**Cómo:** estado JS plano + `render()` que reconstruye `innerHTML` desde un
árbol de funciones `build*()`; delegación de eventos vía `data-action`; el
input de búsqueda conserva foco/cursor tras cada re-render (se guarda y
restaura `document.activeElement` + `selectionStart/End`, un problema real que
apareció al traducir el patrón de recreación total del DOM del prototipo).
Geometría del hemiciclo (`computeHemicycle`) traducida 1:1 del `.dc.html`.
Rutas hash-based (`#/`, `#/diputado/<id>`) con `hashchange` como única fuente
de verdad de navegación. **Verificación:** ver sección 6 (invariantes) y
pruebas de navegador abajo.

### 3.4 Fuentes autohospedadas (`docs/assets/fonts/`)

**Qué:** 10 `.woff2` (Spectral 400/500/600/700, Public Sans 400/500/600/700,
IBM Plex Mono 400/500) descargados vía `npm install @fontsource/*` en un
directorio temporal, extraídos (`files/*-latin-<peso>-normal.woff2`) y
copiados con nombres estables. **Por qué:** invariante 🔒 sin CDN.
**Verificación:** `grep` de `docs/index.html` para
`googleapis|gstatic|unpkg|jsdelivr|cdn|https?://` → 0 coincidencias;
`document.fonts` en el navegador confirmó `status=loaded` para los pesos
efectivamente usados en la vista (Spectral 600, Public Sans ×4, IBM Plex Mono
×2); `getComputedStyle` en el título confirmó resolución real
(`font-family: Spectral, ...` con weight 600), no fallback del sistema.

## 4. Bugs encontrados y resueltos

- **Foco perdido en el buscador.** Síntoma: al re-renderizar `innerHTML`
  completo en cada tecleo, el `<input>` se recreaba y perdía foco/cursor.
  Causa raíz: patrón de "full re-render" sin reconciliación de DOM (esperable
  al no usar un framework). Fix: `render()` guarda `activeElement` +
  `selectionStart/End` antes de reescribir `innerHTML` y los restaura después.
  Verificado interactivamente con `preview_fill` (tecleo sin pérdida de foco).
- **Nombre completo de partido ausente en el índice.** El diseño exige
  tooltip con nombre completo del partido en cada fila de la tabla, pero
  Fase 0 restringió el índice a exactamente 3 columnas nuevas (sin
  `partido_nombre`). Fix: mapa estático `PARTIDO_NOMBRES` (18 entradas)
  embebido en el JS, extraído de datos REALES (`perfil.partido.nombre` en los
  155 perfiles ya generados), no inventado. Documentado como decisión, no bug
  de datos.
- **Valor `OpcionVoto` no listado.** No aplica a esta sesión (ya resuelto en
  sesión 2); se reutilizó el dominio ya corregido (`dispensado`).

## 5. Verificación de invariantes (🔒)

| Invariante | Estado | Evidencia |
|-----------|--------|-----------|
| R único lenguaje del pipeline y de la verificación | **PASA con una autocorrección** | Ver §7. Todo el pipeline (Fases 0/1/4) en R; el único uso de Python en la sesión (dos inspecciones de solo lectura del esquema JSON antes de construir el dashboard) fue detectado y corregido a mitad de sesión, re-verificando en R lo mismo (ver §7). |
| Navegador solo lee JSON precomputado, sin backend | PASA | `docs/index.html` solo hace `fetch()` a `data/*.json`; cero llamadas a APIs externas o a `opendata.camara.cl` desde el cliente (grep confirma 0 referencias de red) |
| Web estática autocontenida, sin CDN | PASA | grep de red en `docs/index.html` = 0 coincidencias; fuentes en `docs/assets/fonts/`; sin React ni build step |
| Llaves de identificación siempre character/string | PASA | JS nunca convierte `id`/`partido` a `Number`; `id` se usa como string en rutas hash, fetch paths y comparaciones (`===`) |
| No alterar clasificación de tendencia; IND=null visible, nunca oculto | PASA | `MAPA_PARTIDO_TENDENCIA` no se tocó en esta sesión; grupo "Independiente" explícito en índice/hemiciclo/leyenda/ficha, verificado interactivamente (25 filas, seats con borde dashed-equivalente, nunca `display:none`) |
| No publicar (push) sin visto bueno del titular | PASA | 4 commits solo locales en `feature/dashboard-fase2`; `git log` sin remoto tocado |

## 6. Verificación en navegador (evidencia de las pruebas manuales)

Servidor estático local (`python3 -m http.server` vía `.claude/launch.json`,
solo para servir archivos — sin lógica de datos en Python, no compromete el
invariante R-only del proyecto). Sin errores de consola en ninguna prueba.

1. **Índice carga 155 filas reales:** confirmado (`Mostrando 155 de 155`,
   snapshot de accesibilidad con nombres reales).
2. **Hemiciclo dibuja 155 asientos** con conteos correctos por tendencia:
   izquierda 26, centroizquierda 17, centro 22, centroderecha 13, derecha 52,
   independiente 25 (suma 155).
3. **Filtros:** búsqueda por substring sin normalizar acentos (`gonzalez` → 0,
   `gonzález` → 3, comportamiento documentado del handoff, no un bug); región
   concreta (`Valparaíso`) → 0 resultados con mensaje explicativo; `Sin dato`
   → 155 (todos, ya que 100% de la fuente real es `NA`); clic en tendencia
   `Independiente` (leyenda o hemiciclo) → 25 filas, seats no-IND atenuados a
   0.24, seats fuera de la base a 0.12.
4. **Orden:** verificado por inspección de cabeceras (▲/▼) y de los datos
   ordenados por nombre asc por defecto.
5. **Ficha:** clic en fila → `fetch('data/perfiles/1165.json')` real → pinta
   asistencia (98%, 58 sesiones), votaciones (barra apilada 315/295/19/0/43,
   tabla con "Sin boletín" para votos sin boletín), proyectos (2 mociones,
   rol "Firmante", pill "Admisible").
6. **Deep-link:** `location.hash = '#/diputado/1165'` seguido de
   `location.reload()` completo → la ficha se abre directamente sin pasar por
   el índice (confirmado vía `document.body.innerHTML.length` y screenshot
   tras `scrollTo(0,0)`).
7. **Grupo IND explícito:** confirmado (ver punto 3).
8. **Responsive <820px:** resize a 390×844 → filtros no-sticky, tarjetas
   apiladas sin cabecera de tabla, etiquetas por valor (`Asistencia`,
   `Proyectos presentados`, `Votaciones`) visibles sobre cada número.
9. **Panel de Ajustes:** cambio de esquema (`teal`) se propaga a
   leyenda/hemiciclo/tabla/chips; toggle de barra de asistencia visible bajo
   el porcentaje; densidad Cómoda/Compacta.

## 7. Decisiones del usuario registradas

- Sensibilidad de datos: N/A (ya resuelto en sesiones previas, proyecto 100%
  público).
- Ninguna decisión de gate en esta sesión: el encargo fue completo y
  autónomo, sin puntos de detención activados.

**Auto-corrección registrada durante la sesión (POLITICA 0.5):** al iniciar la
Fase 2, usé Python (`python3 -c "import json..."`) para dos inspecciones de
solo lectura del esquema real de `indice_diputados.json` y `perfiles/<id>.json`,
y para derivar el mapa sigla→nombre de partido. El invariante R-only precisado
en la sesión 2 ("aplica también a toda verificación, auditoría o script
auxiliar del proyecto, sin excepción") cubre este caso. Lo detecté a mitad de
sesión (antes de escribir código de producción basado en esos hallazgos), lo
señalé explícitamente en el chat, y re-derivé las mismas verificaciones en R
(`50_documentacion/andamios/logs/` — script de inspección de dominios en R,
ver también la Fase 4 de este log). Ningún artefacto commiteado depende de un
cálculo hecho en Python; los valores usados (dominios, mapa de partidos)
fueron re-confirmados en R antes de usarse en `docs/index.html`.

## 8. Pendientes abiertos y `# REVISAR`

- **Rol de autoría siempre "Firmante".** La API no distingue autor/adherente
  (`Orden=0` para todos, hueco documentado desde sesión 1). El dashboard
  muestra el rol real tal cual, no fabrica la distinción "Autor/a"/"Adherente"
  que sí aparece en el mock de diseño (dato ficticio del prototipo). Esto es
  honestidad de datos, no un defecto a corregir.
- **`admisible` solo tiene el valor `"true"`** en el corpus real actual (nunca
  se observó `"false"`). El manejo de "Inadmisible" en el CSS/JS existe y es
  correcto por si apareciera, pero no se pudo probar visualmente con un caso
  real negativo.
- **~33% de los votos no tienen boletín** (`descripcion` tipo "1-Otros",
  "Proyecto de Acuerdo N° X", etc. sin número de boletín parseable). El
  dashboard muestra "Sin boletín" en cursiva; es comportamiento esperado de la
  fuente, no un bug.
- **Subtítulo "Diputada"/"Diputado" en la fila del índice.** El handoff pide
  mostrar el género real por fila; el índice (Fase 0, alcance explícito de 3
  columnas) no trae `sexo`. Se optó por el texto neutro "Diputada/Diputado" en
  vez de fabricar o adivinar el género por fila. En la ficha (perfil) sí se
  usa el `sexo` real porque ese bloque no estaba restringido por Fase 0.
- **Preview server con `python3 -m http.server`** en `.claude/launch.json`:
  es solo un servidor de archivos estáticos para previsualizar en el
  navegador, sin lógica de datos ni verificación en Python — se documenta por
  transparencia, no se considera una desviación del invariante R-only (que
  aplica al proyecto de datos/verificación, no a infraestructura de tooling
  como git o un file server).
- Huecos heredados (sin cambios esta sesión): distrito/región no expuestos por
  la API, estado de tramitación no expuesto.

## 9. Estado de cifras/datos críticos

- `docs/data/indice_diputados.json`: 155 entradas (auditoría Fase 4).
- `docs/data/perfiles/`: 155 archivos, cada uno con los 5 bloques.
- Distribución de tendencia idéntica entre `40_salidas/json/` (canónico) y
  `docs/data/` (publicación): izquierda 26, centroizquierda 17, centro 22,
  centroderecha 13, derecha 52, `NA` 25 (= militantes IND).
- Tamaño de `docs/assets/fonts/`: 192K (10 archivos `.woff2`).

## 10. Notas para el revisor

- Rama `feature/dashboard-fase2`, no mergeada a `main`. Ningún push.
- El commit de Fase 0+1 se hizo combinado (permitido explícitamente por el
  encargo: "mismo commit o chore: publicar json a docs/data").
- Mirar con ojo crítico: el mapa `PARTIDO_NOMBRES` embebido en JS es una
  duplicación de datos que ya existen en cada perfil; se justificó por la
  necesidad de mostrarlo en la tabla del índice (155 filas) sin fetch previo,
  pero si el índice creciera una columna más en el futuro, sería más simple
  agregar `partido_nombre` al índice real en vez de mantener esta constante
  sincronizada a mano.
- La autocorrección de §7 (Python → R) es el único evento de esta sesión que
  calza en la tabla de errores del asistente; si esta sesión cierra con
  traspaso formal, debe registrarse ahí (POLITICA 0.5, SETTINGS §2.2.15).
