#!/bin/bash
#set -x
CTNR_IMAGE="openwhisk/nodejs4action"
AMOUNT=3100
CONTAINERS=""
COUNT=0
while [ "$COUNT" -lt "$AMOUNT" ]
do
	# create container
  	CTNR_ID=$(docker run -d --privileged=true $CTNR_IMAGE)
	docker exec $CTNR_ID /bin/bash -c "echo 0 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts"
	CONTAINERS="$CONTAINERS $CTNR_ID"
	CNTR_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CTNR_ID)
	## Send an arp request to the container
	ARP_STDOUT=$(arping -b -f -w 2 -I docker0 $CNTR_IP)
	GOT_ARP_REPLY=$(echo "$ARP_STDOUT" | grep "Unicast reply" | wc -l)
	if [ "$GOT_ARP_REPLY" == "1" ]
	then
		ARP_REPLY_TIME=$(echo "$ARP_STDOUT" | grep "Unicast reply" | cut -d ' ' -f 7 | cut -d 'm' -f 1 )
	else
		ARP_REPLY_TIME=0
	fi
	let "COUNT+=1"
	echo $COUNT", "$ARP_REPLY_TIME
	## broadcast ping
	#PING_STDOUT=$(ping -b -c 2 172.17.255.255 2>/dev/null)
	#PING_REPLIES=$(echo "$PING_STDOUT" | grep icmp_seq=1 | cut -d '=' -f 4 | cut -d ' ' -f 1)
	#PING_REPLY_COUNT=$(echo $PING_REPLIES | wc -w)
	#tsum=0.0
	#for val in $PING_REPLIES; do
	#	tsum=$tsum+$val
	#done
	## sum latencies
	#PING_REPLY_SUM=$( bc <<< $tsum )
	#tave="${PING_REPLY_SUM}/${PING_REPLY_COUNT}"
	#PING_REPLY_AVE=$( bc -l <<< $tave )
	#echo $COUNT", "$PING_REPLY_COUNT", "$PING_REPLY_AVE
done
# CLEAN UP CONTAINERS
#echo $CONTAINERS
docker rm -f $CONTAINERS &> /dev/null
