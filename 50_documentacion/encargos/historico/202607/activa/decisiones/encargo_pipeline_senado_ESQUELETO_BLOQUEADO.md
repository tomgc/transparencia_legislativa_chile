# Encargo — Pipeline del Senado (ESQUELETO BLOQUEADO)

> **Instrumento de sesion. NO EJECUTAR AUN.** Este encargo esta BLOQUEADO hasta
> que vuelva `encargo_exploracion_senado_v02.md` y se decida, con la fuente real
> confirmada, la arquitectura del pipeline. Redactarlo completo ahora seria
> fabricar arquitectura sobre fuente no confirmada (viola B.1). Este archivo deja
> preparado el ANDAMIAJE del encargo para completarlo rapido cuando se desbloquee.
>
> **Precondicion de desbloqueo:** el reporte de exploracion v02 debe haber
> respondido, con evidencia:
> 1. Fuente primaria del Senado (wspublico vs opendata.congreso.cl vs mixta).
> 2. Si hay ids estables de parlamentario (define si el pipeline necesita capa de
>    resolucion de identidad por nombre o no).
> 3. Roster real de 50 (y su fuente).
> 4. Asistencia: fuente y formato (o decision de omitirla si resulto hueco real).

---

## Decisiones de diseno que este encargo debe fijar ANTES de redactarse

Estas se toman en la sesion de diseno con el titular una vez llegue la
exploracion v02. Estan aqui como checklist, no resueltas:

### D-pipeline-1 — Arquitectura (decision 2 original, aun abierta)
Pipeline extendido (pasos 4x_ que consolidan a los mismos JSON con capa de
normalizacion a un contrato comun) vs. pipeline duplicado.
Recomendacion previa (sesion 5, sujeta a lo que muestre v02): pipeline extendido
con capa de normalizacion a contrato comun, porque el dashboard asume modelo
unico. CONFIRMAR contra la forma real de la fuente elegida.

### D-pipeline-2 — Resolucion de identidad
Depende del hallazgo de ids de v02:
- Si opendata.congreso.cl (u otra fuente) trae ids estables → el pipeline los usa
  directo, sin fuzzy matching.
- Si solo hay nombre string (gap de v01 persiste) → el pipeline necesita una capa
  explicita de resolucion nombre→id, auditable, con reporte de no-matches (nunca
  un match silencioso de baja confianza). Definir el criterio y el umbral como
  constante nombrada.

### D-pipeline-3 — Asistencia del Senado
Segun v02:
- Fuente estructurada encontrada → se integra como metrica, simetrica a la Camara.
- Solo HTML/Diario de Sesiones → decidir si el esfuerzo de parseo vale ahora o se
  difiere (metrica presente para Camara, ausente-por-ahora para Senado, marcada
  explicita en el frontend).

### D-dashboard (decision 3 original, aun abierta)
Unificar ambas camaras con filtro `camara` vs. segmentar en dos secciones.
Recomendacion previa: unificar con filtro `camara` (ya es segmentacion declarada
del proyecto). El frontend debe TOLERAR metricas ausentes por camara (p. ej.
asistencia del Senado si quedo hueca) sin romper — requisito nuevo que surge de la
asimetria de fuentes.

### D-modulo-biblioteca — relacion con el pipeline del Senado
Ver `50_documentacion/activa/decisiones/20260710_decision_modulo_biblioteca_historica.md`.
El eje proyecto/votacion del modulo biblioteca calza mejor con la estructura del
Senado (votaciones anidadas en el boletin, join inherente) que con la Camara.
Decidir si el pipeline del Senado ya produce datos con el eje del modulo, o si el
modulo es una capa posterior sobre ambas camaras. Probablemente: el pipeline
puebla el contrato por-parlamentario (como la Camara) y el modulo es una
reorganizacion posterior sobre el corpus unificado — pero confirmarlo al disenar.

---

## Andamiaje del encargo (a completar al desbloquear)

Estructura estandar de `encargo_autonomo_claude_code_v1.md`:

- CONTRATO DE ENTORNO: repo, posicion, insumos (los docs de exploracion v01 + v02,
  el pipeline de la Camara como patron, el contrato de datos actual).
- REGLAS CANONICAS: R-only, httr2/xml2/jsonlite, here::here(), llaves character,
  naming, rama feature/pipeline-senado, sin push.
- META: poblar el contrato de datos del Senado (las 4 entidades, o 3 si asistencia
  se difiere) e integrarlo al JSON que el dashboard consume, bajo el modelo comun.
- INVARIANTES 🔒: no romper el pipeline ni los JSON de la Camara; CORTE_FECHA sin
  default silencioso tambien para el Senado; gate de conteos extendido para cubrir
  el Senado; llaves character; no fabricar datos (temas/materias/asistencia vacios
  explicitos).
- FASES: (0) leer estado real; (1) extraccion por entidad con la fuente confirmada;
  (2) normalizacion al contrato comun + resolucion de identidad; (3) consolidacion
  al JSON unificado; (4) extension del gate de conteos; (5) verificacion end-to-end
  con only=39 equivalente. Commit atomico por fase.
- CRITERIOS DE EXITO B.4: conteo de 50 senadores; join voto→proyecto verificado;
  cero matches de identidad silenciosos; dashboard renderiza ambas camaras.
- AUTO-AUDITORIA: panel adversarial recomendado AQUI (a diferencia de la
  exploracion), porque este encargo SI altera el corpus publicado y toca cifras;
  re-derivar independientemente que los conteos de la Camara no cambiaron y que la
  resolucion de identidad no introdujo errores.
- LOG + REPORTE segun plantilla.

---

## Nota de secuencia

Orden probable de sesiones futuras:
1. (proxima) correr exploracion v02 → evaluar → tomar D-pipeline-1..3 y D-dashboard.
2. completar y correr este encargo (pipeline del Senado).
3. modulo biblioteca hito B (clasificacion tematica) sobre el corpus ya unificado.
