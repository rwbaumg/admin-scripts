#!/bin/bash
# downloads the latest GeoLine City database

DOWNLOAD_URL="http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz"

wget -O GeoLiteCity.dat.gz "$DOWNLOAD_URL"

gunzip GeoLiteCity.dat.gz
