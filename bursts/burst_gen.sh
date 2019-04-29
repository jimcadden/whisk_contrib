######################################################################
#  Openwhisk Burst Generation Controls 
######################################################################

#export VMIP=${VM_IP:=10.22.22.145}
export BURST_CR=${BURST_CR:=1}
export BURST_FREQ=${BURST_FREQ:=1}
export BACK_CR=${BACK_CR:=1}
export BACK_BATCH=${BACK_BATCH:=}
export BACK_RATE=${BACK_RATE:=}
export END_SLEEP=${END_SLEEP:=60}
export START_SLEEP=${START_SLEEP:=90}
export OUT=${OUT:="./"}
PWD=$1
if [ ! -d "$PWD" ]; then
	echo "Burst file directory not found ($PWD). Exiting..."
	exit 1
fi
NOW=$(date +%Y_%B_%d_%H_%M) 
mkdir -p $OUT
OUTP="${OUT}cmds_${NOW}"

# BACKGROUND STREAM
BACK_OUT=${OUTP}_back.csv
echo "LAUNCHING BACKGROUND STREAM rate=${BACK_RATE}: $BACKOUT " 
go run *.go -cf $BACK_CR -q -rateLimit $BACK_RATE --forever --writeToFile --fileName=$BACK_OUT --create execOWFile $BACK_BATCH &

# CONTAINER COUNT
C_OUT=${OUTP}_cache.csv
echo "LAUNCHING COUNTAINER COUNT $C_OUT " 
#/root/whisk_contrib/ow-deploy.sh countContainerLoop  >> $C_OUT &

echo "SLEEPING FOR $START_SLEEP SECONDS"
sleep $START_SLEEP

bcount=0
for file in $PWD/*.csv
do
	((bcount++))
	BURST_OUT=${OUTP}_burst_${bcount}.csv
	echo "BURST #" $bcount. $file $BURST_OUT "(${BURST_FREQ})"
	#BURST
	go run *.go -cf $BURST_CR -q --writeToFile --fileName=$BURST_OUT --create execOWFile $file &
	sleep $BURST_FREQ
done

echo "SLEEPING FOR $END_SLEEP SECONDS"
sleep $END_SLEEP
pkill -P $$
echo "FINISHED!"
