#!/bin/bash

# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET

cluster_name=$1

while true
do
   # running a command on the amvdb container gives false OK:
   # kubectl -n $cluster_name exec -it queen -c amvdb /usr/bin/df
   # above cmd succeeds even when amvdb container status is not running and ready

   # get amvdb container status from kubernetes
   # uncut output looks like this: map[running:map[startedAt:2018-05-16T21:53:45Z]]
   # cut output looks like this: running
   amvStatus=`$KUBECTL get -n $cluster_name -o=jsonpath='{.status.containerStatuses[?(@.name=="amvdb")].state}' pod queen-0 | cut -d [ -f 2 | cut -d : -f 1`

   # get amvdb container ready flag from kubernetes
   amvReady=`$KUBECTL get -n $cluster_name -o=jsonpath='{.status.containerStatuses[?(@.name=="amvdb")].ready}' pod queen-0`

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
