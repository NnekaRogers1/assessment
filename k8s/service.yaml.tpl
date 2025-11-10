apiVersion: v1
kind: Service
metadata:
  name: tasky-service
  namespace: tasky
spec:
  selector:
    app: tasky
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: ClusterIP

