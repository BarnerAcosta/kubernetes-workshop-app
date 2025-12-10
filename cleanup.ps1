# Script para eliminar el despliegue de Kubernetes

Write-Host "=====================================" -ForegroundColor Red
Write-Host "Eliminando Aplicacion de Kubernetes" -ForegroundColor Red
Write-Host "=====================================" -ForegroundColor Red
Write-Host ""

$confirm = Read-Host "Estas seguro de eliminar todo el namespace 'dev-app'? (s/n)"

if ($confirm -eq "s" -or $confirm -eq "S") {
    Write-Host ""
    Write-Host "Eliminando namespace y todos sus recursos..." -ForegroundColor Yellow
    kubectl delete namespace dev-app
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Todos los recursos han sido eliminados" -ForegroundColor Green
        Write-Host ""
    }
    else {
        Write-Host ""
        Write-Host "Error al eliminar recursos" -ForegroundColor Red
        Write-Host ""
    }
}
else {
    Write-Host ""
    Write-Host "Operacion cancelada" -ForegroundColor Yellow
    Write-Host ""
}
