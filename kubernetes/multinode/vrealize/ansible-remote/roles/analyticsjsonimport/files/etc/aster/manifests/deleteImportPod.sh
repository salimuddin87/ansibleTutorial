#!/bin/bash

# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET

# Delete analyticjsonimport-pod once the status is Succeeded as no work is left for the pod to complete .
# If Pod status gets failed , exit
# Usage:
#        deleteImportPod.sh namespace podfile

if [ "$#" -ne 2 -o -z $1 -o -z $2 ]; then
   echo "ERROR: namespace or podfile not passed. "
   echo "Usage: deleteImportPod.sh namespace podfile "
   echo "Exiting..."
   exit 1
fi

namespace=$1
podfile=$2

while true
   do
      PodIp=`kubectl get -o template po analyticjsonimport -n $namespace --template={{.status.podIP}} 2>/dev/null`
      Status=`kubectl get pods analyticjsonimport -n $namespace --template={{.status.phase}}`

      if [[ $PodIp =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ && $Status == Succeeded ]]; then  
         echo "Deleting upgradeimport Pod "
         kubectl delete -f $podfile -n $namespace
         break
      else
         echo “Still waiting for the analyticjsonimport pod to be completed...”
      fi
      
      if [[ $Status == Failed ]]; then
         echo "Pod status is failed. Exiting..."
         exit 1
      fi
   
      sleep 5

   done
