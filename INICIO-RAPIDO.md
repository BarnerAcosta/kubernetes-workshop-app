# 🚀 Inicio Rápido

## Prerequisitos

✅ Docker Desktop instalado con Kubernetes habilitado
✅ kubectl configurado

## Desplegar TODO en un solo comando

```powershell
.\deploy.ps1
```

Este script despliega automáticamente:

1. ✅ Namespace `dev-app`
2. ✅ Secrets y ConfigMaps
3. ✅ MySQL (base de datos)
4. ✅ Backend (API REST con 3 réplicas)
5. ✅ Frontend (interfaz web con 2 réplicas)
6. ✅ Servicios e Ingress

## Acceder a la Aplicación

**Frontend:** http://localhost
**Backend API:** http://localhost:3000

## Ver el estado

```powershell
kubectl get all -n dev-app
```

## Ver logs

```powershell
# Backend
kubectl logs -f deployment/backend-deployment -n dev-app

# MySQL
kubectl logs -f deployment/mysql-deployment -n dev-app

# Frontend
kubectl logs -f deployment/frontend-deployment -n dev-app
```

## Eliminar TODO

```powershell
.\cleanup.ps1
```

## Arquitectura Desplegada

```
┌──────────────────────────────────────────────┐
│         Kubernetes Cluster (dev-app)         │
│                                              │
│  ┌────────────┐    ┌────────────┐    ┌─────┐│
│  │  Frontend  │───►│  Backend   │───►│MySQL││
│  │  (Nginx)   │    │ (Node.js)  │    │ DB  ││
│  │  2 Pods    │    │  3 Pods    │    │1Pod ││
│  └────────────┘    └────────────┘    └─────┘│
│       │                   │              │   │
│       ▼                   ▼              │   │
│  LoadBalancer        LoadBalancer       │   │
│  localhost:80        localhost:3000     │   │
└──────────────────────────────────────────────┘
```

## Comandos Útiles

```powershell
# Escalar backend
kubectl scale deployment backend-deployment --replicas=5 -n dev-app

# Reiniciar backend
kubectl rollout restart deployment/backend-deployment -n dev-app

# Ver eventos
kubectl get events -n dev-app --sort-by='.lastTimestamp'

# Ejecutar comando en un pod
kubectl exec -it deployment/backend-deployment -n dev-app -- /bin/sh
```

---

**¡Listo!** Tu aplicación completa con frontend, backend y base de datos está funcionando en Kubernetes 🎉
