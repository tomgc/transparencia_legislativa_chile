# Auditoría de gobernanza — P-99: qué implica que el bot versione `20_insumos/`

> **Producida en:** la corrida de detención del encargo P-99 v1 (2026-08-19), y
> re-medida íntegramente al abrir la v2. Cada cifra lleva el comando que la
> produjo, ejecutado en esta sesión.
> **Naturaleza:** medición, no relato. Andamio congelado.
> **Motivo:** la v1 del encargo fijaba `git add 20_insumos` completo. La medición
> mostró que esa decisión cambia el régimen de fallo del CI, y el hallazgo hizo
> que el titular reemplazara el encargo por una v2 con otro diseño.

---

## 1. Resumen

Tres mediciones y un hallazgo.

- **La captura del SIL está limpia** de identificadores personales: 0 en cinco
  detectores sobre 3 271 894 caracteres, con los cinco calibrados y **0 ciegos**.
- **`20_insumos/` no contiene sólo captura cruda**: `territorio/` es insumo
  estático con revisión manual declarada, lo que dispara la compuerta F0.2 de la
  v1 ("detente si aparece cualquier cosa que no sea captura cruda").
- **El hallazgo**: `git add 20_insumos` invierte el régimen de fallo. Con la
  enumeración actual sólo entra lo nombrado (falla cerrado); con el directorio
  entra todo lo no excluido (falla abierto). Y lo que hay al otro lado de esa
  línea es material que el proyecto **ya deliberó y decidió no publicar**.
- **Un argumento de la v1 era factualmente falso**, y se deja registrado.

---

## 2. Inventario de `20_insumos/`

```
$ git ls-files 20_insumos            # leído en R, conteo en el mismo bloque
total trackeado: 62
subdir
    camara     senado territorio
        57          3          2

            ext
subdir       csv gitkeep rds txt
  camara       0       1  56   0
  senado       0       1   1   1
  territorio   2       0   0   0

archivos directos en la raíz de 20_insumos/: 0
```

No trackeados:

```
$ git ls-files --others --exclude-standard 20_insumos   ->  0 archivos
$ git ls-files --others 20_insumos                      ->  2897 archivos
   subdir:  .DS_Store 1 | exploracion 2896
```

Los 2 897 están ignorados (`.gitignore:57` para `exploracion/`, `.gitignore:16`
para `.DS_Store`, ambos confirmados con `git check-ignore -v`), así que
`git add 20_insumos` **no** los tomaría. Sobre el árbol limpio de hoy:

```
$ git add --dry-run 20_insumos   ->  0 líneas, exit 0
```

**Consecuencia metodológica que conviene registrar:** cualquier prueba del cambio
hecha sobre el árbol actual daría un falso "sin diferencia". La medición válida
es un clon con señuelos o la corrida real del workflow.

---

## 3. `territorio/` no es captura cruda

Los dos CSV de `20_insumos/territorio/` son el insumo estático auditado (D5). El
pipeline **sólo los lee**:

```
$ grep -rn "territorio" 30_procesamiento/*.R 10_utils/*.R 00_run_all.R
30_procesamiento/32_extraer_diputados.R:49:  leer_csv_territorio <- function(archivo, clases) {
30_procesamiento/32_extraer_diputados.R:50:    ruta <- ruta_insumos("territorio", archivo)
```

Su regla de actualización está escrita **dos veces**: en
`32_extraer_diputados.R` ("revisa el diff antes de commitear") y en `CLAUDE.md`
("a mano y con revisión del diff cuando cambie el roster"). El generador es la
fase `gen` de `50_documentacion/andamios/medir_fuente_territorio.R`, que no se
invoca desde `00_run_all.R` ni desde el workflow.

**Riesgo hoy: inactivo.** Nada del CI escribe ahí, y el runner corre sobre
checkout fresco. **Riesgo mañana: real.** Un `git add` por directorio arrastra
también las *modificaciones* de archivos ya trackeados, así que el día que algo
escriba en `territorio/`, el bot lo commitea sin la revisión que el propio
proyecto declaró obligatoria.

---

## 4. La captura del SIL está limpia (auditoría de dato personal)

Archivo: `20_insumos/senado/20260812_tramitacion_sil_2026_tope-inf.rds`,
427 × 4 (`boletin`, `xml`, `estado`, `estado_detalle`).

