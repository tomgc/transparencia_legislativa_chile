# Log acumulativo de cierres de sesión

> Un archivo, una sección por cierre, anexada al final. Las secciones previas no
> se editan. Reemplaza al esquema de un log por cierre (instrumento
> `cierre_sesion_autonomo_cc_v4.md`, F9.1): proyectado a cientos de sesiones,
> aquel poblaba `andamios/logs/` sin límite.

## v18 — 2026-08-12

Paquete: `paquete_cierre_v18.md` (57.961 bytes, md5 `100c69f63d8967a74b30bbcbe26dfefc`).
`push_autorizado: no` · `sello_escaner: regenerar` · `backlog_ultimo_previo: 52`.

### Fases

| Fase | Resultado | Evidencia |
|---|---|---|
| F0.1 | OK | `.git/` y `50_documentacion/traspasos/` presentes |
| F0.2 | OK | 1 paquete; 7 de 7 campos del front matter; 0 placeholders; 3 bloques abren y cierran |
| F0.3 | OK | `raiz_proyecto` == `pwd` == `/Users/tomgc/Projects/transparencia_legislativa_chile` |
| F0.4 | OK | vigente v17, máximo en `archivo/` v16 → siguiente **v18**, igual al front matter y al nombre del paquete |
| F0.5 | OK | último número real en disco **52** (grep sobre el detalle cronológico), igual al declarado |
| F0.6 | **FALLÓ y detuvo** (primer intento) | `M SETTINGS_Y_PROMPTS_OPERACIONALES.md`, 392 inserciones / 9 supresiones, fuera de las salidas del escáner |
| F0 (2.º intento) | OK | tras el commit `4f50b5b` del titular, `50_documentacion/` limpio salvo el paquete |
| F1 | OK | escáner regenerado; sello **20260812_215927**; podados los dos archivos de `20260808_082255` |
| F2 | OK | `git mv` de v17 a `archivo/` (`R100`); 0 traspasos planos rezagados |
| F3 | OK | `vigentes=1`; cuerpo idéntico byte a byte al bloque (diff vacío sobre 678 líneas) |
| F4 | OK | 21 cambios aplicados; 15 anclajes con ocurrencia única verificada antes de escribir |
| F5 | OK | `ESTADO.md` idéntico al bloque (33 líneas) |
| F6 | OK | 0 hallazgos en los 4 greps sobre los 3 archivos |
| F7 | OK | stage acotado; diff paquete↔destino vacío en los 3 bloques; paquete eliminado |
| F8 | local | `push_autorizado: no`; commit queda sin publicar |
| F9 | OK | esta sección, anexada antes de F7 y commiteada junto al resto |

### Verificaciones con cifra

- **Cifras del backlog recomputadas en R antes de escribirlas**, como exigía el
  propio delta: **10 de 10** filas coinciden con lo declarado, suma de la columna
  **56**, suma de porcentajes **100,0**. Ninguna cifra se escribió sin recomputar.
- Numeración: último previo **52**, primera nueva **53**, nuevas **53-55**, último
  ahora **55**, **0** duplicados, contiguo 1..55 sin huecos.
- Intangibilidad: las **651** líneas de las entradas 1-52 idénticas por contenido.
- Distribución: los tres bloques verificados por diff contra su destino antes de
  eliminar el vehículo.

### Desviaciones

1. **Delimitadores del paquete.** El paquete usa `<!-- destino: <ruta> -->` +
   `# BEGIN <BLOQUE>` … `# END <BLOQUE>` en vez de los `<<<BLOQUE destino: …>>>`
   que especifica el §2 del instrumento. No se detuvo: los tres bloques abren y
   cierran, y los tres destinos coinciden con los esperados, así que no había
   ambigüedad que interpretar. Anotado además en el §16 del traspaso por
   instrucción del titular.
2. **`traspaso_nuevo` como ruta.** El front matter trae
   `50_documentacion/traspasos/traspaso_cierre_v18.md` donde el §2 especifica
   `v<NN>`. Inequívoco; no detuvo.
3. **Línea añadida al bloque TRASPASO.** El §7 del instrumento prohíbe editar
   bloques del paquete. El titular instruyó explícitamente anexar un bullet al
   final del §16 (Fricciones) sobre la desviación 1. Se ejecutó su texto verbatim;
   el resto del bloque quedó idéntico byte a byte, verificado por diff.
4. **Parada en F0.6 y su resolución.** El titular commiteó `SETTINGS` por separado
   (`4f50b5b`) y autorizó el paso a `main` antes de reanudar.
5. **Rama.** El working tree venía de `fix/guarda-bot-primera-corrida`, ya
   mergeada. El cierre se ejecutó sobre `main` tras `checkout` + `pull`, con
   `3f01124` (merge del PR #10) verificado como ancestro.

### Pendientes fuera de scope detectados

- Las 6 capturas del corte 2026-08-09 que produjo la descarga no solicitada siguen
  en cuarentena fuera del repo (`scratchpad/cuarentena/capturas_20260809/`), sin
  borrar y sin decisión del titular.
- El escáner podó `20260808_082255_*`; la poda es comportamiento propio del
  escáner, no del cierre.
