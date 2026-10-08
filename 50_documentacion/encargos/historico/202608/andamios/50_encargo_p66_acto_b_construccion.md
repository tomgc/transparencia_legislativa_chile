# Encargo P-66 acto B — Construcción de la entidad `proyecto` con tramitación

> **Destino en el repositorio:** `50_documentacion/andamios/50_encargo_p66_acto_b_construccion.md`
> **Proyecto:** `transparencia_legislativa_chile`
> **Sesión:** 21 (2026-08-13)
> **Antecedente directo:** `50_documentacion/andamios/50_medicion_p66_acto_a.md`
> y su bitácora `50_documentacion/andamios/logs/20260813_p66_acto_a_log.md`.
> **Naturaleza:** construcción. Este encargo **sí** escribe pipeline, **sí**
> escribe en `40_salidas/` y **sí** publica en `docs/`. No toca el dashboard
> (`docs/index.html`): la vista es acto C.

---

## §0. Contrato positivo del encargo

### 0.1 Afirmaciones respaldadas

Todas provienen de la medición del acto A, verificada por un panel adversarial de
tres agentes con código propio, y de documentos leídos en la sesión 21.

| # | Afirmación | Fuente |
|---|---|---|
| R1 | El SIL resuelve `GET https://tramitacion.senado.cl/wspublico/tramitacion.php?boletin=<NNNNN>` para **427 de 427** boletines del corte 2026-08-12, con 4 799 trámites | Ficha acto A §3 |
| R2 | Los nodos reales son `descripcion/{etapa, estado, leynro}` y `tramite/{SESION, FECHA, DESCRIPCIONTRAMITE, ETAPDESCRIPCION, CAMARATRAMITE}`. **No** existen `//tramite/ETAPA` ni `//leynro` en la raíz | Ficha acto A §3 y bitácora, fase G3b |
| R3 | Las fechas del SIL llegan en `%d/%m/%Y`, no en ISO: parsearlas como ISO da 0 de 4 799 sin error visible | Ficha acto A §3, confirmado por el panelista P2 |
| R4 | `leynro` viene **presente en 427 y vacío en 399**: contar por presencia da 427 en vez de 28 | Ficha acto A §3b |
| R5 | `estado` llega con **espacio final en 427 de 427** | Ficha acto A §3c |
| R6 | La respuesta del SIL trae **0 atributos XML**: `etapa` y `estado` son glosa sin código de dominio | Ficha acto A §3 |
| R7 | El SIL entrega el estado **al momento de la llamada**, no al corte: `18507-04` trae un trámite del 13/08/2026 contra `CORTE_FECHA` 2026-08-12 | Ficha acto A §3a |
| R8 | El universo de 427 es **derivado**: `union(314 autorados, 119 votados) == 427`, identidad exacta sin diferencia en ninguna dirección | Bitácora acto A, panelista P1 |
| R9 | El nodo `Votaciones` trae **737 elementos: 561 de 2026 y 176 de 2016-2025**, en partición perfecta por año | Bitácora acto A, panelista P1 |
| R10 | El diff cuenta 5 métricas (`10_utils/10_diff_conteos.R:57-61`) y **gatea 4** (`METRICAS_GATE`, `:68`); ninguna cubre tramitación | Ficha acto A §5 |
| R11 | Cobertura de autoría: **364 de 427** boletines; el parser ignora autores Senador (`30_procesamiento/35_extraer_proyectos.R:62`) | Ficha acto A §2 |

### 0.2 Hipótesis (cada una con su fase de verificación)

| # | Hipótesis | Se verifica en |
|---|---|---|
| H1 | ~~`con_cache()` admite una fuente distinta de la API de la Cámara sin modificarse~~ **Falsificada en F0 y resuelta por la enmienda 1 (§0.3): `con_cache()` admite otra fuente con un parámetro de destino, sin cambiar su contrato ni el de sellado** | F0, cerrada |
| H2 | `sellar()` y `leer_sellado()` operan sobre cualquier intermedio nuevo sin cambio de firma | F0 |
| H3 | `39_consolidar_json.R` puede emitir un segundo directorio de salida sin refactor de su flujo | F0 |
| H4 | El paso de publicación a `docs/` es un copiado explícito y no un montaje del directorio | F0 |
| H5 | `CORTE_FECHA` sigue en `2026-08-12` | F0 |

