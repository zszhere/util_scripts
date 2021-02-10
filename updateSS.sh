#!/bin/sh

#get public ip
ip_dns=$(ping -c 1 -w 3 -n **********.us 2>/dev/null|grep -m 1 -oE '(\d{1,3}\.){3}\d{1,3}')
#echo "$ip_dns"
#get ipset list
ip_set=$(ipset list ss_rules_dst_bypass_|grep -oE '(\d{1,3}\.){3}\d{1,3}')
#echo "$ip_set"
#is the str equal
res=$(echo "${ip_set}"|grep -oF "${ip_dns}")
#echo "$res"
if [ "${res}" == "" ]
then
    /etc/init.d/shadowsocks-libev restart
    echo "[+]update ss server ip : ${ip_dns}"
    echo "[+]ss restarted at $(date -R)"
# else
#     echo "[+]ss fine"
fi

#modify ss ipset to go to **********/24
res=$(ipset list ss_rules_dst_bypass_|grep -oF "**********/24 nomatch")
if [ "${res}" == "" ]
then
    ipset add ss_rules_dst_bypass_ **********/24 nomatch
    echo "[+]ipset modify at $(date -R)"
# else
#     echo "[+]ipset fine"
fi

# 加入 crontab 定时执行：
# root@OpenWrt:~# crontab -e
# */3 * * * * /root/updateSS.sh >> /tmp/updateSS.log 2>&1

# 检查 openwrt 的 cron 是否启动：
# ps -w|grep cron 查看是否有 cron 的进程

# 开启cron自动启动：
# /etc/init.d/cron enable
# /etc/init.d/cron start