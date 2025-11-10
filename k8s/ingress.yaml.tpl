apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tasky-ingress
  namespace: tasky
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
    alb.ingress.kubernetes.io/subnets: ${public_subnets}
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: tasky-service
            port:
              number: 80

