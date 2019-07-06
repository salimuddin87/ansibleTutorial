#!/bin/bash

# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET

# Copy upgradeexport pod logs once the status is Succeeded or Failed.
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
      PodIp=`kubectl get -o template po upgradeexport -n $namespace --template={{.status.podIP}} 2>/dev/null`
      Status=`kubectl get pods upgradeexport -n $namespace --template={{.status.phase}}`

      if [[ $PodIp =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ && $Status == Succeeded ]]; then  
         echo "Copying upgradeexport Pod logs"
         kubectl logs upgradeexport mle-metadata-export -n $namespace >> $localpath/metadataExport.log
         break
      else
         echo “Still waiting for the upgradeexport pod to be completed...”
      fi  
    
      if [[ $Status == Failed ]]; then
         echo "Pod status is failed. Copying upgradeexport pod logs"
         kubectl logs upgradeexport mle-metadata-export -n $namespace >> $localpath/metadataExport.log
         break
      fi  
   
      sleep 5

   done

