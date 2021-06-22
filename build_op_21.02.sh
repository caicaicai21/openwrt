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
THREADS=$(($(nproc) + 1))
SKIP=0
BATMAN=0
UPDATE_FEEDS=0
CLEAN=0
MAKE_CLEAN=0
MTK_DRIVER=0
SFE=0
USB=0

while getopts :osuUcBCMSt:m: OPTION; do
	case $OPTION in
		o) ONLY_CONFIG=1
		;;
		m) MODEL=$OPTARG
		;;
		M) MTK_DRIVER=1
		;;
		S) SFE=1
		;;
		B) BATMAN=1
		;;
		u) UPDATE_FEEDS=1
		;;
		U) USB=1
		;;
		C) CLEAN=1
		;;
		c) MAKE_CLEAN=1
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
	-U: include USB driver
	-o: only create config file
	-B: include B.A.T.M.A.N-adv
	-M: use mtk wireless driver(if have)
	-S: include SFE driver
	-C: clean project
	-c: make clean before make
	-t <NUMBER>: thread count, default cpu count
	-m <MODEL_NAME>: x86_64(default) mir3g newifi3 k2p k2p-32 hc5761\n" >&2
		exit 1 ;;
	esac
done

if [ $CLEAN -eq 1 ];then
	git clean -xdf
	make distclean
	rm -rf ./package/custom-packages
	rm -rf ./package/mtk
	exit 0
fi

if [ $SKIP -eq 1 ];then
	start_bulid ${THREADS}
	exit 0
fi

printf "Use MTK wireless drives: "
if [ $MTK_DRIVER -eq 1 ];then
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
printf "Include USB driver: "
if [ $USB -eq 1 ];then
	printf "yes\n"
else
	printf "no\n"
fi
printf "Include SFE drives: "
if [ $SFE -eq 1 ];then
	printf "yes\n"
else
	printf "no\n"
fi
printf "Only config: "
if [ $ONLY_CONFIG -eq 1 ];then
	printf "yes\n"
else
	printf "no\n"
fi
echo "Model name: $MODEL"
echo "Thread count: $THREADS"

if [ -f ".config" ];then
	if [ $MAKE_CLEAN -eq 1 ];then
		make clean
	fi
else
	UPDATE_FEEDS=1
fi

cd package

if [ -d "mtk" ];then
	rm -rf mtk
fi
if [[ "$MODEL" = "k2p" || "$MODEL" = "k2p-32" ]] && [ $MTK_DRIVER -eq 1 ];then
	git clone https://github.com/caicaicai21/mt7615-dbdc-linux5.4.git mtk
	check_git
fi

if [ -d "custom-packages" ];then
	rm -rf custom-packages
