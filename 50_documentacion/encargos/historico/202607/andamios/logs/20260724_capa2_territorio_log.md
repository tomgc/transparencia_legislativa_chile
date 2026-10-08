# Capa 2 — Territorio: construcción. Log de cierre

**Fecha:** 2026-07-24 · **Rama:** `feat/territorio-crosswalk` · **CORTE_FECHA:** 2026-07-20
**Modo:** encargo autónomo, un turno. Sin push, sin PR. Todo en R (🔒 A31).

---

## 1. Resumen

`distrito` y `region` dejan de ser `NA` en el portal. Los 155 diputados del período
vigente quedan con territorio poblado y auditado, por **join determinista contra un
insumo estático versionado**, no por scraping en cada refresh (decisión D5).

Cierra el `# REVISAR` que el paso `32` arrastraba desde la sesión 1
("Distrito y region NO los expone la API → NA").

| Antes | Después |
|---|---|
| 0/155 con distrito | **155/155** |
| 0/155 con región | **155/155** |
| El frontend mostraba "Sin dato" en 155/155 | Muestra distrito y región reales |

---

## 2. Inventario de commits

| Hash | Commit |
|---|---|
| `0f93cb5` | `feat: insumo territorial estatico (crosswalk diputado-distrito + catalogo distrito-region)` |
| `a03be0a` | `feat: el 32 puebla distrito/region por join contra el crosswalk (cierra # REVISAR)` |
| `8c0ba3a` | `refactor: el andamio de medicion queda como generador del insumo territorial` |

Antecedente en la misma rama: `efb479e` (medición y veredicto de la fuente, 2026-07-24).

**Sin push.** Los tres commits son locales; el merge a `main` es gate del titular.

---

## 3. Verificación de los supuestos de entrada (T1–T3)

| # | Supuesto | Resultado |
|---|---|---|
| T1 | `medicion_territorio_155.rds` con los 155 y la regla de los 4 aplicada | ✅ 155 filas, 155 con distrito, estado `ok` en los 155; los 4 colisionados en 13/4/24/11 |
| T2 | 28 distritos, suma 155, ninguno fuera de 1–28 | ✅ 28 distritos, suma 155, rango 1–28, 0 fuera |
| T3 | `32` deja territorio en `NA`; `39` solo propaga | ✅ confirmado leyendo ambos: `32` L63-65 `NA_character_`; `39` L134-135 (índice) y L169-170 (perfiles) sin transformación |

