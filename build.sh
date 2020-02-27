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

sudo rm -rf dhcpserver-rootfs/root/.ssh/
sudo mkdir -p dhcpserver-rootfs/root/.ssh/
cat ~/.ssh/id_rsa.pub | sudo tee dhcpserver-rootfs/root/.ssh/authorized_keys
sudo chmod 600 dhcpserver-rootfs/root/.ssh/authorized_keys
sudo chmod 700 dhcpserver-rootfs/root/.ssh
sudo chroot dhcpserver-rootfs/ systemctl enable --no-reload sshd
