#!/bin/bash

source config.sh

if [ $# != 2 ]; then
    echo "ユーザー名とメッセージを指定してください"
    exit 1
else
    USER_NAME=`echo $1`
    MESSAGE=`echo $2`
fi
    
payload="payload={
    \"username\": \"${USER_NAME}\",
    \"text\": \"${MESSAGE}\"
}"
curl -s -S -X POST --data-urlencode "${payload}" ${SlackWebHook} > /dev/null