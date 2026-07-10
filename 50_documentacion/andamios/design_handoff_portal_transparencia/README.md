# Handoff: Portal de Transparencia Legislativa

## Overview
Portal público de transparencia para la Cámara de Diputadas y Diputados de Chile (155 escaños). Permite a la ciudadanía explorar a las y los parlamentarios, filtrar por partido / tendencia política / región, y abrir la ficha individual de cada uno con su asistencia, historial de votaciones y proyectos de ley presentados.

El portal tiene **dos vistas** dentro de una sola página (SPA):
1. **Índice** — buscador + filtros + gráfico de hemiciclo + tabla ordenable de las 155 personas.
2. **Ficha** (perfil) — detalle individual al hacer clic en una fila.

> **Nota:** el diseño usa **datos ficticios generados determinísticamente** (nombres, partidos, estadísticas). En producción estos deben reemplazarse por datos reales de la fuente oficial (p. ej. API/OData de la Cámara). El diseño ya contempla estados de "sin dato" para región/distrito, que en la fuente actual no está disponible.

## About the Design Files
Los archivos de este paquete son **referencias de diseño creadas en HTML** — un prototipo funcional que muestra el aspecto y comportamiento deseados, **no** código de producción para copiar tal cual. La tarea es **recrear este diseño en el entorno del codebase de destino** (React, Vue, etc.) usando sus patrones y librerías establecidas. Si aún no existe un entorno, elegir el framework más apropiado (se recomienda React, ya que el prototipo es esencialmente un componente React con estado) e implementarlo allí.

`Portal Transparencia.dc.html` es un "Design Component": la plantilla HTML vive entre las etiquetas `<x-dc>…</x-dc>` y la lógica en la clase `class Component extends DCLogic`. `DCLogic` es una envoltura sobre `React.Component` (tiene `state`, `setState`, `props`, ciclo de vida; en lugar de `render()` expone `renderVals()` que devuelve los valores que la plantilla consume). Para reimplementar: la clase se traduce casi 1:1 a un componente React con hooks/estado, y la plantilla a JSX. `support.js` es el runtime del prototipo y **no debe portarse**.

## Fidelity
**Alta fidelidad (hi-fi).** Colores, tipografía, espaciados, radios e interacciones son finales. Recrear la UI de forma pixel-perfect con las librerías del codebase. Los únicos "placeholders" son los **datos** (ver Overview) y el dato de **región/distrito** (intencionalmente "Sin dato").

---

## Screens / Views

### Vista global — Barra superior (siempre visible)
- **Layout:** franja horizontal, `flex` con `space-between`, `fl-wrap`, `gap:16px`, `padding:14px 24px`.
- **Fondo:** `#241F18` (café muy oscuro). Texto `#F1ECDF`.
- **Izquierda:** logo (cuadrado 36×36, `border:1.5px solid #6A6250`, `border-radius:7px`, con un rombo interno 13×13 `#B4AC9C` rotado 45°) + dos líneas de texto:
  - Eyebrow: `Cámara de Diputadas y Diputados · Chile` — 11px, `letter-spacing:0.06em`, color `#B4AC9C`.
  - Título: `Portal de Transparencia Legislativa` — Spectral 17px, weight 600, `letter-spacing:-0.01em`.
- **Derecha:** badge `Propuesta · datos ficticios` — IBM Plex Mono 10.5px, `letter-spacing:0.08em`, color `#241F18`, fondo `#C9B896`, `padding:5px 10px`, `radius:5px`.

---

### Vista 1 — Índice

**Propósito:** buscar, filtrar y ordenar a las 155 diputadas/diputados; ver la composición del hemiciclo.

**Layout:** ancho máximo de contenido `1200px`, centrado. Tres bloques apilados: (A) zona sticky de filtros, (B) tarjeta de hemiciclo, (C) tarjeta de tabla.