**Si H1, H2 o H3 son falsas, detente en F0 y reporta.** Ninguna se resuelve
inventando un helper nuevo: la arquitectura de caché y sellado es del titular.

### 0.3 Enmienda 1 — el destino del crudo (resuelve la contradicción detectada en F0)

F0 detuvo la ejecución con razón: el encargo v1 pedía a la vez usar `con_cache()`
sin modificarla y sacar el crudo del SIL de `20_insumos/camara/`, y las dos cosas
no pueden ser verdaderas porque `ruta_cache()` (`10_utils/10_utils.R:230-233`)
fija el directorio. La contradicción es del redactor, no de la ejecución.

Hallazgos de F0 que pasan a ser afirmaciones respaldadas (fuente: lectura de
Claude Code en la sesión 21, con archivo y línea):

| # | Afirmación | Fuente |
|---|---|---|
| R12 | `con_cache(nombre_cache, fn_descarga, tope, origen)` es agnóstica al **origen** (`fn_descarga` es un closure arbitrario) pero no al **destino**: llama a `ruta_cache()`, que fija `ruta_insumos("camara", …)` | `10_utils.R:428`, `:230-233` |
| R13 | La convención de nombre por corte es `<AAAAMMDD>_<nombre_cache><sufijo_tope>.rds` | `ruta_cache()` `:230-233`, `corte_para_clave()` `:200`, `sufijo_tope()` `:183` |
| R14 | `reportar_estado_capturas()` barre **solo** `ruta_insumos("camara")` y hace `stop()` si no encuentra capturas del corte | `10_utils.R:397-406` |
| R15 | Tres acoplamientos condicionan el paso nuevo: `PASOS_EXTRACCION` filtra `%in% 32:36` (`00_run_all.R:50`), `capturas_crudas_de_paso()` es un `switch` con `stop()` ante id desconocido (`10_utils.R:539`) e `INTERMEDIOS_PIPELINE` enumera 6 intermedios (`10_utils.R:471`) | F0 |

**Decisión del titular (vía elegida: extender, no duplicar ni mezclar):**

1. `ruta_cache()` gana un argumento `subdir = "camara"` y `con_cache()` lo
   propaga. **Retrocompatible por defecto:** ninguna llamada existente cambia de
   comportamiento, y eso se comprueba programáticamente, no por inspección.
2. El crudo del SIL va a `20_insumos/senado/`, con la misma convención de nombre
   (R13). Carpeta por host, como `camara/` es `opendata.camara.cl`.
3. `reportar_estado_capturas()` se extiende para barrer también el directorio
   nuevo. **Esto no es opcional:** si el crudo del SIL queda fuera de su barrido,
   el contrato temporal de P-74 queda ciego justo sobre la fuente que el acto A
   demostró que entrega eventos posteriores al corte (R7), y D-h pierde su
   compuerta. El hallazgo es de F0 y se adopta entero.
4. `sellar()`, `leer_sellado()` y `validar_corte()` **siguen sin tocarse**: eso es
   lo que el 🔒 protege de verdad.

Esta enmienda no autoriza ningún otro cambio de arquitectura. Cualquier otro
helper que resulte insuficiente se reporta, no se extiende por analogía con esta.

---

## §1. Encabezado de contrato

**Modo:** autónomo, secuencial, todo en este turno, un commit atómico por fase.

**Regla de detención.** Solo por: (a) un invariante 🔒 que tendrías que cruzar;
(b) un dato real que contradice R1 a R11; (c) una hipótesis de §0.2 falsa. Todo
lo demás se resuelve con autonomía y se registra en el log.

**Contrato de entorno.**

1. **ENTORNO:** filesystem local, vía Claude Code, sobre
   `/Users/tomgc/Projects/transparencia_legislativa_chile`.
