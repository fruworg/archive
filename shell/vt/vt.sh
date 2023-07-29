#!/bin/bash
apikey=c2fe3b4dc0b284ff2bd7cd08a361e134bc01c6a19a61536a4e514185fb8c37df
md5=$(md5sum "$1" | sed -r "s/ .+$//")
resp=$(curl --request GET \
                --url https://www.virustotal.com/api/v3/files/{"$md5"} \
                --header "x-apikey: "$apikey"" 2>/dev/null)
mlwr=$(echo "$resp" | jq '.data .attributes .total_votes .malicious')
numb=$(ls /dev/pts)
gnome-terminal & 
sleep .1
numb=$(ls /dev/pts)$(printf "\n$numb")
numb=$(echo "$numb" | sort | uniq -u)
if [[ "$mlwr" == "null" ]]; then
out=$(echo "Хэш не найден!")
elif [[ "$mlwr" == "0" ]]; then
out=$(echo "Малварь не найдена.")
else
body=$(echo "$resp" | jq '.data .attributes .last_analysis_results | .[] | "\(.engine_name) \(.result)"' \
                                | sed 's/ /: /' | sed 's/"$//' | sed 's/"//' | sed -r '/null$/d')
out=$(printf "%s\n\nАнтивирусы, нашедшие малварь ↑\nВсего найдено малварей: %s\n" \
        "$body" "$mlwr")
fi
ih=$(echo "$1 - " | sed -r 's/.+\///')
ib=$(file "$1" | sed -r 's/.+: //' | sed -r 's/,.+$//')
printf "$out\n$ih$ib" > /dev/pts/"$numb"
