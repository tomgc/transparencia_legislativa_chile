---
slug: transparencia_legislativa_chile
nombre_real: Transparencia Legislativa Chile
categoria: activo
semaforo: activo
sesion_actual: v02
ultima_actividad: 2026-07-06
maneja_sensibles: false
tipo_pendiente: nuevo
---
## En que vamos
Fase 1 completa y anno completo corrido: el pipeline R extrae de la Camara
(672 votaciones, 218 mociones, 155 diputados) y produce indice + 155 perfiles
con tendencia clasificada por el titular (5 niveles; los 25 IND quedan NA).
Auditoria adversarial en R: distribucion re-derivada identica al indice. Sin push.

## Proximo paso
Disenar y construir la Fase 2: dashboard estatico que consuma el JSON. Resolver
primero dos decisiones de diseno: (a) carga perezosa de perfiles (~17 MB en 155
archivos), (b) tratamiento de los 25 diputados IND sin tendencia en la vista
segmentada.

## Bloqueantes
Ninguno para el pipeline. Deuda tecnica menor pendiente: la clave de cache no
codifica el tope de extraccion (# REVISAR; forzar refresco al cambiar topes).
tipo_pendiente=nuevo: el trabajo que encabeza el proximo arranque es
funcionalidad nueva (dashboard Fase 2).
