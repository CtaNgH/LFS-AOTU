#!/bin/bash

# Linux 内核头文件构建脚本
# 严格参照 LFS-BOOK-SYSD-12.4 文档实现

# 设置脚本执行选项
set -euo pipefail

# 全局变量定义
LFS_ROOT="$(pwd)"
LFS_ROOT="$(dirname "$LFS_ROOT")"
LFS_ROOT="$(dirname "$LFS_ROOT")"
LFS_ROOT="$(dirname "$LFS_ROOT")"
LFS_ROOT="$(dirname "$LFS_ROOT")"
LFS_ROOT="$(dirname "$LFS_ROOT")"
LFS_SCRIPTS="$LFS_ROOT/scripts"
LFS_PACKAGES="$LFS_ROOT/packages"
LFS_LOGS="$LFS_ROOT/logs"
LFS_STATUS="$LFS_ROOT/status"

# 目标系统挂载点
LFS_MOUNT="/mnt/lfs"

# 下载目录
DOWNLOAD_DIR="$LFS_PACKAGES/sources"

# 日志文件
LOG_FILE="$LFS_LOGS/chapter5_linux-headers_$(date +%Y%m%d_%H%M%S).log"

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
    log "Linux 内核头文件构建失败，退出执行"
    exit 1
}

# 函数：解压软件包
extract_package() {
    log "解压 Linux 内核软件包..."
    
    local package_file="$DOWNLOAD_DIR/linux-6.16.1.tar.xz"
    if [ ! -f "$package_file" ]; then
        error_exit "Linux 内核软件包不存在: $package_file"
    fi
    
    # 解压到临时目录
    local build_dir="/tmp/build-linux-headers"
    if [ -d "$build_dir" ]; then
        rm -rf "$build_dir"
    fi
    mkdir -p "$build_dir"
    
    tar -xf "$package_file" -C "$build_dir" || error_exit "解压 Linux 内核软件包失败"
    
    log "Linux 内核软件包解压完成"
    echo "$build_dir/linux-6.16.1"
}

# 函数：构建软件包
build_package() {
    local source_dir="$1"
    log "开始构建 Linux 内核头文件..."
    
    cd "$source_dir" || error_exit "进入源码目录失败"
    
    # 准备编译
    log "准备 Linux 内核头文件编译..."
    make mrproper || error_exit "执行 make mrproper 失败"
    
    # 安装头文件
    log "安装 Linux 内核头文件..."
    make headers || error_exit "执行 make headers 失败"
    
    # 复制头文件到目标目录
    log "复制 Linux 内核头文件到目标目录..."
    find usr/include -name "*.h" -type f | xargs cp --parents -t $LFS_MOUNT/usr/include || error_exit "复制头文件失败"
    
    log "Linux 内核头文件构建完成"
}

# 主函数
main() {
    log "开始 Linux 内核头文件构建过程..."
    
    # 解压软件包
    local source_dir=$(extract_package)
    
    # 构建软件包
    build_package "$source_dir"
    
    # 标记构建完成
    touch "$LFS_STATUS/chapter5_linux-headers"
    
    log "Linux 内核头文件构建完成！"
}

# 执行主函数
main
