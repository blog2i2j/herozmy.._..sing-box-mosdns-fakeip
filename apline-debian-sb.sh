check_os(){
 #获取系统发行版信息
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo -e "${red_text}无法确定当前系统，请使用Debian/Ubuntu/Alpine/armbian运行此脚本${reset}" >&2
    exit 1
fi

echo -e "当前系统: ${green_text}${release}${reset}"

# 支持的系统
supported_systems=("ubuntu" "debian" "alpine")

# 未测试兼容性的系统
untested_systems=("arch" "armbian")

# 不支持的系统
unsupported_systems=("parch" "manjaro" "opensuse-tumbleweed" "centos" "fedora" "almalinux" "rocky" "oracle")

# 检测系统
if [[ " ${supported_systems[@]} " =~ " ${release} " ]]; then
    echo -e "${green_text}系统检测通过${reset}"
    export SYSTEM_RELEASE="$release" 
    install_singbox
elif [[ " ${untested_systems[@]} " =~ " ${release} " ]]; then
    echo -e "${red_text}${release}: 未测试兼容性${reset}"
    main
elif [[ " ${unsupported_systems[@]} " =~ " ${release} " ]]; then
    echo -e "${red_text}${release}: 系统检测未通过，不支持${reset}"
    exit 1
else
    echo -e "${red_text}你的系统不支持当前脚本，未通过兼容性测试${reset}\n"
    echo "请重新安装系统，推荐:"
    echo "- Ubuntu 20.04+"
    echo "- Debian 11+"
    echo "- Alpine 3.14+"
    exit 1
fi

}
################################编译 Sing-Box 的最新版本################################
install_singbox() {


if [[ "$SYSTEM_RELEASE" == "alpine" ]]; then
    apk update
    apk add curl git build-base openssl-dev libevent-dev  gawk nftables|| { echo "软件包安装失败！退出脚本"; exit 1; }
    #zlib-dev mingw-w64
    setup-timezone -z Asia/Shanghai || { echo "时区设置失败！退出脚本"; exit 1; }

else
    apt update && apt -y upgrade || { echo "更新失败！退出脚本"; exit 1; }
    apt -y install curl git build-essential libssl-dev libevent-dev zlib1g-dev gcc-mingw-w64 nftables || { echo "软件包安装失败！退出脚本"; exit 1; }
    echo -e "\n设置时区为Asia/Shanghai"
    timedatectl set-timezone Asia/Shanghai || { echo -e "\e[31m时区设置失败！退出脚本\e[0m"; exit 1; }
    echo -e "\e[32m时区设置成功\e[0m"
fi

echo -e "编译Sing-Box 最新版本"
sleep 1
echo -e "开始编译Sing-Box 最新版本"
rm -rf /root/go/bin/*

# 获取 Go 版本
Go_Version=$(curl -s https://github.com/golang/go/tags | grep '/releases/tag/go' | head -n 1 | gawk -F/ '{print $6}' | gawk -F\" '{print $1}')
if [[ -z "$Go_Version" ]]; then
    echo "获取 Go 版本失败！退出脚本"
    exit 1
fi

# 判断 CPU 架构
case $(uname -m) in
    aarch64)
        arch="arm64"
        ;;
    x86_64)
        arch="amd64"
        ;;
    armv7l)
        arch="armv7"
        ;;
    armhf)
        arch="armhf"
        ;;
    *)
        echo "未知的 CPU 架构: $(uname -m)，退出脚本"
        exit 1
        ;;
esac

echo "系统架构是：$arch"
wget -O ${Go_Version}.linux-$arch.tar.gz https://go.dev/dl/${Go_Version}.linux-$arch.tar.gz || { echo "下载 Go 版本失败！退出脚本"; exit 1; }
tar -C /usr/local -xzf ${Go_Version}.linux-$arch.tar.gz || { echo "解压 Go 文件失败！退出脚本"; exit 1; }

# 设置 Go 环境变量
echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/golang.sh
# 你可能需要手动执行以下命令使环境变量生效
source /etc/profile.d/golang.sh

# 编译 Sing-Box
if ! go install -v -tags with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme github.com/sagernet/sing-box/cmd/sing-box@latest; then
    echo -e "Sing-Box 编译失败！退出脚本"
    exit 1
fi

echo -e "编译完成，开始安装"
sleep 1

# 检查是否存在旧版本的 sing-box
if [ -f "/usr/local/bin/sing-box" ]; then
    echo "检测到已安装的 sing-box"
    read -p "是否替换升级？(y/n): " replace_confirm
    if [ "$replace_confirm" = "y" ]; then
        echo "正在替换升级 sing-box"
        cp "$(go env GOPATH)/bin/sing-box" /usr/local/bin/ || { echo "复制文件失败！退出脚本"; exit 1; }
        chmod +x /usr/local/bin/sing-box  # 确保可执行权限
        echo "正在重启 sing-box"
        
        if [[ "$SYSTEM_RELEASE" == "alpine" ]]; then
            rc-service sing-box restart
        else
            systemctl restart sing-box
        fi
        
        echo "=================================================================="
        echo -e "\t\t\tSing-Box 内核升级完毕"
        echo -e "\t\t\tPowered by www.herozmy.com 2024"
        echo -e "\n"
        echo -e "温馨提示:\n本脚本仅在 LXC ubuntu22.04 环境下测试，其他环境未经验证，仅供个人使用"
        echo -e "本脚本仅适用于学习与研究等个人用途，请勿用于任何违反国家法律的活动！"
        echo "=================================================================="
        exit 0  # 替换完成后停止脚本运行
    else
        echo "用户取消了替换升级操作"
    fi
else
    # 如果不存在旧版本，则直接安装新版本
    cp "$(go env GOPATH)/bin/sing-box" /usr/local/bin/ || { echo "复制文件失败！退出脚本"; exit 1; }
    chmod +x /usr/local/bin/sing-box  # 确保可执行权限
    echo -e "Sing-Box 安装完成"
fi

# 创建 Sing-Box 配置目录
mkdir -p /etc/sing-box || { echo "创建配置目录失败！退出脚本"; exit 1; }
sleep 1  # 确保添加时间



}

################################用户自定义设置################################
customize_settings() {
    echo "是否选择生成配置？(y/n)"
    echo "生成配置文件需要添加机场订阅，如自建vps请选择n"
    read choice
if [ "$choice" = "y" ]; then
    read -p "输入订阅连接：" suburl
    suburl="${suburl:-https://}"
    echo "已设置订阅连接地址：$suburl"
    install_config
    
elif [ "$choice" = "n" ]; then
    echo "请手动配置config.json."
fi
    
}

################################开始创建config.json################################
install_config() {
    sub_host="https://sub-singbox.herozmy.com"   
    echo "请选择："
    echo "1. tproxy_fake_ip O大原版 <适用机场多规则分流> 配合O大mosdns食用"
    echo "2. tproxy_fake_ip O大原版 <适用VPS自建模式>配合O大mosdns食用"
    read -p "请输入选项 [默认: 1]: " choice
    # 如果用户没有输入选择，则默认为1
    choice=${choice:-1}
    if [ $choice -eq 1 ]; then
        json_file="&file=https://raw.githubusercontent.com/52shell/sing-box-mosdns-fakeip/main/config/fake-ip.json"
    elif [ $choice -eq 2 ]; then
        json_file="&file=https://raw.githubusercontent.com/52shell/sing-box-mosdns-fakeip/main/fake-ip.json"
    else
        echo "无效的选择。"
        return 1
    fi
    curl -o config.json "${sub_host}/config/${suburl}${json_file}"    
    # 检查下载是否成功
    if [ $? -eq 0 ]; then
        # 移动文件到目标位置
        mv config.json /etc/sing-box/config.json
        echo "Sing-box配置文件写入成功！"
    else
        echo "下载文件失败，请检查网络连接或者URL是否正确。"
    fi    
}
######################启动脚本################################
install_service() {
    echo -e "配置系统服务文件"
    sleep 1

if [[ "$SYSTEM_RELEASE" == "alpine" ]]; then
    # 检查 /etc/init.d/sing-box 是否存在
    if [ ! -f "/etc/init.d/sing-box" ]; then
        # 写入 sing-box 开机启动
        cat << EOF > /etc/init.d/sing-box
#!/sbin/openrc-run
name=\$RC_SVCNAME
description="sing-box service"

command="/usr/local/bin/sing-box"
command_args="-D /etc/sing-box -C /etc/sing-box run"
supervisor="supervise-daemon"

extra_started_commands="reload"

depend() {
    after net dns
}

reload() {
    ebegin "Reloading \$RC_SVCNAME"
    supervise-daemon "\$RC_SVCNAME" --signal HUP
    eend \$?
}
EOF
        chmod +x /etc/init.d/sing-box
        echo "sing-box 服务脚本已创建"
    else
        echo "警告：sing-box 服务文件已存在，无需创建"
    fi
else
    # 检查服务文件是否存在，如果不存在则创建
    sing_box_service_file="/etc/systemd/system/sing-box.service"
    if [ ! -f "$sing_box_service_file" ]; then
        # 如果服务文件不存在，则创建
        cat << EOF > "$sing_box_service_file"
[Unit]
Description=Sing-Box service
Documentation=https://sing-box.sagernet.org
After=network.target nss-lookup.target

[Service]
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box/config.json
Restart=on-failure
RestartSec=1800s
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF
        echo "sing-box 服务创建完成"
    else
        # 如果服务文件已经存在，则给出警告
        echo "警告：sing-box 服务文件已存在，无需创建"
    fi
        systemctl daemon-reload
fi

}
################################安装tproxy################################
install_tproxy() {
if [ "$SYSTEM_RELEASE" = "ubuntu" ]; then
    echo "当前系统为 Ubuntu 系统"
    
    # 检查 /etc/systemd/resolved.conf 中是否已设置 DNSStubListener=no
    if grep -q "^DNSStubListener=no" /etc/systemd/resolved.conf; then
        echo "DNSStubListener 已经设置为 no, 无需修改"
    else
        # 修改 DNSStubListener 设置为 no
        sed -i '/^#*DNSStubListener/s/#*DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
        echo "DNSStubListener 已被设置为 no"
        
        # 重启 systemd-resolved 服务
        systemctl restart systemd-resolved.service
        sleep 1
    fi
fi


    echo "创建系统转发"
# 判断是否已存在 net.ipv4.ip_forward=1
    if ! grep -q '^net.ipv4.ip_forward=1$' /etc/sysctl.conf; then
        echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    fi

# 判断是否已存在 net.ipv6.conf.all.forwarding = 1
    if ! grep -q '^net.ipv6.conf.all.forwarding = 1$' /etc/sysctl.conf; then
        echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.conf
    fi
    echo "系统转发创建完成"
    sleep 1
    echo "开始创建nftables tproxy转发"

# 写入tproxy rule    
# 判断文件是否存在

if [[ "$SYSTEM_RELEASE" == "alpine" ]]; then
    # 检查 /etc/init.d/singbox-route 是否存在
    if [ ! -f "/etc/init.d/sing-box-route" ]; then
        # 创建 Alpine 的服务脚本
        cat << 'EOF' > /etc/init.d/sing-box-route
#!/sbin/openrc-run

description="singbox-route service"

depend() {
    need net
    after net
}

start() {
    echo "Starting sing-box-route service"
    singbox_route_service_start_command
}

stop() {
    echo "Stopping sing-box-route service"
    singbox_route_service_stop_command
}

singbox_route_service_start_command() {
    /sbin/ip rule add fwmark 1 table 100
    /sbin/ip route add local default dev lo table 100
    /sbin/ip -6 rule add fwmark 1 table 101
    /sbin/ip -6 route add local ::/0 dev lo table 101
}

singbox_route_service_stop_command() {
    /sbin/ip rule del fwmark 1 table 100
    /sbin/ip route del local default dev lo table 100
    /sbin/ip -6 rule del fwmark 1 table 101
    /sbin/ip -6 route del local ::/0 dev lo table 101
}
EOF
        chmod +x /etc/init.d/sing-box-route
        echo "已完成路由表添加"
    else
        echo "警告：singbox-route 服务文件已存在，无需创建"
    fi
else
    # 检查 /etc/systemd/system/sing-box-router.service 是否存在
    if [ ! -f "/etc/systemd/system/sing-box-router.service" ]; then
        # 创建其他系统的服务文件
        cat << 'EOF' > "/etc/systemd/system/sing-box-router.service"
[Unit]
Description=sing-box TProxy Rules
After=network.target
Wants=network.target

[Service]
User=root
Type=oneshot
RemainAfterExit=yes
ExecStart=/sbin/ip rule add fwmark 1 table 100; /sbin/ip route add local default dev lo table 100; /sbin/ip -6 rule add fwmark 1 table 101; /sbin/ip -6 route add local ::/0 dev lo table 101
ExecStop=/sbin/ip rule del fwmark 1 table 100; /sbin/ip route del local default dev lo table 100; /sbin/ip -6 rule del fwmark 1 table 101; /sbin/ip -6 route del local ::/0 dev lo table 101

[Install]
WantedBy=multi-user.target
EOF
        echo "sing-box-router 服务创建完成"
    else
        echo "警告：sing-box-router 服务文件已存在，无需创建"
    fi
fi

################################写入nftables################################
check_interfaces
echo "" > "/etc/nftables.conf"
cat <<EOF > "/etc/nftables.conf"
#!/usr/sbin/nft -f
flush ruleset
table inet singbox {
  set local_ipv4 {
    type ipv4_addr
    flags interval
    elements = {
      10.0.0.0/8,
      127.0.0.0/8,
      169.254.0.0/16,
      172.16.0.0/12,
      192.168.0.0/16,
      240.0.0.0/4
    }
  }

  set local_ipv6 {
    type ipv6_addr
    flags interval
    elements = {
      ::ffff:0.0.0.0/96,
      64:ff9b::/96,
      100::/64,
      2001::/32,
      2001:10::/28,
      2001:20::/28,
      2001:db8::/32,
      2002::/16,
      fc00::/7,
      fe80::/10
    }
  }

  chain singbox-tproxy {
    fib daddr type { unspec, local, anycast, multicast } return
    ip daddr @local_ipv4 return
    ip6 daddr @local_ipv6 return
    udp dport { 123 } return
    meta l4proto { tcp, udp } meta mark set 1 tproxy to :7896 accept
  }

  chain singbox-mark {
    fib daddr type { unspec, local, anycast, multicast } return
    ip daddr @local_ipv4 return
    ip6 daddr @local_ipv6 return
    udp dport { 123 } return
    meta mark set 1
  }

  chain mangle-output {
    type route hook output priority mangle; policy accept;
    meta l4proto { tcp, udp } skgid != 1 ct direction original goto singbox-mark
  }

  chain mangle-prerouting {
    type filter hook prerouting priority mangle; policy accept;
    iifname { wg0, lo, $selected_interface } meta l4proto { tcp, udp } ct direction original goto singbox-tproxy
  }
}
EOF
    echo "nftables规则写入完成"
    if [[ "$SYSTEM_RELEASE" == "alpine" ]]; then
    cp /etc/nftables.nft /etc/nftables.nft.bak
    mv /etc/nftables.conf /etc/nftables.nft
    fi
    install_over
}
################################sing-box安装结束################################
install_over() {
    echo "启用相关服务"
    if [[ "$SYSTEM_RELEASE" == "alpine" ]]; then
   rc-update add sing-box-route && rc-service sing-box-route start
   rc-update add sing-box && rc-service sing-box start
   nft flush ruleset && nft -f /etc/nftables.nft && rc-service nftables restart && rc-update add nftables 
   else
    nft flush ruleset && nft -f /etc/nftables.conf && systemctl enable --now nftables && systemctl enable --now sing-box-router && systemctl enable --now sing-box
    fi
}

#####################################获取网卡################################
check_interfaces() {
    interfaces=$(ip -o link show | awk -F': ' '{print $2}')
    # 输出物理网卡名称
    for interface in $interfaces; do
        # 检查是否为物理网卡（不包含虚拟、回环等），并排除@符号及其后面的内容
        if [[ $interface =~ ^(en|eth).* ]]; then
            interface_name=$(echo "$interface" | awk -F'@' '{print $1}')  # 去掉@符号及其后面的内容
            echo "您的网卡是：$interface_name"
            valid_interfaces+=("$interface_name")  # 存储有效的网卡名称
        fi
    done
    # 提示用户选择
    read -p "脚本自行检测的是否是您要的网卡？(y/n): " confirm_interface
    if [ "$confirm_interface" = "y" ]; then
        selected_interface="$interface_name"
        echo "您选择的网卡是: $selected_interface"
    elif [ "$confirm_interface" = "n" ]; then
        read -p "请自行输入您的网卡名称: " selected_interface
        echo "您输入的网卡名称是: $selected_interface"
    else
        echo "无效的选择"
    fi
}


################################sing-box安装结束################################
install_sing_box_over() {
echo "=================================================================="
echo -e "\t\t\tSing-Box 安装完毕"
echo -e "\t\t\tPowered by www.herozmy.com 2024"
echo -e "\n"
echo -e "singbox运行目录为/etc/sing-box"
echo -e "singbox WebUI地址:http://ip:9090"
echo -e "Mosdns配置脚本：wget https://raw.githubusercontent.com/52shell/sing-box-mosdns-fakeip/main/mosdns-o.sh && bash mosdns-o.sh"
echo -e "温馨提示:\n本脚本仅在 LXC ubuntu22.04 环境下测试，其他环境未经验证，仅供个人使用"
echo -e "本脚本仅适用于学习与研究等个人用途，请勿用于任何违反国家法律的活动！"
echo "=================================================================="
}
main() {
check_os
    # install_singbox
    customize_settings
    install_service
    install_tproxy
    install_sing_box_over
}
main