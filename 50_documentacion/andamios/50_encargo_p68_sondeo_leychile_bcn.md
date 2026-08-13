# Encargo P-68 — Sondeo de LeyChile y `datos.bcn.cl` como fuentes temáticas

> **Sesión 20, 2026-08-13.** Ejecuta: Claude Code. Autoriza mérgenes y push: el
> titular.
>
> **Destino de este archivo:**
> `50_documentacion/andamios/50_encargo_p68_sondeo_leychile_bcn.md`
>
> **Naturaleza:** medición de solo lectura sobre fuentes externas. **Este encargo
> no toca el pipeline, no modifica ningún script de `30_procesamiento/`, no
> publica nada en `docs/` y no propone contrato de datos.** Su único producto es
> un veredicto con cifras contadas en la corrida.
>
> **Origen:** paso 7 del plan de construcción de
> `50_documentacion/activa/50_veredicto_eje_tematico.md`: *"antes de cualquier
> promesa temática, medir si LeyChile o `datos.bcn.cl` tienen materias para los
> boletines sin ellas. Si la respuesta es sí, el veredicto de este documento
> cambia"*.

---

## §0. Contrato positivo

Separación explícita entre lo que está respaldado por una lectura de esta sesión
y lo que es hipótesis. **Ninguna hipótesis de esta tabla se usa como premisa sin
convertirla antes en hecho medido, y la conversión ocurre en la compuerta que se
indica.**

### 0.1 Afirmaciones respaldadas

| # | Afirmación | Fuente |
|---|---|---|
| R1 | El eslabón que hunde el eje temático es `proyecto → materia`; los otros cinco eslabones medidos van de 95,31 % a 100 % | `50_veredicto_eje_tematico.md` §1 y §2, leído en esta sesión |
| R2 | El hueco tiene forma de **nodo vacío**, no de nodo ausente: `<Materias/>` viene presente y autocerrado en 332 de 332 respuestas inspeccionadas | ídem, §4 |
| R3 | No hay segunda vía **dentro de la Cámara**: `retornarVotacionesXProyectoLey` es alias byte a byte de `retornarProyectoLey`, y los listados anuales no emiten el nodo `Materias` | ídem, §4 |
| R4 | El déficit no es de la Cámara: el SIL del Senado devuelve exactamente el mismo conjunto de boletines con materia, con las mismas `n_materias` | ídem, §4 |
| R5 | Dos mecanismos compiten y ninguno está zanjado: gradiente temporal de indexación (A) contra "la materia llega con la tramitación" (B). En cohortes ≥ 2020, P(materia \| con votaciones) = 52,6 % contra 11,9 % sin votaciones | ídem, §4.1 |
| R6 | 4 de los 5 boletines con materia son ley publicada, contra 0 de 15 sin materia | ídem, §4.1 |
| R7 | `50_fusible_red.R` expone `instalar_fusible_red()`, traza `httr::GET`, `httr::POST`, `httr::RETRY` y `curl::curl_fetch_memory`, y mata el proceso con `quit(status = 99)` en la primera llamada | `50_documentacion/andamios/50_fusible_red.R`, leído en esta sesión |
| R8 | Ya existe precedente de reproductor de sondeo aislado bajo `20_insumos/exploracion/<AAAAMMDD>/`, con manifiesto de llamadas en CSV | escáner `estructura_actual.md` del 2026-08-13 09:19, leído en esta sesión |

### 0.2 Hipótesis (ninguna es premisa hasta su compuerta)

| # | Hipótesis | Se convierte en hecho en | Verificar con |
|---|---|---|---|
| H1 | Los denominadores del veredicto (boletines totales, con materia, sin materia) siguen siendo los del corte 2026-08-03 | **G1** | recuento programático en R sobre `40_salidas/intermedios/proyectos_detalle.rds` al corte vigente |
| H2 | `datos.bcn.cl` expone un endpoint SPARQL público y una ontología `bcn-resources` que modela proyectos de ley y votaciones | **G2** | una consulta `SELECT` mínima con `LIMIT 1` contra el endpoint, registrando código HTTP y cuerpo |
| H3 | LeyChile expone XML de norma por identificador (`obtxml`) | **G3** | una descarga por identificador de norma conocido, registrando código HTTP y raíz del XML |
| H4 | LeyChile indexa **normas**, no proyectos en tramitación: su techo de cobertura sobre boletines sin materia es el subconjunto que llegó a ser ley | **G4** | censo del vínculo boletín → norma antes de construir cualquier extractor |
| H5 | Existe en `datos.bcn.cl` alguna propiedad que ligue un proyecto de ley con un descriptor temático | **G5** | inspección del vocabulario, con los boletines que **sí** tienen materia como control positivo |

