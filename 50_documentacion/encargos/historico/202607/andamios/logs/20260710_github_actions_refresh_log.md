# Log de ejecución — Workflow de GitHub Actions para refresh semanal

**Fecha:** 2026-07-10
**Rama:** `feature/github-actions-refresh` (desde `main` ad7ca07; sin push, sin merge).
**Entorno:** Claude Code, macOS, R 4.5.2.
**Naturaleza:** andamio congelado (registro de ejecución, no se actualiza).

## 1. Resumen

Materializa el esqueleto ya documentado (procedimiento_actualizacion.md, pendiente 2)
en un workflow real: `.github/workflows/refresh-semanal.yml`. El YAML solo orquesta;
la lógica vive en R. Lo único que la automatización aporta es **calcular el corte**
(`date +%Y-%m-%d`) e inyectarlo en `CORTE_FECHA` vía `sed`; el resto es el `run_all()`
existente. Antes de publicar, un **gate** corre `10_diff_conteos.R` contra el JSON del
commit previo (copiado del checkout de HEAD, no un respaldo local) y **aborta el job**
(`quit(status=1)`, sin commit ni push) si `perfiles < 155` o si cae cualquier métrica
acumulativa. El push usa el `GITHUB_TOKEN` automático (sin PAT). Dos commits atómicos.
El workflow se probó localmente de punta a punta con un corte nuevo (refresh real, no
cache-hit) y el gate se validó en AMBOS sentidos. Producción intacta: único cambio de
la rama es el `.yml` + el enriquecimiento de `10_diff_conteos.R`; los datos quedaron
en el corte congelado 2026-07-06.

## 2. Inventario de commits

| Fase | Hash | Tipo | Título |
|------|------|------|--------|
| 1 | `07a2852` | feat | diff_conteos_json expone resultado programatico para gate CI |
| 2 | `c950e5b` | feat | workflow de GitHub Actions para refresh semanal |

No hubo `fix:` post-prueba: el YAML pasó la validación local sin necesitar ajustes
(el único retoque, cambiar un guión largo por ASCII, fue previo a la simulación).

## 3. Detalle por cambio

### 3.1 Gate programático en `10_diff_conteos.R` (Fase 1)
- El diff solo imprimía una tabla y devolvía un data.frame invisible; el gate de CI
  necesita una señal pasa/falla programática.
- Se añadió `METRICAS_GATE <- c("perfiles","votaciones","mociones","votos_con_proyecto")`
  y se cambió el retorno de `diff_conteos_json()` a
  `invisible(list(conteos=<df>, gate="OK"/"FAIL", motivos=<character>))`, con parámetro
  `piso_perfiles = 155L`. Política del gate: FAIL si `perfiles_B < piso` o si cualquier
  `METRICAS_GATE` cae (B < A). `votos_sin_proyecto` se reporta pero NO gatea (una caída
  ahí es mejora: más votos trazados a su proyecto).
- Comportamiento standalone (`Rscript ... <A> <B>`) sin cambios: imprime la misma tabla.

### 3.2 Workflow `.github/workflows/refresh-semanal.yml` (Fase 2)
Disparadores: `cron: "0 11 * * 1"` (lunes 11:00 UTC = 07:00 CLT / 08:00 CLST en Chile;
el cron de Actions es siempre UTC y no ajusta por horario de verano) + `workflow_dispatch`
(a demanda). `permissions: contents: write` (para que el `GITHUB_TOKEN` automático pueda
pushear). Job `refresh` en `ubuntu-latest`, pasos:
1. `actions/checkout@v4`.
2. `r-lib/actions/setup-r@v2` (`use-public-rspm: true` → binarios, instalación rápida).
3. `install.packages(c("dplyr","jsonlite","here","fs","httr","xml2","rprojroot"))`.
4. **Corte + previo + sed:** `CORTE=$(date +%Y-%m-%d)` → `$GITHUB_ENV`; `cp -r 40_salidas/json`
   a `$RUNNER_TEMP/json_previo` (JSON "anterior" = el del checkout de HEAD, ANTES de que
   `run_all` lo sobrescriba); `sed -i "s/^CORTE_FECHA <- .*/.../"` (ancla `^CORTE_FECHA`,
   los comentarios que mencionan la constante empiezan con `#` y no matchean).
