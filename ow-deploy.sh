#!/bin/bash
######################################################################
#  Openwhisk Deployment Controls 
#
#  This files provides a collectiion of helper scripts for interacting 
#	   with a configured OpenWhisk deployment.
#
######################################################################

export WSKROOT=${WSK_ROOT:=$HOME/incubator-openwhisk}
export WSKENV=${WSK_ENV:=moc}
export ANSBL=$WSKROOT/ansible
export ENVROOT=$ANSBL/environments/$WSKENV
# MACHINE IPs
export VMIP=${VM_IP:=10.22.22.145}
export VMHOSTIP=${VM_HOST_IP:=10.22.22.144}
export CNTRIP=${CNTR_IP:=10.22.22.100}
export BENCHIP=${BENCH_IP:=10.22.22.100}
# ENABLE/DISBALE SEUSS
export SEUSS=${SEUSS:=}
if [[ ! -z $SEUSS ]]; then
	export LINUX=
	if [[ ! -z $DEBUG ]]
	then
	  echo "********** SEUSS DEBUG TARGET **********"
	  export MOD="-seuss_debug"
	else
	  echo "********** SEUSS TARGET **********"
	  export MOD="-seuss"
	fi
else
	echo "********** LINUX VM TARGET **********"
	export LINUX=1
	export SEUSS=
fi

echo "OpenWhisk deployment control:$ENVROOT"

function Boot 
{
  echo "Deploying OpenWhisk..."
if [[ ! -z $LINUX ]]; then
  LinuxVM_UP	
fi
  SyncClocks
  ansible-playbook -i $ENVROOT $ANSBL/setup.yml
  ansible-playbook -i $ENVROOT $ANSBL/couchdb.yml
  ansible-playbook -i $ENVROOT $ANSBL/initdb.yml
  ansible-playbook -i $ENVROOT $ANSBL/wipe.yml        
  ansible-playbook -i $ENVROOT $ANSBL/openwhisk$MOD.yml    
  sleep 60
  echo "Boot Finished"
}

function SoftBoot
{
  ansible-playbook -i $ENVROOT $ANSBL/setup.yml
  ansible-playbook -i $ENVROOT $ANSBL/couchdb.yml
  ansible-playbook -i $ENVROOT $ANSBL/initdb.yml
  ansible-playbook -i $ENVROOT $ANSBL/wipe.yml        
  ansible-playbook -i $ENVROOT $ANSBL/openwhisk$MOD.yml    
  echo "Boot Finished"
}

function SoftReboot
{
  ansible-playbook -i $ENVROOT $ANSBL/openwhisk$MOD.yml -e mode=clean
  sleep 30 
  ansible-playbook -i $ENVROOT $ANSBL/openwhisk$MOD.yml
  echo "Reboot Finished"
}

function Reboot 
{	
  echo "Redeploying OpenWhisk..."
if [[ ! -z $LINUX ]]; then
  LinuxVM_DOWN	
  LinuxVM_UP	
fi
  ansible-playbook -i $ENVROOT $ANSBL/openwhisk$MOD.yml -e mode=clean
  sleep 30 #90
  ansible-playbook -i $ENVROOT $ANSBL/openwhisk$MOD.yml
  sleep 60 #90
  SyncClocks
  echo "Reboot finished"
}

function Shutdown 
{
  echo "Shutting down OpenWhisk$MOD..."
if [[ ! -z $LINUX ]]; then
  LinuxVM_DOWN	
fi
  ansible-playbook -i $ENVROOT $ANSBL/openwhisk$MOD.yml -e mode=clean
  ansible-playbook -i $ENVROOT $ANSBL/apigateway.yml -e mode=clean
  ansible-playbook -i $ENVROOT $ANSBL/couchdb.yml -e mode=clean
if [[ ! -z $SEUSS ]]; then
	Clean
fi
  echo "Shutdown finished."
}

function Clean 
{
  echo "Removing EbbRT native containers..." 
#	docker ps | grep ebbrt-0 | cut -d ' ' -f 1 | while read id; do docker rm -f $id; done
  echo "Removing EbbRT networks..." 
#	docker network ls | grep ebbrt-0 | cut -d ' ' -f 9 | while read id; do docker network rm $id; done
}

function countContainerLoop
{
count=0
while true;
do
if [ ! -z $LINUX ]; then
	now=$(date +%s%N)
	c=$(ssh $VMIP /root/whisk_contrib/ow-bench.sh countContainers node)
	echo ${count},${now},${c}
	(( count++ ))
	sleep 0.1
fi
done
}

function SyncClocks
{
if [ ! -z $LINUX ]; then
  parallel-ssh -H $BENCHIP -H $CNTRIP -H $VMIP -P "date --date='@2147483647'"
else
  parallel-ssh -H $BENCHIP -H $CNTRIP -P "date --date='@2147483647'"
fi
}

function LinuxVM_UP
{
  if ping -q -c 1 $VMIP > /dev/null ; then
	  echo "VM is already up"
	  exit
  fi	  
  ssh 10.22.22.144 cp ~/ubuntu.qcow2 /dev/shm/
  sleep 2
  ssh 10.22.22.144 virsh start ubuntu18.04
  sleep 30
}

function LinuxVM_DOWN
{
  ssh $VMHOSTIP virsh destroy ubuntu18.04
  sleep 2
  ssh $VMHOSTIP rm /dev/shm/ubuntu.qcow2
  sleep 2
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
