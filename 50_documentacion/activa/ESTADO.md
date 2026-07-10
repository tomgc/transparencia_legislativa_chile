---
slug: transparencia_legislativa_chile
nombre_real: Transparencia Legislativa Chile
categoria: activo
semaforo: activo
sesion_actual: v03
ultima_actividad: 2026-07-10
maneja_sensibles: false
tipo_pendiente: nuevo
---
## En que vamos
Fase 2 completa: dashboard estatico (docs/index.html, vanilla, sin CDN, carga
perezosa, hemiciclo por tendencia con IND explicito) que consume el JSON, con
contenido legible (tipo_iniciativa, materias) y trazabilidad voto->proyecto (cada
voto de Proyecto de Ley enlaza a su proyecto; el 31,5% sin boletin queda null,
hueco estructural). Se corrigio la clave de cache (codifica el tope) y se
integraron las tres ramas a main (71ff7c3, fuente unica). Sin push (no hay remoto).

## Proximo paso
Sesion de DISENO (conversacional, no encargo a Claude Code) del sistema de
actualizacion y del versionado del corte temporal: el date-stamping (Sys.Date en
la clave) impide regenerar hoy sin re-descargar y cambiar conteos. Definir fuente,
procedimiento, canal sin tokens (Positron o GitHub Actions) y periodicidad.
Alternativa de orden: migrar a GitHub primero (protocolo 4.3) y disenar despues.

## Bloqueantes
Ninguno bloquea el estado actual (main integro y verificado). Limitacion activa
(no bloqueante del cierre, si del refresh futuro): el pipeline no se regenera hoy
sin drift por el date-stamping de la clave de cache. tipo_pendiente=nuevo: el
trabajo que encabeza el proximo arranque es diseno de funcionalidad/operacion
nueva (sistema de actualizacion), no un bug ni un bloqueante activo.
