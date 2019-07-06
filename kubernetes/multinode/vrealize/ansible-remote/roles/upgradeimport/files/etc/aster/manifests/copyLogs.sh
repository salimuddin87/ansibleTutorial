#!/bin/bash

# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET

# Copy upgradeimport pod logs once the status is Succeeded or Failed.
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
      PodIp=`kubectl get -o template po upgradeimport -n $namespace --template={{.status.podIP}} 2>/dev/null`
      Status=`kubectl get pods upgradeimport -n $namespace --template={{.status.phase}}`

      if [[ $PodIp =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ && $Status == Succeeded ]]; then  
         echo "Copying upgradeimport pod logs"
         kubectl logs upgradeimport mle-metadata-import -n $namespace >> $localpath/metadataImport.log
         break
      else
         echo “Still waiting for the upgradeimport pod to be completed...”
      fi
      
      if [[ $Status == Failed ]]; then
         echo "Pod status is failed. Copying upgradeimport pod logs"
         kubectl logs upgradeimport mle-metadata-import -n $namespace >> $localpath/metadataImport.log
         break
      fi
   
      sleep 5

   done

