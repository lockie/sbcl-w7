#!/usr/bin/env bash

set -exo pipefail

source env/all_quiet.src
source env/duplicate_exe_outputs.src
export PATH=`dirname $(pwd)`:$PATH:`pwd`/env/wrappers
export CC=win-dupebin-cc

cd ../sbcl
sed -i 's/gcc/win-dupebin-cc/g' src/runtime/Config.x86-64-win32
./make.sh --with-sb-core-compression --xc-host=../run_sbcl.sh --arch=x86_64 || true
cp ../sbcl.nsi .
makensis sbcl.nsi
