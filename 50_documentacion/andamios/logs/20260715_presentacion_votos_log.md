# Log de ejecución — Presentación de votos y región/distrito (Capa 1)

**Fecha:** 2026-07-15
**Rama:** `feat/presentacion-votos` (desde `main` 1be1538; sin push, sin PR, sin merge).
**Entorno:** Claude Code, macOS, R 4.5.2, servidor local de verificación en R (`servr`).
**Naturaleza:** andamio congelado (registro de ejecución, no se actualiza).

## 1. Resumen

Dos cambios de presentación en `docs/index.html`, Capa 1 de la ruta aprobada en
la sesión 8. Ninguno toca el pipeline, ningún `.R`, ningún JSON de datos: el JSON
publicado ya contenía todo lo necesario.

1. **Recorte de votos → toggle.** El perfil mostraba solo los 16 votos más
   recientes; un diputado con 717 votos exhibía el 2 %, lo que impedía
   "verificar un voto puntual". Ahora un botón `Ver los N votos` / `Ver menos`
   expande la lista completa en el mismo lugar. Sin paginación ni buscador
   propio (Ctrl+F del navegador).
2. **Región/distrito deja de estar hardcodeado.** La UI escribía el literal
   `Sin dato` sin consultar el JSON; con la Capa 2 habría seguido diciéndolo.
   Ahora lee `region`/`distrito` y degrada solo si ambos faltan.

Dos commits atómicos. Sin push.

## 2. Inventario de commits

| Fase | Hash | Tipo | Título |
|------|------|------|--------|
| 1 | `2b702dd` | feat | la celda de region/distrito lee el dato del indice en vez de hardcodear "Sin dato" |
| 2 | `c213aa6` | feat | boton para expandir la lista completa de votos en el perfil |

`git diff --name-only main...HEAD` → `docs/index.html` (un solo archivo).

## 3. Detalle por cambio

### 3.1 Región/distrito (Fase 1)
- `regionPartes(r)`: normaliza `null` y cadena vacía a ausencia.
- `renderRegionCell(r)`: celda de la tabla; región arriba, `Distrito N` como
  sublínea; degrada a `<span class="sin-dato">Sin dato</span>`.
- `renderRegionChip(r)`: chip del encabezado de la ficha; una línea
  (`Región · Distrito N`). El span interno (itálico por CSS) queda reservado al
  degradado, igual que `.sin-dato` en la tabla.
- CSS nuevo: `.cell-region .region-nombre` y `.cell-region .region-sub`,
  copiando los valores de `.cell-nombre-name` / `.cell-nombre-sub`.
- Todo dato pasa por `esc()`.

**Ampliación respecto del encargo (§6, decisión 1):** el encargo señalaba solo la
celda de la tabla (L718). El chip del encabezado de la ficha (L1003) hardcodeaba
el mismo literal. Se corrigió también.

### 3.2 Toggle de votos (Fase 2)
- `state.votosExpandidos` (bool), reseteado en `syncFromHash()` → abrir otro
  perfil, o reentrar al mismo, vuelve a la lista colapsada. Estado por perfil,
  no global. Sin localStorage.
- `buildVotacionesSection()`: `LIMITE_COLAPSADO = 16`;
  `hayMas = list.length > 16`; `expandido = hayMas && state.votosExpandidos`.
  La conjunción con `hayMas` hace estructuralmente imposible que el botón
  desaparezca dejando la lista expandida sin forma de colapsar.
- Acción `toggle-votos` en el `switch` de `data-action` existente.
- CSS nuevo: `.btn-votos` (reusa `--border-main`, `--surface-card`,
  `--focus-ring`), `.mini-tbody.expandida{max-height:70vh}` — el estado
  colapsado conserva los `280px` actuales, intacto.
- La lógica del voto sin proyecto (`colBoletin` / `colDesc`) **no se tocó**:
  bloque byte-idéntico a `main` (md5 `6675df84…`, verificado por el panel).

## 4. Verificación en navegador (obligatoria)

Servidor local en R sobre `docs/`, perfil del caso de estrés (id 1165, 717 votos).
Conteos del DOM medidos programáticamente, no a ojo.

