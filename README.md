编译命令

sudo ./compile.sh  BOARD=rock64 BRANCH=current BUILD_MINIMAL=no BUILD_DESKTOP=no KERNEL_ONLY=yes KERNEL_CONFIGURE=yes MAINLINE_MIRROR=tuna DOWNLOAD_MIRROR=china

补丁 add-chainedbox-and-fix-gbe.patch 添加目录

/build/userpatches/kernel/rockchip64-current

lib.config 添加目录
/build/userpatches

http://git.mis.ks.ua/US1GHQ/Armbian/commit/948162b76d62a0dc748762a4b4033e4f9f84b8d1.diff

https://my.oschina.net/u/4349637/blog/3335441

https://www.kflyo.com/howto-compile-armbian/