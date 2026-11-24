# Cambios del móvil (app SIGAT Durazno)

Registro de cambios del código de la app Flutter. **El backend tiene su propio registro:**
`backend-sigat/CHANGELOG.md`.

El detalle de cada PR (diff, pruebas, capturas) vive en GitHub. Aquí queda la rationale de
nivel sprint y los pendientes, no los comentarios de una línea.

## Sprint 3 · Fase 1: resumen del lote para el técnico

- **Ruta propia** `AppRoutes.lotsSummary = '/lots/summary'` (técnico), con argumento `String lotId`. No reutiliza `/agronomist/lot/summary`, que sigue siendo del agrónomo.
- **`LotSummaryScreen` por lote**: recibe `lotId` y consulta `getLotSummary(lotId)` en lugar de leer `AgronomistController.summary`. Sin `lotId` (entradas del agrónomo en el inicio y el perfil) usa el lote seleccionado, así que esas entradas no cambian.
- **Entrada desde el lote**: botón «Ver resumen del lote» en `LotDetailScreen`.
- **Sin conexión**: `ApiAgronomistRepository.getLotSummary` guarda la última respuesta por usuario y lote en `LotSummaryCache` (`SharedPreferences`, clave versionada `sigat.resumen_lote.v1`). Si la red falla, muestra esa copia con aviso y su fecha (`LotSummary.cachedAt`). Si nunca se consultó, muestra un error con reintento; nunca pantalla en blanco.
- **Pruebas**: `test/lot_summary_cache_test.dart` (ida y vuelta, aislamiento por usuario y lote, valor dañado).
- **Fuera de alcance (no tocado)**: paquete de campo, `MapaPredio`, GeoJSON, mapas y la Fase 2 (historial y `VisitDetailScreen`).

## Sprint 3 · Fase 2: historial con detalle de visita

- **Ruta** `AppRoutes.visitDetail = '/history/detail'` (técnico), con argumento `String visitId`. Cada visita del historial abre `VisitDetailScreen`.
- **Repositorio**: `HistoryRepository.getVisit(id)`. Las visitas del servidor se piden a `GET /visitas/{id}`; una visita que solo existe en el teléfono se lee de la cola local.
- **Sin conexión**: la última copia del detalle se guarda por usuario y visita (`VisitDetailCache`, clave versionada `sigat.detalle_visita.v1`) y se muestra con aviso y fecha.
- **Modelo**: `VisitRecord` gana predio, técnico, lotes (códigos), `estado_revision` (nombre del contrato; en la BD es `visi_estado_revision`), motivo de revisión y trampas leídas.
- **Pendiente**: el contrato no entrega estado por lote. La pantalla muestra la lista de lotes sin estado individual.

## Sprint 3 · Fase 3: paquete de campo con caché e invalidación

- **Cliente HTTP**: `ApiClient.getCondicional` envía `If-None-Match` y trata el **304** como respuesta válida (sin cuerpo, sin error).
- **Metadatos**: `PaqueteCampo` refleja `PaqueteCampoInfo` (versión, hash, fecha, invalidación, tamaño).
- **Persistencia**: `PaqueteCampoStore` guarda un paquete por predio con la clave versionada `sigat.paquete.v1.<predioId>`. Guardar reemplaza el anterior.
- **Descarga** (`ApiMapRepository.downloadMap`): pide `/paquete-campo`, compara versión y hash con la copia local y solo baja `/contenido` si cambió.
- **Invalidación** (`isMapDownloaded`): con red, si el servidor trae otra versión, otro hash o un paquete invalidado, borra la copia local. Sin red, considera descargado el predio si hay copia.
- **Interfaz**: `MapDownloadCard` y `MapScreen` ya cubren los estados; no cambiaron.
- **Fuera de alcance (no tocado)**: el bloque `mapa` (GeoJSON) del paquete se guarda tal cual llega y no se modela ni se expone. Queda para el equipo de mapas y el backend.
- **Riesgo conocido**: `SharedPreferences` no es un almacén ideal para paquetes grandes. Si el GeoJSON crece, conviene migrar a archivos.

## Sprint 3 · Fase 4: pruebas y fake backend

- **Fake backend** (`test/support/backend_de_prueba.dart`): paquetes de campo por predio con `ETag`, respuesta **304** con `If-None-Match` y el helper `paqueteDePrueba`. Para el detalle de visita y el resumen se usa `respuestasExtra` con las rutas `GET /visitas/{id}` y `GET /lotes/{id}/resumen`.
- **`test/detalle_visita_test.dart`**: detalle del servidor, copia con fecha sin red, error claro sin copia y resumen del lote sin red.
- **`test/paquete_campo_test.dart`**: descarga, no volver a bajar con el mismo hash, invalidación por hash o por `invalidado_en`, disponibilidad sin red, declaración de sin conexión y **304**.
- **Verificación**: `flutter test` con 158 pruebas en verde, `dart format` sin cambios, `flutter analyze` sin errores ni warnings (quedan 103 avisos de deprecación de `material.dart`) y APK debug compilado con `--android-skip-build-dependency-validation`.

## Sprint 3 · Paquete de campo: GeoJSON

- **Modelo tipado**: `MapaPredio`, `ColeccionGeo` y `FeatureGeo` siguen el `MapaPredio` del contrato (predio, lotes, celdas y trampas, EPSG:4326). La geometría se conserva para MapLibre.
- **Validación**: `downloadMap` comprueba la forma del mapa antes de guardar el paquete. Si no cuadra, no se guarda nada.
- **Acceso sin red**: `MapRepository.getMapaLocal(predioId)` devuelve el GeoJSON guardado, o null si el paquete no se descargó. Es el punto de entrada para MapLibre en el siguiente sprint.
- **Pruebas**: `test/mapa_predio_test.dart` (lectura sin red, sin paquete, forma inválida). El fixture del fake backend trae lotes y trampas.
- **Pendiente**: dibujar las capas en MapLibre y el mosaico satelital siguen fuera de este sprint.

## Cierre del Sprint 3 (móvil)

- **Rama**: `feature/sprint3-paqueteCampo`, sobre `develop` (`3ee8de3`).
- **Pruebas**: 158 en verde; se suman las de resumen con caché, detalle de visita, paquete de campo y forma del GeoJSON.
- **Formato y análisis**: 5 archivos se alinearon con `dart format`; se quitó una expresión nula muerta en `VisitDetailScreen`. `flutter analyze` queda sin errores ni warnings.
- **App en emulador**: resumen del lote accesible desde el detalle, historial con detalle y tarjeta de descarga con sus estados.
- **Backend local**: paquete `200` con ETag y `304`, visitas `200`, resumen `200`. El resumen devuelve MTD, umbral y fecha de efecto en `null` porque la semilla no trae lecturas, periodos ni umbral.
- **Fuera de alcance**: MapLibre, mosaicos, imágenes satelitales y dibujo de capas.
- **Pendiente de integración**: copiar `contracts/openapi.json` a `lib/contracts/`, repetir la descarga real en la app, prueba de modo avión, actualizar la tabla de estado de `api_repositories.dart` y dejar la CI del móvil en verde.

## Pendientes técnicos

1. **Resolución de operaciones en la app** — la bandeja de sincronización muestra el
   estado, pero no permite aceptar ni descartar: el backend no expone
   `POST /sincronizacion/operaciones/{oper_id}/resolucion` (Sprint 3).
2. **Bajada de cambios** — `GET /sincronizacion/cambios` sigue sin implementarse; el
   paquete de campo ya se descarga y se cachea, pero la app solo sube y consulta lo
   recibido.
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
