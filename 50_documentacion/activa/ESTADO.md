---
slug: transparencia_legislativa_chile
nombre_real: Transparencia Legislativa Chile
categoria: activo
semaforo: activo
sesion_actual: v06
ultima_actividad: 2026-07-10
maneja_sensibles: false
tipo_pendiente: deuda_tecnica
---
## En que vamos
La Camara sigue en produccion sin cambios (dashboard y refresh semanal operativos).
La sesion 6 fue de diseno: se confirmo con evidencia la fuente del Senado (backend
`web-back.senado.cl`, con ids estables, roster de 50 y asistencia nominal por sesion),
se fijaron tres decisiones de arquitectura y se produjo una propuesta de contrato de
datos comun con 8 preguntas abiertas. Dos hallazgos derogaron supuestos vigentes: los
ids de Camara y Senado son espacios distintos, y el extractor de asistencia de la
Camara descarta el detalle por sesion que la fuente si entrega.

## Proximo paso
Auditoria de cobertura de la fuente de la Camara (pendiente 12): verificar que expone
el web service que el pipeline NO esta tomando, antes de construir el Senado en
simetria con una base posiblemente incompleta.

## Bloqueantes
Ninguno bloqueante en sentido estricto. El pipeline del Senado (pendiente 7) esta
desbloqueado en cuanto a fuente, pero depende de tres pendientes previos: la auditoria
de cobertura de la Camara (12), el cierre del contrato de datos (13) y el crosswalk
partido->tendencia del Senado (9, decision del titular, no delegable).
