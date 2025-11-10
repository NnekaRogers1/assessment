apiVersion: apps/v1
kind: Deployment
metadata:
  name: tasky
  namespace: tasky
  labels:
    app: tasky
spec:
  replicas: 2
  selector:
    matchLabels:
      app: tasky
  template:
    metadata:
      labels:
        app: tasky
    spec:
      serviceAccountName: tasky-sa
      containers:
      - name: tasky
        image: ${ecr_url}:${image_tag}
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: MONGODB_URI
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: MONGODB_URI
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: SECRET_KEY
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
        # TODO: add resource quotas later
