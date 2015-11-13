#!/bin/bash
# pushes all tags & branches to an 0x19e mirror
# assumes the cwd is a git repo with an 0x19e remote

hash git 2>/dev/null || { echo >&2 "You need to install git. Aborting."; exit 1; }

if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo >&2 "Current directory is not a git repository. Aborting."
  exit 1
fi

if ! git ls-remote 0x19e; then
  echo >&2 "Working copy doesn't have an 0x19e remote. Aborting."
  exit 1
fi

# Fetch from origin, push to 0x19e
git fetch && \
git push 0x19e +refs/remotes/origin/*:refs/heads/* +refs/tags/*:refs/tags/*
