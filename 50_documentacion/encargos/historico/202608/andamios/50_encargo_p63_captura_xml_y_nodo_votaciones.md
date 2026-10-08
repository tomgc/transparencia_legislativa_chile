# Encargo autónomo — P-63: captura XML cruda del 36 y rescate del nodo `Votaciones`

> **Destino en el repositorio:** `50_documentacion/andamios/50_encargo_p63_captura_xml_y_nodo_votaciones.md`
> **Proyecto:** `transparencia_legislativa_chile`
> **Sesión:** 17. **Fecha de redacción:** 2026-08-08.
> **Modo:** ejecución autónoma (Ultracode). Objetivos e invariantes, no fases prescritas.
> **Protocolo vigente:** `POLITICA_PROYECTO.md` v5.6, `SETTINGS_Y_PROMPTS_OPERACIONALES.md` v16.

---

## 0. Declaración de premisas (contrato anti-PAT-01)

Esta sección existe porque el §15 del traspaso v16 registró tres `PAT-01` en una
misma sesión, todos de la misma forma: una ruta de campo, un invariante heredado
y un predicado de cifra que entraron a un encargo sin que ninguna fuente leída
los respaldara. La regla que corresponde no es una prohibición más enfática sino
este contrato positivo: **todo lo que este encargo afirma sobre rutas, invariantes
y cifras aparece aquí con su respaldo, y lo que no aparece aquí no puede aparecer
en el cuerpo del encargo.**

### 0.1 Afirmaciones respaldadas por lectura de esta sesión

| Afirmación | Respaldo |
|---|---|
| `con_cache()` persiste el **retorno** de `fn_descarga()`, no la respuesta HTTP | `10_utils.R:228-240`, leído |
| `extraer_detalle()` del 36 devuelve un tibble ya parseado, no XML | `36_extraer_detalle_proyectos.R:69-104`, leído |
| Por lo tanto el XML de `retornarProyectoLey` **nunca toca disco** | Consecuencia directa de las dos anteriores |
| `parsear_contenido_proyecto()` vive en `10_utils.R:405-418` | `10_utils.R`, leído |
| La función descarta todo salvo `Nombre`, `TipoIniciativa` y `Materias/Materia` | `10_utils.R:405-418`, leído |
| `parsear_contenido_proyecto()` es compartida por 35 y 36 | Comentario en `10_utils.R:403`; **no verificado contra el 35**, ver G1 |
| Las columnas que el 36 escribe son `boletin`, `nombre`, `tipo_iniciativa`, `n_materias`, `materias` | `36_extraer_detalle_proyectos.R:89-95`, leído |
| `capturas_crudas_de_paso("36")` devuelve `ruta_cache("detalle_proyectos_<anio>", Inf)` | `10_utils.R:266-277`, leído |
| El sello se calcula con `hash_origen_de(ruta_cache(...))` sobre esa misma ruta | `36_extraer_detalle_proyectos.R:138-140`, leído |
| La clave de caché debe codificar todo parámetro que altere el contenido cacheado | Doctrina declarada en `10_utils.R:174-179`, leída |
| La guarda de regeneración fuerza `camara.refrescar = FALSE` y lo restaura con `on.exit` | `10_utils.R:343-344`, leído |
| No existe `50_documentacion/activa/50_locale_utf8.md` ni `50_ordenacion_repositorio.md` | `estructura_actual.md` del 2026-08-08 08:22:56, leído |

### 0.2 Afirmaciones NO respaldadas: son hipótesis y este encargo las convierte en compuertas

