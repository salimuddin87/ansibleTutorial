#!/usr/bin/env bash

wait_for() {
    until /usr/bin/curl -sf "$1";do
      echo "Waiting for $1"
      sleep 5
    done
}

. /vagrant/local.env
if [ \( ! -d "/vagrant" \) -a \( ! -L "/vagrant" \) ]; then
  ln -s ${PWD} /vagrant
fi

basedir=$(dirname "$0")

sudo mkdir -p /var/log/containers

export ARCH=amd64
export K8S_VERSION=v1.3.4
docker run -d \
    --volume=/:/rootfs:ro \
    --volume=/sys:/sys:ro \
    --volume=/var/lib/docker/:/var/lib/docker:rw \
    --volume=/var/lib/kubelet/:/var/lib/kubelet:rw \
    --volume=/var/run:/var/run:rw \
    --volume=/var/log/containers/:/var/log/containers:rw \
    --volume=/vagrant/kubernetes/manifests:/etc/kubernetes/manifests:ro \
    --net=host \
    --pid=host \
    --privileged \
    quay.ac.uda.io/google_containers/hyperkube-${ARCH}:${K8S_VERSION} \
    /hyperkube kubelet \
        --containerized \
        --hostname-override=${DOCKER_HOST_IP} \
        --api-servers=http://localhost:8080 \
        --config=/etc/kubernetes/manifests \
        --cluster-dns=10.0.0.10 \
        --cluster-domain=cluster.local \
        --allow-privileged=true --v=2

wait_for "http://127.0.0.1:8080/healthz"

# namespace
kubectl create -f ${basedir}/kubernetes/addons/kube-system-ns.yaml
wait_for "http://127.0.0.1:8080/api/v1/namespaces/kube-system/serviceaccounts/default"

kubectl create -f ${basedir}/platform/cloud-platform-ns.yaml
wait_for "http://127.0.0.1:8080/api/v1/namespaces/cloud-platform/serviceaccounts/default"

kubectl create -f ${basedir}/kubernetes/addons/elasticsearch-logging-rc.yaml

kubectl create -f ${basedir}/kubernetes/addons/elasticsearch-logging-svc.yaml

kubectl create -f ${basedir}/kubernetes/addons/kibana-logging-rc.yaml

# cockpit ui
kubectl create -f ${basedir}/kubernetes/addons/cockpit-ui.yaml

# elk
${basedir}/wait-for-it.sh ${DOCKER_HOST_IP}:9200 --timeout=0
ELK_URL=http://${DOCKER_HOST_IP}:9200/ ${basedir}/elk-bootstrap/add-template.sh ${basedir}/elk-bootstrap/service-template.json

# registry
kubectl create -f ${basedir}/platform/registry-pod.yaml

# copy Files
sh ${basedir}/templates/copyFiles.sh

# create aster namespace
kubectl create -f ${basedir}/aster/cloud-aster-ns.yaml

# create consul pod and required services
kubectl create -f ${basedir}/aster/consul-pod.yaml
kubectl create -f ${basedir}/aster/consul-svc.yaml
kubectl create -f ${basedir}/aster/queenexec-svc.yaml

# update consul and Registry info in pod definitions
sh ${basedir}/aster/updateConsulRegistryIPs.sh

# start aster
bash ${basedir}/aster/startAster.sh
