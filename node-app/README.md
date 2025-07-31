# Node.js Application Helm Chart

A Helm chart for deploying Node.js applications to Kubernetes.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+

## Installing the Chart

To install the chart with the release name `my-node-app`:

```bash
helm install my-node-app ./helm-charts/node-app
```

## Configuration

The following table lists the configurable parameters of the node-app chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Container image repository | `europe-west1-docker.pkg.dev/your-project/node-app-repo/node-app` |
| `image.tag` | Container image tag | `latest` |
| `image.pullPolicy` | Container image pull policy | `IfNotPresent` |
| `service.type` | Kubernetes service type | `NodePort` |
| `service.port` | Kubernetes service port | `8080` |
| `service.nodePort` | Kubernetes service node port | `30000` |
| `resources.limits.cpu` | CPU resource limits | `200m` |
| `resources.limits.memory` | Memory resource limits | `256Mi` |
| `resources.requests.cpu` | CPU resource requests | `100m` |
| `resources.requests.memory` | Memory resource requests | `128Mi` |
| `env.NODE_ENV` | Node.js environment | `production` |
| `env.PORT` | Application port | `8080` |
| `livenessProbe.enabled` | Enable liveness probe | `true` |
| `livenessProbe.path` | Liveness probe path | `/health` |
| `readinessProbe.enabled` | Enable readiness probe | `true` |
| `readinessProbe.path` | Readiness probe path | `/health` |
| `autoscaling.enabled` | Enable horizontal pod autoscaling | `false` |

## Examples

### Basic Installation

```bash
helm install my-node-app ./helm-charts/node-app
```

### Custom Image Repository

```bash
helm install my-node-app ./helm-charts/node-app \
  --set image.repository=europe-west1-docker.pkg.dev/my-project/my-repo/node-app \
  --set image.tag=v1.0.0
```

### Multiple Replicas with Autoscaling

```bash
helm install my-node-app ./helm-charts/node-app \
  --set replicaCount=3 \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=2 \
  --set autoscaling.maxReplicas=10
```

### Custom Environment Variables

```bash
helm install my-node-app ./helm-charts/node-app \
  --set env.NODE_ENV=staging \
  --set env.PORT=3000 \
  --set env.DATABASE_URL=postgresql://user:pass@host:5432/db
```

### LoadBalancer Service Type

```bash
helm install my-node-app ./helm-charts/node-app \
  --set service.type=LoadBalancer
```

## Upgrading the Chart

To upgrade the chart:

```bash
helm upgrade my-node-app ./helm-charts/node-app
```

## Uninstalling the Chart

To uninstall/delete the `my-node-app` deployment:

```bash
helm uninstall my-node-app
```

## Health Checks

The chart includes configurable liveness and readiness probes that check the `/health` endpoint by default. Make sure your Node.js application implements this endpoint.

Example health endpoint implementation:

```javascript
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});
```

## Accessing the Application

After installation, you can access the application using the commands provided in the Helm output notes, or by running:

```bash
# For NodePort service type
kubectl get svc my-node-app -o jsonpath='{.spec.ports[0].nodePort}'

# For LoadBalancer service type
kubectl get svc my-node-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=node-app
```

### View Pod Logs

```bash
kubectl logs -l app.kubernetes.io/name=node-app
```

### Describe Service

```bash
kubectl describe svc my-node-app
```

### Check Events

```bash
kubectl get events --sort-by='.lastTimestamp'
``` 