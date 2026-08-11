#!/bin/bash -e

#脚本的运行目录
script_dir=$(
    cd $(dirname $0)
    pwd
)

work_dir="${script_dir}/dep_lib"
# 安装目录
install="${script_dir}/install"

# 安装依赖
apt update 
# apt install --reinstall -y autoconf automake libtool pkg-config flex bison pkg-config m4 libxml2-dev libpopt-dev liburcu-dev

# apt install liblttng-ust-python-agent1t64 liblttng-ust1t64 lttng-tools libgl1 libopengl0
echo "编译assimp"
cd ${work_dir}
assimp_version="v6.0.4"
assimp_build="${script_dir}/assimp_build"
assimp_src="${script_dir}/assimp"
git clone https://github.com/assimp/assimp.git --branch ${assimp_version}
rm -rf ${assimp_build} && mkdir -p ${assimp_build}

cmake -S "${assimp_src}" -B "${assimp_build}" \
        -DBUILD_SHARED_LIBS=ON \
        -DASSIMP_BUILD_TESTS=OFF \
        -DASSIMP_BUILD_DOCS=OFF \
        -DASSIMP_INSTALL=ON \
        -DASSIMP_BUILD_ZLIB=ON \
        -DASSIMP_BUILD_DRACO=ON  \
        -DASSIMP_BUILD_MINIZIP=ON  \
        -DASSIMP_HUNTER_ENABLED=OFF \
        -DCMAKE_INSTALL_PREFIX=${install} \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DCMAKE_CXX_FLAGS="-Wno-error=array-bounds" \
        -DCMAKE_TOOLCHAIN_FILE=${script_dir}/toolchain.cmake

cmake --build "${assimp_build}" --config Release -j8
cmake --install "${assimp_build}"



echo "编译console_bridge"
cd ${work_dir}
console_bridge_version="1.0.1"
console_bridge_build="${script_dir}/console_bridge_build"
console_bridge_src="${script_dir}/console_bridge"
git clone https://github.com/ros/console_bridge.git --branch ${console_bridge_version}

cmake -S "${console_bridge_src}" -B "${console_bridge_build}" \
      -DCMAKE_INSTALL_PREFIX=${install} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_TOOLCHAIN_FILE=${script_dir}/toolchain.cmake

cmake --build "${console_bridge_build}" --config Release -j8
cmake --install "${console_bridge_build}"


# apt install -y liblttng-ust-python-agent1t64 liblttng-ust1t64 lttng-tools libgl1 libopengl0 \
#     libconsole-bridge1.0 libgsm1 libyaml-cpp0.8 \
#     libopencv-core410 libopencv-video410 libopencv-imgproc410 libopencv-imgcodecs410 libopencv-highgui410 libspdlog1.15 libtinyxml2-11