#### A. Zona de filtros (sticky)
- Contenedor `sticky top:0 z-index:40`, fondo `#EFEBE0`, `border-bottom:1px solid #DED6C2`, `padding:16px 24px 14px` (en móvil `static`, `padding:14px 16px`).
- Fila `flex wrap`, `gap:10px`, `align-items:center`:
  - **Input de búsqueda** — `flex:1 1 220px`, `min-width:170px`. Estilo: `padding:10px 14px`, `border:1px solid #DED6C2`, `radius:9px`, fondo `#FBFAF5`, 14px, color `#2A2622`. Focus: `border-color:#2F5578` + `box-shadow:0 0 0 3px rgba(47,85,120,.12)`. Placeholder `Buscar por nombre…`. Filtra por substring del nombre (case-insensitive).
  - **Botón "Partido ▾"** — abre panel dropdown (checkboxes multi-selección). Muestra sufijo ` · N` con el número de partidos seleccionados. Estilo botón: `padding:10px 14px`, `border:1px solid #DED6C2`, `radius:9px`, fondo `#FBFAF5`, 14px weight 500 color `#3A342A`; hover `border-color:#C4B492`.
  - **Botón "Región ▾"** — abre panel dropdown (single-select radio-like). Etiqueta cambia a `Región · <valor>` o `Región · Sin dato`.
  - **Botón "Limpiar"** (solo si hay filtros activos) — texto, color `#A6483F` weight 600, hover subrayado. Resetea búsqueda, partidos, tendencia y región.
  - **Contador** (empujado a la derecha con `margin-left:auto`): `Mostrando <N> de 155`, 13px, color `#6B634F`, con el número en `#2A2622`.

- **Panel Partido** (dropdown): `position:absolute; top:calc(100% + 6px)`, ancho 308px, `max-height:344px` scroll, fondo `#FBFAF5`, `border:1px solid #DED6C2`, `radius:12px`, `box-shadow:0 14px 32px rgba(50,40,20,.17)`, `padding:8px`. Cada opción (`padding:8px 10px`, `radius:8px`, hover fondo `#F0EBDE`):
  - checkbox 16×16 (checked: fondo `#2F5578`, "✓" blanco; unchecked: `border:1.5px solid #CBC2AC`),
  - punto de color 8×8 (color = paleta de la tendencia del partido; independientes = círculo con borde dashed),
  - sigla en IBM Plex Mono 12px weight 600 color `#4A4436` (ancho fijo 44px),
  - nombre completo 12.5px color `#6B634F` truncado con ellipsis.
- **Panel Región** (dropdown): ancho 250px, mismas cajas visuales. Opciones: `Todas las regiones` (valor ""), `Sin dato` (valor especial `__sindato__`), y las 16 regiones de Chile. Cada opción 13px color `#3A342A`, con "✓" (color `#2F5578`) a la izquierda si está seleccionada.
- Un **overlay invisible** `position:fixed inset:0 z-index:20` se monta cuando cualquier panel está abierto; clic en él cierra los paneles.

#### B. Tarjeta de hemiciclo
- Contenedor exterior `max-width:1200px`, `padding:18px 24px 0`. Tarjeta: fondo `#FBFAF5`, `border:1px solid #E4DDCB`, `radius:12px`, `padding:16px 20px 14px`.
- Título: `Distribución de los <N> diputadas y diputados:` — 14px weight 600 color `#3A342A`. `<N>` con `font-variant-numeric:tabular-nums`.
- **Leyenda** (flex wrap centrada, `gap:6px 12px`): un ítem por tendencia (orden: Izquierda, Centroizquierda, Centro, Centroderecha, Derecha, Independiente). Cada ítem clicable (filtra por tendencia): swatch circular 10×10 + label 12px `#524B3C` + conteo en negrita `#241F18` + porcentaje `(NN%)` en 11.5px `#8A8266`. Ítems no seleccionados bajan a `opacity:0.5` cuando hay alguna tendencia seleccionada.
- **Gráfico SVG** de hemiciclo (`viewBox="-6 -6 212 110"`, `max-width:500px` centrado): 155 círculos (`r=2.7`) dispuestos en semicírculo, 8 filas, radio interno ratio 0.42. Cada asiento coloreado por tendencia; clic filtra por esa tendencia. Asientos fuera del subconjunto filtrado → `opacity:0.12`; asientos de tendencias no seleccionadas (cuando hay selección) → `opacity:0.24`. Independientes: relleno claro `#F4EFE2` con borde del color.

