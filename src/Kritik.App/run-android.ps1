$AndroidSdk = "$env:LOCALAPPDATA\Android\Sdk"
$JavaSdk = "C:\Program Files\Android\Android Studio\jbr"

Write-Host "🚀 Iniciando despliegue en Android..." -ForegroundColor Cyan

dotnet build -t:Run -f net8.0-android -p:AndroidSdkDirectory="$AndroidSdk" -p:JavaSdkDirectory="$JavaSdk"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error en el despliegue." -ForegroundColor Red
    Write-Host "Si el error es 'INSTALL_FAILED_USER_RESTRICTED':" -ForegroundColor Yellow
    Write-Host "1. Abre 'Opciones de Desarrollador' en tu teléfono."
    Write-Host "2. Activa 'Instalar vía USB'."
    Write-Host "3. Asegúrate de que la pantalla esté encendida y acepta el permiso de instalación."
} else {
    Write-Host "✅ ¡App instalada con éxito!" -ForegroundColor Green
}
