#!/usr/bin/env bash

# 1.适用于使用iso安装的纯净系统
# 2.iso安装过程中会创建用户，脚本默认安装时创建的用户为**********，而不会创建新用户
# 3.server版本安装后需要手动配置静态ip，修改 /etc/netplan/ 中配置，配置模板在文件最后,其中注意 1.手动修改网卡号 2.renderer: networkd
# 4.desktop版本安装后需要手动配置静态ip，在gui界面中配置修改
# server 和 desktop 的网络管理程序区别：
# https://www.configserverfirewall.com/ubuntu-linux/ubuntu-network-manager/
# sudo systemctl status systemd-networkd    # server  默认使用 systemd-networkd
# sudo systemctl status NetworkManager      # desktop 默认使用 NetworkManager

# for ubuntu18,need to run as root
# exit

# exit on first error
set -e

# config para
comment='# by initServ'
username='**********'
servername='**********.local'
sshport='22'
pubkey='ssh-rsa **********'

# print color string in shell
red_prefix="\033[31m"
green_prefix="\033[1;32m"
color_suffix="\033[0m"
info="[${green_prefix}INFO${color_suffix}]"
error="[${red_prefix}ERROR${color_suffix}]"

# add user
# pls confirm there already have a user **********!
addUser(){
    echo -e "${info} func addUser()"
    # echo -e "${info} change root passwd first!"
    # passwd root
    # echo -e "${info} add user ${username}"
    # adduser ${username}
    # usermod -aG sudo ${username}
    # groups ${username} root
    edit="${username} ALL=(ALL:ALL) NOPASSWD:ALL"
    # edit with comment
    # sed -i -e "\$a${comment}\n${edit}" /etc/sudoers
    sed -i -e "\$a${edit}" /etc/sudoers
    echo -e "${info} func addUser() done!"
}

# config timezone and servername and language
confInfo(){
    echo -e "${info} func confInfo()"
    timedatectl set-timezone Asia/Shanghai
    date -R
    hostnamectl set-hostname "${servername}"
    hostnamectl status
    sed -i -e "1i\127.0.0.1\t${servername}" /etc/hosts
    # the /etc/default/locale file may not contain the para
    # if so,the s cmd in sed may not work well
    # so 1.del the para 2.add the para
    # sed -i \
    # -e "/LANG=/d" \
    # -e "/LANGUAGE=/d" \
    # -e "/LC_ALL=/d" \
    # /etc/default/locale
    # echo "${comment}" >> /etc/default/locale
    # sed -i \
    # -e "\$aLANG=\"en_US.utf8\"" \
    # -e "\$aLANGUAGE=\"en_US.utf8"\" \
    # -e "\$aLC_ALL=\"en_US.utf8\"" \
    # /etc/default/locale
    cat > /etc/default/locale << "EOF"
LANG="en_US.utf8"
LANGUAGE="en_US.utf8"
LC_ALL="en_US.utf8"
EOF
    echo -e "${info} func confInfo() done!"
}

# conf ssh port and pubkey
confSSH(){
    echo -e "${info} func confSSH()"
    mkdir -p /home/${username}/.ssh
    echo "${pubkey}" > /home/${username}/.ssh/authorized_keys
    chmod 600 /home/${username}/.ssh/authorized_keys
    chmod 700 /home/${username}/.ssh
    chown -R ${username}:${username} /home/${username}/.ssh
    # sed -i.bkup -E \
    # -e "s/^#?Port .*/Port ${sshport}/" \
    # -e "s/^#?PubkeyAuthentication .*/PubkeyAuthentication yes/" \
    # -e "s/^#?PasswordAuthentication .*/PasswordAuthentication no/" \
    # -e "s/^#?PermitEmptyPasswords .*/PermitEmptyPasswords no/" \
    # /etc/ssh/sshd_config
    # diff /etc/ssh/sshd_config /etc/ssh/sshd_config.bkup
    # rm -rf /etc/ssh/sshd_config.bkup
    sed -i -E \
    -e "s/^#?Port .*/Port ${sshport}/" \
    -e "s/^#?PubkeyAuthentication .*/PubkeyAuthentication yes/" \
    -e "s/^#?PasswordAuthentication .*/PasswordAuthentication no/" \
    -e "s/^#?PermitEmptyPasswords .*/PermitEmptyPasswords no/" \
    -e "s/^#?PermitRootLogin .*/PermitRootLogin no/" \
    /etc/ssh/sshd_config
    echo -e "${info} func confSSH() done!"
}

# install Util
insUtil(){
    echo -e "${info} func insUtil()"
    apt update
    apt install -y vim htop iftop curl wget git sl nmap socat dnsutils net-tools
    #apt install -y python3 python3-pip python python-pip
    echo -e "${info} func insUtil() done!"
}

insTmux(){
    echo -e "${info} func insTmux()"
    apt install -y tmux
    echo "set -g mouse on" > /home/${username}/.tmux.conf
    chown -R ${username}:${username} /home/${username}/.tmux.conf
    echo -e "${info} func insTmux() done!"
}

insScreenfetch(){
    echo -e "${info} func insScreenfetch()"
    apt install -y screenfetch
    cat > /etc/update-motd.d/99-screenfetch << "EOF"
#!/bin/sh
if [ -f /usr/bin/screenfetch ]; then screenfetch; fi
EOF
    chmod +x /etc/update-motd.d/99-screenfetch
    echo -e "${info} func insScreenfetch() done!"
}

insZsh(){
    echo -e "${info} func insZsh()"
    apt install -y zsh
# exec error,didn't know why
#     su - ${username} << "EOF"
# /bin/sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# EOF
    su - ${username} -s /bin/sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    su - ${username} -s /bin/sh -c "git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    sed -i -E \
    -e "s/^#? ?ZSH_THEME=.*/ZSH_THEME=\"bira\"/" \
    -e "s/^#? ?DISABLE_AUTO_TITLE=.*/DISABLE_AUTO_TITLE=\"true\"/" \
    -e "s/^#? ?plugins=.*/plugins=\(git zsh-autosuggestions\)/" \
    /home/${username}/.zshrc
    echo -e "${info} func insZsh() done!"
}

addUser
confInfo
confSSH
insUtil
insTmux
insScreenfetch
insZsh

# network:
#   version: 2
#   renderer: networkd
#   ethernets:
#     ens18:
#       dhcp4: false
#       addresses:
#       - **********/24
#       gateway4: **********.1
#       nameservers:
#         addresses:
#         - 223.5.5.5
#         - 8.8.8.8

# network:
#   version: 2
#   renderer: networkd
#   ethernets:
#     enp0s3:
#       dhcp4: yes

# sudo netplay apply

# dnsserver in /etc/resolv.conf
# https://stackoverflow.com/questions/61647017/netcat-throws-a-getnameinfo-temporary-failure-in-name-resolution-error