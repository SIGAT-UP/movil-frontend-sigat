# Verificación obligatoria de la app (Windows PowerShell). Igual que scripts/verificar_flutter.sh.
# Uso (desde la carpeta vigilancia_durazno):  powershell -ExecutionPolicy Bypass -File scripts\verificar_flutter.ps1
$ErrorActionPreference = 'Continue'
Set-Location (Join-Path $PSScriptRoot '..')
$out = 'build\verificacion'; New-Item -ItemType Directory -Force $out | Out-Null
$resumen = Join-Path $out 'resumen.txt'
"fecha: $((Get-Date).ToUniversalTime().ToString('s'))Z" | Set-Content $resumen
(flutter --version 2>&1 | Select-Object -First 4) | Add-Content $resumen
$fallos = 0
$pasos = @(
  @('1_pub_get',     'flutter pub get'),
  @('2_formato',     'dart format --output=none --set-exit-if-changed lib test'),
  @('3_analyze',     'flutter analyze'),
  @('4_test',        'flutter test'),
  @('5_build_debug', 'flutter build apk --debug')
)
foreach ($p in $pasos) {
  Write-Host "==> $($p[0])"
  cmd /c "$($p[1]) > $out\$($p[0]).log 2>&1"
  if ($LASTEXITCODE -eq 0) { "OK    $($p[0])" | Tee-Object -FilePath $resumen -Append }
  else { "FALLA $($p[0]) (ver $out\$($p[0]).log)" | Tee-Object -FilePath $resumen -Append; $fallos++ }
}
Get-Content $resumen
exit $fallos
