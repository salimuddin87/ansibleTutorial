#!/bin/bash

# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET
#
# Deletes docker image tar files
#
# Usage: deleteDockerTarImages.sh <filename> [image directory]
#        'image directory' parameter is optional, will use default 
#        directory if not specified: /data/aster/docker-images/

RM=/bin/rm
directory=$2
filename=$1

if [ -z $directory ]; then
  dockerimages="/data/aster/docker-images/"
  echo "${0}: Using default docker image directory: "
  echo "${0}: $dockerimages"
else
  dockerimages=$directory
fi

fullfilename=$dockerimages/$filename

${RM} -f $fullfilename

if [ "$?" -eq "0" ]; then
  echo "$0: Deleted $fullfilename"
else
  echo "$0: ERROR: Not able to delete $fullfilename"
fi
