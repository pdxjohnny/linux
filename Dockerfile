FROM archlinux

RUN pacman -Sy --noconfirm linux

RUN pacman -Sy --noconfirm dhcp

RUN pacman -Sy --noconfirm openssh
