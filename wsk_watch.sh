#!/bin/bash

export WSKCLI=${WSK_CLI:=wsk}
export WSKLOG=${WSK_INVOKER_LOG:=/tmp/wsklogs/invoker0/invoker0_logs.log}
export TMPDIR=${TMP_DIR:=/tmp}

export DEBUG=${DEBUG:=}
if [[ -n $DEBUG ]]; then
  set -x
fi 

export CLEAR=${CLEAR:=}
export POLL=${POLL:=}
if [[ -n $POLL ]]; then
  if [[ $(bc -l <<< "0 < $POLL") -eq 1 ]]; then
    echo "Poll frequency set at $POLL seconds"
  else
    set POLL=""
  fi 
fi 

usage()
{
  local func=$1
  if [[ -z $func ]]
  then
     echo "USAGE:  ${0##*/} func args" >&2
     grep '^function' $0
  else
     case "$func" in
         'fooBar')
            echo "USAGE: ${0##*/} fooBar " >&2
            echo "     -f foo   : Set foo in fooBar" >&2
            echo "     -b bar   : Set bar in fooBar" >&2
            ;;
          *)
            usage
            ;;
     esac
  fi
}

#################################################### 

function countContainers
{
  extra=""
  if [[ $# -gt 0 ]]; then
    for i in "$@"; do
      extra="$extra | grep $i "
    done
  fi
  cmd="docker ps | grep whisk $extra | wc -l"
  bash -c "$cmd"
}

function showContainers
{
  extra=""
  if [[ $# -gt 0 ]]; then
    for i in "$@"; do
      extra="$extra | grep $i "
    done
  fi
  cmd="docker ps $extra "
  bash -c "$cmd"
}

function streamLog 
{
  cmd="tail -f $WSKLOG"
  bash -c "$cmd"
}

function showStarts
{
  extra=""
  if [[ $# -gt 0 ]]; then
    for i in "$@"; do
      extra="$extra | grep $i "
    done
  fi
  cmd="grep containerState $WSKLOG $extra "
  bash -c "$cmd"
}

function countStarts
{
  echo -e "cold:\t\t" $( showStarts cold | wc -l )
  echo -e "prewarm:\t" $( showStarts prewarm | wc -l )
  echo -e "warm:\t\t" $( showStarts warm | wc -l )
}

function wskAction
{
  cmd="$WSKCLI -i action $@"
  bash -c "$cmd"
}

function randomFunction
{
	seed=$RANDOM
	file="$TMPDIR/wsk_func_$RANDOM.js"
	touch $file
  cat << EOF >> $file
function main() {
    return {payload: 'RANDOM $seed'};
}
EOF
  wskAction create $seed $file > /dev/null
  if [ $? -eq 0 ]; then
		echo $seed
	fi
	rm $file
}

function getInvokeTime
{

	init_t=0
	wait_t=0
	run_t=0
  OUTPUT=$(bash -c "$WSKCLI -i action invoke -b $@ | tail -n +2")
	len=$(echo $OUTPUT | jq -r '.annotations | length') 
	run_t=$( echo $OUTPUT | jq -r '.duration' )
	if [[ $len -eq 4 ]]; then # WARM/HOT START 
		wait_t=$( echo $OUTPUT | jq -r '.annotations' | jq -r '.[3]' | jq -r '.value' )
	elif [[ $len -eq 5 ]]; then #COLD START
		wait_t=$( echo $OUTPUT | jq -r '.annotations' | jq -r '.[1]' | jq -r '.value' )
		init_t=$( echo $OUTPUT | jq -r '.annotations' | jq -r '.[4]' | jq -r '.value' )
	fi
	
	echo $wait_t $init_t $run_t 
}

#################################################### 

processargs()
{
  if [[ $# == 0 ]]
  then
    usage
    exit -1
  fi

  dofunc=$1
}

if [[ -n $POLL ]]; then
   processargs "$@"
   shift
   while [ 1 ]; do
     if [[ -n $CLEAR ]]; then
       clear
     fi
     $dofunc "$@"
     sleep $POLL
   done
elif [[ $COUNT -gt 0 ]]; then
  processargs "$@"
  shift
  for (( i=1; i<=$COUNT; i++ )); do
    if [[ -n $CLEAR ]]; then
      clear
    fi
    $dofunc "$@"
  done
else
  processargs "$@"
  shift
  if [[ -n $CLEAR ]]; then
    clear
  fi
  $dofunc "$@"
  exit $?
fi

#################################################### 
