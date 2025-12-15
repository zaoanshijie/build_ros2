#!/bin/bash -e

#脚本的运行目录
script_dir=$(
    cd $(dirname $0)
    pwd
)
GITHUB_ENV_FILE="${1:-/dev/null}"  # 如果没有传入参数，则输出到 /dev/null

FILE_DATE=$(date +'%Y-%m-%d_%H%M')
# 工作目录
work_dir="${script_dir}/ros2"
cd "${work_dir}"
if [[ -d "${work_dir}/log" ]];then
  tar -caf "log.tar.bz2" log
  mv "log.tar.bz2" ${script_dir}/log_${FILE_DATE}.tar.bz2
  ls -al ${script_dir}/log_${FILE_DATE}.tar.bz2
fi

if [[ -d "${work_dir}/install" ]];then
  tar -caf "install.tar.bz2" install
  mv "install.tar.bz2" ${script_dir}/install_${FILE_DATE}.tar.bz2
  ls -al ${script_dir}/install_${FILE_DATE}.tar.bz2
fi

# 打包整个工作目录
cd ${script_dir}
tar -caf "ros2_${FILE_DATE}.tar.bz2" ros2
ls -al ${script_dir}/ros2_${FILE_DATE}.tar.bz2

echo "LOG_FILE=$script_dir/log_${FILE_DATE}.tar.bz2" >> $GITHUB_ENV_FILE
echo "OUT_FILE=$script_dir/install_${FILE_DATE}.tar.bz2" >> $GITHUB_ENV_FILE
echo "ALL_ENV=$script_dir/ros2_${FILE_DATE}.tar.bz2" >> $GITHUB_ENV_FILE

echo "LOG_FILE=>${LOG_FILE}"
echo "OUT_FILE=>${OUT_FILE}"
echo "ALL_ENV=>${ALL_ENV}"
echo "=======================end"