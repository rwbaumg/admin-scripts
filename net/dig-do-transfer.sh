#!/bin/bash
# performs a zone transfer using dig
# lazy; expects command in the format of './dig-do-transfer.sh example.com @8.8.8.8'
dig $2 $1 axfr