| Hipótesis | Compuerta que la resuelve |
|---|---|
| El universo es de 381 boletines | **G5**. Cifra heredada del traspaso v16 §11.1, **no recontada**. Ninguna salida puede citarla sin recuento propio |
| El nodo `Votaciones` viene en 115 de 115 boletines votados y `Articulo` no vacío en 619 de 723 | **G6**. Cifras heredadas del traspaso v16 §11.1, medidas por la auditoría de P-61 sobre una muestra. Se recuentan sobre el universo completo o no se publican |
| El 35 consume `parsear_contenido_proyecto()` y se rompería al cambiar su retorno | **G1** |
| El 39 consume solo las cinco columnas actuales de `proyectos_detalle.rds` | **G2** |
| `CORTE_FECHA` es `2026-08-03` y `ANIO_PROCESO` es `2026` | **G3** |
| Un XML de `retornarProyectoLey` pesa ~3 KB | **G4**. Extrapolado del tamaño de `andamios/muestras/proyecto_18211_25.xml` en el escáner, que es un archivo suelto y no una medición de la operación |

---

## 1. Meta

El caché del paso 36 guarda un derivado del parser dentro de la carpeta de dato
crudo. Eso tiene dos consecuencias, y la segunda es la que importa:

1. El nodo `Votaciones` que `retornarProyectoLey` ya entrega se pierde en el
   momento del parseo, así que rescatarlo exige volver a la red.
2. **La premisa que sostiene la guarda de autorregeneración de P-65 es falsa para
   el paso 36.** Esa guarda promete regenerar los intermedios sin red a partir de
   la captura versionada; para el 36 solo puede reproducir exactamente los campos
   que el parser de ese día decidió conservar. Cualquier campo nuevo la obliga a
   descargar, que es justamente lo que declara no hacer.

El objetivo de este encargo es, en este orden:

**(a)** convertir la captura del paso 36 en captura genuinamente cruda (el XML de
respuesta, tal cual), con clave de caché propia y sin tocar la captura existente;
**(b)** una vez que el crudo está en disco, extender
`parsear_contenido_proyecto()` para dejar de descartar el nodo `Votaciones`;
**(c)** demostrar que el portal publicado no cambia.

El (c) no es cosmético: esta sesión paga una descarga y un cambio de contrato
interno, y la única forma de que eso sea barato es que el artefacto público quede
byte a byte igual salvo el campo volátil.

---

## 2. Invariantes

Se cumplen todos. Cualquiera que no puedas cumplir es causal de detención (§9),
no de solución creativa.

1. **R es el único lenguaje**, en todo contexto, incluida la inspección auxiliar.
   Sin `jq`, `awk`, `python`, ni `grep`/`sed` sobre artefactos de datos. Nada de
   `Rscript -e` con expresiones regulares: los regex viven en archivos `.R`
   probados contra insumo real.
2. **`20_insumos/camara/` es dato crudo inmutable.** La captura existente del
   corte vigente **no se sobrescribe, no se borra y no se renombra**. Su md5 al
   terminar debe ser idéntico al del inicio, y eso se verifica (C2).
3. **La captura XML usa una clave de caché nueva.** Reutilizar
   `detalle_proyectos_<anio>` con un contenido de forma distinta violaría la
   doctrina de `10_utils.R:174-179` y haría que un caché viejo se leyera como
   nuevo en silencio. Clave propuesta: `detalle_proyectos_xml_<anio>` con
   `tope = Inf`. Si eliges otra, decláralo y justifícalo.
4. **Un `xml_document` no se serializa.** `xml2::read_xml()` devuelve un puntero
   externo; `saveRDS()` de ese objeto produce un `.rds` que al leerse da un
   puntero inválido, sin error visible en la escritura. El XML se persiste como
   `character` (`as.character(doc)`) y se reconstituye con `xml2::read_xml()`.
   Esto es un falso verde silencioso del tipo PAT-02 si se hace mal: verifícalo
   releyendo el `.rds` escrito y reparseando una entrada, no asumiendo.
5. **`sellar()`, `leer_sellado()` y `validar_corte()` no se tocan.** Si algo no
   pasa la compuerta, el defecto está aguas arriba.
6. **La guarda de `00_run_all.R` sigue sin descargar nada.** Al terminar,
   `capturas_crudas_de_paso("36")` debe apuntar a la captura que efectivamente
   permite regenerar el paso 36 sin red. Si apunta a la vieja, la guarda promete
   algo que no puede cumplir y el encargo no está terminado.
