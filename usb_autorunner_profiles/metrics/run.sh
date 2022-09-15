#!/usr/bin/env bash

kubectl="/usr/local/bin/k3s kubectl"

AUTORUNNER_WORKDIR=/opt/usb-autorunner/workdir
PROMETHEUS_METRICS_JOB_NAME=prometheus-snapshot-backup

# Retrieve Docker registry IP address
echo "🗂  Retrieve Docker registry IP."
REGISTRY_IP=${REGISTRY_IP:-10.0.90.99}

# Sync images to registry
echo "⚙️  Upload container images to the registry at $REGISTRY_IP..."
cd $AUTORUNNER_WORKDIR/images/docker.io && skopeo sync --scoped --dest-tls-verify=false --src dir --dest docker ./  $REGISTRY_IP

# Get USB mount point
usb_mount_point=`grep "mount_point" /etc/usb-autorunner/usbinfo | cut -d'=' -f2 | tr -d '"'`
metrics_folder=${usb_mount_point}/metrics-$(date +'%Y-%m-%d_%H-%M')/
echo "ℹ️ Archives will be saved in '${metrics_folder}'"
mkdir -p $metrics_folder

echo "⚙️  Delete old backup jobs"
$kubectl delete job -n monitoring -l app=metrics-backup -n monitoring --ignore-not-found=true

echo "⚙️  Add ConfigMap to 'Get prometheus snapshot'"

cat <<EOF | $kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: get-prometheus-snapshot
  namespace: monitoring
data:
  get_prometheus_snapshot.sh: |
    #!/bin/sh
    set -eu

    snapshot_folder=\`curl -XPOST http://prometheus-server.monitoring/api/v1/admin/tsdb/snapshot | jq ".data.name" -r\`
    
    cp -r /opt/metrics/prometheus_server/snapshots/\$snapshot_folder /opt/output/

    echo "Success."
EOF

echo "⚙️  Get Prometheus snapshot"
# Backup filestore
cat <<EOF | $kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: "${PROMETHEUS_METRICS_JOB_NAME}"
  namespace: monitoring
  labels:
    app: metrics-backup
spec:
  template:
    spec:
      volumes:
        - name: prometheus-data
          persistentVolumeClaim:
            claimName: monitoring-pvc
        - name: output-path
          hostPath:
            path: "${metrics_folder}/"
        - name: snapshot-script
          configMap:
            name: get-prometheus-snapshot
      containers:
      - name: monitoring-metrics
        image: badouralix/curl-jq:alpine
        command: ["sh", "/script/get_prometheus_snapshot.sh"]
        volumeMounts:
        - name: prometheus-data
          mountPath: /opt/metrics
        - name: output-path
          mountPath: /opt/output
        - name: snapshot-script
          mountPath: /script
      restartPolicy: Never
      nodeSelector:
        role: database
EOF

$kubectl -n monitoring wait --for=condition=complete --timeout 3600s job/${PROMETHEUS_METRICS_JOB_NAME}
echo "✅ Prometheus backup complete."
