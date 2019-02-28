# This is a script for windows, but it uses bash syntax.
# You should run it using MINGW64 (ie git-bash from git for windows)
# Prerequisite:
# * install cmake and have it in your PATH
#   PATH=$PATH:/d/dev/cmake-3.13.4-win64-x64/bin/
# * have devenv in your PATH
#   PATH=$PATH:/c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio\ 14.0/Common7/IDE/

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
    # No wget on MINGW64, using curl instead (-L flag to follow redirect)
    cd $ROOT
    curl -L https://github.com/openexr/openexr/releases/download/v2.3.0/ilmbase-2.3.0.tar.gz --output ilmbase-2.3.0.tar.gz

#- task: ExtractFiles@1
#  inputs:
#    archiveFilePatterns: '*.tar.gz'
#    destinationFolder: ilmbase-2.3.0
#    cleanDestinationFolder: true
#  displayName: Extract ILMLab archive
    # Extract
    tar -xvf ilmbase-2.3.0.tar.gz

#- script: |
#    sudo mkdir /usr/local/lib/ilmbase
#    ls
#    cd ilmbase-2.3.0
#    ./bootstrap
#    ./configure --prefix=/usr/local/lib/ilmbase
#    sudo make -j4
#    sudo make install
#    cd /usr/local/lib/ilmbase
#    sudo tar -cf ilmbase-2.3.0.tar *
#    sudo gzip ilmbase-2.3.0.tar
#  displayName: Build ILMBase
#  workingDirectory: ilmbase-2.3.0
    # Following install instructions from ilmbase/README.md
    cd "$ROOT/ilmbase-2.3.0"
    mkdir "$ROOT/lib/ilmbase"
    # Create solution
    cmake -DCMAKE_INSTALL_PREFIX="$ROOT/lib/ilmbase" \
          -G "$VS_VERSION" -B build
    # Build
    cmake --build ./build --target INSTALL --config release


#- script: |
#    wget https://github.com/openexr/openexr/releases/download/v2.3.0/pyilmbase-2.3.0.tar.gz
#  displayName: Download PyILMLab archive
    cd $ROOT
    curl -L https://github.com/openexr/openexr/releases/download/v2.3.0/pyilmbase-2.3.0.tar.gz --output pyilmbase-2.3.0.tar.gz

#- task: ExtractFiles@1
#  inputs:
#    archiveFilePatterns: '*.tar.gz'
#    destinationFolder: pyilmbase-2.3.0
#    cleanDestinationFolder: true
#  displayName: Extract PyILMLab archive
    tar -xvf pyilmbase-2.3.0.tar.gz

#- script: |
#    sudo mkdir /usr/local/lib/pyilmbase
#    sudo pip install numpy
#    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib/ilmbase/lib
#    cd pyilmbase-2.3.0
#    ./configure --prefix=/usr/local/lib/pyilmbase --with-ilmbase-prefix=/usr/local/lib/ilmbase
#    sudo make -j4
#    sudo make install
#    cd /usr/local/lib/pyilmbase
#    sudo tar -czf pyilmbase-2.3.0.tar.gz *
#  displayName: Build PyILMBase
#  workingDirectory: pyilmbase-2.3.0
    # Following install instructions from ilmbase/README.md
    cd "$ROOT/pyilmbase-2.3.0"
    mkdir "$ROOT/lib/pyilmbase"
    # Create solution
    cmake -DILMBASE_PACKAGE_PREFIX="$ROOT/lib/ilmbase" \
          -DCMAKE_INSTALL_PREFIX="$ROOT/lib/pyilmbase" \
          -G "$VS_VERSION" -B build
    # Build
    cmake --build ./build --target INSTALL --config release

- script: |
    wget https://github.com/openexr/openexr/releases/download/v2.3.0/openexr-2.3.0.tar.gz
  displayName: Download OpenEXR archive

- task: ExtractFiles@1
  inputs:
    archiveFilePatterns: '*.tar.gz'
    destinationFolder: openexr-2.3.0
    cleanDestinationFolder: true
  displayName: Extract OpenEXR archive

- script: |
    ls
    cd openexr-2.3.0
    sudo mkdir /usr/local/lib/openexr
    ./bootstrap
    ./configure --prefix=/usr/local/lib/openexr --with-ilmbase-prefix=/usr/local/lib/ilmbase --enable-imfexamples
    sudo make -j4
    sudo make install
    cd /usr/local/lib/openexr
    sudo tar -czf openexr-2.3.0.tar.gz *
  displayName: Build OpenEXR
  workingDirectory: openexr-2.3.0

- script: |
    wget https://github.com/alembic/alembic/archive/1.7.10.tar.gz
  displayName: Download Alembic archive

- task: ExtractFiles@1
  inputs:
    archiveFilePatterns: '*.tar.gz'
    destinationFolder: alembic-1.7.10
    cleanDestinationFolder: true
  displayName: Extract Alembic archive

- script: |
    sudo mkdir alembic
    ls
    cd alembic-1.7.10
    ./bootstrap
    cmake -DUSE_HDF5=ON -DUSE_EXEMPLES=ON -DALEMBIC_LIB_USES_TR1=ON -DALEMBIC_LIB_USES_BOOST=OFF -DILM_INCLUDE_DIR=/usr/local/lib/ilmbase/include/OpenEXR ../alembic-1.7.10 -DCMAKE_INSTALL_PREFIX=/usr/local/lib/alembic
    sudo make -j4
    sudo make install
    cd /usr/local/lib/alembic
    sudo tar -czf alembic-1.7.10.tar.gz *
  displayName: Build Alembic
  workingDirectory: alembic-1.7.10

- script: |
    ls
    cp /usr/local/lib/openexr/openexr-2.3.0.tar.gz $(Build.ArtifactStagingDirectory)
    cp /usr/local/lib/ilmbase/ilmbase-2.3.0.tar.gz $(Build.ArtifactStagingDirectory)
    cp /usr/local/lib/pyilmbase/pyilmbase-2.3.0.tar.gz $(Build.ArtifactStagingDirectory)
    cp /usr/local/lib/alembic/alembic-1.7.10.tar.gz $(Build.ArtifactStagingDirectory)
    ls $(Build.ArtifactStagingDirectory)
  displayName: Prepare Release

- task: GitHubRelease@0
  inputs:
    gitHubConnection: GitHub connection 1
    repositoryName: cgwire/generic-builds
    action: create
    target: 3de0dbd1407c8bc44b373fe425c323d8da02f3f1
    tagSource: auto
    tag: 2.3.0
    assetUploadMode: 'replace'
  displayName: Release to Github