7. **Una sola corrida con red, y es explícita.** La descarga del universo completo
   se hace una vez, con `camara.refrescar = TRUE` fijado a propósito y declarado
   en el log. Ninguna verificación posterior vuelve a la red: todas corren con
   `camara.refrescar = FALSE`.
8. **`REFRESCAR_API` y `camara.refrescar` se restauran** con `on.exit` tras
   cualquier corrida que los altere. Un invariante de entorno no depende del
   estado que dejó el operador (A65).
9. **Fallo ruidoso.** `stop()` con mensaje diagnóstico ante cualquier validación
   fallida. Nunca un default silencioso, nunca un `try(..., silent = TRUE)`,
   nunca un fallback que devuelva estructura vacía como si fuera resultado.
10. **Ninguna cifra sin recuento programático del mismo turno.** Toda cobertura se
    declara con su denominador en la misma línea, y el denominador se cuenta, no
    se hereda. Las cifras del §0.2 son hipótesis hasta que las midas.
11. **Presencia de nodo no es presencia de dato** (A62). `<Materias/>` viene
    presente y autocerrado; el nodo `Votaciones` puede comportarse igual. Cuenta
    valores no vacíos, no nodos.
12. **Git:** `git` siempre con `-C /Users/tomgc/Projects/transparencia_legislativa_chile`;
    `gh` siempre con `-R tomgc/transparencia_legislativa_chile`. `git add` siempre
    con ruta acotada, nunca `git add .` ni `git add -A`. Trabajas en rama y abres
    PR; **no** haces merge. `main` no recibe push directo.
13. **No uses `gh pr diff --name-only`**: devuelve HTTP 406 en PRs grandes de este
    repositorio. Usa `gh api` paginado sobre `/pulls/<n>/files` y declara el
    denominador de archivos.
14. **Nada temático se publica en esta sesión.** No se agrega bloque `materias`,
    no se agrega vista temática, no se toca `docs/`. El portal queda igual.
15. **Dato personal antes de commitear** (A63). La captura XML es un agregado
    nuevo sobre un repositorio público: se evalúa antes de versionarla, contando
    valores no vacíos por tipo de campo sensible, no nodos.

---

## 3. Compuertas de precondición

Ninguna línea de código de producción se escribe antes de que las seis estén
respondidas por escrito, cada una con el archivo y la línea que la responde. Una
compuerta que no puedas responder es causal de detención, no de suposición.

- **G1 — El 35.** Lee el script `35_*` completo. ¿Invoca
  `parsear_contenido_proyecto()`? ¿Qué campos de su retorno consume? Declara si
  extender el retorno con claves nuevas lo afecta y cómo. Si además cachea por su
  cuenta, declara qué persiste.
- **G2 — El 39.** Lee `39_consolidar_json.R`. Declara la lista **exacta** de
  columnas de `proyectos_detalle.rds` que consume, con línea. Las columnas nuevas
  no pueden llegar al JSON público en esta sesión (invariante 14).
- **G3 — Configuración.** Lee `10_utils/10_configuracion.R`. Declara `CORTE_FECHA`
  y `ANIO_PROCESO` vigentes con su línea. Todo el encargo depende de estos dos
  valores y ninguno se hereda de un documento.
- **G4 — Peso real.** Descarga **10 boletines** (no más) y mide: bytes del XML sin
  comprimir, bytes del `.rds` comprimido que los contiene, y la extrapolación al
  universo de G5. Esta es la única descarga permitida antes de la autorización de
  §4.
- **G5 — Universo.** Cuenta programáticamente la unión de boletines autorados y
  votados desde `proyectos.rds` y `votos.rds`, replicando la lógica de
  `36_extraer_detalle_proyectos.R:49-53`. Declara los tres números (autorados,
  votados, unión). **No cites 381 sin haberlo contado.**
