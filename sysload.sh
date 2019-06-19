#!/bin/bash
# print an overview of current system load

hash iostat 2>/dev/null || { echo >&2 "You need to install sysstat. Aborting."; exit 1; }

function getSizeString() {
  if [ -z "$1" ]; then
    echo "NULL"
    return 1
  fi

  re='^[0-9]+$'
  if ! [[ $1 =~ $re ]] ; then
    echo "NaN"
    return 1
  fi

  if [ "$1" -lt 1000 ]; then
    echo "${1} bytes"
    return 0
  fi

  echo "$1" |  awk '
    function human(x) {
        if (x<1000) {return x} else {x/=1024}
        s="kMGTEPZY";
        while (x>=1000 && length(s)>1)
            {x/=1024; s=substr(s,2)}
        return sprintf("%.2f", x) " " substr(s,1,1) "B"
    }
    {sub(/^[0-9]+/, human($1)); print}'

  return 0
}

iostat -m

top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{printf("CPU Load:\t%s%\n",100-$1)}'
free -m | awk 'NR==2{printf "Memory Usage:\t%s MB / %s MB (%.f%%)\n", $3,$2,$3*100/$2 }'

printf "Disk Usage:\n"
df -h | awk '{ printf("%s %s %s %s %s\n", $6, $1, $3, $2, $5); }' \
  | grep -v "Mounted" | grep -vP '^\/(dev|run|sys)' \
  | awk '{ printf("  - %-14s on\t %-14s: %-6s / %-6s (%s)\n", $2, $1, $3, $4, $5); }'
# df -h | awk '$NF=="/"{printf "Disk Usage:\t%d GB /%d GB (%s)\n", $3,$2,$5}'

# NOTE: ps returns value in kB
echo -e "\nProcess memory usage:"
ps axo rss,comm,pid | awk '{ proc_list[$2]++; proc_list[$2 "," 1] += $1; } END { for (proc in proc_list) { printf("%d %s\n", proc_list[proc "," 1],proc); }}' | sort -n | tail -n 10 | sort -nr | while read -r line; do
  proc=$(echo "$line" | awk -F' ' '{ print $2 }')
  bytes=$(echo "$line" | awk -F' ' '{ print $1 }')
  size=$(getSizeString "$((bytes*1024))")

  printf "%-14s %s\n" "$size" "$proc"
done

exit 0
