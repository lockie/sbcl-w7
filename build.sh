#!/usr/bin/env bash

set -exo pipefail

export WIN_DEFAULT_COMPILER=msys2_gcc
source env/all.src
source env/duplicate_exe_outputs.src
export PATH=`dirname $(pwd)`:$PATH:`pwd`/env/wrappers
export CC=win-dupebin-cc

cd ../sbcl
sed -i 's/gcc/win-dupebin-cc/g' src/runtime/Config.x86-64-win32
sed -i 's/extern int ffs(int);/#define ffs __builtin_ffs/g' src/runtime/hopscotch.c
sed -i 's/-WIP//g' generate-version.sh
sed -i '26 aCC=cc' contrib/asdf-module.mk
./make.sh --with-sb-core-compression --xc-host=../run_sbcl.sh --arch=x86_64 || true
cp ../sbcl.nsi .
makensis sbcl.nsi
