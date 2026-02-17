#!/bin/bash

# Coreutils 软件包构建脚本
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
LOG_FILE="$LFS_LOGS/chapter6_coreutils_$(date +%Y%m%d_%H%M%S).log"

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
    log "Coreutils 构建失败，退出执行"
    exit 1
}

# 函数：解压软件包
extract_package() {
    log "解压 Coreutils 软件包..."
    
    local package_file="$DOWNLOAD_DIR/coreutils-9.7.tar.xz"
    if [ ! -f "$package_file" ]; then
        error_exit "Coreutils 软件包不存在: $package_file"
    fi
    
    # 解压到临时目录
    local build_dir="/tmp/build-coreutils"
    if [ -d "$build_dir" ]; then
        rm -rf "$build_dir"
    fi
    mkdir -p "$build_dir"
    
    tar -xf "$package_file" -C "$build_dir" || error_exit "解压 Coreutils 软件包失败"
    
    log "Coreutils 软件包解压完成"
    echo "$build_dir/coreutils-9.7"
}

# 函数：构建软件包
build_package() {
    local source_dir="$1"
    log "开始构建 Coreutils..."
    
    cd "$source_dir" || error_exit "进入源码目录失败"
    
    # 准备编译
    log "准备 Coreutils 编译..."
    ./configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(./config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime || error_exit "配置 Coreutils 失败"
    
    # 编译
    log "编译 Coreutils..."
    make || error_exit "编译 Coreutils 失败"
    
    # 安装
    log "安装 Coreutils..."
    make DESTDIR=$LFS_MOUNT install || error_exit "安装 Coreutils 失败"
    
    # 创建符号链接
    log "创建 Coreutils 符号链接..."
    ln -sf ../../bin/env $LFS_MOUNT/usr/bin/env || error_exit "创建 env 符号链接失败"
    
    log "Coreutils 构建完成"
}

# 主函数
main() {
    log "开始 Coreutils 软件包构建过程..."
    
    # 解压软件包
    local source_dir=$(extract_package)
    
    # 构建软件包
    build_package "$source_dir"
    
    # 标记构建完成
    touch "$LFS_STATUS/chapter6_coreutils"
    
    log "Coreutils 软件包构建完成！"
}

# 执行主函数
main
