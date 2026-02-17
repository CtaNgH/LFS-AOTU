#!/bin/bash

# 章节9构建脚本
# 负责系统配置
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
LOG_FILE="$LFS_LOGS/chapter9_$(date +%Y%m%d_%H%M%S).log"

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
    log "章节9构建失败，退出执行"
    exit 1
}

# 函数：配置网络
configure_network() {
    log "配置网络..."
    
    # 创建 /etc/hosts 文件
    local hosts_file="$LFS_MOUNT/etc/hosts"
    log "创建 /etc/hosts 文件..."
    sudo cat > "$hosts_file" << "EOF"
127.0.0.1   localhost
::1         localhost
127.0.1.1   lfs.localdomain lfs
EOF
    
    # 创建 /etc/resolv.conf 文件
    local resolv_conf_file="$LFS_MOUNT/etc/resolv.conf"
    log "创建 /etc/resolv.conf 文件..."
    sudo cat > "$resolv_conf_file" << "EOF"
# 网络DNS配置
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
    
    log "网络配置完成"
}

# 函数：配置系统时钟
configure_clock() {
    log "配置系统时钟..."
    
    # 创建 /etc/localtime 符号链接
    local localtime_link="$LFS_MOUNT/etc/localtime"
    if [ ! -L "$localtime_link" ]; then
        log "创建 /etc/localtime 符号链接..."
        sudo ln -sf /usr/share/zoneinfo/Asia/Shanghai "$localtime_link" || error_exit "创建时区链接失败"
    fi
    
    log "系统时钟配置完成"
}

# 函数：配置控制台
configure_console() {
    log "配置控制台..."
    
    # 创建 /etc/vconsole.conf 文件
    local vconsole_conf_file="$LFS_MOUNT/etc/vconsole.conf"
    log "创建 /etc/vconsole.conf 文件..."
    sudo cat > "$vconsole_conf_file" << "EOF"
KEYMAP=us
FONT=Lat2-Terminus16
EOF
    
    log "控制台配置完成"
}

# 函数：配置fstab
configure_fstab() {
    log "配置 fstab..."
    
    # 创建 /etc/fstab 文件
    local fstab_file="$LFS_MOUNT/etc/fstab"
    log "创建 /etc/fstab 文件..."
    sudo cat > "$fstab_file" << "EOF"
# 文件系统挂载配置
/dev/nvme1n1p5   /           ext4    defaults        1 1
EOF
    
    log "fstab 配置完成"
}

# 函数：配置引导加载程序
configure_bootloader() {
    log "配置引导加载程序..."
    
    # 安装 GRUB
    log "安装 GRUB..."
    sudo chroot "$LFS_MOUNT" /usr/sbin/grub-install /dev/nvme1n1 || error_exit "GRUB 安装失败"
    
    # 生成 GRUB 配置文件
    log "生成 GRUB 配置文件..."
    sudo chroot "$LFS_MOUNT" /usr/sbin/grub-mkconfig -o /boot/grub/grub.cfg || error_exit "生成 GRUB 配置失败"
    
    log "引导加载程序配置完成"
}

# 主函数
main() {
    log "开始章节9构建过程..."
    log "章节9: 系统配置"
    
    # 配置网络
    configure_network
    
    # 配置系统时钟
    configure_clock
    
    # 配置控制台
    configure_console
    
    # 配置fstab
    configure_fstab
    
    # 配置引导加载程序
    configure_bootloader
    
    log "章节9构建完成！"
}

# 执行主函数
main
