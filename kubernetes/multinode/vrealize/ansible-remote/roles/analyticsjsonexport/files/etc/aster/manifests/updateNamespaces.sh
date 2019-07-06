#!/bin/bash

# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET

# Update namespaces in all the cluster manifest files with a specified value (@arg1)

clusterName=$1
manifestDir=$2
echo -e "Cluster name is: $clusterName"

for file in `ls $manifestDir/*.preNamespace`;
do
   processed=$(echo $file | sed 's/\.preNamespace$//')
   sed s/AsterNamespace/$clusterName/g $file > $processed
done

echo "`basename $0` completed!"
