---
slug: transparencia_legislativa_chile
nombre_real: Transparencia Legislativa Chile
categoria: activo
semaforo: activo
sesion_actual: v23
ultima_actividad: 2026-08-19
maneja_sensibles: false
tipo_pendiente: bug
---
## En que vamos
El portal volvio a publicar dato fresco: se mergearon los tres PR abiertos (refresh del 2026-08-17, fix del runner y sondeo tematico) y se refuto P-91, que resulto no ser un bug sino un run antiguo leido contra el arbol de hoy. La guarda que impide que un paso nuevo del pipeline quede sin registrar quedo construida, probada y en PR #19 sin mergear. Aparecio P-99: el bot no versiona las capturas del Senado, asi que la garantia de regenerar sin red no se cumple para el paso 37.
## Proximo paso
Mergear PR #19 y ejecutar el encargo de P-99 ya escrito, que hace que el workflow derive de R las rutas de crudo que versiona.
## Bloqueantes
ninguno
