---
slug: transparencia_legislativa_chile
nombre_real: Transparencia Legislativa Chile
categoria: activo
semaforo: activo
sesion_actual: v12
ultima_actividad: 2026-07-25
maneja_sensibles: false
tipo_pendiente: deuda_tecnica
---
## En que vamos
Las tres capas del portal estan en produccion: presentacion (Capa 1), territorio
(Capa 2, `ac177be`) y asistencia simetrica (Capa 3, `70263cf`, confirmada esta
sesion con cuatro verificaciones en verde y cero campos legacy alterados). La
sesion 12 no toco codigo del pipeline: confirmo el estado que la 11 dejo en vuelo,
midio el workflow semanal contra la doble descarga de asistencia (sin riesgo para
el refresh del lunes) y salda la deuda de memoria mayor del proyecto, consolidando
el backlog acumulativo de cinco sesiones en un canonico al dia de 34 entradas.

## Proximo paso
P-22: que el bot de refresh semanal trabaje en rama y abra PR en vez de escribir
directo en `main`. Antes, confirmar dos hechos que quedaron sin verificar al
cerrar: el push del commit `a527a95` y el hash del commit del `timeout-minutes`.

## Bloqueantes
Ninguno estructural. Dos verificaciones pendientes con fecha: el push de `a527a95`
(el bot corre el lunes 27; si no se publica antes, la proxima sesion abre
resolviendo divergencia) y el commit del `timeout-minutes` en el workflow.
