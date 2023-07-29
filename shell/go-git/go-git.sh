#!/bin/bash
if [ ! -f username  ]; then
echo Введи ник:
read username
echo Введи токен:
read token
echo "$token" > token
echo "$username" > username
else
token=$(cat token)
username=$(cat username)
fi
echo Введи имя репозитория:
read repo
title="
username="$username"
repo="$repo"
token="$token"
"
commit='
gh auth login --with-token < ../token > /dev/null
if (! gh repo view "$repo" 1> /dev/null 2> /dev/null); then
gh repo create "$repo" --public 1> /dev/null
fi
git init 1> /dev/null 2> /dev/null
git add . 
git rm --cached commit-"$repo".sh 1> /dev/null
echo Введи имя коммита:
read commit
git commit -m "$commit"
git branch -M main
git push --set-upstream https://"$token"@github.com/"$username"/"$repo".git main
'
main='package main

import (

)

func main() {

}'
mod="
module github.com/"$username"/"$repo"

go 1.17

require (
)
"
mkdir "$repo"
cd "./$repo"
echo "### $repo" > README.md
echo "$main" > main.go
echo "$mod" > mod.go
echo "$title" > commit-"$repo".sh
echo "$commit" >> commit-"$repo".sh
chmod 775 commit-"$repo".sh
