# This is a script for windows, but it uses bash syntax.
# You should run it using MINGW64 (ie git-bash from git for windows)
# Prerequisite:
# * install cmake and have it in your PATH
#   PATH=${PATH}:/d/dev/cmake-3.13.4-win64-x64/bin/
# * have devenv in your PATH
#   PATH=${PATH}:/c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio\ 14.0/Common7/IDE/
# * have mt in your PATH (boost)
#   PATH=PATH=${PATH}:/c/Program\ Files\ \(x86\)/Microsoft\ SDKs/Windows/v7.1A/Bin


ROOT=$( pwd )
VS_VERSION="Visual Studio 14 2015 Win64"

#trigger:
#- master

#pool:
#  vmImage: 'Ubuntu-16.04'


#steps:

#- script: |
#    sudo apt update
#    sudo apt install -y wget python python-pip libboost-all-dev libhdf5-serial-dev
#  displayName: Install dependencies

#- script: |
#    wget https://github.com/openexr/openexr/releases/download/v2.3.0/ilmbase-2.3.0.tar.gz
#  displayName: Download ILMLab archive

    # ZLIB ---------------------------------------------------------------------
    # No wget on MINGW64, using curl instead (-L flag to follow redirect)
    curl -L https://zlib.net/zlib1211.zip --output zlib1211.zip
    unzip zlib1211.zip
    cmake -G "${VS_VERSION}"                                                  \
          -S "${ROOT}/zlib-1.2.11"                                                   \
          -B "${ROOT}/zlib-1.2.11/build"                                             \
          -DCMAKE_INSTALL_PREFIX="${ROOT}/dep/zlib"

    cmake --build zlib-1.2.11/build --target INSTALL --config release

    # I found zlib1.dll to be already installed on my system,
    # so getting the headers is enough, I don't build the library
    # --------------------------------------------------------------------------

    # BOOST --------------------------------------------------------------------
    curl -L https://sourceforge.net/projects/boost/files/boost/1.60.0/boost_1_60_0.zip/download --output boost_1_60_0.zip
    unzip boost_1_60_0.zip
    cd boost_1_60_0
    ./bootstrap.bat
    #./b2  # Builds boost -> coffee time !
    #./b2 --prefix=${ROOT}/toto --with-python toolset=msvc address-model=64 link=shared variant=release install
    #b2 --prefix="${ROOT}/dep/Boost" --with-python -j8 --build-type=complete link=static,shared address-model=64 install
    ./b2 --prefix="${ROOT}/dep/Boost" --with-python --with-program_options -j8 toolset=msvc-14.0 link=static,shared address-model=64 install
    # Note that I experienced some difficulties building the boost dll
    # We have to rename boost libs for cmake to find them (b2 might have an argument for that)
    cd ${ROOT}
    # --------------------------------------------------------------------------

    # OPENEXR ------------------------------------------------------------------
    # We get the whole source code, because most releases has their CMAKE files stripped of
    curl -L https://github.com/openexr/openexr/archive/v2.3.0.tar.gz --output openexr.tar.gz
    # Extract
    tar -xvf openexr.tar.gz

    # Deploy bug https://github.com/openexr/openexr/issues/355
    sed -i "s/OPENEXR_PACKAGE_PREFIX/CMAKE_INSTALL_PREFIX/g" openexr/OpenEXR/IlmImf/CMakeLists.txt

    cmake -G "${VS_VERSION}"                                                  \
          -S "${ROOT}/openexr"                                                \
          -B "${ROOT}/openexr/build"                                          \
          -DCMAKE_INSTALL_PREFIX="${ROOT}/dep/openexr"                        \
          -DZLIB_INCLUDE_DIR="${ROOT}/dep/zlib/include"                       \
          -DZLIB_LIBRARY="${ROOT}/dep/zlib/lib/zlib.lib"                      \
          -DBOOST_ROOT="${ROOT}/dep/Boost/"                                   \
          -DBoost_INCLUDE_DIR="${ROOT}/dep/Boost/include/boost-1_60/"         \
          -DBoost_LIBRARIES="${ROOT}/dep/Boost/lib"                           \
          -DPYTHON_INCLUDE_DIR="${ADSK_3DSMAX_x64_2018}/python/include"       \
          -DPYTHON_LIBRARY="${ADSK_3DSMAX_x64_2018}/python/libs/python27.lib" \
          -DPYTHON_EXECUTABLE="${ADSK_3DSMAX_x64_2018}/3dsmaxpy.exe"          \
          -DNUMPY_INCLUDE_DIRS="${ADSK_3DSMAX_x64_2018}/python/Lib/site-packages/numpy/core/include"

        # Attention à bien utiliser les headers générés par b2 et pas ceux des sources de boost !!!

