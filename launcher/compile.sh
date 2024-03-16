#!/bin/bash

if [[ "$OSTYPE" == "msys" ]]; then
    winpty docker run -v `pwd | sed 's/\//\/\//g'`://src/ -it z88dk/z88dk make
    python checksums.py main.rom
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    docker run -v `pwd | sed 's/\//\/\//g'`://src/ -it z88dk/z88dk make
    python3 checksums.py main.rom
else
    echo "Unknown operating system"
fi