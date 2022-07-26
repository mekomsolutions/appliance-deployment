#!/usr/bin/env bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}"; )" &> /dev/null && pwd 2> /dev/null; )";
REGISTRY_IP=${REGISTRY_IP:-10.0.90.99}
kubectl_bin="/usr/local/bin/k3s kubectl"
: "${NAMESPACE:=default}"
MONITOR_NAMESPACE="monitoring"

POD_NAME=$($kubectl_bin get pod -l app=registry -o jsonpath="{.items[0].metadata.name}" -n $NAMESPACE)
$kubectl_bin wait --for=condition=ready --timeout 1800s pod $POD_NAME -n $NAMESPACE

# Sync images to registry
echo "⚙️  Upload container images to the registry at $REGISTRY_IP..."
for dir in $SCRIPT_DIR/images/*/ ; do
    cd $dir && skopeo sync --scoped --dest-tls-verify=false --src dir --dest docker ./ $REGISTRY_IP
done

# Create namespace
echo "⚙️  Create namespace for monitoring"
$kubectl_bin create namespace $MONITOR_NAMESPACE

# Create Persistent Volume Claims
echo "⚙️  Create PVCs for monitoring"
$kubectl_bin apply -f $SCRIPT_DIR/monitoring-pvc.yml

# Apply K8s Prometheus resources
echo "⚙️  Apply K8s Prometheus manifests..."
$kubectl_bin apply -n $MONITOR_NAMESPACE -f $SCRIPT_DIR/k8s/prometheus -R

echo "✅  Done."
