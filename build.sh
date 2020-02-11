#!/usr/bin/env bash
set -xe

IMAGE_NAME=${IMAGE_NAME:-"dhcpserver"}

docker build -t "${IMAGE_NAME}" .

CONTAINER_NAME=$(mktemp --dry-run builder-XXXXXXXXXX)
trap "set +e; docker kill ${CONTAINER_NAME}; docker rm -f ${CONTAINER_NAME}" EXIT
docker run -d --name "${CONTAINER_NAME}" --entrypoint tail "${IMAGE_NAME}" -F /dev/null
docker kill "${CONTAINER_NAME}"

mkdir -p dhcpserver-rootfs
docker export "${CONTAINER_NAME}" | sudo tar -C dhcpserver-rootfs -x
