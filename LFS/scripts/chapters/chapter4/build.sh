#!/bin/bash

# 章节4构建脚本
# 负责最终准备工作
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
LOG_FILE="$LFS_LOGS/chapter4_$(date +%Y%m%d_%H%M%S).log"

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
    log "章节4构建失败，退出执行"
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

# 函数：创建目录结构
create_directory_structure() {
    log "创建目标系统目录结构..."
    
    # 创建必要的目录
    log "创建基本目录结构..."
    sudo mkdir -pv "$LFS_MOUNT/etc" "$LFS_MOUNT/var" "$LFS_MOUNT/usr/bin" "$LFS_MOUNT/usr/lib" "$LFS_MOUNT/usr/sbin" || error_exit "创建基本目录失败"
    
    # 创建符号链接
    log "创建符号链接..."
    for i in bin lib sbin; do
        sudo ln -sv "usr/$i" "$LFS_MOUNT/$i" || error_exit "创建符号链接 $i 失败"
    done
    
    # 创建 lib64 目录（如果是 x86_64 架构）
    if [ "$(uname -m)" = "x86_64" ]; then
        log "创建 lib64 目录..."
        sudo mkdir -pv "$LFS_MOUNT/lib64" || error_exit "创建 lib64 目录失败"
    fi
    
    log "目录结构创建完成"
}

# 函数：创建非特权用户
create_lfs_user() {
    log "创建非特权用户..."
    
    # 检查 lfs 用户是否已存在
    if ! id -u lfs &> /dev/null; then
        log "创建 lfs 用户..."
        sudo groupadd lfs || error_exit "创建 lfs 用户组失败"
        sudo useradd -s /bin/bash -g lfs -m -k /dev/null lfs || error_exit "创建 lfs 用户失败"
    fi
    
    # 设置 lfs 用户密码
    log "设置 lfs 用户密码..."
    echo "lfs:lfs" | sudo chpasswd || error_exit "设置 lfs 用户密码失败"
    
    # 授予 lfs 用户对挂载点的访问权限
    log "授予 lfs 用户对挂载点的访问权限..."
    sudo chown -v lfs:lfs "$LFS_MOUNT" || error_exit "设置挂载点权限失败"
    
    log "非特权用户创建完成"
}

# 函数：创建构建环境脚本
create_build_environment() {
    log "创建构建环境脚本..."
    
    # 创建 .bashrc 文件
    local bashrc_path="$LFS_MOUNT/home/lfs/.bashrc"
    sudo mkdir -p "$(dirname "$bashrc_path")" || error_exit "创建 home 目录失败"
    
    sudo cat > "$bashrc_path" << "EOF"
set +h
export LFS=$LFS_MOUNT
export LC_ALL=POSIX
export LFS_TGT=$(uname -m)-lfs-linux-gnu
export PATH=/usr/bin:/bin

if [ ! -L /bin/sh ]; then
    ln -sf bash /bin/sh
fi

EOF
    
    # 创建 .bash_profile 文件
    local bash_profile_path="$LFS_MOUNT/home/lfs/.bash_profile"
    sudo cat > "$bash_profile_path" << "EOF"

if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

EOF
    
    # 设置文件权限
    sudo chown -v lfs:lfs "$bashrc_path" "$bash_profile_path" || error_exit "设置配置文件权限失败"
    
    log "构建环境脚本创建完成"
}

# 主函数
main() {
    log "开始章节4构建过程..."
    log "章节4: 最终准备工作"
    
    # 检查挂载点
    check_mount_point
    
    # 创建目录结构
    create_directory_structure
    
    # 创建非特权用户
    create_lfs_user
    
    # 创建构建环境
    create_build_environment
    
    log "章节4构建完成！"
}

# 执行主函数
main
