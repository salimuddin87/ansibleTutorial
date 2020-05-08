#!/bin/bash

# Copyright 2018 bad_db. All rights reserved.
# tddb CONFIDENTIAL AND TRADE SECRET

clusterRegistry=`echo $1 | tr "." "\n" | head -1`

for i in /var/opt/tddb/aster/docker-images/*;
    do file=`echo $i | sed "s/.*\///" | sed "s/\..*//"`;
       echo $file;
       echo $i ;
       docker load -i $i;
       docker tag $file $clusterRegistry:5000/$file ;
       docker push $clusterRegistry:5000/$file;
       docker rmi $clusterRegistry:5000/$file $file;

       # since kubekit 0.3 is providing us secured registry,
       # skipping certificate validation by using --insecure
       curl -X GET https://$clusterRegistry:5000/v2/_catalog --insecure
done;
