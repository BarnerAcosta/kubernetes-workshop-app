# Documento de Diseño - Aplicación DevOps con Kubernetes

## 1. Introducción

Este documento describe el diseño y la arquitectura de una aplicación web desplegada en Kubernetes, siguiendo las mejores prácticas de DevOps y CI/CD.

### 1.1 Objetivo General

Diseñar y preparar la solución técnica para que la aplicación:

- Se construya como imagen Docker versionada a partir del código fuente en Git
- Se despliegue en un cluster Kubernetes utilizando Deployments y Services
- Permita escalar el backend horizontalmente sin cambios manuales en el servidor
- Se integre con un pipeline de CI/CD que automatice el build y despliegue

---

## 2. Arquitectura Actual vs Arquitectura Propuesta

### 2.1 Arquitectura Actual (Antes de Kubernetes)

```
┌─────────────────────────────────────┐
│     Servidor VPS Único              │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  Frontend (HTML/CSS/JS)      │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  Backend (Node.js)           │  │
│  │  - Despliegue manual         │  │
│  │  - git pull                  │  │
│  │  - docker build/run          │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  MySQL Database              │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

**Problemas:**

- Sin escalado automático
- Despliegue manual propenso a errores
- Si el contenedor cae, la app queda fuera hasta que alguien lo levanta
- Sin alta disponibilidad

### 2.2 Arquitectura Propuesta (Con Kubernetes)

```
┌──────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                             │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                     Namespace: dev-app                      │  │
│  │                                                             │  │
│  │  ┌───────────────────────────────────────────────────────┐ │  │
│  │  │  Ingress Controller (Nginx)                           │ │  │
│  │  │  - Enrutamiento HTTP/HTTPS                            │ │  │
│  │  │  - Certificados TLS                                   │ │  │
│  │  └───────────────────────────────────────────────────────┘ │  │
│  │           │                                │                │  │
│  │           ▼                                ▼                │  │
│  │  ┌──────────────────┐          ┌──────────────────┐       │  │
│  │  │ Frontend Service │          │ Backend Service  │       │  │
│  │  │ Type: ClusterIP  │          │ Type: ClusterIP  │       │  │
│  │  │ Port: 80         │          │ Port: 80         │       │  │
│  │  └──────────────────┘          └──────────────────┘       │  │
│  │           │                                │                │  │
│  │           ▼                                ▼                │  │
│  │  ┌──────────────────┐          ┌──────────────────┐       │  │
│  │  │ Frontend Deploy  │          │ Backend Deploy   │       │  │
│  │  │ Replicas: 2      │          │ Replicas: 3      │       │  │
│  │  │ Strategy: Rolling│          │ Strategy: Rolling│       │  │
│  │  │                  │          │                  │       │  │
│  │  │ ┌─────┐ ┌─────┐ │          │ ┌─────┐ ┌─────┐ │       │  │
│  │  │ │ Pod │ │ Pod │ │          │ │ Pod │ │ Pod │ │       │  │
│  │  │ └─────┘ └─────┘ │          │ └─────┘ └─────┘ │       │  │
│  │  └──────────────────┘          │    ┌─────┐     │       │  │
│  │                                │    │ Pod │     │       │  │
│  │                                │    └─────┘     │       │  │
│  │                                └──────────────────┘       │  │
│  │                                         │                  │  │
│  │                                         ▼                  │  │
│  │                                ┌──────────────────┐       │  │
│  │                                │  ConfigMap       │       │  │
│  │                                │  - DB_HOST       │       │  │
│  │                                │  - NODE_ENV      │       │  │
│  │                                └──────────────────┘       │  │
│  │                                         │                  │  │
│  │                                         ▼                  │  │
│  │                                ┌──────────────────┐       │  │
│  │                                │  Secret          │       │  │
│  │                                │  - DB_USER       │       │  │
│  │                                │  - DB_PASSWORD   │       │  │
│  │                                └──────────────────┘       │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │  MySQL Database (Externo o en otro Namespace)          │  │
│  └─────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 3. Objetos Kubernetes Utilizados

### 3.1 Namespace

