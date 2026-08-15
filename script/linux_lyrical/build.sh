#!/bin/bash -e

#脚本的运行目录
script_dir=$(
    cd $(dirname $0)
    pwd
)
# ros2版本
ros2_version=
# 目标架构(amd64 arm64)
build_target=

function print_help() {
  echo "-r ros2的版本 默认lyrical"
  echo "-t 目标架构(amd64 arm64)"
}

while getopts 'r:t:h' OPT; do
  case $OPT in
  r)
    ros2_version="${OPTARG}"
    ;;
  t)
    build_target="${OPTARG}"
    ;;
  h)
    print_help
    exit 1
    ;;
  esac
done

if [[ -z ${ros2_version} ]]; then
  ros2_version="lyrical"
  echo "设置默认的ros2版本: ${ros2_version}"
fi

cpuinfo="$(lscpu |grep aarch64 || true)"
if [[ -z "${cpuinfo}" ]]; then
  echo "当前架构amd64"
else
  echo "当前架构arm64"
fi

echo "=== 当前locale设置 ==="
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
locale

# https://docs.ros.org/en/lyrical/Installation/Alternatives/Ubuntu-Development-Setup.html
echo "下载源码"
rm -rf "${script_dir}/src"
mkdir -p ${script_dir}/src
cd ${script_dir}

src_addr="https://raw.githubusercontent.com/ros2/ros2/${ros2_version}-release/ros2.repos"
echo "源码地址:${src_addr}"
vcs import --input ${src_addr} src

# if [[ -z ${cpuinfo} ]]; then
#   echo "初始化pixi环境"
#   export PIXI_HOME="/opt/pixi"
#   export PATH="${PIXI_HOME}/bin:${PATH}"
#   # pixi shell 会卡住
#   if ! command -v pixi &> /dev/null; then
#       echo "错误: pixi 命令不存在"
#       exit 1
#   fi
#   echo "pixi路径:$(which pixi)"
#   source /opt/pixi/activate_ros2.sh
# fi


export MAKEFLAGS="-j4"
colcon build \
      --parallel-workers 2 \
      --merge-install \
      --event-handlers console_direct+ \
      --cmake-args -DLTTNGPY_DISABLED=1 -DCMAKE_TOOLCHAIN_FILE=${script_dir}/toolchain.cmake \
      --packages-skip qt_gui_cpp \
      --packages-skip-by-dep qt_gui_cpp \
      --packages-skip-build-finished
      
ls -alh