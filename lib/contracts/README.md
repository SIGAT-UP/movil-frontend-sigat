# Contratos

El cliente Dart se genera desde el `openapi.json` que publica `backend-sigat` y
no se edita a mano.

```bash
cp ../../backend-sigat/contracts/openapi.json lib/contracts/
# generar con openapi_generator o el generador acordado por el equipo
```

El archivo del contrato se fija por versión; actualizarlo es un PR explícito.
