#!/bin/bash

# Copyright (c) 2017 by bad_db Corporation. All rights reserved.
# tddb CORPORATION CONFIDENTIAL AND TRADE SECRET

# get consulIp
while true ;
   do consulIp=`kubectl get -o template svc consul-service \
      --namespace=cloud-aster --template={{.spec.clusterIP}}`;
      # no need to check for valid quads here as k8s will assign valid IP
      # need this check to avoid any other errors
      echo $consulIp
      if [ $consulIp != ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ] ; then
         break;
      else
         echo “fail”;
      fi;
done;

# check if working with local or remote registry
isLocalRegistry=`grep "USE_LOCAL_REGISTRY" /vagrant/templates/vars.yml | awk '{ print $2}'`;
if [ -z "$isLocalRegistry" ]; then
   echo "Required $isLocalRegistry not found in vars.yml file. \
   Please check installation guide.";
fi

if [ "$isLocalRegistry" = true ] ; then
   dockerRegistryHost="localhost"
   dockerRegistryPort="5001"
   dockerRegistryTag="latest"
   sh /vagrant/aster/addDockerImagesIntoRegistry.sh
else
   dockerRegistryPath=`grep "DOCKER_REPO_PATH" /vagrant/templates/vars.yml | awk '{ print $2}'`;
   if [ -z "$dockerRegistryPath" ]; then
      echo "Required $dockerRegistryPath not found in vars.yml file. \
      Please check installation guide.";
   fi

   dockerRegistryTag=`grep "DOCKER_REPO_TAG" /vagrant/templates/vars.yml | awk '{ print $2}'`;
   if [ -z "$dockerRegistryTag" ]; then
      echo "Required $dockerRegistryTag not found in vars.yml file. \
      Please check installation guide.";
   fi

   dockerRegistryHost=`grep "DOCKER_REPO_HOST" /vagrant/templates/vars.yml | awk '{ print $2}'`;
   if [ -z "$dockerRegistryHost" ]; then
      echo "Required $dockerRegistryHost not found in vars.yml file. \
      Please check installation guide.";
   fi

   dockerRegistryPort=`grep "DOCKER_REPO_PORT" /vagrant/templates/vars.yml | awk '{ print $2}'`;
   if [ -z "$dockerRegistryPort" ]; then
      echo "Required $dockerRegistryPort not found in vars.yml file. \
      Please check installation guide.";
   fi

   # create k8s secret when dealing with remote registry
   dockerUsername=`grep "DOCKER_REPO_USERNAME" /vagrant/templates/vars.yml | awk '{ print $2}'`;
   if [ -z "$dockerUsername" ]; then
      echo "Required $dockerUsername not found in vars.yml file. \
      Please check installation guide.";
   fi

   dockerPassword=`grep "DOCKER_REPO_PASSWORD" /vagrant/templates/vars.yml | awk '{ print $2}'`;
   if [ -z "$dockerPassword" ]; then
      echo "Required $dockerPassword not found in vars.yml file. \
      Please check installation guide.";
   fi

   dockerEmail=`grep "DOCKER_EMAIL" /vagrant/templates/vars.yml | awk '{ print $2}'`;
   if [ -z "$dockerEmail" ]; then
      echo "Required $dockerEmail not found in vars.yml file. \
      Please check installation guide.";
   fi

   # create required secret
   kubectl delete secret regsecret --namespace=cloud-aster
   kubectl create secret docker-registry regsecret \
     --docker-server=$dockerRegistryHost:$dockerRegistryPort \
     --docker-username=$dockerUsername \
     --docker-password=$dockerPassword \
     --docker-email=$dockerEmail \
     --namespace=cloud-aster

fi

# update consul and Resistry info in pods
for i in queen worker worker2;
do
   sed -ie s/localconsulip/$consulIp/g /vagrant/aster/$i-pod.yaml
   if [ "$isLocalRegistry" = true ] ; then
      sed -ie s@localregistryhost:localregistryport@$dockerRegistryHost:$dockerRegistryPort@g \
      /vagrant/aster/$i-pod.yaml
   else
      sed -ie s@localregistryhost:localregistryport@$dockerRegistryHost:$dockerRegistryPort\/$dockerRegistryPath@g \
      /vagrant/aster/$i-pod.yaml
   fi
   sed -ie s/localregistrytag/$dockerRegistryTag/g /vagrant/aster/$i-pod.yaml
done;
