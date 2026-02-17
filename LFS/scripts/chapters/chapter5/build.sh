#!/bin/bash

# 章节5构建脚本
# 负责构建交叉工具链和临时工具
# 严格参照 LFS-BOOK-SYSD-12.4 文档实现

# 设置脚本执行选项
set -euo pipefail

# 全局变量定义
LFS_ROOT="$(dirname "$(dirname "$(dirname "$(dirname "$(pwd)")")")")"
LFS_SCRIPTS="$LFS_ROOT/scripts"
LFS_PACKAGES="$LFS_ROOT/packages"
LFS_LOGS="$LFS_ROOT/logs"
LFS_STATUS="$LFS_ROOT/status"

# 目标系统挂载点
LFS_MOUNT="/mnt/lfs"

# 下载目录
DOWNLOAD_DIR="$LFS_PACKAGES/sources"

# 日志文件
LOG_FILE="$LFS_LOGS/chapter5_$(date +%Y%m%d_%H%M%S).log"

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
    log "章节5构建失败，退出执行"
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

# 函数：创建工具目录
create_tools_directory() {
    log "创建工具目录..."
    
    sudo mkdir -pv "$LFS_MOUNT/tools" || error_exit "创建工具目录失败"
    sudo chown -v lfs:lfs "$LFS_MOUNT/tools" || error_exit "设置工具目录权限失败"
    
    # 创建 tools 符号链接
    if [ ! -L /tools ]; then
        sudo ln -sv "$LFS_MOUNT/tools" / || error_exit "创建 tools 符号链接失败"
    fi
    
    log "工具目录创建完成"
}

# 函数：构建软件包
build_package() {
    local package="$1"
    log "开始构建软件包: $package"
    
    # 检查软件包脚本是否存在
    local package_script="$LFS_SCRIPTS/chapters/chapter5/packages/$package.sh"
    if [ ! -f "$package_script" ]; then
        error_exit "软件包脚本不存在: $package_script"
    fi
    
    # 检查是否已经构建完成
    if [ -f "$LFS_STATUS/chapter5_$package" ]; then
        log "软件包 $package 已经构建完成，跳过执行"
        return 0
    fi
    
    # 执行软件包构建脚本
    bash "$package_script" || error_exit "软件包 $package 构建失败"
    
    log "软件包 $package 构建完成"
}

# 主函数
main() {
    log "开始章节5构建过程..."
    log "章节5: 构建交叉工具链和临时工具"
    
    # 检查挂载点
    check_mount_point
    
    # 创建工具目录
    create_tools_directory
    
    # 构建交叉工具链和临时工具
    # 按照文档顺序构建各个软件包
    local packages=(
        "binutils-pass1"
        "gcc-pass1"
        "linux-headers"
        "glibc"
        "libstdc++"
    )
    
    for package in "${packages[@]}"; do
        build_package "$package"
    done
    
    # 标记章节5构建完成
    touch "$LFS_STATUS/chapter_5"
    
    log "章节5构建完成！"
}

# 执行主函数
main
