# Copyright (c) 2016 by bad_db Corporation. All rights reserved.
# tddb CORPORATION CONFIDENTIAL AND TRADE SECRET

# start all aster pods

kubectl create -f /vagrant/aster/queen-pod.yaml
kubectl get pods --all-namespaces

while true ;
   do sysmanIp=`kubectl get -o template po queen \
      --namespace=cloud-aster --template={{.status.podIP}}`;
      # no need to check for valid quads here as k8s will assign valid IP
      # need this check to avoid any other errors
      #echo $sysmanIp
      if [[ $sysmanIp =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] ; then
         break;
      fi;
      sleep 5
done;

kubectl create -f /vagrant/aster/worker-pod.yaml
kubectl get pods --all-namespaces

while true ;
   do workerOnePodIp=`kubectl get -o template po worker \
      --namespace=cloud-aster --template={{.status.podIP}}`;
      #echo $workerOnePodIp
      if [[ $workerOnePodIp =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] ; then
         break;
      fi;
      sleep 5
done;

kubectl create -f /vagrant/aster/worker2-pod.yaml
kubectl get pods --all-namespaces

while true ;
   do workerTwoPodIp=`kubectl get -o template po worker2 \
      --namespace=cloud-aster --template={{.status.podIP}}`;
      #echo $workerTwoPodIp
      if [[ $workerTwoPodIp =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] ; then
         break;
      fi;
      sleep 5
done;

