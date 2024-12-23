#!/bin/bash

export IMAGE_BASE=os-base
export IMAGE_NAME=devops-cli
export IMAGE_VER=4.0

export HTTP_PROXY=
export HTTPS_PROXY=

set -x
set -e

curl --noproxy '*' -vv -sLO https://github.com/dimetron.keys

docker rm -f $IMAGE_NAME
docker buildx ls | grep           multi-buildx || :
docker buildx create --use --name multi-buildx || :

#BASE
if [ "$1" == "base" ]; then
  docker buildx build --platform linux/arm64,linux/amd64 base -t dimetron/$IMAGE_BASE:$IMAGE_VER --push
fi

#CLI IMAGE
docker buildx build --platform linux/arm64,linux/amd64 .    -t dimetron/$IMAGE_NAME:$IMAGE_VER --push

#testing

docker pull dimetron/$IMAGE_NAME:$IMAGE_VER
crane manifest dimetron/$IMAGE_NAME:$IMAGE_VER | jq

mkdir  -p tmp
mkdir  -p ~/.kube

docker rm -f $IMAGE_NAME  || :
docker run -d --net=host --cap-add=NET_ADMIN -v /var/run/docker.sock:/var/run/docker.sock -v `pwd`/tmp:/root/tmp --name $IMAGE_NAME dimetron/$IMAGE_NAME:$IMAGE_VER

docker exec -it $IMAGE_NAME docker ps     | grep dimetron
docker exec -it $IMAGE_NAME docker images | grep dimetron

#docker exec  -t $IMAGE_NAME curl -LO https://raw.githubusercontent.com/cilium/cilium/1.11.0/Documentation/gettingstarted/kind-config.yaml
#docker exec  -t $IMAGE_NAME kind delete cluster --name dev-local 2>/dev/null || :
#docker exec  -t $IMAGE_NAME kind create cluster --name dev-local --config=kind-config.yaml --wait 2m
docker exec  -t $IMAGE_NAME kind create cluster --name dev-local

#update container & host
docker exec -t $IMAGE_NAME zsh -c 'kind get kubeconfig   --name dev-local  > ~/.kube/config'
docker exec -t $IMAGE_NAME zsh -c 'kind get kubeconfig   --name dev-local' > ~/.kube/config

#docker exec -t $IMAGE_NAME cilium install
#docker exec -t $IMAGE_NAME cilium status

docker exec -it $IMAGE_NAME k9s
docker exec -it $IMAGE_NAME zsh

#test security
docker scan dimetron/$IMAGE_NAME:$IMAGE_VER
