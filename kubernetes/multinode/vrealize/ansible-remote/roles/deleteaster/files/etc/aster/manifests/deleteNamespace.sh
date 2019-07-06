#!/bin/bash

# Copyright (c) 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET
#
# Delete cloud-aster namespace, wait for 
# termination to complete before exiting
#
# Usage: deleteNamespace.sh namespace aster templatedir
#        Timeout of 15 minutes

KUBECTL="kubectl --kubeconfig=$KUBECONFIG_VAR"
SLEEP=/bin/sleep

TIMEOUT=900
TIMER=0

NAMESPACE=$1
TEMPLATEDIR=$3

ASTERNAMESPACE=$TEMPLATEDIR/cloud-aster-ns.yaml

function checkAndWait {
  cmd_output="initial"
  while [[ ! -z $cmd_output ]]; do
    cmd_output=`${KUBECTL} get ns ${1}`
    let TIMER=$TIMER+1
    if [ "$TIMER" -eq "$TIMEOUT" ]; then
      echo "$0: WARN: Script timed out while waiting for $1 to terminate.
            Terminating the pods forcefully.."
      ${KUBECTL} delete pods --all --grace-period=0 --force -n ${1} --cascade=true
      ${SLEEP} 2
      exit 0
    fi
    ${SLEEP} 1
  done
}

if [[ "$2" = "aster" ]] || [ -z "$NAMESPACE" ] 
then
  ${KUBECTL} delete -f ${ASTERNAMESPACE} --cascade=true
  if [ "$?" -ne "0" ]; then
    echo "$0: ERROR: Problem occurred while deleting $NAMESPACE namespace"
  else
    checkAndWait $NAMESPACE $ASTERNAMESPACE
  fi
fi