**Ninguna URL, nombre de operación, prefijo de ontología o nombre de propiedad de
este documento se da por bueno.** Todos se declaran como punto de partida de
búsqueda y se sustituyen por lo que la fuente devuelva. Si una ruta que este
encargo sugiere no existe, eso **no es un fallo del encargo**: es el primer
hallazgo, se registra y se sigue por la ruta que la fuente sí ofrezca.

---

## §1. Pregunta que este encargo cierra

> ¿Alguna de las dos fuentes de la BCN entrega descriptores temáticos para los
> boletines que la API de la Cámara deja con `<Materias/>` vacío, en cantidad
> suficiente para dar vuelta el veredicto?

El veredicto se da vuelta **solo si** la cobertura combinada sobre el universo
contado en G1 supera con holgura la fracción actual. La respuesta legítima de
este encargo incluye **"no"**, y un "no" bien medido cierra P-68 igual que un
"sí": el resultado condiciona el alcance de P-66, no lo cancela.

---

## §2. Posición y prohibiciones

**Ejecutas un sondeo.** No tocas `30_procesamiento/`, `10_utils/`, `00_run_all.R`
ni `docs/`. No abres PR de código. No propones contrato de datos: eso es P-66 y
depende de lo que este encargo devuelva.

**Prohibido:**

- Usar `con_cache()`, `descargar_xml_camara()` o cualquier función de descarga
  del pipeline. El sondeo trae su propio cliente HTTP, en su propio archivo, con
  su propia carpeta de destino. Reutilizar el cliente del pipeline es cómo una
  captura de sondeo termina dentro del dato crudo del producto.
- Escribir **un solo byte** bajo `20_insumos/camara/`. Es crudo inmutable.
- Escribir bajo `40_salidas/`. El sondeo no produce intermedios ni JSON.
- Persistir cualquier respuesta que no sea HTTP 200 con cuerpo no vacío. Los no-200
  van al manifiesto con su código, **sin archivo**. Cachear un error es cómo un
  sondeo se convierte en una fuente de datos falsos que nadie recuerda haber creado.
- Subagentes o `Task tool`. El trabajo va en lotes secuenciales, uno por medición.
- `git add -A`, `git add .`, `git commit -a`.
- Cualquier lenguaje que no sea R. Sin `jq`, `awk`, `python`, ni `grep`/`sed`
  sobre artefactos de datos; sin regex en `Rscript -e`.
- Continuar si una compuerta falla. Una compuerta que falla se reporta y se espera.
- Afirmar una cifra que no hayas contado en el mismo paso que la afirma.

**Presupuesto de red declarado.** Máximo **500 llamadas HTTP** en toda la corrida.
El reproductor lleva un contador y **se detiene solo** al llegar al tope,
reportando cuántas quedaron sin hacer. Si una medición necesita más, se reporta y
se espera autorización: no se amplía el presupuesto por cuenta propia.

---

## §3. Entorno

- Repositorio: `/Users/tomgc/Projects/transparencia_legislativa_chile`
- Rama de trabajo a crear: `sondeo/p68-fuentes-tematicas`
- Shell: zsh. El word-splitting exige `${=VAR}`; un glob sin match aborta el
  comando entero, así que todo glob de verificación va protegido con
  `setopt local_options null_glob` o comprobado con
  `ls -1 ... 2>/dev/null | wc -l`.
- `git` siempre con `-C <ruta absoluta>`; `gh` siempre con
  `-R tomgc/transparencia_legislativa_chile`, **salvo `gh api`**, que no acepta `-R`.
- `git add` siempre con ruta acotada.

**Artefactos que produces, y ninguno más:**

| Ruta | Qué es |
|---|---|
| `20_insumos/exploracion/<AAAAMMDD>/20260813_sondeo_p68.R` | el reproductor, ejecutable de principio a fin |
| `20_insumos/exploracion/<AAAAMMDD>/_manifiesto_p68.csv` | una fila por llamada: url, código HTTP, bytes, si se persistió, y por qué no si no |
| `20_insumos/exploracion/<AAAAMMDD>/*.xml`, `*.json` | solo las respuestas 200 con cuerpo no vacío |
| `50_documentacion/andamios/logs/20260813_p68_sondeo_log.md` | bitácora de la corrida, compuerta por compuerta |
| `50_documentacion/activa/50_veredicto_fuentes_tematicas_bcn.md` | el veredicto |

---

## §4. Compuertas de precondición

Cada una se ejecuta, se reporta con su salida literal y **bloquea** si falla.

### G0 — Estado del repositorio

