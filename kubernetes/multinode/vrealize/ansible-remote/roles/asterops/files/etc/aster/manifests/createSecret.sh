#!/bin/bash

# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET

#create required k8s secret so that k8s can pull images from artifactory

docker_server=$1:$2
docker_username=$3
docker_password=$4
docker_email=$5
namespace=$6

$KUBECTL create secret docker-registry regsecret --docker-server=$docker_server --docker-username=$docker_username --docker-password=$docker_password --docker-email=$docker_email --namespace=$namespace
