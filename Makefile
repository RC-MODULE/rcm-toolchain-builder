http_proxy=http://shadowblade:3128
export http_proxy
https_proxy=http://shadowblade:3128
export https_proxy

DATE=$(shell date +%d%m%Y)
ROOT=$(shell pwd)

SYSROOT=rapsbian
ifeq ($(SYSROOT),raspbian)
	TARGET_TRIPLET=arm-rcm-linux-gnueabihf
else
	TARGET_TRIPLET=arm-rcm-linux-gnueabi
endif

all: output/linux/$(TARGET_TRIPLET)-$(DATE).tgz output/windows/$(TARGET_TRIPLET)-$(DATE).tgz

output/linux/$(TARGET_TRIPLET)-$(DATE).tgz: build-mingw32/.symlinkfix
		mkdir -p output/linux/
		cp build-linux/snapshots/gcc-linaro-*.tar.xz $(@)

output/windows/$(TARGET_TRIPLET)-$(DATE).tgz: build-mingw32/.symlinkfix
		mkdir -p output/windows/
		cd build-mingw32/builds/destdir/ && \
			tar cvpzf ../../../$(@) .

build-linux/.sysroot:
	cd sysroot-builder/$(SYSROOT) && sudo skyforge build
	mkdir -p build-linux/builds/destdir/x86_64-unknown-linux-gnu/$(TARGET_TRIPLET)/libc
	tar vxpf sysroot-builder/$(SYSROOT)/debian-sysroot.tgz -C \
		build-linux/builds/destdir/x86_64-unknown-linux-gnu/$(TARGET_TRIPLET)/libc
	touch $@

build-mingw32/.sysroot:
	cd sysroot-builder/$(SYSROOT) && sudo skyforge build
	mkdir -p build-mingw32/builds/destdir/i686-w64-mingw32/$(TARGET_TRIPLET)/libc
	tar vxpf sysroot-builder/$(SYSROOT)/debian-sysroot-symfix.tgz -C \
		build-linux/builds/destdir/i686-w64-mingw32/$(TARGET_TRIPLET)/libc
	touch $@

build-mingw32/.symlinkfix: build-mingw32/.built
	cd build-mingw32/builds/destdir/ && \
		../../../symlink2copy.sh
	touch $(@)

build-mingw32/.built: build-linux/.built
	mkdir build-mingw32
	export PATH=`pwd`/build-linux/builds/destdir/x86_64-unknown-linux-gnu/bin:$$PATH
	cd build-mingw32 && ../abe/configure && \
		../abe/abe.sh --timeout 60 --target $(TARGET_TRIPLET) --host i686-w64-mingw32 --build all
	touch $@

build-linux/.built: abe/.patched
	mkdir build-linux
	cd build-linux && ../abe/configure && \
		../abe/abe.sh --timeout 60 --target $(TARGET_TRIPLET) --build all
	touch $@

abe:
	git clone https://git.linaro.org/toolchain/abe.git
	cd abe && git checkout stable

abe/.patched: abe
	cd abe && \
		git reset --hard HEAD && \
		patch -p1 < ../gcc.conf.patch
	touch $@

clean:
	rm -Rfv output
	rm -Rfv build-*

distclean: clean
	rm -Rfv abe snapshots
