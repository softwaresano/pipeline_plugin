#!/bin/bash
[ -z "DP_HOME" ] && echo "[Error] DP_HOME must be defined" && exit 1
### HELP section
dp_help_message="This command has not any help
[aws] deploy type
"
source $DP_HOME/dp_help.sh $*
### END HELP section

# DEFINITIONS
####################################################################
declare -a LAYER_IDS
declare -a LAYER_OUT_IPS
declare -a LAYER_IN_IPS
declare -a LAYER_NUMBER

# Add a default LOG_FILE destination
LOG_FILE=errors.log

# This variable will hold the key of the layer in the LAYER_IDS array
# that it's being currently treated.
CURRENT_LAYER=-1

# CONFIGURATION LOCATION
####################################################################

DEPLOY_PATH=$DP_HOME/profiles/deploy/aws
source ${DEPLOY_PATH}/deploy.cfg
[ -f neore/config/deploy.cfg ] && source neore/config/deploy.cfg
[ -f neore/config/deploy.cfg.local ] && source neore/config/deploy.cfg.local

# COMMON UTILITY FUNCTIONS
####################################################################

# Log an error to the console
function error() {
  echo -e "\n\t-> Error: $1\n"
  echo -e "\n\t-> Error: $1\n" >> $LOG_FILE
}

# Log information to the console
function log() {
  echo -e "\t- $1"
  echo -e "\t- $1" >> $LOG_FILE
}

# Log a task title to the console
function task() {
  echo -e "\n  *) $1\n"
  echo -e "\n  *) $1\n" >> $LOG_FILE
}

function break_log() {
  echo -e "\n\n\n" >> $LOG_FILE
  echo "-----------------------------------------------------------" >> $LOG_FILE
  echo "-----------------------------------------------------------" >> $LOG_FILE
  echo -e "\n\n\n" >> $LOG_FILE
}

function initialize() {
  break_log

  task "Starting new tasks"
}

# Ends the program execution with the given code
function terminate() {
  
  if [[ $1 = 0 ]]; then
    task "Actions finished successfully"
  else
    task "There were some errors executing actions"
  fi

  break_log

  exit $1
}


# SCRIPT SPECIFIC FUNCTIONS
####################################################################

function findkey() {
  COUNT=0
  for item in $LAYERS; do
    if [[ $1 = $item ]]; then
      CURRENT_LAYER=$COUNT
    fi
    COUNT=$((COUNT+1))
  done
}

# Show the script usage
function show_usage() {
  PROGRAM_NAME=$(basename "$0")
  echo -e "\nUsage:"
  echo -e "\t$PROGRAM_NAME install (<node-type> <node-number)+\n"
  echo -e "\t\tDeploys an environment consisting of a Puppet master and a variable"
  echo -e "\t\tnumber of nodes, specified in the command line as any number of pairs"
  echo -e "\t\t<node-type> <node-number>. If no nodes are specified the default"
  echo -e "\t\tarchitecture from the deploy.cfg will be used. If a single parameter"
  echo -e "\t\tis passed, it will be considered the name of an architecture in"
  echo -e "\t\tthe config file and used as so.\n"
  echo -e "\t$PROGRAM_NAME uninstall <summary_file>\n"
  echo -e "\t\tUninstall an environment from a previously saved summary file\n"
  echo -e "\t$PROGRAM_NAME add <summary_file> <node_type>\n"
  echo -e "\t\tAdds a new node of the given type to the given environment\n"
  echo -e "\t$PROGRAM_NAME remove <summary_file> <node_type>\n"
  echo -e "\t\tRemoves a node of the given type from the given environment\n"
  echo -e "\t$PROGRAM_NAME help\n"
  exit 0
}

