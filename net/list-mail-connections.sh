#!/bin/bash
IP_REGEX="((([1-9]?\d|1\d\d|2[0-5][0-5]|2[0-4]\d)\.){3}([1-9]?\d|1\d\d|2[0-5][0-5]|2[0-4]\d))"

# grep -P 'DPT\=(25|587)' /var/log/syslog | grep -P '(dropped|accepted)' | grep -Po "(?<=SRC=)$IP_REGEX(?=\b)" | sort | uniq
# grep -P 'DPT\=(25|587)' /var/log/syslog | grep -P '(dropped)' | grep -Po "(?<=SRC=)$IP_REGEX(?=\b)" | sort | uniq

# print header
printf '=%.0s' {1..50}
printf '\n'
printf "%-16s %s\n" "IP Address" "Hostname"
printf '=%.0s' {1..50}
printf '\n'

for ip in `grep -P 'DPT\=(25|587)' /var/log/syslog | grep -P '(dropped)' | grep -Po "(?<=SRC=)$IP_REGEX(?=\b)" | sort -n | uniq | sort -n`; do
  name=$(nslookup $ip | awk '/name = / { print $4 }')
  printf "%-16s %s\n" $ip $name
done

exit 0
