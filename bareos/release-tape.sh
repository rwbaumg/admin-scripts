#!/bin/bash
# releases the tape
sudo bconsole <<END_OF_DATA
release storage=Tape
END_OF_DATA
