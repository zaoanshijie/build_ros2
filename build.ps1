# 参数定义
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("jazzy", "kilted")]
    [string]$distro = "jazzy",
    
    # [Parameter(Mandatory=$false)]
    # [ValidateSet("Debug", "Release", "RelWithDebInfo", "MinSizeRel")]
    # [string]$BuildType = "Release",
    
    [Parameter(Mandatory=$false)]
    [string]$github,
    
    [Parameter(Mandatory=$false)]
    [string]$raw,

    [Parameter(Mandatory=$false)]
    [switch]$notrmwork
)

# 设置错误处理
$ErrorActionPreference = "Stop"
# 增加Windows的最大路径长度
# New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force

# 当前目录
if ($PSScriptRoot) {
    $script_dir = $PSScriptRoot
}
else {
    $script_dir = Split-Path $MyInvocation.MyCommand.Path -Parent
}
# 工作目录
$work_dir="$script_dir/ros"


if ([string]::IsNullOrEmpty($github)) {
    $github = "https://github.com"
}
if ([string]::IsNullOrEmpty($raw)) {
    $raw = "https://raw.githubusercontent.com"
}

if ($distro -eq "jazzy") {
  $download_version="${distro}_patch_release_6"
}
elseif ($distro -eq "kilted") {
  $download_version="$distro"
}


# 重建工作目录
if ((Test-Path "$work_dir") -and (-not $notrmwork)) {
  rm -r -fo $work_dir
}

if (-not (Test-Path "$work_dir")) {
  mkdir $work_dir
}

cd $work_dir

echo "下载pixi"
if (-not (Test-Path "$work_dir/pixi.zip")) {
  iwr "$github/prefix-dev/pixi/releases/download/v0.61.0/pixi-x86_64-pc-windows-msvc.zip" -OutFile "$work_dir/pixi.zip"
}
Expand-Archive -Path "$work_dir/pixi.zip" -DestinationPath "$work_dir/pixi"
$env:PATH="$work_dir/pixi;$env:PATH"


echo "安装依赖"
irm $raw/ros2/ros2/refs/heads/$distro/pixi.toml -OutFile pixi.toml
pixi install -vvv

echo "加载msvc环境"
# 导入 Visual Studio DevShell 模块
Import-Module "C:/Program Files/Microsoft Visual Studio/2022/Enterprise/Common7/Tools/Microsoft.VisualStudio.DevShell.dll"
# 进入开发环境
Enter-VsDevShell -VsInstallPath "C:/Program Files/Microsoft Visual Studio/2022/Enterprise" -SkipAutomaticLocation -DevCmdArguments "-arch=amd64"

# 这种方式ci/cd不行 会报错
# "C:/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Auxiliary/Build/vcvars64.bat"


$repo_addr="$raw/ros2/ros2/$download_version/ros2.repos"
echo "repos addr: $repo_addr"

# 加载pixi环境
pixi shell-hook -s powershell > "$work_dir/pixi_env.ps1"
. "$work_dir/pixi_env.ps1"

# 报错模块不存在
# pip install catkin_pkg rospkg

echo "编译"
mkdir $work_dir/src
vcs import --input $repo_addr $work_dir/src

# iceoryx 在patch6 会报错
$iceoryx_hoofs_time_fix="$work_dir/src/eclipse-iceoryx/iceoryx/iceoryx_hoofs/platform/win/source/time.cpp"
if ((Test-Path $iceoryx_hoofs_time_fix) -and ($distro -eq "jazzy")) {
  # $newContent = $content -replace $pattern, $replacement
  # 读取文件内容
  $content = Get-Content $iceoryx_hoofs_time_fix -Raw
  # 替换
  $content = $content -replace "`"iceoryx_hoofs/platform/time.hpp`"", "`"iceoryx_hoofs/platform/time.hpp`"`n#include <chrono>"
  # 回写文件
  Set-Content "$iceoryx_hoofs_time_fix" -Value $content -Encoding UTF8 -NoNewline
}
# 这里需要处理一下 FASTDDS 他有一个警告视为错误
$fastdds_cmake="$work_dir/src/eProsima/Fast-DDS/CMakeLists.txt"
if (Test-Path $fastdds_cmake) {
  # $newContent = $content -replace $pattern, $replacement
  # 读取文件内容
  $content = Get-Content $fastdds_cmake -Raw
  # 替换
  $content = $content -replace '\$\{SANITIZER_THREAD\} EQUAL -1', 'FALSE'
  # 回写文件
  Set-Content "$fastdds_cmake" -Value $content -Encoding UTF8 -NoNewline
}

# 编译
# CMAKE_SUPPRESS_DEVELOPER_WARNINGS=ON # 抑制开发者警告
# CMAKE_WARN_DEPRECATED=OFF # 是否对已弃用的功能发出警告
#  --cmake-args -DCMAKE_BUILD_TYPE=Release
colcon build --merge-install

if ($LASTEXITCODE -ne 0) {
    throw "命令执行失败，退出码: $LASTEXITCODE"
}


echo "end"