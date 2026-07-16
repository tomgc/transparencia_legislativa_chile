### Sesión 7 (2026-07-11) — Opus 4.8 — Auditoría de cobertura y diagnóstico de propósito

**24. Versionado de la memoria estructural del proyecto.**
Se detectó que los traspasos v04, v05 y v06, la carpeta `activa/decisiones/`
completa, los tres encargos de la sesión 6, el backlog con sus entradas 20-23 y el
`ESTADO.md` estaban sin versionar: existían únicamente en el working tree local. Se
commitearon a `main` como `fe0e226` (11 archivos, 2.430 inserciones). El hallazgo
surgió al notar que el escáner mostraba el mismo contenido desde dos ramas distintas,
lo que llevó a verificar con `git ls-tree` en lugar de con el escáner. Sin este
commit, un working tree perdido se llevaba tres sesiones de memoria del proyecto.
Categoría: integración / repo.

**25. Auditoría adversarial de cobertura del web service de la Cámara (cierra el pendiente 12).**
Encargo autónomo a Claude Code, solo lectura, en `explore/cobertura-camara`. Se
enumeró el catálogo ASMX completo (5 servicios, 49 operaciones; el pipeline consume
8), se descargó una respuesta real de cada endpoint (usado y no usado) con su muestra
en disco, y se sondearon parámetros y endpoints alternativos. Resultado: ~14 gaps
inventariados con evidencia, más una entidad completa sin cubrir (comisiones).
Confirma y extiende A23: la asistencia no solo entrega el detalle nominal por sesión y
la fecha, sino también la justificación por diputado. El panel adversarial detectó un
falso negativo del propio auditor (había enumerado los campos mirando solo el primer
item de la colección, que era un "Asiste" sin justificación). Confirma A24: la Cámara
estaba efectivamente sub-explorada. Categoría: diagnóstico / exploración.

**26. Diagnóstico de brecha entre el propósito declarado y lo entregado.**
Encargo autónomo a Claude Code, solo lectura, en `explore/diagnostico-proposito`.
Cuatro fases: join autoritativo votación-proyecto contra la fuente (490 boletines
consultados), estado real de lo publicado en `docs/data/`, análisis del frontend, y
mapa de fuentes alternativas de territorio (con búsqueda web). Panel adversarial de
dos agentes (uno técnico, uno "ciudadano adversarial" que recorrió el portal listando
las preguntas que no puede responder). Tres resultados principales: (a) se derogó la
hipótesis de que el regex del script 34 perdiera boletines — las cuatro cifras del
join autoritativo son d=460, c=0, a=0, b=212, de modo que el 31,5% de votaciones sin
boletín es estructural y el traspaso v03 tenía razón; (b) se midieron las brechas de
propósito con cifras (territorio 100% nulo en 155/155 perfiles; 32,9% de votos sin
proyecto legible; 0 de 1.311 proyectos con materia); (c) persiguiendo una discrepancia
menor no solicitada, se destapó un bug activo de reproducibilidad: el intermedio
`asistencia.rds` en disco no corresponde a lo publicado, por lo que `run_all(only=39)`
republicaría el dashboard con datos stale. Categoría: diagnóstico / exploración.
