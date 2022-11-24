IMAGE_REPO = "philipgatzka/docker-taskd"
TASKD_STABLE_COMMIT ?= $$(git ls-remote 'https://github.com/GothenburgBitFactory/taskserver.git' refs/heads/master | cut -b -7)
TASKD_DEV_COMMIT ?= $$(git ls-remote 'https://github.com/GothenburgBitFactory/taskserver.git' refs/heads/1.2.0 | cut -b -7)

.PHONY: build push

default: Dockerfile entrypoint.sh vars.template build

build:
	docker build --build-arg TASKD_COMMIT="$(TASKD_STABLE_COMMIT)" -t "$(IMAGE_REPO):latest" -t "$(IMAGE_REPO):$(TASKD_STABLE_COMMIT)" .
	docker build --build-arg TASKD_COMMIT="$(TASKD_DEV_COMMIT)" -t "$(IMAGE_REPO):dev" -t "$(IMAGE_REPO):$(TASKD_DEV_COMMIT)" .

push:
	docker push "$(IMAGE_REPO):latest"
	docker push "$(IMAGE_REPO):dev"
	docker push "$(IMAGE_REPO):$(TASKD_COMMIT)"

