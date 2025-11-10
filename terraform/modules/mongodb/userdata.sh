#!/bin/bash
set -e

apt-get update

wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list
apt-get update
apt-get install -y mongodb-org=4.4.18 mongodb-org-server=4.4.18 mongodb-org-shell=4.4.18 mongodb-org-mongos=4.4.18 mongodb-org-tools=4.4.18

wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
apt-get update
apt-get install -y mongodb-mongosh || apt-get install -y mongodb-database-tools

echo "mongodb-org hold" | dpkg --set-selections
echo "mongodb-org-server hold" | dpkg --set-selections

cat > /etc/mongod.conf <<EOF
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 0.0.0.0

security:
  authorization: enabled

processManagement:
  timeZoneInfo: /usr/share/zoneinfo
EOF

systemctl start mongod
systemctl enable mongod

sleep 10

sed -i 's/authorization: enabled/authorization: disabled/' /etc/mongod.conf
systemctl restart mongod
sleep 5

mongo admin --eval 'db.createUser({user: "admin", pwd: "SecureP@ssw0rd123", roles: [{role: "root", db: "admin"}]})'

sed -i 's/authorization: disabled/authorization: enabled/' /etc/mongod.conf
systemctl restart mongod
sleep 5

mongo go-mongodb -u admin -p 'SecureP@ssw0rd123' --authenticationDatabase admin --eval 'db.createUser({user: "tasky", pwd: "TaskAppPass123", roles: [{role: "readWrite", db: "go-mongodb"}]})'

apt-get install -y awscli

cat > /usr/local/bin/backup-mongodb.sh <<BACKUPSCRIPT
#!/bin/bash
BACKUP_DIR="/tmp/mongodb-backup"
TIMESTAMP=\$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="mongodb-backup-\$TIMESTAMP.gz"
BUCKET_NAME="${backup_bucket}"

mongodump --uri="mongodb://admin:SecureP@ssw0rd123@localhost:27017" --out=\$BACKUP_DIR --gzip
cd \$BACKUP_DIR
tar -czf /tmp/\$BACKUP_FILE .
aws s3 cp /tmp/\$BACKUP_FILE s3://\$BUCKET_NAME/\$BACKUP_FILE
rm -rf \$BACKUP_DIR /tmp/\$BACKUP_FILE
BACKUPSCRIPT

chmod +x /usr/local/bin/backup-mongodb.sh
echo "0 2 * * * root /usr/local/bin/backup-mongodb.sh >> /var/log/mongodb-backup.log 2>&1" > /etc/cron.d/mongodb-backup