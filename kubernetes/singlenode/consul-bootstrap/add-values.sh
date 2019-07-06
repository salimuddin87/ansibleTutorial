#!/bin/sh
while read  line; do
    key=`echo $line | cut -f1 -d '='`
    value=`echo $line | cut -f2- -d '='`
    result=`curl -X PUT -d "$value"  $CONSUL_URL/kv$key`
    if [ $result = "true" ]
    then
      echo "Added value for $key"
    else
      echo "Failed to add value of $key exit 1"
      exit 1
    fi
done < $1