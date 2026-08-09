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
# 源码目录
docker_ros2_dir="/ros2_work_dir"

function print_help() {
  echo "-r ros2的版本 默认jazzy"
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
  ros2_version="jazzy"
  echo "设置默认的ros2版本: ${ros2_version}"
fi

echo "=== 当前locale设置 ==="
locale

# https://docs.ros.org/en/jazzy/Installation/Alternatives/Ubuntu-Development-Setup.html
cd ${docker_ros2_dir}

dest_arch="amd64"
if [[ ${build_target} == "aarch64" ]]; then
  dest_arch="arm64"
fi
echo "编译平台:${dest_arch}"
# 替换平台
# sed -i "s/^.*CMAKE_SYSTEM_PROCESSOR.*$/set(CMAKE_SYSTEM_PROCESSOR ${dest_arch})/" ${docker_ros2_dir}/toolchain.cmake

# echo "配置llvm库的路径"
# export LD_LIBRARY_PATH=${llvm_path}/lib:$LD_LIBRARY_PATH
# export LIBRARY_PATH=${llvm_path}/lib:$LIBRARY_PATH

# echo "${llvm_path}/lib" >> /etc/ld.so.conf
# ldconfig
# ldconfig -p

# 编译
# CMAKE_SUPPRESS_DEVELOPER_WARNINGS=ON # 抑制开发者警告
# CMAKE_WARN_DEPRECATED=OFF # 是否对已弃用的功能发出警告
# --mixin release 等价 --cmake-args -DCMAKE_BUILD_TYPE=Release
export MAKEFLAGS="-j4"
colcon build \
    --parallel-workers 2 \
    --merge-install \
    --mixin release \
    --cmake-force-configure \
    --cmake-args -DCMAKE_TOOLCHAIN_FILE=${script_dir}/toolchain.cmake

ls -alh