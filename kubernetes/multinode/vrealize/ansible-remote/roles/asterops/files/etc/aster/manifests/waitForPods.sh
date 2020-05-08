#!/bin/bash

# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET

# wait for all pods (queen and workers) until they are up and running
# we are adding this check as image pulling from artifactory takes time even
# though kubectl pod create command returns successful. Pods might not up and
# running, so user won't be able to run queries
#
# Usage:
#        waitForPods.sh [number of workerpods]
#        Optional variable, number of workerpods in configuration
#        default number of workerpods set to 2

if [[ -z $1 ]]; then
   echo "ERROR: ${0}: workerpod count not set. Exiting..."
   exit 1
fi

wpCount=`expr $1 - 1`
cluster_name=$2

#no need to check for queen pod since we took care of it while executing waitTillQueenPodUp.sh script
for currentCount in `seq 0 ${wpCount}`
do
   while true
   do
      workerPodIp=`$KUBECTL get -o template po worker-${currentCount} -n $cluster_name --template={{.status.podIP}} 2>/dev/null`
      status=`$KUBECTL get pods worker-${currentCount} -n $cluster_name --template={{.status.phase}}`
      echo "worker-${currentCount} ip address is $workerPodIp"
      if [[ $workerPodIp =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ && $status == Running ]]; then
         break
      else
         echo “Still waiting for the worker pods to be running ....”
      fi
      sleep 5
   done
done
