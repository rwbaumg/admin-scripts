#!/bin/bash
# print top 10 processes by cpu usage

ps --no-headers aux | sort -rnk +3 | head
