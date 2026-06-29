#!/bin/bash

maindir="$(pwd)"
outside="${maindir}/.."

dir="${outside}/android-clang"

case $1 in
  "setup" )
    # Clone Android prebuilt clang (branch has clang-r547379 for Android 16)
    if [[ ! -d "${dir}" ]]; then
      mkdir ${dir} && cd ${dir}
      git clone https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 . -b mirror-goog-llvm-r596125-release --depth=1
    fi
  ;;

  "build" )
    export PATH="${dir}/clang-r547379/bin:/usr/bin:${PATH}"

    # Multi-Defconfig: merge configs using kernel's merge_config.sh
    make "${DEFCONFIGS%% *}" O=out ARCH=arm64 CC=clang LD=ld.lld
    scripts/kconfig/merge_config.sh -O out out/.config ${DEFCONFIGS#* }
    make O=out olddefconfig

    # Build uncompressed Image
    make -j$NJOBS O=out \
      CC=clang \
      LD=ld.lld \
      CROSS_COMPILE=aarch64-linux-gnu- \
      LLVM=1 \
      LLVM_IAS=1 \
      KCFLAGS="-Wno-error" \
      Image \
      2>&1 | tee ${CUR_TOOLCHAIN}.log
    sh ${outside}/ver_toolchain.sh clang ld.lld > ${CUR_TOOLCHAIN}.info
  ;;
esac