| Comprobación | Resultado |
|---|---|
| Caso de estrés (máx. votos) | **717** (71 diputados empatan en 717) |
| Filas en DOM al expandir vs `n_votaciones` | **717 = 717** ✓ |
| Colapsar vuelve a 16 | ✓ (clic real sobre el botón, vía `ref`) |
| Voto sin proyecto: tipo + descripción | **226 de 717** con `boletin: null` → 226 `.voto-tipo-sinbol` renderizados ✓ |
| Errores en consola | **0** |
| Región con dato inyectado en memoria | `Valparaíso · Distrito 7`; solo región → `Biobío`; solo distrito → `Distrito 12` ✓ |
| Degradado hoy (155/155 null) | byte-idéntico al literal anterior ✓ |
| Escapado | `<script>` e `<img onerror>` inyectados → 0 nodos creados ✓ |
| Responsive (`isNarrow()===true`) | tabla `.narrow`, toggle 16↔717 funciona ✓ |
| Densidad (`state.density`) | conservada ✓ |

**Rendimiento:** expandir las 717 filas cuesta **9 ms** de re-render (colapsar,
7 ms). No hay degradación; no se activa el caso de detención 2.

## 5. Panel adversarial (Fase 3)

Dos auditores independientes de solo lectura. Ambos **CONFIRMARON** las dos
afirmaciones de mayor riesgo. No contradijeron el reporte. Matices que
levantaron, registrados por honestidad:

1. **`esc()` no cubre literalmente "todo dato".** Los numéricos
   (`total`, `s.count`, `s.pct`, y los nuevos `list.length` y `LIMITE_COLAPSADO`)
   se concatenan crudos. Inocuo (un `Array.length` es entero no negativo, no
   puede portar marcado) y **preexistente**: esta rama no introduce ninguna
   brecha nueva de escapado. La formulación exacta es "toda cadena de origen
   externo pasa por `esc()`".
2. **La nota cambió de denominador.** `main` usaba `total` (`v.n_votaciones`,
   el conteo declarado por el pipeline); ahora usa `list.length` (el largo real
   del array, que es lo que efectivamente se puede mostrar). Verificados los
   155 perfiles: **0 divergencias**. Acoplamiento latente, no un bug vivo. Si
   algún día divergen, el encabezado ("N registradas") y el botón ("Ver los M
   votos") se contradirían a la vista — que es justamente el síntoma deseable.

## 6. Decisiones tomadas en ejecución

1. **Corregir también el chip de región de la ficha (L1003).** El encargo
   señalaba solo L718. Arreglar únicamente la tabla habría dejado el habilitante
   a medias: con la Capa 2, la tabla mostraría la región y la ficha seguiría
   negándola. Mismo defecto, mismo criterio, mismo archivo.
2. **Conservar `max-height:280px` al colapsar y usar `70vh` al expandir.** El
   estado colapsado queda indistinguible del actual; expandir dentro de una
   ventana de 280 px habría hecho inusable la lista completa.
3. **Botón por sobre la nota.** Colapsado se conservan ambos (la nota informa
   el recorte, el botón lo revierte); expandido, la nota desaparece.

## 7. Hallazgos fuera del encargo (para el titular)

1. **`.claude/launch.json` violaba el invariante 🔒 1.** Estaba commiteado
   (`63e6d57`, ya en `main`) con `python3 -m http.server` como servidor de
   preview. El invariante prohíbe Python "en ningún contexto", con alcance
   explícito sobre "toda verificación, auditoría o script auxiliar". Se
   reemplazó por `Rscript -e "servr::httd(dir='docs', port=8123, ...)"` (mismo
   puerto, mismo directorio) y se usó ese servidor para verificar. **Queda
   modificado en el working tree, SIN commitear:** es andamiaje local, no
   producto, y la decisión de versionarlo es del titular.
2. **`encargo_autonomo_claude_code_v1.md` no existe en el repo.** El encargo lo
   cita como referencia de formato de este log (§4). Se siguió el formato de los
   logs existentes en `50_documentacion/andamios/logs/`.
3. **El ejecutor usó Python una vez**, al inicio, para ordenar el índice por
   `n_votaciones` — violando el invariante 🔒 1. Se detectó en el acto, se
   rehízo la inspección en R y no se repitió. Ningún resultado reportado
   proviene de esa ejecución.

## 8. Estado final

- Rama `feat/presentacion-votos`, 2 commits sobre `main`. Sin push, sin PR.
- `docs/` limpio: todo el trabajo está commiteado.
- Working tree: `.claude/launch.json` modificado sin commitear (§7.1) + 13
  archivos heredados sucios en `50_documentacion/` (preexistentes de la sesión
  7, mtime del 11 de julio; no los tocó este trabajo).
- Casos de detención: ninguno se activó. `region`/`distrito` existen como claves
  en el índice; el rendimiento del caso de estrés es holgado; no se tocó ningún
  `.R` ni JSON de datos.
