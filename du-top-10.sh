#!/bin/bash
# find large files

du -hsx * | sort -rh | head -10
