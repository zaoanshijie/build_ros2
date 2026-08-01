# set(CMAKE_SYSTEM_NAME Linux)
# set(CMAKE_SYSTEM_PROCESSOR aarch64)

# set(CMAKE_C_COMPILER clang)
# set(CMAKE_CXX_COMPILER clang++)
# set(CMAKE_LINKER lld)

set(LLVM_INSTALL_DIR "/opt/llvm")

# rpath
set(_DEFAULT_RPATH "\$ORIGIN:\$ORIGIN/lib:\$ORIGIN/../lib:\$ORIGIN/..")
set(CMAKE_EXE_LINKER_FLAGS "-Wl,-rpath,\"${_DEFAULT_RPATH}\"")
set(CMAKE_SHARED_LINKER_FLAGS "-Wl,-rpath,\"${_DEFAULT_RPATH}\"")

# 可选：指定编译器和链接器标志
# set(CMAKE_EXE_LINKER_FLAGS "-fuse-ld=lld -lc++ -lc++abi -rtlib=compiler-rt -stdlib=libc++ -unwindlib=libunwind -Wl,-rpath,\"${_DEFAULT_RPATH}\"")
# set(CMAKE_SHARED_LINKER_FLAGS "-fuse-ld=lld -lc++ -lc++abi -rtlib=compiler-rt -stdlib=libc++ -unwindlib=libunwind -Wl,-rpath,\"${_DEFAULT_RPATH}\"")
# set(CMAKE_CXX_FLAGS "-stdlib=libc++ -Wno-c2y-extensions -Wno-deprecated-literal-operator")
# set(CMAKE_C_FLAGS "-Wno-c2y-extensions -Wno-deprecated-literal-operator")

# clang-22
# -Wno-c2y-extensions 解决下面错误
# /workspace/build/google_benchmark_vendor/benchmark-1.8.3-prefix/src/benchmark-1.8.3/include/benchmark/benchmark.h:1446:30: error: '__COUNTER__' is a C2y extension [-Werror,-Wc2y-extensions]
# 1446 | #if defined(__COUNTER__) && (__COUNTER__ + 1 == __COUNTER__ + 0)

# -Wno-deprecated-literal-operator
# foonathan_memory_vendor 的-werrord的错误
# Clang 17+引入的新警告
# 空格的区别
# ❌ 旧写法：operator"" _KiB
# ✅ 新写法：operator""_KiB

# ld.lld: error: undefined symbol
# -lc++ -lc++abi