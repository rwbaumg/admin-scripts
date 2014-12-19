#!/bin/bash
tcpdump -nnXSs 1514 -w $2 -i $1
