#!/bin/bash


# 定义全局颜色变量
green_text="\033[32m"
yellow="\033[33m"
reset="\033[0m"
sub_host="https://sub-singbox.herozmy.com"
json_file="&file=https://raw.githubusercontent.com/herozmy/sing-box-mosdns-fakeip/main/config/fake-ip.json"
main(){
echo -e "1. TProxy Sing-Box | Mihomo Fake-ip <官方内核|喵佬P核|曦灵X核|Mihomo内核>"
echo -e "2. Mosdns Fake-ip分流"
echo -e "3. 卸载 Sing-Box | Mihomo | Mosdns"
echo -e "请选择:"
read choice
case $choice in
    1) 
        choose_singbox  # 先选择核心类型
        ;;
    2) 
        install_mosdns
        install_mosdns_config
        ;;
    3) 
        uninstall_all
        ;;
    *)
        echo "无效的选项，请重新运行脚本并选择有效的选项."
    ;;
esac

}
# 修改架构检测函数为最新标准
detect_architecture() {
    case $(uname -m) in
        x86_64)     echo "amd64" ;;
        aarch64)    echo "arm64" ;;
        armv7l)     echo "armv7" ;;
        armhf)      echo "armhf" ;;
        s390x)      echo "s390x" ;;
        i386|i686)  echo "386" ;;
        *)
            echo -e "${yellow}不支持的CPU架构: $(uname -m)${reset}"
            exit 1
            ;;
    esac
}



