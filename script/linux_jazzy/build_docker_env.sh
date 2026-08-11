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
ros2_dir="/ros2_work_dir"
# 只构建依赖
dep_only="false"


function print_help() {
  echo "-r ros2的版本 默认jazzy"
  echo "-d 只生成依赖包"
}

while getopts 'r:d:h' OPT; do
  case $OPT in
  r)
    ros2_version="${OPTARG}"
    ;;
  d)
    dep_only="${OPTARG}"
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

# 先删除目录
rm -rf ${ros2_dir}
mkdir -p ${ros2_dir}

# 阻止交互式命令 使用默认的
export DEBIAN_FRONTEND=noninteractive

apt update -y
apt dist-upgrade -y

# 时区
apt -y install tzdata
ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

# https://docs.ros.org/en/jazzy/Installation/Alternatives/Ubuntu-Development-Setup.html

apt install curl wget xz-utils lsb-release locales -y

echo "$(lsb_release -si)"
if lsb_release -si 2>/dev/null | grep -qi ubuntu; then
    OS="Ubuntu"
else
    OS="Debian"
fi

echo "检测到系统: $OS"

cpuinfo="$(lscpu |grep aarch64 || true)"
if [[ -z "${cpuinfo}" ]]; then
  echo "当前架构amd64"
else
  echo "当前架构arm64"
fi
echo "当前ros2版本:${ros2_version}"


echo "设定locale"
echo "=== 检查当前locale设置 ==="
locale

if [ "$OS" = "Ubuntu" ]; then
    echo "=== Ubuntu系统配置 ==="
    # Ubuntu通常默认已启用en_US.UTF-8，直接生成即可
    locale-gen en_US en_US.UTF-8
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

else
    echo "=== Debian系统配置 ==="
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
    locale-gen
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
fi

# 设置当前shell环境变量（立即生效，不持久化）
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# 持久化 docker中没用
# echo "LANG=en_US.UTF-8" > /etc/default/locale
# echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
# echo "LANGUAGE=en_US.UTF-8" >> /etc/default/locale

echo "=== 当前locale设置 ==="
locale


echo "启用所需的仓库"
apt install software-properties-common -y
if [ "$OS" = "Ubuntu" ]; then
  add-apt-repository universe -y
fi

export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F'"' '{print $4}')
apt_source_url="https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb"
echo "ros2-apt-source.deb下载地址:${apt_source_url}"
curl -L -o ${work_dir}/ros2-apt-source.deb "${apt_source_url}"
ls -alh
if [ ! -f "${work_dir}/ros2-apt-source.deb" ]; then
  echo "错误：软件包下载失败，请检查网络或系统兼容性。"
  exit 1
fi
dpkg -i ${work_dir}/ros2-apt-source.deb


echo "安装开发工具: $(lsb_release -r)"
# 这里必须更新 ros2-apt-source.deb 这个更新了源
apt update -y
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
llvm_path="/opt"
llvm_version="22.1.8"
if [[ ! -d ${llvm_path} ]]; then
  mkdir ${llvm_path}
fi
if [[ -z ${cpuinfo} ]]; then
  curl -OL https://github.com/llvm/llvm-project/releases/download/llvmorg-${llvm_version}/LLVM-${llvm_version}-Linux-X64.tar.xz
  mv LLVM-${llvm_version}-Linux-X64.tar.xz ${llvm_path}
  cd ${llvm_path}
  tar -xf LLVM-${llvm_version}-Linux-X64.tar.xz
  ln -s ${llvm_path}/LLVM-${llvm_version}-Linux-X64 ${llvm_path}/llvm
else
  curl -OL https://github.com/llvm/llvm-project/releases/download/llvmorg-${llvm_version}/LLVM-${llvm_version}-Linux-ARM64.tar.xz
  mv LLVM-${llvm_version}-Linux-ARM64.tar.xz ${llvm_path}
  cd ${llvm_path}
  tar -xf LLVM-${llvm_version}-Linux-ARM64.tar.xz
  ln -s ${llvm_path}/LLVM-${llvm_version}-Linux-ARM64 ${llvm_path}/llvm
fi

rm -rf ${llvm_path}/*.tar.xz


echo "下载源码"
mkdir -p ${ros2_dir}/src
cd ${ros2_dir}

src_addr="https://raw.githubusercontent.com/ros2/ros2/${ros2_version}-release/ros2.repos"
echo "源码地址:${src_addr}"
vcs import --input ${src_addr} src

echo "安装colcon mixins"
colcon mixin add default https://github.com/colcon/colcon-mixin-repository/raw/master/index.yaml
colcon mixin update default

echo "使用rosdep安装依赖"
rosdep init
rosdep update

if [[ ${dep_only} == "true" ]]; then
  echo "下载并打包依赖"
  dep_data=$(rosdep install --from-paths src --ignore-src -y --skip-keys "fastcdr rti-connext-dds-6.0.1 urdfdom_headers" -s)
  echo "${dep_data}" > dep_data.txt
  echo "--------------------------------------------" >> dep_data.txt
  pip freeze >> dep_data.txt
  # 将依赖打包
  # 创建存放deb包的目录
  download_dir="${ros2_dir}/packages"
  rm -rf "${download_dir}"
  mkdir -p "${download_dir}"

  # 提取包名列表
  packages=$(grep -E "^\s*apt-get install -y" dep_data.txt | awk '{print $NF}' | tr '\n' ' ')

  # 设置apt下载目录
  echo "开始下载所有依赖包（包含依赖）..."
  apt-get install --download-only -y -o Dir::Cache::Archives="${download_dir}" ${packages}

  # 打包所有deb文件
  echo "打包所有deb文件..."
  tar -czvf deps_packages.tar.bz2 -C "${download_dir}" .

  echo "下载的包数量: $(ls -1 "${download_dir}"/*.deb 2>/dev/null | wc -l)"

  exit 0
fi

echo "安装依赖"
rosdep install --from-paths src --ignore-src -y --skip-keys "fastcdr rti-connext-dds-6.0.1 urdfdom_headers"


apt-get clean
rm -rf /var/lib/apt/lists/*