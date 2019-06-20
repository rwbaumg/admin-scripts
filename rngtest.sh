#!/bin/bash
# tests the random pool

hash rngtest 2>/dev/null || { echo >&2 "You need to install rng-tools. Aborting."; exit 1; }

RND_SOURCE="/dev/urandom"
TEST_COUNT=1000

echo "Testing ${RND_SOURCE} ..."
if ! rngtest -c $TEST_COUNT < "${RND_SOURCE}"; then
  echo
  echo "WARNING: Test failed!"
  exit 1
fi

exit 0
