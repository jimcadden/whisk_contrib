#!/bin/bash

export WSKCLI=${WSK_CLI:=wsk}

#################################################### 

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
  cmd="docker ps $extra | wc -l"
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

function wskInvoke
{
	cmd="$WSKCLI -i action invoke $@"
	bash -c "$cmd"
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
