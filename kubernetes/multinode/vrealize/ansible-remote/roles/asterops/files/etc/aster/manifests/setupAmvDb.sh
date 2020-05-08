#!/bin/bash

# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET

useAmv=$1
amvBaseDir="./amv"
namespace=$2

if [[ ! -d $amvBaseDir ]]; then
    mkdir -p $amvBaseDir
fi
amvdbKey="$amvBaseDir/amvDb.txt"
echo "useAmvDb=$useAmv" > $amvdbKey

# use secret here because projected volume does not support configMap
$KUBECTL delete secret useamvdb -n $namespace
$KUBECTL create secret generic useamvdb --from-file=$amvdbKey --namespace=$namespace
