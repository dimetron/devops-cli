#variables
.EXPORT_ALL_VARIABLES:
IMAGE_VER=4.4.3
IMAGE_BASE=os-base
IMAGE_NAME=devops-cli
GO_VERSION=1.24.2

DOCKER_HOST=
BUILDER=cloud-dimetron-docker-cloud

setup:
	docker run --privileged --rm tonistiigi/binfmt --install all
	docker buildx create --driver cloud dimetron/docker-cloud

clean:
	mkdir -p tmp
	mkdir -p ~/.kube
	curl --noproxy '*' -vv -sLO https://github.com/dimetron.keys
	docker rm -f $(IMAGE_NAME)

image-base: clean
	docker buildx build --builder $(BUILDER) --build-arg GO_VERSION=$(GO_VERSION) --build-arg  IMAGE_VER=$(IMAGE_VER) --platform linux/arm64,linux/amd64 base -t dimetron/$(IMAGE_BASE):$(IMAGE_VER) --push

image-main: clean
	docker buildx build --builder $(BUILDER) --build-arg GO_VERSION=$(GO_VERSION) --build-arg  IMAGE_VER=$(IMAGE_VER)  --platform linux/arm64,linux/amd64 .    -t dimetron/$(IMAGE_NAME):$(IMAGE_VER) --push

image-local: clean
	docker buildx build --builder $(BUILDER) --build-arg GO_VERSION=$(GO_VERSION) --build-arg  IMAGE_VER=$(IMAGE_VER)                                 base     -t dimetron/$(IMAGE_BASE):$(IMAGE_VER) --load
	docker buildx build --builder $(BUILDER) --build-arg GO_VERSION=$(GO_VERSION) --build-arg  IMAGE_VER=$(IMAGE_VER)                                    .     -t dimetron/$(IMAGE_NAME):$(IMAGE_VER) --load

image-scan:
	docker pull dimetron/$(IMAGE_NAME):$(IMAGE_VER)
	docker scout cves dimetron/$(IMAGE_NAME):$(IMAGE_VER)
	grype docker:dimetron/$(IMAGE_NAME):$(IMAGE_VER)  -o template -t reports/report.tmpl.html --file reports/$(IMAGE_VER)/cni-cve.html

test: image-main
	docker pull dimetron/$(IMAGE_NAME):$(IMAGE_VER)
	crane manifest dimetron/$(IMAGE_NAME):$(IMAGE_VER) | jq
	docker run -d --net=host --cap-add=NET_ADMIN -v /var/run/docker.sock:/var/run/docker.sock -v `pwd`/tmp:/root/tmp --name $(IMAGE_NAME) dimetron/$(IMAGE_NAME):$(IMAGE_VER)

builds: image-base
builds: image-main
builds: image-scan

.PHONY: clean image-base image-main image-local image-scan test builds