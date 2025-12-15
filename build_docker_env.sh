#!/bin/bash -e

#脚本的运行目录
script_dir=$(
    cd $(dirname $0)
    pwd
)
work_dir=${script_dir}

# https://docs.ros.org/en/jazzy/Installation/Alternatives/Ubuntu-Development-Setup.html

echo "设定locale"

locale  # check for UTF-8

apt update -y
apt dist-upgrade -y
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

echo "安装开发工具"
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

echo "安装clang:${cpuinfo}"
cpuinfo=$(lscpu |grep aarch64 || true)
clang_path="/opt"
if [[ ! -d ${clang_path} ]]; then
  mkdir ${clang_path}
fi
if [[ -z ${cpuinfo} ]]; then
  curl -OL https://github.com/llvm/llvm-project/releases/download/llvmorg-22.1.8/LLVM-22.1.8-Linux-X64.tar.xz
  mv LLVM-22.1.8-Linux-X64.tar.xz ${clang_path}
  cd ${clang_path}
  tar -xf LLVM-22.1.8-Linux-X64.tar.xz
  ln -s ${clang_path}/LLVM-22.1.8-Linux-X64 ${clang_path}/llvm
else
  curl -OL https://github.com/llvm/llvm-project/releases/download/llvmorg-22.1.8/LLVM-22.1.8-Linux-ARM64.tar.xz
  mv LLVM-22.1.8-Linux-ARM64.tar.xz ${clang_path}
  cd ${clang_path}
  tar -xf LLVM-22.1.8-Linux-ARM64.tar.xz
  ln -s ${clang_path}/LLVM-22.1.8-Linux-ARM64 ${clang_path}/llvm
fi

rm -rf ${clang_path}/*.tar.xz

echo 'export PATH=${clang_path}/llvm/bin:$PATH' >> ~/.bashrc

apt-get clean
rm -rf /var/lib/apt/lists/*