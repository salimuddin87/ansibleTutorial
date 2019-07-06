#!/bin/bash

# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET

wpCount=$1
cluster_name=$2
tmpl_dir=$3

while true
do
   # running a command on the amvdb container gives false OK: 
   # kubectl -n $cluster_name exec -it queen -c amvdb /usr/bin/df 
   # above cmd succeeds even when amvdb container status is not running and ready

   # get amvdb container status from kubernetes
   # uncut output looks like this: map[running:map[startedAt:2018-05-16T21:53:45Z]]
   # cut output looks like this: running
   amvStatus=`kubectl get -n $cluster_name -o=jsonpath='{.status.containerStatuses[?(@.name=="amvdb")].state}' pod queen | cut -d [ -f 2 | cut -d : -f 1`

   # get amvdb container ready flag from kubernetes
   amvReady=`kubectl get -n $cluster_name -o=jsonpath='{.status.containerStatuses[?(@.name=="amvdb")].ready}' pod queen`

   # is amvdb container running and ready?
   if [[ $amvStatus == "running" ]]; then
      if [[ $amvReady == "true" ]]; then
         echo "amv is running and ready."
         break
      fi
      echo "amv is not ready."
   fi
   sleep 5
done

while true
do
   ip=`kubectl get -o template po queen --namespace=$cluster_name --template={{.status.podIP}} 2>/dev/null`
   # no need to check for valid quads here as k8s will assign valid IP
   # need this check to avoid any other errors
   echo $ip
   if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      break
   else
      echo "fail"
   fi
   sleep 5
done

for i in `seq 1 ${wpCount}`
do
    sed -i '/SYSMAN_IP/{ n;s/.*/          value : '\"$ip\"'/g}' $tmpl_dir/worker${i}-pod.yaml
done
