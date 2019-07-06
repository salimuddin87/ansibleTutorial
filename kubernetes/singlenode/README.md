# Local Environment

This repository consists of docker compose scripts to setup a local AppCenter Environment.
The environment is mainly used for developing and testing AppCenter.

The technologies used:

* docker-compose 1.6 or higher
* docker 1.10 or higher
* SQL postgres dialect

## Setting up

To get started to setup, the environment requires to use vagrant

```
$ vagrant up
$ vagrant ssh
```

To connect to vagrant box under VPN 
 
```
$ ssh vagrant@127.0.0.1 -p 2224 -i ~/.vagrant.d/insecure_private_key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PasswordAuthentication=no -o IdentitiesOnly=yes
```
 
## How the build works

The build pulls the required docker containers from registry and starts them in docker-machine (or local)

## BUILD/RUN

### Start all applications

#### Vagrant

```
$ source local.env
$ start.sh

$ export PGPASSWORD=postgres && psql --host=${DOCKER_HOST_IP} --port=5432 --username=postgres --dbname=metadata    
$ select * from "user";
$ \q
        
$ curl -L http://${DOCKER_HOST_IP}:5001/v2/_catalog        

$ curl -L http://${DOCKER_HOST_IP}:8500/v1/health/service/consul        

$ curl -L http://${DOCKER_HOST_IP}:1080

$ curl http://${DOCKER_HOST_IP}:9200/_cluster/health?pretty=true
$ curl http://${DOCKER_HOST_IP}:9200/_cat/indices?v        

$ curl -L http://${DOCKER_HOST_IP}:5601/status
        
$ docker build -t ${DOCKER_HOST_IP}:5001/sql-runner-java sql-runner/java/.
$ docker build -t ${DOCKER_HOST_IP}:5001/bteq-runner-bash bteq/.
$ docker push ${DOCKER_HOST_IP}:5001/sql-runner-java
$ docker push ${DOCKER_HOST_IP}:5001/bteq-runner-bash
```

### Stop all applications

#### Vagrant

Stop all containers

```
$ stop.sh 
```

Stop and delete all existing containers

```
$ stop.sh -rm -rd 
```

## To Stop and Delete all existing containers
```
$ docker stop $(docker ps -a -q)
$ docker rm --force $(docker ps -a -q)
```

## URL's

* `http://${DOCKER_HOST_IP}:8003`                 - AppCenter
* `http://${DOCKER_HOST_IP}:8000/swagger-ui.html` - App Service
* `http://${DOCKER_HOST_IP}:8001/swagger-ui.html` - User Service
* `http://${DOCKER_HOST_IP}:8002/swagger-ui.html` - Logging Service
* `http://${DOCKER_HOST_IP}:8004/swagger-ui.html` - System Service
* `http://${DOCKER_HOST_IP}:9090`                 - Kubernetes
* `http://${DOCKER_HOST_IP}:5601`                 - Kibana
* `http://${DOCKER_HOST_IP}:8500/ui`              - Consul
* `http://${DOCKER_HOST_IP}:4194`                 - cAdvisor
* `http://${DOCKER_HOST_IP}:1080`                 - bad_db REST

## Troubleshooting

### Docker
```
$ docker ps
$ docker ps -a 
```

```
$ docker ps | grep kibana
$ docker logs f79c1f09342e
```

```
$ docker ps | grep kibana
$ docker exec -it f79c1f09342e /bin/bash
```

### Kubernetes
```
$ kubectl get pods --all-namespaces
$ kubectl get events --all-namespaces
```

```
$ kubectl logs elk --namespace=cloud-platform -c kibana
```

```
$ kubectl exec elk -it --namespace=cloud-platform -c kibana -- /bin/bash
```

## Tests

### Kubernetes
```
$ kubectl version

$ kubectl create -f kubernetes/examples/nginx-pod.yaml
$ kubectl get pods
$ curl http://$(kubectl get pod nginx -o=template --template={{.status.podIP}})

$ kubectl create -f kubernetes/examples/nginx-svc.yaml                
$ kubectl get svc
$ export SERVICE_IP=$(kubectl get svc nginx-service -o=template --template={{.spec.clusterIP}})
$ export SERVICE_PORT=$(kubectl get svc nginx-service -o=template '--template={{(index .spec.ports 0).port}}')
$ curl http://${SERVICE_IP}:${SERVICE_PORT}

$ kubectl delete svc nginx-service
$ kubectl delete svc nginx
                                
$ kubectl create -f kubernetes/examples/pi-job.yaml                                
$ kubectl get jobs
$ kubectl get pods -a                                

$ kubectl describe jobs/pi

$ kubectl delete -f kubernetes/examples/pi-job.yaml                                
```
