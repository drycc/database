# Short name: Short name, following [a-zA-Z_], used all over the place.
# Some uses for short name:
# - Docker image name
# - Kubernetes service, rc, pod, secret, volume names
SHORT_NAME := postgres
DRYCC_REGISTRY ?= ${DEV_REGISTRY}
IMAGE_PREFIX ?= drycc
PLATFORM ?= linux/amd64,linux/arm64

include versioning.mk

SHELL_SCRIPTS = $(wildcard _scripts/*.sh contrib/ci/*.sh rootfs/bin/*)

# The following variables describe the containerized development environment
# and other build options
DEV_ENV_IMAGE := ${DEV_REGISTRY}/drycc/go-dev
DEV_ENV_WORK_DIR := /go/src/${REPO_PATH}
DEV_ENV_CMD := docker run --rm -v ${CURDIR}:${DEV_ENV_WORK_DIR} -w ${DEV_ENV_WORK_DIR} ${DEV_ENV_IMAGE}
DEV_ENV_CMD_INT := docker run -it --rm -v ${CURDIR}:${DEV_ENV_WORK_DIR} -w ${DEV_ENV_WORK_DIR} ${DEV_ENV_IMAGE}

all: docker-build docker-push

# For cases where we're building from local
# We also alter the RC file to set the image name.
docker-build:
	docker build ${DOCKER_BUILD_FLAGS} -t ${IMAGE} .
	docker tag ${IMAGE} ${MUTABLE_IMAGE}

docker-buildx:
	docker buildx build --platform ${PLATFORM} -t ${IMAGE} . --push

test: test-style test-functional

test-style:
	${DEV_ENV_CMD} shellcheck $(SHELL_SCRIPTS)

test-functional: test-functional-minio

test-functional-minio:
	contrib/ci/test-minio.sh ${IMAGE}

.PHONY: all docker-build docker-push test
