#!/usr/bin/env bash
# Verificación obligatoria de la app antes de integrar cambios (la misma que ejecuta la CI).
# Uso (desde la carpeta vigilancia_durazno):  bash scripts/verificar_flutter.sh
# Deja la salida de cada paso en build/verificacion/ (no se versiona) y termina con error
# si algún paso falla. No usa credenciales: la compilación es debug.
set -uo pipefail
cd "$(dirname "$0")/.."
OUT=build/verificacion; mkdir -p "$OUT"
RESUMEN="$OUT/resumen.txt"
{ echo "fecha: $(date -u +%FT%TZ)"; flutter --version 2>&1 | head -4; } > "$RESUMEN"
fallos=0
paso() { # nombre, comando...
  local nombre=$1; shift
  echo "==> $nombre"
  if "$@" > "$OUT/$nombre.log" 2>&1; then echo "OK    $nombre" | tee -a "$RESUMEN"
  else echo "FALLA $nombre (ver $OUT/$nombre.log)" | tee -a "$RESUMEN"; fallos=$((fallos + 1)); fi
}
paso 1_pub_get        flutter pub get
paso 2_formato        dart format --output=none --set-exit-if-changed lib test
paso 3_analyze        flutter analyze
paso 4_test           flutter test
paso 5_build_debug    flutter build apk --debug
echo; cat "$RESUMEN"
exit "$fallos"
