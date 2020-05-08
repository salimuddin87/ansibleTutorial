#!/bin/bash

# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET

# Copy analyticjsonexport-pod logs once the status is Succeeded or Failed.
# Usage:
#        copyLogs.sh namespace localpath

if [ "$#" -ne 2 -o -z $1 -o -z $2 ]; then
   echo "ERROR: namespace or localpath not passed. "
   echo "Usage: copyLogs.sh namespace localpath "
   echo "Exiting..."
   exit 1
fi

namespace=$1
localpath=$2

while true
   do
      PodIp=`kubectl get -o template po analyticjsonexport -n $namespace --template={{.status.podIP}} 2>/dev/null`
      Status=`kubectl get pods analyticjsonexport -n $namespace --template={{.status.phase}}`

      if [[ $PodIp =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ && $Status == Succeeded ]]; then  
         echo "Copying analyticjsonexport Pod logs"
         kubectl logs analyticjsonexport analytic-json-export -n $namespace >> $localpath/udfJsonExport.log
         break
      else
         echo “Still waiting for the analyticjsonexport pod to be completed...”
      fi
      
      if [[ $Status == Failed ]]; then
         echo "Pod status is failed. Copying analyticjsonexport Pod logs"
         kubectl logs analyticjsonexport analytic-json-export -n $namespace >> $localpath/udfJsonExport.log
         break
      fi
   
      sleep 5

   done
