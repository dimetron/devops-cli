#!/bin/bash
export IMAGE_NAME=devops-cli
export IMAGE_VER=2.33

curl -sLO https://github.com/dimetron.keys

docker rm -f $IMAGE_NAME
docker build . -t dimetron/$IMAGE_NAME:$IMAGE_VER

docker rm -f $IMAGE_NAME  || :
docker run -d --net=host -v /var/run/docker.sock:/var/run/docker.sock --name $IMAGE_NAME dimetron/$IMAGE_NAME:$IMAGE_VER

docker exec -t $IMAGE_NAME kind delete cluster --name dev-local 2>/dev/null || :
docker exec -t $IMAGE_NAME kind create cluster --name dev-local --wait 2m

#update container
docker exec -t $IMAGE_NAME zsh -c 'kind get kubeconfig   --name dev-local  > ~/.kube/config'

#update host
docker exec -t $IMAGE_NAME zsh -c 'kind get kubeconfig   --name dev-local' > ~/.kube/config

#start k9s
docker exec -it $IMAGE_NAME k9s

#test manual
docker exec -it $IMAGE_NAME zsh