# Check if the EC2 environment is correctly set and working
function check_ec2_environment() {
  if [[ -z "$EC2_HOME" ]]; then
    error "Amazon installation base variable not defined";
    exit 1
  fi

  if [[ -z "$AWS_ACCESS_KEY" ]] || [[ -z "$AWS_SECRET_KEY" ]]; then
    error "Amazon EC2 Access Key or secret variables not defined";
    exit 1
  fi

  if [[ -z "$JAVA_HOME" ]]; then
    error "JAVA_HOME variable not defined";
    exit 1
  fi

  which ec2-describe-regions > /dev/null

  if [[ $? = 1 ]]; then
    error "EC2 Tools not installed or not found in path";
    exit 1
  fi
}

# Wait for a EC2 instance to be deployed
function wait_for_instance() {
  IID=$1
  log "Waiting for instance $IID" 

  TIMES=0
  while [ 10 -gt $TIMES ] && ! ec2-describe-instances --region $REGION $IID | grep -q "running"
  do
    TIMES=$(( $TIMES + 1 ))
    log "Verifying state of instance $IID"
    sleep 25
  done 

  STATUS=$(ec2-describe-instance-status --region $REGION $IID | awk '/^INSTANCE/ {print $4}' | head -n 1)

  echo -e "\n$STATUS\n" >> $LOG_FILE 

  if [ "$STATUS" = "running" ]; then 
    log "Instance successfully installed"
  else
    error "Instance ended in an unexpected state: $STATUS" 
  fi  
}

function wait_for_ssh() {
  IP=$1

  log "Waiting for SSH on IP $IP"
  TIMES=0

  CONTINUE=1

  while [ 10 -gt $TIMES ] && [[ $CONTINUE -ne 0 ]]
  do
    TIMES=$(( $TIMES + 1 ))
    log "Trying SSH Connection number $TIMES"
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 ec2-user@$PM_EXTERNAL_DN ls &> /dev/null
    CONTINUE=$?

    sleep 20
  done

  echo -e "\nThe final status is $CONTINUE\n" >> $LOG_FILE

  if [[ $CONTINUE = 0 ]]; then
    log "Instance is accesible with SSH"
  else
    error "Couldn't SSH-access the VM: $CONTINUE"
  fi
}

# Extract the IPs of the redis using its instance ID and add it to the global array
function extract_node_data() {
  INSTANCE_ID=$1
  OUTPUT=$(ec2-describe-instances --region $REGION $INSTANCE_ID)
  NODE_IN_IP=$(echo $OUTPUT | awk '{print $19}')
  NODE_OUT_IP=$(echo $OUTPUT | awk '{print $18}')
  findkey $2
  LAYER_IN_IPS[$CURRENT_LAYER]+=" $NODE_IN_IP"
  LAYER_OUT_IPS[$CURRENT_LAYER]+=" $NODE_OUT_IP"
  log "$2: InternalIP($NODE_IN_IP), ExternalIP($NODE_OUT_IP)"
}

# Deploy a Redis instance in EC2
function deploy_node() {
  task "Deploying <<$2>> instance number $1"
  findkey $2

  INITFILE=$TMP_FOLDER/init-$2.sh
  OUTPUT=$(ec2-run-instances $IMAGE -t $SIZE_REDIS --region $REGION --key $KEYS -g $GROUP --user-data-file $INITFILE)

  echo $OUTPUT >> $LOG_FILE

  INSTANCE_ID=$(echo $OUTPUT|awk '{print $6}')
  LAYER_IDS[$CURRENT_LAYER]+=" $INSTANCE_ID"

  wait_for_instance $INSTANCE_ID
  extract_node_data $INSTANCE_ID $2
  
  log "Adding tags to the node"
  INSTANCE_NAME=${PUPPET_MASTER_ID}_$2_$INSTANCE_ID
  ec2addtag $INSTANCE_ID --region $REGION --tag Name=$INSTANCE_NAME 1>> $LOG_FILE 2>> $LOG_FILE
  ec2addtag $INSTANCE_ID --region $REGION --tag Environment=${PUPPET_MASTER_ID} 1>> $LOG_FILE 2>> $LOG_FILE
}

