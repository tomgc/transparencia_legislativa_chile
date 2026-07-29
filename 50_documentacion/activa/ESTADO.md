---
slug: transparencia_legislativa_chile
nombre_real: Portal de Transparencia Legislativa (Camara de Diputadas y Diputados)
categoria: activo
semaforo: activo
sesion_actual: v14
ultima_actividad: 2026-07-27
maneja_sensibles: false
tipo_pendiente: deuda_tecnica
---
## En que vamos
Las tres capas estan en produccion y la Capa 3 de asistencia ya es visible en la
ficha: el portal dejo de mostrar solo los cinco campos legacy y publica ahora la
presencia del periodo vigente como titular, la tasa que suma las inasistencias
justificadas como segunda lectura, el tercer estado `sin_registro` sin imputar y
la serie nominal de sesiones con su glosa de justificacion. La decision
metodologica P7, abierta desde la sesion 11, quedo resuelta. El refresh semanal
corre solo, commitea en rama y abre PR; el del 2026-07-27 ya se mergeo y no hay
PRs abiertos ni bugs activos.

## Proximo paso
P-48: retirar el contrato legacy de asistencia (cinco campos del bloque
`asistencia` y `tasa_asistencia` del indice) del `39` y la doble descarga del
`33`, en sesion dedicada, encadenando P-52 y P-56.

## Bloqueantes
Ninguno.
