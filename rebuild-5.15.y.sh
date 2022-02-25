#!/bin/bash
origin="Rock64"
target="Chainedbox"
WORK_DIR=$(pwd)
echo "$WORK_DIR"
mount_point="tmp"

DTB=dtbs/5.15.y-bsp
IDB=loader/idbloader.bin
UBOOT=loader/uboot.img
TRUST=loader/trust.bin

echo -e "01.01 读取镜像"
#设置镜像路径
imgdir=./build/output/images/
imgfile="$(ls ${imgdir}/*.img)"
echo "找到镜像: $imgfile"

echo -e "01.02 识别镜像名称"
#获取镜像名称
imgname=`basename $imgfile`
echo "镜像名称: $imgname"
echo -e "完成"

echo -e "02.01 挂载镜像"

umount -f tmp
losetup -D
echo "挂载镜像 ... "
losetup -D
losetup -f -P ${imgfile}

BLK_DEV=$(losetup | grep "$imgname" | head -n 1 | gawk '{print $1}')
echo "挂载镜像成功 位置："${BLK_DEV}""

echo "设置卷标"
e2label ${BLK_DEV}p1 ROOTFS
tune2fs ${BLK_DEV}p1 -L ROOTFS

lsblk -l
mkdir -p ${WORK_DIR}/tmp
mount ${BLK_DEV}p1 ${WORK_DIR}/$mount_point
echo "挂载镜像根目录到 ${WORK_DIR}/$mount_point "

echo -e "完成"

echo -e "03.01 复制文件"
echo "复制文件"
cp -v ${WORK_DIR}/$DTB/*.dtb $mount_point/boot/
cp -v ${WORK_DIR}/l1pro/install-docker.sh $mount_point/root/
cp -v ${WORK_DIR}/l1pro/install-omv.sh $mount_point/root/
cp -v ${WORK_DIR}/l1pro/pwm-fan.service $mount_point/etc/systemd/system/
cp -v ${WORK_DIR}/l1pro/pwm-fan.pl $mount_point/usr/bin/ && chmod 700 $mount_point/usr/bin/pwm-fan.pl

echo -e "完成"

echo -e "04.01 修改引导分区相关配置"


echo "修改引导分区相关配置 ... "
cd ${WORK_DIR}

sed -i '/^verbosity/cverbosity=7' $mount_point/boot/armbianEnv.txt && \
sed -i '/rootfstype=ext4/a rootflags=rw' $mount_point/boot/armbianEnv.txt && \
echo "extraargs=usbcore.autosuspend=-1" >> $mount_point/boot/armbianEnv.txt && \
echo "extraboardargs=" >> $mount_point/boot/armbianEnv.txt && \
echo "fdtfile=rk3328-l1pro-1296mhz.dtb" >> $mount_point/boot/armbianEnv.txt && \
echo "usbstoragequirks=0x05e3:0x0612:u,0x1d6b:0x0003:u,0x05e3:0x0610:u" >> $mount_point/boot/armbianEnv.txt && \
sed -i 's/0x9000000/0x39000000/' $mount_point/boot/boot.cmd && \
sed -i 's#${prefix}dtb/${fdtfile}#${prefix}/${fdtfile}#' $mount_point/boot/boot.cmd
mkimage -C none -T script -d $mount_point/boot/boot.cmd $mount_point/boot/boot.scr

# patch rootfs
echo "patch rootfs"
cat > $mount_point/etc/apt/sources.list <<EOF
deb [arch=arm64,armhf] https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free
deb [arch=arm64,armhf] https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-updates main contrib non-free
deb [arch=arm64,armhf] https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-backports main contrib non-free
deb [arch=arm64,armhf] https://mirrors.tuna.tsinghua.edu.cn/debian-security bullseye-security main contrib non-free
EOF

cat > /etc/apt/sources.list.d/armbian.list <<EOF
deb [arch=arm64,armhf] https://mirrors.tuna.tsinghua.edu.cn/armbian/ bullseye main bullseye-utils bullseye-desktop
EOF

sed -i 's/ENABLED=true/#ENABLED=true/' $mount_point/etc/default/armbian-zram-config
sed -i 's/ENABLED=true/#ENABLED=true/' $mount_point/etc/default/armbian-ramlog
rm -f $mount_point/etc/systemd/system/getty.target.wants/serial-getty\@ttyS2.service
ln -sf /usr/share/zoneinfo/Asia/Shanghai $mount_point/etc/localtime
sed -i 's/Rock 64/chainedbox/' $mount_point/etc/armbian-image-release
sed -i 's/rock64/chainedbox/' $mount_point/etc/armbian-image-release
sed -i 's/rock64/chainedbox/' $mount_point/etc/armbian-release
sed -i 's/Rock 64/chainedbox/' $mount_point/etc/armbian-release
sed -i 's/rock64/Chainedbox/' $mount_point/etc/hostname
sync

echo "进入 CHROOT 模式更新系统组件"

chroot $mount_point <<EOF
su
systemctl enable pwm-fan.service
apt-mark hold linux-dtb-legacy-rockchip64 linux-image-legacy-rockchip64 linux-dtb-current-rockchip64 linux-image-current-rockchip64 linux-dtb-edge-rockchip64 linux-image-edge-rockchip64
#锁定内核文件，防止升级的时候 我家云 的专用内核被通用内核替换导致不开机

ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
	dpkg-reconfigure --frontend noninteractive tzdata
exit
EOF
sync

cd ${WORK_DIR}

umount -f $mount_point

echo "添加引导项： idb,uboot,trust"

dd if=${IDB} of=${imgfile} seek=64 bs=512 conv=notrunc status=none && echo "idb patched: ${IDB}" || { echo "idb patch failed!"; exit 1; }
dd if=${UBOOT} of=${imgfile} seek=16384 bs=512 conv=notrunc status=none && echo "uboot patched: ${UBOOT}" || { echo "u-boot patch failed!"; exit 1; }
dd if=${TRUST} of=${imgfile} seek=24576 bs=512 conv=notrunc status=none && echo "trust patched: ${TRUST}" || { echo "trust patch failed!"; exit 1; }

imgname_new=`basename $imgfile | sed "s/${origin}/${target}/"`
echo "新文件名: $imgname_new"
mv $imgfile ${imgdir}/${imgname_new}
rm -rf ${tmpdir}

losetup -D
blkid
echo "ok"

