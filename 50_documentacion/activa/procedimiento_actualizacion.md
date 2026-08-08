# Procedimiento de actualización semanal

Cómo refrescar el corpus publicado a un corte temporal nuevo. Manual, en
Positron. El pipeline NO se auto-actualiza: el corte es explícito
(`CORTE_FECHA`) para que cada refresh sea reproducible y auditable, sin drift
silencioso (la API de la Cámara crece día a día).

## Concepto: el corte temporal (`CORTE_FECHA`)

`CORTE_FECHA` (en `10_utils/10_configuracion.R`, formato `AAAA-MM-DD`) es la
fecha "as-of" del refresh. La clave de caché (`con_cache`) la usa **en vez de
`Sys.Date()`**, así que:

- Dos corridas con el **mismo** `CORTE_FECHA` reutilizan el snapshot (cache-hit),
  sin re-descargar ni cambiar conteos — reproducible entre días.
- Cambiar `CORTE_FECHA` a un corte **nuevo** genera claves nuevas → el pipeline
  re-descarga el corpus de ese corte (refresh real, controlado).

La clave codifica además el tope de extracción (`sufijo_tope`), así que un
snapshot queda identificado por `<CORTE>_<fuente>_<tope>.rds`.

## Procedimiento (semanal, manual en Positron)

1. **Respaldar el JSON vigente** (para el diff del paso 4). Copiar el directorio
   de salida actual a una ubicación temporal, p. ej. en R:
   ```r
   fs::dir_copy(here::here("40_salidas", "json"),
                here::here("40_salidas", "_json_previo"), overwrite = TRUE)
   ```

2. **Fijar el corte nuevo.** Editar `CORTE_FECHA` en
   `10_utils/10_configuracion.R` a la fecha del corte de esta semana
   (`AAAA-MM-DD`). Es el único cambio manual del refresh.

3. **Correr el pipeline completo.**
   ```r
   source(here::here("00_run_all.R"))
   run_all()
   ```
   Como el corte es nuevo, `con_cache` no encuentra snapshots previos de ese
   corte y re-descarga (roster, asistencia, votaciones, proyectos, detalle) —
   varios minutos. Si `CORTE_FECHA` no está fijada, `run_all()` se detiene al
   inicio con mensaje claro (nunca a mitad de corrida).

4. **Verificación programática de conteos ANTES de publicar.** Correr el script
   de diff comparando el JSON anterior (respaldo del paso 1) contra el nuevo:
   ```r
   source(here::here("10_utils", "10_diff_conteos.R"))
   diff_conteos_json(here::here("40_salidas", "_json_previo"),
                     here::here("40_salidas", "json"))
   ```
   (o standalone desde la terminal:
   `Rscript 10_utils/10_diff_conteos.R 40_salidas/_json_previo 40_salidas/json`).
   Imprime a consola el diff de los totales clave (perfiles, votaciones,
   mociones, split con/sin proyecto). **Revisar el diff antes de continuar:** un
   crecimiento moderado es esperado (la API acumula datos); un salto anómalo o
   una caída (perfiles < 155, votaciones que bajan) es señal de problema — NO
   publicar, investigar. `39` ya copia el JSON a `docs/data/` al final; el diff
   es el gate de sanidad previo a versionar.

5. **Commit atómico con el corte en el mensaje.**
   ```
   data: refresh corte AAAA-MM-DD
   ```
   Incluir el resumen del diff (conteos nuevos vs previos) en el cuerpo del
   commit. Borrar el respaldo `40_salidas/_json_previo` (no se versiona).

## Verificación de reproducibilidad (cualquier día, sin refrescar)

Para confirmar que el corpus publicado se regenera idéntico desde los
intermedios congelados (sin re-descargar), con el `CORTE_FECHA` vigente:
```r
source(here::here("00_run_all.R")); run_all(only = 39)
```
Debe reproducir los 155 perfiles idénticos salvo el timestamp `generado`.

### Después de mergear un refresh del bot, el orquestador se realinea solo (P-65)

Los intermedios de `40_salidas/intermedios/` **no se versionan** (`.gitignore`), y
el workflow commitea `10_utils/10_configuracion.R`, `20_insumos/camara`,
`40_salidas/json` y `docs/data` — **no los intermedios**. Al mergear un refresh,
`CORTE_FECHA` avanza en tu árbol pero los `.rds` locales siguen sellados con el
corte de tu última corrida local (diagnóstico de P-62).

