#!/bin/bash

# Bison 软件包构建脚本
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
LOG_FILE="$LFS_LOGS/chapter7_bison_$(date +%Y%m%d_%H%M%S).log"

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
    log "Bison 构建失败，退出执行"
    exit 1
}

# 函数：解压软件包
extract_package() {
    log "解压 Bison 软件包..."
    
    local package_file="$DOWNLOAD_DIR/bison-3.8.2.tar.xz"
    if [ ! -f "$package_file" ]; then
        error_exit "Bison 软件包不存在: $package_file"
    fi
    
    # 解压到临时目录
    local build_dir="/tmp/build-bison"
    if [ -d "$build_dir" ]; then
        rm -rf "$build_dir"
    fi
    mkdir -p "$build_dir"
    
    tar -xf "$package_file" -C "$build_dir" || error_exit "解压 Bison 软件包失败"
    
    log "Bison 软件包解压完成"
    echo "$build_dir/bison-3.8.2"
}

# 函数：构建软件包
build_package() {
    local source_dir="$1"
    log "开始构建 Bison..."
    
    cd "$source_dir" || error_exit "进入源代码目录失败"
    
    # 准备编译
    log "准备 Bison 编译..."
    ./configure --prefix=/usr || error_exit "配置 Bison 失败"
    
    # 编译
    log "编译 Bison..."
    make || error_exit "编译 Bison 失败"
    
    # 安装
    log "安装 Bison..."
    make install || error_exit "安装 Bison 失败"
    
    log "Bison 构建完成"
}

# 主函数
main() {
    log "开始 Bison 软件包构建过程..."
    
    # 解压软件包
    local source_dir=$(extract_package)
    
    # 构建软件包
    build_package "$source_dir"
    
    # 标记构建完成
    touch "$LFS_STATUS/chapter7_bison"
    
    log "Bison 软件包构建完成！"
}

# 执行主函数
main