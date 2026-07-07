---
slug: transparencia_legislativa_chile
nombre_real: Transparencia Legislativa Chile
categoria: activo
semaforo: activo
sesion_actual: v01
ultima_actividad: 2026-07-06
maneja_sensibles: false
tipo_pendiente: nuevo
---
## En que vamos
Fase 1 completa: scaffold Rama A y pipeline R que extrae de la Camara
(opendata.camara.cl) roster, asistencia, votaciones y proyectos, y los
consolida en JSON estaticos (indice + 155 perfiles). `run_all()` corre de cero
sin error; auditoria adversarial 10/10. Sin push (a la espera del titular).

## Proximo paso
Que el titular clasifique la tendencia (izq/der) de los 18 partidos del roster
en `MAPA_PARTIDO_TENDENCIA`, y decidir si se corre el anno completo (topes en
Inf) antes de encarar la Fase 2 (dashboard).

## Bloqueantes
Ninguno para el pipeline. Diferido al titular: la clasificacion politica de los
partidos (tendencia hoy NA para los 155). Nota: `tipo_pendiente=nuevo` es el
default conservador para una decision metodologica que habilita una
segmentacion (no calza literal en el enum de prioridad de §1.2.4).
