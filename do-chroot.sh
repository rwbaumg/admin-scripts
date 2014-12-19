#!/bin/bash
args=""
for i in "$@" ; do
    args="$args '$i'"
    # echo $args
done

echo chroot  : $1
echo command : $2
echo args    : $3
#echo args    : $args

/usr/bin/schroot -c $1 --directory=/root "$2" $3
#/usr/bin/schroot -c $1 --directory=/root "$2" $args
