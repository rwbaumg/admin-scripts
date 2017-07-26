#!/bin/bash
# print top 10 processes by memory usage

ps aux | sort -rnk +4 | head
