#!/bin/bash

dir_name=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 24 | xargs)
mkdir $dir_name
cd $dir_name

for ((i = 1; i <= 100; i++)); do
    file_name=$(LC_CTYPE=C tr -dc A-Za-z0-9 < /dev/urandom | head -c 12 | xargs)
    dd if=/dev/urandom bs=1 count=200 of=./$file_name > /dev/null 2>&1
done

echo "Directory $dir_name created"
