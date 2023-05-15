#!/usr/bin/env bash

set -exo pipefail

export TERM=linux
export DEBIAN_FRONTEND="noninteractive"
dpkg --add-architecture i386
apt-get update -qq
apt-get install -q -y --no-install-recommends ca-certificates git gpg make msitools nsis tar unzip wget wine winetricks xz-utils zstd

winetricks win7
wget -q -O /tmp/sbcl-1.4.14-x86-64-windows-binary.msi "https://sourceforge.net/projects/sbcl/files/sbcl/1.4.14/sbcl-1.4.14-x86-64-windows-binary.msi/download"
msiextract -C /tmp /tmp/sbcl-1.4.14-x86-64-windows-binary.msi
mv /tmp/PFiles/Steel\ Bank\ Common\ Lisp/ ~/.wine/drive_c/Program\ Files/

git clone --branch sbcl-${SBCL_VERSION} git://git.code.sf.net/p/sbcl/sbcl

git clone --depth=1 https://github.com/HolyBlackCat/quasi-msys2
cd quasi-msys2
make install _gcc _gdb

wget https://download-mirror.savannah.gnu.org/releases/coreutils/windows-64bit-unsupported/coreutils-8.31-28-windows-64bit.zip -P /tmp
unzip -j /tmp/coreutils-8.31-28-windows-64bit.zip -d /root/.wine/drive_c/windows/

../build.sh
