---
slug: transparencia_legislativa_chile
nombre_real: Transparencia Legislativa Chile
categoria: activo
semaforo: activo
sesion_actual: v17
ultima_actividad: 2026-08-08
maneja_sensibles: false
tipo_pendiente: deuda_tecnica
---
## En que vamos

El paso 36 guardaba un derivado del parser dentro de la carpeta de dato crudo, asi
que el nodo `Votaciones` que la API ya entrega se perdia al parsear y la guarda de
autorregeneracion prometia regenerar sin red algo que no podia. Se corrigio de
raiz: la captura ahora es el XML tal cual bajo clave propia, el parser conserva los
14 campos reales del nodo, y el pipeline regenera los seis intermedios con 0
llamadas HTTP. El artefacto publicado quedo identico en 156 de 156 archivos
excluido el campo volatil. Una medicion posterior probo que el `Id` de votacion
particiona exactamente el universo (546 de 546 de tipo `Proyecto de Ley`), lo que
da a la entidad `proyecto` una llave directa donde hoy hay un regex sobre texto
libre.

## Proximo paso

Resolver P-74: el nodo rescatado crece con el tiempo y el sello valida corte
declarado y no contenido, asi que hay al menos un evento posterior al corte pasando
las seis compuertas sin ruido; es precondicion de P-66.

## Bloqueantes

Ninguno. 0 bugs activos, `main` sin PRs pendientes y `run_all()` completo en 12,4 s.