check_singbox(){

    # 统一检测所有可能的核心服务
    if [[ -f /usr/local/bin/mihomo ]] || 
       [[ -f /usr/local/bin/sing-box ]]; then
        echo -e "${green_text}[信息] 核心已安装，请选择是否升级${reset}"
        echo -e "${yellow}1. 升级${reset}"
        echo -e "${yellow}2. 跳过${reset}"
        read -p "请输入选择 (1/2): " choice
        case "$choice" in
            1)
                echo -e "${yellow}开始升级核心...${reset}"
                # 检测已安装的核心类型
            if [[ "$core_choice" == "4" ]]; then
                if [[ -f /usr/local/bin/mihomo ]]; then
                    echo -e "${green_text}检测到已安装Mihomo核心，开始升级...${reset}"
                    mihomo_install
                    mv mihomo /usr/local/bin/mihomo
                    chmod +x /usr/local/bin/mihomo
                    echo -e "${green_text}Mihomo 升级完成${reset}"
                    exit 0
                fi
            fi
                if [[ -f /usr/local/bin/sing-box ]]; then
                    echo -e "${green_text}检测到已安装Sing-Box核心，开始升级...${reset}"
                    # 无法自动判断时让用户选择
                    echo -e "${yellow}无法自动识别核心版本，请手动选择：${reset}"
                    echo -e "1. 官方核心\n2. Puer喵佬核心\n3. 曦灵X核心"
                    read -p "请输入选择 (1/2/3): " core_choice
                    case "$core_choice" in
                        1) 
                        choose_install_singbox
                        ;;
                        2) 
                        singbox_p_install
                        mv sing-box /usr/local/bin/ || { echo "移动 sing-box 失败！"; exit 1; }
                        chmod +x /usr/local/bin/sing-box 
                        echo -e "${green_text}Puer喵佬核心升级完成${reset}"
                        exit 0
                        ;;
                        3) 
                        singbox_x_install
                        mv sing-box /usr/local/bin/ || { echo "移动 sing-box 失败！"; exit 1; }
                        chmod +x /usr/local/bin/sing-box 
                        echo -e "${green_text}曦灵X核心升级完成${reset}"
                        exit 0
                        ;;
                        *) 
                            echo -e "${yellow}无效选择，退出脚本${reset}"
                            exit 1
                            ;;
                    esac
                fi  # 新增的
            
                ;;
            2)
                echo -e "${yellow}已跳过升级${reset}"
                exit 1
                ;;
        esac  # 新增的esac闭合
    else
        echo -e "${yellow}[信息] 开始安装核心...${reset}"
          # 调用安装函数
    fi
}
update_version(){

        apt update && apt -y upgrade || { 
            echo "更新失败！退出脚本"; 
            exit 1; 
        }
        apt -y install curl git gawk build-essential libssl-dev libevent-dev zlib1g-dev gcc-mingw-w64 nftables || { 
            echo "软件包安装失败！退出脚本"; 
            exit 1; 
        }
        echo -e "\n设置时区为Asia/Shanghai"
        timedatectl set-timezone Asia/Shanghai || { 
            echo -e "\e[31m时区设置失败！退出脚本\e[0m"; 
            exit 1; 
        }
        echo -e "\e[32m时区设置成功\e[0m"
  

}
check_enter(){

    if [[ "$core_choice" == "1" ]]; then
        export core_service="sing-box"
        update_version
        singbox_install_make
        cp "$(go env GOPATH)/bin/sing-box" /usr/local/bin/ || { echo "复制文件失败！退出脚本"; exit 1; }
        chmod +x /usr/local/bin/sing-box
        echo -e "${green_text}Sing-Box 安装完成${reset}"
    elif [[ "$core_choice" == "2" ]]; then
        export core_service="sing-box"
        update_version
        singbox_p_install
        mv sing-box /usr/local/bin/sing-box || { echo "移动 sing-box 失败！"; exit 1; }
        chmod +x /usr/local/bin/sing-box
        echo -e "${green_text}Puer喵佬核心安装完成${reset}"
    elif [[ "$core_choice" == "3" ]]; then
        export core_service="sing-box"
        update_version
        singbox_x_install       
        mv sing-box /usr/local/bin/sing-box || { echo "移动 sing-box 失败！"; exit 1; }
        chmod +x /usr/local/bin/sing-box
        echo -e "${green_text}曦灵X核心安装完成${reset}"
        
    elif [[ "$core_choice" == "4" ]]; then
        export core_service="mihomo"
        update_version
        mihomo_install
        mv mihomo /usr/local/bin/mihomo
        chmod +x /usr/local/bin/mihomo
        echo -e "${green_text}Mihomo 安装完成${reset}"
    else
        echo "无效的选择，退出脚本"
        exit 1
    fi

}
singbox_install_make(){
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
    arch=$(detect_architecture)
    echo "系统架构是：$arch"
    wget -O ${Go_Version}.linux-$arch.tar.gz https://go.dev/dl/${Go_Version}.linux-$arch.tar.gz || { 
        echo "下载 Go 版本失败！退出脚本"; 
        exit 1; 
    }
    tar -C /usr/local -xzf ${Go_Version}.linux-$arch.tar.gz || { 
        echo "解压 Go 文件失败！退出脚本"; 
        exit 1; 
    }
    rm -f ${Go_Version}.linux-$arch.tar.gz  # 清理下载的文件

    # 设置 Go 环境变量
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/golang.sh
    source /etc/profile.d/golang.sh  # 立即生效

    # 编译 Sing-Box
    if ! go install -v -tags with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme github.com/sagernet/sing-box/cmd/sing-box@latest; then
        echo -e "Sing-Box 编译失败！退出脚本"
        exit 1
    fi
    echo -e "编译完成"
    sleep 1
}

singbox_install_core(){
    set -e -o pipefail
    # 替换原有架构判断
    arch=$(detect_architecture)
    
    VERSION=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | grep tag_name | cut -d ":" -f2 | sed 's/[\",v ]//g')
    curl -Lo sing-box.tar.gz "https://github.com/SagerNet/sing-box/releases/download/v${VERSION}/sing-box-${VERSION}-linux-${arch}.tar.gz"
    tar -zxvf sing-box.tar.gz
    cd sing-box-${VERSION}-linux-${arch} || { echo "进入解压目录失败！"; exit 1; }
    mv sing-box ../ || { echo "移动 sing-box 失败！"; exit 1; }
    cd ..
    rm -rf sing-box-${VERSION}-linux-${arch} sing-box.tar.gz
    rm -rf sing-box.tar.gz
}

