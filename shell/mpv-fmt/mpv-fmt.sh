#!/usr/bin/env bash
# kill -9 $(pgrep mpv)
read -p 'С какой серии начать? ' -i Ep01 -e START_EPISODE
for CURRENT_EPISODE in $(ls | grep mkv)
  do
    if grep -q "$START_EPISODE" <<< "$CURRENT_EPISODE"; then
      mpv --vf=lavfi=[crop=1440:1080:240:0] $CURRENT_EPISODE \
      --audio-file=$(sed 's/mkv/mka/g' <<< $CURRENT_EPISODE)
    fi
done