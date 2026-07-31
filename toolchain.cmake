set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)
set(CMAKE_LINKER lld)

# rpath
set(_DEFAULT_RPATH "\$ORIGIN:\$ORIGIN/lib:\$ORIGIN/../lib:\$ORIGIN/..")

# 可选：指定编译器和链接器标志
set(CMAKE_EXE_LINKER_FLAGS "-fuse-ld=lld -rtlib=compiler-rt -stdlib=libc++ -unwindlib=libunwind -Wl,-rpath,\"${_DEFAULT_RPATH}\"")
set(CMAKE_SHARED_LINKER_FLAGS "-fuse-ld=lld -rtlib=compiler-rt -stdlib=libc++ -unwindlib=libunwind -Wl,-rpath,\"${_DEFAULT_RPATH}\"")
set(CMAKE_CXX_FLAGS "-stdlib=libc++ -Wno-c2y-extensions")
set(CMAKE_C_FLAGS "-Wno-c2y-extensions")

# clang-22
# -Wno-c2y-extensions 解决下面错误
# /workspace/build/google_benchmark_vendor/benchmark-1.8.3-prefix/src/benchmark-1.8.3/include/benchmark/benchmark.h:1446:30: error: '__COUNTER__' is a C2y extension [-Werror,-Wc2y-extensions]
# 1446 | #if defined(__COUNTER__) && (__COUNTER__ + 1 == __COUNTER__ + 0)