mihomo_install(){
    arch=$(detect_architecture)
    download_url="https://github.com/herozmy/StoreHouse/releases/download/mihomo/mihomo-meta-linux-${arch}.tar.gz
"
    echo -e "${yellow}开始下载Mihomo核心...${reset}"
    if ! wget -O mihomo.tar.gz $download_url; then
        echo -e "${yellow}下载失败，请检查网络连接${reset}"
        exit 1
    fi
    
    echo -e "${green_text}下载完成，开始安装${reset}"
    tar -zxvf mihomo.tar.gz
    rm -f mihomo.tar.gz
}

choose_install_singbox(){
   
    echo -e "请选择${green_text}程序${reset}"
    echo -e "${yellow}1. Sing-box编译安装${reset}"
    echo -e "${yellow}2. Sing-box二进制安装${reset}"
    echo -e "${yellow}0. 返回主菜单${reset}"
    read -p "请输入选择 (1/2/0): " choice
    case "$choice" in
        1)
            echo -e "当前选择: ${green_text}Sing-BOX${reset}编译安装"              
            if [[ -f /usr/local/bin/sing-box ]]; then            
            singbox_install_make
            cp "$(go env GOPATH)/bin/sing-box" /usr/local/bin/ || { echo "复制文件失败！退出脚本"; exit 1; }
            chmod +x /usr/local/bin/sing-box 
            echo -e "${green_text}Sing-Box 升级编译完成${reset}"
            exit 0
            else
            export core_service="sing-box"
            update_version
            singbox_install_make
            cp "$(go env GOPATH)/bin/sing-box" /usr/local/bin/ || { echo "复制文件失败！退出脚本"; exit 1; }
            chmod +x /usr/local/bin/sing-box 
            echo -e "${green_text}Sing-Box 编译安装完成${reset}"
            fi  
            ;;
        2)
            echo -e "当前选择: ${green_text} Sing-BOX ${reset}二进制安装"
            export core_service="sing-box"
            if [[ -f /usr/local/bin/sing-box ]]; then  
            singbox_install_core
            mv sing-box /usr/local/bin/ || { echo "复制文件失败！退出脚本"; exit 1; }
            chmod +x /usr/local/bin/sing-box
            echo -e "${green_text}Sing-Box 升级二进制安装完成${reset}"
            exit 0
            else
            update_version
            singbox_install_core
            mv sing-box /usr/local/bin/ || { echo "复制文件失败！退出脚本"; exit 1; }
            chmod +x /usr/local/bin/sing-box
            echo -e "${green_text}Sing-Box 二进制安装完成${reset}"
            fi
            ;;
        0)
            main
            ;;
        *)
            echo -e "无效选择，退出脚本"
            exit 1
            ;;
    esac
}



# 修改二进制安装函数
singbox_p_install(){
    arch=$(detect_architecture)
    download_url="https://github.com/herozmy/StoreHouse/releases/download/sing-box/sing-box-puernya-linux-${arch}.tar.gz"

    echo -e "${yellow}开始下载Puer喵佬核心...${reset}"
    if ! wget -O sing-box.tar.gz $download_url; then
        echo -e "${yellow}下载失败，请检查网络连接${reset}"
        exit 1
    fi
    
    echo -e "${green_text}下载完成，开始安装${reset}"
    tar -zxvf sing-box.tar.gz
    rm -f sing-box.tar.gz
}

# 完善曦灵X核心安装函数
singbox_x_install(){
    arch=$(detect_architecture)
    download_url="https://github.com/herozmy/StoreHouse/releases/download/sing-box-x/sing-box-x.tar.gz"

    echo -e "${yellow}开始下载曦灵X核心...${reset}"
    if ! wget -O sing-box.tar.gz $download_url; then
        echo -e "${yellow}下载失败，请检查网络连接${reset}"
        exit 1
    fi
    
    echo -e "${green_text}下载完成，开始安装${reset}"
    tar -zxvf sing-box.tar.gz
    mv sing-box_linux_amd64 sing-box

    rm -f sing-box.tar.gz
}

### 自定义设置
customize_settings() {
    local retry_count=0
    local max_retries=3
    local suburl=""
    
    while [ $retry_count -lt $max_retries ]; do
        # 获取订阅地址
        get_subscription_url  # 新增函数处理订阅地址输入
        
        # 生成配置文件
        generate_config  # 新增配置文件生成函数
        
        # 验证配置文件
        if check_config; then
            return 0
        else
            retry_count=$((retry_count+1))
            remaining=$((max_retries - retry_count))
            echo -e "${yellow}剩余尝试次数: ${remaining}${reset}"
        fi
    done
    
    echo -e "${red}连续3次生成配置文件失败，请检查订阅地址有效性${reset}"
    exit 1
}

