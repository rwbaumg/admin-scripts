#!/bin/bash
# print top 10 processes by cpu usage

ps aux | sort -rnk +3 | head
