#!/usr/bin/env bash
if [ "$EUID" -eq 0 ]
  then echo "Dont use sudo!"
  exit
fi
LAST_PROTON=$(curl -s https://api.github.com/repos/GloriousEggroll/wine-ge-custom/releases/latest \
  | grep browser_download_url | cut -d '"' -f 4 | grep tar\.xz)
(echo $LAST_PROTON | grep LoL) && echo "Last Proton for LoL." && exit
(ls ~/.local/share/lutris/runners/wine/ | grep $(echo $LAST_PROTON | grep -o lutris.*64)) \
  > /dev/null && echo "No new verisons." && exit
echo "New version available!" 
cd /tmp && wget $LAST_PROTON -O proton.tar.xz
tar -xvf proton.tar.xz
mv *lutris* ~/.local/share/lutris/runners/wine/
