#!/bin/sh
result=`curl -X PUT $ELK_URL/_template/services -d @$1`
