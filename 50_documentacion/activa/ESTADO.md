---
slug: transparencia_legislativa_chile
nombre_real: Transparencia Legislativa Chile
categoria: activo
semaforo: activo
sesion_actual: v07
ultima_actividad: 2026-07-11
maneja_sensibles: false
tipo_pendiente: bug
---
## En que vamos
Sesion de diagnostico puro: no se toco codigo de produccion. Se cerro el pendiente 12 (auditoria adversarial de la fuente de la Camara: 49 operaciones expuestas, el pipeline usa 8, ~14 gaps inventariados con muestra real) y se levanto un diagnostico de brecha entre el proposito declarado del portal y lo que entrega. Se derogo una hipotesis del asistente (el regex del 34 NO pierde boletines: el 31,5% de votos sin proyecto es estructural) y aparecio un bug real no buscado: el intermedio asistencia.rds esta desincronizado de lo publicado.

## Proximo paso
Corregir P-15 (correr run_all(only=39) hoy republicaria el dashboard con asistencia stale) y luego construir la ruta de desarrollo en cuatro capas con las cifras del diagnostico.

## Bloqueantes
ninguno (P-15 es un bug activo, no un bloqueante externo: es ejecutable ahora)