```
valores de texto no-NA: 1281 | caracteres barridos: 3271894
   (estado_detalle es NA en 427/427: sin contenido que barrer)

-- BARRIDO REAL vs CALIBRACIÓN (señuelo por detector, copia EN MEMORIA) --
   correo           real=0 senuelo=1 delta=+1 DETECTA
   rut_con_puntos   real=0 senuelo=1 delta=+1 DETECTA
   rut_sin_puntos   real=0 senuelo=1 delta=+1 DETECTA
   telefono_cl      real=0 senuelo=1 delta=+1 DETECTA
   digitos_9mas     real=0 senuelo=1 delta=+1 DETECTA
   detectores ciegos: 0 de 5
```

El señuelo se inyectó en la fila 1 de la columna `xml` de una **copia en
memoria**; el archivo en disco no se tocó (`git diff --stat HEAD -- 20_insumos`
= 0 líneas). Cada detector recibió un señuelo con **su propia forma**, tras
corregir dos defectos del arnés descritos en §7.

Tres controles estructurales independientes apuntan igual:

```
   caracteres '@' en todo el corpus: 0     -> correo estructuralmente imposible
   caracteres '+' en todo el corpus: 0     -> forma +56 imposible
   corridas de dígitos: 51102 | longitud máxima: 5
   corridas de 7 a 9 dígitos (rango de RUT y teléfono): 0
   etiquetas XML distintas: 71
   etiquetas de contacto (EMAIL/FONO/TELEFONO/DIRECCION/RUT/RUN): 0
```

Lo único de persona que hay son nombres de parlamentarios en rol público:

```
   <PARLAMENTARIO>: ocurrencias 5055 | distintos 369 | con dígito 0 | con @ 0
```

Es identidad de autoridad en ejercicio de función pública, ya publicada por la
fuente y ya presente en `40_salidas/json`. No es dato personal en el sentido que
obligaría a auditoría previa.

**Verificación independiente.** Estas cifras se sometieron a un panel de cuatro
lentes con refutadores adversariales (regex chileno, estructura XML, alcance de
git, archivos olvidados). Las cuatro lentes, todas con calibración demostrada,
concordaron en cero; ningún refutador tumbó el resultado de limpieza. El panel
añadió mediciones propias: `estructura-xml` midió 0 en cinco familias sobre
54 390 nodos de texto no vacío, y también 0 en
`20260812_tramitacion_pedidos.txt` (427 líneas, todas de forma `NNNNN-NN`).

---

## 5. El hallazgo: el cambio invierte el régimen de fallo

Estado actual del paso de commit:

```
.github/workflows/refresh-semanal.yml:115
   git add 10_utils/10_configuracion.R 20_insumos/camara 40_salidas/json docs/data
```

Enumerar **falla cerrado**: un directorio nuevo con material sensible no entra
aunque nadie lo revise. Barrer el directorio **falla abierto**: entra todo lo que
nadie excluyó. Y esto es lo que queda al otro lado de esa línea — texto literal
del propio repositorio, `.gitignore:49-57`:

> Cache de exploracion de fuentes (auditoria de la sesion 16). `20_insumos/camara/`
> SI se versiona (es el insumo del pipeline, dato publico agregado). Este
> directorio es otra cosa: respuestas crudas de sondeo, que incluyen endpoints de
> padron del Senado con EMAIL y FONO nominales de los parlamentarios (157 correos
> y 53 telefonos no vacios solo en el roster vigente, medido el 2026-08-07).
> Agregar eso a un repositorio PUBLICO no es lo mismo que consultarlo en la
> fuente.

Es decir: **el proyecto ya deliberó sobre ese material y falló en contra de
publicarlo.** Hoy `git add` respeta `.gitignore`, así que la v1 no habría
publicado nada de eso. Lo que cambia es la arquitectura de la decisión: pasa de
estar sostenida por una lista de inclusión a estar sostenida por una línea de
exclusión, en un repositorio público donde el bot commitea solo cada semana.

Y el próximo ocupante de esa zona ya está declarado:

```
50_documentacion/activa/50_catalogo_fuentes_senado.md:315
  | GET /api/parlamentarios | NO USADA | ... | Fuente de padrón. |
```

**Agravante medido por el panel:** la compuerta humana que mitigaría esto es
ciega para este material. El bot abre un PR que el titular mergea, pero el diff
de un `.rds` en GitHub se ve como `Bin 275006 -> 275013 bytes | 1 file changed,
0 insertions(+), 0 deletions(-)`. Hay compuerta, y no ve la carga.

---

## 6. Un argumento de la v1 era factualmente falso

La v1 descartó la enumeración de dos rutas con dos argumentos. El segundo decía
que `20_insumos/senado` puede no existir en el runner y que `git add` sobre ruta
inexistente aborta el step. Medido:

