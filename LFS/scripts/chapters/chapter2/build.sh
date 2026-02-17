#!/bin/bash

# 章节2构建脚本
# 负责准备宿主系统
# 严格参照 LFS-BOOK-SYSD-12.4 文档实现

# 设置脚本执行选项
set -euo pipefail

# 全局变量定义
LFS_ROOT="$(dirname "$(dirname "$(dirname "$(dirname "$(pwd)")")")")"
LFS_SCRIPTS="$LFS_ROOT/scripts"
LFS_LOGS="$LFS_ROOT/logs"
LFS_STATUS="$LFS_ROOT/status"

# 日志文件
LOG_FILE="$LFS_LOGS/chapter2_$(date +%Y%m%d_%H%M%S).log"

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
    log "章节2构建失败，退出执行"
    exit 1
}

# 函数：检查宿主系统硬件要求
check_hardware() {
    log "检查宿主系统硬件要求..."
    
    # 检查CPU核心数
    local cpu_cores=$(nproc)
    log "CPU核心数: $cpu_cores"
    if [ "$cpu_cores" -lt 4 ]; then
        log "警告: CPU核心数少于4个，构建过程可能会很慢"
    fi
    
    # 检查内存大小
    local mem_total=$(free -m | awk '/Mem:/ {print $2}')
    log "内存大小: ${mem_total}MB"
    if [ "$mem_total" -lt 8192 ]; then
        log "警告: 内存大小少于8GB，构建过程可能会很慢"
    fi
    
    log "硬件要求检查完成"
}

# 函数：检查宿主系统软件要求
check_software() {
    log "检查宿主系统软件要求..."
    
    # 检查必要的软件包版本
    # 这里需要根据 LFS 文档要求检查具体版本
    # 暂时只检查是否存在
    local required_commands=(
        "gcc" "g++" "make" "binutils" "bash" "bzip2" "coreutils" "diff" 
        "find" "gawk" "gcc" "grep" "gzip" "m4" "make" "patch" "sed" 
        "tar" "xz" "file" "bc" "flex" "bison" "gperf" "expat" 
        "openssl" "perl" "python3" "texinfo"
    )
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            error_exit "缺少必要命令: $cmd"
        fi
    done
    
    log "软件要求检查完成"
}

# 函数：创建版本检查脚本
create_version_check_script() {
    log "创建版本检查脚本..."
    
    local script_path="$LFS_SCRIPTS/chapters/chapter2/version-check.sh"
    cat > "$script_path" << "EOF"
#!/bin/bash
# 版本检查脚本

# 检查命令是否存在
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "错误: 缺少命令 $1"
        exit 1
    fi
}

# 检查版本号
check_version() {
    local cmd="$1"
    local version_regex="$2"
    local min_version="$3"
    
    check_command "$cmd"
    
    local version=$($cmd --version | head -n 1 | grep -oE "$version_regex" | head -n 1)
    if [ -z "$version" ]; then
        echo "错误: 无法获取 $cmd 版本"
        exit 1
    fi
    
    echo "$cmd 版本: $version"
    
    # 简单的版本比较
    if [ "$(printf '%s\n' "$min_version" "$version" | sort -V | head -n 1)" != "$min_version" ]; then
        echo "错误: $cmd 版本低于要求的 $min_version"
        exit 1
    fi
}

# 检查必要的命令
check_version "gcc" "[0-9]+(\.[0-9]+)+" "11.0"
check_version "g++" "[0-9]+(\.[0-9]+)+" "11.0"
check_version "make" "[0-9]+(\.[0-9]+)+" "4.3"
check_version "binutils" "[0-9]+(\.[0-9]+)+" "2.36"
check_version "bash" "[0-9]+(\.[0-9]+)+" "5.0"
check_version "bzip2" "[0-9]+(\.[0-9]+)+" "1.0.6"
check_version "coreutils" "[0-9]+(\.[0-9]+)+" "8.30"
check_version "diff" "[0-9]+(\.[0-9]+)+" "3.7"
check_version "find" "[0-9]+(\.[0-9]+)+" "4.7"
check_version "gawk" "[0-9]+(\.[0-9]+)+" "5.0"
check_version "grep" "[0-9]+(\.[0-9]+)+" "3.4"
check_version "gzip" "[0-9]+(\.[0-9]+)+" "1.10"
check_version "m4" "[0-9]+(\.[0-9]+)+" "1.4.18"
check_version "patch" "[0-9]+(\.[0-9]+)+" "2.7"
check_version "sed" "[0-9]+(\.[0-9]+)+" "4.7"
check_version "tar" "[0-9]+(\.[0-9]+)+" "1.32"
check_version "xz" "[0-9]+(\.[0-9]+)+" "5.2"

# 检查其他必要的命令
check_command "file"
check_command "bc"
check_command "flex"
check_command "bison"
check_command "gperf"
check_command "expat"
check_command "openssl"
check_command "perl"
check_command "python3"
check_command "texinfo"

echo "所有检查通过，宿主系统满足要求"
EOF
    
    chmod +x "$script_path"
    log "版本检查脚本创建完成"
}

# 函数：执行版本检查
run_version_check() {
    log "执行版本检查..."
    
    local script_path="$LFS_SCRIPTS/chapters/chapter2/version-check.sh"
    bash "$script_path" || error_exit "版本检查失败"
    
    log "版本检查完成"
}

# 主函数
main() {
    log "开始章节2构建过程..."
    log "章节2: 准备宿主系统"
    
    # 检查硬件要求
    check_hardware
    
    # 检查软件要求
    check_software
    
    # 创建并执行版本检查脚本
    create_version_check_script
    run_version_check
    
    log "章节2构建完成！"
}

# 执行主函数
main