fi
git clone -b openwrt-21.02 https://github.com/caicaicai21/openwrt_custom_packages.git custom-packages
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
CONFIG_TARGET_x86_64_DEVICE_generic=y
EOF
elif [ "$MODEL" = "mir3g" ];then
cat >> .config <<EOF
CONFIG_TARGET_ramips=y
CONFIG_TARGET_ramips_mt7621=y
CONFIG_TARGET_ramips_mt7621_DEVICE_xiaomi_mi-router-3g=y
EOF
elif [ "$MODEL" = "newifi3" ];then
cat >> .config <<EOF
CONFIG_TARGET_ramips=y
CONFIG_TARGET_ramips_mt7621=y
CONFIG_TARGET_ramips_mt7621_DEVICE_d-team_newifi-d2=y
EOF
elif [ "$MODEL" = "k2p" ];then
cat >> .config <<EOF
CONFIG_TARGET_ramips=y
CONFIG_TARGET_ramips_mt7621=y
CONFIG_TARGET_ramips_mt7621_DEVICE_phicomm_k2p=y
EOF
elif [ "$MODEL" = "k2p-32" ];then
cat >> .config <<EOF
CONFIG_TARGET_ramips=y
CONFIG_TARGET_ramips_mt7621=y
CONFIG_TARGET_ramips_mt7621_DEVICE_phicomm_k2p-32m=y
EOF
elif [ "$MODEL" = "hc5761" ];then
cat >> .config <<EOF
CONFIG_TARGET_ramips=y
CONFIG_TARGET_ramips_mt7620=y
CONFIG_TARGET_ramips_mt7620_DEVICE_hiwifi_hc5761=y
EOF
else
	echo "Build type error, use: x86_64 mir3g newifi3 k2p k2p-32 hc5761"
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
CONFIG_PACKAGE_wget=y
CONFIG_PACKAGE_iperf3=y
#
CONFIG_PACKAGE_luci-app-zerotier=y
CONFIG_PACKAGE_luci-app-softethervpn=y
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_luci-app-adguardhome=y
CONFIG_PACKAGE_kmod-tun=y
CONFIG_PACKAGE_luci-app-ddns=y
CONFIG_PACKAGE_ddns-scripts=y
CONFIG_PACKAGE_ddns-scripts-cloudflare=y
CONFIG_PACKAGE_ddns-scripts_aliyun=y
# CONFIG_PACKAGE_luci-app-netdata=y
# CONFIG_PACKAGE_luci-app-clash is not set
# CONFIG_PACKAGE_dnsmasq is not set
# CONFIG_PACKAGE_luci-app-smartdns is not set
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
CONFIG_PACKAGE_wget=y
CONFIG_PACKAGE_iperf3=y
#
CONFIG_PACKAGE_luci-app-zerotier=y
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_kmod-tun=y
# CONFIG_PACKAGE_dnsmasq is not set
# CONFIG_PACKAGE_luci-app-smartdns is not set
# CONFIG_PACKAGE_luci-app-clash is not set
#
# CONFIG_PACKAGE_wpad-basic is not set
# CONFIG_PACKAGE_wpad-basic-wolfssl is not set
CONFIG_PACKAGE_wpad-mesh-wolfssl=y
EOF
elif [ "$MODEL" = "k2p" ] || [ "$MODEL" = "k2p-32" ];then
cat >> .config <<EOF
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_nano=y
CONFIG_PACKAGE_wget=y
# CONFIG_PACKAGE_upx is not set
CONFIG_PACKAGE_iperf3=y
#
CONFIG_PACKAGE_luci-app-zerotier=y
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-app-openclash=y
# CONFIG_PACKAGE_luci-app-softethervpn is not set
# CONFIG_PACKAGE_luci-app-ksmbd is not set
CONFIG_PACKAGE_kmod-tun=y
# CONFIG_PACKAGE_luci-app-adguardhome is not set
CONFIG_PACKAGE_luci-app-samba4=y
# CONFIG_PACKAGE_luci-app-clash is not set
# CONFIG_PACKAGE_luci-app-smartdns is not set
# CONFIG_PACKAGE_dnsmasq is not set
#
# CONFIG_PACKAGE_wpad-basic is not set
# CONFIG_PACKAGE_wpad-basic-wolfssl is not set
EOF
if [ $MTK_DRIVER -eq 1 ];then
cat >> .config <<EOF
CONFIG_PACKAGE_wireless-tools=y
CONFIG_PACKAGE_luci-app-mtwifi=y
CONFIG_PACKAGE_kmod-mt_wifi=y
CONFIG_MTK_FIRST_IF_MT7615E=y
CONFIG_MTK_MT_WIFI=y
CONFIG_MTK_WIFI_MODE_AP=m
CONFIG_MTK_DOT11R_FT_SUPPORT=y
EOF
else
cat >> .config <<EOF
CONFIG_PACKAGE_wpad-mesh-wolfssl=y
CONFIG_PACKAGE_kmod-mt7615e=y
CONFIG_PACKAGE_kmod-mt7615-firmware=y
EOF
fi
elif [ "$MODEL" = "hc5761" ];then
cat >> .config <<EOF
CONFIG_PACKAGE_nano=y
CONFIG_PACKAGE_wget=y
#
CONFIG_PACKAGE_luci-app-zerotier=y
#
CONFIG_PACKAGE_luci-app-upnp=y
# CONFIG_PACKAGE_luci-app-openclash is not set
# CONFIG_PACKAGE_luci-app-clash is not set
# CONFIG_PACKAGE_kmod-tun is not set
CONFIG_PACKAGE_dnsmasq=y
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

if [ $USB -eq 1 ];then
cat >> .config <<EOF
# USB
CONFIG_PACKAGE_kmod-usb3=y
CONFIG_PACKAGE_kmod-usb2=y
CONFIG_PACKAGE_kmod-usb-core=y
CONFIG_PACKAGE_kmod-usb-ohci=y
CONFIG_PACKAGE_kmod-usb-uhci=y
CONFIG_PACKAGE_kmod-usb-storage=y
CONFIG_PACKAGE_kmod-usb-storage-extras=y
# CONFIG_PACKAGE_automount is not set
# CONFIG_PACKAGE_kmod-nls-cp936 is not set
CONFIG_PACKAGE_kmod-fs-vfat=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-exfat=y
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_antfs-mount=y
EOF
fi

if [ $SFE -eq 1 ];then
cat >> .config <<EOF
CONFIG_PACKAGE_kmod-shortcut-fe=y
# CONFIG_PACKAGE_kmod-shortcut-fe-cm is not set
CONFIG_PACKAGE_kmod-fast-classifier=y
EOF
fi

sed -i 's/^[ \t]*//g' ./.config
make defconfig

if [ $ONLY_CONFIG -eq 1 ];then
	make menuconfig
	exit 0
fi

start_bulid ${THREADS}
