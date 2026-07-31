#!/bin/bash -e

#脚本的运行目录
script_dir=$(
    cd $(dirname $0)
    pwd
)
# 工作目录
work_dir="${script_dir}"
# ros2版本
ros2_version=
# 目标架构(amd64 arm64)
build_target=

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
echo "设置llvm环境"
export PATH=/opt/llvm/bin:${PATH}
clang --version

if [[ -z ${ros2_version} ]]; then
  ros2_version="jazzy"
  echo "设置默认的ros2版本: ${ros2_version}"
fi
if [[ -z ${build_target} ]]; then
  echo "编译目标架构不能为空"
  print_help
  exit 1
fi

# https://docs.ros.org/en/jazzy/Installation/Alternatives/Ubuntu-Development-Setup.html

mkdir -p ${work_dir}/src
cd ${work_dir}

vcs import --input https://raw.githubusercontent.com/ros2/ros2/${ros2_version}-release/ros2.repos src

# 使用 rosdep 安装依赖
apt update
rosdep init
rosdep update
rosdep install --from-paths src --ignore-src -y --skip-keys "fastcdr rti-connext-dds-6.0.1 urdfdom_headers"

# Install colcon mixins
colcon mixin add default https://github.com/colcon/colcon-mixin-repository/raw/master/index.yaml
colcon mixin update default

# 编译
# CMAKE_SUPPRESS_DEVELOPER_WARNINGS=ON # 抑制开发者警告
# CMAKE_WARN_DEPRECATED=OFF # 是否对已弃用的功能发出警告
# --mixin release 等价 --cmake-args -DCMAKE_BUILD_TYPE=Release
colcon build \
    --merge-install \
    --mixin release \
    --cmake-force-configure \
    --cmake-args -DCMAKE_TOOLCHAIN_FILE=${work_dir}/toolchain.cmake

ls -alh
echo "end"
# tar -cavf install.tar.bz2 install
# tar -cavf log.tar.bz2 log

# mv install.tar.bz2 ${script_dir}/install.tar.bz2
# mv log.tar.bz2 ${script_dir}/log.tar.bz2