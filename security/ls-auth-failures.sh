#!/bin/bash
# Simple script to list logged authentication failures

# list authentication failures
grep -i "failure" /var/log/auth.log

exit 0
