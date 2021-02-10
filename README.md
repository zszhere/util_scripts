# initPVE

- 一键初始化配置VPE服务器
- 使用前需要配置config para中的字段
- 功能
  - 修改语言为en_US.utf8
  - 关闭企业源更新，添加社区源
  - 关闭登录时的未关注提醒
  - 合并lvm的磁盘空间
  - 配置ssh参数并添加公钥
  - 安装常用工具
  - 安装邮件提醒，使用163的smtp来发送，装好会发送给自己测试邮件
  - 安装配置tmux
  - 安装配置screenfetch
  - 安装配置ohmyzsh

# initServ

- 一键配置本地的ubuntu18
- 使用前需要配置config para中的字段
- 功能，基本同上，看注释

# initVPS

- 一键配置远程的ubuntu18
- 使用前需要配置config para中的字段
- 功能，基本同上，看注释

# updateSS

- 使用openwrt中的ss-redir制作了三层网络的VPN
- 解决ddns更新的问题，会重启ss-redir