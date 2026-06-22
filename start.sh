#!/bin/bash
# Boot Alpine Linux (RISC-V) in QEMU
# Usage: ./start.sh [rootfs] [extra_cmdline]
#   rootfs = directory    → 9p passthrough
#   rootfs = block device → direct passthrough (e.g. /dev/sdb2)
#   extra_cmdline         → additional kernel command line args
#   (default: ./alpine-rootfs)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KERNEL="${SCRIPT_DIR}/Image"
ROOTFS="${1:-${SCRIPT_DIR}/alpine-rootfs}"
EXTRA_CMDLINE="$2"

QEMU_ARGS=(
    -machine virt
    -cpu rv64
    -smp 2
    -bios /usr/share/qemu/opensbi-riscv64-generic-fw_dynamic.bin
    -kernel "${KERNEL}"
    -netdev user,id=net0
    -device virtio-net-pci,netdev=net0
    -m 2G
    -serial mon:stdio
    -display none
)

if [ -d "${ROOTFS}" ]; then
    # Directory → 9p passthrough
    echo "Booting with 9p rootfs: ${ROOTFS}"
    QEMU_ARGS+=(
        -append "console=ttyS0 root=hostshare rootfstype=9p rootflags=trans=virtio,version=9p2000.L rw ${EXTRA_CMDLINE}"
        -virtfs local,path="${ROOTFS}",mount_tag=hostshare,security_model=none,id=hostshare
    )
elif [ -b "${ROOTFS}" ]; then
    # Block device → direct passthrough
    echo "Booting with block device: ${ROOTFS}"
    if mountpoint -q "${ROOTFS}" 2>/dev/null; then
        echo "Unmounting ${ROOTFS} ..."
        umount "${ROOTFS}"
    fi
    QEMU_ARGS+=(
        -append "console=ttyS0 root=/dev/vda modules=af_packet,virtio_blk,virtio_pci,virtio_net,ext4 rw ${EXTRA_CMDLINE}"
        -drive file="${ROOTFS}",format=raw,if=virtio,cache=none
    )
else
    echo "Error: ${ROOTFS} is not a directory or block device"
    exit 1
fi

exec qemu-system-riscv64 "${QEMU_ARGS[@]}"
