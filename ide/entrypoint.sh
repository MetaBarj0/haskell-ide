#!/bin/sh

export PATH="${PATH}:$(stack path --local-bin 2>/dev/null)"

while true; do sleep 10; done
