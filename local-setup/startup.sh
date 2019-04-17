#!/bin/bash
set -e

# startup cp (control-plane) with 2 nodes and cc (customer-cluster) with 2 nodes
docker-compose up -d --scale node-cp=2 --scale node-cc=2

echo "wait until both kubeconfig files are created"
while [ ! -f kubeconfig-cp.yaml ] || [ ! -f kubeconfig-cc.yaml ]
do
  sleep 1
done

# need to adapt cluster server port within kubeconfig (which would otherwise conflict)
sed -i -e 's/localhost:6443/localhost:6443/g' kubeconfig-cp.yaml
sed -i -e 's/localhost:6443/localhost:6444/g' kubeconfig-cc.yaml

echo "wait for all nodes to be ready on both clusters ..."
until [ $(kubectl --kubeconfig=kubeconfig-cp.yaml get nodes | grep -c "Ready") -eq 2 ]; do sleep 1 ; done
until [ $(kubectl --kubeconfig=kubeconfig-cc.yaml get nodes | grep -c "Ready") -eq 2 ]; do sleep 1 ; done

# print cp nodes:
echo "cp nodes:"
kubectl --kubeconfig=kubeconfig-cp.yaml get nodes

# print cc nodes:
echo "cc nodes:"
kubectl --kubeconfig=kubeconfig-cc.yaml get nodes

echo "wait for traefik deployment to be ready on both clusters ... so our k3s clusters are fully set up and ready for action"
until kubectl --kubeconfig=kubeconfig-cp.yaml get deployment traefik -n kube-system > /dev/null 2>&1; do sleep 1; done
kubectl --kubeconfig=kubeconfig-cp.yaml wait --for=condition=available --timeout=120s deployment/traefik -n kube-system
until kubectl --kubeconfig=kubeconfig-cc.yaml get deployment traefik -n kube-system > /dev/null 2>&1; do sleep 1; done
kubectl --kubeconfig=kubeconfig-cc.yaml wait --for=condition=available --timeout=120s deployment/traefik -n kube-system