```
git -C <raiz> status --porcelain          -> vacío
git -C <raiz> stash list                  -> vacío
git -C <raiz> rev-parse --abbrev-ref HEAD -> no main
```

`git fetch` antes de cualquier comparación con el remoto. Crear
`sondeo/p68-fuentes-tematicas` desde `main` actualizado.

**Sello de inmutabilidad, tomado ANTES de la primera llamada de red:** md5 de
todos los archivos de `20_insumos/camara/`, persistido en el log. Se recontrasta
en el cierre (criterio C8). Reporta el conteo de archivos sellados: es el
denominador de C8 y no se hereda de ningún documento.

### G1 — Universo, contado hoy y no heredado

Con el **fusible de red armado** (`50_fusible_red.R`, R7), en un proceso que no
carga `00_run_all.R`, medir sobre `40_salidas/intermedios/proyectos_detalle.rds`:

- `CORTE_FECHA` vigente y sello del intermedio;
- N total de boletines;
- N con al menos una materia, y N sin ninguna;
- de los sin materia, distribución por cohorte de año del boletín.

**El fusible debe NO dispararse.** Si se dispara (exit 99), esta medición estaba
tocando la red y el resultado no sirve: reportar y detenerse.

Si el intermedio está desalineado con `CORTE_FECHA`, la guarda de arranque ya
resuelve el caso sin red; si pide autorización de descarga, **detente y reporta**:
este encargo no autoriza descargas del pipeline.

⚠️ Las cifras del veredicto vigente (5 de 381 con materia, 376 sin) son del corte
2026-08-03. **Se citan como antecedente y se sustituyen por lo medido aquí.** Si
el número que mides difiere, eso es un hallazgo del sondeo, no un error a
corregir en silencio.

### G2 — ¿Responde `datos.bcn.cl`?

Punto de partida de búsqueda (hipótesis H2, no premisa): el sitio de datos
abiertos enlazados de la BCN publica un endpoint SPARQL y una ontología de
recursos legislativos. Una consulta mínima con `LIMIT 1`, registrando código HTTP
y forma del cuerpo.

**Si no responde o no existe:** rama cerrada, se registra con la evidencia y se
sigue con G3. Una rama cerrada por medición es un resultado, no un fracaso.

### G3 — ¿Responde LeyChile?

Punto de partida de búsqueda (H3): LeyChile expone XML de norma por
identificador. Una descarga de control, registrando código HTTP y el nombre de la
raíz del XML devuelto.

### G4 — El techo de LeyChile, medido antes de construir nada

**Esta es la compuerta que puede matar la rama LeyChile en una sola medición, y
por eso va antes que cualquier extractor.**

LeyChile indexa normas publicadas. Un proyecto en tramitación que nunca llegó a
ley **no tiene norma**, así que la cobertura máxima alcanzable por esta vía es la
fracción de los boletines sin materia que **sí** llegaron a ser ley (H4).

Medir esa fracción **antes** de escribir el extractor:

- por censo en `datos.bcn.cl` si G2 pasó (una consulta, no una por boletín);
- si G2 falló, por el SIL (`tramitacion.senado.cl/wspublico/tramitacion.php`),
  que el veredicto midió resolviendo el total de boletines de la Cámara, leyendo
  el campo de ley publicada. Aquí sí es una llamada por boletín: contra el
  presupuesto de §2.

**Criterio de la compuerta:** si la fracción medida es menor que la cobertura
temática que el portal ya tiene, la rama LeyChile queda cerrada con evidencia y
**no se escribe extractor**. Se pasa a G5.

Esto es exactamente la hipótesis B del veredicto (R5, R6) puesta a prueba desde
el otro lado: si la materia llega con la promulgación, LeyChile cubre "lo
legislado" y no "lo que se vota este año", y eso es un producto distinto del que
el portal promete.

### G5 — Control positivo antes que cualquier medición sobre el universo

Los boletines que **sí** traen materia en la Cámara (los que G1 contó) son el
control positivo obligatorio.

**A una fuente alternativa no se le cree nada sobre los boletines sin materia
mientras no reproduzca los que sí la tienen.** Para cada uno:

- ¿la fuente lo encuentra?
- ¿devuelve descriptores temáticos?
- ¿coinciden con las materias que la Cámara ya entrega, por id o por texto?

Si el control positivo falla, cualquier cobertura que la fuente reporte sobre el
resto es **inverificable**, y así se declara: no se publica como cobertura.

Control negativo, en el mismo paso: al menos 5 identificadores inventados o de
boletín inexistente. Si la fuente devuelve algo con apariencia de dato para un
identificador que no existe, la cobertura medida está inflada y hay que decirlo.

---

## §5. Mediciones

