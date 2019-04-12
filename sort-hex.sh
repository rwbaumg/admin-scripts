#!/bin/bash
# Sorts an input list of hexadecimal values to sort

cat | awk '{printf("%050s\t%s\n", toupper($0), $0)}' | LC_COLLATE=C sort -k1,1 | cut -f2
