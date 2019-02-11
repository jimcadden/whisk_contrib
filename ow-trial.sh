#!/bin/bash
######################################################################
#  Openwhisk Trail Runner
#
######################################################################

export OWBENCH=${WSK_BENCH:=$PWD/openwhisk-bench}
export OWDEPLOY=${OW_DEPLOY:=$PWD/../ow-deploy.sh}
export OWCF=${OW_CF:=128}
export TRIALDATADIR=${OW_DATA_DIR:=$PWD/data/seuss_data}


#export CMDPREFIX=${CMD_PREFIX:=echo "CMDR: "}
export CMDPREFIX=${CMD_PREFIX:=}
export CMDPOSTFIX=${CMD_POSTFIX:=}

export OWWRAP="go run *.go -q -cf $OWCF "

if [[ ! -z $DEBUG ]]; then set -x; fi

echo "> Begin OpenWhisk Benchmark Trial"
echo ">	  benchmark concurrency: $OWCF"

function CMDR
{
  $CMDPREFIX $@ $CMDPOSTFIX
}

function SingleTrial
{
  local TPATH=$1
  FILES=$(/bin/bash -c "ls $TPATH | grep csv")
  
  echo "$FILES"

  TrialInit

  CMDR $OWDEPLOY Boot
  
  # IF argument is a directory
  for i in $FILES; 
  do
    DoRun $TPATH$i;
    CMDR $OWDEPLOY Reboot
  done

  CMDR $OWDEPLOY Shutdown
}

function TrialInit
{
  if [[ -z $TRIALID ]]; then
    export TRIALID=$(/bin/date +%d-%m-%y-%H-%M)
    export TRIALPATH=$TRIALDATADIR/$TRIALID
  fi
  CMDR mkdir -p $TRIALPATH 
  CMDR git -C ~/incubator-openwhisk/ diff > $TRIALPATH/trial.log
}

function DoRun 
{
  local TESTNAME=$(/bin/bash -c "echo $1 | /usr/bin/cut -d '/' -f 2")
  local FILENAME=$(/bin/bash -c "echo $1 | /usr/bin/cut -d '/' -f 3")
  #echo $1
  #echo $TESTNAME
  #echo $FILENAME
  local NAME=${TESTNAME}_${FILENAME}
  local FN=$TRIALID # filename
  if [[ -n $SEUSS ]]; then
    FN="$TRIALPATH/seuss_$NAME"
  else 
    FN="$TRIALPATH/linux_$NAME"
  fi
  # Run the benchmark
  CMDR touch $FN 
  echo "> Starting Run: $FN"
  CMDR $OWWRAP --create --writeToFile --fileName $FN execOWFile $1
  echo "> Finished Run: $FN"

  # Dump the Invoker logs 
  echo "> ============================================" >> $TRIALPATH/trial.log
  echo "> TRIAL LOGS $FN                              " >> $TRIALPATH/trial.log
  echo "> ============================================" >> $TRIALPATH/trial.log
  if [[ -n $SEUSS ]]; then
    # Seuss 
    #echo "\n> INVOKER LOG $FN                           " >> $TRIALPATH/trial.log
    #echo "> --------------------------------------------" >> $TRIALPATH/trial.log
    #ssh 10.22.22.144 "cat /tmp/wsklogs/seuss_invoker0/seuss_invoker0_logs.log" >> $TRIALPATH/trial.log
    #echo "> --------------------------------------------" >> $TRIALPATH/trial.log
    echo "> BACKEND LOG $FN                           " >> $TRIALPATH/trial.log
    echo "> --------------------------------------------" >> $TRIALPATH/trial.log
    local CID=$( ssh 10.22.22.144 "docker ps -a | grep ebbrt/kvm-qemu | cut -d ' ' -f 1")
    ssh 10.22.22.144 "docker logs $CID" >> $TRIALPATH/trial.log
    echo "> --------------------------------------------" >> $TRIALPATH/trial.log
    echo "> NETWORK LOG $FN                           " >> $TRIALPATH/trial.log
    echo "> --------------------------------------------" >> $TRIALPATH/trial.log
    ssh 10.22.22.144 "netstat -i" >> $TRIALPATH/trial.log
    ssh 10.22.22.144 "netstat -s" >> $TRIALPATH/trial.log
  else
    # Linux 
    echo "> CONTAINER COUNT $FN                       " >> $TRIALPATH/trial.log
    echo "> --------------------------------------------" >> $TRIALPATH/trial.log
    ssh 10.22.22.145 "~/whisk_contrib/ow-bench.sh countAll" >> $TRIALPATH/trial.log
    echo "> INVOKER LOG $FN                           " >> $TRIALPATH/trial.log
    echo "> --------------------------------------------" >> $TRIALPATH/trial.log
    ssh 10.22.22.145 "cat /tmp/wsklogs/invoker0/invoker0_logs.log" >> $TRIALPATH/trial.log
    echo "> --------------------------------------------" >> $TRIALPATH/trial.log
    echo "> NETWORK LOG $FN                           " >> $TRIALPATH/trial.log
    echo "> --------------------------------------------" >> $TRIALPATH/trial.log
    ssh 10.22.22.145 "netstat -i" >> $TRIALPATH/trial.log
    ssh 10.22.22.145 "netstat -s" >> $TRIALPATH/trial.log
  fi
}

#######################################################################

usage()
{
  local func=$1
  if [[ -z $func ]]
  then
     echo "USAGE:  ${0##*/} func args" >&2
     grep '^function' $0
  fi
}

processargs()
{
  if [[ $# == 0 ]]
  then
    usage
    exit -1
  fi

  dofunc=$1
}

if [[ -n $WAIT ]]; then
   processargs "$@"
   shift
   while [ 1 ]; do
     if [[ -n $CLEAR ]]; then
       clear
     fi
     $dofunc "$@"
     sleep $WAIT
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
