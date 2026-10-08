# Encargo — P-62: sello de los intermedios desalineado, y merge del PR #5

- **Destino en el repo:** `50_documentacion/andamios/50_encargo_p62_sello_intermedios.md`
- **Proyecto:** `transparencia_legislativa_chile`
- **Raíz absoluta:** `/Users/tomgc/Projects/transparencia_legislativa_chile`
- **Repo:** `tomgc/transparencia_legislativa_chile`
- **Sesión:** 16. **Pendientes:** P-62 (bloqueante) y cierre de P-61.
- **Modo:** ejecución autónoma con compuertas. Te detienes SOLO donde el encargo lo dice.

---

## 1. Meta

Dejar el proyecto en estado corrible: hoy `validar_corte()` hace `stop()` sobre los
intermedios y **cualquier corrida de `39` falla** (fuente: `50_veredicto_eje_tematico.md`
§8, riesgo 5, producto de la auditoría P-61).

El síntoma: los intermedios de `40_salidas/intermedios/` declaran sello **2026-07-27**
mientras `CORTE_FECHA` vale **2026-08-03**.

Antes de eso, cerrar P-61 mergeando su PR de documentación (#5), que no toca el pipeline.

**Lo que este encargo busca no es hacer desaparecer el `stop()`.** Es averiguar **por qué**
un artefacto sellado quedó desalineado del corte y arreglar la causa. Un arreglo que sólo
haga pasar la validación, sin explicar cómo se produjo el desalineamiento, **no cumple este
encargo**: la compuerta hizo su trabajo, el defecto está aguas arriba de ella.

---

## 2. Invariantes (🔒)

1. 🔒 **R es el único lenguaje** para toda inspección de datos. Prohibido `jq`, `awk`,
   `python`, y prohibido `grep`/`sed` sobre artefactos de datos. `git` y `gh` sí, como
   herramientas de repositorio.
2. 🔒 **Todo comando de git lleva `git -C /Users/tomgc/Projects/transparencia_legislativa_chile`.**
   Todo subcomando `gh pr` lleva `-R tomgc/transparencia_legislativa_chile`. `gh api` es la
   excepción (el repo va en el endpoint). Prohibido `gh pr diff --name-only`.
3. 🔒 **`git add` siempre con ruta acotada.** Nunca `git add .` ni `git add -A`.
4. 🔒 **No dispares el workflow** (`workflow_dispatch`).
5. 🔒 **`20_insumos/camara/` es dato crudo inmutable.** Se lee, no se escribe.
6. 🔒 **Prohibido debilitar la compuerta.** No se relaja `validar_corte()`, no se envuelve en
   `try()` ni en `suppressWarnings()`, no se le agrega un parámetro para saltarla, y no se
   toca `CORTE_FECHA` para que cuadre con el sello. La compuerta detectó un defecto real;
   apagarla es el peor desenlace posible de este encargo.
7. 🔒 **No afirmes `CORTE_FECHA` ni el valor de ningún sello sin leerlo** en el momento de
   afirmarlo, con la ruta y la línea.
8. 🔒 **Toda cifra se cuenta programáticamente en el turno en que se escribe.** Aritmética
   mental y cifras heredadas de otro documento no son fuentes.
9. 🔒 **Ningún `grep` de verificación con metacaracteres sin `-F`** (o `fixed = TRUE` en R).

---

## 3. Fases y compuertas

### Fase 1 — Cerrar P-61: mergear el PR #5

Va primero, deliberadamente: el PR #5 es sólo documentación y mergearlo deja `main` al día
para que el arreglo del sello nazca sobre un árbol limpio.

1. `git -C <raíz> fetch --all --prune` y `git -C <raíz> status`.
2. Verifica que el PR #5 **no toca el pipeline**, con `gh api` paginado sobre
   `/repos/tomgc/transparencia_legislativa_chile/pulls/5/files` y **declarando el
   denominador**: 0 archivos bajo `10_utils/`, `30_procesamiento/`, `docs/` y
   `40_salidas/`. Prohibido `gh pr diff --name-only` para esto (devuelve 406 en PRs
   grandes).
3. Si la verificación pasa: `gh pr merge 5 -R tomgc/transparencia_legislativa_chile --merge`.
4. `git -C <raíz> checkout main && git -C <raíz> pull origin main`.

**Compuerta 1.** El PR #5 mergeado con 0 archivos de pipeline tocados sobre el denominador
declarado, y `main` local al día. Si aparece **cualquier** archivo de pipeline en el PR,
**detente y reporta**: el criterio 9 de P-61 habría sido un falso verde.

---

### Fase 2 — Diagnóstico del sello, sin escribir nada

Esta fase es de solo lectura. Nada se arregla todavía.

**2.1 Cómo funciona el sello.** Lee `10_utils/10_utils.R` y `10_utils/10_configuracion.R`
completos. Responde, cada respuesta con archivo y línea:

- ¿Dónde y cómo se **escribe** el sello sobre un intermedio? (atributo, columna, archivo
  lateral, nombre de archivo: no lo asumas)
- ¿Dónde y cómo lo **lee** `validar_corte()`, y qué compara exactamente?
- ¿Qué scripts invocan a `validar_corte()` y sobre qué artefactos?

**2.2 Qué declara cada intermedio.** En R, sobre los seis `.rds` de
`40_salidas/intermedios/` (`asistencia_ambitos`, `asistencia_nominal`, `diputados`,
`proyectos_detalle`, `proyectos`, `votos`): tabla con una fila por artefacto, columnas
*sello declarado*, *mtime*, *filas*. Declara el denominador (6 de 6).

**2.3 ¿El contenido es del corte nuevo o del viejo?** Aquí está la trampa que hay que
evitar: la auditoría infirió que el contenido corresponde al refresh 2026-08-03 porque
`96 397 = 65 478 + 30 919` reconcilia. **Esa reconciliación es interna y no prueba nada
sobre la fecha**: una partición suma igual en cualquier corte. La prueba real es el
contraste **contra el artefacto publicado del corte vigente**:

- Compara los conteos derivados de `votos.rds` contra los del PR del bot ya mergeado
  (cuerpo del PR #3, reproducido en
  `50_documentacion/andamios/logs/20260806_p58_resolucion_prs_log.md`).
- Y, más decisivo, contra los **155 perfiles publicados** en `40_salidas/json/perfiles/`:
  ¿los votos, votaciones y proyectos que declaran los perfiles se derivan de estos
  intermedios, o hay filas en unos que no están en los otros? Declara numerador y
  denominador de la comparación que elijas, y di qué mide.
- Compara además contra los cortes fechados de `20_insumos/camara/`: si existe un insumo
  del 2026-08-03, ¿el intermedio se deriva de él o del anterior?

**2.4 Causa raíz.** Con lo anterior, responde: **¿cómo llegó un artefacto sellado a
desalinearse del corte?** Hipótesis a descartar o confirmar con evidencia, no por
plausibilidad:

- El workflow semanal regenera intermedios en CI y **no los commitea**, de modo que los del
  repositorio quedan siempre del último corte local. Léelo en
  `.github/workflows/refresh-semanal.yml`: ¿qué rutas commitea?
- El sello se escribe desde una variable que se resuelve antes de que `CORTE_FECHA` cambie.
- Los intermedios simplemente no se regeneraron desde el 2026-07-27 y su contenido **es**
  del corte viejo (en cuyo caso 2.3 lo mostrará).
- Otra. Si es otra, dilo.

**Compuerta 2.** Tienes: el mecanismo del sello con archivo y línea, la tabla de los 6
artefactos, el veredicto de 2.3 con su denominador, y una causa raíz **con evidencia**. Si
al terminar 2.4 no puedes sostener ninguna causa con evidencia, **detente y reporta el
diagnóstico**: no arregles a ciegas.

---

### Fase 3 — Arreglo, por regla

La bifurcación se resuelve con el resultado de 2.3, no por preferencia:

- **Contingencia A — el contenido SÍ es del corte 2026-08-03.** El defecto es el sello.
  Re-séllalo con el mecanismo real que descubriste en 2.1 (no inventes uno nuevo), y
  **arregla la causa raíz de 2.4** para que no vuelva a ocurrir en el próximo refresh.
- **Contingencia B — el contenido NO es del corte vigente.** El defecto es el dato.
  Regenera los intermedios corriendo `32`–`36` en orden (regla A34), con lo que el sello
  queda correcto por construcción. Cuenta el tiempo y el tráfico y decláralo.
- **Contingencia C — el mecanismo hace que esto sea inevitable** (por ejemplo, el workflow
  nunca commitea intermedios). Entonces el arreglo no es un valor sino una decisión de
  diseño: **no la tomes**. Aplica el arreglo mínimo que deje el proyecto corrible, deja
  registrada la decisión pendiente en el log y en el reporte final, y sigue.

Ocurra lo que ocurra: **no toques `validar_corte()` para que pase** (🔒 6).

**Compuerta 3.** Declara qué contingencia aplicaste y con qué evidencia la elegiste.

---

### Fase 4 — Verificación

1. `validar_corte()` pasa sobre los 6 intermedios, invocada tal como la invoca el pipeline.
2. **`39` corre completo y termina sin error.**
3. Los JSON regenerados por `39` se comparan contra los publicados en `40_salidas/json/`:
   155 perfiles más el índice. **`metadatos.generado` es volátil por construcción y queda
   excluido de la comparación, y la exclusión se declara en el mismo enunciado del
   resultado.** `corte_fecha` **no** es volátil y sí se compara.
4. Si aparece **cualquier** diferencia fuera de `generado`, **detente y repórtala antes de
   commitear**: significa que el arreglo cambió el dato publicado, que no es lo que este
   encargo autoriza.
5. `git -C <raíz> status` acotado a `docs/`: sin cambios. Este encargo no republica.

**Compuerta 4.** Los cinco puntos, cada uno con su cifra y su denominador.

---

### Fase 5 — Cierre

1. Commit con ruta acotada: los intermedios re-sellados o regenerados, más cualquier
   corrección de causa raíz.
2. Push a `main` autorizado para este encargo (el candado del proyecto prohíbe escrituras
   **automáticas del bot** sobre `main`, no un commit manual verificado).
3. **Log** en `50_documentacion/andamios/logs/<AAAAMMDD>_p62_sello_intermedios_log.md`:
   mecanismo del sello, tabla de los 6 artefactos, veredicto de 2.3, causa raíz,
   contingencia aplicada, verificaciones de la Fase 4, y las decisiones tomadas en
   autonomía, una línea cada una.
4. **Reporte final al chat**, compacto: qué causó el desalineamiento, qué contingencia
   aplicaste, si `39` corre, y qué quedó pendiente de decisión.

---

## 4. Criterios de éxito (contrastables)

Marca cada uno CUMPLE / NO CUMPLE con la cifra y el artefacto del que sale.

| # | Criterio | Medida |
|---|---|---|
| 1 | PR #5 mergeado sin tocar el pipeline | 0 archivos bajo `10_utils/`, `30_procesamiento/`, `docs/`, `40_salidas/`, sobre el denominador declarado del PR |
| 2 | Mecanismo del sello documentado | Archivo y línea donde se escribe y donde se lee |
| 3 | Los 6 intermedios inventariados | 6 de 6 con sello declarado y filas contadas |
| 4 | La procedencia del contenido está resuelta contra el artefacto publicado, no por reconciliación interna | Numerador y denominador declarados, con el predicado que miden |
| 5 | Causa raíz sostenida con evidencia | El log nombra el mecanismo, no una plausibilidad |
| 6 | `validar_corte()` pasa | 6 de 6 intermedios |
| 7 | `39` corre completo | Sin error, con el tiempo declarado |
| 8 | El dato publicado no cambió | 156 de 156 artefactos idénticos, excluido `metadatos.generado` |
| 9 | La compuerta no fue debilitada | `validar_corte()` sin cambios, o con cambios que la endurecen; 0 usos de `try()`/`suppressWarnings()` sobre ella |
| 10 | `docs/` intacto | `git status` acotado a `docs/` sin cambios |

---

## 5. Qué NO hace este encargo

- No republica `docs/` ni toca GitHub Pages.
- No modifica el contrato de datos ni agrega campos.
- No dispara el workflow.
- No decide si los intermedios deben versionarse: si la causa raíz es esa, se reporta.
- No aborda P-63 (nodo `Votaciones`) ni P-59 (locale): van después, por separado.
