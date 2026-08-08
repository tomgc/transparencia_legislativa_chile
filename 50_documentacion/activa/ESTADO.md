---
slug: transparencia_legislativa_chile
nombre_real: Transparencia Legislativa Chile
categoria: activo
semaforo: activo
sesion_actual: v16
ultima_actividad: 2026-08-08
maneja_sensibles: false
tipo_pendiente: nuevo
---
## En que vamos
La sesion 16 cerro cinco pendientes (P-58, P-61, P-62, P-64, P-65): el contrato legacy de asistencia quedo retirado en produccion, la auditoria de fuentes Camara/Senado se ejecuto completa con panel adversarial, y el orquestador gano una guarda que regenera los intermedios desalineados sin red. `main` esta en `f1584b8`, con 0 PRs abiertos, 0 bugs activos y `run_all()` corriendo completo en 12,1 s. El eje tematico quedo medido: NO por materias (la cadena voto - proyecto - materia cierra en 1,90 %), pero la entidad `proyecto` con tramitacion si es construible con cobertura 381 de 381.

## Proximo paso
P-63: dejar de descartar el nodo `Votaciones` que `retornarProyectoLey` ya trae y `parsear_contenido_proyecto()` descarta, sin ninguna llamada nueva a la API.

## Bloqueantes
ninguno