5. `Rscript -e 'source("00_run_all.R"); run_all()'`.
6. **Gate:** `capture.output(r <- diff_conteos_json(json_previo, "40_salidas/json"))`
   imprime la tabla, la guarda para el cuerpo del commit, y `if (r$gate=="FAIL") quit(status=1)`
   → step en rojo, job abortado sin commit ni push.
7. **Commit + push:** `git add 10_configuracion.R 20_insumos/camara 40_salidas/json docs/data`;
   si no hay cambios, `exit 0` (no-op); si los hay, commit
   `data: refresh corte AAAA-MM-DD (automatizado)` con el resumen del diff en el cuerpo, y `git push`.

## 4. Bugs

Ninguno en el código entregado. Incidencias de la sesión de prueba (no del entregable):
- El escape `\.` dentro de `Rscript -e '...'` en zsh vuelve a dar "unrecognized escape";
  se evitó usando `[.]` en las regex de verificación y escribiendo el chequeo a archivo.
- `$?` tras un pipe (`Rscript ... | grep`) mide el exit de `grep`, no de `Rscript`;
  el exit real del gate se confirmó redirigiendo a `/dev/null` sin pipe (ver §7).

## 5. Verificación de invariantes (🔒)

| Invariante | Estado | Evidencia |
|-----------|--------|-----------|
| R único lenguaje (pipeline + verificación) | PASA | pipeline, gate y validación YAML (parser `yaml` de R) todo en R; 0 Python |
| El navegador no ejecuta R ni llama APIs | PASA | el workflow corre en el runner; el cliente sigue leyendo JSON estático |
| Llaves de identificación character | PASA | no se tocaron tipos de llave |
| Corte inyectado por sed sobre 10_configuracion.R | PASA | step 4 del workflow; ancla `^CORTE_FECHA <- ` matchea solo la línea 41 |
| Push con GITHUB_TOKEN automático, sin PAT | PASA | 0 `${{ secrets... }}`; "PAT" solo aparece en comentarios que dicen que NO se usa |
| Gate aborta ante caída (perfiles<155 o cualquier baja) | PASA | caída simulada → exit 1 (§7) |
| JSON previo del commit anterior (no respaldo local) | PASA | `cp -r 40_salidas/json` del checkout de HEAD a `$RUNNER_TEMP`, antes de run_all |
| No tocar docs/index.html (grep red = 0) | PASA | `docs/index.html` no aparece en el workflow ni se modificó |
| Rama nueva, no main; sin push ni merge | PASA | `feature/github-actions-refresh`; 2 commits locales; merge = gate del titular |

## 6. Decisiones de diseño y su porqué

- **JSON "anterior" = copia del checkout de HEAD** (`cp -r 40_salidas/json` a tmp ANTES de
  run_all), no `git show HEAD:...` fichero-a-fichero. En un checkout fresco el árbol de
  trabajo ES HEAD, así que la copia es exactamente "el JSON del commit previo"; es más
  simple y robusto que 155 `git show` y respeta el invariante (no es un respaldo local
  persistente, se deriva del checkout).
- **`cron: "0 11 * * 1"`**: temprano el lunes en Chile todo el año sin depender del DST
  (11:00 UTC = 07:00 en invierno CLT / 08:00 en verano CLST). El cron de Actions es UTC fijo.
- **Instalar paquetes con `install.packages` sobre RSPM** (no `setup-r-dependencies`):
  el proyecto no tiene DESCRIPTION; la lista explícita de 7 paquetes es directa y usa
  binarios. `instalar_si_falta` del pipeline los encuentra ya instalados y no reinstala.
- **`if git diff --cached --quiet; then exit 0`**: si un refresh no cambió nada (corte
  con corpus idéntico), el job no falla ni crea un commit vacío.

## 7. Auto-auditoría (ejecución real, no de memoria)