# 新增订阅地址获取函数
get_subscription_url() {
    echo -e "是否选择生成配置？(y/n) ${green_text}生成配置文件需要添加机场订阅，如自建vps请选择n${reset}"
    read choice
    if [ "$choice" = "y" ]; then
        read -p "输入订阅连接：" suburl
        suburl="${suburl:-https://}"
        echo "已设置订阅连接地址：$suburl"
    else
        echo "请手动编写config配置文件,默认模版仓库地址：https://github.com/herozmy/StoreHouse/tree/main/config"
        exit 0
    fi
    check_interfaces
}

# 新增配置文件生成函数
generate_config() {
    echo -e "${yellow}正在生成配置文件...${reset}"
    curl -o config.json "${sub_host}/config/${suburl}${json_file}" || {
        echo -e "${red}配置文件下载失败${reset}"
        return 1
    }
}

# 修改后的配置检查函数
check_config() {
    local config_file="config.json"
    
    if [ ! -f "$config_file" ]; then
        echo -e "${red}配置文件不存在${reset}"
        return 1
    fi

    line_count=$(wc -l < "$config_file")
    
    if [ "$line_count" -gt 10 ]; then
        echo -e "${green}配置文件检测通过 (${line_count}行)${reset}"
       # return 0
    else
        echo -e "${red}配置文件不完整 (仅${line_count}行)${reset}"
        return 1
    fi
}

### 安装配置文件
install_josn_config(){
###官方内核配置文件
    if [[ "$core_choice" == "1" ]]; then
        customize_settings  
        mkdir -p /etc/sing-box
        mv config.json /etc/sing-box/config.json || {
            echo -e "${red}配置文件移动失败${reset}"
            exit 1
        }
        echo -e "${green_text}Sing-box配置文件写入成功！${reset}"
###Puer喵佬核心配置文件
    elif [[ "$core_choice" == "2" ]]; then
        get_subscription_url
        mkdir -p /etc/sing-box
        mkdir -p /etc/sing-box/providers
        mkdir -p /etc/sing-box/rule
        if curl -o /etc/sing-box/config.json https://d.herozmy.com/public/Routing/Config/sing-box/sing-box-p-fakeip.json; then
            echo -e "${green_text} 配置文件下载成功${reset}"
            sed -i "s|\"download_url\": \"机场订阅\"|\"download_url\": \"$suburl\"|g" /etc/sing-box/config.json
        else
            echo -e "${red}配置文件下载失败${reset}"
            exit 1
        fi
        wget -O /etc/sing-box/p_rule.tar.gz https://github.com/herozmy/StoreHouse/releases/download/rule/p_rule.tar.gz
        tar --strip-components=1 -zxvf /etc/sing-box/p_rule.tar.gz -C /etc/sing-box/rule
        rm -f /etc/sing-box/p_rule.tar.gz
###曦灵X核心配置文件
    elif [[ "$core_choice" == "3" ]]; then
        get_subscription_url
        mkdir -p /etc/sing-box
        if curl -o /etc/sing-box/config.json https://d.herozmy.com/public/Routing/Config/sing-box/sing-box-x-fakeip.json; then
            echo -e "${green_text} 配置文件下载成功${reset}"
            sed -i "s|\"download_url\": \"机场订阅\"|\"download_url\": \"$suburl\"|g" /etc/sing-box/config.json
        else
            echo -e "${red}配置文件下载失败${reset}"
            exit 1
        fi
###Mihomo核心配置文件
    elif [[ "$core_choice" == "4" ]]; then
        get_subscription_url
        mkdir -p /etc/mihomo
        wget -O /etc/mihomo/config.yaml https://github.com/herozmy/sing-box-mosdns-fakeip/raw/refs/heads/main/config/clash-fake-ip.yaml
        sed -i "s|url: '机场订阅'|url: '$suburl'|" /etc/mihomo/config.yaml
        sed -i "s|interface-name: eth0|interface-name: $interface_name|" /etc/mihomo/config.yaml
    fi

}

