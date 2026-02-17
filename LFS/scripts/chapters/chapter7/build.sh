#!/bin/bash

# 章节7构建脚本
# 负责进入chroot环境并构建最终系统
# 严格参照 LFS-BOOK-SYSD-12.4 文档实现

# 设置脚本执行选项
set -euo pipefail

# 全局变量定义
LFS_ROOT="$(dirname "$(dirname "$(dirname "$(dirname "$(pwd)")")")")"
LFS_SCRIPTS="$LFS_ROOT/scripts"
LFS_LOGS="$LFS_ROOT/logs"
LFS_STATUS="$LFS_ROOT/status"

# 目标系统挂载点
LFS_MOUNT="/mnt/lfs"

# 日志文件
LOG_FILE="$LFS_LOGS/chapter7_$(date +%Y%m%d_%H%M%S).log"

# 函数：记录日志
log() {
    local message="$1"
    local timestamp="$(date +%Y-%m-%d %H:%M:%S)"
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# 函数：错误处理
error_exit() {
    local message="$1"
    log "ERROR: $message"
    log "章节7构建失败，退出执行"
    exit 1
}

# 函数：检查挂载点
check_mount_point() {
    log "检查目标系统挂载点..."
    
    if [ ! -d "$LFS_MOUNT" ]; then
        error_exit "目标系统挂载点 $LFS_MOUNT 不存在"
    fi
    
    if ! mount | grep -q "$LFS_MOUNT"; then
        error_exit "目标系统挂载点 $LFS_MOUNT 未挂载"
    fi
    
    log "目标系统挂载点检查完成"
}

# 函数：挂载虚拟文件系统
mount_virtual_filesystems() {
    log "挂载虚拟文件系统..."
    
    # 挂载 /dev
    if ! mount | grep -q "$LFS_MOUNT/dev"; then
        log "挂载 /dev..."
        sudo mount --bind /dev "$LFS_MOUNT/dev" || error_exit "挂载 /dev 失败"
    fi
    
    # 挂载 /dev/pts
    if ! mount | grep -q "$LFS_MOUNT/dev/pts"; then
        log "挂载 /dev/pts..."
        sudo mount -t devpts devpts "$LFS_MOUNT/dev/pts" -o gid=5,mode=620 || error_exit "挂载 /dev/pts 失败"
    fi
    
    # 挂载 /proc
    if ! mount | grep -q "$LFS_MOUNT/proc"; then
        log "挂载 /proc..."
        sudo mount -t proc proc "$LFS_MOUNT/proc" || error_exit "挂载 /proc 失败"
    fi
    
    # 挂载 /sys
    if ! mount | grep -q "$LFS_MOUNT/sys"; then
        log "挂载 /sys..."
        sudo mount -t sysfs sysfs "$LFS_MOUNT/sys" || error_exit "挂载 /sys 失败"
    fi
    
    # 挂载 /run
    if ! mount | grep -q "$LFS_MOUNT/run"; then
        log "挂载 /run..."
        sudo mount -t tmpfs tmpfs "$LFS_MOUNT/run" || error_exit "挂载 /run 失败"
    fi
    
    log "虚拟文件系统挂载完成"
}

# 函数：进入chroot环境
enter_chroot() {
    log "进入chroot环境..."
    
    # 执行chroot命令
    log "执行 chroot 命令..."
    sudo chroot "$LFS_MOUNT" /usr/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin \
    /bin/bash --login +h || error_exit "进入chroot环境失败"
    
    log "退出chroot环境"
}

# 主函数
main() {
    log "开始章节7构建过程..."
    log "章节7: 进入chroot环境并构建最终系统"
    
    # 检查挂载点
    check_mount_point
    
    # 挂载虚拟文件系统
    mount_virtual_filesystems
    
    # 进入chroot环境
    enter_chroot
    
    log "章节7构建完成！"
}

# 执行主函数
main
