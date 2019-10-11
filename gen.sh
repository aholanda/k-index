#!/bin/bash

# This script has auxiliary functions used in the project

function usage() {
    echo "$0 [OPTIONS] ARGS"
    echo " where OPTIONS are:"
    echo "   timestamp          - generate timestamp with minutes and seconds;"
    echo "   hash \"AUTHOR NAME\" - generate a hash using MD5 of \"AUTHOR NAME\""
    echo "                        that is the 2th argument to the script."
    echo "e.g."
    echo "\$ $0 timestamp"
    echo "\$ $0 hash \"Max Planck\""
    exit 2
}

##
# This function generates a string using MD5 algorithm using the input
# $1. It is used to generate identifier for researchers whose Author
# Identifier is missing.
##
function echo_hash() {
    file=/tmp/hash.txt
    if [ $# != 2 ]; then
	usage
    fi

    name=$1
    printf "$name" >${file}
    md5str=`md5sum ${file} |awk '{print $1}'`
    echo $md5str
}

##
# Timestamp is an important feature to mark the moment of change in an
# entry, for example, or to append to file name with the aim to mark
# the file creation time, avoiding the risk of dependency to system
# attributes that could be modified when a file is touched.
##
function echo_timestamp {
    date +%Y%m%d%H%M%S
}
case "$1" in
    hash)
	echo_hash "$@"
	;;
    timestamp)
	echo_timestamp
	;;
    *)
	usage
	;;
esac

exit 0