#          -DOPENEXR_BUILD_OPENEXR=OFF                              \
    # Building for max requires to point to the max distributed python.lib

    cmake --build openexr/build --target INSTALL --config release

    # --------------------------------------------------------------------------

    # HDF5 ---------------------------------------------------------------------
    #curl -L https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.5/src/hdf5-1.10.5.tar.gz --output hdf5.tar.gz
    curl -L https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.5/src/hdf5-1.10.5.tar.gz --output hdf5.tar.gz
    tar -xvf hdf5.tar.gz

    cmake -G "${VS_VERSION}"                                                  \
          -S "${ROOT}/hdf5"                                                   \
          -B "${ROOT}/hdf5/build"                                             \
          -DCMAKE_INSTALL_PREFIX="${ROOT}/dep/hdf5"

    cmake --build hdf5/build --target INSTALL --config release
    # --------------------------------------------------------------------------

    # ALEMBIC ------------------------------------------------------------------
    #curl -L https://github.com/alembic/alembic/archive/1.7.10.tar.gz --output alembic.tar.gz
    curl -L https://github.com/alembic/alembic/archive/1.7.10.tar.gz --output alembic.tar.gz
    tar -xvf alembic.tar.gz

    # Build Alembic.dll with version number (to avoid conflicts)
    sed -i "s/SET_TARGET_PROPERTIES(Alembic PROPERTIES/SET_TARGET_PROPERTIES(Alembic PROPERTIES OUTPUT_NAME \${PROJECT_NAME}_\${PROJECT_VERSION}/" alembic/lib/Alembic/CMakeLists.txt

    cmake -G "${VS_VERSION}"                                                  \
          -S "${ROOT}/alembic"                                                \
          -B "${ROOT}/alembic/build"                                          \
          -DUSE_PYALEMBIC=ON                                                  \
          -DUSE_HDF5=OFF                                                       \
          -DUSE_TESTS=OFF                                                      \
          -DILMBASE_ROOT="${ROOT}/dep/openexr"                                \
          -DHDF5_ROOT="${ROOT}/dep/hdf5"                                      \
          -DHDF5_DIR="${ROOT}/dep/hdf5/cmake/hdf5"                                      \
          -DBOOST_ROOT="${ROOT}/dep/Boost/"                                   \
          -DZLIB_ROOT="${ROOT}/dep/zlib"                                       \
          -DALEMBIC_PYILMBASE_INCLUDE_DIRECTORY="${ROOT}/dep/openexr/include"          \
          -DALEMBIC_PYILMBASE_PYIMATH_LIB="${ROOT}/dep/openexr/lib/PyImath.lib"          \
          -DALEMBIC_PYIMATH_MODULE_DIRECTORY="${ROOT}/dep/openexr/lib/python2.7/site-packages/" \
          -DPYTHON_EXECUTABLE="${ADSK_3DSMAX_x64_2018}/3dsmaxpy.exe"                            \
          -DPYTHON_INCLUDE_DIR="${ADSK_3DSMAX_x64_2018}/python/include"                         \
          -DPYTHON_LIBRARY="${ADSK_3DSMAX_x64_2018}/python/libs/python27.lib"                   \
          -DCMAKE_INSTALL_PREFIX="${ROOT}/dep/alembic"

          -DZLIB_INCLUDE_DIR="${ROOT}/dep/zlib/include"                       \
          -DZLIB_LIBRARY="${ROOT}/dep/zlib/lib/zlib.lib"                      \
          -DBoost_INCLUDE_DIR="${ROOT}/dep/Boost/include/boost-1_60/"           \
          -DBoost_LIBRARIES="${ROOT}/dep/Boost/lib"                           \
          #-DBOOST_INCLUDEDIR="${ROOT}/dep/Boost/include/boost-1_60/"          \
          #-DBOOST_LIBRARYDIR="${ROOT}/dep/Boost/lib"                          \
          #-DUSE_STATIC_BOOST=1                                                        \
    cmake --build alembic/build --target INSTALL --config release

    # --------------------------------------------------------------------------









git clone https://github.com/Microsoft/vcpkg.git
./bootstrap-vcpkg.bat
./vcpkg.exe integrate install
./vcpkg install alembic:x64-Windows
