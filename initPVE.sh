#!/usr/bin/env bash

# 1.run this script
# 2.手动删除local-lvm：数据中心-存储-删除local-lvm
# 3.手动编辑local：内容里添加 磁盘映像和容器

# for PVE6.3,need to run as root
# exit

# exit on first error
set -e

# config para
comment='# by initPVE'
sshport='22'
pubkey='ssh-rsa **********'
mailName='z**********@163.com'
mailPwd='N**********M'

# print color string in shell
red_prefix="\033[31m"
green_prefix="\033[1;32m"
color_suffix="\033[0m"
info="[${green_prefix}INFO${color_suffix}]"
error="[${red_prefix}ERROR${color_suffix}]"

# config language and other things
confInfo(){
    echo -e "${info} func confInfo()"
    # config language
    cat > /etc/default/locale << "EOF"
LANG="en_US.utf8"
LANGUAGE="en_US.utf8"
LC_ALL="en_US.utf8"
EOF
    # disable apt pve-enterprise source
    sed -i -E \
    -e "s/^deb/#deb/" \
    /etc/apt/sources.list.d/pve-enterprise.list
    echo "deb http://download.proxmox.com/debian/pve buster pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list
    # disable subscribe notice in web
    sed -i \
    -e "s/if (res === null || res === undefined || \!res || res/if (false) {/g" \
    -e "s/.data.status.toLowerCase() !== 'active') {/ /" \
    /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
    # config lvm disk space,remove local-lvm then extend pve/root
    pvs
    vgs
    lvs
    lvremove pve/data
    lvextend -l +100%FREE -r pve/root
    lvs
    echo -e "${info} func confInfo() done!"
}

# conf ssh port and pubkey
confSSH(){
    echo -e "${info} func confSSH()"
    echo "${pubkey}" >> /root/.ssh/authorized_keys
    sed -i -E \
    -e "s/^#?Port .*/Port ${sshport}/" \
    -e "s/^#?PubkeyAuthentication .*/PubkeyAuthentication yes/" \
    -e "s/^#?PasswordAuthentication .*/PasswordAuthentication no/" \
    -e "s/^#?PermitEmptyPasswords .*/PermitEmptyPasswords no/" \
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

# install Mail
insMail(){
    echo -e "${info} func insMail()"
    apt install -y libsasl2-modules
    echo "[smtp.163.com]:465 ${mailName}:${mailPwd}" > /etc/postfix/sasl_passwd
    postmap hash:/etc/postfix/sasl_passwd
    chmod 600 /etc/postfix/sasl_passwd
    chmod 600 /etc/postfix/sasl_passwd.db
    echo "/From:.*/ REPLACE From: ${mailName}" > /etc/postfix/header_checks
    echo "/.+/ ${mailName}" > /etc/postfix/sender_canonical_maps
    sed -i -E \
    -e "s/^relayhost/#relayhost/" \
    /etc/postfix/main.cf
    cat >> /etc/postfix/main.cf << "EOF"
# relay smtp config
relayhost = [smtp.163.com]:465
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_security_options = noanonymous
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_tls_CAfile = /etc/ssl/certs/Entrust_Root_Certification_Authority.pem
smtp_tls_session_cache_database = btree:/var/lib/postfix/smtp_tls_session_cache
smtp_tls_session_cache_timeout = 3600s
smtp_tls_wrappermode = yes
smtp_tls_security_level = encrypt
# filter the from addr
sender_canonical_classes = envelope_sender, header_sender
sender_canonical_maps =  regexp:/etc/postfix/sender_canonical_maps
smtp_header_checks = regexp:/etc/postfix/header_checks
EOF
    systemctl restart postfix.service
    echo "" > /var/log/mail.log
    echo "initPVE : $(uname -a)" | mail -s "initPVE : $(uname -n)" "${mailName}"
    sleep 3
    cat /var/log/mail.log
    echo -e "${info} func insMail() done!"
}

insTmux(){
    echo -e "${info} func insTmux()"
    apt install -y tmux
    echo "set -g mouse on" > /root/.tmux.conf
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
    /bin/sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    sed -i -E \
    -e "s/^#? ?ZSH_THEME=.*/ZSH_THEME=\"bira\"/" \
    -e "s/^#? ?DISABLE_AUTO_TITLE=.*/DISABLE_AUTO_TITLE=\"true\"/" \
    -e "s/^#? ?plugins=.*/plugins=\(git zsh-autosuggestions\)/" \
    /root/.zshrc
    echo -e "${info} func insZsh() done!"
}

confInfo
confSSH
insUtil
insMail
insTmux
insScreenfetch
insZsh