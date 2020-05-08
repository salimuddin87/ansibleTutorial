#!/bin/bash

# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET

# Copy analyticjsonimport-pod logs once the status is Succeeded or Failed.
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
      PodIp=`kubectl get -o template po analyticjsonimport -n $namespace --template={{.status.podIP}} 2>/dev/null`
      Status=`kubectl get pods analyticjsonimport -n $namespace --template={{.status.phase}}`

      if [[ $PodIp =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ && $Status == Succeeded ]]; then  
         echo "Copying analyticjsonimport pod logs"
         kubectl logs analyticjsonimport analytic-json-import -n $namespace >> $localpath/udfJsonImport.log
         break
      else
         echo “Still waiting for the analyticjsonimport pod to be completed...”
      fi
      
      if [[ $Status == Failed ]]; then
         echo "Pod status is failed. Copying analyticjsonimport pod logs."
         kubectl logs analyticjsonimport analytic-json-import -n $namespace >> $localpath/udfJsonImport.log
         break
      fi
   
      sleep 5

   done