Solo después de las compuertas, y cada una con su denominador contado en el paso.

| # | Medición | Qué devuelve |
|---|---|---|
| M1 | Censo del vocabulario temático disponible en la fuente que haya pasado G2/G3 | Cardinalidad del catálogo, si tiene identificadores estables, y si es el mismo catálogo de la Cámara o uno distinto |
| M2 | Cobertura sobre una **muestra aleatoria con semilla declarada** de los boletines sin materia, estratificada por cohorte anual | Fracción con descriptor, con intervalo de confianza, **antes** de gastar el presupuesto en el universo completo |
| M3 | Si y solo si M2 da una cobertura que podría dar vuelta el veredicto: extensión al universo, dentro del presupuesto de §2 | Cobertura sobre el denominador de G1 |
| M4 | Naturaleza del descriptor: ¿es el mismo tesauro de las 8518 materias de la Cámara, o un vocabulario ajeno? | Si es ajeno, un eje temático mezclaría dos vocabularios sin decirlo, y eso es un hallazgo que pesa más que la cobertura |

**M2 antes que M3 es innegociable.** Gastar 376 llamadas para descubrir que la
cobertura es 2 % es el error que este orden previene.

---

## §6. Criterios de éxito (definidos antes de codificar)

| # | Criterio | Cómo se mide |
|---|---|---|
| C1 | G1 corrió con el fusible armado y **no** se disparó | exit code distinto de 99, registrado |
| C2 | Todo denominador del veredicto final fue contado en esta corrida | cada cifra del veredicto cita el paso que la produjo |
| C3 | 0 respuestas no-200 persistidas como archivo | contraste entre el manifiesto y los archivos en disco, contado en R |
| C4 | El manifiesto tiene una fila por llamada, y el total de filas coincide con el contador del reproductor | dos conteos independientes, iguales |
| C5 | Control positivo de G5 resuelto en los dos sentidos (encuentra / no encuentra), con su cifra | tabla en el log |
| C6 | Control negativo de G5 con 0 falsos positivos, o el número exacto si los hubo | tabla en el log |
| C7 | El presupuesto de red no se excedió | contador final contra el tope de §2 |
| C8 | `20_insumos/camara/` intacto | md5 de G0 contra md5 de cierre, sobre el mismo denominador |
| C9 | 0 archivos escritos fuera de las rutas declaradas en §3 | `git status --porcelain` de la rama contra la lista de §3 |
| C10 | El reproductor corre de principio a fin en una sesión limpia | segunda corrida en proceso nuevo, sin estado heredado |
| C11 | El veredicto declara su universo y su denominador **en la misma línea** que cada cobertura | inspección del documento (A81) |

---

## §7. Panel adversarial

Antes de dar el veredicto por cerrado, responde estas cinco por escrito en el log.
Cada una con la cifra que la sostiene, no con un juicio.

1. **¿La cobertura que estoy reportando es sobre boletines, sobre votaciones o
   sobre filas de voto?** Son tres denominadores distintos y el veredicto vigente
   ya fue reconstruido una vez por confundirlos. Declara los tres o declara cuál
   y por qué.
2. **Si la fuente cubre bien, ¿cubre lo que se vota este año o lo que ya es ley?**
   Cruza la cobertura contra la cohorte anual. Una fuente que cubre 90 % de 2014 y
   0 % de 2026 no da vuelta nada: reproduce la hipótesis A con otro proveedor.
3. **¿El descriptor que devuelve la fuente es una materia legislativa o es otra
   cosa** (una clasificación de ministerio, una etiqueta de organismo emisor, un
   tipo de norma)? Un campo con nombre parecido no es el mismo campo.
4. **¿Qué explicaría el resultado si la fuente estuviera devolviendo el mismo
   contenido de la Cámara por otro camino?** El veredicto ya tiene un antecedente
   de dos operaciones idénticas byte a byte que parecían fuentes distintas (R3).
   Contrasta cuerpos, no nombres de operación.
5. **¿Qué medición haría falta para que este veredicto se equivocara?** Nómbrala.
   Si es barata, córrela.

---

## §8. Entrega

1. Los cinco artefactos de §3, ninguno más.
2. Commits selectivos con ruta acotada, en la rama del sondeo. **Sin push sin
   visto bueno del titular.** Sin PR: el titular decide si esto entra a `main`.
3. Reporte final en el chat con: tabla de compuertas (pasa / falla), tabla de
   criterios C1-C11, el veredicto en una línea, y las cinco respuestas del panel.
4. Si una compuerta bloqueó, el reporte termina ahí. Un encargo detenido en G4
   con evidencia vale más que uno completado sobre una premisa falsa.
