# Decision — Barrido exploratorio de opendata.congreso.cl (datos complementarios)

**Fecha:** 2026-07-10
**Sesion:** 5
**Estado:** pendiente de exploracion (no iniciado). Registrado como pendiente 11.
**Prioridad:** BAJA (informacion complementaria, no bloquea nada del roadmap actual).
**Tipo:** exploracion / diagnostico de fuente.

---

## Que es (en una frase)

Un barrido exploratorio COMPLETO del portal de datos abiertos legislativos del
Congreso (`opendata.congreso.cl`) para inventariar TODO lo que expone, y descubrir
que datos complementarios podrian sumarse al proyecto que hoy ni siquiera estamos
considerando.

## Que NO es (para no confundirlo con el encargo v02 del Senado)

- NO es el encargo de exploracion del Senado v02
  (`encargo_exploracion_senado_v02.md`). Ese toca `opendata.congreso.cl` de pasada,
  con una pregunta ACOTADA: ¿resuelve asistencia, roster de 50 e ids estables del
  Senado? Ese encargo mira el portal solo por lo que necesita para el pipeline del
  Senado.
- ESTE pendiente es lo contrario: un inventario EXHAUSTIVO del portal completo,
  sin una pregunta previa estrecha. La pregunta es abierta: "¿que hay aqui que
  podria enriquecer el proyecto?".
- NO es urgente ni bloqueante. Es complementario: cualquier dato que aparezca se
  evalua despues como posible feature nuevo, no como requisito de lo ya planeado.

## El caso de uso

El proyecto hoy cubre, por parlamentario: asistencia, proyectos presentados,
proyectos votados y sentido del voto, perfil. El portal de datos abiertos del
Congreso podria exponer entidades que hoy no tocamos y que darian profundidad al
portal de transparencia. Candidatos plausibles a inventariar (lista NO exhaustiva,
a confirmar con el barrido real, sin asumir que existen):

- Comisiones y su composicion / asistencia a comisiones.
- Intervenciones en sala (quien hablo, sobre que).
- Dietas, asignaciones parlamentarias, gastos operacionales.
- Viajes / misiones al extranjero.
- Agenda legislativa, urgencias de proyectos.
- Indicaciones a proyectos.
- Tramitacion detallada (estados, plazos).
- Historico de periodos legislativos anteriores.
- Datos biograficos / patrimonio / intereses declarados.

El valor: identificar 2-3 features complementarios de alto interes-publico y bajo
costo de integracion, para el backlog de mejoras del proyecto.

## Alcance del pendiente

1. Barrido completo del portal `opendata.congreso.cl`: mapear todas las secciones,
   endpoints, datasets descargables, formatos (XML/JSON/CSV/bulk), y cobertura
   (¿Camara, Senado, ambos? ¿que periodos?).
2. Por cada dataset relevante: una nota de que contiene, en que formato, con que
   llaves, y si se cruza con lo que el proyecto ya tiene (por id de parlamentario).
3. Producir un catalogo/inventario del portal como documento, con una seccion final
   de RECOMENDACION: que 2-3 datasets complementarios valdria la pena integrar y
   por que (interes publico vs. costo de integracion).
4. NO integrar nada: es solo diagnostico. La integracion de cualquier dataset es
   una decision posterior y un pendiente aparte.

## Relacion con otros pendientes

- Se beneficia de correr DESPUES del encargo v02, que ya habra tocado el portal y
  dejado documentado como se consume (protocolo, ids). El barrido completo puede
  reusar ese conocimiento de acceso en vez de redescubrirlo.
- Cualquier dato complementario que aparezca se evalua contra el modulo biblioteca
  (pendiente 10) y el pipeline del Senado (pendiente 7): si un dataset del portal
  simplifica alguno, sube su prioridad; si no, queda como mejora futura.

## Por que prioridad baja

La informacion es complementaria: enriquece, no completa un hueco del contrato
actual ni desbloquea otro pendiente. El roadmap vigente (Senado, modulo biblioteca)
no depende de esto. Se aborda cuando haya holgura, no antes.

## Principios relevantes

- Insumos-first: inventariar la fuente completa antes de decidir que integrar.
- B.1 (sin supuestos): los datasets candidatos listados arriba son hipotesis a
  confirmar contra el portal real, no cosas que damos por existentes.
- No fabricar cobertura: lo que el portal no exponga se reporta como ausente.
