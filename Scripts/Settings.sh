#!/bin/bash

#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_CI-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")
#修改默认WIFI名
sed -i "s/\.ssid=.*/\.ssid=$WRT_WIFI/g" $(find ./package/kernel/mac80211/ ./package/network/config/ -type f -name "mac80211.*")

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo "$WRT_PACKAGE" >> ./.config
fi

#高通平台调整
if [[ $WRT_TARGET == *"IPQ"* ]]; then
	#取消nss相关feed
	echo "CONFIG_FEED_nss_packages=n" >> ./.config
	echo "CONFIG_FEED_sqm_scripts_nss=n" >> ./.config
fi

#######################################
#DIY
#######################################
WRT_IP="192.168.1.1"
WRT_NAME="FWRT"
WRT_WIFI="FWRT"
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#修改默认WIFI名
sed -i "s/\.ssid=.*/\.ssid=$WRT_WIFI/g" $(find ./package/kernel/mac80211/ ./package/network/config/ -type f -name "mac80211.*")

#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

keywords_to_delete=(
    "xiaomi_ax3600" "xiaomi_ax9000" "xiaomi_ax1800" "glinet" "cmiot_ax18" "qihoo_v6" "redmi_ax5"
    "mr7350" "uugamebooster" "luci-app-wol" "luci-i18n-wol-zh-cn" "CONFIG_TARGET_INITRAMFS" "ddns" "tailscale" "luci-app-advancedplus"
)

[[ $WRT_TARGET == *"WIFI-NO"* ]] && keywords_to_delete+=("usb" "wpad" "hostapd")
[[ $WRT_TARGET != *"EMMC"* ]] && keywords_to_delete+=("samba" "autosamba" "jdcloud_ax1800-pro" "jdcloud_ax6600")
[[ $WRT_TARGET == *"EMMC"* ]] && keywords_to_delete+=("jdcloud_ax1800-pro" "jdcloud_ax6600")

for keyword in "${keywords_to_delete[@]}"; do
    sed -i "/$keyword/d" ./.config
done

# Configuration lines to append to .config
provided_config_lines=(
    "CONFIG_PACKAGE_cpufreq=y"
    "CONFIG_PACKAGE_luci-app-cpufreq=y"
    "CONFIG_PACKAGE_luci-app-ttyd=y"
    "CONFIG_PACKAGE_luci-app-homeproxy=y"
    "CONFIG_PACKAGE_luci-app-alist=y"
    "CONFIG_PACKAGE_luci-app-mosdns=y"
    "CONFIG_PACKAGE_luci-app-lucky=y"
    "CONFIG_PACKAGE_luci-app-upnp"
    "CONFIG_PACKAGE_luci-app-aria2=y"
)

[[ $WRT_TARGET == *"WIFI-NO"* ]] && provided_config_lines+=("CONFIG_PACKAGE_hostapd-common=n" "CONFIG_PACKAGE_wpad-openssl=n")
[[ $WRT_TARGET == *"EMMC"* ]] && provided_config_lines+=(
    "CONFIG_PACKAGE_luci-app-diskman=y"
    "CONFIG_PACKAGE_luci-i18n-diskman-zh-cn=y"
    "CONFIG_PACKAGE_luci-app-docker=y"
    "CONFIG_PACKAGE_luci-i18n-docker-zh-cn=y"
    "CONFIG_PACKAGE_luci-app-dockerman=y"
    "CONFIG_PACKAGE_luci-i18n-dockerman-zh-cn=y"
)

# Append configuration lines to .config
for line in "${provided_config_lines[@]}"; do
    echo "$line" >> .config
done


#rm -rf package/feeds/packages/shadowsocks-rust
#cp -r package/helloworld/shadowsocks-rust package/feeds/packages/shadowsocks-rust
find ./ -name "getifaddr.c" -exec sed -i 's/return 1;/return 0;/g' {} \;