# Extract the Puppet Master data from its instance ID in EC2
function extract_puppet_master_data() {
  INSTANCE_ID=$1
  OUTPUT=$(ec2-describe-instances --region $REGION $INSTANCE_ID)
  PM_OUT_IP=$(echo $OUTPUT | awk '{print $18}')
  PM_IN_IP=$(echo $OUTPUT | awk '{print $19}')
  PM_INTERNAL_DN=$(echo $OUTPUT | awk '{print $9}')
  PM_EXTERNAL_DN=$(echo $OUTPUT | awk '{print $8}')
  log "Puppet Master: InternalIP($PM_IN_IP), ExternalIP($PM_OUT_IP)"
}

function create_init_scripts() {
  for nodename in $LAYERS; do
    cat ${DEPLOY_PATH}/initScripts/init-node.sh | sed s/@PM_IP/$PM_IN_IP/g | sed s/@NODE_TAG/$nodename/g  | sed s/@USER/$USERNAME/g | sed s/@PM_INTERNAL_DN/$PM_INTERNAL_DN/g > $TMP_FOLDER/init-$nodename.sh
  done
}

# Deploy the puppet master that will coordinate the configuration of the machines
function deploy_puppet_master() {
  task "Deploying puppet master"
  INITFILE=${DEPLOY_PATH}/initScripts/init-puppetmaster.sh
  OUTPUT=$(ec2-run-instances $IMAGE -t $SIZE_PUPPET --region $REGION --key $KEYS -g $GROUP --user-data-file $INITFILE)

  echo $OUTPUT >> $LOG_FILE

  INSTANCE_ID=$(echo $OUTPUT|awk '{print $6}')
  PUPPET_MASTER_ID=$INSTANCE_ID
  wait_for_instance $INSTANCE_ID
  extract_puppet_master_data $INSTANCE_ID
  create_init_scripts
  wait_for_ssh $PM_OUT_IP
  
  SLEEP_TIME=100
  log "Waiting $SLEEP_TIME s for the Puppet Master to be ready"
  sleep $SLEEP_TIME

  log "Adding tags to the Puppet Master"
  INSTANCE_NAME=${PUPPET_MASTER_ID}_puppetmaster
  ec2addtag $PUPPET_MASTER_ID --region $REGION --tag Name=$INSTANCE_NAME 1>> $LOG_FILE 2>> $LOG_FILE
  ec2addtag $INSTANCE_ID --region $REGION --tag Environment=${PUPPET_MASTER_ID} 1>> $LOG_FILE 2>> $LOG_FILE
}

# Check all the EC2 data of each instance and print it
function print_instances() {

    for instance in $1; do
      log "Instance = $2_$instance" >> $IP_SUMMARY

      OUTPUT=$(ec2-describe-instances --region $REGION $instance | grep INSTANCE)
        
      echo $OUTPUT >> $LOG_FILE

      log "Instance id: $instance"
      log "External name: $(echo $OUTPUT  | awk '{print $4}')" >> $IP_SUMMARY
      log "Internal name: $(echo $OUTPUT  | awk '{print $5}')" >> $IP_SUMMARY
      log "External ip: $(echo $OUTPUT  | awk '{print $14}')" >> $IP_SUMMARY
      log "Internal ip: $(echo $OUTPUT  | awk '{print $15}')" >> $IP_SUMMARY
      echo -e "\n" >> $IP_SUMMARY
    done
}

