#!/bin/bash

# 章节8构建脚本
# 负责安装基本系统软件
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
LOG_FILE="$LFS_LOGS/chapter8_$(date +%Y%m%d_%H%M%S).log"

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
    log "章节8构建失败，退出执行"
    exit 1
}

# 函数：构建软件包
build_package() {
    local package="$1"
    log "开始构建软件包: $package"
    
    # 检查软件包脚本是否存在
    local package_script="$LFS_SCRIPTS/chapters/chapter8/packages/$package.sh"
    if [ ! -f "$package_script" ]; then
        error_exit "软件包脚本不存在: $package_script"
    fi
    
    # 检查是否已经构建完成
    if [ -f "$LFS_STATUS/chapter8_$package" ]; then
        log "软件包 $package 已经构建完成，跳过执行"
        return 0
    fi
    
    # 执行软件包构建脚本
    bash "$package_script" || error_exit "软件包 $package 构建失败"
    
    log "软件包 $package 构建完成"
}

# 主函数
main() {
    log "开始章节8构建过程..."
    log "章节8: 安装基本系统软件"
    
    # 构建基本系统软件包
    # 这里需要按照文档顺序构建各个软件包
    # 暂时只列出主要软件包，后续需要为每个软件包创建单独的脚本
    local packages=(
        "man-pages"
        "iana-etc"
        "glibc"
        "zlib"
        "bzip2"
        "xz"
        "lz4"
        "zstd"
        "file"
        "readline"
        "m4"
        "bc"
        "flex"
        "tcl"
        "expect"
        "dejagnu"
        "pkgconf"
        "binutils"
        "gmp"
        "mpfr"
        "mpc"
        "attr"
        "acl"
        "libcap"
        "libxcrypt"
        "shadow"
        "gcc"
        "ncurses"
        "sed"
        "psmisc"
        "gettext"
        "bison"
        "grep"
        "bash"
        "libtool"
        "gdbm"
        "gperf"
        "expat"
        "inetutils"
        "less"
        "perl"
        "xml-parser"
        "intltool"
        "autoconf"
        "automake"
        "openssl"
        "elfutils"
        "libffi"
        "python"
        "flit-core"
        "packaging"
        "wheel"
        "setuptools"
        "ninja"
        "meson"
        "kmod"
        "coreutils"
        "diffutils"
        "gawk"
        "findutils"
        "groff"
        "grub"
        "gzip"
        "iproute2"
        "kbd"
        "libpipeline"
        "make"
        "patch"
        "tar"
        "texinfo"
        "vim"
        "markupsafe"
        "jinja2"
        "systemd"
        "d-bus"
        "man-db"
        "procps-ng"
        "util-linux"
        "e2fsprogs"
    )
    
    for package in "${packages[@]}"; do
        build_package "$package"
    done
    
    log "章节8构建完成！"
}

# 执行主函数
main
