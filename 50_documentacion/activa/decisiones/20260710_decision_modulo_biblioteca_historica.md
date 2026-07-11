# Decision — Modulo biblioteca historica de proyectos y votaciones

**Fecha:** 2026-07-10
**Sesion:** 5
**Estado:** pendiente de diseno (no iniciado). Registrado como pendiente 10.
**Tipo:** funcionalidad nueva (modulo), alcance Congreso completo.
**Relacion con otros pendientes:** depende parcialmente del pendiente 7
(agregar Senado); ver hitos abajo.

---

## Que es (en una frase)

Un modulo NUEVO del proyecto: una biblioteca con eje en el proyecto de ley y la
votacion como entidades de primera clase (no colgando de cada parlamentario),
que reune el historico completo de proyectos presentados y votaciones del que
haya registros, para el Congreso completo (Camara + Senado), y que en una fase
posterior se clasifica tematicamente para permitir busqueda por concepto.

## Que NO es (para no confundirlo en una sesion futura)

- NO reemplaza nada. El dashboard actual por-parlamentario (perfil de cada
  diputado con sus proyectos y votaciones) sigue intacto y funcionando. Este
  modulo se SUMA; ambos ejes coexisten.
- NO es una reestructuracion del pipeline existente. Es un modulo aparte que
  consume/reorganiza los mismos datos crudos hacia un contrato distinto.
- NO es solo Camara. El valor del modulo esta en cruzar ambas camaras; por eso
  el objetivo es Congreso completo.

## El problema que resuelve / el caso de uso

Hoy los datos estan organizados por parlamentario: para ver un proyecto hay que
entrar al perfil de quien lo presento o lo voto. El eje es la persona.

Este modulo invierte el eje: pone el proyecto y la votacion al centro. Sobre esa
biblioteca, una fase posterior clasifica los proyectos por tema/concepto. El
resultado buscado, en palabras del titular:

> "Buscar por ejemplo proyectos relacionados con el concepto de 'Familia' y
> apareceran las propuestas y como votaron. O el concepto 'Seguridad' y
> apareceran las propuestas y como votaron."

Es decir: entrada = un concepto tematico; salida = las propuestas de ese tema
mas el detalle de como voto cada parlamentario en las votaciones asociadas.

## Alcance del historico

El titular quiere "todos los proyectos propuestos y las votaciones historicas de
las que haya registros". Esto es una afirmacion de COBERTURA que NO se ha
verificado contra los datos reales y NO debe darse por supuesta (B.1). Lo que se
sabe hasta ahora, parcial, desde traspasos y backlog:

- La corrida del anno completo (backlog entrada 8) trajo 672 votaciones y 218
  mociones con topes de extraccion a Inf.
- El join voto->proyecto tiene cobertura 460/460 en Proyecto de Ley; el 31,5%
  sin boletin es estructural (backlog entrada 11).
- Todo lo anterior es SOLO Camara. Del Senado aun no hay datos (pendiente 7 /
  encargo de exploracion de API en curso al momento de registrar esto).

Pendiente de verificacion explicita como PRIMER paso del hito A: confirmar hasta
donde llega el historico real disponible (que periodos/legislaturas cubre la
fuente de la Camara, y luego la del Senado), y documentar los limites de
cobertura como parte del contrato del modulo, no como un detalle.

## Hitos (desglose acordado)

### Hito A — Corpus Camara al eje proyecto/votacion + verificacion de cobertura
Factible YA (no depende del Senado).
1. Verificar la cobertura historica real de la Camara: que periodos cubren los
   datos disponibles, si "todos los registros" es literal o hay un limite
   temporal de la fuente. Documentar los limites.
2. Disenar el contrato de datos del modulo con eje en el proyecto y en la
   votacion (no en el parlamentario): cada proyecto como entidad con sus autores,
   su tramitacion, sus materias; cada votacion como entidad con su resultado y el
   detalle nominal de como voto cada parlamentario.
3. Producir la biblioteca (JSON estaticos nuevos, coherentes con la arquitectura
   serverless del proyecto) SIN tocar los JSON del dashboard actual.

### Hito B — Extension a Senado + clasificacion tematica
Depende del pendiente 7 (Senado ya integrado).
4. Extender la biblioteca al corpus del Senado bajo el mismo contrato de datos
   comun.
5. Clasificar los proyectos tematicamente (definir la taxonomia de conceptos:
   "Familia", "Seguridad", etc. — decidir si es taxonomia cerrada curada, o
   derivada de las materias que la API ya expone, o hibrida). ESTA es la fase
   donde vive el valor central que el titular describe.
6. Habilitar la busqueda por concepto en el frontend: entrada = concepto,
   salida = proyectos del tema + como voto cada parlamentario.

## Insumos que ya existen y sirven al modulo

- El paso 36 (detalle de proyectos) ya expone `tipo_iniciativa` y `materias` por
  proyecto: las `materias` son candidatas naturales a insumo de la clasificacion
  tematica del hito B (evaluar si bastan o si se necesita una capa curada encima).
- El join estructurado voto->proyecto (VotacionProyectoLey/Id) ya resuelto para
  la Camara es exactamente el puente que el modulo necesita entre la entidad
  "votacion" y la entidad "proyecto".

## Decisiones abiertas para la sesion de diseno del modulo (no resolver ahora)

- Taxonomia tematica: cerrada curada vs. derivada de `materias` vs. hibrida.
- Si la clasificacion tematica es manual, asistida o automatica (y si automatica,
  con que criterio reproducible y auditable — coherente con el invariante de no
  fabricar datos).
- Como se relaciona la biblioteca con el dashboard actual en el frontend: seccion
  nueva del mismo sitio, o vista independiente.
- Contrato de datos comun Camara+Senado para las entidades proyecto y votacion
  (se define mejor junto con el diseno del pipeline del Senado, decision 2 del
  pendiente 7).

## Principios relevantes

- B.1 (sin supuestos implicitos): la cobertura historica se verifica, no se asume.
- Insumos-first: extraer el contrato de datos completo antes de escribir pipeline.
- No fabricar datos: materias/temas vacios se marcan explicitos, nunca inventados
  (mismo criterio que "Sin materias registradas" del dashboard actual).
- Modulo nuevo, no reemplazo: no se toca el pipeline ni los JSON existentes.
