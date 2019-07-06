#!/bin/bash

# Copyright (c) 2017 by bad_db Corporation. All rights reserved.
# tddb CORPORATION CONFIDENTIAL AND TRADE SECRET

cp templates/cloud-aster-ns.yaml.j2 aster/cloud-aster-ns.yaml
cp templates/cloud-platform-ns.yaml.j2 aster/cloud-platform-ns.yaml

cp templates/registry-pod.yaml.j2 aster/registry-pod.yaml
cp templates/consul-pod.yaml.j2 aster/consul-pod.yaml

cp templates/consul-svc.yaml.j2 aster/consul-svc.yaml
cp templates/queenexec-svc.yaml.j2 aster/queenexec-svc.yaml

cp templates/queen-pod.yaml.j2 aster/queen-pod.yaml
cp templates/worker-pod.yaml.j2 aster/worker-pod.yaml
cp templates/worker2-pod.yaml.j2 aster/worker2-pod.yaml

cp templates/updateConsulRegistryIPs.sh aster/updateConsulRegistryIPs.sh
cp templates/addDockerImagesIntoRegistry.sh aster/addDockerImagesIntoRegistry.sh
cp templates/startAster.sh aster/startAster.sh
cp templates/stopAster.sh aster/stopAster.sh