**Archivo:** `namespace.yaml`

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev-app
```

**Justificación:**

- Separar ambientes (dev, staging, prod)
- Aislar recursos y aplicar políticas específicas
- Facilitar la organización en equipos

---

### 3.2 Deployment - Backend

**Archivo:** `deployment-backend.yaml`

**Características clave:**

- **Replicas:** 3 (escalabilidad y alta disponibilidad)
- **Estrategia:** RollingUpdate
  - `maxSurge: 1` → Permite crear 1 Pod adicional durante la actualización
  - `maxUnavailable: 0` → Garantiza que siempre haya réplicas disponibles
- **Variables de entorno:** Inyectadas desde ConfigMap y Secret
- **Health Checks:**
  - `livenessProbe`: Verifica si el contenedor está vivo (reinicia si falla)
  - `readinessProbe`: Verifica si está listo para recibir tráfico
- **Resources:**
  - Requests: CPU 100m, Memory 128Mi
  - Limits: CPU 500m, Memory 512Mi

**Justificación:**

- **¿Por qué Kubernetes mejora la escalabilidad?**

  - Kubernetes mantiene siempre el número de réplicas deseado
  - Si un Pod cae, lo levanta automáticamente (self-healing)
  - Se puede aumentar réplicas sin downtime: `kubectl scale deployment backend-deployment --replicas=5`

- **¿Cómo se aprovecha la resiliencia del Deployment?**
  - Si el Pod se levanta de nuevo gracias al Deployment, el tráfico no se pierde
  - El RollingUpdate permite actualizar código sin interrumpir el servicio
  - Se puede ajustar manualmente el número de réplicas o usar HPA (Horizontal Pod Autoscaler)

---

### 3.3 Service - Backend

**Archivo:** `service-backend.yaml`

```yaml
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
    - port: 80
      targetPort: 3000
```

**Justificación:**

- **Type: ClusterIP** → Solo accesible dentro del cluster (más habitual para un backend)
- El Service expone los Pods en el cluster con un único endpoint
- El puerto lógico 80 mapea al puerto real del contenedor (3000)
- El selector `app: backend` conecta automáticamente con los Pods del Deployment

---

### 3.4 Deployment - Frontend

**Archivo:** `deployment-frontend.yaml`

**Características:**

- Replicas: 2
- Estrategia: RollingUpdate
- Resources ajustados (menos intensivo que backend)
- Health checks en puerto 80

---

### 3.5 Service - Frontend

**Archivo:** `service-frontend.yaml`

```yaml
spec:
  type: LoadBalancer
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 80
```

**Justificación:**

- **Type: LoadBalancer** → Expone la aplicación externamente
- En cloud providers (AWS, GCP, Azure) crea automáticamente un balanceador de carga
- Para entornos locales se puede usar NodePort o Ingress

---

### 3.6 ConfigMap

**Archivo:** `configmap.yaml`

Almacena configuración **no sensible**:

- NODE_ENV
- DB_HOST
- DB_NAME

**Ventajas:**

- Separar configuración del código
- Cambiar variables sin reconstruir la imagen
- Facilitar ambientes múltiples (dev, prod)

---

### 3.7 Secret

**Archivo:** `secret.yaml`

Almacena datos **sensibles** (codificados en base64):

- username: root
- password: mypassword

**Importante:** En producción usar soluciones más seguras como:

- HashiCorp Vault
- AWS Secrets Manager
- Azure Key Vault
- Sealed Secrets

---

### 3.8 Ingress (Opcional)

**Archivo:** `ingress.yaml`

Permite:

- Exponer múltiples servicios bajo un mismo dominio
- Configurar reglas de enrutamiento HTTP/HTTPS
- Integrar certificados TLS

```yaml
rules:
  - host: empresa.com
    http:
      paths:
        - path: /
          backend:
            service:
              name: frontend-service
        - path: /api
          backend:
            service:
              name: backend-service
