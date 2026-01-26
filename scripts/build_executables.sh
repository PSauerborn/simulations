#!/bin/bash

# CPU architecture of the host system
cpu_arch=$(uname -m)

mkdir -p bin temp
# Build executables
venv/bin/fpm install --prefix=. --bindir=temp
# Copy executables to bin and add CPU arch suffix
for file in temp/*; do
    cp "$file" "bin/$(basename "$file")_$cpu_arch"
done
