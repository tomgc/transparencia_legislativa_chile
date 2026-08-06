# Encargo Ultracode — Auditoría de fuentes: Cámara y Senado

> **Proyecto:** `transparencia_legislativa_chile` · **Sesión 15** · 2026-08-03
> **Modo:** Ultracode (workflows dinámicos). **Ejecutor:** Claude Code, app de escritorio.
> **Naturaleza:** medición de solo lectura. Este encargo **no modifica el pipeline
> ni el contrato publicado**. Su producto son catálogos, un veredicto y un plan.
>
> **Por qué está escrito así.** Un encargo Ultracode no prescribe fases: la
> orquestación la decide el runtime. Lo que sí fija el redactor, y lo que este
> documento contiene, es la **meta**, los **invariantes**, el **contrato de
> salida** y los **criterios de éxito contrastables**. Si una instrucción de aquí
> te parece que compite con tu propia descomposición, gana tu descomposición,
> salvo que sea un 🔒.

---

## 1. Meta

Convertir el pipeline del Senado de **bloqueado** a **diseñable**, y de paso
saber qué hay en las fuentes de la Cámara que el proyecto no está usando.

Concretamente, responder cuatro preguntas con evidencia reproducible:

1. **¿Qué expone realmente la API de la Cámara?** El proyecto consume 8
   operaciones de un servicio que expone del orden de 49. Las otras ~41 nunca se
   han inventariado. Qué hay ahí, con qué llaves, con qué cobertura.
2. **¿Alguna de esas operaciones no usadas resuelve un pendiente abierto?** En
   particular **P2**: los campos `RebajaAsistencia` y `RebajaQuorum` se persisten
   pero están excluidos de toda fórmula porque su semántica reglamentaria no está
   documentada. Si alguna operación del servicio la documenta o la deriva, P2 deja
   de estar bloqueado.
3. **¿Qué expone el backend del Senado** (`web-back.senado.cl/api/`) y con qué
   llaves, sabiendo que `senadores_vigentes.php` **no es fuente confiable de
   padrón** para el período vigente?
4. **¿Es construible el contrato simétrico de asistencia nominal por sesión (D2)
   para el Senado?** Veredicto explícito: sí, no, o sí con estas lagunas. Esta es
   la pregunta que desbloquea el pendiente mayor del proyecto.

---

## 2. Contexto mínimo suficiente

### 2.1 El proyecto

Portal serverless de transparencia legislativa de Chile. Scripts en R consolidan
API públicas en JSON estáticos que consume un `docs/index.html` de una pieza,
servido por GitHub Pages desde `/docs`. Raíz:
`/Users/tomgc/Projects/transparencia_legislativa_chile`.

### 2.2 Lo que ya está decidido y no se re-discute

- **D1:** el Senado entra por un pipeline extendido con capa de normalización, no
  por un pipeline paralelo ni por un esquema distinto.
- **D2:** el contrato de asistencia es **simétrico** entre cámaras: serie nominal
  por sesión, con estado por parlamentario y por sesión, no un agregado.
- **D3:** la llave es compuesta, `(camara, parlamentario_id)`, con fecha de
  captura. Los espacios de identificadores de Cámara y Senado son **distintos**;
  no hay colisión que resolver, hay que declarar la separación.
- **D18:** el titular de asistencia del portal es
  `asistencia.periodo_vigente.tasa_presencia`.

Este encargo **no revisa estas decisiones**. Las usa como vara: mide si las
fuentes las soportan.

### 2.3 Dónde mirar en el propio repositorio antes de salir a la red

- `30_procesamiento/32_extraer_diputados.R`, `33_extraer_asistencia.R`,
  `34_extraer_votaciones.R`, `35_extraer_proyectos.R`,
  `36_extraer_detalle_proyectos.R`: las 8 operaciones que **sí** se usan, con su
  forma de invocación real y su manejo de caché.
- `10_utils/10_utils.R` y `10_utils/10_configuracion.R`: utilidades de descarga,
  caché, sellado y validación de corte. **Reúsalas**; no escribas un cliente HTTP
  nuevo si ya hay uno.
- `40_salidas/intermedios/`: los datos ya extraídos. De ahí salen los
  identificadores reales para muestrear (ver 🔒 sobre identificadores inventados).
