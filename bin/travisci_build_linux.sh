#!/bin/sh

set -ev

# Environment variables
export CXXFLAGS="-mno-avx"
if [ "$CXX" = "g++" ]; then
    export CC=/usr/bin/gcc-$GCC_VERSION
    export CXX=/usr/bin/g++-$GCC_VERSION
else
    export CC=/usr/bin/clang-$LLVM_VERSION
    export CXX=/usr/bin/clang++-$LLVM_VERSION
fi

##########   test with cblas   ##########
mkdir build_cblas
cd build_cblas
cmake .. -DBTAS_ASSERT_THROWS=ON -DUSE_CBLAS=ON -DBOOST_INCLUDEDIR=/usr/include/boost -DBOOST_LIBRARYDIR=/usr/lib
make VERBOSE=1
make check VERBOSE=1
cd ..

########## test without cblas ##########
mkdir build
cd build
cmake .. -DBTAS_ASSERT_THROWS=ON -DBoost_NO_BOOST_CMAKE=ON -DBOOST_INCLUDEDIR=/usr/include/boost -DBOOST_LIBRARYDIR=/usr/lib
make VERBOSE=1
make check VERBOSE=1
cd ..

