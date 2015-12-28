#!/bin/bash
# tests the random pool

hash rngtest 2>/dev/null || { echo >&2 "You need to install rng-tools. Aborting."; exit 1; }

TEST_COUNT=1000

echo "Testing /dev/random..."
cat /dev/random | rngtest -c $TEST_COUNT