```

---

## 4. Estrategia de Escalado y Resiliencia

### 4.1 Escalado Horizontal

**Manual:**

```bash
kubectl scale deployment backend-deployment --replicas=5 -n dev-app
```

**Automático (HPA - Horizontal Pod Autoscaler):**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
  namespace: dev-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend-deployment
  minReplicas: 3
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

**Explicación:**

- Kubernetes ajusta automáticamente el número de réplicas
- Si el CPU promedio supera 70%, crea más Pods
- Si baja, reduce Pods (respetando el mínimo de 3)

### 4.2 Resiliencia

**Mecanismos implementados:**

1. **Self-Healing:** Si un Pod muere, Kubernetes lo reinicia
2. **RollingUpdate:** Actualiza sin downtime
3. **Health Probes:**
   - `livenessProbe`: Reinicia containers que no responden
   - `readinessProbe`: Evita enviar tráfico a Pods no listos
4. **Resource Limits:** Previene que un Pod consuma todos los recursos del nodo

---

## 5. Pipeline CI/CD

### 5.1 Estructura del Pipeline

**Archivo:** `.github/workflows/ci-cd.yaml`

**Etapas:**

1. **Checkout:**

   - Clona el repositorio
   - Configura Git

2. **Build Backend:**

   - Construye imagen Docker del backend
   - Usa tags basados en commit SHA y branch
   - Push a GitHub Container Registry

3. **Build Frontend:**

   - Construye imagen Docker del frontend
   - Push a registry

4. **Tests:**

   - Instala dependencias
   - Ejecuta tests (si existen)

5. **Deploy:**
   - Solo en rama `main`
   - Configura kubectl
   - Aplica manifiestos YAML en orden
   - Verifica el rollout

### 5.2 Evento Disparador

```yaml
on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main
```

**Funcionamiento:**

- Cada push o merge a `main` → Build + Deploy automático
- Pull requests → Solo build y tests (sin deploy)

### 5.3 Cómo se conectan Git, Docker y Kubernetes

```
Developer → Git Push → GitHub Actions → Docker Build → Push Registry
                                            ↓
                                    Deploy to Kubernetes
                                            ↓
                        kubectl apply -f manifests → Cluster
```

**Requisitos importantes:**

El despliegue debe ser **rolling** (sin downtime completo):

- Configurado en `strategy: RollingUpdate`
- El Deployment garantiza actualizaciones graduales

---

## 6. Resumen de Archivos Generados

### 6.1 Backend

```
backend/
├── server.js              # API REST con Express
├── package.json           # Dependencias Node.js
├── Dockerfile             # Imagen multi-stage
├── .dockerignore          # Excluir archivos del build
└── .env.example           # Variables de entorno de ejemplo
```

### 6.2 Frontend

```
frontend/
├── index.html             # Interfaz web
├── styles.css             # Estilos
├── app.js                 # Lógica cliente
├── nginx.conf             # Configuración Nginx
├── Dockerfile             # Imagen con Nginx
└── .dockerignore          # Excluir archivos del build
```

### 6.3 Kubernetes

```
kubernetes/
├── namespace.yaml                # Namespace dev-app
├── secret.yaml                   # Credenciales DB
├── configmap.yaml                # Variables de entorno
├── deployment-backend.yaml       # Deployment backend (3 replicas)
├── service-backend.yaml          # Service ClusterIP
├── deployment-frontend.yaml      # Deployment frontend (2 replicas)
├── service-frontend.yaml         # Service LoadBalancer
└── ingress.yaml                  # Ingress (opcional)
```

### 6.4 CI/CD

```
.github/
└── workflows/
    └── ci-cd.yaml         # Pipeline GitHub Actions
```

---

## 7. Comandos de Despliegue

### 7.1 Construcción Local

```bash
# Backend
cd backend
docker build -t backend:1.0.0 .

# Frontend
cd frontend
docker build -t frontend:1.0.0 .
```

### 7.2 Despliegue en Kubernetes

```bash
# Aplicar todos los manifiestos
kubectl apply -f kubernetes/

# Verificar estado
kubectl get pods -n dev-app
kubectl get services -n dev-app
kubectl get deployments -n dev-app

# Ver logs
kubectl logs -f deployment/backend-deployment -n dev-app

# Escalar manualmente
kubectl scale deployment backend-deployment --replicas=5 -n dev-app
```

---

## 8. Mejoras Futuras (Opcional)

- **HPA:** Implementar autoscaling basado en métricas
- **Monitoring:** Integrar Prometheus + Grafana
- **Logging:** ELK Stack o Loki
- **Service Mesh:** Istio para tráfico avanzado
- **GitOps:** ArgoCD o Flux para deploys declarativos
- **Seguridad:** Network Policies, Pod Security Standards

---

## 9. Conclusión

Este diseño cumple con todos los requisitos del taller:

✅ Aplicación contenerizada con Docker  
✅ Manifiestos YAML completos (Namespace, Deployment, Service, ConfigMap, Secret)  
✅ Estrategia de escalado y resiliencia  
✅ Pipeline CI/CD automatizado  
✅ Despliegue rolling sin downtime

La arquitectura es escalable, resiliente y sigue las mejores prácticas de DevOps y Kubernetes.
