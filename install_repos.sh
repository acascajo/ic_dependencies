#!/bin/bash
set -e  

HOME=$PWD/..
echo "User's home set to $HOME"
sleep 2

# Repository list
REPOS=(
  "https://github.com/icl-utk-edu/papi.git"
  "https://github.com/firedrakeproject/glpk.git"
  "https://github.com/redis/hiredis.git"
  "https://github.com/redis/redis.git"
  "https://github.com/json-c/json-c.git"
)

# Current dir
CDIR=$(pwd)

# PREFIX
INSTALL_DIR="$HOME/local/"
mkdir -p $INSTALL_DIR

# Download all in a tmp folder
mkdir -p tmp
cd tmp

# Download and installation
for REPO in "${REPOS[@]}"; do
  NAME=$(basename "$REPO" .git)
  echo "---- Clonning $NAME..."

  # Clonar o actualizar si ya existe
  git clone "$REPO"
  cd $NAME

  echo "---- Installing $NAME..."

  if [ "$NAME" == "papi" ]; then
    cd src
  fi

  if [ "$NAME" == "hiredis" ]; then
    make install PREFIX=$INSTALL_DIR/
    cd ..
    echo "---- $NAME completed"
    continue
  fi
  
  if [ "$NAME" == "json-c" ]; then
    mkdir -p build && cd build
    cmake .. -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DCMAKE_INSTALL_PREFIX:PATH=$INSTALL_DIR \
        -DCMAKE_INSTALL_LIBDIR:PATH=lib \
        -DINSTALL_PKGCONFIG_DIR:PATH=lib/pkgconfig \
        && make && make install
    cd ..
    echo "---- $NAME completed"
    continue
  fi

  # Look for installation method
  if [ -f "CMakeLists.txt" ]; then
    mkdir -p build && cd build
    cmake --prefix $INSTALL_DIR -DINSTALL_PKGCONFIG_DIR:PATH=$INSTALL_DIR/lib/pkgconfig ..
    make -j$(nproc)
    make install
    cd ..
  elif [ -f "configure" ]; then
    ./configure --prefix=$INSTALL_DIR
    make -j$(nproc)
    make install
  elif [ -f "autogen.sh" ]; then
    ./autogen.sh
    ./configure --prefix=$INSTALL_DIR
    make -j$(nproc)
    make install
  elif [ -f "Makefile" ]; then
    make -j$(nproc)
    echo "    *** With Makefile you must specify the installation folder. Please, check it out."
  else
    echo "    *** No installation method detected for $NAME. Skipping..."
  fi

  if [ "$NAME" == "papi" ]; then
    cd ..
  fi

  cd ..
  echo "---- $NAME completed"
done

cd $CDIR
echo "++++++++ Repos already installed +++++++++"
echo ""
echo "++++++++ Consider remove tmp folder +++++++++"
echo ""
echo "++++++++ Installing local components +++++++++"

#compile libfabric
tar zxvf libfabric-1.12.1.tar
cd libfabric-1.12.1
./autogen.sh 
./configure --prefix=$INSTALL_DIR --disable-verbs --disable-psm3 --disable-psm2 --disable-psm \
    && make && make install && make distclean
cd ..

#compile mercury
tar zxvf mercury-2.0.1.tar
cd mercury-2.0.1
mkdir -p build
cd build
cmake .. -DBUILD_SHARED_LIBS:BOOL=ON \
         -DMERCURY_USE_BOOST_PP:BOOL=ON \
         -DNA_USE_OFI:BOOL=ON \
         -DCMAKE_INSTALL_PREFIX:PATH=$INSTALL_DIR/ \
         -DOFI_LIBRARY:FILEPATH=$INSTALL_DIR/lib/libfabric.so \
         -DOFI_INCLUDE_DIR:PATH=$INSTALL_DIR/include \
         -Dpkgcfg_lib_PC_OFI_fabric:FILEPATH=$INSTALL_DIR/lib/libfabric.so && \
        make && make install
cd ../..

#Compile argobots
tar zxvf argobots-1.1.tar
cd argobots-1.1
./configure --prefix=$INSTALL_DIR/ && make && make install && make distclean
cd ..

#Compile mochi-margo
tar zxvf mochi-margo-0.9.5.tar
cd mochi-margo-0.9.5
autoreconf -i && ./configure --prefix=$INSTALL_DIR \
    PKG_CONFIG_PATH=$INSTALL_DIR/lib/pkgconfig:$PKG_CONFIG_PATH && make \
    && make install && make distclean
cd ..

echo "++++++++ All components installed +++++++++"
echo ""

# Set environment variables
echo "export PATH=$INSTALL_DIR/bin:$CDIR/tmp/redis/src:\$PATH" 
echo "export LD_LIBRARY_PATH=$INSTALL_DIR/lib:\$LD_LIBRARY_PATH"
echo "export PKG_CONFIG_PATH=$INSTALL_DIR/lib/pkgconfig:\$PKG_CONFIG_PATH"