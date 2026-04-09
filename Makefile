#####################
####  compiler  #####
#####################
.PHONY: install/riscv64-unknown-elf/gcc
install/riscv64-unknown-elf/gcc:
	@ sudo apt-get install gcc-riscv64-unknown-elf

######################
####  buildroot  #####
######################
.PHONY: buildroot/build
buildroot/build:
	@ git clone git@github.com:buildroot/buildroot.git
	@ cd buildroot && git checkout 56c6862bc81ef41c0fe012677eafa24381b1f76c
	@ cd buildroot && make qemu_riscv64_virt_defconfig
	@ cd buildroot && sed -i 's/^BR2_TARGET_ROOTFS_EXT2_2=y/# BR2_TARGET_ROOTFS_EXT2_2 is not set/' .config
	@ cd buildroot && sed -i 's/.*BR2_TARGET_ROOTFS_EXT2_4.*/BR2_TARGET_ROOTFS_EXT2_4=y/' .config
	@ cd buildroot && make olddefconfig
	@ cd buildroot && make -j$(shell nproc)
	@ cd buildroot && sed -i 's/^auto eth0/#auto eth0/' output/target/etc/network/interfaces
	@ cd buildroot && make -j$(shell nproc)

#########################
####  linux kernel  #####
#########################
.PHONY: linux/build
linux/build:
	@ git clone --depth 1 -b v6.8 https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
	@ cd linux && make ARCH=riscv CROSS_COMPILE=$(realpath ./buildroot/output/host/bin)/riscv64-buildroot-linux-gnu- defconfig
	@ cd linux && make ARCH=riscv CROSS_COMPILE=$(realpath ./buildroot/output/host/bin)/riscv64-buildroot-linux-gnu- vmlinux Image -j$(shell nproc)

###########################
########  OpenSBI  ########
###########################
# We need to build linux kernel before building OpenSBI
.PHONY: opensbi/build
opensbi/build:
	@ git clone https://github.com/riscv-software-src/opensbi.git
	@ cd opensbi && git checkout 0b041e58c0787f76325da5081e41a13bf304d328
	@ cd opensbi && make CROSS_COMPILE=$(realpath ./buildroot/output/host/bin)/riscv64-buildroot-linux-gnu- PLATFORM=generic FW_PAYLOAD_PATH=$(realpath ./linux/arch/riscv/boot/Image) -j$(shell nproc)

#################
####  gem5  #####
#################
.PHONY: gem5/build
gem5/build:
	@ git clone git@github.com:gem5/gem5.git
	@ cd gem5 && git checkout 7a2b0e413d06c5ce7097104abef3b1d9eaabca91 
	@ cd gem5 && scons build/RISCV/gem5.opt -j$(shell nproc)

.PHONY: gem5/run
gem5/run:
	@ ./gem5/build/RISCV/gem5.opt ./run_riscv.py

.PHONY: gem5/run/atomic
gem5/run/atomic:
	@ ./gem5/build/RISCV/gem5.opt ./run_riscv.py --cpu-type=atomic

.PHONY: gem5/run/timing
gem5/run/timing:
	@ ./gem5/build/RISCV/gem5.opt ./run_riscv.py --cpu-type=timing

.PHONY: gem5/run/minor
gem5/run/minor:
	@ ./gem5/build/RISCV/gem5.opt ./run_riscv.py --cpu-type=minor

.PHONY: gem5/run/o3
gem5/run/o3:
	@ ./gem5/build/RISCV/gem5.opt ./run_riscv.py --cpu-type=o3

.PHONY: gem5/term
gem5/term:
	@ ./gem5/util/term/gem5term 3456