#### C. Tarjeta de tabla
- Contenedor `max-width:1200px`, `padding:20px 24px 64px`. Tarjeta: `border:1px solid #E4DDCB`, `radius:12px`, `overflow:hidden`, fondo `#FBFAF5`, `box-shadow:0 1px 2px rgba(60,50,30,.05)`.
- **Cabecera** (solo desktop): fila `height:46px`, `padding:0 22px`, fondo `#F0EBDE`, `border-bottom:1px solid #DED6C2`. Columnas (11.5px weight 700 `letter-spacing:0.01em` color `#6B634F`):
  - `Nombre` — `flex:1 1 auto; min-width:160px`, **botón** de orden.
  - `Partido` — ancho 70px (tooltip "Sigla del partido…", `cursor:help`).
  - `Tendencia` — ancho 156px.
  - `Región / Distrito` — ancho 118px.
  - `Asistencia` — ancho 96px, alineado a la derecha, **botón** de orden.
  - `Proyectos presentados` — ancho 104px, derecha, **botón** de orden.
  - `Votaciones` — ancho 104px, derecha, **botón** de orden.
  - Los botones de orden muestran ▲ (asc) / ▼ (desc) junto al label de la columna activa.
- **Filas** (desktop): `height:62px` (densidad Cómoda) o `46px` (Compacta), `padding:0 22px`, `border-bottom:1px solid #ECE6D8`, fondo `#FBFAF5`, `cursor:pointer`. Hover: fondo `#F4EFE2`. Contenido por celda:
  - **Nombre:** nombre 15px weight 600 color `#2A2622` `letter-spacing:-0.01em`; debajo `Diputada`/`Diputado` en 11.5px `#96907C`.
  - **Partido:** chip con sigla — IBM Plex Mono 12px weight 600 `#4A4436`, fondo `#EAE4D4`, `border:1px solid #DED6C2`, `padding:2px 7px`, `radius:5px`. Tooltip = nombre completo del partido.
  - **Tendencia:** punto 10×10 (color de la tendencia; independientes con borde) + label 13px `#524B3C`.
  - **Región / Distrito:** `Sin dato` en 12px itálica `#A59C82`.
  - **Asistencia:** porcentaje 14.5px weight 600 tabular-nums, alineado derecha; opcionalmente barra 54×5 (fondo `#EAE4D4`, relleno = color de tendencia) si el toggle está activo.
  - **Proyectos / Votaciones:** número 14.5px weight 600 tabular-nums, alineado derecha.
- **Móvil (< 820px):** cada fila se vuelve una tarjeta apilada (`flex wrap`, `padding:15px 16px`), sin cabecera; cada valor numérico lleva su etiqueta encima (10.5px weight 600 `#8A8266`).
- **Estado carga:** 3 filas skeleton con shimmer (~320ms al montar).
- **Estado vacío:** título Spectral 20px `Sin resultados`; si se filtró por una región concreta, mensaje explicando que el dato de región no está en la fuente; si no, `Ajusta los filtros o la búsqueda.`

---

### Vista 2 — Ficha (perfil)

**Propósito:** detalle de una persona. Se abre al hacer clic en una fila; scroll al top; skeleton ~480ms y luego contenido con animación `fadeUp`.

**Layout:** `max-width:1080px`, `padding:22px 20px 64px`.

