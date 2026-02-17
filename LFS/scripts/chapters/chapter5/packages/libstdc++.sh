#!/bin/bash

# Libstdc++ 软件包构建脚本
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
LOG_FILE="$LFS_LOGS/chapter5_libstdc++_$(date +%Y%m%d_%H%M%S).log"

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
    log "Libstdc++ 构建失败，退出执行"
    exit 1
}

# 函数：解压软件包
extract_package() {
    log "解压 GCC 软件包..."
    
    local package_file="$DOWNLOAD_DIR/gcc-15.2.0.tar.xz"
    if [ ! -f "$package_file" ]; then
        error_exit "GCC 软件包不存在: $package_file"
    fi
    
    # 解压到临时目录
    local build_dir="/tmp/build-libstdc++"
    if [ -d "$build_dir" ]; then
        rm -rf "$build_dir"
    fi
    mkdir -p "$build_dir"
    
    tar -xf "$package_file" -C "$build_dir" || error_exit "解压 GCC 软件包失败"
    
    log "GCC 软件包解压完成"
    echo "$build_dir/gcc-15.2.0"
}

# 函数：构建软件包
build_package() {
    local source_dir="$1"
    log "开始构建 Libstdc++..."
    
    # 进入 Libstdc++ 目录
    local libstdcxx_dir="$source_dir/libstdc++-v3"
    cd "$libstdcxx_dir" || error_exit "进入 Libstdc++ 目录失败"
    
    # 创建构建目录
    local build_dir="$libstdcxx_dir/build"
    mkdir -p "$build_dir"
    cd "$build_dir" || error_exit "进入构建目录失败"
    
    # 准备编译
    log "准备 Libstdc++ 编译..."
    ../configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(../config.guess) \
            --disable-nls \
            --disable-libstdcxx-pch \
            --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/15.2.0 || error_exit "配置 Libstdc++ 失败"
    
    # 编译
    log "编译 Libstdc++..."
    make || error_exit "编译 Libstdc++ 失败"
    
    # 安装
    log "安装 Libstdc++..."
    make DESTDIR=$LFS_MOUNT install || error_exit "安装 Libstdc++ 失败"
    
    # 清理
    log "清理 Libstdc++ 构建文件..."
    rm -v $LFS_MOUNT/usr/lib/lib{stdc++{,exp,fs},supc++}.la || error_exit "清理 Libtool 归档文件失败"
    
    log "Libstdc++ 构建完成"
}

# 主函数
main() {
    log "开始 Libstdc++ 软件包构建过程..."
    
    # 解压软件包
    local source_dir=$(extract_package)
    
    # 构建软件包
    build_package "$source_dir"
    
    # 标记构建完成
    touch "$LFS_STATUS/chapter5_libstdc++"
    
    log "Libstdc++ 软件包构建完成！"
}

# 执行主函数
main
