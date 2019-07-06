# Copyright (c) 2016 by bad_db Corporation. All rights reserved.
# tddb CORPORATION CONFIDENTIAL AND TRADE SECRET

#!/usr/bin/env bash

docker load -i /aster/registry.tar
docker load -i /aster/pause.tar
docker load -i /aster/logstash.tar
docker load -i /aster/kubernetes.tar
docker load -i /aster/kibana.tar
docker load -i /aster/hyperkube.tar
docker load -i /aster/fluentd-elasticsearch.tar
docker load -i /aster/filebeat.tar
docker load -i /aster/etcd.tar
docker load -i /aster/elasticsearch.tar
docker load -i /aster/consul.tar

docker load -i /aster/statsserver.tar
docker load -i /aster/astershell.tar
docker load -i /aster/arc.tar
docker load -i /aster/ice.tar
docker load -i /aster/procmgmt.tar
docker load -i /aster/qosmanager.tar
docker load -i /aster/sysman.tar
docker load -i /aster/mailman.tar
docker load -i /aster/queenexec.tar
docker load -i /aster/runner.tar
docker load -i /aster/txman.tar
docker load -i /aster/txmanslave.tar

docker tag statsserver localhost:5001/statsserver
docker tag arc localhost:5001/arc
docker tag astershell localhost:5001/astershell
docker tag ice localhost:5001/ice
docker tag procmgmt localhost:5001/procmgmt
docker tag qosmanager localhost:5001/qosmanager
docker tag sysman localhost:5001/sysman
docker tag mailman localhost:5001/mailman
docker tag queenexec localhost:5001/queenexec
docker tag runner localhost:5001/runner
docker tag txman localhost:5001/txman
docker tag txmanslave localhost:5001/txmanslave

docker push localhost:5001/statsserver
docker push localhost:5001/arc
docker push localhost:5001/astershell
docker push localhost:5001/ice
docker push localhost:5001/procmgmt
docker push localhost:5001/qosmanager
docker push localhost:5001/sysman
docker push localhost:5001/mailman
docker push localhost:5001/queenexec
docker push localhost:5001/runner
docker push localhost:5001/txman
docker push localhost:5001/txmanslave

curl -X GET http://localhost:5001/v2/_catalog