- **Botón "‹ Volver al índice"** — inline-flex, `border:1px solid #DED6C2`, `radius:8px`, `padding:8px 14px`, 13px weight 600 `#524B3C`; hover `border-color:#C4B492` + fondo `#FBFAF5`.
- **Cabecera de ficha** — tarjeta `flex wrap` `space-between`, fondo `#FBFAF5`, `border:1px solid #E4DDCB`, `radius:14px`, `padding:24px 26px`:
  - **Bloque izquierdo** (`flex:1 1 340px`): eyebrow `Ficha de diputada o diputado` (IBM Plex Mono 11px `letter-spacing:0.1em` `#A59C82`); `<h1>` con el nombre — Spectral 30px weight 600 color `#241F18`. Debajo, chips: (1) tendencia (fondo = color de tendencia, texto blanco; independientes con borde), (2) sigla + nombre del partido (fondo `#EAE4D4`), (3) `Región/distrito: Sin dato` (borde, `#96907C`, itálica).
  - **Bloque derecho — tarjeta Asistencia** (`flex:0 0 300px`, fondo `#F3EEE1`, `border:1px solid #E4DDCB`, `radius:12px`, `padding:16px 18px`): label `Asistencia` (mono 11px `#8A8266`) + porcentaje grande Spectral 40px weight 600 `#241F18` con `%` en 22px verde `#4B7A52`; barra de progreso 7px (fondo `#EAE4D4`, relleno verde `#4B7A52`); 3 mini-tarjetas: **Sesiones** (número `#2A2622`), **Asiste** (verde `#4B7A52`), **No asiste** (rojo `#A6483F`), cada una 18px weight 600 con label 10px `#8A8266`.
- **Tarjeta Votaciones** (ancho completo, fondo `#FBFAF5`, `border:1px solid #E4DDCB`, `radius:14px`, `padding:22px 24px`):
  - Header: label mono `Votaciones` + `<total> registradas` (total en Spectral 20px).
  - **Barra apilada** 14px de alto (`radius:7px`) con 4 segmentos: A favor `#4B7A52`, En contra `#A6483F`, Abstención `#B0873C`, Pareo `#8C8578`; leyenda debajo con punto cuadrado 9×9 + label + conteo.
  - **Tabla de votaciones** (max-height 280px scroll): columnas Boletín (mono 12px), Fecha, Materia, Resultado (`Aprobado` verde / `Rechazado` rojo), Mi voto (color del sentido). Encabezado en IBM Plex Mono 10px `letter-spacing:0.04em` `#A59C82`. Nota en itálica si hay más de 16 (se muestra muestra de 16).
- **Tarjeta Proyectos** (ancho completo, mismo estilo, `margin-top:18px`):
  - Header: `Proyectos presentados · mociones <total>` + badge `El estado de tramitación no está disponible en la fuente`.
  - Si 0 → `No presentó mociones en el período.` (itálica).
  - Si >0 → tabla: Boletín (mono), Nombre del proyecto, Ingreso (fecha), Rol (`Autor/a`/`Adherente`), Admisible (chip pill: `Admisible` verde / `Inadmisible` rojo, con fondo y borde tenues).
- **Skeletons de carga** para la sección inferior mientras `loadingProfile` (bloques shimmer de 240px y 150px).

---

