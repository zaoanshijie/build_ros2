@echo off 
chcp 65001

set script_dir=%~dp0
if "!script_dir:~-1!"=="\" (
    set "script_dir=!script_dir:~0,-1!"
)

@REM 工作目录
set "work_dir=%script_dir%/ros2"
@REM ros2版本
set "ros2_version="
@REM github地址/镜像
set "mirror_github="
set "mirror_raw="

:parse_args
if "%~1"=="" goto :end_parse_args

if "%~1"=="-r" (
    set "lib_static=1"
) else if "%~1"=="-g" (
    set "lib_reload=1"
) else if "%~1"=="-w" (
    set "lib_default_mirror=1"
) else (
    echo invalid option: %~1
    goto :print_help
)

shift
GOTO :parse_args

:print_help
echo "-r  ros2的版本 默认jazzy"
echo "-w  raw的镜像 为空则是默认的官方地址"
echo "-g  github地址/镜像 为空则是默认的官方地址"
exit /b

:end_parse_args


if "!ros2_version!"=="" (
  set "ros2_version=jazzy"
  echo "设置默认的ros2版本: %ros2_version%"
)
if "!mirror_github!"=="" (
  set "mirror_github=https://github.com"
)
if "!mirror_raw!"=="" (
  set "mirror_raw=https://raw.githubusercontent.com"
)


if exist "%work_dir%" (
    rd /S /Q "%work_dir%"
)
mkdir %lib_work_dir%

dir "C:/Program Files/Git/bin"
echo "============"
dir "C:/Program Files/Git"

cd %lib_work_dir%
mkdir src

@REM 下载pixi
curl -OL %mirror_github%/prefix-dev/pixi/releases/download/v0.61.0/pixi-x86_64-pc-windows-msvc.zip
7z x pixi-x86_64-pc-windows-msvc.zip -opixi
set "PATH=%lib_work_dir%/pixi;%PATH%"

@REM 安装依赖
curl -OL %mirror_raw%/ros2/ros2/refs/heads/jazzy/pixi.toml
pixi install


@REM 加载msvc环境
call "C:/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Auxiliary/Build/vcvars64.bat"

@REM 编译
set "repo_addr=%mirror_raw%/ros2/ros2/%ros2_version%/ros2.repos"
echo "repos addr: %repo_addr%"
curl -OL %repo_addr%

pixi shell
vcs import --input %work_dir%/ros2.repos src

@REM 这里需要处理一下 FASTDDS 他有一个警告视为错误

colcon build --merge-install