#!/bin/bash

BLOCKFILE=/home/ddopson/renaturedash/scraper/LOCK

if [ -e $BLOCKFILE ]; then
  echo 'Blocked from running'
  exit 1
fi

/home/ddopson/renaturedash/scraper/sync.sh &>> /home/ddopson/renaturedash/scraper/log/$(date +%s).txt
