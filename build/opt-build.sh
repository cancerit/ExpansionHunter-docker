#!/bin/bash

get_distro () {
  EXT=""
  if [[ $2 == *.tar.bz2* ]] ; then
    EXT="tar.bz2"
  elif [[ $2 == *.zip* ]] ; then
    EXT="zip"
  elif [[ $2 == *.tar.gz* ]] ; then
    EXT="tar.gz"
  elif [[ $2 == *.tgz* ]] ; then
    EXT="tgz"
  else
    echo "I don't understand the file type for $1"
    exit 1
  fi
  rm -f $1.$EXT
  if hash curl 2>/dev/null; then
    curl --retry 10 -sS -o $1.$EXT -L $2
  else
    wget --tries=10 -nv -O $1.$EXT $2
  fi
}

get_file () {
# output, source
  if hash curl 2>/dev/null; then
    curl -sS -o $1 -L $2
  else
    wget -nv -O $1 $2
  fi
}

if [ "$#" -ne "1" ] ; then
  echo "Please provide an installation path  such as /opt/ICGC"
  exit 0
fi

CPU=`grep -c ^processor /proc/cpuinfo`
if [ $? -eq 0 ]; then
  if [ "$CPU" -gt "6" ]; then
    CPU=6
  fi
else
  CPU=1
fi
echo "Max compilation CPUs set to $CPU"

INST_PATH=$1

# get current directory
INIT_DIR=`pwd`

set -e
# cleanup inst_path
mkdir -p $INST_PATH
cd $INST_PATH
INST_PATH=`pwd`
mkdir -p $INST_PATH
cd $INIT_DIR

export PATH="$INST_PATH/bin:$PATH"

#create a location to build dependencies
SETUP_DIR=$INIT_DIR/install_tmp
mkdir -p $SETUP_DIR

echo -n "Building ExpansionHunter ..."
if [ -e $SETUP_DIR/ehunter.success ]; then
  echo " previously built ...";
else
  echo
  cd $SETUP_DIR
  mkdir -p ehunter
  get_distro "ehunter" "https://github.com/Illumina/ExpansionHunter/archive/refs/tags/${VER_EXPANSIONHUNTER}.tar.gz"
  tar --strip-components 1 -C ehunter -zxf ehunter.tar.gz
  cd ehunter
  mkdir build
  cd build
  cmake ..
  make
  mv install/* $INST_PATH
  cd $SETUP_DIR
  rm -r ehunter.tar.gz
  touch $SETUP_DIR/ehunter.success
fi

