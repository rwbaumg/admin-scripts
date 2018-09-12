#!/bin/bash
# Displays a list of commits only found in the specified branch

git log --oneline --cherry-pick --no-merges --right-only master...$1
