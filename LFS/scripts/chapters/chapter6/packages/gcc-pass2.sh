#!/bin/bash

# GCC-pass2 软件包构建脚本
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
LOG_FILE="$LFS_LOGS/chapter6_gcc-pass2_$(date +%Y%m%d_%H%M%S).log"

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
    log "GCC-pass2 构建失败，退出执行"
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
    local build_dir="/tmp/build-gcc-pass2"
    if [ -d "$build_dir" ]; then
        rm -rf "$build_dir"
    fi
    mkdir -p "$build_dir"
    
    tar -xf "$package_file" -C "$build_dir" || error_exit "解压 GCC 软件包失败"
    
    # 解压依赖包
    local gcc_dir="$build_dir/gcc-15.2.0"
    cd "$gcc_dir" || error_exit "进入 GCC 源码目录失败"
    
    # 解压 MPFR
    local mpfr_file="$DOWNLOAD_DIR/mpfr-4.2.2.tar.xz"
    if [ -f "$mpfr_file" ]; then
        log "解压 MPFR 软件包..."
        tar -xf "$mpfr_file" || error_exit "解压 MPFR 软件包失败"
        mv -v mpfr-4.2.2 mpfr || error_exit "重命名 MPFR 目录失败"
    else
        error_exit "MPFR 软件包不存在: $mpfr_file"
    fi
    
    # 解压 GMP
    local gmp_file="$DOWNLOAD_DIR/gmp-6.3.0.tar.xz"
    if [ -f "$gmp_file" ]; then
        log "解压 GMP 软件包..."
        tar -xf "$gmp_file" || error_exit "解压 GMP 软件包失败"
        mv -v gmp-6.3.0 gmp || error_exit "重命名 GMP 目录失败"
    else
        error_exit "GMP 软件包不存在: $gmp_file"
    fi
    
    # 解压 MPC
    local mpc_file="$DOWNLOAD_DIR/mpc-1.3.1.tar.gz"
    if [ -f "$mpc_file" ]; then
        log "解压 MPC 软件包..."
        tar -xf "$mpc_file" || error_exit "解压 MPC 软件包失败"
        mv -v mpc-1.3.1 mpc || error_exit "重命名 MPC 目录失败"
    else
        error_exit "MPC 软件包不存在: $mpc_file"
    fi
    
    # 在 x86_64 主机上，设置 64 位库的默认目录名为 "lib"
    if [ "$(uname -m)" = "x86_64" ]; then
        log "在 x86_64 主机上设置默认库目录名..."
        sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64 || error_exit "修改库目录名配置失败"
    fi
    
    log "GCC 软件包解压完成"
    echo "$gcc_dir"
}

# 函数：构建软件包
build_package() {
    local source_dir="$1"
    log "开始构建 GCC-pass2..."
    
    # 创建构建目录
    local build_dir="$source_dir/build"
    mkdir -p "$build_dir"
    cd "$build_dir" || error_exit "进入构建目录失败"
    
    # 准备编译
    log "准备 GCC-pass2 编译..."
    ../configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(../config.guess) \
            --disable-nls \
            --enable-gprofng=no \
            --disable-libstdcxx-pch \
            --disable-decimal-float \
            --disable-libatomic \
            --disable-libgomp \
            --disable-libquadmath \
            --disable-libssp \
            --disable-libvtv \
            --enable-languages=c,c++ || error_exit "配置 GCC-pass2 失败"
    
    # 编译
    log "编译 GCC-pass2..."
    make || error_exit "编译 GCC-pass2 失败"
    
    # 安装
    log "安装 GCC-pass2..."
    make DESTDIR=$LFS_MOUNT install || error_exit "安装 GCC-pass2 失败"
    
    # 清理
    log "清理 GCC-pass2 构建文件..."
    rm -v $LFS_MOUNT/usr/lib/lib{stdc++{,exp,fs},supc++}.la || error_exit "清理 Libtool 归档文件失败"
    
    log "GCC-pass2 构建完成"
}

# 主函数
main() {
    log "开始 GCC-pass2 软件包构建过程..."
    
    # 解压软件包
    local source_dir=$(extract_package)
    
    # 构建软件包
    build_package "$source_dir"
    
    # 标记构建完成
    touch "$LFS_STATUS/chapter6_gcc-pass2"
    
    log "GCC-pass2 软件包构建完成！"
}

# 执行主函数
main
