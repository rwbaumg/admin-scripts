#!/bin/bash
# downloads the IANA ports list

DOWNLOAD_URL=http://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.csv
# DOWNLOAD_URL=http://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.txt

wget -N $DOWNLOAD_URL
