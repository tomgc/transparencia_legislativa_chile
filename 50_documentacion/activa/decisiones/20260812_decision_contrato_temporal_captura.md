# D31 — Qué afirma una captura sobre su propio alcance temporal

> **Fecha:** 2026-08-12. **Sesión de origen:** 18 (P-74, actos a y b).
> **Ratificada por el titular:** sesión 19. **Estado:** vigente.
> **Cierra:** P-78.

## Decisión

Desde P-74, una captura de `20_insumos/camara/` afirma sobre sí misma en qué
fecha real se descargó y si esa descarga cayó dentro del corte que su clave
declara. El pipeline se detiene antes de escribir una captura nueva cuya
descarga caiga fuera de ese corte, salvo excepción declarada de un solo uso,
que queda marcada en el propio registro.

Lo que una captura **sigue sin afirmar**:

- que su contenido quepa dentro del corte (eso se acota al derivar, solo en el
  paso 36 y solo por el borde superior);
- nada sobre las capturas anteriores al contrato, que quedan en `sin_registro`,
  un tercer estado que **no es conformidad**.

## Origen

La medición del acto (a) encontró un evento de votación posterior al corte
declarado y, sobre todo, encontró por qué: la captura del paso 36 se descargó
el 2026-08-08 bajo una clave que declaraba el corte 2026-08-03.
`corte_para_clave()` construye la clave desde `CORTE_FECHA` y no desde la fecha
de descarga, así que nada relacionaba una con otra. El problema no era el sello
sino la ventana entre descarga y corte declarado.

## Alternativas consideradas

- **(A) Filtrar al derivar, sin contrato.** Contenía el síntoma en un script y
  no impedía la reincidencia en otro paso. Se adoptó igual, pero como segundo
  anillo (contención), no como solución.
- **(B) Que el sello validara contenido.** Exigía ensanchar `validar_corte()`,
  hoy invariante, con un mapeo explícito intermedio → campo temporal que no
  puede ser genérico (`diputados` tiene un campo de fecha que no se compara con
  el corte).

## Justificación

(C) ataca la causa medida (que una clave declare un corte que su captura no
honra) y es la única de las tres que generaliza a los seis pasos sin tocar el
gate compartido.

## Tensión resuelta

A67 declaraba que el sello valida el corte declarado y no el contenido, lo que
sugería (B). La medición mostró que el exceso no lo producía el sello sino la
ventana entre descarga y corte: A67 sigue siendo cierto y deja de ser la causa.

## Implementación

En `10_utils/10_utils.R` (PR #8, mergeado en `b619a50`):

| Pieza | Función |
|---|---|
| `escape_captura_declarado()` | Lee `getOption`, **no** `Sys.getenv()`: una variable del shell no puede encender la excepción |
| `consumir_escape_captura()` | Apaga el escape al usarlo (un solo uso) |
| `guarda_captura_en_corte()` | Detiene la escritura de una captura cuya descarga cae fuera del corte, con mensaje accionable |
| `verificar_cierre_de_descarga()` | Vuelve a mirar el reloj después de descargar, por si el bucle cruzó la medianoche |
| `registrar_captura()` | Adhiere `descarga_fecha`, `descarga_inicio`, `descarga_fin`, `corte_fecha`, `escape` |
| `estado_temporal_captura()` | Clasifica en `dentro_de_corte`, `fuera_de_corte`, `sin_registro` |
| `reportar_estado_capturas()` | Reporta con denominador al cerrar la corrida |

Constantes nombradas: `ATRIBUTO_CAPTURA`, `OPCION_ESCAPE_CAPTURA`,
`ESTADOS_CAPTURA`. La opción de escape es
`camara.permitir_captura_fuera_de_corte`, apagada por defecto.

## Implicancias vigentes

- Las capturas anteriores al contrato quedan permanentemente en `sin_registro`,
  porque el crudo no se reescribe (D24).
- El reporte no distingue "no sabemos" de "sabemos que está mal", y al menos una
  captura previa está medida como descargada cinco días tarde. Cerrar esa
  distinción exige un registro lateral: **P-79**.
- La contención del borde superior cubre solo el paso 36 y solo el nodo
  `Votaciones`: **P-81**.

## Invariante derivado

La guarda del contrato temporal y su registro **no se aflojan sin decisión
explícita del titular**. `sin_registro` no se imputa, ni en el dato ni en la
presentación.
