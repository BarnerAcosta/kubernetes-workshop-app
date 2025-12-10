# Script de Despliegue en Kubernetes
# Despliegue completo: Namespace, Secrets, ConfigMaps, MySQL, Backend y Frontend

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Despliegue de Aplicacion en Kubernetes" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# 1. Crear el Namespace
Write-Host "1. Creando Namespace..." -ForegroundColor Yellow
kubectl apply -f kubernetes/namespace.yaml
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al crear el namespace" -ForegroundColor Red
    exit 1
}
Write-Host "OK Namespace creado" -ForegroundColor Green
Write-Host ""

# 2. Aplicar Secret (credenciales de DB)
Write-Host "2. Creando Secret..." -ForegroundColor Yellow
kubectl apply -f kubernetes/secret.yaml
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al crear el secret" -ForegroundColor Red
    exit 1
}
Write-Host "OK Secret creado" -ForegroundColor Green
Write-Host ""

# 3. Aplicar ConfigMap
Write-Host "3. Creando ConfigMap..." -ForegroundColor Yellow
kubectl apply -f kubernetes/configmap.yaml
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al crear el configmap" -ForegroundColor Red
    exit 1
}
Write-Host "OK ConfigMap creado" -ForegroundColor Green
Write-Host ""

# 4. Desplegar MySQL
Write-Host "4. Desplegando MySQL..." -ForegroundColor Yellow
kubectl apply -f kubernetes/deployment-mysql.yaml
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al desplegar MySQL" -ForegroundColor Red
    exit 1
}
Write-Host "OK MySQL desplegado" -ForegroundColor Green
Write-Host ""

# 5. Service de MySQL
Write-Host "5. Creando Service de MySQL..." -ForegroundColor Yellow
kubectl apply -f kubernetes/service-mysql.yaml
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al crear el service de MySQL" -ForegroundColor Red
    exit 1
}
Write-Host "OK Service de MySQL creado" -ForegroundColor Green
Write-Host ""

Write-Host "Esperando a que MySQL este listo..." -ForegroundColor Yellow
kubectl rollout status deployment/mysql-deployment -n dev-app --timeout=3m
Write-Host "OK MySQL esta listo" -ForegroundColor Green
Write-Host ""

# 6. Deployment del Backend
Write-Host "6. Desplegando Backend..." -ForegroundColor Yellow
kubectl apply -f kubernetes/deployment-backend.yaml
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al desplegar el backend" -ForegroundColor Red
    exit 1
}
Write-Host "OK Backend desplegado" -ForegroundColor Green
Write-Host ""

# 7. Service del Backend
Write-Host "7. Creando Service del Backend..." -ForegroundColor Yellow
kubectl apply -f kubernetes/service-backend.yaml
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al crear el service del backend" -ForegroundColor Red
    exit 1
}
Write-Host "OK Service del Backend creado" -ForegroundColor Green
Write-Host ""

# 8. Deployment del Frontend
Write-Host "8. Desplegando Frontend..." -ForegroundColor Yellow
kubectl apply -f kubernetes/deployment-frontend.yaml
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al desplegar el frontend" -ForegroundColor Red
    exit 1
}
Write-Host "OK Frontend desplegado" -ForegroundColor Green
Write-Host ""

# 9. Service del Frontend
Write-Host "9. Creando Service del Frontend..." -ForegroundColor Yellow
kubectl apply -f kubernetes/service-frontend.yaml
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al crear el service del frontend" -ForegroundColor Red
    exit 1
}
Write-Host "OK Service del Frontend creado" -ForegroundColor Green
Write-Host ""

# 10. Ingress (opcional)
Write-Host "10. Creando Ingress..." -ForegroundColor Yellow
kubectl apply -f kubernetes/ingress.yaml
if ($LASTEXITCODE -ne 0) {
    Write-Host "Advertencia: Error al crear el ingress (puede ser normal si no tienes ingress controller)" -ForegroundColor Yellow
}
else {
    Write-Host "OK Ingress creado" -ForegroundColor Green
}
Write-Host ""

# 11. Verificar el rollout
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Verificando Despliegue..." -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Esperando rollout de MySQL..." -ForegroundColor Yellow
kubectl rollout status deployment/mysql-deployment -n dev-app --timeout=2m

Write-Host "Esperando rollout del backend..." -ForegroundColor Yellow
kubectl rollout status deployment/backend-deployment -n dev-app --timeout=2m

Write-Host "Esperando rollout del frontend..." -ForegroundColor Yellow
kubectl rollout status deployment/frontend-deployment -n dev-app --timeout=2m

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Estado Actual del Cluster" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "PODS:" -ForegroundColor Yellow
kubectl get pods -n dev-app
Write-Host ""

Write-Host "SERVICES:" -ForegroundColor Yellow
kubectl get services -n dev-app
Write-Host ""

Write-Host "DEPLOYMENTS:" -ForegroundColor Yellow
kubectl get deployments -n dev-app
Write-Host ""

Write-Host "INGRESS:" -ForegroundColor Yellow
kubectl get ingress -n dev-app
Write-Host ""

Write-Host "=====================================" -ForegroundColor Green
Write-Host "Despliegue Completado!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""
Write-Host "Aplicacion lista en:" -ForegroundColor Cyan
Write-Host "   Frontend: http://localhost" -ForegroundColor White
Write-Host "   Backend:  http://localhost:3000" -ForegroundColor White
Write-Host ""
Write-Host "Comandos utiles:" -ForegroundColor Cyan
Write-Host "  Ver logs del backend:" -ForegroundColor Yellow
Write-Host "    kubectl logs -f deployment/backend-deployment -n dev-app" -ForegroundColor White
Write-Host ""
Write-Host "  Ver logs de MySQL:" -ForegroundColor Yellow
Write-Host "    kubectl logs -f deployment/mysql-deployment -n dev-app" -ForegroundColor White
Write-Host ""
Write-Host "  Escalar el backend:" -ForegroundColor Yellow
Write-Host "    kubectl scale deployment backend-deployment --replicas=5 -n dev-app" -ForegroundColor White
Write-Host ""
Write-Host "  Ver todos los recursos:" -ForegroundColor Yellow
Write-Host "    kubectl get all -n dev-app" -ForegroundColor White
Write-Host ""
