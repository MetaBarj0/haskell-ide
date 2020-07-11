#!/bin/sh
cd "/home/hsdev/.config/nvim/"

if [ ! -f init.vim ]; then
  cp -a init.vim.dist init.vim
fi

if [ ! -f plugins.vim ]; then
  cp -a plugins.vim.dist plugins.vim
fi

if [ ! -f coc-settings.json ]; then
  cp -a coc-settings.json.dist coc-settings.json
fi

cd - 1>/dev/null 2>&1

cd ~

if [ ! -f .gitconfig ]; then
  cp -a .gitconfig.dist .gitconfig
fi

cd - 1>/dev/null 2>&1

cd ~/.stack
if [ ! -f config.yaml ]; then
  cp -a config.yaml.dist config.yaml
fi

cd - 1>/dev/null 2>&1

while true; do sleep 10; done
