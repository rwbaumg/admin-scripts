#!/bin/bash
# Tests network speed from the commandline
# wget --output-document=/dev/null "${SPEEDTEST_URL}" /dev/null 2>&1 | grep --before-context=5 saved; 
#
# See: http://speedtest.tds.net/speedtest/
# See: https://c.speedtest.net/speedtest-servers-static.php

#TEST_FILE="10MB.zip"
#TEST_FILE="10GB.zip"
#DOWNLOAD_URL="http://speedtest.tele2.net"
#UPLOAD_URL="http://speedtest.tele2.net/upload.php"

TEST_FILE="random2500x2500.jpg" # 12M
#TEST_FILE="random4000x4000.jpg" # 30M
DOWNLOAD_URL="http://chicago02.speedtest.windstream.net:8080/speedtest"
UPLOAD_URL="${DOWNLOAD_URL}/upload.php"

hash bc 2>/dev/null || { echo >&2 "You need to install bc. Aborting."; exit 1; }

cputest () {
	cpuName=$(grep "model name" /proc/cpuinfo | cut -d ":" -f2 | tr -s " " | head -n 1);
	cpuCount=$(grep "model name" /proc/cpuinfo | cut -d ":" -f2 | wc -l);
	echo "CPU: $cpuCount x$cpuName";
	echo -n "Time taken to generate PI to 5000 decimal places with a single thread: ";
	(time echo "scale=5000; 4*a(1)" | bc -lq) 2>&1 | grep real |  cut -f2
}

disktest () {
	echo "Writing 1000MB file to disk"
	dd if=/dev/zero of=$$.disktest bs=64k count=16k conv=fdatasync 2>&1 | tail -n 1 | cut -d " " -f3-;
	rm "$$.disktest";
}

if [ -z "${TEST_FILE}" ]; then
  echo >&2 "ERROR: No test file specified."
  exit 1
fi
if [ -z "${DOWNLOAD_URL}" ]; then
  echo >&2 "ERROR: No download URL specified."
  exit 1
fi

if ! temp_file=$(mktemp -t "${TEST_FILE}.XXXXXXXX"); then
  echo >&2 "ERROR: Failed to create temporary file: ${temp_file}"
  exit 1
fi

# Perform other system tests
# cputest;
# disktest;

echo "Speedtest server : ${DOWNLOAD_URL}"
echo "Speedtest file   : ${TEST_FILE}"

down_url="${DOWNLOAD_URL}/${TEST_FILE}"
#echo "Checking download speed: ${down_url} ..."
if ! download_speed=$(curl -o "${temp_file}" "${down_url}" -w "%{speed_download}" -s); then
  echo >&2 "ERROR: Failed to download test file: ${down_url}"
  exit 1
fi
# shellcheck disable=2001
if ! download_speed=$(echo "scale=2; $(echo "${download_speed}" | sed "s/\,/\./g") / 1048576" | bc -q | awk '{printf "%.2f", $0}'); then
  echo >&2 "ERROR: Failed to calculate download speed."
  exit 1
fi

err=0
if [ -n "${UPLOAD_URL}" ] && [ -s "${temp_file}" ]; then
  #echo "Checking upload speed: ${UPLOAD_URL} ..."
  if ! upload_speed=$(curl -T "${temp_file}" "${UPLOAD_URL}" -w "%{speed_upload}" -s -o /dev/null); then
    echo >&2 "ERROR: Upload test failed."; err=1
  fi
  # shellcheck disable=2001
  upload_speed=$(echo "scale=2; $(echo "${upload_speed}" | sed "s/\,/\./g") / 1048576" | bc -q | awk '{printf "%.2f", $0}')
else
  echo >&2 "Skipped upload test (not configured)."
fi

echo "Download speed   : ${download_speed} MB/s"

if [ -n "${upload_speed}" ]; then
echo "Upload speed     : ${upload_speed} MB/s"
fi

if [ -e "${temp_file}" ]; then
  rm "${temp_file}"
fi

exit $err
