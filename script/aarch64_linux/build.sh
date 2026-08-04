#!/bin/bash -e

#脚本的运行目录
script_dir=$(
    cd $(dirname $0)
    pwd
)
work_dir=${script_dir}
# ros2版本
ros2_version=
# 源码目录
ros2_dir="${work_dir}/ros2"

function print_info() {
  echo "输出编译机器信息"
  lscpu
  cat /proc/cpuinfo
  whoami
  echo "输出目录信息"
  ls -alh
}

function print_help() {
  echo "-r ros2的版本 默认jazzy"
}

while getopts 'r:h' OPT; do
  case $OPT in
  r)
    ros2_version="${OPTARG}"
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

print_info

apt update -y
apt dist-upgrade -y

# 阻止交互式命令 使用默认的
export DEBIAN_FRONTEND=noninteractive

# 时区
apt -y install tzdata
ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

# https://docs.ros.org/en/jazzy/Installation/Alternatives/Ubuntu-Development-Setup.html

echo "设定locale"

locale  # check for UTF-8

apt install locales -y

locale-gen en_US en_US.UTF-8
update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

locale  # verify settings

echo "启用所需的仓库"
apt install software-properties-common -y
add-apt-repository universe -y

# 重来一次
apt update -y

apt install curl -y

export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F'"' '{print $4}')
curl -L -o ${work_dir}/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb"
dpkg -i ${work_dir}/ros2-apt-source.deb

apt update -y

echo "安装开发工具: $(lsb_release -r)"
apt install -y \
  python3-flake8-blind-except \
  python3-flake8-class-newline \
  python3-flake8-deprecated \
  python3-mypy \
  python3-pip \
  python3-pytest \
  python3-pytest-cov \
  python3-pytest-mock \
  python3-pytest-repeat \
  python3-pytest-rerunfailures \
  python3-pytest-runner \
  python3-pytest-timeout \
  ros-dev-tools \
  libssl-dev

llvm_path="/opt"
llvm_version="22.1.8"
if [[ ! -d ${llvm_path} ]]; then
  mkdir ${llvm_path}
fi

curl -OL https://github.com/llvm/llvm-project/releases/download/llvmorg-${llvm_version}/LLVM-${llvm_version}-Linux-ARM64.tar.xz
mv LLVM-${llvm_version}-Linux-ARM64.tar.xz ${llvm_path}
cd ${llvm_path}
tar -xf LLVM-${llvm_version}-Linux-ARM64.tar.xz
ln -s ${llvm_path}/LLVM-${llvm_version}-Linux-ARM64 ${llvm_path}/llvm

rm -rf ${llvm_path}/*.tar.xz


echo "下载源码"
rm -rf ${ros2_dir}
mkdir -p ${ros2_dir}/src
cd ${ros2_dir}

vcs import --input https://raw.githubusercontent.com/ros2/ros2/${ros2_version}-release/ros2.repos src

# 使用 rosdep 安装依赖
rosdep init
rosdep update
# 获取有哪些依赖
dep_data=$(rosdep install --from-paths src --ignore-src -y --skip-keys "fastcdr rti-connext-dds-6.0.1 urdfdom_headers" -s)
rosdep install --from-paths src --ignore-src -y --skip-keys "fastcdr rti-connext-dds-6.0.1 urdfdom_headers"

# Install colcon mixins
colcon mixin add default https://github.com/colcon/colcon-mixin-repository/raw/master/index.yaml
colcon mixin update default


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
