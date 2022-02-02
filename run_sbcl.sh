#!/usr/bin/env sh

export SBCL_HOME=$HOME/.wine/drive_c/Program\ Files/Steel\ Bank\ Common\ Lisp/1.4.14/
wine "$HOME/.wine/drive_c/Program Files/Steel Bank Common Lisp/1.4.14/sbcl.exe" --lose-on-corruption --disable-ldb --disable-debugger "$@"
