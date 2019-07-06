#!/bin/bash

# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET

# Delete upgradeexport once the status is Succeeded as no work is left for the pod to complete .
# If Pod status gets failed , exit
# Usage:
#        deleteExportPod.sh namespace podfile

if [ "$#" -ne 2 -o -z $1 -o -z $2 ]; then
   echo "ERROR: namespace or podfile not passed. "
   echo "Usage: deleteExportPod.sh namespace podfile "
   echo "Exiting..."
   exit 1
fi

namespace=$1
podfile=$2

while true
   do
      PodIp=`kubectl get -o template po upgradeexport -n $namespace --template={{.status.podIP}} 2>/dev/null`
      Status=`kubectl get pods upgradeexport -n $namespace --template={{.status.phase}}`

      if [[ $PodIp =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ && $Status == Succeeded ]]; then  
         echo "Deleting upgradeexport Pod "
         kubectl delete -f $podfile -n $namespace
         break
      else
         echo “Still waiting for the upgradeexport pod to be completed...”
      fi
      
      if [[ $Status == Failed ]]; then
         echo "Pod status is failed. Exiting..."
         exit 1
      fi
   
      sleep 5

   done
