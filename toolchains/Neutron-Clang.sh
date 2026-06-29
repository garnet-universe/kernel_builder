#!/bin/bash

maindir="$(pwd)"
outside="${maindir}/.."

dir="${outside}/NeutronClang"

case $1 in
  "setup" )
    # Clone compiler
    if [[ ! -d "${dir}" ]]; then
      mkdir ${dir} && cd ${dir}
      curl -LO "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman"
      if ! bash antman -S=latest &>/dev/null; then
        exit 1
      fi
    fi
  ;;

  "build" )
    export PATH="${dir}/bin:/usr/bin:${PATH}"

    # Multi-Defconfig: merge configs using kernel's merge_config.sh
    # Base config first, then fragment configs override
    make "${DEFCONFIGS%% *}" O=out ARCH=arm64 SUBARCH=arm64 CC=clang LD=ld.lld
    scripts/kconfig/merge_config.sh -O out out/.config ${DEFCONFIGS#* }
    make O=out olddefconfig

    # Build uncompressed Image
    make -j$NJOBS O=out \
      KCFLAGS="-Wno-error" \
      CROSS_COMPILE="aarch64-linux-gnu-" \
      CROSS_COMPILE_ARM32="arm-linux-gnueabi-" \
      CROSS_COMPILE_COMPAT="arm-linux-gnueabi-" \
      CC=clang \
      LD=ld.lld \
      NM=llvm-nm \
      AR=llvm-ar \
      STRIP=llvm-strip \
      OBJCOPY=llvm-objcopy \
      OBJDUMP=llvm-objdump \
      READELF=llvm-readelf \
      LLVM_IAS=1 \
      HOSTCC=clang \
      HOSTCXX=clang++ \
      HOSTLD=ld.lld \
      HOSTAR=llvm-ar \
      Image \
      2>&1 | tee ${CUR_TOOLCHAIN}.log
    sh ${outside}/ver_toolchain.sh clang ld.lld > ${CUR_TOOLCHAIN}.info
  ;;
esac