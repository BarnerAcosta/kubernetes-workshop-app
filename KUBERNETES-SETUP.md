# 🚀 Guía de Despliegue en Kubernetes

## Prerequisitos

Necesitas tener un cluster de Kubernetes funcionando. Tienes varias opciones:

### Opción 1: Docker Desktop con Kubernetes (Recomendado para Windows)

1. Abre **Docker Desktop**
2. Ve a **Settings** → **Kubernetes**
3. Marca la opción **Enable Kubernetes**
4. Click en **Apply & Restart**
5. Espera a que aparezca "Kubernetes is running" (tarda unos minutos)

### Opción 2: Minikube

```powershell
# Instalar Minikube con Chocolatey
choco install minikube

# O descargar desde: https://minikube.sigs.k8s.io/docs/start/

# Iniciar cluster
minikube start --driver=docker

# Verificar
minikube status
```

### Opción 3: Kind (Kubernetes in Docker)

```powershell
# Instalar Kind con Chocolatey
choco install kind

# O descargar desde: https://kind.sigs.k8s.io/

# Crear cluster
kind create cluster --name dev-cluster

# Verificar
kubectl cluster-info --context kind-dev-cluster
```

## Verificar que Kubernetes está funcionando

```powershell
# Verificar versión de kubectl
kubectl version --client

# Verificar conexión al cluster
kubectl cluster-info

# Ver nodos
kubectl get nodes
```

Deberías ver algo como:

```
NAME             STATUS   ROLES           AGE   VERSION
docker-desktop   Ready    control-plane   1d    v1.28.2
```

## 🏗️ Construcción de Imágenes Docker

Las imágenes ya están construidas si ejecutaste:

```powershell
cd C:\dev-k8s-app

# Backend
docker build -t backend:1.0.0 ./backend

# Frontend
docker build -t frontend:1.0.0 ./frontend

# Verificar
docker images | Select-String -Pattern "backend|frontend"
```

### Importante para Minikube

Si usas Minikube, necesitas cargar las imágenes en su registro interno:

```powershell
# Cargar imágenes en Minikube
minikube image load backend:1.0.0
minikube image load frontend:1.0.0

# Verificar
minikube image ls | Select-String -Pattern "backend|frontend"
```

### Importante para Kind

Si usas Kind, necesitas cargar las imágenes en el cluster:

```powershell
# Cargar imágenes en Kind
kind load docker-image backend:1.0.0 --name dev-cluster
kind load docker-image frontend:1.0.0 --name dev-cluster
```

## 🚀 Despliegue en Kubernetes

### Método 1: Script Automatizado (Recomendado)

```powershell
cd C:\dev-k8s-app
.\deploy.ps1
```

Este script hace todo automáticamente en el orden correcto:

1. ✅ Crea el namespace `dev-app`
2. ✅ Crea el Secret con credenciales de DB
3. ✅ Crea el ConfigMap con variables de entorno
4. ✅ Despliega el Backend (3 réplicas)
5. ✅ Crea el Service del Backend
6. ✅ Despliega el Frontend (2 réplicas)
7. ✅ Crea el Service del Frontend
8. ✅ Crea el Ingress (opcional)
9. ✅ Verifica el rollout
10. ✅ Muestra el estado del cluster

### Método 2: Manual (Paso a paso)

```powershell
cd C:\dev-k8s-app

# 1. Crear Namespace
kubectl apply -f kubernetes/namespace.yaml

# 2. Crear Secret
kubectl apply -f kubernetes/secret.yaml

# 3. Crear ConfigMap
kubectl apply -f kubernetes/configmap.yaml

# 4. Desplegar Backend
kubectl apply -f kubernetes/deployment-backend.yaml
kubectl apply -f kubernetes/service-backend.yaml

# 5. Desplegar Frontend
kubectl apply -f kubernetes/deployment-frontend.yaml
kubectl apply -f kubernetes/service-frontend.yaml

# 6. (Opcional) Crear Ingress
kubectl apply -f kubernetes/ingress.yaml
```

## 📊 Verificar el Despliegue

```powershell
# Ver todos los recursos
kubectl get all -n dev-app

# Ver pods
kubectl get pods -n dev-app

# Ver servicios
kubectl get services -n dev-app

# Ver deployments
kubectl get deployments -n dev-app

# Verificar rollout del backend
kubectl rollout status deployment/backend-deployment -n dev-app

# Verificar rollout del frontend
kubectl rollout status deployment/frontend-deployment -n dev-app
```

Deberías ver algo como:

```
NAME                                      READY   STATUS    RESTARTS   AGE
pod/backend-deployment-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
pod/backend-deployment-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
pod/backend-deployment-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
pod/frontend-deployment-xxxxxxxxx-xxxxx   1/1     Running   0          1m
pod/frontend-deployment-xxxxxxxxx-xxxxx   1/1     Running   0          1m
```

## 🌐 Acceder a la Aplicación

### Docker Desktop o Kubernetes local

