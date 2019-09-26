#!/bin/bash
# Manually balance interrupts

if [ -z "$1" ] || [ -z "$2" ]; then
echo "Usage: $0 <nic> <number of cpus>"
exit 1
fi

cpu=0
grep $1 /proc/interrupts | awk '{ print $1 }' | sed 's/://' | while read a
do
echo $cpu > /proc/irq/$a/smp_affinity_list
echo "echo $cpu > /proc/irq/$a/smp_affinity_list"
    if [ $cpu = $2 ]; then
    then
        cpu=0
    fi
    let cpu=cpu+1
done
