#!/bin/bash
set -e

docker-compose down
docker volume prune -f
rm -f kubeconfig-cp.yaml kubeconfig-cc.yaml
rm -rf .helm-cp/ .helm-cc/
