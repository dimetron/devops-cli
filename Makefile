#variables
.EXPORT_ALL_VARIABLES:
IMAGE_VER=4.4.0
IMAGE_BASE=os-base
IMAGE_NAME=devops-cli
GO_VERSION=1.23.2

DOCKER_HOST=ssh://dimetron@k3s.raccoon-universe.ts.net

clean:
	mkdir -p tmp
	mkdir -p ~/.kube
	curl --noproxy '*' -vv -sLO https://github.com/dimetron.keys
	docker rm -f $(IMAGE_NAME)
	docker buildx ls | grep           multi-buildx || :
	docker buildx create --use --name multi-buildx || :
	docker run --privileged --rm tonistiigi/binfmt --install all

image-base: clean
	docker buildx build --builder multi-buildx --build-arg GO_VERSION=$(GO_VERSION) --build-arg  IMAGE_VER=$(IMAGE_VER) --platform linux/arm64,linux/amd64 base -t dimetron/$(IMAGE_BASE):$(IMAGE_VER) --push

image-main: clean
	docker buildx build --builder multi-buildx --build-arg GO_VERSION=$(GO_VERSION) --build-arg  IMAGE_VER=$(IMAGE_VER)  --platform linux/arm64,linux/amd64 .    -t dimetron/$(IMAGE_NAME):$(IMAGE_VER) --push

image-local: clean
	docker buildx build --builder multi-buildx --build-arg GO_VERSION=$(GO_VERSION) --build-arg  IMAGE_VER=$(IMAGE_VER)                                 base     -t dimetron/$(IMAGE_BASE):$(IMAGE_VER) --load
	docker buildx build --builder multi-buildx --build-arg GO_VERSION=$(GO_VERSION) --build-arg  IMAGE_VER=$(IMAGE_VER)                                    .     -t dimetron/$(IMAGE_NAME):$(IMAGE_VER) --load

image-scan:
	docker pull dimetron/$(IMAGE_NAME):$(IMAGE_VER)
	docker scout cves dimetron/$(IMAGE_NAME):$(IMAGE_VER)
	grype dimetron/$(IMAGE_NAME):$(IMAGE_VER)

test: image-main
	docker pull dimetron/$IMAGE_NAME:$IMAGE_VER
	crane manifest dimetron/$IMAGE_NAME:$IMAGE_VER | jq
	docker run -d --net=host --cap-add=NET_ADMIN -v /var/run/docker.sock:/var/run/docker.sock -v `pwd`/tmp:/root/tmp --name $IMAGE_NAME dimetron/$IMAGE_NAME:$IMAGE_VER

builds: image-base
builds: image-main

all: image-local image-scan