- `50_documentacion/activa/encargo_contrato_datos_camara_senado.md` y
  `50_documentacion/activa/encargo_exploracion_asistencia_senado_h1bis.md`:
  exploraciones previas sobre este mismo terreno. **Léelos antes de empezar**:
  contienen hallazgos que no hay que redescubrir y, posiblemente, callejones sin
  salida ya recorridos.

---

## 3. Invariantes (🔒)

- 🔒 **Solo lectura sobre el proyecto.** No se modifica ningún script del
  pipeline, ningún JSON publicado, ningún archivo de `docs/`. Lo único que este
  encargo escribe son los artefactos del contrato de salida (sección 4).
- 🔒 **No mergees ningún PR, no dispares el workflow de GitHub Actions, no
  escribas en `main`.** Hay un PR de retiro de contrato legacy en revisión del
  titular y es posible que haya uno del bot: no los toques.
- 🔒 **R es el único lenguaje** para toda consulta, parseo e inspección de datos.
  Prohibido `jq`, `awk`, `python` y prohibido `grep`/`sed` sobre artefactos de
  datos. Sobre código fuente puedes buscar con las herramientas del entorno.
- 🔒 **Ningún identificador inventado.** Todo muestreo usa identificadores reales
  leídos de `40_salidas/intermedios/` o devueltos por la propia API. Probar una
  operación con un ID fabricado y concluir que "no devuelve datos" es exactamente
  el error que este encargo existe para no cometer.
- 🔒 **Ausencia de dato ≠ ausencia de capacidad.** Si una operación devuelve vacío
  para el muestreo, se registra como *sin datos para los parámetros probados*, con
  los parámetros declarados. Nunca como *no expone*.
- 🔒 **No se fabrica semántica.** Si el significado de un campo no consta en la
  fuente, se registra como *no documentado*, no se deduce del nombre. Esta es la
  regla que mantiene a P2 honestamente bloqueado en vez de falsamente resuelto.
- 🔒 **Amabilidad con las APIs públicas.** Ambos servicios son infraestructura
  pública de un tercero. **Máximo 4 agentes concurrentes en cualquier fase que
  toque la red**, pausa entre llamadas, y toda respuesta se cachea en disco para
  no repetir una descarga ya hecha. Si un servicio empieza a devolver errores o a
  degradarse, esa rama **se detiene** y se registra; no se reintenta en bucle.
- 🔒 **`20_insumos/camara/` es dato crudo inmutable y no se toca.** Todo lo que
  descargue esta exploración va a `20_insumos/exploracion/<AAAAMMDD>/`, un
  directorio nuevo y separado, para que la exploración no contamine el insumo del
  pipeline.
- 🔒 **`senadores_vigentes.php` no se usa como fuente de padrón** para el período
  vigente: ya se comprobó que no es confiable. Puede inventariarse como operación,
  con esa advertencia registrada.
- 🔒 **El repositorio es público.** Ningún artefacto de salida incluye rutas
  locales del titular, tokens, cabeceras de autenticación ni nada que no deba
  quedar publicado.

---

## 4. Contrato de salida

Cuatro artefactos, todos en la rama de trabajo, ninguno mergeado.

### 4.1 `50_documentacion/activa/50_catalogo_fuentes_camara.md`

Una fila por operación expuesta por el servicio. **El universo debe salir del
descriptor del propio servicio** (WSDL o equivalente), no de los scripts del
proyecto ni de una lista recordada: el denominador se declara y se cita su fuente.

Por operación:

| Campo | Contenido |
|---|---|
| Operación | Nombre exacto |
| Estado | `EN USO` (con el script que la invoca) / `NO USADA` |
| Parámetros | Nombre, tipo, obligatoriedad |
| Campos de respuesta | Nombre, tipo, y si es llave |
| Llave | Cuál identifica unívocamente la fila |
| Granularidad | Qué representa una fila |
| Cobertura probada | Qué parámetros se probaron y qué devolvió |
| Solapamiento | Si duplica algo que el proyecto ya obtiene por otra vía |
| Utilidad potencial | Qué pendiente o capacidad habilitaría, o "ninguna aparente" |
| Notas | Rarezas, campos sin documentar, inconsistencias |

Y al final, tres secciones cerradas:

- **Veredicto sobre P2:** ¿alguna operación documenta o permite derivar la
  semántica de `RebajaAsistencia` / `RebajaQuorum`? Sí (con cuál y cómo), o no
  (con la lista de las que se descartaron y por qué).
