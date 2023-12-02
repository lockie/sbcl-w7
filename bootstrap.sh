#!/usr/bin/env bash

set -exo pipefail

export TERM=linux
export DEBIAN_FRONTEND="noninteractive"
dpkg --add-architecture i386
apt-get update -qq
apt-get install -q -y --no-install-recommends ca-certificates git gpg make msitools nsis sudo tar unzip wget wine winetricks xz-utils zstd

winetricks win7
wget -q -O /tmp/sbcl-1.4.14-x86-64-windows-binary.msi "https://sourceforge.net/projects/sbcl/files/sbcl/1.4.14/sbcl-1.4.14-x86-64-windows-binary.msi/download"
msiextract -C /tmp /tmp/sbcl-1.4.14-x86-64-windows-binary.msi
mv /tmp/PFiles/Steel\ Bank\ Common\ Lisp/ ~/.wine/drive_c/Program\ Files/

git clone --branch sbcl-${SBCL_VERSION} git://git.code.sf.net/p/sbcl/sbcl

git clone --depth=1 https://github.com/HolyBlackCat/quasi-msys2
cd quasi-msys2
make install _gcc _gdb

wget https://github.com/sharkdp/bat/releases/download/v0.23.0/bat-v0.23.0-x86_64-pc-windows-gnu.zip -P /tmp
unzip -j /tmp/bat-v0.23.0-x86_64-pc-windows-gnu.zip bat-v0.23.0-x86_64-pc-windows-gnu/bat.exe -d /root/.wine/drive_c/windows/
mv /root/.wine/drive_c/windows/bat.exe /root/.wine/drive_c/windows/cat.exe

../build.sh
