#!/bin/bash

# Generate a random filename
file_name=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 12 | xargs)

# Populate file with dd
dd if=/dev/zero bs=1 count=0 seek=2000000000 of=./$file_name > /dev/null 2>&1

echo "File $file_name created"
