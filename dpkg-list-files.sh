#!/bin/bash

DEBFILE="$1"
dpkg -c $DEBFILE | awk '{ print $6 }' | sort