- **G6 — Forma del nodo.** Sobre los 10 XML de G4, declara la estructura real de
  `Votaciones`: nombres de los hijos, cardinalidad, y cuántos traen valor no vacío
  por campo. Los cuatro campos que el traspaso nombra
  (`TipoVotacionProyectoLey`, `Articulo`, `TramiteConstitucional`,
  `TramiteReglamentario`) son una hipótesis de nombre, no un contrato leído.

---

## 4. Punto de autorización (única pausa)

Tras G1-G6, **detente y reporta** antes de la descarga completa. El reporte cabe
en una tabla y trae: los tres números de G5, el peso extrapolado de G4, la
estructura real de G6, y el efecto declarado sobre 35 y 39.

Sigue automáticamente **solo si** el peso extrapolado de la captura XML comprimida
es **menor a 2 MB por corte**. Si lo supera, detente y reporta: el bot commitea una
captura por semana y el costo se acumula en el historial del repositorio, así que
esa es una decisión del titular y no tuya.

Este es el único punto de pausa del encargo. Todo lo demás lo resuelves solo.

---

## 5. Objetivos

### O1 — Captura genuinamente cruda para el paso 36

El paso 36 persiste el XML de respuesta de cada boletín bajo la clave nueva, y
deriva el tibble desde esa captura en vez de derivarlo del vuelo. La estructura
persistida asocia cada boletín con su XML como texto y permite distinguir tres
estados sin ambigüedad: resuelto, no resuelto por error de red, y no resuelto
porque la API no reconoce el boletín (hoy ambos últimos colapsan en
`no_resueltos`, ver `36:78-88`).

Consecuencia obligada: reparsear con un parser distinto ya no necesita red. Ese es
el criterio con el que se juzga si O1 quedó bien hecho.

### O2 — El parser deja de descartar `Votaciones`

`parsear_contenido_proyecto()` conserva el nodo `Votaciones` con la forma que G6
haya encontrado, respetando lo que la función ya hace bien: las llaves como
`character` (`como_llave()`), el vacío como `data.frame` de 0 filas y nunca
fabricado, y `NA` donde la fuente no trae valor. El retorno se extiende; no se
reorganiza lo existente.

Si G1 muestra que el 35 se rompe con el retorno extendido, la extensión es
aditiva y el 35 sigue leyendo lo que leía.

### O3 — El paso 36 expone las claves nuevas en su intermedio

`proyectos_detalle.rds` conserva sus cinco columnas actuales, con los mismos
valores para los mismos boletines, y suma las columnas del nodo `Votaciones`.
`capturas_crudas_de_paso()` y el `hash_origen_de()` del 36 apuntan a la captura
nueva.

### O4 — Demostración de neutralidad sobre lo publicado

`run_all()` completo corre desde intermedios borrados, sin red, y produce
artefactos idénticos a los publicados con la única excepción de
`metadatos.generado`, que es volátil por construcción (A54).

---

## 6. Criterios de éxito

Cada uno se contrasta con una medición que imprime su resultado. Ninguno puede
pasarse en silencio: un criterio que no se puede medir se reporta como NO CUMPLE,
nunca se omite.

| # | Criterio | Contraste |
|---|---|---|
| C1 | La captura XML existe y está completa | N entradas con XML no vacío = N de la unión contada en G5; 0 entradas vacías; declarar el denominador |
| C2 | La captura anterior quedó intacta | md5 de `<corte>_detalle_proyectos_<anio>_tope-inf.rds` idéntico antes y después |
| C3 | El XML persistido es reparseables | Releer el `.rds`, reparsear 10 entradas con `xml2::read_xml()` y obtener `Nombre` no vacío en 10 de 10 |
| C4 | El tibble no cambió en lo viejo | Comparación campo a campo de las 5 columnas previas contra el `proyectos_detalle.rds` actual, por boletín; 0 diferencias sobre los boletines comunes; declarar cuántos son |
| C5 | Las claves nuevas están presentes | Las columnas que G6 definió existen en el intermedio, con su tipo declarado |
| C6 | Cobertura del nodo, medida | N boletines con `Votaciones` no vacío sobre el denominador de **boletines votados** contado en G5, no sobre la unión. Valores no vacíos, no nodos (A62) |
| C7 | Regeneración sin red | Borrar los 6 intermedios, correr `run_all()` con `camara.refrescar = FALSE` y sin conectividad efectiva; completa sin error y `validar_corte()` pasa 6 de 6 |
| C8 | La guarda apunta a la captura correcta | `capturas_crudas_de_paso("36")` devuelve la ruta de la captura XML, y el escenario "intermedio ausente" de P-65 se resuelve sin red |
| C9 | Neutralidad del artefacto público | Artefactos de `40_salidas/json/` idénticos a los publicados excluido `metadatos.generado`; declarar el denominador de archivos comparados |
| C10 | `docs/` intacto | `git status` acotado a `docs/`: 0 líneas |
| C11 | Evaluación de dato personal | Recuento de valores **no vacíos** por tipo de campo sensible sobre la captura XML, con la decisión de versionar o ignorar y su justificación |
| C12 | El PR declara sus conteos | Cuerpo del PR con las cifras de C1, C4, C6 y C9, cada una con denominador |