check_resolved(){
    if [ -f /etc/systemd/resolved.conf ]; then
        # 检测是否有未注释的 DNSStubListener 行
        dns_stub_listener=$(grep "^DNSStubListener=" /etc/systemd/resolved.conf)
        if [ -z "$dns_stub_listener" ]; then
            # 如果没有找到未注释的 DNSStubListener 行，检查是否有被注释的 DNSStubListener
            commented_dns_stub_listener=$(grep "^#DNSStubListener=" /etc/systemd/resolved.conf)
            if [ -n "$commented_dns_stub_listener" ]; then
                # 如果找到被注释的 DNSStubListener，取消注释并改为 no
                sed -i 's/^#DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
                systemctl restart systemd-resolved.service
                green "53端口占用已解除"
            else
                green "未找到53端口占用配置，无需操作"
            fi
        elif [ "$dns_stub_listener" = "DNSStubListener=yes" ]; then
            # 如果找到 DNSStubListener=yes，则修改为 no
            sed -i 's/^DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
            systemctl restart systemd-resolved.service
            green "53端口占用已解除"
        elif [ "$dns_stub_listener" = "DNSStubListener=no" ]; then
            # 如果 DNSStubListener 已为 no，提示用户无需修改
            echo -e "${yellow}53端口未被占用，无需操作${reset}"
        fi
    else
        echo -e "${yellow} /etc/systemd/resolved.conf 不存在，无需操作${reset}"
    fi

}

#####sing-box自启动脚本

install_core_service(){
    check_resolved
    sleep 1
    echo -e "配置系统服务文件"
    sleep 1
    core_service_file="/etc/systemd/system/${core_service}.service"
cat << EOF > "$core_service_file"
[Unit]
Description=$core_service service

[Service]
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
ExecStart=/usr/local/bin/${core_service} run -c /etc/${core_service}/config.json
Restart=on-failure
RestartSec=1800s
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF
    if [ "$core_service" = "mihomo" ]; then
        sed -i '/CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE/,/LimitNOFILE=infinity/c\Type=simple\nExecStart=/usr/local/bin/mihomo -d /etc/mihomo/' "$core_service_file"
    
    fi
    echo "${core_service} 服务创建完成"
    systemctl daemon-reload
    systemctl enable ${core_service}
}
install_singbox_tproxy(){
    echo -e "配置tproxy"
    sleep 1
    echo "创建系统转发"
# 判断是否已存在 net.ipv4.ip_forward=1
    if ! grep -q '^net.ipv4.ip_forward=1$' /etc/sysctl.conf; then
        echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    fi

# 判断是否已存在 net.ipv6.conf.all.forwarding = 1
    if ! grep -q '^net.ipv6.conf.all.forwarding = 1$' /etc/sysctl.conf; then
        echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.conf
    fi
    sleep 1
    echo "系统转发创建完成"
    # 写入tproxy rule  
    echo "写入路由 rule"
        cat <<EOF > "/etc/systemd/system/${core_service}-router.service"
[Unit]
Description=${core_service} TProxy Rules
After=network.target
Wants=network.target

[Service]
User=root
Type=oneshot
RemainAfterExit=yes
# there must be spaces before and after semicolons
ExecStart=/sbin/ip rule add fwmark 1 table 100 ; /sbin/ip route add local default dev lo table 100 ; /sbin/ip -6 rule add fwmark 1 table 101 ; /sbin/ip -6 route add local ::/0 dev lo table 101
ExecStop=/sbin/ip rule del fwmark 1 table 100 ; /sbin/ip route del local default dev lo table 100 ; /sbin/ip -6 rule del fwmark 1 table 101 ; /sbin/ip -6 route del local ::/0 dev lo table 101

[Install]
WantedBy=multi-user.target
EOF
echo -e "${green_text}${core_service}-router 服务创建完成"
####写入nftables
echo "" > "/etc/nftables.conf"
cat <<EOF > "/etc/nftables.conf"
#!/usr/sbin/nft -f
flush ruleset
table inet $selected_option {
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

  chain ${selected_option}-tproxy {
    fib daddr type { unspec, local, anycast, multicast } return
    ip daddr @local_ipv4 return
    ip6 daddr @local_ipv6 return
    udp dport { 123 } return
    meta l4proto { tcp, udp } meta mark set 1 tproxy to :7896 accept
  }

  chain ${selected_option}-mark {
    fib daddr type { unspec, local, anycast, multicast } return
    ip daddr @local_ipv4 return
    ip6 daddr @local_ipv6 return
    udp dport { 123 } return
    meta mark set 1
  }

  chain mangle-output {
    type route hook output priority mangle; policy accept;
    meta l4proto { tcp, udp } skgid != 1 ct direction original goto ${selected_option}-mark
  }

  chain mangle-prerouting {
    type filter hook prerouting priority mangle; policy accept;
    iifname { wg0, lo, $interface_name } meta l4proto { tcp, udp } ct direction original goto ${selected_option}-tproxy
  }
}
EOF
    echo -e "${green_text}nftables规则写入完成${reset}"

}
###检测ui是否存在
check_ui(){
    found_files=$(find /usr/local/bin/ -type f \( -name "mihomo" -o -name "sing-box" \))
    if [ -n "$found_files" ]; then
    for file in $found_files; do
        filename=$(basename "$file")
    done
    fi  
    if [ -d "/etc/${filename}/ui" ]; then
        echo "更新 WEBUI..."
        rm -rf /etc/${filename}/ui
        git_ui
    else
        git_ui
    fi
}
git_ui(){
    if git clone https://github.com/metacubex/metacubexd.git -b gh-pages /etc/${filename}/ui; then
        echo -e "UI 源码拉取${green_text}成功${reset}。"
    else
        echo "拉取源码失败，请手动下载源码并解压至 /etc/${filename}/ui."
        echo "地址: https://github.com/metacubex/metacubexd"
    fi
}