## Interactions & Behavior
- **Navegación:** SPA sin rutas; el estado `view` (`'index'` / `'profile'`) alterna las vistas. Clic en fila → `openProfile(id)`; botón Volver → `back()`. Al abrir perfil se hace `window.scrollTo(0,0)`.
- **Búsqueda:** filtrado en vivo por substring del nombre (minúsculas, sin acento-normalización explícita).
- **Filtro Partido:** multi-select (objeto `{sigla:true}`). Fila pasa si su sigla está en la selección (o si no hay selección).
- **Filtro Tendencia:** multi-select, activable desde leyenda o desde los asientos del hemiciclo. Afecta las filas mostradas y atenúa (opacity) los elementos no seleccionados del gráfico y leyenda.
- **Filtro Región:** single-select. Cualquier región concreta (≠ "") produce 0 resultados a propósito (no hay dato de región en la fuente) → estado vacío explicativo. En producción, conectar a datos reales.
- **Orden:** clic en cabeceras Nombre/Asistencia/Proyectos/Votaciones. Primer clic: nombre asc, numéricos desc; clics siguientes alternan dir. Desempate secundario por nombre (`localeCompare` 'es').
- **Dropdowns:** solo uno abierto a la vez; overlay full-screen cierra al hacer clic fuera.
- **Animaciones:**
  - `shimmer` — skeleton loaders, `1.4s infinite linear`, gradiente que se desplaza sobre `background-size:720px`.
  - `fadeUp` — entrada de contenido de perfil, `0.3s ease`, `opacity 0→1` + `translateY(6px→0)`.
  - Barras del hemiciclo: `transition:height .25s, opacity .2s`.
- **Timing simulado:** índice "carga" 320ms; perfil "carga" 480ms. En producción, reemplazar por estados reales de fetch.
- **Responsive:** breakpoint en **820px** (`isNarrow`). Bajo 820px: filtros no-sticky, tabla → tarjetas apiladas con etiquetas, sin cabecera de tabla, tamaños de fuente ligeramente menores. Se escucha `window.resize`.

## State Management
Variables de estado (en el prototipo, en `this.state`):
- `view` — `'index'` | `'profile'`
- `selectedId` — id de la persona abierta
- `loadingProfile` — bool (skeleton de perfil)
- `profileRaw` — datos generados del perfil actual
- `indexReady` — bool (skeleton del índice)
- `search` — string
- `selectedParties` — `{ [sigla]: true }`
- `selectedTend` — `{ [tendencia]: true }`
- `region` — string (`''`, `'__sindato__'`, o nombre de región)
- `sort` — `{ field: 'nombre'|'asistencia'|'proyectos'|'votaciones', dir: 'asc'|'desc' }`
- `partyPanelOpen`, `regionPanelOpen` — bools
- `vw` — ancho de ventana (para responsive)

