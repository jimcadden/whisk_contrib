#!/bin/bash
#set -x
CTNR_IMAGE="openwhisk/nodejs4action"
AMOUNT=1
CONTAINERS=""
COUNT=0
while [ "$COUNT" -lt "$AMOUNT" ]
do
	# create container
  	CTNR_ID=$(docker run -d --privileged=true $CTNR_IMAGE)
	docker exec $CTNR_ID /bin/bash -c "echo 0 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts"
	CONTAINERS="$CONTAINERS $CTNR_ID"
	# broadcast ping
	let "COUNT+=1"
	PING_STDOUT=$(ping -b -c 2 172.17.255.255 2>/dev/null)
	PING_REPLIES=$(echo "$PING_STDOUT" | grep icmp_seq=1 | cut -d '=' -f 4 | cut -d ' ' -f 1)
	PING_REPLY_COUNT=$(echo $PING_REPLIES | wc -w)
	tsum=0.0
	for val in $PING_REPLIES; do
		tsum=$tsum+$val
	done
	# sum latencies
	PING_REPLY_SUM=$( bc <<< $tsum )
	tave="${PING_REPLY_SUM}/${PING_REPLY_COUNT}"
	PING_REPLY_AVE=$( bc -l <<< $tave )
	echo $COUNT", "$PING_REPLY_COUNT", "$PING_REPLY_AVE
done
# CLEAN UP CONTAINERS
#docker rm -f $CONTAINERS &> /dev/null
echo $CONTAINERS
