DOCKER_IMAGE:=storm-debian-packaging
DOCKER_CONTAINER:=storm-debian-packaging
UID:=$(shell whoami | id -u)
GID:=$(shell whoami | id -g)
STORM_VERSION:=$(shell cat STORM_VERSION)
# since the project name is established to be `apache-storm`,
# decided to keep it hardcoded here
UPSTREAM_PATH=apache-storm-${STORM_VERSION}
UPSTREAM_FILE=downloads/${UPSTREAM_PATH}.tar.gz
ORIG_FILE=apache-storm_${STORM_VERSION}.orig.tar.gz
DOWNLOAD_COMMAND=wget -c -P downloads http://www.apache.org/dist/storm/${UPSTREAM_PATH}/${UPSTREAM_PATH}.tar.gz

clean:
	rm -f apache-storm_*.changes
	rm -f apache-storm_*.dsc
	rm -f apache-storm_*.tar.gz
	rm -f apache-storm_*.debian.tar.xz
	rm -f *.deb

upstream:
	$(info Download the upstream tarball, if it does not exists.)
	$(info Done so to make it possible to build custom version.)
	$(info To force download use `make download_upstream`)
	if [ -a $(UPSTREAM_FILE) ]; then echo "Using existing file $(UPSTREAM_FILE)"; else echo "Downloading file. $(UPSTREAM_FILE)"; $(DOWNLOAD_COMMAND); fi;

orig: upstream
	$(info Prepare *.orig.tar from apache-storm build)
	cp ${UPSTREAM_FILE} $(ORIG_FILE)

download_upstream:
	$(DOWNLOAD_COMMAND)

docker_rm:
	docker inspect -f {{.Id}} --type=container $(DOCKER_CONTAINER) >/dev/null 2>&1 && \
	docker rm -f $(DOCKER_CONTAINER) || true

docker_rmi: docker_rm
	docker inspect -f {{.Id}} --type=image $(DOCKER_IMAGE) >/dev/null 2>&1 && \
	docker rmi $(DOCKER_IMAGE) || true

docker_clean: docker_rm docker_rmi

docker_image:
	docker inspect -f {{.Id}} --type=image $(DOCKER_IMAGE) >/dev/null 2>&1 || \
	docker build $(DOCKER_BUILD_PROXY_ARGS) -t $(DOCKER_IMAGE) .

docker_console: docker_image orig
	docker run -ti --name $(DOCKER_CONTAINER) --rm -v $(shell pwd):/usr/src/app $(DOCKER_IMAGE) /bin/bash

docker_package: docker_rm orig
	docker run --name $(DOCKER_CONTAINER) --detach=true -v $(shell pwd):/usr/src/app $(DOCKER_IMAGE) sleep infinity
	docker exec $(DOCKER_CONTAINER) /bin/bash ./build.sh
	# Let caller be the owner (quick workaround)
	docker exec $(DOCKER_CONTAINER) chown --recursive $(UID):$(GID) *
	docker stop $(DOCKER_CONTAINER)
	docker rm $(DOCKER_CONTAINER)
