#!/bin/bash

# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET
#
# Delete the objects within cloud-aster (except persistent volume claims) 
# and wait for termination to complete before exiting
#
# Usage: deleteNamespaces.sh [ namespace ] [ path to file of list of namespace objects]
#        Optional parameter - specify namespace to delete
#        Timeout of 15 minutes

SLEEP=/bin/sleep

NAMESPACE=$1
FILESDIR=$2

FILE=$FILESDIR/listOfNamespaceObjects.txt

function checkAndWait {
   ${SLEEP} 60
   variable=$(cat $FILE)
   while IFS= read -r line
   do
      echo ${KUBECTL} get $line -n $NAMESPACE
      ${KUBECTL} get $line -n $NAMESPACE
      while [ "$?" -eq "0" ]
      do
         echo "Namespace object $line has not been deleted"
         ${SLEEP} 60
         ${KUBECTL} get $line -n $NAMESPACE
      done
   done <<< "$variable"
}

variable=$(cat $FILE)
while IFS= read -r line
do
   echo ${KUBECTL} delete $line -n $NAMESPACE
   ${KUBECTL} delete $line -n $NAMESPACE
done <<< "$variable"
checkAndWait
