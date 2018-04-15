#!/bin/bash

# list authentication failures
grep -i "failure" /var/log/auth.log
