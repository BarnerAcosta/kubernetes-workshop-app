# 🚀 Aplicación DevOps con Kubernetes

[![Docker](https://img.shields.io/badge/Docker-Enabled-2496ED?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Ready-326CE5?style=flat&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Node.js](https://img.shields.io/badge/Node.js-18-339933?style=flat&logo=node.js&logoColor=white)](https://nodejs.org/)
[![CI/CD](https://github.com/BarnerAcosta/kubernetes-workshop-app/workflows/CI/CD%20Pipeline/badge.svg)](https://github.com/BarnerAcosta/kubernetes-workshop-app/actions)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Taller completo de Kubernetes con aplicación full-stack (Node.js + HTML/CSS/JS), manifiestos K8s y CI/CD**

Proyecto completo de una aplicación web (Frontend + Backend + MySQL) desplegada en Kubernetes con CI/CD automatizado.

---

## 📋 Descripción

Este proyecto implementa una aplicación web monolítica migrada a arquitectura de microservicios con Kubernetes:

- **Frontend:** HTML/CSS/JavaScript servido con Nginx
- **Backend:** API REST en Node.js/Express
- **Base de Datos:** MySQL (gestionada como servicio aparte)
- **Orquestación:** Kubernetes
- **CI/CD:** GitHub Actions

## 🏗️ Arquitectura

```
┌──────────────────────────────────────────────┐
│         Kubernetes Cluster (dev-app)         │
│                                              │
│  ┌────────────┐         ┌────────────┐     │
│  │  Frontend  │         │  Backend   │     │
│  │  (Nginx)   │ ◄─────► │ (Node.js)  │     │
│  │  2 Pods    │         │  3 Pods    │     │
│  └────────────┘         └────────────┘     │
│       │                       │             │
│       │                       ▼             │
│       │              ┌──────────────┐      │
│       │              │   ConfigMap  │      │
│       │              │   + Secret   │      │
│       │              └──────────────┘      │
│       ▼                                     │
│  ┌─────────────────────────────────┐      │
│  │      Ingress Controller          │      │
│  └─────────────────────────────────┘      │
└──────────────────────────────────────────────┘
```

## 📁 Estructura del Proyecto

```
dev-k8s-app/
├── backend/
│   ├── server.js           # API REST
│   ├── package.json        # Dependencias
│   ├── Dockerfile          # Imagen Docker
│   └── .env.example        # Variables de entorno
├── frontend/
│   ├── index.html          # Interfaz
│   ├── styles.css          # Estilos
│   ├── app.js              # Cliente API
│   ├── nginx.conf          # Config Nginx
│   └── Dockerfile          # Imagen Docker
├── kubernetes/
│   ├── namespace.yaml              # Namespace dev-app
│   ├── secret.yaml                 # Credenciales DB
│   ├── configmap.yaml              # Variables entorno
│   ├── deployment-backend.yaml     # Deploy backend
│   ├── service-backend.yaml        # Service backend
│   ├── deployment-frontend.yaml    # Deploy frontend
│   ├── service-frontend.yaml       # Service frontend
│   └── ingress.yaml                # Ingress rules
├── .github/
│   └── workflows/
│       └── ci-cd.yaml      # Pipeline CI/CD
├── DESIGN.md               # Documento de diseño
└── README.md               # Este archivo
```

## 🚀 Inicio Rápido

### Prerequisitos

- ✅ Docker Desktop instalado
- ✅ Kubernetes habilitado (Docker Desktop, Minikube o Kind)
- ✅ kubectl configurado
- ✅ Git instalado

### 1. Clonar el repositorio

```bash
git clone https://github.com/BarnerAcosta/kubernetes-workshop-app.git
cd kubernetes-workshop-app
```

### 2. Construir imágenes Docker

```bash
# Backend
cd backend
docker build -t tu-usuario/backend:1.0.0 .

# Frontend
cd ../frontend
docker build -t tu-usuario/frontend:1.0.0 .
```

### 3. Desplegar en Kubernetes

```bash
# Aplicar todos los manifiestos
kubectl apply -f kubernetes/

# Verificar despliegue
kubectl get all -n dev-app
```

### 4. Acceder a la aplicación

```bash
# Obtener IP del servicio frontend
kubectl get service frontend-service -n dev-app

# Si usas LoadBalancer en cloud
# Navega a la EXTERNAL-IP

# Si usas Minikube
minikube service frontend-service -n dev-app
```

## 🔧 Configuración

### Variables de Entorno (Backend)

Edita `kubernetes/configmap.yaml` y `kubernetes/secret.yaml`:

- `NODE_ENV`: Entorno de ejecución
- `DB_HOST`: Host de MySQL
- `DB_NAME`: Nombre de la base de datos
- `DB_USER`: Usuario (en Secret, base64)
- `DB_PASSWORD`: Contraseña (en Secret, base64)

### Escalado

```bash
# Escalar backend manualmente
kubectl scale deployment backend-deployment --replicas=5 -n dev-app

# Ver estado
kubectl get pods -n dev-app
```

## 📊 Objetos Kubernetes

| Objeto     | Nombre                | Propósito                  |
| ---------- | --------------------- | -------------------------- |
| Namespace  | `dev-app`             | Aislamiento de recursos    |
| Deployment | `backend-deployment`  | 3 réplicas del backend     |
| Deployment | `frontend-deployment` | 2 réplicas del frontend    |
| Service    | `backend-service`     | ClusterIP para backend     |
| Service    | `frontend-service`    | LoadBalancer para frontend |
| ConfigMap  | `backend-config`      | Variables de entorno       |
| Secret     | `db-credentials`      | Credenciales DB (base64)   |
| Ingress    | `app-ingress`         | Enrutamiento HTTP/HTTPS    |

## 🔄 Pipeline CI/CD

El pipeline se ejecuta automáticamente en cada push a `main`:

1. **Checkout:** Clonar código
2. **Build Backend:** Construir y pushear imagen
3. **Build Frontend:** Construir y pushear imagen
4. **Tests:** Ejecutar pruebas
5. **Deploy:** Aplicar manifiestos a Kubernetes

### Configurar Secrets en GitHub

Necesitas configurar estos secrets en tu repositorio:

- `KUBE_CONFIG`: Archivo kubeconfig en base64

```bash
# Generar KUBE_CONFIG
cat ~/.kube/config | base64
```

## 📖 Endpoints API

### Backend (Puerto 3000)

- `GET /health` - Health check
- `GET /api/items` - Obtener todos los items
- `POST /api/items` - Crear nuevo item
- `DELETE /api/items/:id` - Eliminar item

### Ejemplos

```bash
# Health check
curl http://backend-service/health

# Crear item
curl -X POST http://backend-service/api/items \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","description":"Item de prueba"}'

# Listar items
curl http://backend-service/api/items
```

## 🛠️ Comandos Útiles

```bash
# Ver logs del backend
kubectl logs -f deployment/backend-deployment -n dev-app

# Ver logs del frontend
kubectl logs -f deployment/frontend-deployment -n dev-app

# Entrar a un pod
kubectl exec -it <pod-name> -n dev-app -- /bin/sh

# Ver eventos
kubectl get events -n dev-app --sort-by='.lastTimestamp'

# Eliminar todo
kubectl delete namespace dev-app
```

## 🔐 Seguridad

⚠️ **Importante para producción:**

1. No usar credenciales en texto plano
2. Implementar Network Policies
3. Usar Pod Security Standards
4. Integrar con Secrets Manager (Vault, AWS Secrets, etc.)
5. Habilitar RBAC
6. Escanear imágenes con herramientas como Trivy

## 📈 Monitoreo y Observabilidad

Próximamente:

- Prometheus + Grafana
- ELK Stack para logs
- Jaeger para tracing

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama (`git checkout -b feature/nueva-funcionalidad`)
3. Commit cambios (`git commit -m 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## 📚 Documentación Completa

- 📖 **[DESIGN.md](DESIGN.md)** - Documento de arquitectura y diseño técnico
- 🚀 **[KUBERNETES-SETUP.md](KUBERNETES-SETUP.md)** - Guía completa de despliegue
- ✅ **[STATUS.md](STATUS.md)** - Estado del proyecto y checklist

## 🔗 Enlaces Útiles

- 🐙 **[Repositorio GitHub](https://github.com/BarnerAcosta/kubernetes-workshop-app)**
- 🐳 **[Docker Hub](https://hub.docker.com/)** - Para publicar tus imágenes
- ☸️ **[Kubernetes Docs](https://kubernetes.io/docs/)** - Documentación oficial

## 📄 Licencia

Este proyecto es de código abierto bajo licencia MIT.

## 👨‍💻 Autor

**Barner Acosta**  
Proyecto educativo para el taller de Kubernetes y DevOps

[![GitHub](https://img.shields.io/badge/GitHub-BarnerAcosta-181717?style=flat&logo=github)](https://github.com/BarnerAcosta)

---

<div align="center">

**⭐ Si te fue útil este proyecto, dale una estrella en GitHub ⭐**

[Reportar Bug](https://github.com/BarnerAcosta/kubernetes-workshop-app/issues) · [Solicitar Feature](https://github.com/BarnerAcosta/kubernetes-workshop-app/issues)

</div>
