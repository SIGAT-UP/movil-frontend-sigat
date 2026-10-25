# mobile-sigat

Aplicación móvil del sistema de monitoreo fitosanitario del durazno (ICA).
Flutter + Dart, offline-first: la base local es la fuente de verdad en campo y
la cola de envío sincroniza cuando hay red.

## Estado

Esqueleto: aplicación mínima que arranca, tema, configuración de API por
`--dart-define` y el árbol de carpetas por feature. Falta generar las carpetas
de plataforma (`android/`, `ios/`), que requieren el SDK de Flutter.

## Puesta en marcha

```bash
flutter create . --platforms=android,ios --org co.ica --project-name sigat_mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

`flutter create .` completa `android/` e `ios/` sin sobrescribir `lib/`.

## Estructura

```text
lib/
├── main.dart
├── bootstrap.dart        arranque: base local, cola, configuración regional
├── app/                  app, router, tema y l10n
├── core/                 auth, config, error, network, storage, sync, location, time, ui
├── features/             un módulo por funcionalidad
│   └── <feature>/
│       ├── data/         dto, dao, remote, repositories
│       ├── domain/       entities, repositories, use_cases
│       └── presentation/ pages, controllers, widgets
└── contracts/            cliente Dart generado desde OpenAPI
```

Regla de dependencia:

```text
presentation → domain
data → domain
domain → nada de Flutter
core → nada de features
features → core, contracts
```

## Dependencias previstas

Se agregan al implementar cada capa:

| Necesidad | Paquete |
|---|---|
| Estado | `flutter_riverpod` |
| Rutas | `go_router` |
| HTTP | `dio` |
| Base local | `drift`, `sqlite3_flutter_libs` |
| Mapa | `maplibre_gl` |
| Conectividad | `connectivity_plus` |
| Rutas de archivos | `path_provider` |
| Modelos | `freezed_annotation`, `json_annotation` |

## Pruebas

```bash
flutter test
flutter test integration_test
```

## Distribución

No pasa por Coolify. Se compila como APK/IPA y se distribuye por GitHub
Releases, Firebase App Distribution o Play Store interno.

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.tudominio.com
```

El flujo `.github/workflows/build-apk.yml` construye el APK en cada push a
`main`. La firma se configura con secretos del repositorio, nunca en el código.
