#!/bin/sh

nvim --headless -u /home/hsdev/.config/nvim/plugins.vim +PlugInstall +qa

[ $? -eq 0 ] && exit 0 || exit 1