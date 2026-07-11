# Log de ejecución — Esquema Cámara + contrato de datos común Cámara/Senado

**Fecha:** 2026-07-10
**Rama:** `design/contrato-datos` (desde `main`; sin push/PR/merge).
**Entorno:** Claude Code, macOS, R 4.5.2, `httr2` + `jsonlite`.
**Naturaleza:** andamio congelado (diagnóstico + propuesta, no se actualiza).

## 1. Resumen

Se documentó el esquema REAL del pipeline de la Cámara (leído de los scripts 32-39
Y confirmado contra los `.rds` reales) y se propuso un contrato común Cámara/Senado
(una tabla canónica por entidad, mapeando campo-Cámara y campo-Senado). Se
extrajeron en vivo los 14 pares (PARTIDO_ID, PARTIDO) de los 50 senadores como
insumo del crosswalk (sin decidir la tendencia). No se modificó ningún archivo del
pipeline; solo se agregaron el documento, su log, la muestra de partidos y un
script auxiliar de Fase 3.

## 2. Esquema de la Cámara (entidades y claves)

| Intermedio | filas | forma | PK |
|-----------|-------|-------|-----|
| `diputados.rds` | 155 | 1/diputado | `diputado_id` |
| `asistencia.rds` | 239 | **AGREGADO** 1/diputado | `diputado_id` |
| `votos.rds` | 104160 | largo diputado×votación | `(votacion_id, diputado_id)` |
| `proyectos.rds` | 1313 | 1/autor×boletín | `(boletin, diputado_id)` |
| `proyectos_detalle.rds` | 317 | 1/boletín (materias list-col) | `boletin` |

Joins: `*.diputado_id → diputados`; `votos.boletin`/`proyectos.boletin →
proyectos_detalle.boletin`. Fuente de cada campo declarada en el doc (código +
`.rds` real). JSON final de `39`: índice (11 campos) + perfil (5 bloques).

## 3. Hallazgos que condicionan el contrato

1. **Asistencia Cámara = agregado.** `33` no persiste `sesion_id` ni `fecha`; el
   largo vive solo en el caché. El contrato simétrico (nominal/sesión) requiere
   extender el normalizador de la Cámara (la fuente SÍ da fecha por sesión). →
   PREGUNTA ABIERTA #1 (materializa caso de detención #3).
2. **IDs de espacios distintos.** `diputado_id` (Cámara) ≠ `ID_PARLAMENTARIO`
   (Senado): solo 11/155 coinciden (casual). Verificado en vivo. → clave compuesta
   `(camara, parlamentario_id)` (PREGUNTA ABIERTA #2).
3. **`sexo` con dominios distintos:** Femenino/Masculino (Cámara) vs Mujer/Hombre
   (Senado) → normalizar (#4).
4. **Sentido del voto:** Cámara (dispensado/no_vota) vs Senado (pareo) → vocabulario
   canónico unión (#3).
5. **Proyectos del Senado** no están en el backend; se complementan con `wspublico`
   (autor por nombre → id vía crosswalk determinista, `estado` que la Cámara no
   tiene) → entidad más asimétrica (#6).

## 4. Pares de partido del Senado (Fase 3, insumo del crosswalk)

50 senadores, 14 partidos: Independiente 10, R.N. 8, P.S. 7, U.D.I. 5, P.C 3,
P.D.C. 3, P.P.D. 3, Republicano 3, Evópoli 2, Frente Amplio 2, Demócratas 1,
F.R.E.V.S. 1, Liberal 1, Nacional Libertario 1. Muestra en
`50_documentacion/andamios/contrato_datos/senado_partidos_muestra.json` (auto-auditada:
205 filas, CAMARA==S = 50, 14 partidos distintos). La decisión de tendencia es del
titular; se entregó la taxonomía destino (5 niveles) y el mapa vigente de la Cámara
como referencia de formato (NO extrapolado al Senado).

## 5. Qué costó / decisiones

- La verificación id-espacios (11/155) fue clave: sin ella, el contrato habría
  asumido erróneamente un id compartido. Se comprobó cruzando `diputados.rds` con el
  backend `parlamentarios` (CAMARA=D) por id.
- El gap de asistencia (agregado vs nominal) se detectó leyendo `33` y confirmando
  con `asistencia.rds` (5 columnas, sin sesión/fecha): el largo se descarta al
  agregar.
- Script auxiliar `31e` (admisible por el encargo, criterio 31c/31d) para que la
  muestra de partidos sea regenerable; NO entra a run_all.
- Los campos-Senado del contrato se re-auditaron contra los docs de exploración
  (git show): todos existen (los de detalle de proyectos —titulo/iniciativa/estado/
  materias— vienen de v01, que v02 cita como fuente complementaria de proyectos).

## 6. Casos de detención

- #1 (backend sin auth/no responde): NO — respondió (Fase 3 OK, 50 senadores).
- #2 (intermedio .rds inexistente): NO — los 5 intermedios existen y se leyeron.
- #3 (contrato del código contradice premisa): **SÍ (reportado, no aborta)** — la
  asistencia agregada de la Cámara vs el contrato simétrico → PREGUNTA ABIERTA #1.
- #4 (falta insumo de la Cámara en main): NO — los 7 verificados en Fase 0.

## 7. Invariantes verificados

| Invariante | Estado |
|-----------|--------|
| R único lenguaje (toda inspección en R; 0 Python/curl+jq) | PASA |
| httr2/jsonlite en Fase 3; resto lectura de código/`.rds` | PASA |
| Identificadores como character | PASA |
| Naming sin tildes/ñ/espacios en archivos nuevos | PASA |
| NO modificar 32-39, config, pipeline | PASA |
| NO escribir normalizadores/pipeline (solo diagnóstico + propuesta) | PASA |
| NO tocar 20_insumos/, 40_salidas/, docs/ | PASA |
| NO decidir crosswalk (solo pares reales) | PASA |
| No inventar esquema (código + `.rds` real; lo dudoso marcado "a confirmar") | PASA |
| Rama design/contrato-datos; sin push/PR/merge | PASA |
| Cambios heredados no tocados ni incluidos | PASA |

## 8. Archivos nuevos (entregables)

- `50_documentacion/activa/contrato_datos_camara_senado.md` (documento principal)
- `30_procesamiento/31e_extraer_partidos_senado.R` (script auxiliar Fase 3)
- `50_documentacion/andamios/contrato_datos/senado_partidos_muestra.json` (muestra)
- `50_documentacion/andamios/logs/20260710_contrato_datos_log.md` (este)

Nota: el working tree traía cambios previos ajenos (estructura/backlog/decisiones/
traspasos y archivos de encargos); no se tocaron ni se incluyen en los commits.