function print_summary() {
    task "Printing Results"
    
    TARGET_FILE=summary.tdafenv

    echo "* Environment summary:" > $TARGET_FILE

    TOTAL_INSTANCES=$PUPPET_MASTER_ID
    for nodename in $LAYERS; do
      findkey $nodename
      TOTAL_INSTANCES+=" ${LAYER_IDS[$CURRENT_LAYER]}"
      echo "${nodename}_layer=${LAYER_IDS[$CURRENT_LAYER]}" >> $TARGET_FILE
    done

    echo "TOTAL_INSTANCES= $TOTAL_INSTANCES" >> $TARGET_FILE
    echo "PUPPET_MASTER=" $PM_IN_IP >> $TARGET_FILE
    echo "MASTER_ID=$PUPPET_MASTER_ID" >> $TARGET_FILE
    
    log "Puppet Master ips: External ($PM_OUT_IP), Internal ($PM_IN_IP)\n\n" > $IP_SUMMARY

    for nodename in $LAYERS; do
      findkey $nodename
      print_instances "${LAYER_IDS[$CURRENT_LAYER]}" $nodename
    done
}

# Inject the Puppet Master files and the local source code into the puppet 
# master and uncompress it
function inject_code() {
  task "Injecting code into the Puppet Master"
  log "Injecting Puppet Master data"
  scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $TMP_FOLDER/puppetMasterCode.tgz ec2-user@$PM_EXTERNAL_DN: 1>> $LOG_FILE 2>> $LOG_FILE
  if [[ -n "$LOCAL_SOURCE_CODE" ]]; then
    log "Injecting local source code"
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $TMP_FOLDER/localSourceCode.tar ec2-user@$PM_EXTERNAL_DN: 1>> $LOG_FILE 2>> $LOG_FILE
  fi
  log "Injecting Puppet Master scripts"
  scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${DEPLOY_PATH}/initScripts/get-node-info.js ec2-user@$PM_EXTERNAL_DN: 1>> $LOG_FILE 2>> $LOG_FILE
  scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${DEPLOY_PATH}/initScripts/update-puppetmaster.sh ec2-user@$PM_EXTERNAL_DN: 1>> $LOG_FILE 2>> $LOG_FILE
  
  log "Updating Puppet Master to reflect the changes"
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@$PM_EXTERNAL_DN "bash update-puppetmaster.sh" 1>> $LOG_FILE 2>> $LOG_FILE
}


# Deploy an instance of the full stack. The number of Popbox Agents and 
# Redis instances will be taken from the config files, unless overriden
# by the input parameters.
function deploy_vm () {
  if [[ -n "$1" ]]; then
    GIT_BRANCH=$1
  fi;

  task "Deploying stack"

  deploy_puppet_master
  inject_code

  for nodename in $LAYERS; do
    findkey $nodename

    for i in `seq 1 ${LAYER_NUMBER[$CURRENT_LAYER]}`;
    do
      deploy_node $i $nodename
    done
  done

  print_summary
}

# Check the file passed as a parameter is a valid environment file
function check_environment() {
  echo $1 |egrep ".*tdafenv" > /dev/null
  
  if [[ $? = 1 ]]; then
    error "Extension not recognized. *.tdafenv expected."
    exit 1
  fi

  cat $1 |egrep "TOTAL_INSTANCES" > /dev/null

  if [[ $? = 1 ]]; then
    error "Instance IDs not found. Invalid environment format."
    exit 1
  fi
}

# Remove all the instances from a previously saved environment summary
function remove_vms() {
  SUMMARY=$1

  check_environment $SUMMARY

  if [[ -z "$SUMMARY" ]]; then
    error "No summary provided. Nothing will be removed"
    exit 1
  fi

  
  task "Removing selected environment: $SUMMARY"

  TOTAL_IDS=$(cat $1 |grep TOTAL_INSTANCES| cut -d= -f2)

  for id in $TOTAL_IDS; do
    log "Removing instance $id"
    ec2-terminate-instances --region $REGION $id 1>> $LOG_FILE 2>> $LOG_FILE
  done

}

