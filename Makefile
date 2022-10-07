#variables
.EXPORT_ALL_VARIABLES:
IMAGE_VER=3.2
IMAGE_BASE=os-base
IMAGE_NAME=devops-cli

all: image-base image-main scan

clean:
	mkdir -p tmp
	mkdir -p ~/.kube
	curl --noproxy '*' -vv -sLO https://github.com/dimetron.keys
	docker rm -f $(IMAGE_NAME)
	docker buildx ls | grep           multi-buildx || :
	docker buildx create --use --name multi-buildx || :

image-base: clean
	docker buildx build --platform linux/arm64,linux/amd64 base -t dimetron/$(IMAGE_BASE):$(IMAGE_VER) --push

image-main: clean
	docker buildx build --platform linux/arm64,linux/amd64 .    -t dimetron/$(IMAGE_NAME):$(IMAGE_VER) --push

scan: image-main
	docker scan dimetron/$(IMAGE_NAME):$(IMAGE_VER)

test: image-main
	docker pull dimetron/$IMAGE_NAME:$IMAGE_VER
	crane manifest dimetron/$IMAGE_NAME:$IMAGE_VER | jq
	docker run -d --net=host --cap-add=NET_ADMIN -v /var/run/docker.sock:/var/run/docker.sock -v `pwd`/tmp:/root/tmp --name $IMAGE_NAME dimetron/$IMAGE_NAME:$IMAGE_VER