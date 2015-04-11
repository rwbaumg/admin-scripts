#!/bin/bash
TMP_FILE=/tmp/wall_msg

/bin/echo "$1" > $TMP_FILE
/usr/bin/wall < $TMP_FILE
/bin/rm -f $TMP_FILE
