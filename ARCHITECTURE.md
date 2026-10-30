# Arquitectura — vigilancia_durazno (app móvil SIGAT)

Flutter (Android, iOS). Habla solo con el backend `sigat-durazno-api` por `/api/v1` y trabaja sin conexión con una cola local.

## Capas

```
features/<pantalla>  ──▶  controladores (ValueNotifier/ChangeNotifier)  ──▶  AppServices (repositorios)
                                                                                 │
                                         ┌───────────────────────────────────────┼───────────────────┐
                                         ▼                                       ▼                   ▼
                              data/api/api_client.dart              data/local/pending_store.dart   data/photo_service.dart
                              (HTTP, Bearer, renovación)            (cola de pendientes + dueño)    (fotos validadas, sin EXIF)
```

| Carpeta | Responsabilidad |
|---|---|
| `lib/app/` | `app.dart`, rutas con nombre y rol dueño (`routes.dart`), pestañas por rol, pantalla de configuración inválida |
| `lib/core/` | Configuración (`api_config.dart`), tema, widgets genéricos, utilidades (`AppLog` no escribe nada en release) |
| `lib/data/api/` | `ApiClient` (sin redirecciones automáticas) y `SecureStore` (Keystore/Keychain) |
| `lib/data/local/` | `PendingStore` (cola persistente) y `RecordOwner` (dueño obligatorio de cada registro) |
| `lib/data/repositories/` | Contratos (`*_repository.dart`) e implementación contra el backend (`api_repositories.dart`) |
| `lib/data/image_metadata.dart` | Elimina EXIF/GPS, XMP y textos de JPEG, PNG y WebP sin recodificar |
| `lib/features/` | Pantallas por función y por rol (técnico, productor, agrónomo) |

## Trabajo sin conexión

1. Lo capturado se guarda en `PendingStore` con su dueño (`RecordOwner.requerido()`).
2. Cada usuario solo ve y envía lo suyo; sin sesión válida no se guarda nada.
3. Nada se marca como enviado sin confirmación del servidor. Hoy el backend no recibe sincronizaciones (`501`): los registros quedan «pendientes de enviar» con el motivo.

## Seguridad

- Tokens en almacenamiento seguro; logout que limpia todo aunque falle la red.
- Release solo con `API_URL` HTTPS; Android sin copias de seguridad y sin tráfico HTTP en release.

Documentación de integración: `docs/integracion/`.
