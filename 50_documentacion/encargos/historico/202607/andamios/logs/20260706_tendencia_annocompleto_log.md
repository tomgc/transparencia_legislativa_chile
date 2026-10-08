# Log de ejecucion — Tendencia + anno completo (sesion 2)

**Proyecto:** transparencia_legislativa_chile
**Fecha:** 2026-07-06
**Entorno:** Claude Code, macOS, R 4.5.2.
**Naturaleza:** andamio congelado (registro de ejecucion, no se actualiza).

## 1. Resumen de la sesion

Sesion CONTINUATION (segunda). Tres fases: (1) precisar en CLAUDE.md el alcance
del invariante R-only para cerrar la ambiguedad del traspaso v01 §15 error 2;
(2) poblar `MAPA_PARTIDO_TENDENCIA` con la clasificacion del titular (taxonomia
de 5 niveles, IND=NA); (3) correr el pipeline del anno completo (topes en Inf) y
regenerar el JSON con la tendencia propagada. `run_all()` corrio de cero en
sesion R limpia sin error. Auditoria adversarial EN R (sesion limpia, re-parseo
de la captura cruda con xml2 directo, mapa independiente): la distribucion de
tendencia re-derivada es identica al indice comprometido; indice==perfiles==
roster==155. Sin push (a la espera del visto bueno del titular). No se genero
traspaso v02 ni ESTADO (el cierre formal lo decide el titular).

## 2. Inventario de commits (locales, sin push)

| # | Hash | Tipo | Titulo |
|---|------|------|--------|
| 1 | `2ddd754` | docs | precisar alcance del invariante R-only (pipeline + verificacion) |
| 2 | `a11b3fb` | feat | clasificar tendencia de los 18 partidos (5 niveles, IND=NA) |
| 3 | `48e158c` | feat | correr anno completo (topes Inf) y regenerar JSON con tendencia |
| 4 | (este log) | docs | log andamio de la sesion 2 |

## 3. Cambios sustantivos

- **CLAUDE.md — invariante R-only precisado.** Alcance total: pipeline Y toda
  verificacion/auditoria/script auxiliar; la independencia adversarial se logra
  en R (sesion limpia, pull fresco, codigo desacoplado), nunca cambiando de
  lenguaje. Cierra el error 2 del traspaso v01 §15.
- **MAPA_PARTIDO_TENDENCIA poblado** con los valores exactos del titular
  (taxonomia de 5 niveles). IND queda NA deliberadamente. Verificado en R:
  `tendencia_de_partido()` sobre los 18 ids -> 0 NA salvo IND; helper sin cambios.
- **Topes a Inf (produccion).** Se agrego nota # REVISAR: la clave de `con_cache`
  no codifica el tope; cambiar un tope exige forzar el refresco.
- **Corrida del anno completo** con `options(camara.refrescar=TRUE)` (el cache de
  sesion 1 tenia los topes viejos 120/150; el refresco garantiza cobertura real).

## 4. Verificacion (en R, entre generacion y commit)

- `run_all()` de cero: 5 pasos, 0 errores, 167.9s.
- indice = 155 == perfiles = 155.
- Cobertura anno completo: **672 votaciones** (vs 120 en sesion 1) y **218
  mociones** de origen Camara (vs 150). 104160 registros de voto, 1313 de autoria.
- Distribucion de tendencia (indice): derecha 52, izquierda 26, centro 22,
  centroizquierda 17, centroderecha 13, NA 25. NA == solo militantes IND.
- Dominio de sentido de voto: {a_favor, en_contra, abstencion, dispensado,
  no_vota}; 0 valores fuera de `DOMINIO_VOTO`.
- Tamano de `40_salidas/json/`: 17 MB; perfil mas pesado 154 KB (`1059.json`).

## 5. Auditoria adversarial (en R, independiente del pipeline)

Script en sesion limpia que NO sourcea 10_utils ni 10_configuracion: re-parsea
la captura cruda `20_insumos/camara/20260706_diputados.rds` con xml2 directo,
usa una copia propia del mapa (del encargo, no del repo) y re-deriva la
distribucion de tendencia. Resultado: **identica** al indice comprometido;
indice==perfiles==roster==155; ids coinciden. Se cumple el invariante R-only
tambien en la verificacion (cero Python).

## 6. Verificacion de invariantes (🔒)

| Invariante | Estado | Evidencia |
|-----------|--------|-----------|
| R unico lenguaje (pipeline + verificacion) | PASA | pipeline y auditoria 100% R; 0 Python |
| Llaves como character | PASA | ids de diputado/partido como string en JSON e indice |
| Clasificacion de tendencia la fija el titular | PASA | valores copiados exactos del encargo; IND=NA por instruccion |
| Escritura atomica + validacion tras join | PASA | escribir_atomico + checks de cobertura/dominio/rango |

## 7. Pendientes abiertos / # REVISAR

- **Clave de cache sin tope** (nuevo # REVISAR, en `10_configuracion.R`): al
  cambiar un tope hay que forzar `camara.refrescar=TRUE` o el snapshot del dia
  se reutiliza con el tope viejo. Fix sugerido: codificar el tope (o "Inf") en
  la clave de `con_cache`. Fuera del alcance de esta sesion (encargo scoping).
- Huecos heredados de sesion 1 (sin cambios): distrito/region no expuestos;
  estado de tramitacion no expuesto; rol autor/coautor no jerarquizado.
- Asistencia por ANIO_PROCESO incluye la transicion de periodo (ene-mar 2026).

## 8. Notas para el revisor

- El cierre formal (traspaso v02 + ESTADO) queda pendiente por decision del
  titular. El log documenta el estado para ese cierre.
- Los 25 diputados con tendencia NA son exactamente los militantes IND
  (Independientes); es el comportamiento pedido, no un hueco de datos.
- La segmentacion por tendencia ya es utilizable en el JSON del dashboard.