---

## 7. Panel adversarial

Antes de abrir el PR, cuatro verificadores independientes, cada uno con código
propio que no reutiliza el del ejecutor. Sus hallazgos se aplican **antes** del
PR, no se anexan después.

- **V1 — El puntero externo.** Confirma que ningún `.rds` escrito contiene un
  objeto `xml_document`. Un `.rds` con puntero inválido se lee sin error y falla
  después: es el falso verde de este encargo.
- **V2 — El denominador.** Recuenta por su cuenta la unión de boletines y la
  cobertura de `Votaciones`. Cualquier cifra del reporte cuyo denominador no pueda
  reproducir se marca como no verificada.
- **V3 — La inmutabilidad.** Verifica que ningún archivo preexistente de
  `20_insumos/camara/` cambió de md5, y que la captura nueva no colisiona de clave
  con ninguna existente.
- **V4 — La promesa de la guarda.** Borra los 6 intermedios, desconecta la red y
  comprueba que `run_all()` completa. Si necesita red, O1 no está cumplido por
  mucho que C1 haya pasado.

---

## 8. Entregables

1. Código modificado: `10_utils/10_utils.R`, `36_extraer_detalle_proyectos.R`, y
   lo que G1 obligue en el 35.
2. Log de ejecución en `50_documentacion/andamios/logs/20260808_p63_captura_xml_log.md`,
   con las respuestas de G1-G6, las decisiones tomadas, los 12 criterios
   contrastados uno a uno, y los hallazgos del panel.
3. Rama y PR abierto contra `main`, con el cuerpo exigido por C12. **Sin merge.**

---

## 9. Regla de detención

Te detienes y reportas, sin continuar, si ocurre cualquiera de estas:

- Una compuerta de §3 no se puede responder leyendo un archivo del repositorio.
- El peso extrapolado de G4 supera 2 MB por corte (§4).
- G1 muestra que el 35 no puede quedar indemne con una extensión aditiva.
- C11 encuentra dato personal no vacío en la captura XML.
- Una premisa estructural de este encargo resulta falsa al medirla.

**Esta regla se aplica, no se interpreta.** El §15 del traspaso v16 registra una
corrida anterior en la que la condición de detención se cumplió, el ejecutor juzgó
que detenerse no aportaba información y continuó. El juicio pudo ser correcto y la
regla igual fue cruzada. Si crees que detenerte es innecesario, detente y dilo:
esa es la información que se te pide.

---

## 10. Lo que NO haces

- No mergeas el PR.
- No tocas `docs/` ni ningún artefacto publicado.
- No agregas bloque `materias` ni vista temática (⚠️ heredado: la cobertura es de
  5 sobre 381 y publicarla respondería preguntas temáticas con datos parciales).
- No tocas `sellar()`, `leer_sellado()` ni `validar_corte()`.
- No abordas P-59 (locale UTF-8) ni P-60 (ordenación): están encendidos y son
  decisión aparte del titular.
- No mueves archivos por tu cuenta entre carpetas del repositorio.
