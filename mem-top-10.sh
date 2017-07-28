#!/bin/bash
# print top 10 processes by memory usage

ps --no-headers aux | sort -rnk +4 | head
