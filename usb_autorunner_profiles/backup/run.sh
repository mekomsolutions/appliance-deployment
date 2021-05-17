#!/usr/bin/env bash
set -e
kubectl="/usr/local/bin/k3s kubectl" 
# Get NFS IP address
registry_ip=`$kubectl get svc registry-service -o json | jq '.spec.loadBalancerIP' | tr -d '"'`
# Get USB mount point
usb_mount_point=`grep "mount_point" /opt/autorunner/usbinfo | cut -d'=' -f2 | tr -d '"'`

echo "⚙️ Delete old usb backup jobs"
$kubectl delete job -l app=usb-backup

echo "⚙️ Run Filestore backup job"
# Backup filestore
cat <<EOF | $kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: filestore-data-backup
  labels:
    app: usb-backup
spec:
  template:
    spec:
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: data-pvc
        - name: backup-path
          hostPath:
            path: "${usb_mount_point}"
      containers:
      - name: data-backup
        image: ${registry_ip}/mekomsolutions/filestore_backup:latest
        env:
          - name: FILESTORE_PATH
            value: /opt/data
        volumeMounts:
        - name: data
          mountPath: "/opt/data"
          subPath: "./"
        - name: backup-path
          mountPath: /opt/backup
      restartPolicy: Never
EOF

mysql_app=`$kubectl get statefulsets.apps | grep 'mysql'`
if [ -n "$mysql_app" ] ; then
# Backup MySQL
echo "⚙️ Fetch MySQL credentials"
mysql_root_user=`$kubectl get configmap mysql-configs -o json | jq '.data.MYSQL_ROOT_USER' | tr -d '"'`
mysql_root_password=`$kubectl get configmap mysql-configs -o json | jq '.data.MYSQL_ROOT_PASSWORD' | tr -d '"'`
mysql_databases=`$kubectl exec -ti mysql-0 -- mysql -u $mysql_root_user -p$mysql_root_password -BNe "show databases;"`

echo "⚙️ Run MySQL backup jobs"
# Backup MySQL Databases
for database in $mysql_databases
do
hash=`cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 7 | head -n 1`
cat <<EOF | $kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: mysql-$hash-db-backup
  labels:
    app: usb-backup
spec:
  template:
    spec:
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: data-pvc
        - name: backup-path
          hostPath:
            path: "${usb_mount_point}/mysql"
      containers:
      - name: mysql-db-backup
        image: ${registry_ip}/mekomsolutions/mysql_backup:latest
        env:
          - name: DB_NAME
            value: ${database}
          - name: DB_USERNAME
            value: ${mysql_root_user}
          - name: DB_PASSWORD
            value: ${mysql_root_password}
          - name: DB_HOST
            value: mysql
        volumeMounts:
        - name: backup-path
          mountPath: /opt/backup
      restartPolicy: Never
EOF
done
else
echo "⚙️ MySQL service is not found, abort"
fi

postgres_app=`$kubectl get statefulsets.apps | grep 'postgres'`
if [ -n "$postgres_app" ] ; then
# Backup PostgreSQL databases
echo "⚙️ Fetch PostgreSQL credentials and database names"
postgres_user=`$kubectl get configmap postgres-configs -o json | jq '.data.POSTGRES_USER' | tr -d '"'`
postgres_password=`$kubectl get configmap postgres-configs -o json | jq '.data.POSTGRES_PASSWORD' | tr -d '"'`
postgres_databases=`kubectl exec -ti postgres-0 -- psql -n -U $postgres_user --pset="footer=off" --pset="border=0" --pset="tuples_only=on" -c "SELECT datname FROM pg_database;"`

echo "⚙️ Run PostgreSQL backup jobs"
# Backup PostgreSQL Databases
for database in $postgres_databases
do
hash=`cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 7 | head -n 1`
cat <<EOF | $kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: postgres-$hash-db-backup
  labels:
    app: usb-backup
spec:
  template:
    spec:
      volumes:
        - name: backup-path
          hostPath:
            path: "${usb_mount_point}/postgres"
      containers:
      - name: postgres-db-backup
        image: ${registry_ip}/mekomsolutions/postgres_backup:latest
        env:
          - name: DB_HOST
            value: postgres
          - name: DB_NAME
            value: ${database}
          - name: DB_USERNAME
            value: ${postgres_user}
          - name: DB_PASSWORD
            value: ${postgres_password}
        volumeMounts:
        - name: backup-path
          mountPath: /opt/backup
      restartPolicy: Never
EOF
done
else
echo "⚙️ PostgreSQL service is not found, abort"
fi
