#!/bin/sh

# This script generates a string using MD5 algorithm
# using the input $1.
# It is used to generate identifier for authors that
# dont have Researcher Identification.
file=/tmp/t.txt
if [ $# != 1 ]; then
    echo "Usage: $0 \"Author Name\""
    exit
fi

name=$1
printf "$name" >${file}
md5str=`md5sum ${file} |awk '{print $1}'`
echo $md5str