check_interfaces() {
    interfaces=$(ip -o link show | awk -F': ' '{print $2}')
    # 输出物理网卡名称
    for interface in $interfaces; do
        # 检查是否为物理网卡（不包含虚拟、回环等），并排除@符号及其后面的内容
        if [[ $interface =~ ^(en|eth).* ]]; then
            interface_name=$(echo "$interface" | awk -F'@' '{print $1}')  # 去掉@符号及其后面的内容
            echo -e "您的网卡是：${yellow}$interface_name${reset}"
            valid_interfaces+=("$interface_name")  # 存储有效的网卡名称
        fi
    done
    # 提示用户选择
    
    #read -p "脚本自行检测的是否是您要的网卡？(y/n): " confirm_interface
    #if [ "$confirm_interface" = "y" ]; then
        #selected_interface="$interface_name"
        #echo -e "您选择的网卡是: ${green_text}$selected_interface${reset}"
    #elif [ "$confirm_interface" = "n" ]; then
        #read -p "请自行输入您的网卡名称: " selected_interface
        #echo -e "您输入的网卡名称是: ${green_text}$selected_interface${reset}"
    #else
        #echo "无效的选择"
    #fi
}

install_over() {
    echo -e "${green_text}启用相关服务${reset}"
    systemctl enable --now ${core_service} 
    sleep 2
    systemctl enable --now ${core_service}-router
    nft flush ruleset
    nft -f /etc/nftables.conf
    systemctl enable --now nftables
echo "=================================================================="
echo -e "\t\t\t${core_service} 安装完毕"
echo -e "\t\t\tPowered by www.herozmy.com 2025"
echo -e "\n"
echo -e "${core_service}运行目录为/etc/${core_service}"
echo -e "${core_service} WebUI地址:http://ip:9090"
echo -e "本脚本仅适用于学习与研究等个人用途，请勿用于任何违反国家法律的活动！"
echo "=================================================================="
    echo -e "${green_text}请使用${reset} ${yellow}systemctl start ${core_service}${reset} ${green_text}启动服务${reset}"
    echo -e "${green_text}请使用${reset} ${yellow}systemctl enable ${core_service}${reset} ${green_text}设置开机自启${reset}"
    echo -e "${green_text}请使用${reset} ${yellow}systemctl status ${core_service}${reset} ${green_text}查看服务状态${reset}"
    echo -e "${green_text}请使用${reset} ${yellow}systemctl restart ${core_service}${reset} ${green_text}重启服务${reset}"
    echo -e "${green_text}请使用${reset} ${yellow}systemctl stop ${core_service}${reset} ${green_text}停止服务${reset}"
    echo -e "${green_text}请使用${reset} ${yellow}systemctl disable ${core_service}${reset} ${green_text}禁用开机自启${reset}"
    echo -e "${green_text}请使用${reset} ${yellow}systemctl restart nftables${reset} ${green_text}重启nftables${reset}"
    echo -e "${green_text}请使用${reset} ${yellow}systemctl status nftables${reset} ${green_text}查看nftables状态${reset}"
    echo -e "${green_text}请使用${reset} ${yellow}systemctl restart ${core_service}-router${reset} ${green_text}重启路由${reset}"
    echo -e "${green_text}请使用${reset} ${yellow}systemctl status ${core_service}-router${reset} ${green_text}查看路由状态${reset}" 

}
choose_singbox(){
    echo -e "请选择${green_text}程序${reset}"
    echo -e "${yellow}1. Sing-box官核${reset}"
    echo -e "${yellow}2. Sing-boxPuer喵佬核心${reset}"
    echo -e "${yellow}3. Sing-box曦灵X核心${reset}"
    echo -e "${yellow}4. Mihomo核心${reset}"
    echo -e "${yellow}0. 返回主菜单${reset}"
    read -p "请输入选择 (1/2/3/4/5/0): " core_choice
  
    case "$core_choice" in
        1)
            echo -e "当前选择: ${green_text}Sing-BOX${reset}官方核心"        
            echo -e "请选择: ${green_text}Sing-BOX${reset}官方核心安装方式"  
            check_singbox
            choose_install_singbox
            install_josn_config
            install_core_service
            install_singbox_tproxy
            ;;
        2)
            echo -e "当前选择: ${green_text} Sing-BOX ${reset}Puer喵佬核心"
            check_singbox
            check_enter
            install_josn_config
            install_core_service
            install_singbox_tproxy
            ;;
        3)
            echo -e "当前选择: ${green_text}Sing-BOX${reset}曦灵X核心"
            check_singbox
            check_enter
            install_josn_config
            install_core_service
            install_singbox_tproxy
            ;;
        4)
            echo -e "当前选择: ${green_text}Mihomo${reset}核心"
            check_singbox
            check_enter
            install_josn_config
            install_core_service
            install_singbox_tproxy
            ;;
        0)
            main
            ;;
        *)
            echo -e "无效选择，退出脚本"
            exit 1
            ;;
    esac
}
###################################################################Mosdns

