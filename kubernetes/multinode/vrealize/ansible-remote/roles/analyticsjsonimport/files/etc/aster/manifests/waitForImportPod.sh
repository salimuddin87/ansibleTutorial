#!/bin/bash

# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET

# wait for analyticjsonimport,  until pod is up and running
# we are adding this check as image pulling from artifactory takes time even
# though kubectl pod create command returns successful. Pods might not up and
# running .If any problem occurs in container running , playbook has to fail .
#
# Usage:
#        waitForImportPod.sh namespace


if [ "$#" -ne 1 -o -z $1 ]; then
   echo "ERROR: namespace not passed. "
   echo "Usage: waitForImportPod.sh namespace "
   echo "Exiting..."
   exit 1
fi

namespace=$1

while true
   do
      PodIp=`kubectl get -o template po analyticjsonimport -n $namespace --template={{.status.podIP}} 2>/dev/null`
      Status=`kubectl get pods analyticjsonimport -n $namespace --template={{.status.phase}}`

      if [[ $PodIp =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ && $Status == Succeeded || $Status == Running ]]; then
         break
      elif [[ $PodIp =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ && $Status == Failed ]]; then
         echo “Pod status is failed .Exiting...”
         exit 1
      else
         echo “Still waiting for the analyticjsonimport pods to be running ....”
      fi

      sleep 5

   done
