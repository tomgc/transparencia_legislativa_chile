---
slug: transparencia_legislativa_chile
nombre_real: Transparencia Legislativa Chile
categoria: activo
semaforo: activo
sesion_actual: v11
ultima_actividad: 2026-07-25
maneja_sensibles: false
tipo_pendiente: nuevo
---
## En que vamos
La Capa 2 (territorio) esta en produccion: 155 de 155 diputados con distrito y region, mergeada en ac177be. La Capa 3 (asistencia simetrica) quedo construida, verificada y auditada por panel adversarial en la rama feat/capa3-asistencia: serie nominal de 8718 entradas con justificacion, dos ambitos de denominador y dos tasas que comparten base, sin alterar ningun campo que el portal en vivo consuma. El encargo de merge de la Capa 3 corria al cerrar la sesion.

## Proximo paso
Confirmar el estado real del merge de la Capa 3 (rama, log, divergencia, campos legacy intactos en produccion) y revisar el workflow de GitHub Actions contra la doble descarga de asistencia antes del refresh del lunes 27; luego abrir la sesion de frontend de asistencia.

## Bloqueantes
ninguno