install_mosdns(){
    if [[ $(uname -m) == "aarch64" ]]; then
        arch="arm64"
    elif [[ $(uname -m) == "x86_64" ]]; then
        arch="amd64"
    else
        arch="未知"
        exit 0
    fi
    echo "系统架构是：$arch"
    mosdns_host="https://github.com/herozmy/StoreHouse/releases/download/mosdns/mosdns-linux-$arch.zip"
    apt update && apt -y upgrade || { echo "更新失败！退出脚本"; exit 1; }
    apt install curl wget git tar gawk sed cron unzip nano -y || { echo "更新失败！退出脚本"; exit 1; }
    echo -e "\n设置时区为Asia/Shanghai"
    timedatectl set-timezone Asia/Shanghai || { echo -e "\e[31m时区设置失败！退出脚本\e[0m"; exit 1; }
    echo -e "\e[32m时区设置成功\e[0m"
    echo -e "\n设置时区为Asia/Shanghai"
    wget "${mosdns_host}" || { echo -e "\e[31m下载失败！退出脚本\e[0m"; exit 1; }
    echo "开始解压"
    unzip ./mosdns-linux-$arch.zip 
    sleep 1
    mv -v ./mosdns /usr/local/bin/
    rm -rf mosdns-linux-$arch.zip
    chmod 0777 /usr/local/bin/mosdns 
}
install_mosdns_config(){   
    echo -e "\n自定义设置（以下设置可直接回车使用默认值）"
    read -p "输入sing-box/mihomo入站地址端口（默认10.10.10.147:6666）：" uiport
    uiport="${uiport:-10.10.10.147:6666}"
    echo -e "已设置sing-box/mihomo入站地址：\e[36m$uiport\e[0m"
    check_resolved
    echo "配置mosdns规则"
    sleep 1
    echo -e "请选择Mosdns规则"
    echo -e "
   分流规则:
  0. 退出脚本
————————————————
  1. O佬分流规则
  2. PH佬分流规则
 "
    rm -rf .git
    echo && read -p "请输入选择 [0-2]: " num
    case "${num}" in
    0)
        exit 0
        ;;
    1)
   (
    git init >/dev/null 2>&1 &&
    git remote add -f origin https://github.com/herozmy/sing-box-mosdns-fakeip.git &&
    git config core.sparsecheckout true &&
    echo 'mosdns' > .git/info/sparse-checkout &&
    git pull origin main
   )
        ;;
    2)
 (
    git init >/dev/null 2>&1 &&
    git remote add -f origin https://github.com/herozmy/sing-box-mosdns-fakeip.git &&
    git config core.sparsecheckout true &&
    echo 'mosdns-ph' > .git/info/sparse-checkout &&
    git pull origin main
    mv mosdns-ph mosdns
)
        ;;
    *)
        echo "请输入正确的数字 [0-2]"
        ;;
    esac

