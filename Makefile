http_proxy=http://shadowblade:3128
export http_proxy
https_proxy=http://shadowblade:3128
export https_proxy

DATE=$(shell date +%d%m%Y)
ROOT=$(shell pwd)

VENDOR?=rcm
SYSROOT?=raspbian

COMPONENT_VERSIONS:= \
	gcc=gcc-linaro-4.9-2016.02.tar.xz \
	binutils=binutils-linaro-2.24.0-2014.11-2.tar.xz \
	dejagnu=dejagnu.git/linaro \
	glibc=glibc-linaro-2.20-2014.11.tar.xz

ABE_OP?=$(COMPONENT_VERSIONS) --tarbin --build all

ifeq ($(SYSROOT),raspbian)
 TARGET_TRIPLET=arm-$(VENDOR)-linux-gnueabihf
 NEED_ARMV6_PATCH=y
 SKYFORGE_BUILD_DIR=raspbian
 DEBARCH=armhf
endif

ifeq ($(SYSROOT),debian-armel)
 TARGET_TRIPLET=arm-$(VENDOR)-linux-gnueabi
 NEED_ARMV6_PATCH=y
 SKYFORGE_BUILD_DIR=debian
 DEBARCH=armel
endif

ifeq ($(SYSROOT),debian-armhf)
 TARGET_TRIPLET=arm-$(VENDOR)-linux-gnueabihf
 NEED_ARMV6_PATCH=n
 SKYFORGE_BUILD_DIR=raspbian
 DEBARCH=armhf
endif

SKYFORGE:=$(ROOT)/skyforge/skyforge
PATH:=$(ROOT)/build-linux/builds/destdir/x86_64-unknown-linux-gnu/bin:$(PATH)
SNAPSHOTS_DIR:=--snapshots $(shell pwd)/snapshots
#SNAPSHOTS_DIR:=

export PATH
export DEBARCH

all: linux win32

linux: output/linux/$(TARGET_TRIPLET)-$(DATE).tgz

win32: output/windows/$(TARGET_TRIPLET)-$(DATE).zip

output/linux/$(TARGET_TRIPLET)-$(DATE).tgz: build-linux/.sysroot
		mkdir -p output/linux/
		cd build-linux/builds/destdir/ && \
			mv x86_64-unknown-linux-gnu $(TARGET_TRIPLET); \
			tar cpzf ../../../$(@) . ;\
			mv $(TARGET_TRIPLET) x86_64-unknown-linux-gnu

output/windows/$(TARGET_TRIPLET)-$(DATE).zip: build-mingw32/.sysroot
		mkdir -p output/windows/
		cd build-mingw32/builds/destdir/ && \
			mv i686-w64-mingw32 $(TARGET_TRIPLET) && \
			zip -r ../../../$(@) . && \
			mv $(TARGET_TRIPLET) i686-w64-mingw32

build-linux/.sysroot: skyforge build-linux/.built
	cd sysroot-builder/$(SKYFORGE_BUILD_DIR) && sudo DEBARCH=armhf $(SKYFORGE) build
	mkdir -p build-linux/builds/destdir/x86_64-unknown-linux-gnu/$(TARGET_TRIPLET)/libc
	tar xpf sysroot-builder/$(SKYFORGE_BUILD_DIR)/sysroot.tgz -C \
		build-linux/builds/destdir/x86_64-unknown-linux-gnu/$(TARGET_TRIPLET)/libc
	touch $@

build-mingw32/.sysroot: skyforge build-mingw32/.built
	cd sysroot-builder/$(SKYFORGE_BUILD_DIR) && sudo DEBARCH=armhf $(SKYFORGE) build
	mkdir -p build-mingw32/builds/destdir/i686-w64-mingw32/$(TARGET_TRIPLET)/libc
	tar xpf sysroot-builder/$(SKYFORGE_BUILD_DIR)/sysroot-symfix.tgz -C \
		build-mingw32/builds/destdir/i686-w64-mingw32/$(TARGET_TRIPLET)/libc
	touch $@

build-mingw32/.symlinkfix: build-mingw32/.built
	cd build-mingw32/builds/destdir/ && \
		../../../symlink2copy.sh
	touch $(@)

build-mingw32/.built: build-linux/.built
	mkdir -p build-mingw32
	cd build-mingw32 && ../abe/configure && \
		../abe/abe.sh $(SNAPSHOTS_DIR) --timeout 60 --target $(TARGET_TRIPLET) --host i686-w64-mingw32 $(ABE_OP)
	touch $@

build-linux/.built: abe/.patched
	mkdir -p build-linux
	cd build-linux && ../abe/configure && \
		../abe/abe.sh $(SNAPSHOTS_DIR) --timeout 60 --target $(TARGET_TRIPLET) $(ABE_OP)
	touch $@

abe:
	git clone https://git.linaro.org/toolchain/abe.git
	cd abe && git checkout stable

skyforge:
	git clone https://github.com/RC-MODULE/skyforge.git


abe/.patched: abe
	cd abe && \
	git reset --hard HEAD && \
	echo "glibc       http://148.251.136.42/snapshots-ref" >> config/sources.conf && \
	patch -p1 < ../abe-gcc-4.9-missing.stub.patch


ifeq ($(NEED_ARMV6_PATCH),y)
	cd abe && patch -p1 < ../gcc.conf.patch
endif

	touch $@

clean:
	rm -Rfv build-*

distclean: clean
	rm -Rfv abe snapshots skyforge
	rm -Rfv output

.PHONY: win32 linux
