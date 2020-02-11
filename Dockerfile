FROM archlinux

RUN pacman -Sy --noconfirm linux

RUN pacman -Sy --noconfirm dhcp
