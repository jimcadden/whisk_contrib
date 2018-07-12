OW_PATH=$HOME/incubator-openwhisk
ANSBL=$OW_PATH/ansible
ENV=$ANSBL/environments/kumo

ansible-playbook -i $ENV $ANSBL/openwhisk.yml -e mode=clean
ansible-playbook -i $ENV $ANSBL/apigateway.yml -e mode=clean
ansible-playbook -i $ENV $ANSBL/couchdb.yml -e mode=clean
