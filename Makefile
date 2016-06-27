#http_proxy=http://shadowblade:3128
#export http_proxy
#https_proxy=http://shadowblade:3128
#export https_proxy

DATE=$(shell date +%d%m%Y)
ROOT=$(shell pwd)

SYSROOT?=raspbian
NEED_ARMV6_PATCH?=y
ifeq ($(SYSROOT),raspbian)
 TARGET_TRIPLET=arm-rcm-linux-gnueabihf
else
 TARGET_TRIPLET=arm-rcm-linux-gnueabi
endif

PATH:=$(ROOT)/build-linux/builds/destdir/x86_64-unknown-linux-gnu/bin:$(ROOT)/skyforge:$(PATH)
export PATH

all: output/linux/$(TARGET_TRIPLET)-$(DATE).tgz output/windows/$(TARGET_TRIPLET)-$(DATE).tgz

linux: output/linux/$(TARGET_TRIPLET)-$(DATE).tgz

win32: output/windows/$(TARGET_TRIPLET)-$(DATE).tgz

output/linux/$(TARGET_TRIPLET)-$(DATE).tgz: build-linux/.sysroot
		mkdir -p output/linux/
		cd build-linux/builds/destdir/ && \
			mv x86_64-unknown-linux-gnu $(TARGET_TRIPLET); \
			tar cpzf ../../../$(@) . ;\
			mv $(TARGET_TRIPLET) x86_64-unknown-linux-gnu

output/windows/$(TARGET_TRIPLET)-$(DATE).tgz: build-mingw32/.sysroot
		mkdir -p output/windows/
		cd build-mingw32/builds/destdir/ && \
			mv i686-w64-mingw32 $(TARGET_TRIPLET) && \
			tar cpzf ../../../$(@) . && \
			mv $(TARGET_TRIPLET) i686-w64-mingw32

build-linux/.sysroot: skyforge build-linux/.built
	cd sysroot-builder/$(SYSROOT) && sudo skyforge build
	mkdir -p build-linux/builds/destdir/x86_64-unknown-linux-gnu/$(TARGET_TRIPLET)/libc
	tar xpf sysroot-builder/$(SYSROOT)/sysroot.tgz -C \
		build-linux/builds/destdir/x86_64-unknown-linux-gnu/$(TARGET_TRIPLET)/libc
	touch $@

build-mingw32/.sysroot: skyforge build-mingw32/.built
	cd sysroot-builder/$(SYSROOT) && sudo skyforge build
	mkdir -p build-mingw32/builds/destdir/i686-w64-mingw32/$(TARGET_TRIPLET)/libc
	tar xpf sysroot-builder/$(SYSROOT)/sysroot-symfix.tgz -C \
		build-mingw32/builds/destdir/i686-w64-mingw32/$(TARGET_TRIPLET)/libc
	touch $@

build-mingw32/.symlinkfix: build-mingw32/.built
	cd build-mingw32/builds/destdir/ && \
		../../../symlink2copy.sh
	touch $(@)

build-mingw32/.built: build-linux/.built
	mkdir -p build-mingw32
	cd build-mingw32 && ../abe/configure && \
		../abe/abe.sh --timeout 60 --target $(TARGET_TRIPLET) --host i686-w64-mingw32 --tarbin --build all
	touch $@

build-linux/.built: abe/.patched
	mkdir build-linux
	cd build-linux && ../abe/configure && \
		../abe/abe.sh --timeout 60 --target $(TARGET_TRIPLET) --tarbin --build all
	touch $@

abe:
	git clone https://git.linaro.org/toolchain/abe.git
	cd abe && git checkout stable

skyforge:
	git clone https://github.com/RC-MODULE/skyforge.git


abe/.patched: abe
	cd abe && \
		git reset --hard HEAD && \
ifeq($(NEED_ARMV6_PATCH),y)
		patch -p1 < ../gcc.conf.patch
else
		echo "No need to patch"
endif
	touch $@

clean:
	rm -Rfv build-*

distclean: clean
	rm -Rfv abe snapshots skyforge
	rm -Rfv output

.PHONY: win32 linux
