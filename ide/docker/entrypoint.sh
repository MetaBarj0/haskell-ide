#!/bin/sh
cd "/home/hsdev/.config/nvim/"

if [ ! -f init.vim ]; then
  cp -a init.vim.dist init.vim
fi

if [ ! -f plugins.vim ]; then
  cp -a plugins.vim.dist plugins.vim
fi

cd - 1>/dev/null 2>&1

cd ~

if [ ! -f .gitconfig ]; then
  cp -a .gitconfig.dist .gitconfig
fi

cd - 1>/dev/null 2>&1

while true; do sleep 10; done
