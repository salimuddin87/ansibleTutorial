#!/bin/bash

# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET

manifestDir=$1
isLocalRegistry=$2

# update docker registry related parameters depending on whether
# working with local or remote (Artifactory) registry.

if [ "$isLocalRegistry" = True ] ; then
   dockerRegistryHost=$3
   dockerRegistryPort="5000"
   dockerRegistryTag="latest"
   wpCount=$4
else
   dockerRegistryHost=$3
   dockerRegistryPort=$4
   dockerRegistryPath=$5
   dockerRegistryTag=$6
   wpCount=$7
fi

for i in queen worker mle-fdr;
do
   if [ "$isLocalRegistry" = True ] ; then
      sed -ie s@localregistryhost:localregistryport@$dockerRegistryHost:$dockerRegistryPort@g \
      $manifestDir/$i-pod.yaml
   else
      sed -ie s@localregistryhost:localregistryport@$dockerRegistryHost:$dockerRegistryPort\/$dockerRegistryPath@g \
      $manifestDir/$i-pod.yaml
   fi
   sed -ie s/localregistrytag/$dockerRegistryTag/g $manifestDir/$i-pod.yaml
done;

