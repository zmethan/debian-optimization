整合了 Debian 12 优化、ZRAM 配置 和 Swap 配置 的 Bash 脚本，带有交互界面，并支持以下功能：
* 优化前自动备份系统配置。
* 用户主动触发备份。
* 恢复到优化前的初始配置。
* 提供简单的交互选项。


## 下载脚本
```
wget -O debian_optimization.sh "https://github.com/zmethan/debian-optimization/raw/main/debian_optimization.sh" && chmod +x debian_optimization.sh && ./debian_optimization.sh
```

##功能说明
1. 备份：
* 自动备份 /etc/fstab 和 /etc/default/zram-config 文件。
* Swap 文件的状态也会在恢复时自动重置。

2.恢复：
* 将系统配置恢复到优化前的状态（包括 Swap 和 ZRAM 配置）。

3.交互界面：
* 提供菜单式选择，可单独执行某些优化任务或一键全部优化。

4.Swap 和 ZRAM 配置：
* 默认创建 1GB 的 Swap 文件。
* 启用 ZRAM，占用 50% 内存，使用高效的 zstd 压缩算法。

5. 服务优化：
* 禁用常见的非必要服务，如蓝牙、打印机、ModemManager 等。

* 