```
$ git ls-tree -r --name-only HEAD -- 20_insumos/senado
20_insumos/senado/.gitkeep
20_insumos/senado/20260812_tramitacion_pedidos.txt
20_insumos/senado/20260812_tramitacion_sil_2026_tope-inf.rds
```

`.gitkeep` está trackeado, así que `actions/checkout@v4` materializa el
directorio en toda corrida y el `git add` no podía abortar por inexistencia. El
propio `.gitignore:46` ya razona así para otro caso ("`.gitkeep` NO se ignora:
sigue trackeado").

El primer argumento (la enumeración deja fuera al próximo origen en silencio)
**sigue en pie**, y es el que la v2 recoge derivando la lista de la declaración
que ya existe en R.

---

## 7. Lo que costó: dos defectos de mi propio arnés

Ambos producían resultados *plausibles*, que es lo peligroso.

1. **Contadores contaminados por NA.** `estado_detalle` es `NA` en 427/427, y sin
   filtrar los NA los contadores de `@` y `+` devolvían `NA` en vez de `0`. Un
   `NA` se lee como "no medido"; peor, podría haberse reportado como cero.
   **Fix:** filtrar `is.na()` antes de contar.
2. **Un señuelo que no ejercitaba su detector.** El señuelo de RUT llevaba puntos
   (`11.111.111-1`), así que el detector `rut_sin_puntos` marcó CIEGO — no porque
   el patrón estuviera roto, sino porque nada con su forma se le puso delante.
   **Fix:** un señuelo con la forma propia de cada detector. Pasó de 1 ciego de 5
   a **0 de 5**.

**Regla aprendida:** un control de calibración no basta con existir; tiene que
ejercitar *cada* detector con la forma que ese detector busca. Un panel con
"calibración OK" y un detector ciego adentro reporta un cero que no vale.

---

## 8. Pendientes que esta auditoría deja abiertos

*(Sin numerar como P-NN: la numeración la asigna el asistente en el cierre.)*

- **`territorio/` y el bot.** Autorizar o no que el bot commitee automáticamente
  modificaciones de un insumo cuya gobernanza declarada exige revisión humana del
  diff. Hoy inactivo, mañana no.
- **La compuerta del PR es ciega para `.rds`.** El único gate del CI es
  `diff_conteos_json`, que compara conteos y no contenido. Si se acepta que el
  bot versione binarios opacos cada semana, conviene una compuerta de contenido.
- **`<RUT/>` y `<RUTDV/>` en las capturas de la Cámara.** El panel midió 1 395
  pares (155 × 9 cortes), **todos vacíos** hoy. Es condición **preexistente** y
  ajena a P-99 (esos archivos ya los commitea el bot desde julio), pero nada
  avisaría si la API empezara a poblarlos. Punto ciego instrumental asociado: el
  regex clásico de RUT exige guion y dígito verificador, y sería ciego a la forma
  `<RUT>12345678</RUT>`.
- **Discrepancia no arbitrada.** Tres lentes del panel midieron el volumen de
  `20_insumos/exploracion/` y dieron tres cifras incompatibles de correos
  (1 138 / 1 088 / 412 ocurrencias). Las tres están calibradas y ninguna explica
  la diferencia de las otras. El hallazgo que dependía de esa cifra fue refutado
  por otras razones, así que no cambia ningún veredicto, pero **ninguna de las
  tres debe citarse como establecida**. La cifra que sí es firme es la del propio
  `.gitignore`: 157 correos y 53 teléfonos, medidos por el proyecto el 2026-08-07.

---

## 9. Estado de los datos al cerrar la auditoría

| Objeto | Medición | Estado |
|---|---|---|
| `20_insumos/` | `git diff --stat HEAD -- 20_insumos` = 0 líneas | **Intacto** |
| Captura del SIL | leída con `readRDS`, señuelos sólo en copia en memoria | **Sin tocar** |
| Árbol | `git status --porcelain` = 0 líneas | **Limpio** |
| Worktrees | `git worktree list` = 1 línea | **Limpio** |

Ninguna captura se movió ni se borró en esta auditoría: fue lectura pura.

---

## 10. Notas para el revisor

1. **La conclusión de limpieza del SIL no autoriza el cambio.** La captura está
   limpia, así que la calificación del riesgo **no puede apoyarse en su
   contenido**: lo que se decide es el régimen, no el archivo.
2. **La comparación de opciones que la v1 presentó estaba viciada** por el
   argumento falso de §6. Cualquier decisión tomada sobre esa base merece
   revisarse.
3. **Mis dos defectos de arnés (§7) los detecté por contradicciones internas de
   la salida**, no por diseño. Si algo aquí parece raro, el primer sospechoso
   debería ser el arnés que lo produjo.
