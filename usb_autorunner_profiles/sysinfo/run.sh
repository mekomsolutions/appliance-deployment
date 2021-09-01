#!/usr/bin/env bash
set +e
DISTRO_NAME=c2c
kubectl="/usr/local/bin/k3s kubectl"
# Get NFS IP address
registry_ip=`$kubectl get svc registry-service -o json | jq '.spec.loadBalancerIP' | tr -d '"'`
# Get USB mount point
usb_mount_point=`grep "mount_point" /opt/autorunner/usbinfo | cut -d'=' -f2 | tr -d '"'`
echo "ℹ️ Archives will be saved in '${usb_mount_point}'"
sysinfo_folder=${usb_mount_point}/sysinfo
mkdir -p ${sysinfo_folder}

ps aux > ${sysinfo_folder}/master1_processes.txt
top -n 1 > ${sysinfo_folder}/top.txt

ping 10.0.90.11 -c 4 -W 3 > ${sysinfo_folder}/ping_worker1.txt
ping 10.0.90.12 -c 4 -W 3 > ${sysinfo_folder}/ping_worker2.txt

$kubectl get nodes -o json > ${sysinfo_folder}/nodes.json
$kubectl get deployment.apps -o json > ${sysinfo_folder}/deployments.json
$kubectl get statefulsets.apps -o json > ${sysinfo_folder}/statefulsets.json
$kubectl get pods -o json > ${sysinfo_folder}/pods.json
$kubectl get jobs -o json > ${sysinfo_folder}/jobs.json
$kubectl get pv -o json > ${sysinfo_folder}/pv.json
$kubectl get pvc -o json > ${sysinfo_folder}/pvc.json

$kubectl describe nodes > ${sysinfo_folder}/nodes.txt
$kubectl describe deployment.apps > ${sysinfo_folder}/deployments.txt
$kubectl describe statefulset.apps > ${sysinfo_folder}/statefulsets.txt
$kubectl describe jobs > ${sysinfo_folder}/jobs.txt
$kubectl describe pods > ${sysinfo_folder}/pods.txt



echo "⚙️  Delete old backup jobs"
$kubectl delete job -l app=usb-backup --ignore-not-found=true
sleep 30

$kubectl get pods -o json > ${sysinfo_folder}/pods_list_after_fix.json

echo "✅ Done."
