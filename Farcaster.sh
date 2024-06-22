#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 安装基本依赖
function install_dependencies() {
    sudo apt update
    sudo apt install pkg-config curl build-essential libssl-dev libclang-dev ufw -y

    # 检查 Git 是否已安装
    if ! command -v git &> /dev/null; then
        echo "未检测到 Git，正在安装..."
        sudo apt install git -y
    else
        echo "Git 已安装。"
    fi

    # 检查 Docker 是否已安装
    if ! command -v docker &> /dev/null; then
        echo "未检测到 Docker，正在安装..."
        sudo apt-get install ca-certificates curl gnupg lsb-release -y
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        sudo apt-get update
        sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
    else
        echo "Docker 已安装。"
    fi

    install_jq
}

# 安装 jq 工具
function install_jq() {
    if command -v jq >/dev/null 2>&1; then
        echo "jq 已安装。"
        return 0
    fi

    echo "安装 jq..."

    if [[ "$(uname)" == "Darwin" ]]; then
        if command -v brew >/dev/null 2>&1; then
            brew install jq
        else
            echo "未检测到 Homebrew，请先安装 Homebrew。"
            return 1
        fi
    elif [[ -f /etc/lsb-release ]] || [[ -f /etc/debian_version ]]; then
        sudo apt-get update
        sudo apt-get install -y jq
    elif [[ -f /etc/redhat-release ]]; then
        sudo yum install -y jq
    elif [[ -f /etc/fedora-release ]]; then
        sudo dnf install -y jq
    elif [[ -f /etc/os-release ]] && grep -q "ID=openSUSE" /etc/os-release; then
        sudo zypper install -y jq
    elif [[ -f /etc/arch-release ]]; then
        sudo pacman -S jq
    else
        echo "不支持的操作系统，请手动安装 jq。"
        return 1
    fi

    echo "jq 安装成功。"
}

# 从仓库获取文件
function fetch_file_from_repo() {
    local file_path="$1"
    local local_filename="$2"

    local download_url="https://raw.githubusercontent.com/farcasterxyz/hub-monorepo/@latest/$file_path?t=$(date +%s)"
    curl -sS -o "$local_filename" "$download_url" || { echo "下载 $download_url 失败。"; exit 1; }
}

# 安装 hubble 节点
function install_node() {
    install_dependencies

    mkdir -p ~/hubble
    local tmp_file=$(mktemp)
    fetch_file_from_repo "scripts/hubble.sh" "$tmp_file"
    mv "$tmp_file" ~/hubble/hubble.sh
    chmod +x ~/hubble/hubble.sh

    cd ~/hubble
    exec ./hubble.sh "upgrade" < /dev/tty
}

# 查看节点日志
function check_service_status() {
    cd $HOME
    /root/hubble/hubble.sh logs
}

# 主菜单
function main_menu() {
    clear
    echo "脚本以及教程由推特用户大赌哥 @y95277777 编写，免费开源，请勿相信收费"
    echo "=====================Farcaster节点安装========================="
    echo "节点社区 Discord 社群:https://discord.gg/GbMV5EcNWF"
    echo "请选择要执行的操作:"
    echo "1. 安装节点"
    echo "2. 查看节点日志"
    read -p "请输入选项（1-2）: " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_service_status ;;
    *) echo "无效选项。" ;;
    esac
}

# 显示主菜单
main_menu
