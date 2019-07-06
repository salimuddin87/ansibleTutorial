# Copyright (c) 2016 by bad_db Corporation. All rights reserved.
# tddb CORPORATION CONFIDENTIAL AND TRADE SECRET

# stop all aster pods

kubectl delete -f /vagrant/aster/queen-pod.yaml
kubectl get pods --all-namespaces

kubectl delete -f /vagrant/aster/worker-pod.yaml
kubectl get pods --all-namespaces

kubectl delete -f /vagrant/aster/worker2-pod.yaml
kubectl get pods --all-namespaces
