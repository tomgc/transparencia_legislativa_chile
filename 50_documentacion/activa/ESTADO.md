---
slug: transparencia_legislativa_chile
nombre_real: Portal de transparencia legislativa de Chile
categoria: activo
semaforo: activo
sesion_actual: v22
ultima_actividad: 2026-08-13
maneja_sensibles: false
tipo_pendiente: bug
---
## En que vamos
La sesion 22 cerro P-86 y P-90 (el runner vigila siete intermedios y su mensaje de
recuperacion nombra el paso 37) y resolvio con P-92 la pregunta que el proyecto
arrastraba desde la sesion 16: existe eje tematico construible, derivado del sufijo del
numero de boletin, con cobertura de 427 de 427 boletines y 86 955 de 130 510 filas de
voto, y con brechas de 39 a 44 puntos entre izquierda y derecha en cinco areas del
periodo vigente. Quedo descubierto un bug activo que ninguna sesion habia visto: el
refresh semanal de produccion falla desde al menos el 2026-08-10, asi que el portal
lleva semanas sin actualizarse. Nada publicado cambio en la sesion.

## Proximo paso
Diagnosticar y reparar P-91, el refresh semanal caido, antes de construir la entidad
tematica sobre la via 1 (P-94).

## Bloqueantes
- P-91: el workflow `refresh-semanal.yml` falla en produccion con `6 de 6 intermedios
  NO corresponden al corte vigente`; causa raiz no establecida.
