#!/bin/bash
set -e

### Basic Setup (Namespace etc.)

kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml apply -f ns.yaml


### Thanos Setup (1/2)

# get IP Address of s3 store with which Thanos can communicate
ip_s3_1=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' local-setup_store-s3_1)

# create Thanos secret to access S3 object store; templated via store-s3-ip (see https://stackoverflow.com/a/415775/860756)
thanos_s3_config_b64=$(sed -e "s/\${store-s3-ip}/${ip_s3_1}/" thanos-s3-config.yaml | base64 -w0)
sed -e "s/\${thanos-s3-config-b64}/${thanos_s3_config_b64}/" ../manifests/thanos-s3-config-secret.yaml | kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml apply -f -

# Thanos store gateway service
kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml apply -f ../manifests/prometheus-thanosStoreGatewayService.yaml


### Prometheus Operator

# see https://github.com/helm/charts/tree/master/stable/prometheus-operator#helm-fails-to-create-crds
kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/alertmanager.crd.yaml
kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheus.crd.yaml
kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheusrule.crd.yaml
kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/servicemonitor.crd.yaml
kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml wait --for=condition=NamesAccepted crd/alertmanagers.monitoring.coreos.com --timeout=10s
kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml wait --for=condition=NamesAccepted crd/prometheuses.monitoring.coreos.com --timeout=10s
kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml wait --for=condition=NamesAccepted crd/prometheusrules.monitoring.coreos.com --timeout=10s
kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml wait --for=condition=NamesAccepted crd/servicemonitors.monitoring.coreos.com --timeout=10s

helm --kubeconfig=../local-setup/kubeconfig-cc.yaml --home=../local-setup/.helm-cc repo update
helm --kubeconfig=../local-setup/kubeconfig-cc.yaml --home=../local-setup/.helm-cc upgrade -i test --wait --namespace monitoring stable/prometheus-operator -f custom-values.yaml --force

# wait until prometheus instance is Ready
until kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml get pod prometheus-test-prometheus-operator-prometheus-0 -n monitoring > /dev/null 2>&1; do sleep 0.5; done
kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml wait --for=condition=Ready pod/prometheus-test-prometheus-operator-prometheus-0 -n monitoring --timeout=60s


### Thanos Setup (2/2)

# Thanos Sidecar
kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml apply -f ../manifests/prometheus-thanosSidecarService.yaml
kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml apply -f ../manifests/prometheus-serviceMonitorThanosSidecar.yaml

# Thanos Querier (exposes http and grpc port)
kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml apply -f ../manifests/prometheus-thanosQueryDeployment-cc.yaml
kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml apply -f ../manifests/prometheus-thanosQueryService-cc.yaml
kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml apply -f ../manifests/prometheus-serviceMonitorThanosQuery.yaml

# Thanos Store
kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml apply -f ../manifests/prometheus-thanosStoreStatefulset.yaml
kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml apply -f ../manifests/prometheus-thanosStoreService.yaml
kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml apply -f ../manifests/prometheus-serviceMonitorThanosStore.yaml

# Thanos Compactor
kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml apply -f ../manifests/prometheus-thanosCompactorStatefulset.yaml
kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml apply -f ../manifests/prometheus-thanosCompactorService.yaml
kubectl --kubeconfig=../local-setup/kubeconfig-cc.yaml apply -f ../manifests/prometheus-serviceMonitorThanosCompactor.yaml