2. **INSUMOS**, todos en ese filesystem, con ruta verificada por ti en F0:
   - `10_utils/10_configuracion.R`, `10_utils/10_utils.R`, `10_utils/10_locale.R`, `10_utils/10_diff_conteos.R`
   - `30_procesamiento/35_extraer_proyectos.R`, `36_extraer_detalle_proyectos.R`, `39_consolidar_json.R`
   - `00_run_all.R`
   - `50_documentacion/andamios/50_medicion_p66_acto_a.md` (la medición, fuente de R1 a R11)
   - `20_insumos/exploracion/20260813/p66_g4_*.xml` (427 respuestas ya descargadas; **solo para probar el parser sin red**, nunca como origen del artefacto publicado)
   - `50_documentacion/andamios/50_fusible_red.R`
   La plantilla del log **no está en el repositorio**: usa la estructura de
   `50_documentacion/andamios/logs/20260813_p66_acto_a_log.md`, que es la forma
   canónica de facto.
3. **POSICIÓN:** toda ruta completa desde la raíz. `git` siempre con
   `-C /Users/tomgc/Projects/transparencia_legislativa_chile`; `gh` siempre con
   `-R tomgc/transparencia_legislativa_chile` salvo `gh api`.

**Reglas canónicas.** `POLITICA_PROYECTO.md` v5.6, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`
v23. R es el único lenguaje en todo contexto: sin `jq` (tampoco `gh --jq`), sin
`awk`, sin `python`, sin `grep`/`sed` sobre artefactos, sin regex en `Rscript -e`.
Pipe nativo `|>`, `.by=`, `here::here()` dentro de scripts.

---

## §2. Decisiones ya tomadas (no se reabren)

El titular resolvió los diez gates del acto A. **Son insumo, no materia de
deliberación.** Si alguna resulta imposible de implementar, detente y reporta;
no la sustituyas por tu criterio.

| # | Decisión | Consecuencia concreta |
|---|---|---|
| D-a | La tramitación entra **con caché por corte**, no en llamada directa del cron | Clave de caché por `CORTE_FECHA`, igual que las capturas de la Cámara |
| D-b | El contrato se rehace sobre el **universo del corte vigente**, contado en la corrida | Ninguna cifra del veredicto §5.2 se hereda |
| D-c | `etapa` y `estado` se publican **solo como glosa**, con `trimws()` | No se fabrica catálogo código→glosa (R6) |
| D-d | `ley_numero` lleva flag **`cobertura_ley`** | El lector distingue "no es ley" de "no lo sabemos" |
| D-e | `autores[].camara` **se retira del contrato** | En su lugar, `metadatos.autoria_cubre` declara que la autoría cubre solo diputados (R11) |
| D-f | El padrón histórico (`retornarDiputados`) **queda fuera de alcance** | Los autores fuera del padrón se marcan, no se resuelven |
| D-g | La compuerta nueva es **`proyectos_con_tramitacion`**, sola | `tramites_totales` no entra |
| D-h | La tramitación **se acota al corte**, con descarte contado y emitido por log | Patrón de `acotar_votaciones_al_corte()` (R7) |
| D-i | El universo derivado **se declara en `metadatos`** | El JSON dice qué universo publica y cuál no (R8) |
| D-j | Los **176 eventos de votación anteriores a `ANIO_PROCESO` se conservan** en `votaciones[]`, cada uno con `detalle_nominal: false` | La entidad `proyecto` es donde la historia completa de un boletín corresponde; lo que no se tiene es el desglose nominal, y eso se declara por evento, no se imputa ni se borra (R9) |

---

## §3. Invariantes (🔒)

- 🔒 `sellar()`, `leer_sellado()` y `validar_corte()` **no se tocan**. Se usan.
- 🔒 `10_utils/10_utils.R` no adquiere dependencias de paquetes.
- 🔒 Los intermedios **no se versionan** (D24). `40_salidas/intermedios/.gitkeep`
  sigue trackeado.
- 🔒 `20_insumos/camara/` es crudo inmutable **en el sentido correcto: ninguna
  captura ya escrita se modifica ni se borra**. Agregar la captura del corte es
  justamente lo que el pipeline hace cada semana, y no viola nada. Lo que sí está
  vedado es mezclar orígenes: `camara/` es `opendata.camara.cl`, y el crudo del
  SIL vive en `20_insumos/senado/` (enmienda 1, §0.3).
- 🔒 El crudo se persiste **como XML character**, no como derivado parseado
  (principio de dato crudo inmutable ya establecido en `con_cache()`).
- 🔒 Ninguna respuesta HTTP distinta de 200 se persiste como crudo.
- 🔒 `sin_registro` no se imputa, ni en el dato ni en la presentación. Un campo
  ausente se publica ausente y con su flag.
- 🔒 D26: ninguna cobertura se publica sobre el denominador total de votaciones.
- 🔒 D28: `proyectos_detalle.rds` mantiene una fila por boletín. Este encargo no
  cambia su granularidad.
- 🔒 `main` no recibe push directo ni escritura automática. El trabajo va en rama
  y a PR.
- 🔒 Ninguna prueba que ejercite el pipeline corre sin el fusible instalado
  (`quit(99)`): un `stop()` no basta, el 36 lo atrapa y lo degrada a
  `estado = error_red`.
- 🔒 Toda cifra que reportes se recuenta programáticamente en el momento de
  escribirla. Ninguna se hereda de la ficha, del veredicto ni de este encargo.

---

## §4. Presupuesto de red

**Máximo 600 llamadas.** El desarrollo y las pruebas del parser se hacen **con
cero red**, contra los 427 XML ya descargados en
`20_insumos/exploracion/20260813/`. La red se gasta **una sola vez**, en la
captura real que puebla la caché (F1), y a partir de ahí la caché sirve.

Si la captura real necesitara más de 500 llamadas, detente: el universo creció
más de lo previsto y el costo por refresh vuelve a ser decisión del titular.

---

## §5. Fases, en orden estricto

Cada fase: Paso 0 de lectura del estado real, implementación, **verificación
observable entre la generación y el commit**, commit atómico con `git add` de
ruta acotada.

### F0 — Lectura del estado real y contrato de rutas (sin escribir código)

**Paso 0.** Lee completos `10_utils/10_utils.R` (al menos `con_cache()`,
`sellar()`, `leer_sellado()`, `validar_corte()`, `escribir_atomico()` y
`acotar_votaciones_al_corte()`), `10_utils/10_configuracion.R`,
`10_utils/10_diff_conteos.R`, `30_procesamiento/36_extraer_detalle_proyectos.R`,
`39_consolidar_json.R` y `00_run_all.R`.

**Qué produce.** Un reporte breve, antes de tocar nada, con:

1. Valor literal de `CORTE_FECHA` y su línea (H5).
2. Firma exacta de `con_cache()` y si admite una fuente que no sea la API de la
   Cámara sin modificarla (H1). **Conocer la firma no es conocer la forma de lo
   que recibe: muestra el esquema, no solo los argumentos.**
3. Convención real de la carpeta de crudo y del nombre de archivo por corte, y
   la ruta que le corresponde al SIL bajo esa convención. **No la inventes: dedúcela
   de la convención existente y decláralas ambas.**
4. Cómo `39_consolidar_json.R` emite hoy y dónde habría que insertar un segundo
   directorio de salida (H3).
5. Cómo llega hoy `40_salidas/json/` a `docs/` (H4).
6. Dónde se insertaría el paso nuevo en `00_run_all.R` y con qué número de script.

**Criterio de término.** Los seis puntos respondidos con archivo y línea. Si H1,
H2 o H3 son falsas, **detente**.

**Commit.** Ninguno: F0 no escribe.

---

### F0bis — Extensión del destino de caché (enmienda 1)

**F0 ya está ejecutada y su reporte, entregado.** Esta fase implementa la
enmienda de §0.3 y nada más.

**Qué construye.**

1. `ruta_cache(nombre_cache, tope = NULL, corte = NULL, subdir = "camara")` y la
   propagación del parámetro desde `con_cache()`.
2. La extensión de `reportar_estado_capturas()` al directorio nuevo, conservando
   su `stop()` actual: si no encuentra capturas del corte en el directorio que le
   corresponde, sigue fallando ruidosamente.
3. `20_insumos/senado/` con su entrada de `.gitignore` decidida por la misma
   regla que hoy aplica a `camara/`: si `camara/` se versiona, `senado/` también.

**Verificación antes del commit.** Programática, no por inspección:

- Toda llamada existente a `ruta_cache()` y a `con_cache()` devuelve exactamente
  la misma ruta que antes del cambio. Compáralo contra la salida del `HEAD`
  anterior, no contra tu lectura del código.
- `reportar_estado_capturas()` sigue haciendo `stop()` en el escenario que hoy lo
  provoca, comprobado en subproceso con el fusible instalado.

**Criterio de término.** Retrocompatibilidad demostrada con conteo de rutas
idénticas, y las tres funciones protegidas por el 🔒 sin una sola línea tocada,
comprobado con `git diff --stat`.

**Commit.** `feat(cache): destino parametrizable para crudo de fuentes no Camara`.

---

### F1 — Extractor de tramitación

**Qué construye.** Un script nuevo en `30_procesamiento/`, numerado según lo que
F0 determine, que:

1. Construye la **lista de boletines pedidos** desde el universo del corte y la
   persiste antes de llamar.
2. Descarga por `con_cache()`, persistiendo **XML character** como crudo.
3. Parsea con los nodos reales de R2. Fechas con `%d/%m/%Y` (R3).
4. Cuenta por **contenido no vacío**, nunca por presencia de nodo (R4).
5. Normaliza `etapa` y `estado` con `trimws()` (R5).
6. **Acota al corte** (D-h): todo trámite posterior a `CORTE_FECHA` se descarta,
   **se cuenta y se emite por log**, nunca en silencio.
7. Cuadra contra la lista pedida con `stopifnot()` (D38): el denominador es lo
   pedido, jamás lo devuelto.
8. Emite `40_salidas/intermedios/tramitacion.rds` **sellado** con el corte.

**Verificación antes del commit.** Contra los 427 XML de la exploración, sin red:
número de boletines, de trámites, de `etapa`/`estado`/`leynro` no vacíos, y el
conteo de trámites descartados por el acotamiento. Compara con la ficha del acto
A y **declara toda diferencia**: una diferencia es un resultado a explicar, no
un error a ocultar.

**Criterio de término.** El cuadre pasa; el intermedio existe, sellado y legible
por `leer_sellado()`; el descarte temporal aparece contado en el log.

---

### F2 — Pruebas de guarda por escenario

**Qué construye.** Pruebas en subproceso, con el fusible de red instalado, que
ejerciten: corte ausente, respuesta no 200, XML malformado, boletín que el SIL no
resuelve, y trámite posterior al corte. Cada guarda debe **fallar ruidosamente**
(`stop()`), sin defaults silenciosos.

**Criterio de término.** Cada escenario con su resultado esperado declarado antes
de correrlo y observado después. Si alguno degrada en vez de detenerse, es bug y
se corrige antes de F3.

---

### F3 — La entidad `proyecto`

**Qué construye.** Extensión de `39_consolidar_json.R` que emite
`40_salidas/json/proyectos/<boletin>.json`, una fila por proyecto, más su índice.

**Contrato del JSON** (revisión del §5.2 del veredicto, con las decisiones de §2
aplicadas):

```
{
  "boletin", "nombre", "tipo_iniciativa", "camara_origen", "fecha_ingreso",
  "tramitacion": { "etapa_actual", "estado", "ley_numero",
                   "tramites": [ { "fecha", "camara", "etapa", "descripcion", "sesion" } ] },
  "autores":    [ { "parlamentario_id", "nombre", "en_padron_vigente" } ],
  "votaciones": [ { "votacion_id", "fecha", "tipo", "tramite_constitucional",
                    "articulo", "resultado", "detalle_nominal" } ],
  "materias":   [ { "id", "nombre" } ],
  "metadatos":  { "corte", "universo", "autoria_cubre",
                  "cobertura_materias", "cobertura_ley", "cobertura_autoria",
                  "tramites_descartados_por_corte" }
}
```

- `metadatos.universo` **declara en texto** que el corpus son los boletines
  tocados por un diputado del roster vigente (unión de autorados y votados), no
  los proyectos ingresados en el año (D-i, R8).
- `metadatos.autoria_cubre` declara que la autoría cubre solo diputados (D-e).
- `votaciones[].detalle_nominal` es `false` para los eventos sin filas en
  `votos.rds` (D-j, R9).
- `autores[].camara` **no existe** (D-e).

**Verificación antes del commit.** Conteo de archivos emitidos contra el universo
contado; un spot-check 1:1 de tres proyectos contra su XML crudo, incluido uno de
los 28 con `ley_numero` y uno de los que traen eventos anteriores a
`ANIO_PROCESO`; y validación de que ningún JSON trae `null` donde el contrato
pide flag.

---

### F4 — La compuerta

**Qué construye.** `10_utils/10_diff_conteos.R` aprende a contar el segundo
directorio y suma `proyectos_con_tramitacion` (D-g).

**Precaución.** La métrica **no gatea en su primera corrida**: no hay corte
anterior con el que comparar. Se cuenta y se reporta; el gateo se activa cuando
exista el segundo corte. Deja eso explícito en el código, no en un comentario
suelto.

**Criterio de término.** El diff corre y reporta la métrica nueva sin romper las
cuatro existentes, verificado contra la salida actual.

---

### F5 — Integración y publicación

**Qué construye.** El paso nuevo en `00_run_all.R`, en el orden que F0 determinó,
y la publicación de `40_salidas/json/proyectos/` a `docs/` por la misma vía que
hoy usan los perfiles.

**Criterio de término.** `00_run_all.R` corre de principio a fin sin intervención
manual, con la caché ya poblada y **cero llamadas nuevas**. Los perfiles
existentes quedan **byte-idénticos**: comprueba por md5 antes y después. Si alguno
cambió, detente: este encargo no modifica la entidad parlamentario.

---

### F6 — Panel adversarial

Tres agentes de solo lectura, con código propio, sin acceso a tus scripts ni a
tus objetos, con prohibición explícita de leer los archivos que produjiste:

- **P1.** Que la cobertura de tramitación del artefacto publicado se sostenga
  recontada contra la lista pedida, por camino propio.
- **P2.** Que ningún JSON de `proyectos/` contenga un trámite posterior a
  `CORTE_FECHA`, y que el conteo de descartados cuadre con el emitido por log.
- **P3.** Que los perfiles de diputado publicados sean byte-idénticos a los de
  antes del encargo, y que ningún campo existente haya cambiado de tipo.

Si un panelista contradice una cifra tuya, **manda el panelista**: detente,
reporta ambas y no publiques la tuya.

---

### F7 — Cierre

1. Bitácora en `50_documentacion/andamios/logs/<AAAAMMDD>_p66_acto_b_log.md`,
   con la estructura del log del acto A, honesta: incluye lo que costó.
2. Commits atómicos por fase, `git add` de ruta acotada, **nunca `git add .`**.
3. `git fetch` antes de cualquier compuerta de divergencia; verificación de rama
   con `git cherry`, no con `git diff`.
4. Push de la rama y **PR abierto**. **No mergees**: el merge es del titular.
5. **Antes de reportar "listo", comprueba con `gh api` paginado que el PR liste
   los archivos que crees haber cambiado.** La vista de archivos de un PR queda
   anclada a su `base.sha`: si `main` se movió, mide el merge real con
   `git merge-tree --write-tree`, no con la vista.

---

## §6. Reporte final al chat

1. Los seis puntos de F0, con archivo y línea.
2. Cobertura de tramitación del artefacto publicado, con numerador, denominador y
   corte, contados en la corrida.
3. Trámites descartados por el acotamiento al corte, con su conteo.
4. Conteo de JSON emitidos y el spot-check 1:1 de los tres proyectos.
5. md5 de los perfiles antes y después, con el veredicto de identidad.
6. Métrica nueva del diff y su valor en esta corrida.
7. Panel adversarial, panelista por panelista, con PASA/FALLA y qué cambió.
8. Estado de cada 🔒 de §3, con evidencia.
9. Llamadas de red gastadas contra las 600 autorizadas.
10. Número y URL del PR, hashes de los commits, ruta de la bitácora.
