# Cambios del móvil (app SIGAT Durazno)

Registro de cambios del código de la app Flutter. **El backend tiene su propio registro:**
`backend-sigat/CHANGELOG.md`.

El detalle de cada PR (diff, pruebas, capturas) vive en GitHub. Aquí queda la rationale de
nivel sprint y los pendientes, no los comentarios de una línea.

## Pendientes técnicos

1. **Resolución de operaciones en la app** — la bandeja de sincronización muestra el
   estado, pero no permite aceptar ni descartar: el backend no expone
   `POST /sincronizacion/operaciones/{oper_id}/resolucion` (Sprint 3).
2. **Bajada de cambios y paquete de campo** — `GET /sincronizacion/cambios` no está
   implementado; la app solo sube y consulta lo recibido.
3. **MTD/concepto** — sin recálculo ni reemisión en el teléfono; se resuelve en el
   backend.
4. **Autorreportes de productor y evidencias** — `push()` envía visita, lectura y
   justificación del técnico. Las aplicaciones y cosechas quedan en la cola local, y las
   evidencias fotográficas aún no salen del teléfono.

## Cierre del Sprint 2 (móvil)

### Formato de `lib` y `test`

- **Un commit mecánico** (`e9b2c02`, 152 archivos, +3859 / −1800): `dart format` en 135
  archivos de `lib/` y 17 de `test/`, más llaves en los `if` de una línea
  (`curly_braces_in_flow_control_structures`).
- **Único cambio no mecánico**: el comentario de la tabla de estado de la API separa lo
  que funciona de lo que responde 501. Sin cambios de lógica, rutas ni textos visibles.
- **Por qué**: el CI ejecuta `dart format --output=none --set-exit-if-changed lib test` y
  `develop` no lo pasaba (152 de 163 archivos fuera de formato desde el 30/10); cualquier
  PR quedaba en rojo. Se separó para que el revisor vea que es mecánico y para que el PR
  del sprint muestre solo su diff.
- **Pruebas**: 140 en verde sin código nuevo; `flutter analyze` sin errores (102 avisos de
  deprecación de `material.dart` que ya venían de `develop`); 0 archivos cambiados tras el
  commit.

### Sincronización del técnico

- **Envío por lote** (`POST /api/v1/sincronizacion/lotes`): visitas, lecturas y
  justificaciones en tandas de hasta 200; la visita va antes que sus lecturas y cada
  operación lleva un `cliente_id` estable derivado del dispositivo y del registro.
- **Bandeja de solo lectura** (`GET /api/v1/sincronizacion/operaciones`): clasificación,
  motivo y datos por operación.
- **Huella canónica** (`lib/core/utils/canonical_json.dart`): JSON determinista (claves
  ordenadas, números y cadenas como RFC 8785) y SHA-256 del sobre, para que el teléfono y
  el servidor calculen el mismo `hash_contenido`.
- **Resultado por operación**: el resumen separa confirmadas, en revisión, rechazadas y
  diferidas; solo se borra de la cola lo que el servidor confirmó y lo demás queda con el
  motivo.
- **Fecha real de observación**: `t_observacion` sale de `observedAt`, no del momento del
  envío; `t_captura` usa el mayor entre el reloj actual y la observación.
- **Leída / no leída**: una trampa no leída envía `lect_leida = false`, sin especímenes y
  con justificación; una leída con 0 es «cero moscas».
- **Sin rutas inventadas**: se quitaron las llamadas a `resolucion` y `cambios`, que el
  backend no expone (501) y quedan fuera del alcance.
- **Dependencia nueva**: `crypto` (SHA-256); los vectores de huella viven en el código y
  `test/vectores_huella.json` queda en `.gitignore` por ser generado.
- **Pruebas**: 140 en verde, 8 nuevas de JSON canónico y las de envío, idempotencia,
  lectura sin visita y bandeja; `test/support/backend_de_prueba.dart` cubre las dos rutas
  nuevas.
- **Integración**: el PR necesita el de formato; hasta esa fusión GitHub muestra sus 152
  archivos y después baja a los 21 propios.
