
---
slug: transparencia_legislativa_chile
nombre_real: Transparencia Legislativa Chile
categoria: activo
semaforo: activo
sesion_actual: v18
ultima_actividad: 2026-08-12
maneja_sensibles: false
tipo_pendiente: deuda_tecnica
---
## En que vamos

La sesion 18 cerro P-74 en dos actos: midio el alcance temporal del nodo
`Votaciones` y luego implanto un contrato por el que una captura declara su fecha
real de descarga y el pipeline se detiene si esa descarga cae fuera del corte que su
clave dice (D31). Al verificar ese trabajo contra el bot semanal aparecio que estaba
roto desde el PR #6 por una guarda circular, con una corrida programada ya fallida en
produccion; se reparo y se verifico de punta a punta con una corrida real de 10 de 10
pasos. El proyecto queda sin bugs activos, con el refresh automatico restituido y con
`CORTE_FECHA` en 2026-08-12.

## Proximo paso

Cerrar en un solo PR las dos deudas declaradas del PR #9: que el escape de la guarda
de primera corrida se consuma al usarse (hoy es asimetrico con el de D31) y que
borrar los intermedios sin tener capturas del corte no derive en una descarga
silenciosa.

## Bloqueantes

ninguno

