#!/bin/bash

export IMAGE_NAME=devops-cli
export IMAGE_VER=2.39-rc

set -x
set -e

curl -sLO https://github.com/dimetron.keys

docker rm -f $IMAGE_NAME
docker build --progress plain . -t dimetron/$IMAGE_NAME:$IMAGE_VER

mkdir  -p tmp
docker rm -f $IMAGE_NAME  || :
docker run -d --net=host --cap-add=NET_ADMIN -v /var/run/docker.sock:/var/run/docker.sock -v `pwd`/tmp:/root/tmp --name $IMAGE_NAME dimetron/$IMAGE_NAME:$IMAGE_VER

docker exec -it $IMAGE_NAME docker ps     | grep dimetron
docker exec -it $IMAGE_NAME docker images | grep dimetron

docker exec  -t $IMAGE_NAME kind delete cluster --name dev-local 2>/dev/null || :
docker exec  -t $IMAGE_NAME kind create cluster --name dev-local --wait 2m

#update container & host
docker exec -t $IMAGE_NAME zsh -c 'kind get kubeconfig   --name dev-local  > ~/.kube/config'
docker exec -t $IMAGE_NAME zsh -c 'kind get kubeconfig   --name dev-local' > ~/.kube/config
docker exec -it $IMAGE_NAME k9s
docker exec -it $IMAGE_NAME zsh

#test skopeo
docker exec -it $IMAGE_NAME skopeo --tmpdir=/root/tmp inspect docker-daemon:dimetron/$IMAGE_NAME:$IMAGE_VER
docker scan dimetron/$IMAGE_NAME:$IMAGE_VER
