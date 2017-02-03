DOCKER_IMAGE:=storm-debian-packaging
DOCKER_CONTAINER:=storm-debian-packaging
UID:=$(shell whoami | id -u)
GID:=$(shell whoami | id -g)

clean:
	rm -f apache-storm_*.changes
	rm -f apache-storm_*.dsc
	rm -f apache-storm_*.tar.gz
	rm -f *.deb	

docker_rm:
	docker inspect -f {{.Id}} --type=container $(DOCKER_CONTAINER) >/dev/null 2>&1 && \
	docker rm -f $(DOCKER_CONTAINER) || true

docker_rmi:
	docker inspect -f {{.Id}} --type=image $(DOCKER_IMAGE) >/dev/null 2>&1 && \
	docker rmi $(DOCKER_IMAGE) || true

docker_clean: docker_rm docker_rmi

docker_image:
	docker inspect -f {{.Id}} --type=image $(DOCKER_IMAGE) >/dev/null 2>&1 || \
	docker build $(DOCKER_BUILD_PROXY_ARGS) -t $(DOCKER_IMAGE) .

docker_console: docker_image
	docker run -ti --name $(DOCKER_CONTAINER) --rm -v $(shell pwd):/usr/src/app $(DOCKER_IMAGE) /bin/bash

docker_package: docker_rm
	docker run --name $(DOCKER_CONTAINER) --detach=true -v $(shell pwd):/usr/src/app $(DOCKER_IMAGE) sleep infinity
	docker exec $(DOCKER_CONTAINER) /bin/bash ./build.sh
	# Let caller be the owner (quick workaround)
	docker exec $(DOCKER_CONTAINER) chown --recursive $(UID):$(GID) *
	docker stop $(DOCKER_CONTAINER)
	docker rm $(DOCKER_CONTAINER)
