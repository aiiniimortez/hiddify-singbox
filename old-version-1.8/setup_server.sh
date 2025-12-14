#!/bin/bash

# --- ایجاد و قفل کردن sysctl.conf ---

echo "[+] Updating /etc/sysctl.conf ..."

sudo rm -f /etc/sysctl.conf

sudo tee /etc/sysctl.conf >/dev/null <<EOF
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
tcp_adv_win_scale = -2
net.ipv4.tcp_syncookies = 1
net.ipv4.ip_local_port_range = 10000 65535
net.core.netdev_max_backlog = 32768
net.core.optmem_max = 262144
net.core.somaxconn = 65536
net.core.rmem_max = 33554432
net.core.rmem_default = 1048576
net.core.wmem_max = 33554432
net.core.wmem_default = 1048576
net.ipv4.tcp_rmem = 16384 1048576 33554432
net.ipv4.tcp_wmem = 16384 1048576 33554432
net.ipv4.tcp_max_syn_backlog = 20480
net.ipv4.tcp_mem = 65536 1048576 33554432
net.ipv4.udp_mem = 65536 1048576 33554432
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384
EOF

sudo chattr +i /etc/sysctl.conf
echo "[✓] sysctl.conf created and locked."


# --- تنظیم DNS و قفل کردن resolv.conf ---

echo "[+] Setting DNS to 8.8.8.8 ..."
sudo rm -f /etc/resolv.conf
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf >/dev/null
sudo chattr +i /etc/resolv.conf
echo "[✓] DNS updated and locked."


# --- چک کردن مسیر warp و اجرای اسکریپت‌ها ---

WARP_DIR="/opt/hiddify-manager/other/warp/wireguard"

if [ -d "$WARP_DIR" ]; then
    echo "[+] Warp directory found. Running scripts..."
    cd "$WARP_DIR" || exit
    
    chmod +x *.sh

    if [ -f "./install.sh" ]; then
        ./install.sh
    fi
    
    if [ -f "./change_ip.sh" ]; then
        ./change_ip.sh
    fi
    
    echo "[✓] Warp scripts executed."
else
    echo "[!] Warp directory not found. Skipping warp setup."
fi


# --- اجرای اسکریپت آنلاین GitHub ---

echo "[+] Running remote modify-singbox.sh script ..."
bash <(curl -fsSL https://raw.githubusercontent.com/aiiniimortez/hiddify-singbox/refs/heads/main/modify-singbox.sh)
echo "[✓] Remote script executed."


# --- ریبوت سیستم ---

echo "[+] Rebooting system in 3 seconds ..."
sleep 3
sudo reboot