if [ $? -ne 0 ]; then
    echo "拉取失败，请重新拉取"
    exit 1
fi
    echo -e "${green_text}Mosdns规则拉取成功${reset}"
    cd /root && mv mosdns /etc/
    echo "配置mosdns"
    sed -i "s/- addr: 10.10.10.147:6666/- addr: ${uiport}/g" /etc/mosdns/config.yaml
    echo "设置mosdns开机自启动"
    mosdns service install -d /etc/mosdns -c /etc/mosdns/config.yaml
    echo "mosdns开机启动完成"
    sleep 1
    systemctl restart mosdns

}

uninstall_all(){
    echo -e "卸载Sing-Box | Mihomo | Mosdns"
    found_files=$(find /usr/local/bin/ -type f \( -name "mihomo" -o -name "sing-box" -o -name "mosdns" \))
    if [ -z "$found_files" ]; then
        echo -e "${yellow}[检测结果] 未找到任何已安装的核心程序${reset}"
        return 0
    fi
    echo -e "${yellow}检测到已安装以下核心：${reset}"
    for file in $found_files; do
        echo -e "  ${green}$(basename $file)${reset}"
    done
    # 确认卸载
    read -p "是否继续卸载？(y/n) " confirm
    [[ $confirm != "y" ]] && return 0
    # 执行卸载操作
    for file in $found_files; do
        filename=$(basename "$file")
    if [ "${filename}" == "mosdns" ]; then
        systemctl disable mosdns
        systemctl stop mosdns
        rm -rf /etc/mosdns
        rm -rf /usr/local/bin/mosdns
        rm -rf /etc/systemd/system/mosdns.service
    elif [ "${filename}" == "sing-box" ]; then
        systemctl disable ${filename}
        systemctl stop ${filename}
        systemctl disable ${filename}-router
        systemctl stop ${filename}-router
        echo " " > "/etc/nftables.conf"
        nft flush ruleset
        nft -f /etc/nftables.conf 
        rm -rf /etc/sing-box
        rm -rf /usr/local/bin/sing-box
        rm -rf /etc/systemd/system/${filename}.service
        rm -rf /etc/systemd/system/${filename}-router.service
    elif [ "${filename}" == "mihomo" ]; then
        systemctl disable ${filename}
        systemctl stop ${filename}
        systemctl disable ${filename}-router
        systemctl stop ${filename}-router
        echo " " > "/etc/nftables.conf"
        nft flush ruleset
        nft -f /etc/nftables.conf 
        rm -rf /etc/mihomo
        rm -rf /usr/local/bin/mihomo
        rm -rf /etc/systemd/system/${filename}.service
        rm -rf /etc/systemd/system/${filename}-router.service

    fi
    done
    echo "卸载完成"
}
main