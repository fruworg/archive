#!/bin/bash
cat -n "$1" | curl -F "paste=<-" sicp.me | xclip -sel clip
