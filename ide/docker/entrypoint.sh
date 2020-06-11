#!/bin/sh

export PATH="${PATH}:$(stack path --local-bin 2>/dev/null)"
export TERM=screen-256color

while true; do sleep 10; done
