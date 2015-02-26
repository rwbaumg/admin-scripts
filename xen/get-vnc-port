#!/bin/bash
if [ "$1" = "" ]
then
  echo "Usage: $0 <xen guest name>"
  exit
fi
name=$1
lsof -nPi | grep `ps -ef|grep qemu|grep "name $name"|awk '{ print $2}'`
