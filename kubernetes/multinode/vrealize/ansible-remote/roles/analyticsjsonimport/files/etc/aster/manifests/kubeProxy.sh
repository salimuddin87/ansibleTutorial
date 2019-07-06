#!/bin/bash

# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET

# Starts and Stops Kubernetes Proxy

OPTION=$1

function stopAndWait {
  PID=$1
  if [ ! -z $PID ]; then
    kill $PID
    while ps $PID>/dev/null; do sleep 0.5; done
  fi
}

if [ "$OPTION" == "start" ]; then
  REMOTE_KUBECONFIG=$2
  if [ ! -f $REMOTE_KUBECONFIG ]; then
    echo "$REMOTE_KUBECONFIG does not exist, exiting"
    exit 1
  fi

  # check for an existing proxy 
  EXISTINGPROXY=$(ps -ef | grep proxy | grep kubectl | egrep -v grep | tr ' ' '\n' | grep kubeconfig | cut -d= -f2)
  if [ ! -z $EXISTINGPROXY ]; then
    echo "KUBECONFIG=${EXISTINGPROXY}"
    exit 0
  fi

  # start new proxy
  kubectl --kubeconfig=$REMOTE_KUBECONFIG --port=8080 proxy >/dev/null &
  disown
  echo $!
  

elif [ "$OPTION" == "stop" ]; then
  KUBE_PID=$2
  stopAndWait $KUBE_PID

else
  echo "ERROR: Incorrect argument"
  exit 1
fi
