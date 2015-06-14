#!/bin/bash
cat /boot/System.map-$(uname -r) | grep sys_call_table | cut -d " " -f 1
