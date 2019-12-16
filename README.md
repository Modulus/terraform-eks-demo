# TODO 
- create tests for metrics-server
- create testes for pod autoscaler 
- create tests for ingress controller

# Metrics Server
sh metrics-server
see bases/metrics-server and/or /tmp/metrics-server

# Auth
kubectl describe configmap -n kube-system aws-auth

edit this and reapply it


# Cluster autoscaler
https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml


# Vertical Pod Autoscaler
https://docs.aws.amazon.com/eks/latest/userguide/vertical-pod-autoscaler.html


### TODO: Husk å fjerne configMap fra base og heller merge med config-map med navn: aws-auth