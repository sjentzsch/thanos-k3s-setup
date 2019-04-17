#!/bin/bash
set -e

# cluster cp
## Ensure Tiller on kube-system is set-up and up-to-date, so we can install our apps
kubectl --kubeconfig=local-setup/kubeconfig-cp.yaml -n kube-system create serviceaccount tiller --dry-run -o json | kubectl --kubeconfig=local-setup/kubeconfig-cp.yaml apply -f -
kubectl --kubeconfig=local-setup/kubeconfig-cp.yaml create clusterrolebinding tiller --clusterrole=cluster-admin --serviceaccount=kube-system:tiller --dry-run -o json | kubectl --kubeconfig=local-setup/kubeconfig-cp.yaml apply -f -
helm --kubeconfig=local-setup/kubeconfig-cp.yaml --home=local-setup/.helm-cp init --upgrade --wait --tiller-namespace kube-system --service-account tiller

# cluster cc
## Ensure Tiller on kube-system is set-up and up-to-date, so we can install our apps
kubectl --kubeconfig=local-setup/kubeconfig-cc.yaml -n kube-system create serviceaccount tiller --dry-run -o json | kubectl --kubeconfig=local-setup/kubeconfig-cc.yaml apply -f -
kubectl --kubeconfig=local-setup/kubeconfig-cc.yaml create clusterrolebinding tiller --clusterrole=cluster-admin --serviceaccount=kube-system:tiller --dry-run -o json | kubectl --kubeconfig=local-setup/kubeconfig-cc.yaml apply -f -
helm --kubeconfig=local-setup/kubeconfig-cc.yaml --home=local-setup/.helm-cc init --upgrade --wait --tiller-namespace kube-system --service-account tiller

# setup prometheus-cp
cd prometheus-cp
./setup.sh
cd ../

# setup prometheus-cc
cd prometheus-cc
./setup.sh
cd ../
