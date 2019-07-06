#!/bin/bash

# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET

# Use to delete docker images on master and node systems
#
# Usage:   dockerRMI.sh <image name> <deletion type> [tag prefix]
#            deletion type - untagged, master, node, node_remote, or node_remote_all
#            tag prefix - is optional as it is used only for node systems
# Example: dockerRMI.sh arc node sdl07074:5001

DOCKER=/usr/bin/docker
GREP=/bin/grep
AWK=/usr/bin/awk
imageName=$1
deleteType=$2
tagPrefix=$3

if [[ -z $deleteType ]]; then
  echo "$0: ERROR: Missing type parameter"
  exit 1
fi

function checkAndDeleteWildcard {
  imageNameParm=$1
  imageNameWildcard=$2

  ${DOCKER} images |
  ${GREP} $imageNameParm |
  ${AWK} '{ if ($1 ~ /"'$imageNameWildcard'"/) {
              command="'${DOCKER}' rmi -f "$3
              command | getline resultVar
              close(command)
              print resultVar
            }
          }'
}

function checkAndDelete {
  imageNameParm=$1
  ${DOCKER} images |
  ${GREP} $imageNameParm |
  ${AWK} '{ if ($1=="'$imageNameParm'") {
              command="'${DOCKER}' rmi -f "$3
              command | getline resultVar
              close(command)
              print resultVar
            }
          }'
}

function rmiUntagged {
  imageIDs=`${DOCKER} images --filter "dangling=true" -q`
  if [[ -z $imageIDs ]]; then
    echo "${0}: No untagged images found, exiting"
  else
    ${DOCKER} rmi -f $imageIDs
  fi
}

if [[ "$deleteType" == "untagged" ]]; then
  rmiUntagged
  exit 0

elif [[ "$deleteType" == "master" ]]; then
  checkAndDelete $imageName
  exit 0

elif [[ "$deleteType" == "node" ]]; then

  if [[ -z $tagPrefix ]]; then
    echo "$0: ERROR: Missing tag prefix parameter"
    exit 1
  fi

  tagPrefix=`echo $tagPrefix | tr "." "\n" | head -1`

  checkAndDelete $tagPrefix:5001/$imageName
  exit 0
elif [[ "$deleteType" == "node_remote" ]]; then
  repoPath=$3
  repoHost=$4
  repoPort=$5
  
  checkAndDelete $repoHost:$repoPort/$repoPath/$imageName
elif [[ "$deleteType" == "node_remote_all" ]]; then
  repoHost=$3

  checkAndDeleteWildcard $repoHost:.*/.*/$imageName $repoHost:*/*/$imageName
else
  echo "$0: ERROR: Type parameter does not match existing deletion type"
  exit 1
fi
