# qemu-alpine-live

QEMU RISC-V Alpine Linux 启动环境，支持 9p 文件夹直通和块设备直通。

## 文件说明

| 文件 | 说明 |
|---|---|
| `Image` | RISC-V 内核（raw Image，从 linux 源码编译） |
| `alpine-rootfs/` | Alpine rootfs 目录（9p 直通到 guest） |
| `alpine-minirootfs-*.tar.gz` | Alpine 官方 mini rootfs 压缩包 |
| `start.sh` | 启动脚本 |
| `patch-alpine-rootfs.sh` | rootfs 补丁（busybox init + 串口登录） |

## 快速开始

```bash
# 1. 解压 rootfs
mkdir -p alpine-rootfs
tar xzf alpine-minirootfs-*.tar.gz -C alpine-rootfs

# 2. 打补丁（busybox init + 串口 getty + root 空密码）
./patch-alpine-rootfs.sh

# 3. 启动
./start.sh
```

## 启动脚本用法

```bash
# 默认：9p 直通 alpine-rootfs/
./start.sh

# 9p 直通指定目录
./start.sh /path/to/rootfs

# 直通块设备（如 USB）
./start.sh /dev/sdb2

# 带额外内核参数
./start.sh ./alpine-rootfs "loglevel=7"
```

## 直通块设备的权限

直通块设备（如 USB）时，QEMU 需要对设备有读写权限。

```bash
# 查看设备权限
ls -l /dev/sdb2
# brw-rw---- 1 root disk 8, 18 Jun 22 11:00 /dev/sdb2

# 临时授权（重启后失效）
sudo chmod 666 /dev/sdb2

# 或加入 disk 组（推荐）
sudo usermod -aG disk $USER
# 重新登录后生效
```

## 内核编译

从 Linux 源码编译 RISC-V 内核：

```bash
# 需要 riscv64-linux-gnu-gcc 交叉编译工具链
# Arch Linux: pacman -S riscv64-linux-gnu-gcc
make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- olddefconfig
make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- -j$(nproc) Image
cp arch/riscv/boot/Image ../Image
```

关键配置项（`.config`）：
- `CONFIG_EFI_STUB=n` — 生成 raw Image 而非 PE/COFF
- `CONFIG_9P_FS=y` — 9p 文件系统支持
- `CONFIG_VIRTIO_PCI=y` / `CONFIG_VIRTIO_NET=y` — virtio 驱动
- `CONFIG_PACKET=y` — DHCP 需要
