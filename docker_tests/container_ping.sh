#!/bin/bash
set -x

CTNR_IMAGE="openwhisk/nodejs4action"

CREATE_START_TIME=$(($(date +%s%N)/1000000))
CTNR_ID=$(docker run -d $CTNR_IMAGE)
CREATE_END_TIME=$(($(date +%s%N)/1000000))

CTNR_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CTNR_IP)
PING_START_TIME=$(($(date +%s%N)/1000000))
PING_INTERNAL_TIME=$(ping -c 1 $CTNR_IP | grep "time=" | cut -d '=' -f 4 | cut -d ' ' -f 1)
PING_END_TIME=$(($(date +%s%N)/1000000))

CREATE_TIME=$(($CREATE_END_TIME-$CREATE_START_TIME))
PING_TIME=$(($PING_END_TIME-$PING_START_TIME))

echo "CID=$CTNR_ID"
echo "TIME=$CREATE_TIME"
echo "PITIME=$PING_INTERNAL_TIME"
echo "PTIME=$PING_TIME"


