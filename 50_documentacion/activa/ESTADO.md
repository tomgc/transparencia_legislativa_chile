---
proyecto: transparencia_legislativa_chile
semaforo: amarillo
sesion: 15
ultima_actividad: 2026-08-03
sensibilidad_datos: publica
tipo_pendiente: bloqueante
traspaso_vigente: 50_documentacion/traspasos/traspaso_cierre_v15.md
---

## En qué vamos

Portal serverless de transparencia legislativa de la Cámara de Diputados de Chile,
con las tres capas de datos en producción (votaciones, territorio y asistencia
nominal simétrica). La sesión 15 retiró el contrato legacy de asistencia: cinco
campos del bloque `asistencia` del perfil y `tasa_asistencia` del índice dejaron
de publicarse, y el extractor perdió su segunda descarga completa de la
asistencia por corrida. El cambio está verificado (1 058 008 claves comparadas,
cero diferencias en los campos sobrevivientes, panel adversarial de cuatro
agentes en verde) pero **no publicado**: vive en el PR #4, abierto y sin mergear,
porque cambia un contrato de datos público.

## Próximo paso

Resolver los dos PRs abiertos (P-58). El PR #4 y el PR #3 del bot tocan los
mismos 310 archivos de datos y conflictan en ambos órdenes, pero el conflicto es
de un solo hunk por archivo (`metadatos.generado`). Se resuelve por hunk.
Encadenado: lanzar la auditoría de fuentes Cámara/Senado (P-61), cuyo encargo ya
está escrito y solo hay que ejecutar.

## Bloqueantes

- **P-58** es el bloqueante activo: nada de lo hecho en la sesión 15 llega a
  producción hasta que se resuelva. Resolver el conflicto **a nivel de archivo**
  resucita el contrato legacy en 310 de 310 perfiles y deja el índice incoherente.
- Dos gatillos de protocolo encendidos y sin atender: 4bis (ordenación del
  repositorio, P-60) y 4ter (invariante de locale UTF-8, P-59).
- El pipeline del Senado sigue bloqueado a la espera de P-61.
