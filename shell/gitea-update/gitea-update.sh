#!/usr/bin/env bash
if [ "$EUID" -ne 0 ]
  then echo "Use sudo!"
  exit
fi
systemctl stop gitea.service
LAST_GITEA_BINARY=$(curl -s https://api.github.com/repos/go-gitea/gitea/releases/latest \
  | grep browser_download_url | cut -d '"' -f 4 | grep $(echo $(uname)-$(dpkg --print-architecture) \
  | sed 's/\(.*\)/\L\1/')$) && wget -O /usr/local/bin/gitea $LAST_GITEA_BINARY
systemctl start gitea.service