#!/bin/sh
set -e

cd /root

git clone --recurse-submodule https://github.com/MetaBarj0/ctags.git

cd - 1>/dev/null 2>&1

cd /root/ctags/thirdparties/jansson

autoreconf -i
./configure

cpuCount="$(cat /proc/cpuinfo | grep '^processor' | wc -l)"

make -j $cpuCount
make install

cd - 1>/dev/null 2>&1

cd /root/ctags

./autogen.sh
./configure

make -j $cpuCount
make install