# Add a new node to the environment passed as te first parameter. The second
# parameter specifies the type of node to deploy.
function add_node() {

  if [[ -z "$1" ]]; then
    error "No environment was provided. Nothing will be added"
    exit 1
  fi

  if [[ -z "$2" ]]; then
    error "Node type missing. Nothing will be added"
    exit 1
  fi

  task "Adding node type $2 to environment $1"

  # Find the Puppet Master ID to prepare the init_scripts
  PM_IN_IP=$(cat summary.tdafenv |grep PUPPET_MASTER|awk '{print $2}')
  PUPPET_MASTER_ID=$(cat summary.tdafenv |grep MASTER_ID|cut -d= -f2)
  LAYERS=$2
  create_init_scripts

  deploy_node 1 $2

  findkey $2
  sed -i "s/TOTAL_INSTANCES.*/& ${LAYER_IDS[$CURRENT_LAYER]}/g" $1
  sed -i "s/$2_layer.*/& ${LAYER_IDS[$CURRENT_LAYER]}/g" $1  
}

# Remove a node of the given type from the given environment. The script
# allways remove the first node in the list.
function remove_node() {

  if [[ -z "$1" ]]; then
    error "No environment was provided. Nothing will be removed"
    exit 1
  fi

  if [[ -z "$2" ]]; then
    error "Node type missing. Nothing will be removed"
    exit 1
  fi

  LAYER_INSTANCES=$(cat $1 |grep $2_layer | cut -d= -f2)
  INSTANCE=$(echo $LAYER_INSTANCES | cut -d' '  -f1)

  task "Removing node type $2 from environment $1: $INSTANCE"
  ec2-terminate-instances --region $REGION $INSTANCE 1>> $LOG_FILE 2>> $LOG_FILE
  
  sed -i "s/$INSTANCE//g" $1
}

# Extract the parameters from the command line to decide which modules to deploy
function extract_parameters() {
  ARRAY=(${@})

  if [[ $# = 1 ]]; then
    log "Proceding with default architecture";

    if [[ -z "$ARCHITECTURE_DEFAULT" ]]; then
      error "Default architecture not found"
      terminate 1
    fi
    ELEMENTS=($ARCHITECTURE_DEFAULT)
  elif [[ $# = 2 ]]; then
    log "Proceding with selected architecture: $2"
    VARNAME="ARCHITECTURE_$2"

    if [[ -z "${!VARNAME}" ]]; then
      error "Selected architecture <$2> not found"
      terminate 1
    fi
    ELEMENTS=(${!VARNAME})
  else
    log "Proceding with ad-hoc architecture: ${ARRAY[*]:1}"
    ELEMENTS=(${ARRAY[*]:1})
  fi

  LAYERS=""
  for (( i = 0; i < ${#ELEMENTS[@]}; i=i+2 )); do
    LAYERS+="${ELEMENTS[$i]} "
    LAYER_NUMBER[$(($i/2))]=${ELEMENTS[$(($i+1))]}
  done
}

function store_code() {
  task "Storing Puppet Master code and Local Source Code to inject in the PM"

  log "Storing $PUPPET_MASTER_CODE"
  tar cvzf $TMP_FOLDER/puppetMasterCode.tgz -C $PUPPET_MASTER_CODE --exclude=".git" . 1>> $LOG_FILE 2>> $LOG_FILE
  if [[ -n "$LOCAL_SOURCE_CODE" ]]; then
    log "Storing $LOCAL_SOURCE_CODE"
    tar cvf $TMP_FOLDER/localSourceCode.tar -C $LOCAL_SOURCE_CODE --exclude=".git" . 1>> $LOG_FILE 2>> $LOG_FILE
  fi
}

# Check the first command line argument to execute the corresponding action.
function dispatch_actions() {
  case "$1" in 
    install)
      initialize
      extract_parameters $@
      store_code
      deploy_vm $2
    ;;
    uninstall)
      initialize
      remove_vms $2
    ;;
    add)
      initialize
      add_node $2 $3
    ;;
    remove)
      initialize
      remove_node $2 $3
    ;;
    help)
      show_usage
    ;;
    *)
      show_usage
    ;;
  esac
}

# LAUNCH SCRIPT
####################################################################

check_ec2_environment
dispatch_actions $@

terminate 0
