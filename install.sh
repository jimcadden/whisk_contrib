OW_PATH=$HOME/incubator-openwhisk
ANSBL=$OW_PATH/ansible
ENV=$ANSBL/environments/kumo

ansible-playbook -i $ENV $ANSBL/setup.yml
ansible-playbook -i $ENV $ANSBL/couchdb.yml
ansible-playbook -i $ENV $ANSBL/initdb.yml
ansible-playbook -i $ENV $ANSBL/wipe.yml        
ansible-playbook -i $ENV $ANSBL/apigateway.yml    
ansible-playbook -i $ENV $ANSBL/openwhisk.yml     
ansible-playbook -i $ENV $ANSBL/postdeploy.yml