- **Operaciones que valdría la pena consumir**, ordenadas por valor para el
  portal, cada una con qué agrega y qué costaría.
- **Denominador declarado:** cuántas operaciones expone el descriptor, cuántas se
  probaron, cuántas quedaron sin probar y por qué.

### 4.2 `50_documentacion/activa/50_catalogo_fuentes_senado.md`

Misma estructura, adaptada al backend del Senado. Además, obligatoriamente:

- **Padrón:** cuál es la fuente confiable de senadores del período vigente, con la
  evidencia de por qué es confiable (no basta que responda: tiene que cuadrar
  contra algo independiente).
- **Identificadores:** qué espacio de IDs usa, si es estable en el tiempo, y cómo
  se relaciona (o no) con el de la Cámara.
- **Sesiones:** existe o no un catálogo de sesiones del Senado, con fecha y
  legislatura.
- **Asistencia:** existe o no asistencia **nominal por sesión**; si solo hay
  agregados, decirlo con todas las letras.
- **Votaciones y proyectos:** qué hay, aunque queden fuera del alcance inmediato.

### 4.3 `50_documentacion/activa/50_veredicto_contrato_simetrico_senado.md`

El documento que de verdad importa. Corto, decidible, sin relleno:

1. **Veredicto sobre D2:** el contrato simétrico de asistencia nominal por sesión
   ¿es construible para el Senado? `SÍ` / `NO` / `SÍ CON LAGUNAS`.
2. **Mapeo campo a campo** entre el contrato actual de la Cámara (léelo del JSON
   publicado y del `39`) y lo que el Senado puede entregar. Tres columnas: campo
   de la Cámara, equivalente en el Senado, veredicto (`directo`,
   `derivable`, `ausente`).
3. **Lagunas**, cada una con: qué falta, qué la haría salvable, y qué costaría.
4. **Plan de construcción propuesto**, en el nivel de detalle que permita
   convertirlo en encargos: qué scripts nuevos, qué capa de normalización, qué
   orden, qué se puede verificar en cada paso. **Propuesta, no ejecución.**
5. **Riesgos**, con el que más te preocupe primero.

### 4.4 `20_insumos/exploracion/<AAAAMMDD>/` y su script reproductor

El sondeo se hace con un script en R que queda guardado en
`50_documentacion/andamios/<AAAAMMDD>_sondeo_fuentes.R`, y las respuestas crudas
quedan cacheadas en `20_insumos/exploracion/<AAAAMMDD>/`. Esto no es burocracia:
un catálogo que no se puede volver a derivar es una afirmación de memoria, y este
proyecto tiene un patrón documentado de errores por afirmar sin releer. **Si el
catálogo no se puede reproducir corriendo un archivo, el encargo no está
terminado.**

Si la exploración pesa lo suficiente como para ensuciar el repositorio, cachea
igual pero añade el directorio a `.gitignore` y decláralo en el log: la
reproducibilidad la da el script, no los bytes.

---

## 5. Criterios de éxito contrastables

Cada uno debe poder fallar ruidosamente. Un criterio que no puede fallar no es un
criterio.

| # | Criterio | Cómo se contrasta |
|---|---|---|
| 1 | El universo de operaciones de la Cámara sale del descriptor del servicio | El catálogo cita el descriptor y su total; el número no proviene de ningún script del proyecto |
| 2 | Las 8 operaciones en uso aparecen en el catálogo marcadas `EN USO`, con el script que las invoca | Contraste programático contra los scripts `32`–`36` |
| 3 | Toda operación marcada como probada tiene registrada la llamada real y su respuesta | El caché de `20_insumos/exploracion/` contiene la respuesta de cada una |
| 4 | El veredicto de P2 es una de las dos formas cerradas, nunca "no está claro" | Lectura del documento |
| 5 | La fuente de padrón del Senado cuadra contra una fuente independiente | Se declara cuál y qué diferencia hubo (cero o la que sea) |
| 6 | El veredicto sobre D2 es `SÍ` / `NO` / `SÍ CON LAGUNAS`, nunca prosa evasiva | Lectura del documento |
| 7 | El mapeo campo a campo cubre **todos** los campos del contrato de asistencia vigente | Contraste contra el bloque `asistencia` de un perfil publicado real |
| 8 | Todo el catálogo se reproduce corriendo el script de sondeo | Correrlo de nuevo y comparar |
| 9 | Ningún archivo del pipeline cambió | `git status` acotado a `10_utils/`, `30_procesamiento/`, `docs/`, `40_salidas/` |

