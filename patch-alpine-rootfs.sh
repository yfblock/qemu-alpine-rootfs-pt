#!/bin/bash
# Patch alpine-rootfs for busybox init with serial console

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOTFS="${SCRIPT_DIR}/alpine-rootfs"

# inittab: busybox init + serial getty
cat > "${ROOTFS}/etc/inittab" << 'EOF'
# /etc/inittab - busybox init

# 挂载基础文件系统
::sysinit:/bin/mount -t proc proc /proc
::sysinit:/bin/mount -t sysfs sysfs /sys
::sysinit:/bin/mount -t devtmpfs devtmpfs /dev
::sysinit:/bin/mkdir -p /dev/pts /dev/shm
::sysinit:/bin/mount -t devpts devpts /dev/pts
::sysinit:/bin/hostname -F /etc/hostname

# 网络
::sysinit:/sbin/ip link set lo up
::sysinit:/sbin/ip link set eth0 up
::sysinit:/sbin/udhcpc -i eth0

# 串口 getty
ttyS0::respawn:/sbin/getty -L 115200 ttyS0 vt100

# Ctrl+Alt+Del
::ctrlaltdel:/sbin/reboot

# 关机
::shutdown:/bin/umount -a -r
::shutdown:/bin/sync
EOF

# 解锁 root 密码（空密码）
sed -i 's/^root:\*:/root::/' "${ROOTFS}/etc/shadow"

# 设置主机名
echo "alpine" > "${ROOTFS}/etc/hostname"

echo "Done: ${ROOTFS}"
