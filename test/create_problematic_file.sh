#!/bin/bash

file_name=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 12 | xargs)
dd if=/dev/urandom bs=1M count=2000 of=./$file_name > /dev/null 2>&1

echo "File $file_name created"