**Desde P-65 no hay paso manual que recordar.** `run_all()` — en cualquiera de sus
formas, incluida `run_all(only = 39)` — pasa por una guarda
(`regenerar_intermedios_si_desalineados()`, invocada en `00_run_all.R`) que compara
el sello de los 6 intermedios contra `CORTE_FECHA` y, si detecta el desfase,
**regenera los pasos 32–36 antes de seguir**, anunciándolo por consola:

```
[guarda_intermedios] [WARN] Intermedios desalineados con el corte vigente (AAAA-MM-DD): 6 de 6.
[guarda_intermedios] [WARN] Regenerando los pasos 32, 33, 34, 35, 36 desde la captura
                            cruda del corte AAAA-MM-DD (cache hit, sin red).
```

Con los sellos alineados no hace nada ni imprime: es idempotente.

**No genera tráfico.** La captura cruda del corte vigente sí viene commiteada en
`20_insumos/camara/`, así que los cinco extractores dan *cache hit* (medido en
P-65: **6 de 6 cache hit, 0 llamadas a la API, ~1 s**). La guarda fuerza el caché
durante esa regeneración aunque `camara.refrescar` esté en `TRUE`.

**Cuándo falla ruidosamente, y qué hacer entonces.** Si los intermedios están
desalineados **y** falta la captura cruda de ese corte en `20_insumos/camara/`, la
guarda **no descarga por su cuenta**: se detiene con `stop()` nombrando los
archivos que faltan y los `source()` exactos a correr con red. Correrlos y
reintentar `run_all()` es todo el procedimiento.

**Sigue sin resolverse tocando `CORTE_FECHA` ni relajando `validar_corte()`.** La
guarda actúa **aguas arriba** de esa compuerta, que queda intacta: invocar el `39`
suelto (`source("30_procesamiento/39_consolidar_json.R")`) con intermedios
desalineados sigue fallando, y eso es correcto.

---

## Automatización con GitHub Actions (OPERATIVA desde 2026-07-10)

> El workflow **existe y corre**: `.github/workflows/refresh-semanal.yml`. Ese
> archivo es la fuente de verdad; lo de aquí abajo es su descripción. Hasta P-65
> esta sección seguía rotulada *"Pendiente 2 — NO EJECUTAR AÚN"* y describía como
> pseudocódigo un workflow que llevaba un mes en producción.

El mismo pipeline R, disparado por `cron`, donde lo ÚNICO que la automatización
aporta es **calcular el corte** (la fecha de hoy) e inyectarlo como `CORTE_FECHA`;
todo lo demás (extracción, consolidación, publicación a `docs/`) es el `run_all()`
ya existente.

| Qué | Cómo, en el workflow real |
|---|---|
| **Disparadores** | `cron: "0 11 * * 1"` (lunes 11:00 UTC = 07:00 en Chile todo el año) y `workflow_dispatch` manual |
| **Corte** | `CORTE=$(date +%Y-%m-%d)`, inyectado con `sed` sobre la única línea `^CORTE_FECHA <- ` de `10_utils/10_configuracion.R` |
| **Pipeline** | `Rscript -e 'source("00_run_all.R"); run_all()'` |
| **Gate de conteos** | `10_utils/10_diff_conteos.R` contra el JSON del checkout (copiado a `runner.temp` antes de correr). Si `gate == "FAIL"`, `quit(status = 1)`: el job muere **sin rama ni PR** |
| **Publicación** | El bot **no escribe en `main`** (P-22): commitea en `refresh/<corte>` (`git add` acotado a `10_utils/10_configuracion.R`, `20_insumos/camara`, `40_salidas/json`, `docs/data`) y abre un PR con `gh pr create`. El titular lo revisa y mergea a mano |
| **Pages** | Republica `docs/` **al mergear el PR**, no al terminar el job |
| **Credenciales** | `GITHUB_TOKEN` automático (`contents: write`, `pull-requests: write`). Sin PAT |

Diferencia con el modo manual: en Actions el corte se **calcula** en vez de
editarse a mano, y el gate de conteos puede abortar la publicación. Consecuencia
para tu copia local: el merge de ese PR mueve `CORTE_FECHA` pero **no** los
intermedios, que están gitignored — el desfase que la guarda de P-65 resuelve sola
(ver la sección anterior).
