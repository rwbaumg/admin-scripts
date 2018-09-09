#!/bin/bash
# Generates a new password following the Bacula / Bareos specification

hash openssl 2>/dev/null || { echo >&2 "You need to install openssl. Aborting."; exit 1; }

openssl rand -base64 33

exit 0
