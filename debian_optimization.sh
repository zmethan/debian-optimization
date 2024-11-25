#!/bin/bash

BACKUP_DIR="/root/system_backup"
ZRAM_CONFIG="/etc/default/zram-config"
FSTAB_FILE="/etc/fstab"
SWAP_FILE="/swapfile"

# 检查是否以 root 用户运行
if [[ $EUID -ne 0 ]]; then
    echo "请以 root 用户运行此脚本。"
    exit 1
fi

# 创建备份
backup_system() {
    echo "正在备份系统配置..."
    mkdir -p "$BACKUP_DIR"
    cp "$FSTAB_FILE" "$BACKUP_DIR/fstab.bak" 2>/dev/null
    cp "$ZRAM_CONFIG" "$BACKUP_DIR/zram-config.bak" 2>/dev/null
    echo "备份完成，备份文件存储于 $BACKUP_DIR"
}

# 恢复备份
restore_system() {
    echo "正在恢复系统配置..."
    if [[ -f "$BACKUP_DIR/fstab.bak" ]]; then
        cp "$BACKUP_DIR/fstab.bak" "$FSTAB_FILE"
    fi
    if [[ -f "$BACKUP_DIR/zram-config.bak" ]]; then
        cp "$BACKUP_DIR/zram-config.bak" "$ZRAM_CONFIG"
    fi
    if [[ -f "$SWAP_FILE" ]]; then
        swapoff "$SWAP_FILE"
        rm -f "$SWAP_FILE"
    fi
    echo "恢复完成，请重启系统以生效。"
}

# 配置 Swap
configure_swap() {
    echo "配置 Swap..."
    SWAP_SIZE_MB=1024  # 修改 Swap 大小为 1GB
    if swapon --show | grep -q "$SWAP_FILE"; then
        echo "Swap 已存在，跳过创建。"
    else
        fallocate -l "${SWAP_SIZE_MB}M" "$SWAP_FILE"
        chmod 600 "$SWAP_FILE"
        mkswap "$SWAP_FILE"
        swapon "$SWAP_FILE"
        echo "$SWAP_FILE none swap sw 0 0" >> "$FSTAB_FILE"
        echo "Swap 配置完成，大小：${SWAP_SIZE_MB}MB"
    fi
}

# 配置 ZRAM
configure_zram() {
    echo "配置 ZRAM..."
    apt update && apt install -y zram-tools
    cat <<EOF > "$ZRAM_CONFIG"
PERCENTAGE=50
ALGO=zstd
NUM_DEVICES=1
EOF
    systemctl enable zram-config
    systemctl restart zram-config
    echo "ZRAM 配置完成。当前状态："
    zramctl
}

# 优化系统
optimize_system() {
    echo "优化系统..."
    local services_to_disable=(
        "bluetooth.service"
        "avahi-daemon.service"
        "cups.service"
        "ModemManager.service"
        "rpcbind.service"
        "nfs-server.service"
        "apparmor.service"
        "cron.service"
        "systemd-timesyncd.service"
    )
    for service in "${services_to_disable[@]}"; do
        systemctl stop "$service" 2>/dev/null
        systemctl disable "$service" 2>/dev/null
    done

    echo "调整 Swappiness 参数..."
    sysctl vm.swappiness=10
    echo "vm.swappiness=10" >> /etc/sysctl.conf

    echo "优化完成！"
}

# 菜单
while true; do
    echo "=== Debian 12 优化工具 ==="
    echo "1) 备份当前系统配置"
    echo "2) 恢复系统到备份前状态"
    echo "3) 配置 Swap"
    echo "4) 配置 ZRAM"
    echo "5) 优化系统服务"
    echo "6) 全部优化（包含 Swap、ZRAM、系统服务）"
    echo "0) 退出"
    read -rp "请选择操作: " choice

    case $choice in
        1)
            backup_system
            ;;
        2)
            restore_system
            ;;
        3)
            configure_swap
            ;;
        4)
            configure_zram
            ;;
        5)
            optimize_system
            ;;
        6)
            backup_system
            configure_swap
            configure_zram
            optimize_system
            ;;
        0)
            echo "退出程序。"
            exit 0
            ;;
        *)
            echo "无效选项，请重试！"
            ;;
    esac
    echo
done
