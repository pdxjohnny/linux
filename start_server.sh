#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
#  start_qemu.sh
#
#  Copyright (c) 2016-2017 Intel Corporation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

VMN=${VMN:="0"}
rm -f debug.log

# 10/25/2018: keep back compatibility for a while
UEFI_BIOS="-bios OVMF.fd"

if [ -f OVMF_VARS.fd -a -f OVMF_CODE.fd ]; then
    UEFI_BIOS=" -drive file=OVMF_CODE.fd,if=pflash,format=raw,unit=0,readonly=on "
    UEFI_BIOS+=" -drive file=OVMF_VARS.fd,if=pflash,format=raw,unit=1 "
fi

if [ -f pxe_server_${VMN}.mac ]; then
    mac=$(cat pxe_server_${VMN}.mac)
else
    mac=$(printf '52:54:00:%02X:%02X:%02X\n' \
        $[RANDOM%256] $[RANDOM%256] $[RANDOM%256])
    echo $mac > pxe_server_${VMN}.mac
fi

# Mount the rootfs directory from within the VM
# mount -t 9p -o trans=virtio,version=9p2000.L host0 /mnt

export CHROOT=${CHROOT:-"dhcpserver-rootfs/"}

# ${UEFI_BIOS} \

exec qemu-system-x86_64 \
    -enable-kvm \
    -smp sockets=1,cpus=4,cores=2 -cpu host \
    -m 1024 \
    -vga none -nographic \
    -fsdev \
        local,id=fsdev-root,path="${CHROOT}",security_model=passthrough,readonly \
    -device \
        virtio-9p-pci,fsdev=fsdev-root,mount_tag=9p_root \
    -net \
        nic,model=virtio \
    -net \
        user,id=mynet0,hostfwd=tcp::22222-:22 \
    -device virtio-rng-pci \
    -netdev socket,id=mynet1,mcast=239.192.168.1:1102 \
    -device virtio-net-pci,netdev=mynet1,mac=$mac \
    -kernel \
        "${CHROOT}/boot/vmlinuz-linux" \
    -append \
        "systemd.default_standard_error=ttyS0 systemd.default_standard_output=ttyS0 console=ttyS0 rootfstype=9p root=9p_root rootflags=trans=virtio,version=9p2000.L,ro init=/usr/lib/systemd/systemd" \
    -initrd \
        "${CHROOT}/boot/initramfs-linux-fallback.img"
