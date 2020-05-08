#!/bin/bash

# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET

# Create required k8s secrets for ICE, ARC security and https webservices

credDir="./credentials"
configFile="$credDir/aster-security-config.json"
iceKey="$credDir/mutual-auth-key-base64.txt"
arcserverCert="$credDir/server.crt"
arcServerKey="$credDir/server.key"
arcRootCert="$credDir/root.crt"
arcClientCert="$credDir/postgresql.crt"
arcClientKey="$credDir/postgresql.key"
namespace=$1
kk_ns="kube-system"

$KUBECTL create secret generic iceserver --from-file=$iceKey --namespace=$namespace

$KUBECTL create secret generic arcserver --from-file=$arcserverCert --from-file=$arcServerKey --from-file=$arcRootCert --namespace=$namespace

$KUBECTL create secret generic arcclient --from-file=$arcClientCert --from-file=$arcClientKey --from-file=$arcRootCert --namespace=$namespace

$KUBECTL create secret generic configjson --from-file=$configFile --namespace=$namespace

kubectl get secret nginx-ingress-controller-tls-v1 -n $kk_ns -o json | sed -e "s/$kk_ns/$namespace/g" | sed -e "s/nginx-ingress-controller-tls-v1/webservices/g" | kubectl create -f  -

# Removing the credential files after creating secrets
rm -rf $credDir
