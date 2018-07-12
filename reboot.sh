OW_PATH=$HOME/incubator-openwhisk
ANSBL=$OW_PATH/ansible
ENV=$ANSBL/environments/kumo

ansible-playbook -i $ENV $ANSBL/openwhisk.yml     
