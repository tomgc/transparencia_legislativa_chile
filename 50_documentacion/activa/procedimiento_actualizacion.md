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

---

## Pendiente 2 — Automatización con GitHub Actions (NO EJECUTAR AÚN)

> **Esqueleto ilustrativo, no operativo.** No crear el `.yml` todavía: depende de
> que exista un repositorio remoto (pendiente 2 del traspaso, fuera de este
> encargo). Se documenta aquí solo para fijar la forma que tendría.

La idea: el mismo pipeline R, disparado por un `cron`, donde lo ÚNICO que la
automatización aporta es **calcular el corte** (la fecha de hoy) y pasarlo como
`CORTE_FECHA`; todo lo demás (extracción, consolidación, publicación a `docs/`)
es el `run_all()` ya existente.

Pseudocódigo del workflow (prosa, no archivo real):

```
# .github/workflows/refresh-semanal.yml  (NO CREAR AUN — pendiente 2)
nombre: refresh semanal del corpus
disparadores:
  - cron: "0 12 * * 1"        # lunes 12:00 UTC (semanal)
  - manual (workflow_dispatch) # para correr a demanda

trabajo refrescar:
  runs-on: ubuntu-latest
  pasos:
    1. checkout del repo
    2. instalar R + paquetes (httr, xml2, dplyr, jsonlite, fs, here, rprojroot)
    3. calcular el corte:
         CORTE=$(date +%Y-%m-%d)
         # inyectarlo en 10_configuracion.R (sed) o exponerlo como variable de
         # entorno que el script lea; el corte es el UNICO parametro que cambia.
    4. correr el pipeline:
         Rscript -e 'source("00_run_all.R"); run_all()'
    5. verificacion de conteos (gate): correr 10_diff_conteos.R contra el
         JSON del commit anterior (git show HEAD:... a un tmp) y fallar el job
         si el diff supera un umbral sospechoso (caida de perfiles, etc.).
    6. commit + push del refresh:
         git commit -m "data: refresh corte $CORTE" && git push
         # (requiere remoto + token con permisos de escritura — pendiente 2)
    7. (GitHub Pages publica docs/ automaticamente al mergear a main)
```

Diferencia clave con el modo manual: en Actions el corte se **calcula**
(`date`) en vez de editarse a mano; el resto es idéntico. La verificación de
conteos (paso 5) es el mismo `10_diff_conteos.R`, aquí como compuerta que puede
abortar el push si algo se ve mal. Nada de esto se implementa hasta que exista
el remoto (pendiente 2).
