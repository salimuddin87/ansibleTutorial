#!/bin/bash

# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET
#
# Delete the cloud-aster and cloud-platform namespaces, wait for 
# termination to complete before exiting
#
# Usage: deleteNamespaces.sh [ namespace ]
#        Optional parameter - specify namespace to delete
#        Timeout of 15 minutes

SLEEP=/bin/sleep

GRACE_TIMEOUT=900
FORCE_TIMEOUT=1200
TIMER=0

NAMESPACE=$1
PLATFORM_NAMESPACE=$1-platform
TEMPLATEDIR=$3

ASTERNAMESPACE=$TEMPLATEDIR/cloud-aster-ns.yaml
ASTERNAMESPACE_PLATFORM=$TEMPLATEDIR/cloud-platform-ns.yaml

function checkAndWait {
  cmd_output="initial"
  while [[ ! -z $cmd_output ]]; do
    cmd_output=`${KUBECTL} get ns ${1} --no-headers --ignore-not-found=true`
    let TIMER=$TIMER+1
    if [ "$TIMER" -eq "$GRACE_TIMEOUT" ]; then
      echo "$cmd_output"
      echo "$0: WARN: Script timed out while waiting for $1 to terminate.
            Terminating the pods forcefully.."
      ${KUBECTL} delete pods --all --grace-period=0 --force -n ${1}
      ${SLEEP} 2
      ${KUBECTL} delete -f ${2} --grace-period=0 --force --ignore-not-found=true
      ${SLEEP} 2
    fi
    if [ "$TIMER" -gt "$FORCE_TIMEOUT" ]; then
       # UKS-1180: Sometimes the force deletion of namespace return errors.
       echo "ERROR: Even the force deletion of pods/namespace did not work.
             Please contact the Kubernetes support team."
       exit 1
    fi
    ${SLEEP} 1
  done
}

if [[ "$2" = "platform" ]] || [ -z "$NAMESPACE" ]
then
  ${KUBECTL} delete -f ${ASTERNAMESPACE_PLATFORM}
  if [ "$?" -ne "0" ]; then
    echo "$0: ERROR: Problem occurred while deleting $PLATFORM_NAMESPACE namespace"
  else
    checkAndWait $PLATFORM_NAMESPACE $ASTERNAMESPACE_PLATFORM
  fi
fi

if [[ "$2" = "aster" ]] || [ -z "$NAMESPACE" ] 
then
  ${KUBECTL} delete -f ${ASTERNAMESPACE}
  if [ "$?" -ne "0" ]; then
    echo "$0: ERROR: Problem occurred while deleting $NAMESPACE namespace"
  else
    checkAndWait $NAMESPACE $ASTERNAMESPACE
  fi
fi
