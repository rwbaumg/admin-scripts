#!/bin/bash
# List assigned IOMMU groups

LOGFILE=/var/log/kern.log

#for d in /sys/kernel/iommu_groups/*/devices/*; do
#    n=${d#*/iommu_groups/*}; n=${n%%/*}
#    printf 'IOMMU Group %s ' "$n"
#    lspci -nns "${d##*/}"
#done;

IOMMU_GROUPS=$(cat $LOGFILE | grep iommu | grep group | awk '{print $14}' | uniq)

for d in $IOMMU_GROUPS; do
  GROUP_DEVS=$(cat $LOGFILE | grep iommu | grep "group $d" | awk '{print $11}' | uniq)
  for gd in $GROUP_DEVS; do
    DESCR=$(lspci -nn -s $gd)
    echo "group $d device $DESCR"
  done
done;
