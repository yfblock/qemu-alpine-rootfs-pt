#!/usr/bin/bash
wget https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/riscv64/alpine-minirootfs-3.24.1-riscv64.tar.gz -O alpine-rootfs.tar.gz
mkdir alpine-rootfs
tar zxf alpine-rootfs.tar.gz -C alpine-rootfs