---

## 6. Exigencias de calidad (esto es lo que separa un catálogo útil de una lista)

- **Verificación adversarial de los hallazgos de alto riesgo.** Los tres que hay
  que re-derivar con agentes independientes, con código propio, sin reutilizar el
  del hallazgo original: el **veredicto de P2**, la **fuente de padrón del
  Senado**, y la **existencia de asistencia nominal por sesión en el Senado**. Un
  falso positivo en cualquiera de los tres manda al proyecto a construir sobre
  arena. Si el verificador no puede confirmar ni refutar, se reporta como **no
  verificado**, que no es lo mismo que refutado.
- **Cada afirmación con su fuente en la misma línea**, en los tres documentos:
  el archivo leído o la llamada hecha. Una afirmación sin fuente es una hipótesis
  y se marca como tal, con el comando que la resolvería.
- **Las cifras se cuentan programáticamente en el momento de escribirlas.**
  Aritmética mental, cifras heredadas de otro documento y cifras recordadas no son
  fuentes.
- **Lo que no se pudo probar se dice.** Un catálogo con huecos declarados vale
  más que uno completo por relleno. El objetivo es un documento sobre el que se
  pueda decidir, no uno que se vea terminado.
- **Prefiere el fan-out ancho al agente largo.** Si el runtime interrumpe la
  corrida, un fan-out de agentes cortos conserva mucho más trabajo hecho que unos
  pocos agentes largos.

---

## 7. Orden sugerido (no prescriptivo)

Lo determinista antes que lo interpretativo; lo local antes que la red.

1. Lectura del repositorio: scripts `32`–`36`, `10_utils/`, y los dos encargos de
   exploración previos. Sin red.
2. Descriptor del servicio de la Cámara y construcción del universo de
   operaciones. Denominador declarado.
3. Sondeo de la Cámara, con identificadores reales y caché.
4. Backend del Senado: descubrimiento, padrón, sesiones, asistencia.
5. Mapeo contra el contrato vigente y veredicto sobre D2.
6. Panel adversarial sobre los tres hallazgos de alto riesgo.
7. Escritura de los cuatro artefactos, commits atómicos, rama, PR.

Si tu descomposición encuentra un orden mejor, úsalo. **Lo único no negociable es
que el panel adversarial vaya después de los hallazgos y antes del PR.**

---

## 8. Cierre

- Rama: `auditoria/fuentes-camara-senado`, desde `origin/main` actualizado.
- Commits atómicos por artefacto, con `git add` de ruta acotada (nunca `git add .`).
- Comandos de git con `git -C /Users/tomgc/Projects/transparencia_legislativa_chile`;
  subcomandos de `gh` con `-R tomgc/transparencia_legislativa_chile`. Prohibido
  `gh pr diff --name-only` en este repositorio.
- **Log** en `50_documentacion/andamios/logs/<AAAAMMDD>_auditoria_fuentes_log.md`:
  qué se probó, qué falló, qué quedó sin probar y por qué, veredicto de cada
  agente del panel, y las notas para el revisor.
- **PR abierto y no mergeado.** El cuerpo lleva: los tres veredictos (P2, padrón
  del Senado, D2), el denominador de operaciones, y una línea que diga que este PR
  no toca el pipeline.
- **Reporte final al chat**, compacto: rama, URL del PR, los tres veredictos, el
  denominador, qué quedó sin probar, y la ruta del log. El detalle vive en los
  documentos; el reporte es el índice.

---

## 9. Regla de detención

Un workflow no admite intervención a mitad de corrida, así que aquí no hay gates
de titular: **lo que en otro encargo sería una pregunta, aquí es un registro**.
Ante una ambigüedad, documenta las alternativas y sigue con la más conservadora,
dejando la decisión anotada en el log.

Detente de verdad, y reporta, solo si:

- cumplir una instrucción te obligaría a cruzar un 🔒;
- un servicio público empieza a degradarse o a bloquear (ahí paras esa rama,
  registras, y no reintentas);
- descubres que una premisa estructural del proyecto es falsa (por ejemplo, que
  los IDs del Senado **no** son estables, contra lo que el proyecto tiene
  registrado). Eso no se resuelve dentro de una corrida: se reporta.