**Un dato del encargo que no cuadró con la fuente:** el encargo pedía verificar que
el id 1017 (Álvaro Carter) mostrara **distrito 20**. La fuente dice **12**, tanto en
`medicion_territorio_155.rds` como en la ficha BCN cruda ("Distrito Nº 12, que
comprende las comunas de La Florida, La Pintana, Pirque, Puente Alto"). El D20 es
Biobío; Carter es RM. Se usó el dato de la fuente, **no se ajustó nada para calzar
con el encargo**, y se reportó al titular en el momento.

---

## 4. Cambios sustantivos, con causa raíz

### 4.1 Insumo estático (`20_insumos/territorio/`)

**`20260724_crosswalk_distrito_diputado.csv`** — 155 filas.
`diputado_id` (character), `distrito` (integer 1–28), `bcn_persona_id`,
`capturado_el`, `fuente`. Cabecera con procedencia y con la regla de desambiguación.

**Causa raíz de que sea un archivo y no una consulta:** la ficha de BCN es HTML sin
contrato de datos. Ya hoy escribe el ordinal de tres formas distintas
(`13er Distrito`, `4° Distrito` con U+00B0, `24º Distrito` con U+00BA). Un cambio de
plantilla rompería el refresh semanal en silencio. Congelarlo y auditarlo es lo que
D5 pedía.

**`catalogo_distrito_region.csv`** — 28 filas, construido contra la Ley 20.840, con
la Región de Ñuble en el D19 (Ley 21.033, 2018). **No se derivó de la prosa de la
ficha BCN**: un catálogo derivado del trazado histórico habría puesto el D19 en
Biobío.

### 4.2 Join en `32_extraer_diputados.R`

Se eliminan los dos `NA_character_` hardcodeados y entran dos `left_join`:
por `diputado_id` (character) contra el crosswalk, y por `distrito` (integer)
contra el catálogo.

**Validación ruidosa (C.8):** si el roster incorpora un reemplazo que el crosswalk
no cubre, el paso hace `stop()` **nombrando el `diputado_id` culpable** e indicando
cómo regenerar el insumo. También valida rango 1–28, duplicados en ambos insumos y
cobertura de región. El territorio nunca degrada a `NA` en silencio ni se fabrica.

**`39` no se tocó.** Ya propagaba ambas columnas sin transformarlas.

### 4.3 Un bug de encoding encontrado y corregido durante la construcción

La primera versión del catálogo salió corrupta: el archivo contenía la cadena
literal `Regi<c3><b3>n de <c3><91>uble` (29 caracteres ASCII) en vez de
`Región de Ñuble` (15 caracteres, 17 bytes).

**Causa raíz:** el script generador se ejecutó con `LC_CTYPE=C`, y bajo ese locale
R convierte los literales no-ASCII del propio código fuente a su forma escapada al
parsearlo. El archivo escrito era "UTF-8 válido" — por eso `validUTF8()` daba
`TRUE` — pero su contenido era el texto de los escapes, no los caracteres.

**Corrección doble:**
1. El generador se corre con `LC_ALL=en_US.UTF-8`.
2. `32` marca explícitamente como UTF-8 las columnas de texto que lee del CSV
   (`Encoding(d[[col]]) <- "UTF-8"`). Bajo un locale UTF-8 es no-op; bajo locale C
   evita que el `enc2utf8()` del `39` reinterprete los bytes y rompa las tildes y
   la ñ. Sin esto, el pipeline sería correcto en Positron y estaría roto en CI.

**Lección:** `validUTF8()` sobre el archivo no prueba que el contenido sea el
esperado. La comprobación que sí discrimina es `nchar()` vs bytes.

---

## 5. Verificación de invariantes (sobre el JSON publicado, recontado)

| Invariante | Medido |
|---|---|
| Cobertura territorial | **155/155** con `distrito` y `region` no nulos |
| Suma de escaños | **155** |
| Distritos distintos | **28** (rango 1–28, sin huecos) |
| Regiones distintas | **16** |
| Magnitudes por distrito | 3–8 |
| Tipo de `distrito` en JSON | `integer` (el frontend ya hacía `String(r.distrito)`) |
| Tipo de `region` | `character`, acentos correctos |
| Los 4 colisionados | 1159→13, 1175→4, 1209→24, 1252→11 — la persona **vigente**, no la histórica |
| Carter (1017) | distrito 12, Región Metropolitana de Santiago |
| Sello de corte | `39` validó 5 intermedios al corte **2026-07-20** |

**Sobre A34:** los intermedios locales estaban sellados a 2026-07-10 contra un
`CORTE_FECHA` de 2026-07-20. La compuerta habría fallado. Se corrió
`run_all(from = 32)`: los 5 cachés del corte vigente ya estaban en local, así que
32–36 resolvieron por cache hit (sin llamadas a la API) y `39` validó procedencia
antes de consolidar.

---

## 6. Panel adversarial

Panel de solo lectura, con código propio, sin `source()` del pipeline y sin usar
los `.rds` intermedios como fuente de verdad.

| Verificación | Veredicto |
|---|---|
| 1. Escaños recontados desde el CSV crudo | **CUADRA** — 155 filas, 0 duplicados, 28 distritos, suma 155 |
| 2. Índice vs 155 perfiles del JSON publicado | **CUADRA** — 155/155 idénticos en distrito y en región, 0 discrepancias |
| 3. Los 4 colisionados contra la ficha BCN cruda | **CUADRA 4/4** |
| 4. Catálogo distrito→región contra la ley electoral | **CUADRA** — incluido el D19 (Ñuble) y los 7 distritos de la RM |

**Veredicto global del panel: nada que detenga el commit.** Contrastes extra que
hizo por su cuenta: CSV→JSON 155/155 y catálogo→JSON 155/155, sin drift.

El panel levantó dos observaciones, ambas atendidas:

1. **Robustez del parser ante `°` (U+00B0) vs `º` (U+00BA).** Se verificó
   empíricamente: el parser normaliza con `iconv(..., to = "ASCII", sub = " ")`
   **antes** de casar la regex, así que ambos codepoints colapsan al mismo espacio
   y las tres formas de ordinal resuelven igual. Probado con las cuatro variantes.
   **No era un defecto**; sí lo sería en un parser que nombrara el carácter.
2. **La regla de desambiguación solo era auditable a medias.** Correcto: estaban
   versionadas las fichas de las personas elegidas, no las de las descartadas. Se
   añadieron las 4 fichas descartadas y se comprobó la **exclusividad** de la
   regla: ninguna de las históricas tiene fila del período 2026-2030, y la de 1175
   devuelve HTTP 404.

---

## 7. Pendientes

- **Reemplazos dentro del período.** Si entra un reemplazante, `32` fallará
  ruidosamente con su `diputado_id`; la corrección es correr la fase `gen` del
  andamio y revisar el diff del CSV. **Sigue sin verificarse** el supuesto de D5 de
  que un reemplazante hereda el distrito de quien reemplaza — el flujo actual no lo
  asume: va a la fuente.
- **RUT como llave sin uso.** La API de la Cámara expone `RUT`/`RUTDV` por
  diputado. Es una llave nacional inequívoca que hoy no se usa en ningún cruce y
  que sería la vía natural para cualquier fuente futura (SERVEL, declaraciones de
  patrimonio) que no conozca el id de la Cámara.
- **Región en el frontend.** El filtro por región de `docs/index.html` tenía un
  mensaje de vacío que dice que "el dato de región/distrito aún no está disponible
  en la fuente" (L778). Ya no aplica: conviene revisarlo. No se tocó en este
  encargo por estar fuera de alcance.
- **`# REVISAR` que persisten en el proyecto** (ajenos al territorio): estado de
  tramitación de proyectos (`NA`, proxy `admisible`) y rol autor/coautor
  (`Orden=0` para todos los firmantes).

---

## 8. Qué queda para el titular

1. **Revisar y decidir el merge de `feat/territorio-crosswalk` a `main`.** Tres
   commits de construcción más el de la medición. Sin push.
2. **Decidir si la Capa 2 incluye el ajuste del copy del frontend** (punto 3 de
   §7) o si va aparte.
3. **Confirmar la elección de tipo de `distrito` como `integer` en el JSON.** Se
   siguió el encargo; el 🔒 invariante 4 aplica a llaves de identificación y
   `distrito` es atributo, no llave de join. El frontend ya lo coercía con
   `String()`, así que funciona en ambos casos.

---

## 9. Errores del asistente en esta sesión (POLITICA 0.5)

1. **Escritura del catálogo corrupta por locale.** Se generó el CSV con literales
   acentuados bajo `LC_CTYPE=C` y el archivo quedó con los escapes como texto.
   Se detectó porque `nchar()` daba 29 donde debía dar 15 — no porque el archivo
   pareciera inválido (`validUTF8()` decía `TRUE`). **Regla:** verificar contenido
   con `nchar()` vs bytes, no con `validUTF8()`.
2. **Diagnóstico del encoding perseguido en el lugar equivocado.** Se gastaron
   varias iteraciones probando `Encoding<-`, `iconv`, `readr` y cambios de locale
   sobre la **lectura**, cuando el defecto estaba en la **escritura**. La pista que
   lo resolvió (29 caracteres ≈ largo exacto de la cadena escapada) estaba
   disponible desde la primera medición. **Regla:** cuando un valor leído es
   inexplicable, comprobar primero que lo escrito sea lo que se cree.
