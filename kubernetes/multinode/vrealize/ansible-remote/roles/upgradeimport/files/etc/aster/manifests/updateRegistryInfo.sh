#!/bin/bash

# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET

manifestDir=$1
isLocalRegistry=$2

echo "mainfest path is $manifestDir"

# update docker registry related parameters depending on whether
# working with local or remote (Artifactory) registry.

if [ "$isLocalRegistry" = True ] ; then
   dockerRegistryHost=$3
   dockerRegistryPort="5000"
   dockerRegistryTag="latest"
else
   dockerRegistryHost=$3
   dockerRegistryPort=$4
   dockerRegistryPath=$5
   dockerRegistryTag=$6
fi

for i in $manifestDir*.yaml
do
echo "final path is $i"
   if [ "$isLocalRegistry" = True ] ; then
      sed -ie s@localregistryhost:localregistryport@$dockerRegistryHost:$dockerRegistryPort@g \
      $i
   else
      sed -ie s@localregistryhost:localregistryport@$dockerRegistryHost:$dockerRegistryPort\/$dockerRegistryPath@g \
      $i
   fi
   sed -ie s/localregistrytag/$dockerRegistryTag/g $i
done;

