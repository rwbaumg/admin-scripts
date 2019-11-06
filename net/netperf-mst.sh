#!/bin/bash
# Run a netperf test using multiple streams

hash netperf 2>/dev/null || { echo >&2 "You need to install netperf. Aborting."; exit 1; }

NUMBER=8
TMPFILE=$(mktemp)
PORT=12865
DURATION=10

if [ -z "$1" ]; then
  echo >&2 "Usage: $0 <peer>"; exit 1;
fi
PEER="$1"

# echo "Writing to file $TMPFILE ..."

for i in $(seq $NUMBER); do
  echo "Starting netperf stream: $i"
  nohup netperf -H "$PEER" -p $PORT -t TCP_MAERTS -P 0 -c -l $DURATION -- -m 32K -M 32K -s 256K -S 256K >> "$TMPFILE" &
  nohup netperf -H "$PEER" -p $PORT -t TCP_STREAM -P 0 -c -l $DURATION -- -m 32K -M 32K -s 256K -S 256K >> "$TMPFILE" &
done

if ! wait; then
  echo >&2 "ERROR: Failed."
  killall netperf
  exit 1
fi

echo "Finished."
echo

echo "Total result: $(awk '{sum += $5} END{print sum}' "$TMPFILE") Mb/s"
rm "$TMPFILE"

exit 0
