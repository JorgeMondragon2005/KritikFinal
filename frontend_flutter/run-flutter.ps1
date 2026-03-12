# run-flutter.ps1
Write-Host "🚀 Iniciando Kritik en Flutter..." -ForegroundColor Cyan

# Asegurarse de estar en el directorio correcto
if (!(Test-Path "pubspec.yaml")) {
    Write-Host "❌ Error: Ejecuta este script desde la carpeta 'frontend_flutter'" -ForegroundColor Red
    exit
}

Write-Host "📦 Verificando dependencias..." -ForegroundColor Yellow
flutter pub get

Write-Host "📱 Buscando dispositivos..." -ForegroundColor Yellow
flutter devices

Write-Host "🏗️ Compilando y ejecutando..." -ForegroundColor Green
flutter run

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n⚠️  Si ves 'INSTALL_FAILED_USER_RESTRICTED':" -ForegroundColor Yellow
    Write-Host "1. En tu teléfono: Opciones de Desarrollador > Activar 'Instalar vía USB'."
    Write-Host "2. Mantén la pantalla encendida y ACEPTA el permiso que aparecerá."
}
