#!/bin/bash
set -e  

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
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"


# Download and installation
for REPO in "${REPOS[@]}"; do
  NAME=$(basename "$REPO" .git)
  echo "---- Clonning $NAME..."

  # Clonar o actualizar si ya existe
  git clone "$REPO"
  cd "$NAME"

  echo "---- Installing $NAME..."
  
  # Look for installation method
  if [ -f "CMakeLists.txt" ]; then
    mkdir -p build && cd build
    cmake --prefix $INSTALL_DIR ..
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

  cd "$CDIR"
  echo "---- $NAME completed"
done

echo "++++++++ Repos already installed +++++++++"
