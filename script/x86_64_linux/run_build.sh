#!/bin/bash -e

#脚本的运行目录
script_dir=$(
    cd $(dirname $0)
    pwd
)
# ros2版本
ros2_version=
# docker镜像(编译环境)
build_docker=
# 目标架构(x86_64 aarch64)
build_target=
# 源码目录
docker_ros2_dir="/ros2_work_dir"

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
  echo "-i docker镜像(编译环境)"
  echo "-t 目标架构(x86_64 aarch64)"
}

while getopts 'r:i:t:h' OPT; do
  case $OPT in
  r)
    ros2_version="${OPTARG}"
    ;;
  i)
    build_docker="${OPTARG}"
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

if [[ -z ${build_docker} ]]; then
  echo "docker镜像不能为空"
  print_help
  exit 1
fi
if [[ -z ${build_target} ]]; then
  echo "编译目标架构不能为空"
  print_help
  exit 1
fi
if [[ ! -f ${build_docker} ]]; then
  echo "docker镜像不存在:${build_docker}"
  exit 1
fi
print_info

echo "导入 Docker 镜像..."
docker load --input ${build_docker}
# 获取导入的镜像名称
IMAGE_NAME=$(docker images --format "{{.Repository}}:{{.Tag}}" | head -n 1)
echo "成功导入镜像: $IMAGE_NAME"

echo "启动容器:${IMAGE_NAME}"
docker run -itd \
  --platform linux/${build_target} \
  --name ros2-build-${build_target} \
  -v ${script_dir}:/workspace \
  ${IMAGE_NAME} \
  /bin/bash

# 等待容器启动
sleep 5

echo "执行编译"
docker exec ros2-build-${build_target} /bin/bash -c "echo '容器运行成功,开始执行${build_target}编译'"
docker exec ros2-build-${build_target} /bin/bash -c "cp -r /workspace/* ${docker_ros2_dir}"
docker exec ros2-build-${build_target} /bin/bash -c "cd ${docker_ros2_dir} && /bin/bash build.sh -r ${ros2_version} -t ${build_target}"
docker exec ros2-build-${build_target} /bin/bash -c "cd ${docker_ros2_dir} && tar -cavf ros2.tar.bz2 install && mv ros2.tar.bz2 /workspace"
docker exec ros2-build-${build_target} /bin/bash -c "cd ${docker_ros2_dir} && cp dep_data.txt /workspace"
docker exec ros2-build-${build_target} /bin/bash -c "echo '${build_target}编译执行完毕'"
# 清理容器
docker stop ros2-build-${build_target}
docker rm ros2-build-${build_target}