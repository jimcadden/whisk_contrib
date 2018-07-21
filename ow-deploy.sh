#!/bin/bash
######################################################################
#  Openwhisk Deployment Controls 
#
#  This files provides a collectiion of helper scripts for interacting 
#	   with a configured OpenWhisk deployment.
#
######################################################################

export WSKROOT=${WSK_ROOT:=$HOME/incubator-openwhisk}
export WSKENV=${WSK_ENV:=seuss}
export ANSBL=$WSKROOT/ansible
export ENVROOT=$ANSBL/environments/$WSKENV

echo "OpenWhisk deployment control:$ENVROOT"

function Shutdown 
{
  echo "Shutting down OpenWhisk..."
  ansible-playbook -i $ENVROOT $ANSBL/openwhisk.yml -e mode=clean
  ansible-playbook -i $ENVROOT $ANSBL/apigateway.yml -e mode=clean
  ansible-playbook -i $ENVROOT $ANSBL/couchdb.yml -e mode=clean
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
  ansible-playbook -i $ENVROOT $ANSBL/openwhisk.yml     
  ansible-playbook -i $ENVROOT $ANSBL/postdeploy.yml
  echo "Finished."
}

function Install 
{
  echo "Installing OpenWhisk..."
  echo "TODO!"
  echo "Finished."
}

function Reboot 
{
  echo "Redeploying OpenWhisk..."
  ansible-playbook -i $ENVROOT $ANSBL/openwhisk.yml     
  echo "Finished."
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
