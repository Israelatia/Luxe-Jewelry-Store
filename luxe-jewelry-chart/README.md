# Luxe Jewelry Store Helm Chart

This Helm chart deploys the Luxe Jewelry Store application on a Kubernetes cluster.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- Ingress controller (e.g., nginx, traefik) if using Ingress

## Installing the Chart

To install the chart with the release name `luxe-jewelry`:

```bash
helm install luxe-jewelry ./luxe-jewelry-chart -n demo-app --create-namespace
```

## Uninstalling the Chart

To uninstall/delete the `luxe-jewelry` deployment:

```bash
helm uninstall luxe-jewelry -n demo-app
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace` | Kubernetes namespace | `demo-app` |
| `backend.replicaCount` | Number of backend replicas | `2` |
| `backend.image.repository` | Backend image repository | `israelatia/luxe-jewelry-store-backend` |
| `backend.image.tag` | Backend image tag | `latest` |
| `backend.service.type` | Backend service type | `ClusterIP` |
| `frontend.replicaCount` | Number of frontend replicas | `2` |
| `frontend.image.repository` | Frontend image repository | `israelatia/luxe-jewelry-store-frontend` |
| `frontend.image.tag` | Frontend image tag | `latest` |
| `frontend.service.type` | Frontend service type | `LoadBalancer` |
| `ingress.enabled` | Enable Ingress | `true` |
| `ingress.hosts[0].host` | Ingress host | `luxe-jewelry.local` |
| `autoscaling.enabled` | Enable autoscaling | `true` |
| `autoscaling.backend.targetCPUUtilizationPercentage` | Backend CPU utilization target | `50` |
| `autoscaling.frontend.targetCPUUtilizationPercentage` | Frontend CPU utilization target | `50` |

For a complete list of configurable parameters, see the `values.yaml` file.

## Accessing the Application

If you're using Minikube, you can access the application using:

```bash
minikube service luxe-jewelry-frontend -n demo-app
```

If you've enabled Ingress, add the following to your `/etc/hosts` file:

```
<minikube-ip> luxe-jewelry.local
```

Then access the application at `http://luxe-jewelry.local`.

## Persistence

By default, the chart creates PersistentVolumeClaims for both the frontend and backend. You can disable this by setting `persistence.enabled` to `false` in your values file.

## Scaling

Horizontal Pod Autoscaling (HPA) is enabled by default. The backend and frontend will scale based on CPU utilization.
