# Kubernetes Environment

This repository consists of ansible scripts to setup a kubernetes cluster at Vmware/vRealize.


The technologies used:

* ansible 2.1 or higher
* kubectl 1.4 or higher

OS X Setup
```
brew update
brew tap Homebrew/bundle

brew install base64
brew install curl
brew install ansible
brew install kubernetes-cli
```

## Setting up

To get started to setup, the environment requires at least two Ubuntu 14.04 vms from https://cloud.labs.tddb.com/vcac/org/vsphere.local

Create ansible inventory file with vms details

```
$ cp ./inventory/inventory.example ./inventory/inventory.local
$ vim ./inventory/inventory.local
```

Validate that inventory file is correct and all vms are reachable

```
$ ansible --inventory-file=./inventory/inventory.local -u root --ask-pass all -m ping -vvvv
```

Provision cluster

```
$ ansible-playbook --inventory-file=./inventory/inventory.local -u root --ask-pass kube-cluster.yml -vvvv
```

## Connect to the cluster

### Kubectl

Use pre generated `kubeconfig.yaml`

```
$ kubectl cluster-info --kubeconfig="./rendered/kubeconfig.yaml"
```

Add to you local configuration

```
$ kubectl config set-cluster <kube-master>-cluster --server=https://<kube-master>:443 --certificate-authority=${PWD}/rendered/certs/ca.pem
$ kubectl config set-credentials <kube-master>-admin --certificate-authority=${PWD}/rendered/certs/ca.pem --client-key=${PWD}/rendered/certs/client-key.pem --client-certificate=${PWD}/rendered/certs/client.pem
$ kubectl config set-context <kube-master>-cluster --cluster=<kube-master>-cluster --user=<kube-master>-admin
$ kubectl config use-context <kube-master>-cluster
$ kubectl cluster-info
```

### Browser
* http://&lt;kube-master&gt;:32080/kubernetes-dashboard/
* http://&lt;kube-master&gt;:32080/kibana/
* http://&lt;kube-master&gt;:32080/prometheus/
* http://&lt;kube-master&gt;:32080/grafana/
