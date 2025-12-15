# 设置错误处理
$ErrorActionPreference = "Stop"

# 当前目录
if ($PSScriptRoot) {
    $script_dir = $PSScriptRoot
}
else {
    $script_dir = Split-Path $MyInvocation.MyCommand.Path -Parent
}
# 工作目录
$work_dir="$script_dir/ros"

# 打包日志
if (Test-Path "$work_dir/log") {
  7z a -t7z -mx=9 -m0=LZMA2 "$env:GITHUB_WORKSPACE/log_$env:FILE_DATE.7z" "$work_dir/log"
  echo "$env:GITHUB_WORKSPACE/log_$env:FILE_DATE.7z"
  ls  "$env:GITHUB_WORKSPACE/log_$env:FILE_DATE.7z"
}

# 打包结果
if (Test-Path "$work_dir/install") {
  7z a -t7z -mx=9 -m0=LZMA2 "$env:GITHUB_WORKSPACE/install_$env:FILE_DATE.7z" "$work_dir/install"
  echo "$env:GITHUB_WORKSPACE/install_$env:FILE_DATE.7z"
  ls  "$env:GITHUB_WORKSPACE/install_$env:FILE_DATE.7z"
}

# 打包整个工作环境
7z a -t7z -mx=9 -m0=LZMA2 "$env:GITHUB_WORKSPACE/ros2_$env:FILE_DATE.7z" "$work_dir"
echo "$env:GITHUB_WORKSPACE/ros2_$env:FILE_DATE.7z"
ls  "$env:GITHUB_WORKSPACE/ros2_$env:FILE_DATE.7z"

echo "LOG_FILE=$env:GITHUB_WORKSPACE/log_$env:FILE_DATE.7z" >> $env:GITHUB_ENV
echo "OUT_FILE=$env:GITHUB_WORKSPACE/install_$env:FILE_DATE.7z" >> $env:GITHUB_ENV
echo "ALL_ENV=$env:GITHUB_WORKSPACE/ros2_$env:FILE_DATE.7z" >> $env:GITHUB_ENV

echo "LOG_FILE=>${LOG_FILE}"
echo "OUT_FILE=>${OUT_FILE}"
echo "ALL_ENV=>${ALL_ENV}"
echo "=======================end"