```powershell
# Ver la IP del servicio frontend
kubectl get service frontend-service -n dev-app
```

Si el tipo es **LoadBalancer**, espera a que aparezca una EXTERNAL-IP.

### Minikube

```powershell
# Obtener URL del servicio
minikube service frontend-service -n dev-app --url

# O abrir en el navegador automáticamente
minikube service frontend-service -n dev-app
```

### Kind o sin LoadBalancer

Si no tienes LoadBalancer, usa port-forward:

```powershell
# Forward del frontend al puerto local 8080
kubectl port-forward -n dev-app service/frontend-service 8080:80

# Abre en el navegador: http://localhost:8080
```

## 📝 Ver Logs

```powershell
# Logs del backend
kubectl logs -f deployment/backend-deployment -n dev-app

# Logs del frontend
kubectl logs -f deployment/frontend-deployment -n dev-app

# Logs de un pod específico
kubectl logs <nombre-del-pod> -n dev-app

# Ver eventos
kubectl get events -n dev-app --sort-by='.lastTimestamp'
```

## 📈 Escalar la Aplicación

```powershell
# Escalar backend manualmente a 5 réplicas
kubectl scale deployment backend-deployment --replicas=5 -n dev-app

# Escalar frontend a 3 réplicas
kubectl scale deployment frontend-deployment --replicas=3 -n dev-app

# Verificar
kubectl get pods -n dev-app
```

## 🔄 Actualizar la Aplicación (Rolling Update)

```powershell
# 1. Reconstruir imagen con nueva versión
docker build -t backend:1.1.0 ./backend

# 2. Si usas Minikube, cargar la nueva imagen
minikube image load backend:1.1.0

# 3. Actualizar el deployment
kubectl set image deployment/backend-deployment backend=backend:1.1.0 -n dev-app

# 4. Monitorear el rollout
kubectl rollout status deployment/backend-deployment -n dev-app

# 5. Ver historial de rollouts
kubectl rollout history deployment/backend-deployment -n dev-app

# 6. Rollback si algo falla
kubectl rollout undo deployment/backend-deployment -n dev-app
```

## 🛠️ Troubleshooting

### Los pods no inician (ImagePullBackOff)

```powershell
# Verificar que las imágenes existen localmente
docker images | Select-String -Pattern "backend|frontend"

# Para Minikube, asegúrate de cargar las imágenes
minikube image load backend:1.0.0
minikube image load frontend:1.0.0

# Para Kind
kind load docker-image backend:1.0.0 --name dev-cluster
kind load docker-image frontend:1.0.0 --name dev-cluster
```

### Ver detalles de un pod que falla

```powershell
# Describir el pod
kubectl describe pod <nombre-del-pod> -n dev-app

# Ver logs
kubectl logs <nombre-del-pod> -n dev-app

# Entrar al pod (si está corriendo)
kubectl exec -it <nombre-del-pod> -n dev-app -- /bin/sh
```

### El servicio no responde

```powershell
# Verificar que los pods están corriendo
kubectl get pods -n dev-app

# Verificar endpoints del servicio
kubectl get endpoints -n dev-app

# Probar conectividad desde dentro del cluster
kubectl run test-pod --image=busybox -n dev-app -it --rm -- wget -O- http://backend-service
```

## 🧹 Limpiar/Eliminar el Despliegue

### Método 1: Script Automatizado

```powershell
.\cleanup.ps1
```

### Método 2: Manual

```powershell
# Eliminar todo el namespace (elimina todos los recursos)
kubectl delete namespace dev-app

# O eliminar recursos individualmente
kubectl delete -f kubernetes/
```

## 🔍 Comandos Útiles

```powershell
# Ver todos los namespaces
kubectl get namespaces

# Ver todos los recursos en dev-app
kubectl get all -n dev-app

# Describir un deployment
kubectl describe deployment backend-deployment -n dev-app

# Ver uso de recursos
kubectl top pods -n dev-app
kubectl top nodes

# Editar un deployment en vivo
kubectl edit deployment backend-deployment -n dev-app

# Ver ConfigMap
kubectl get configmap backend-config -n dev-app -o yaml

# Ver Secret (decodificado)
kubectl get secret db-credentials -n dev-app -o jsonpath='{.data.username}' | base64 -d
```

## 🎯 Próximos Pasos

1. **Agregar MySQL** como StatefulSet o usar un servicio externo
2. **Configurar Ingress** con un dominio real
3. **Habilitar HPA** (Horizontal Pod Autoscaler)
4. **Implementar CI/CD** con GitHub Actions
5. **Agregar Monitoring** con Prometheus + Grafana
6. **Implementar Logging** con ELK Stack

## 📚 Recursos Adicionales

- [Documentación de Kubernetes](https://kubernetes.io/docs/)
- [Kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Minikube](https://minikube.sigs.k8s.io/)
- [Kind](https://kind.sigs.k8s.io/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)

---

**¿Problemas?** Revisa los logs con `kubectl logs` y describe los pods con `kubectl describe pod`.
