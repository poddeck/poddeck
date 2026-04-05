# PodDeck Deployment

Deploy [PodDeck](https://github.com/poddeck) — a multi-cluster Kubernetes management dashboard.

## Architecture

```
┌─────────────────────────────────────────────────┐
│  Control Plane (deployed once)                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │
│  │  Panel    │→ │  Core    │──│  PostgreSQL  │  │
│  │  :80      │  │ :8080 API│  │              │  │
│  │           │  │ :10101   │  │              │  │
│  └──────────┘  │  gRPC    │  └──────────────┘  │
│                └──────────┘                     │
└───────────────────┬─────────────────────────────┘
                    │ gRPC :10101
    ┌───────────────┼───────────────┐
    ▼               ▼               ▼
┌─────────┐   ┌─────────┐   ┌─────────┐
│ Agent   │   │ Agent   │   │ Agent   │
│Cluster A│   │Cluster B│   │Cluster C│
└─────────┘   └─────────┘   └─────────┘
```

**Control Plane** — Core API + Panel UI + PostgreSQL. Deploy once on a VM or Kubernetes cluster.

**Agent** — One per managed cluster. Connects to the control plane via gRPC. Deploy after creating a cluster in the PodDeck UI.

---

## Option 1: Docker Compose

Best for VMs, bare metal, or local testing.

### Quick Start

```sh
cd docker
cp .env.example .env
```

Edit `.env` with your configuration:

```sh
# Generate JWT secrets
openssl rand -hex 16  # use for AUTH_KEY
openssl rand -hex 16  # use for REFRESH_KEY

# Set your database password
DB_PASSWORD=your-secure-password

# Set the hostname that agents will use to connect (must be reachable from K8s clusters)
GRPC_HOST=poddeck.example.com
```

Start the control plane:

```sh
docker compose up -d
```

PodDeck is now accessible at `http://localhost` (or the port configured in `PANEL_PORT`).

### Ports

| Port | Service | Purpose |
|------|---------|---------|
| 80 | Panel | Web UI |
| 10101 | Core (gRPC) | Agent connections — must be reachable from managed clusters |

---

## Option 2: Helm (Kubernetes)

Best for production deployments on Kubernetes.

### Prerequisites

- Helm 3.x
- A Kubernetes cluster for the control plane

### Install Control Plane

```sh
helm repo add poddeck https://poddeck.github.io/poddeck-charts
helm repo update
```

Using the provided values file:

```sh
# Edit helm/values-control-plane.yaml with your settings
helm install poddeck poddeck/poddeck -f helm/values-control-plane.yaml
```

Or inline:

```sh
helm install poddeck poddeck/poddeck \
  --set postgresql.auth.password=your-db-password \
  --set core.grpcHost=poddeck.example.com
```

JWT keys are auto-generated if not provided.

### Install Agent (per cluster)

After deploying the control plane:

1. Open the PodDeck UI
2. Go to the **Cluster** page
3. Click **+ Add cluster**, fill in name and icon
4. The **Deploy Agent** dialog will show a Helm command with your cluster credentials pre-filled
5. Run the command in the target Kubernetes cluster

Or manually:

```sh
helm install poddeck-agent poddeck/poddeck-agent \
  --set core.hostname=poddeck.example.com \
  --set core.port=10101 \
  --set cluster.id=<CLUSTER_ID> \
  --set cluster.key=<AGENT_KEY>
```

The `cluster.id` and `cluster.key` are provided by the PodDeck UI when you create a cluster.

---

## Network Requirements

The gRPC port (default `10101`) on the control plane **must be reachable** from every managed Kubernetes cluster. Ensure:

- Firewall rules allow inbound TCP on the gRPC port
- DNS or IP is resolvable from the managed clusters
- For Helm deployments, the `core.grpcService.type: LoadBalancer` creates an external endpoint automatically

---

## Configuration Reference

### Docker (.env)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DB_PASSWORD` | Yes | — | PostgreSQL password |
| `AUTH_KEY` | Yes | — | JWT signing key (32 hex chars) |
| `REFRESH_KEY` | Yes | — | JWT refresh key (32 hex chars) |
| `GRPC_HOST` | Yes | `localhost` | Hostname for agent connections |
| `GRPC_PORT` | No | `10101` | gRPC port |
| `PANEL_PORT` | No | `80` | Panel web UI port |
| `ALLOWED_ORIGINS` | No | `http://localhost` | CORS origins |
| `DB_USERNAME` | No | `poddeck` | PostgreSQL username |
| `DB_DATABASE` | No | `poddeck` | PostgreSQL database name |

### Helm (Control Plane)

See [`helm/values-control-plane.yaml`](helm/values-control-plane.yaml) for all available values.

### Helm (Agent)

See [`helm/values-agent.yaml`](helm/values-agent.yaml) for all available values.
