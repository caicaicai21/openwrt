#!/bin/bash

start_bulid() {
	#make download -j$(($(nproc) + 1))
	make download -j$1

	#make -j$(($(nproc) + 1)) V=s
	make -j$1 V=s
}

check_git(){
	if [ $? -ne 0 ];then
		echo "git download fail, exit..."
		exit 1
	fi
}

ONLY_CONFIG=0
MODEL=x86_64
THREADS=$(nproc)
SKIP=0
BATMAN=0
UPDATE_FEEDS=0

while getopts :osubt:m: OPTION; do
	case $OPTION in
		o) ONLY_CONFIG=1
		;;
		m) MODEL=$OPTARG
		;;
		b) BATMAN=1
		;;
		u) UPDATE_FEEDS=1
		;;
		t)
			if [ $OPTARG -gt 0 ];then
				THREADS=$OPTARG
			fi
		;;
		s) SKIP=1
		;;
		?)
		printf "[Usage]
	-u: update feeds
	-o: only create config file
	-b: include B.A.T.M.A.N-adv
	-t <NUMBER>: thread count, default cpu count
	-m <MODEL_NAME>: x86_64(default) mir3g newifi3 hc5761\n" >&2
		exit 1 ;;
	esac
done

if [ $SKIP -eq 1 ];then
	start_bulid ${THREADS}
	exit 0
fi

printf "Only config: "
if [ $ONLY_CONFIG -eq 1 ];then
	printf "yes\n"
else
	printf "no\n"
fi
printf "Include B.A.T.M.A.N-adv: "
if [ $BATMAN -eq 1 ];then
	printf "yes\n"
else
	printf "no\n"
fi
echo "Model name: $MODEL"
echo "Thread count: $THREADS"

if [ -f ".config" ];then
	make clean
else
	UPDATE_FEEDS=1
fi

cd package
if [ -d "custom-packages" ];then
	rm -rf custom-packages
fi
git clone -b openwrt-19.07 https://github.com/caicaicai21/openwrt_custom_packages.git ./custom-packages
check_git
cd custom-packages

if [ ! -f "/usr/bin/po2lmo" ];then
	cd ./luci-app-openclash/tools/po2lmo
	make && sudo make install
	cd ../../../
fi

#git clone https://github.com/frainzy1477/luci-app-clash.git
#check_git
#if [ ! -f "/usr/bin/po2lmo" ];then
#	cd ./luci-app-clash/tools/po2lmo
#	make && sudo make install
#	cd ../../../
#else
#	po2lmo ./luci-app-clash/po/zh-cn/clash.po ./luci-app-clash/po/zh-cn/clash.zh-cn.lmo
#fi

cd ../../

if [ $UPDATE_FEEDS -eq 1 ];then
	./scripts/feeds update -a
fi

./scripts/feeds install -a

rm -f ./.config*
touch ./.config

# target cpu
if [ "$MODEL" = "x86_64" ];then
cat >> .config <<EOF
CONFIG_TARGET_x86=y
CONFIG_TARGET_x86_64=y
CONFIG_TARGET_x86_64_Generic=y
EOF
elif [ "$MODEL" = "mir3g" ];then
cat >> .config <<EOF
CONFIG_TARGET_ramips=y
CONFIG_TARGET_ramips_mt7621=y
CONFIG_TARGET_ramips_mt7621_DEVICE_xiaomi_mir3g=y
EOF
elif [ "$MODEL" = "newifi3" ];then
cat >> .config <<EOF
CONFIG_TARGET_ramips=y
CONFIG_TARGET_ramips_mt7621=y
CONFIG_TARGET_ramips_mt7621_DEVICE_d-team_newifi-d2=y
EOF
elif [ "$MODEL" = "hc5761" ];then
cat >> .config <<EOF
CONFIG_TARGET_ramips=y
CONFIG_TARGET_ramips_mt7620=y
CONFIG_TARGET_ramips_mt7620_DEVICE_hc5761=y
EOF
else
	echo "Build type error, use: x86_64, rpi3, rpi4, mir3g, newifi3, hc5761"
	exit -1
fi

# packages
cat >> .config <<EOF
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-compat=y
#
CONFIG_LUCI_LANG_zh_Hans=y=y
EOF

if [ "$MODEL" = "x86_64" ];then
cat >> .config <<EOF
CONFIG_PACKAGE_qemu-ga=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_nano=y
CONFIG_PACKAGE_wget-ssl=y
CONFIG_PACKAGE_iperf3=y
#
# CONFIG_PACKAGE_luci-app-netdata=y
CONFIG_PACKAGE_luci-app-zerotier=y
CONFIG_PACKAGE_luci-app-softethervpn=y
#
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-app-openclash=y
# CONFIG_PACKAGE_luci-app-clash is not set
CONFIG_PACKAGE_kmod-tun=y
# CONFIG_PACKAGE_dnsmasq is not set
CONFIG_PACKAGE_luci-app-smartdns=y
CONFIG_PACKAGE_luci-app-ddns=y
CONFIG_PACKAGE_ddns-scripts=y
CONFIG_PACKAGE_ddns-scripts_cloudflare.com-v4=y
CONFIG_PACKAGE_ddns-scripts_aliyun=y
#
CONFIG_TARGET_IMAGES_GZIP=y
# CONFIG_EFI_IMAGES is not set
# CONFIG_VDI_IMAGES is not set
# CONFIG_VMDK_IMAGES is not set
# # CONFIG_TARGET_IMAGES_PAD is not set
EOF
elif [ "$MODEL" = "mir3g" ] || [ "$MODEL" = "newifi3" ];then
cat >> .config <<EOF
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_nano=y
CONFIG_PACKAGE_wget-ssl=y
CONFIG_PACKAGE_iperf3=y
#
CONFIG_PACKAGE_luci-app-zerotier=y
#
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-app-openclash=y
# CONFIG_PACKAGE_luci-app-clash is not set
CONFIG_PACKAGE_kmod-tun=y
# CONFIG_PACKAGE_dnsmasq is not set
CONFIG_PACKAGE_luci-app-smartdns=y
#
# CONFIG_PACKAGE_wpad-basic is not set
# CONFIG_PACKAGE_wpad-basic-wolfssl is not set
CONFIG_PACKAGE_wpad-mesh-wolfssl=y
EOF
elif [ "$MODEL" = "hc5761" ];then
cat >> .config <<EOF
CONFIG_PACKAGE_nano=y
CONFIG_PACKAGE_wget-ssl=y
#
CONFIG_PACKAGE_luci-app-zerotier=y
#
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-app-openclash=y
# CONFIG_PACKAGE_luci-app-clash is not set
CONFIG_PACKAGE_kmod-tun=y
# CONFIG_PACKAGE_dnsmasq is not set
#
# CONFIG_PACKAGE_wpad-basic is not set
# CONFIG_PACKAGE_wpad-basic-wolfssl is not set
CONFIG_PACKAGE_wpad-mesh-wolfssl=y
EOF
fi

if [ $BATMAN -eq 1 ];then
cat >> .config <<EOF
CONFIG_PACKAGE_kmod-batman-adv=y
EOF
fi

sed -i 's/^[ \t]*//g' ./.config
make defconfig

if [ $ONLY_CONFIG -eq 1 ];then
	exit 0
fi

start_bulid ${THREADS}
