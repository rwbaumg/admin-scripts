#!/bin/bash
# show each of the available console colors

for code in {0..255}; do
  echo -e "\e[38;05;${code}m $code: This is a test string."
done
