#!/bin/bash

# Ncurses 软件包构建脚本
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
LOG_FILE="$LFS_LOGS/chapter6_ncurses_$(date +%Y%m%d_%H%M%S).log"

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
    log "Ncurses 构建失败，退出执行"
    exit 1
}

# 函数：解压软件包
extract_package() {
    log "解压 Ncurses 软件包..."
    
    local package_file="$DOWNLOAD_DIR/ncurses-6.5-20250809.tgz"
    if [ ! -f "$package_file" ]; then
        error_exit "Ncurses 软件包不存在: $package_file"
    fi
    
    # 解压到临时目录
    local build_dir="/tmp/build-ncurses"
    if [ -d "$build_dir" ]; then
        rm -rf "$build_dir"
    fi
    mkdir -p "$build_dir"
    
    tar -xf "$package_file" -C "$build_dir" || error_exit "解压 Ncurses 软件包失败"
    
    log "Ncurses 软件包解压完成"
    echo "$build_dir/ncurses-6.5-20250809"
}

# 函数：构建软件包
build_package() {
    local source_dir="$1"
    log "开始构建 Ncurses..."
    
    cd "$source_dir" || error_exit "进入源码目录失败"
    
    # 首先在构建主机上构建 tic 程序
    log "在构建主机上构建 tic 程序..."
    mkdir build
    pushd build
    ../configure --prefix=$LFS_MOUNT/tools AWK=gawk || error_exit "配置 tic 程序失败"
    make -C include || error_exit "编译 include 目录失败"
    make -C progs tic || error_exit "编译 tic 程序失败"
    install progs/tic $LFS_MOUNT/tools/bin || error_exit "安装 tic 程序失败"
    popd
    
    # 准备编译 Ncurses
    log "准备 Ncurses 编译..."
    ./configure --prefix=/usr \
            --host=$LFS_TGT \
            --build=$(./config.guess) \
            --mandir=/usr/share/man \
            --with-manpage-format=normal \
            --with-shared \
            --without-normal \
            --with-cxx-shared \
            --without-debug \
            --without-ada \
            --disable-stripping \
            AWK=gawk || error_exit "配置 Ncurses 失败"
    
    # 编译
    log "编译 Ncurses..."
    make || error_exit "编译 Ncurses 失败"
    
    # 安装
    log "安装 Ncurses..."
    make DESTDIR=$LFS_MOUNT install || error_exit "安装 Ncurses 失败"
    
    # 创建必要的符号链接
    log "创建 Ncurses 符号链接..."
    ln -sf libncursesw.so $LFS_MOUNT/usr/lib/libncurses.so || error_exit "创建符号链接失败"
    
    log "Ncurses 构建完成"
}

# 主函数
main() {
    log "开始 Ncurses 软件包构建过程..."
    
    # 解压软件包
    local source_dir=$(extract_package)
    
    # 构建软件包
    build_package "$source_dir"
    
    # 标记构建完成
    touch "$LFS_STATUS/chapter6_ncurses"
    
    log "Ncurses 软件包构建完成！"
}

# 执行主函数
main
