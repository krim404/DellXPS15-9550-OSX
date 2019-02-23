#!/bin/bash

## Extract
# for f in *.zlib; do
#   zlib-flate -uncompress < "${f%.*}.zlib" > "${f%.*}.plist"
# done

## Compress
for f in *.plist; do
   zlib-flate -compress < "${f%.*}.plist" > "${f%.*}.zlib"
done
