set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# 指定交叉编译的编译器
set(TRIPLE ${CMAKE_SYSTEM_PROCESSOR}-linux-gnu)

set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)
set(CMAKE_LINKER lld)

# rpath
set(_DEFAULT_RPATH "\$ORIGIN:\$ORIGIN/lib:\$ORIGIN/../lib:\$ORIGIN/..")

# 可选：指定编译器和链接器标志
set(CMAKE_EXE_LINKER_FLAGS "-fuse-ld=lld -rtlib=compiler-rt -stdlib=libc++ -unwindlib=libunwind -Wl,-rpath,\"${_DEFAULT_RPATH}\"")
set(CMAKE_SHARED_LINKER_FLAGS "-fuse-ld=lld -rtlib=compiler-rt -stdlib=libc++ -unwindlib=libunwind -Wl,-rpath,\"${_DEFAULT_RPATH}\"")
set(CMAKE_CXX_FLAGS "-stdlib=libc++")
