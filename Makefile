IMAGE_REPO = "philipgatzka/docker-taskd"
TASKD_COMMIT ?= $$(git ls-remote 'https://github.com/GothenburgBitFactory/taskserver.git' refs/heads/1.2.0 | cut -b -7)

.PHONY: build push

default: Dockerfile entrypoint.sh vars.template build

build:
	docker build -t "$(IMAGE_REPO):latest" -t "$(IMAGE_REPO):$(TASKD_COMMIT)" .

push:
	docker push "$(IMAGE_REPO):latest"
	docker push "$(IMAGE_REPO):$(TASKD_COMMIT)"

