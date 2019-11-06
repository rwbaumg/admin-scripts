#!/bin/bash
# Get the main function from the specified C source file

if [ -n "$*" ]; then
  if ! MATCH=$(grep -Pzo "(?s)(\s*)\N([a-z]+(\s)?){0,3}main.*?{.*?\1}" "$@"); then
    exit 1
  fi
else
  if ! MATCH=$(grep -Pzo "(?s)(\s*)\N([a-z]+(\s)?){0,3}main.*?{.*?\1}" ./*.c); then
    exit 1
  fi
fi

if [ -z "$(echo "${MATCH}" | head -n1)" ]; then
  MATCH=$(echo "${MATCH}" | tail -n+2)
fi

echo "${MATCH}"

exit 0
