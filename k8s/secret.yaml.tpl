apiVersion: v1
kind: Secret
metadata:
  name: mongodb-secret
  namespace: tasky
type: Opaque
stringData:
  MONGODB_URI: "mongodb://tasky:TaskAppPass123@${mongodb_ip}:27017/go-mongodb?authSource=go-mongodb"
  SECRET_KEY: "7Dol1Cqlx6Y8XzK30336SKDuxW42qJ"