Prueba local de punta a punta sobre la rama, con corte nuevo **2026-07-10** (≠ 2026-07-06
→ fuerza re-descarga, refresh real):

- **Secuencia central completa sin error:** `run_all()` con el corte inyectado corrió los
  6 pasos, re-descargó (nuevos snapshots `20260710_*`), 289.9s, 155 perfiles. PASA.
- **Gate, caso OK (crecimiento real 06→10-jul):** votaciones 77952→84927 (+6975),
  mociones 1233→1311 (+78), votos_con_proyecto 52148→56953 (+4805); `gate=OK`,
  **exit code real 0** → el job seguiría al commit/push. PASA.
- **Gate, caso FAIL (caída simulada 155→150 perfiles):** el comando exacto del step gate
  reportó `perfiles 150 < piso 155` + caídas de votaciones/mociones/votos_con_proyecto;
  `gate=FAIL`, **exit code real 1** → el job aborta ANTES del commit/push. PASA.
- **Sin residuos de datos:** tras revertir (checkout de config+json+docs/data, restaurar
  intermedios congelados, borrar los 5 snapshots `20260710_*`), `git status` = solo
  `.github/`; `run_all(only=39)` desde los intermedios restaurados reprodujo el corpus
  congelado EXACTO (diff de conteos vs JSON congelado = 0 en las 5 métricas). PASA.
- **Validación YAML:** el parser `yaml` de R parsea el archivo sin error (sintaxis válida;
  nota: YAML 1.1 coacciona `on:`→TRUE, GitHub lo parsea bien); chequeo estructural sobre
  el texto crudo (name/on/cron/workflow_dispatch/permissions/checkout/setup-r/run_all/gate/
  quit/sed/push) todo PASA; archivo ASCII puro. PASA.

## 8. Cómo probar en producción la primera vez (para el titular)

El archivo `.yml` puede existir en la rama sin disparar nada: los workflows con `schedule`
solo corren desde la rama por defecto (`main`), así que en `feature/github-actions-refresh`
el cron NO se activa. Una vez mergeado a `main`:

1. **NO esperar al cron.** Ir a la pestaña **Actions** del repo en GitHub →
   "refresh semanal del corpus" → **"Run workflow"** (usa `workflow_dispatch`) sobre `main`.
2. Revisar el log del job. En el step **"Gate de conteos"** debe verse la tabla de diff y
   `### GATE OK -> se publica ###` (o, si algo cayó, `### GATE FALLIDO -> NO se publica ###`
   y el job en rojo sin commit — que es el comportamiento correcto).
3. Si el gate pasó, el step **"Commit y push"** deja un commit
   `data: refresh corte AAAA-MM-DD (automatizado)` en `main` y GitHub Pages republica `docs/`.
4. Solo tras ver un `workflow_dispatch` manual verde de punta a punta, confiar en el cron
   semanal (lunes 11:00 UTC).

**Requisito remoto:** el push del bot exige que `main` acepte el push del `GITHUB_TOKEN`.
Si `main` tuviera protección de rama que bloquee pushes directos, habría que permitir a
`github-actions[bot]` (o ajustar la protección); con el repo sin esa protección, el
`GITHUB_TOKEN` con `contents: write` basta.

## 9. Pendientes abiertos / # REVISAR

- **Merge a main:** este encargo deja la rama lista pero NO la mergea (es el gate del
  titular). El cron solo se activa tras el merge a `main`.
- **Primer refresh real en la nube:** la prueba local demostró el mecanismo; el primer
  `workflow_dispatch` en GitHub es la validación in situ (§8).
- **Diff por totales, no por-diputado** (heredado de `10_diff_conteos.R`): un cambio
  compensado (uno sube, otro baja, mismo total) no lo detectaría; suficiente para sanidad
  global pre-publicación.
- **Acumulación de snapshots:** cada refresh a un corte nuevo agrega snapshots
  `<CORTE>_*.rds` a `20_insumos/camara` (provenance, Rama A). Si el repo creciera mucho,
  archivar cortes viejos sería una mejora futura (fuera de alcance).
