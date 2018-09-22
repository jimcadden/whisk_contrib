#!/bin/bash
######################################################################
#  Openwhisk Deployment Controls 
#
#  This files provides a collectiion of helper scripts for interacting 
#	   with a configured OpenWhisk deployment.
#
######################################################################

export WSKROOT=${WSK_ROOT:=$HOME/incubator-openwhisk}
export WSKENV=${WSK_ENV:=local}
export ANSBL=$WSKROOT/ansible
export ENVROOT=$ANSBL/environments/$WSKENV

export SEUSS=${SEUSS:=}

if [[ ! -z $SEUSS ]]
then
	if [[ ! -z $DEBUG ]]
	then
		echo "********** SEUSS DEBUG ENABLED **********"
		export MOD="-seuss_debug"
	else
	  echo "********** SEUSS ENABLED **********"
	  export MOD="-seuss"
	fi
fi


echo "OpenWhisk deployment control:$ENVROOT"

function Shutdown 
{
  echo "Shutting down OpenWhisk$MOD..."
  ansible-playbook -i $ENVROOT $ANSBL/openwhisk$MOD.yml -e mode=clean
  ansible-playbook -i $ENVROOT $ANSBL/apigateway.yml -e mode=clean
  ansible-playbook -i $ENVROOT $ANSBL/couchdb.yml -e mode=clean
if [[ ! -z $SEUSS ]]; then
	Clean
fi
  echo "Finished."
}

function Boot 
{
  echo "Deploying OpenWhisk..."
  ansible-playbook -i $ENVROOT $ANSBL/setup.yml
  ansible-playbook -i $ENVROOT $ANSBL/couchdb.yml
  ansible-playbook -i $ENVROOT $ANSBL/initdb.yml
  ansible-playbook -i $ENVROOT $ANSBL/wipe.yml        
  ansible-playbook -i $ENVROOT $ANSBL/apigateway.yml    
  ansible-playbook -i $ENVROOT $ANSBL/openwhisk$MOD.yml     
  echo "Finished."
}

function Reboot 
{
  echo "Redeploying OpenWhisk..."
  ansible-playbook -i $ENVROOT $ANSBL/openwhisk$MOD.yml -e mode=clean
	if [[ ! -z $SEUSS ]]; then
		Clean
	fi
  ansible-playbook -i $ENVROOT $ANSBL/openwhisk$MOD.yml     
  echo "Finished."
}

function Clean 
{
  echo "Removing EbbRT native containers..." 
	docker ps | grep ebbrt-0 | cut -d ' ' -f 1 | while read id; do docker rm -f $id; done
  echo "Removing EbbRT networks..." 
	docker network ls | grep ebbrt-0 | cut -d ' ' -f 9 | while read id; do docker network rm $id; done
}

######################################################################
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
