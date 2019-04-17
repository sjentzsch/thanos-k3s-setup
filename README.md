Deploy a full-fledged Thanos-based setup build on top of Prometheus-Operator locally on k3s and Minio.

Features:
* k3s-based lightweight Kubernetes (https://github.com/rancher/k3s) spinning up two clusters with each two nodes
* remote S3 storage via Minio (https://github.com/minio/minio)
* Thanos global view across the clusters: Control-plane (`cp`) has access to the metrics of the customer-cluster (`cc`)
* Grafana connected to Thanos Query within `cp`
* automated via bash scripts (using `docker-compose`, `docker`, `helm`, `kubectl`)
* manifests for all Thanos component (except `Ruler`)

This work is meant for testing only, in order to understand each component, and not at all production-ready.

# Requirements
Make sure you have `docker`, `docker-compose`, `kubectl` and `helm` installed and set up in your `PATH`.

# Setup Kubernetes clusters (local)
Within `local-setup/` run `./startup.sh`.

# Deploy and setup Prometheus-Thanos setup
Run `./setup-all`.

# Work with it
e.g. run:
```
kubectl --kubeconfig=local-setup/kubeconfig-cc.yaml get pods --all-namespaces
helm --kubeconfig=local-setup/kubeconfig-cc.yaml --home=local-setup/.helm-cc list
```

## UIs on localhost:
* Prometheus cp: `http://localhost:21090`
* Prometheus cc: `http://localhost:22090`
* Thanos cp: `http://localhost:21190`
* Thanos cc: `http://localhost:22190`
* Grafana cp: `http://localhost:21300` (username: `admin`, password: `admin123`)
* S3 (Minio): `http://localhost:19000` (username: `admin`, password: `admin123`)

## Thanos Dashboards
Grafana Dashboards for Thanos components are not yet automatically deployed. Feel free to import them in Grafana (see `dashboards/`).

# Cleanup (full)
Within `local-setup/` run `./cleanup.sh`.