**Data fetching (producción):** reemplazar la generación determinística por llamadas reales. Endpoints sugeridos: lista de parlamentarios (nombre, sexo, partido, tendencia, región/distrito, %asistencia, #proyectos, #votaciones); detalle por id (sesiones/asiste/no_asiste, votaciones con boletín/fecha/materia/resultado/sentido, mociones con boletín/nombre/fecha/rol/admisibilidad).

## Design Tokens

**Colores — base / superficies**
- Fondo página: `#EFEBE0`
- Superficie tarjeta: `#FBFAF5`
- Superficie secundaria / hover fila: `#F4EFE2`
- Superficie terciaria (cabecera tabla, tarjeta asistencia): `#F0EBDE` / `#F3EEE1`
- Chip / relleno tenue: `#EAE4D4`
- Barra oscura (topbar): `#241F18`; texto sobre oscuro `#F1ECDF`, mutado `#B4AC9C`
- Badge propuesta: fondo `#C9B896`

**Colores — bordes**
- Borde principal: `#DED6C2`
- Borde tarjeta: `#E4DDCB`
- Borde divisor filas: `#ECE6D8` / `#EDE7D9`
- Borde hover botón: `#C4B492`

**Colores — texto**
- Primario: `#2A2622` / `#241F18`
- Secundario: `#3A342A` / `#524B3C`
- Terciario / mutado: `#6B634F` / `#8A8266` / `#96907C` / `#A59C82`

**Colores — acento / semántico**
- Azul (links, focus, checkbox): `#2F5578` (hover `#21384f`)
- Verde (positivo / asistencia / a favor / admisible): `#4B7A52`
- Rojo (negativo / limpiar / en contra / inadmisible): `#A6483F`
- Ámbar (abstención): `#B0873C`
- Gris (pareo): `#8C8578`

**Paletas de tendencia política** (prop `tendenciaScheme`, 3 opciones):
- *Divergente rojo-azul* (default): izquierda `#AE3B34`, centroizquierda `#CB7B62`, centro `#9A917F`, centroderecha `#5E86AC`, derecha `#2F5578`, independiente `#B4AC9C`
- *Secuencial teal*: `#A9CFC9` · `#79B2A9` · `#4E9086` · `#2F7268` · `#17534A` · `#B4AC9C`
- *Categórica sobria*: `#A6564E` · `#B0863F` · `#6E8E68` · `#4E7C93` · `#6A5B8A` · `#B4AC9C`

**Tipografía** (Google Fonts):
- **Spectral** (serif) — títulos, cifras destacadas. Weights 400/500/600/700.
- **Public Sans** (sans) — cuerpo/UI por defecto. Weights 400/500/600/700.
- **IBM Plex Mono** — siglas, boletines, eyebrows, encabezados de tabla de detalle. Weights 400/500.
- Escala usada: 30px (h1 ficha), 40px (cifra asistencia), 20px (títulos vacío/totales), 17px (título topbar), 15px (nombre fila), 14.5px (números fila), 14px (input/labels), 13px, 12.5px, 12px, 11.5px, 11px, 10.5px, 10px. `letter-spacing:-0.01em` en titulares; `0.04–0.1em` en eyebrows mono. Números con `font-variant-numeric:tabular-nums`.

**Radios:** 5px (chips/badges), 7px (barra progreso, logo), 8px (mini-tarjetas, opciones dropdown, botón volver), 9px (input, botones filtro), 12px (tarjetas índice, dropdowns), 14px (tarjetas ficha), 20px (chips pill), 50% (puntos).

**Sombras:** `0 1px 2px rgba(60,50,30,.05)` (tarjetas), `0 14px 32px rgba(50,40,20,.17)` (dropdowns), focus ring `0 0 0 3px rgba(47,85,120,.12)`.

**Espaciados frecuentes:** padding topbar `14px 24px`; tarjetas índice `16px 20px`; tarjetas ficha `22px 24px`; contenido `max-width:1200px` (índice) / `1080px` (ficha); gaps `6–22px`.

## Props / Tweaks (configurables)
El componente raíz expone 3 props:
- `tendenciaScheme` (enum) — `Divergente rojo-azul` (def) | `Secuencial teal` | `Categórica sobria`. Cambia toda la codificación de color por tendencia.
- `rowDensity` (enum) — `Cómoda` (def, filas 62px) | `Compacta` (46px).
- `showAsistenciaBar` (boolean, def false) — muestra/oculta la barrita de asistencia en cada fila de la tabla.

## Assets
Sin imágenes ni íconos externos. Toda la iconografía es CSS/Unicode:
- Logo: cuadrado con rombo interno (divs).
- Flechas dropdown `▾`, orden `▲`/`▼`, check `✓`, chevron volver `‹` — caracteres Unicode.
- Hemiciclo: SVG generado programáticamente (155 `<circle>`).
Fuentes desde Google Fonts (ver Tipografía). En producción, autohospedar si se requiere offline.

## Files
- `Portal Transparencia.dc.html` — prototipo completo (plantilla en `<x-dc>` + lógica en `class Component`). **Fuente principal a portar.** La lógica (generación de datos, filtros, orden, hemiciclo) está en la clase; la maquetación e inline-styles en la plantilla.
- `support.js` — runtime del entorno de prototipado. **No portar.** Incluido solo para que el HTML abra y se pueda inspeccionar en un navegador.

Para previsualizar: abrir `Portal Transparencia.dc.html` en un navegador (requiere `support.js` en la misma carpeta).
