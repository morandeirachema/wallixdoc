# 25 - Container & Kubernetes Deployment

## Table of Contents

1. [Container Overview](#container-overview)
2. [Docker Deployment](#docker-deployment)
3. [Kubernetes Deployment](#kubernetes-deployment)
4. [Helm Charts](#helm-charts)
5. [OpenShift Deployment](#openshift-deployment)
6. [Container Security](#container-security)

---

## Container Overview

### Container Deployment Options

```
+===============================================================================+
|                   WALLIX CONTAINER DEPLOYMENT                                |
+===============================================================================+

  DEPLOYMENT OPTIONS
  ==================

  +------------------------------------------------------------------------+
  |                                                                        |
  | OPTION 1: DOCKER (Single Host)                                         |
  | ==============================                                         |
  |                                                                        |
  |   Best for: Development, testing, small deployments                    |
  |                                                                        |
  |   +------------------+                                                 |
  |   | Docker Host      |                                                 |
  |   |                  |                                                 |
  |   | +-------------+  |                                                 |
  |   | | WALLIX      |  |                                                 |
  |   | | Container   |  |                                                 |
  |   | +-------------+  |                                                 |
  |   |                  |                                                 |
  |   | +-------------+  |                                                 |
  |   | | MariaDB     |  |                                                 |
  |   | | Container   |  |                                                 |
  |   | +-------------+  |                                                 |
  |   |                  |                                                 |
  |   +------------------+                                                 |
  |                                                                        |
  +------------------------------------------------------------------------+
  |                                                                        |
  | OPTION 2: KUBERNETES (Orchestrated)                                    |
  | ===================================                                    |
  |                                                                        |
  |   Best for: Production, HA, scalability                                |
  |                                                                        |
  |   +----------------------------------------------------------+        |
  |   | Kubernetes Cluster                                       |        |
  |   |                                                          |        |
  |   |  +----------------+  +----------------+  +-------------+ |        |
  |   |  | WALLIX Pod 1   |  | WALLIX Pod 2   |  | MariaDB     | |        |
  |   |  | (Primary)      |  | (Standby)      |  | StatefulSet | |        |
  |   |  +----------------+  +----------------+  +-------------+ |        |
  |   |                                                          |        |
  |   |  +----------------+  +----------------+                  |        |
  |   |  | Ingress        |  | PVC            |                  |        |
  |   |  | Controller     |  | (Recordings)   |                  |        |
  |   |  +----------------+  +----------------+                  |        |
  |   |                                                          |        |
  |   +----------------------------------------------------------+        |
  |                                                                        |
  +------------------------------------------------------------------------+
  |                                                                        |
  | OPTION 3: DOCKER COMPOSE (Multi-Container)                             |
  | ==========================================                             |
  |                                                                        |
  |   Best for: Development, small production                              |
  |                                                                        |
  |   docker-compose.yml defines:                                          |
  |   - WALLIX Bastion service                                             |
  |   - MariaDB service                                                    |
  |   - Shared volumes                                                     |
  |   - Network configuration                                              |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Container Image Information

```
+===============================================================================+
|                   WALLIX CONTAINER IMAGES                                    |
+===============================================================================+

  OFFICIAL IMAGES
  ===============

  +------------------------------------------------------------------------+
  | Image                          | Description                           |
  +--------------------------------+---------------------------------------+
  | wallix/bastion:latest          | Latest stable release (12.x)          |
  | wallix/bastion:12.1            | Version 12.1.x                        |
  | wallix/bastion:12.0            | Version 12.0.x                        |
  | wallix/bastion:12.1.1-alpine   | Alpine-based (smaller)                |
  +--------------------------------+---------------------------------------+

  IMAGE DETAILS
  =============

  +------------------------------------------------------------------------+
  | Property              | Value                                          |
  +-----------------------+------------------------------------------------+
  | Base Image            | Debian 12 (Bookworm) or Alpine                 |
  | Exposed Ports         | 22, 443, 3389, 5900                            |
  | Default User          | wab                                            |
  | Config Directory      | /etc/opt/wab/                                  |
  | Data Directory        | /var/wab/                                      |
  | Recording Directory   | /var/wab/recorded/                             |
  | Log Directory         | /var/log/wab/                                  |
  +-----------------------+------------------------------------------------+

  MINIMUM REQUIREMENTS
  ====================

  +------------------------------------------------------------------------+
  | Resource    | Minimum      | Recommended                               |
  +-------------+--------------+-------------------------------------------+
  | CPU         | 2 cores      | 4+ cores                                  |
  | Memory      | 4 GB         | 8+ GB                                     |
  | Storage     | 50 GB        | 100+ GB (plus recordings)                 |
  +-------------+--------------+-------------------------------------------+

+===============================================================================+
```

---

## Docker Deployment

### Docker Compose Configuration

```
+===============================================================================+
|                   DOCKER COMPOSE DEPLOYMENT                                  |
+===============================================================================+

  docker-compose.yml
  ==================

  version: '3.8'

  services:
    wallix-bastion:
      image: wallix/bastion:12.1
      container_name: wallix-bastion
      hostname: wallix-bastion
      restart: unless-stopped
      ports:
        - "443:443"      # HTTPS (Web UI, API)
        - "22:22"        # SSH Proxy
        - "3389:3389"    # RDP Proxy
        - "5900:5900"    # VNC Proxy
      volumes:
        - wallix-config:/etc/opt/wab
        - wallix-data:/var/wab
        - wallix-recordings:/var/wab/recorded
        - wallix-logs:/var/log/wab
      environment:
        - WAB_ADMIN_PASSWORD=${WAB_ADMIN_PASSWORD}
        - WAB_DB_HOST=wallix-db
        - WAB_DB_PORT=3306
        - WAB_DB_NAME=wallix
        - WAB_DB_USER=wallix
        - WAB_DB_PASSWORD=${WAB_DB_PASSWORD}
        - WAB_LICENSE_KEY=${WAB_LICENSE_KEY}
        - TZ=UTC
      depends_on:
        - wallix-db
      networks:
        - wallix-network
      # NOTE: Verify /health endpoint exists for your WALLIX version
      healthcheck:
        test: ["CMD", "curl", "-f", "https://localhost:443/health"]
        interval: 30s
        timeout: 10s
        retries: 3

    wallix-db:
      image: mariadb:10.11
      container_name: wallix-db
      restart: unless-stopped
      volumes:
        - wallix-db-data:/var/lib/mysql/data
      environment:
        - MARIADB_DATABASE=wallix
        - MARIADB_USER=wallix
        - MARIADB_PASSWORD=${WAB_DB_PASSWORD}
      networks:
        - wallix-network
      healthcheck:
        test: ["CMD-SHELL", "pg_isready -U wallix"]
        interval: 10s
        timeout: 5s
        retries: 5

  volumes:
    wallix-config:
    wallix-data:
    wallix-recordings:
    wallix-logs:
    wallix-db-data:

  networks:
    wallix-network:
      driver: bridge

  --------------------------------------------------------------------------

  .env file
  =========

  # WALLIX Credentials
  WAB_ADMIN_PASSWORD=SecureAdminPassword123!
  WAB_DB_PASSWORD=SecureDbPassword456!
  WAB_LICENSE_KEY=XXXX-XXXX-XXXX-XXXX

  --------------------------------------------------------------------------

  DEPLOYMENT COMMANDS
  ===================

  # Start services
  docker-compose up -d

  # View logs
  docker-compose logs -f wallix-bastion

  # Stop services
  docker-compose down

  # Stop and remove volumes (WARNING: destroys data)
  docker-compose down -v

  # Update to new version
  docker-compose pull
  docker-compose up -d

+===============================================================================+
```

### Docker Run (Single Container)

```
+===============================================================================+
|                   DOCKER RUN COMMANDS                                        |
+===============================================================================+

  BASIC DEPLOYMENT
  ================

  # Create network
  docker network create wallix-net

  # Start MariaDB
  docker run -d \
    --name wallix-db \
    --network wallix-net \
    -e MARIADB_DATABASE=wallix \
    -e MARIADB_USER=wallix \
    -e MARIADB_PASSWORD=SecurePassword \
    -v wallix-db:/var/lib/mysql/data \
    mariadb:10.11

  # Start WALLIX Bastion
  docker run -d \
    --name wallix-bastion \
    --network wallix-net \
    -p 443:443 \
    -p 22:22 \
    -p 3389:3389 \
    -e WAB_DB_HOST=wallix-db \
    -e WAB_DB_PORT=3306 \
    -e WAB_DB_NAME=wallix \
    -e WAB_DB_USER=wallix \
    -e WAB_DB_PASSWORD=SecurePassword \
    -e WAB_ADMIN_PASSWORD=AdminPassword \
    -v wallix-config:/etc/opt/wab \
    -v wallix-data:/var/wab \
    -v wallix-recordings:/var/wab/recorded \
    wallix/bastion:12.1

  --------------------------------------------------------------------------

  PRODUCTION DEPLOYMENT WITH EXTERNAL STORAGE
  ===========================================

  # With NFS mount for recordings
  docker run -d \
    --name wallix-bastion \
    --network wallix-net \
    -p 443:443 \
    -p 22:22 \
    -p 3389:3389 \
    -e WAB_DB_HOST=external-mariadb.company.com \
    -e WAB_DB_PORT=3306 \
    -e WAB_DB_NAME=wallix \
    -e WAB_DB_USER=wallix \
    -e WAB_DB_PASSWORD_FILE=/run/secrets/db_password \
    -v /mnt/nfs/wallix/recordings:/var/wab/recorded \
    -v /path/to/certs:/etc/opt/wab/certs:ro \
    --mount type=bind,source=/path/to/secrets,target=/run/secrets,readonly \
    --memory=8g \
    --cpus=4 \
    wallix/bastion:12.1

+===============================================================================+
```

---

## Kubernetes Deployment

### Kubernetes Architecture

```
+===============================================================================+
|                   KUBERNETES ARCHITECTURE                                    |
+===============================================================================+

  +------------------------------------------------------------------------+
  |                      KUBERNETES CLUSTER                                |
  +------------------------------------------------------------------------+
  |                                                                        |
  |  Namespace: wallix                                                     |
  |  +--------------------------------------------------------------------+|
  |  |                                                                    ||
  |  |  +------------------------+    +------------------------+          ||
  |  |  | Deployment             |    | StatefulSet            |          ||
  |  |  | wallix-bastion         |    | wallix-db              |          ||
  |  |  |                        |    |                        |          ||
  |  |  | +------------------+   |    | +------------------+   |          ||
  |  |  | | Pod: wallix-0    |   |    | | Pod: db-0        |   |          ||
  |  |  | | (Primary)        |   |    | | (Primary)        |   |          ||
  |  |  | +------------------+   |    | +------------------+   |          ||
  |  |  |                        |    |                        |          ||
  |  |  | +------------------+   |    | +------------------+   |          ||
  |  |  | | Pod: wallix-1    |   |    | | Pod: db-1        |   |          ||
  |  |  | | (Standby)        |   |    | | (Replica)        |   |          ||
  |  |  | +------------------+   |    | +------------------+   |          ||
  |  |  |                        |    |                        |          ||
  |  |  +------------------------+    +------------------------+          ||
  |  |                                                                    ||
  |  |  +------------------------+    +------------------------+          ||
  |  |  | Service                |    | Service                |          ||
  |  |  | wallix-bastion-svc     |    | wallix-db-svc          |          ||
  |  |  | ClusterIP              |    | ClusterIP (headless)   |          ||
  |  |  +------------------------+    +------------------------+          ||
  |  |                                                                    ||
  |  |  +------------------------+    +------------------------+          ||
  |  |  | Ingress                |    | PersistentVolumeClaim  |          ||
  |  |  | wallix-ingress         |    | wallix-recordings-pvc  |          ||
  |  |  | (HTTPS termination)    |    | (ReadWriteMany)        |          ||
  |  |  +------------------------+    +------------------------+          ||
  |  |                                                                    ||
  |  |  +------------------------+    +------------------------+          ||
  |  |  | ConfigMap              |    | Secret                 |          ||
  |  |  | wallix-config          |    | wallix-secrets         |          ||
  |  |  +------------------------+    +------------------------+          ||
  |  |                                                                    ||
  |  +--------------------------------------------------------------------+|
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Kubernetes Manifests

```
+===============================================================================+
|                   KUBERNETES MANIFEST FILES                                  |
+===============================================================================+

  namespace.yaml
  ==============

  apiVersion: v1
  kind: Namespace
  metadata:
    name: wallix
    labels:
      app: wallix-bastion

  --------------------------------------------------------------------------

  secrets.yaml
  ============

  apiVersion: v1
  kind: Secret
  metadata:
    name: wallix-secrets
    namespace: wallix
  type: Opaque
  stringData:
    admin-password: "SecureAdminPassword123!"
    db-password: "SecureDbPassword456!"
    license-key: "XXXX-XXXX-XXXX-XXXX"

  --------------------------------------------------------------------------

  configmap.yaml
  ==============

  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: wallix-config
    namespace: wallix
  data:
    WAB_DB_HOST: "wallix-db-svc"
    WAB_DB_PORT: "3306"
    WAB_DB_NAME: "wallix"
    WAB_DB_USER: "wallix"
    TZ: "UTC"

  --------------------------------------------------------------------------

  pvc.yaml
  ========

  apiVersion: v1
  kind: PersistentVolumeClaim
  metadata:
    name: wallix-recordings-pvc
    namespace: wallix
  spec:
    accessModes:
      - ReadWriteMany
    storageClassName: nfs-client  # or your storage class
    resources:
      requests:
        storage: 500Gi

  ---
  apiVersion: v1
  kind: PersistentVolumeClaim
  metadata:
    name: wallix-config-pvc
    namespace: wallix
  spec:
    accessModes:
      - ReadWriteOnce
    storageClassName: standard
    resources:
      requests:
        storage: 10Gi

  --------------------------------------------------------------------------

  deployment.yaml
  ===============

  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: wallix-bastion
    namespace: wallix
    labels:
      app: wallix-bastion
  spec:
    replicas: 2
    selector:
      matchLabels:
        app: wallix-bastion
    template:
      metadata:
        labels:
          app: wallix-bastion
      spec:
        containers:
        - name: wallix-bastion
          image: wallix/bastion:12.1
          ports:
          - containerPort: 443
            name: https
          - containerPort: 22
            name: ssh
          - containerPort: 3389
            name: rdp
          envFrom:
          - configMapRef:
              name: wallix-config
          env:
          - name: WAB_ADMIN_PASSWORD
            valueFrom:
              secretKeyRef:
                name: wallix-secrets
                key: admin-password
          - name: WAB_DB_PASSWORD
            valueFrom:
              secretKeyRef:
                name: wallix-secrets
                key: db-password
          - name: WAB_LICENSE_KEY
            valueFrom:
              secretKeyRef:
                name: wallix-secrets
                key: license-key
          volumeMounts:
          - name: config
            mountPath: /etc/opt/wab
          - name: recordings
            mountPath: /var/wab/recorded
          resources:
            requests:
              memory: "4Gi"
              cpu: "2"
            limits:
              memory: "8Gi"
              cpu: "4"
          # NOTE: Verify /health endpoint exists for your WALLIX version
          livenessProbe:
            httpGet:
              path: /health
              port: 443
              scheme: HTTPS
            initialDelaySeconds: 60
            periodSeconds: 30
          readinessProbe:
            httpGet:
              path: /health
              port: 443
              scheme: HTTPS
            initialDelaySeconds: 30
            periodSeconds: 10
        volumes:
        - name: config
          persistentVolumeClaim:
            claimName: wallix-config-pvc
        - name: recordings
          persistentVolumeClaim:
            claimName: wallix-recordings-pvc

  --------------------------------------------------------------------------

  service.yaml
  ============

  apiVersion: v1
  kind: Service
  metadata:
    name: wallix-bastion-svc
    namespace: wallix
  spec:
    selector:
      app: wallix-bastion
    ports:
    - name: https
      port: 443
      targetPort: 443
    - name: ssh
      port: 22
      targetPort: 22
    - name: rdp
      port: 3389
      targetPort: 3389
    type: ClusterIP

  --------------------------------------------------------------------------

  ingress.yaml
  ============

  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: wallix-ingress
    namespace: wallix
    annotations:
      kubernetes.io/ingress.class: nginx
      nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
      nginx.ingress.kubernetes.io/ssl-passthrough: "true"
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
  spec:
    tls:
    - hosts:
      - wallix.company.com
      secretName: wallix-tls
    rules:
    - host: wallix.company.com
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: wallix-bastion-svc
              port:
                number: 443

  --------------------------------------------------------------------------

  mariadb-statefulset.yaml
  ========================

  apiVersion: apps/v1
  kind: StatefulSet
  metadata:
    name: wallix-db
    namespace: wallix
  spec:
    serviceName: wallix-db-svc
    replicas: 1
    selector:
      matchLabels:
        app: wallix-db
    template:
      metadata:
        labels:
          app: wallix-db
      spec:
        containers:
        - name: mariadb
          image: mariadb:10.11
          ports:
          - containerPort: 3306
          env:
          - name: MARIADB_DATABASE
            value: "wallix"
          - name: MARIADB_USER
            value: "wallix"
          - name: MARIADB_PASSWORD
            valueFrom:
              secretKeyRef:
                name: wallix-secrets
                key: db-password
          volumeMounts:
          - name: db-data
            mountPath: /var/lib/mysql
          resources:
            requests:
              memory: "1Gi"
              cpu: "500m"
            limits:
              memory: "2Gi"
              cpu: "1"
    volumeClaimTemplates:
    - metadata:
        name: db-data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: standard
        resources:
          requests:
            storage: 100Gi

  ---
  apiVersion: v1
  kind: Service
  metadata:
    name: wallix-db-svc
    namespace: wallix
  spec:
    selector:
      app: wallix-db
    ports:
    - port: 3306
      targetPort: 3306
    clusterIP: None  # Headless service

+===============================================================================+
```

### Kubernetes Deployment Commands

```
+===============================================================================+
|                   KUBERNETES DEPLOYMENT COMMANDS                             |
+===============================================================================+

  DEPLOYMENT
  ==========

  # Create namespace
  kubectl create namespace wallix

  # Apply all manifests
  kubectl apply -f namespace.yaml
  kubectl apply -f secrets.yaml
  kubectl apply -f configmap.yaml
  kubectl apply -f pvc.yaml
  kubectl apply -f mariadb-statefulset.yaml
  kubectl apply -f deployment.yaml
  kubectl apply -f service.yaml
  kubectl apply -f ingress.yaml

  # Or apply all at once
  kubectl apply -f ./manifests/

  --------------------------------------------------------------------------

  VERIFICATION
  ============

  # Check pod status
  kubectl get pods -n wallix

  # Check services
  kubectl get svc -n wallix

  # Check ingress
  kubectl get ingress -n wallix

  # View logs
  kubectl logs -f deployment/wallix-bastion -n wallix

  # Exec into container
  kubectl exec -it deployment/wallix-bastion -n wallix -- /bin/bash

  --------------------------------------------------------------------------

  SCALING
  =======

  # Scale replicas
  kubectl scale deployment wallix-bastion --replicas=3 -n wallix

  # Horizontal Pod Autoscaler
  kubectl autoscale deployment wallix-bastion \
    --min=2 --max=5 --cpu-percent=70 -n wallix

  --------------------------------------------------------------------------

  UPDATES
  =======

  # Rolling update
  kubectl set image deployment/wallix-bastion \
    wallix-bastion=wallix/bastion:12.1 -n wallix

  # Check rollout status
  kubectl rollout status deployment/wallix-bastion -n wallix

  # Rollback if needed
  kubectl rollout undo deployment/wallix-bastion -n wallix

+===============================================================================+
```

---

## Helm Charts

### Helm Chart Structure

```
+===============================================================================+
|                   HELM CHART STRUCTURE                                       |
+===============================================================================+

  wallix-bastion/
  |
  +-- Chart.yaml
  +-- values.yaml
  +-- templates/
  |   +-- _helpers.tpl
  |   +-- namespace.yaml
  |   +-- secrets.yaml
  |   +-- configmap.yaml
  |   +-- pvc.yaml
  |   +-- deployment.yaml
  |   +-- service.yaml
  |   +-- ingress.yaml
  |   +-- mariadb.yaml
  |   +-- hpa.yaml
  |   +-- NOTES.txt
  +-- charts/
  |   +-- mariadb/           # Dependency chart
  +-- README.md

+===============================================================================+
```

### values.yaml

```
+===============================================================================+
|                   HELM VALUES FILE                                           |
+===============================================================================+

  # values.yaml

  # Image configuration
  image:
    repository: wallix/bastion
    tag: "12.1"
    pullPolicy: IfNotPresent

  # Replica count
  replicaCount: 2

  # Resource limits
  resources:
    requests:
      memory: "4Gi"
      cpu: "2"
    limits:
      memory: "8Gi"
      cpu: "4"

  # Service configuration
  service:
    type: ClusterIP
    ports:
      https: 443
      ssh: 22
      rdp: 3389

  # Ingress configuration
  ingress:
    enabled: true
    className: nginx
    annotations:
      nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
    hosts:
      - host: wallix.company.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: wallix-tls
        hosts:
          - wallix.company.com

  # MariaDB configuration
  mariadb:
    enabled: true
    auth:
      username: wallix
      password: ""  # Set via --set or secrets
      database: wallix
    primary:
      persistence:
        size: 100Gi

  # External database (if mariadb.enabled=false)
  externalDatabase:
    host: ""
    port: 3306
    database: wallix
    username: wallix
    password: ""

  # Persistence
  persistence:
    recordings:
      enabled: true
      storageClass: "nfs-client"
      accessMode: ReadWriteMany
      size: 500Gi
    config:
      enabled: true
      storageClass: "standard"
      accessMode: ReadWriteOnce
      size: 10Gi

  # WALLIX configuration
  wallix:
    adminPassword: ""  # Set via --set or secrets
    licenseKey: ""     # Set via --set or secrets
    timezone: "UTC"

  # Autoscaling
  autoscaling:
    enabled: false
    minReplicas: 2
    maxReplicas: 5
    targetCPUUtilizationPercentage: 70

  # Node selector
  nodeSelector: {}

  # Tolerations
  tolerations: []

  # Affinity
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchExpressions:
                - key: app
                  operator: In
                  values:
                    - wallix-bastion
            topologyKey: kubernetes.io/hostname

+===============================================================================+
```

### Helm Deployment Commands

```
+===============================================================================+
|                   HELM DEPLOYMENT COMMANDS                                   |
+===============================================================================+

  INSTALLATION
  ============

  # Add WALLIX Helm repository (if available)
  helm repo add wallix https://charts.wallix.com
  helm repo update

  # Install with default values
  helm install wallix-bastion wallix/wallix-bastion \
    --namespace wallix \
    --create-namespace

  # Install with custom values
  helm install wallix-bastion wallix/wallix-bastion \
    --namespace wallix \
    --create-namespace \
    --values custom-values.yaml \
    --set wallix.adminPassword=SecurePassword \
    --set wallix.licenseKey=XXXX-XXXX-XXXX \
    --set mariadb.auth.password=DbPassword

  # Install from local chart
  helm install wallix-bastion ./wallix-bastion \
    --namespace wallix \
    --create-namespace \
    --values values-production.yaml

  --------------------------------------------------------------------------

  MANAGEMENT
  ==========

  # List releases
  helm list -n wallix

  # Get values
  helm get values wallix-bastion -n wallix

  # Upgrade
  helm upgrade wallix-bastion wallix/wallix-bastion \
    --namespace wallix \
    --values custom-values.yaml

  # Rollback
  helm rollback wallix-bastion 1 -n wallix

  # Uninstall
  helm uninstall wallix-bastion -n wallix

  --------------------------------------------------------------------------

  DEBUG
  =====

  # Dry run
  helm install wallix-bastion wallix/wallix-bastion \
    --namespace wallix \
    --dry-run --debug

  # Template rendering
  helm template wallix-bastion wallix/wallix-bastion \
    --namespace wallix \
    --values custom-values.yaml

+===============================================================================+
```

---

## OpenShift Deployment

### OpenShift-Specific Configuration

```
+===============================================================================+
|                   OPENSHIFT DEPLOYMENT                                       |
+===============================================================================+

  SECURITY CONTEXT CONSTRAINTS
  ============================

  # wallix-scc.yaml
  apiVersion: security.openshift.io/v1
  kind: SecurityContextConstraints
  metadata:
    name: wallix-scc
  allowPrivilegedContainer: false
  allowedCapabilities:
    - NET_BIND_SERVICE
  runAsUser:
    type: MustRunAsRange
    uidRangeMin: 1000
    uidRangeMax: 65535
  seLinuxContext:
    type: MustRunAs
  fsGroup:
    type: MustRunAs
  volumes:
    - configMap
    - downwardAPI
    - emptyDir
    - persistentVolumeClaim
    - projected
    - secret
  users:
    - system:serviceaccount:wallix:wallix-sa

  --------------------------------------------------------------------------

  ROUTE CONFIGURATION
  ===================

  # wallix-route.yaml
  apiVersion: route.openshift.io/v1
  kind: Route
  metadata:
    name: wallix-bastion
    namespace: wallix
  spec:
    host: wallix.apps.openshift.company.com
    port:
      targetPort: https
    tls:
      termination: passthrough
    to:
      kind: Service
      name: wallix-bastion-svc
      weight: 100
    wildcardPolicy: None

  --------------------------------------------------------------------------

  DEPLOYMENT WITH OPENSHIFT
  =========================

  # Using oc CLI
  oc new-project wallix

  # Apply SCC
  oc apply -f wallix-scc.yaml

  # Create service account
  oc create serviceaccount wallix-sa -n wallix

  # Add SCC to service account
  oc adm policy add-scc-to-user wallix-scc \
    system:serviceaccount:wallix:wallix-sa

  # Deploy using Helm with OpenShift values
  helm install wallix-bastion ./wallix-bastion \
    --namespace wallix \
    --values values-openshift.yaml

+===============================================================================+
```

---

## Container Security

### Security Best Practices

```
+===============================================================================+
|                   CONTAINER SECURITY                                         |
+===============================================================================+

  IMAGE SECURITY
  ==============

  +------------------------------------------------------------------------+
  | Practice                        | Implementation                       |
  +---------------------------------+--------------------------------------+
  | Use official images             | wallix/bastion from trusted registry |
  | Scan for vulnerabilities        | Trivy, Clair, or cloud-native scans  |
  | Use specific tags               | :12.1.1 not :latest                  |
  | Verify image signatures         | cosign, Notary                       |
  | Use read-only root filesystem   | Where possible                       |
  +---------------------------------+--------------------------------------+

  --------------------------------------------------------------------------

  RUNTIME SECURITY
  ================

  +------------------------------------------------------------------------+
  | Practice                        | Implementation                       |
  +---------------------------------+--------------------------------------+
  | Run as non-root                 | securityContext.runAsNonRoot: true   |
  | Drop capabilities               | Drop ALL, add only needed            |
  | Read-only filesystem            | readOnlyRootFilesystem: true         |
  | Resource limits                 | Set CPU/memory limits                |
  | Network policies                | Restrict pod-to-pod traffic          |
  +---------------------------------+--------------------------------------+

  Security Context Example:

  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
    capabilities:
      drop:
        - ALL
      add:
        - NET_BIND_SERVICE

  --------------------------------------------------------------------------

  NETWORK POLICIES
  ================

  # wallix-network-policy.yaml
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: wallix-bastion-policy
    namespace: wallix
  spec:
    podSelector:
      matchLabels:
        app: wallix-bastion
    policyTypes:
      - Ingress
      - Egress
    ingress:
      - from:
          - namespaceSelector:
              matchLabels:
                name: ingress-nginx
        ports:
          - protocol: TCP
            port: 443
      - from:
          - ipBlock:
              cidr: 10.0.0.0/8  # Internal users
        ports:
          - protocol: TCP
            port: 22
          - protocol: TCP
            port: 3389
    egress:
      - to:
          - podSelector:
              matchLabels:
                app: wallix-db
        ports:
          - protocol: TCP
            port: 3306
      - to:
          - ipBlock:
              cidr: 10.0.0.0/8  # Target systems
        ports:
          - protocol: TCP
            port: 22
          - protocol: TCP
            port: 3389

  --------------------------------------------------------------------------

  SECRETS MANAGEMENT
  ==================

  +------------------------------------------------------------------------+
  | Practice                        | Implementation                       |
  +---------------------------------+--------------------------------------+
  | Use external secrets            | HashiCorp Vault, AWS Secrets Manager |
  | Encrypt secrets at rest         | Enable etcd encryption               |
  | Rotate secrets regularly        | Automated rotation policies          |
  | Audit secret access             | Enable audit logging                 |
  +---------------------------------+--------------------------------------+

  # Using External Secrets Operator
  apiVersion: external-secrets.io/v1beta1
  kind: ExternalSecret
  metadata:
    name: wallix-secrets
    namespace: wallix
  spec:
    refreshInterval: 1h
    secretStoreRef:
      name: vault-backend
      kind: ClusterSecretStore
    target:
      name: wallix-secrets
    data:
      - secretKey: admin-password
        remoteRef:
          key: secret/wallix
          property: admin-password
      - secretKey: db-password
        remoteRef:
          key: secret/wallix
          property: db-password

+===============================================================================+
```

---

## Next Steps

Continue to [26 - API Reference](../26-api-reference/README.md) for complete API documentation.
