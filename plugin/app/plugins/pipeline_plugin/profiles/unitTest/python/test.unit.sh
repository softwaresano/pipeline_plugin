#!/usr/bin/env bash

#
# Copyright 2013 Telefonica Digital. All rights reserved.
#
# Authors:
#    Pablo Enfedaque <pev@tid.es> - 06/2013
#    Carlos E. Gomez <carlosg@tid.es> - 06/2013
#

######
# NeoRE BUILD STAGE SCRIPT
#
# Steps:
#    - Install RPM dependencies
#    - Create virtualenv
#    - Install 3rd party requirements
#    - Install local requirements
#    - Autodetect if this is a Django or pure Python component
#    - Run unit tests
#
# Assuming this script is executed inside $PROJECT_ROOT/$COMPONENT_ROOT/src
# it will load (source) the project and component configuration files (in strict order):
#    - project config: $PROJECT_ROOT/neore/config/project.cfg
#    - local project config: $PROJECT_ROOT/neore/config/project.local.cfg
#    - component config: $PROJECT_ROOT/$COMPONENT_ROOT/neore/config/component.cfg
#    - local component config: $PROJECT_ROOT/$COMPONENT_ROOT/neore/config/component.local.cfg
# Note that the "local" configuration files are optional.
#
####


###
# CONSTANTS DEFINITION
###

## SCRIPT CONSTANTS
# Current script name
SCRIPT_NAME=$(basename $0)

# Current script folder
SCRIPT_FOLDER=$(dirname $0)

# Current working directory
CURR_PWD=$(pwd -P)

# Source folder name
SOURCE_FOLDER="src"

# Project configuration files relative paths (from project root)
PROJECT_CONFIG_SUFFIX="neore/config/project.cfg"
PROJECT_LOCAL_CONFIG_SUFFIX="neore/config/project.local.cfg"

# Component configuration files relative paths (from component root)
COMPONENT_CONFIG_SUFFIX="neore/config/component.cfg"
COMPONENT_LOCAL_CONFIG_SUFFIX="neore/config/component.local.cfg"

# Commands existence validation
VALIDATE_CMD="command -v"

# RPMs installation constants
YUM_INSTALL_CMD="yum install -y"

# Virtualenv constants
VIRTUALENV_CMD="virtualenv"
VENV_ACTIVATE_SUFFIX="/bin/activate"
VENV_DEACTIVATE="deactivate"

# Local dependencies installation script
INSTALL_LOCAL_REQS="install_local_reqs"

# Coverage report file
COVERAGE_FILE="coverage.xml"


## DEFAULT VALUES
# Name of the project used in traces
DEFAULT_PROJECT_NAME="UNKNOWN_PROJECT"

# Path where virtualenvs are created
DEFAULT_VENVS_ROOT="/tmp/build_venvs"

# Python binary to use in venv creation
DEFAULT_PYTHON_BIN="/usr/bin/python2.7"

# Absolute path to virtualenv binary to use
DEFAULT_VENV_BIN="/usr/bin/virtualenv-2.7"

# Use sudo when installing RPM dependencies with Yum
DEFAULT_BUILD_USE_SUDO_YUM=true

# Folder to be used as pip cache
PIP_CACHE_FOLDER="/tmp/build_pip_cache"

# Component Python requirements file
DEFAULT_REQUIREMENTS_FILE="requirements.txt"

# Component development Python requirements file
DEFAULT_REQUIREMENTS_DEVEL_FILE="requirements_dev.txt"

# Component local Python requirements file
DEFAULT_REQUIREMENTS_LOCAL_FILE="requirements_local.txt"

# Install RPMs in unit tests stage (build)
DEFAULT_UNITTEST_INSTALL_RPMS=true

# Create or replace and enable virtualenv in unit tests stage (build)
DEFAULT_UNITTEST_USE_VENV=true

# Create a new virtualenv deleting it if previous virtualenv exists
DEFAULT_UNITTEST_CREATE_NEW_VENV=false

# Install requirements  in unit tests stage (build)
DEFAULT_UNITTEST_INSTALL_REQS=true

# Install local requirements  in unit tests stage (build)
DEFAULT_UNITTEST_INSTALL_LOCAL_REQS=true


###
# FUNCTIONS DEFINITION
###

## Echo function with '[build]' prefix
function neore_echo {
    if [ $# -eq 2 ]; then
        BREAKLINE=$2
    else
        BREAKLINE=true
    fi
    if [ -z "$COMPONENT_NAME" ]; then
        OUT_TEXT="[$SCRIPT_NAME] $1"
    else
        OUT_TEXT="[$SCRIPT_NAME][$COMPONENT_NAME] $1"
    fi
    if $BREAKLINE ; then
        echo -e $OUT_TEXT
    else
        echo -ne $OUT_TEXT" "
    fi
}


## Initialize generic component configuration
function init_component_conf {
    if [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME=$DEFAULT_PROJECT_NAME
    fi
    if [ -z "$COMPONENT_NAME" ]; then
        COMPONENT_NAME=$(dirname $(dirname $(pwd -P))) 
    fi
    echo -e ""
    echo -e "\t############################################"
    echo -e "\t##  NeoRE BUILDING / UNIT TESTING PROCESS ##"
    echo -e "\t############################################"
    echo -e "\t > PROJECT NAME:  \t$PROJECT_NAME"
    echo -e "\t > COMPONENT NAME:\t$COMPONENT_NAME"
    echo -e "\t > BUILD SCRIPT:  \t$SCRIPT_FOLDER/$SCRIPT_NAME"
    echo -e ""
}


## Function to validate the result of a command and print error and exit if failed
function check_result {
    if [ $1 -ne 0 ]; then
        neore_echo "[ERROR] $2 failed. Exiting"
        exit -1
    fi
}


## Check and initialise all stages selectors
function init_stages {
    if [ -z "$UNITTEST_INSTALL_RPMS" ]; then
        UNITTEST_INSTALL_RPMS=$DEFAULT_UNITTEST_INSTALL_RPMS
    fi
    if [ -z "$UNITTEST_USE_VENV" ]; then
        UNITTEST_USE_VENV=$DEFAULT_UNITTEST_USE_VENV
    fi
    if [ -z "$UNITTEST_CREATE_NEW_VENV" ]; then
        UNITTEST_CREATE_NEW_VENV=$DEFAULT_UNITTEST_CREATE_NEW_VENV
    fi
    if [ -z "$UNITTEST_INSTALL_REQS" ]; then
        UNITTEST_INSTALL_REQS=$DEFAULT_UNITTEST_INSTALL_REQS
    fi
    if [ -z "$UNITTEST_INSTALL_REQS" ]; then
        UNITTEST_INSTALL_REQS=$DEFAULT_UNITTEST_INSTALL_REQS
    fi
}


## Check and initialise RPM configuration variables
function init_rpm_deps_conf {
    if [ -z "$BUILD_USE_SUDO_YUM" ]; then
        BUILD_USE_SUDO_YUM=$DEFAULT_BUILD_USE_SUDO_YUM
    fi
}


## Install RPM dependencies (if any)
function install_rpm_reqs {
    if [ -z "$BUILD_RPM_DEPENDENCIES" ]; then
        neore_echo "[INFO] No RPM dependencies to install. Skipping"
        return
    fi
    neore_echo "[INFO] Installing RPM dependencies: $BUILD_RPM_DEPENDENCIES"
    if $BUILD_USE_SUDO_YUM ; then
        sudo $YUM_INSTALL_CMD $BUILD_RPM_DEPENDENCIES
    else
        $YUM_INSTALL_CMD $BUILD_RPM_DEPENDENCIES
    fi
    check_result $? "RPM dependencies installation"
}


## Check and initialise if possible loaded virtualenv settings
function init_venv_conf {
    if [ -z "$VENV_PATH" ]; then
        # Initialize with default value
        if [ -z "$VENVS_ROOT" ]; then
            VENVS_ROOT=$DEFAULT_VENVS_ROOT
        fi
        if [ -z "$PYTHON_BIN" ]; then
            PYTHON_BIN=$DEFAULT_PYTHON_BIN
        fi
        if [ -z "$VENV_BIN" ]; then
            VENV_BIN=$DEFAULT_VENV_BIN
        fi
        # Validate Python binary
        neore_echo "[INFO] Validating Python binary '$PYTHON_BIN'" false
        $VALIDATE_CMD "$PYTHON_BIN"
        RES=$?
        if [ $RES -ne 0 ]; then
            echo ""
        fi
        check_result $RES "Virtualenv Python binary validation"
    elif [ ! -d "$VENV_PATH" ]; then
        neore_echo "[ERROR] Provide virtualenv not found: '$VENV_PATH'"
        exit 3
    fi
}


## Generate absolute path of the virtualenv to use
function init_venv_path {
    VENV_PATH="$VENVS_ROOT""/""$COMPONENT_NAME"
}


## Create or replace virtualenv
function init_venv {
    if [ -z "$VENV_PATH" ]; then
        init_venv_path
        if [[ $UNITTEST_CREATE_NEW_VENV == "true" ]]; then
            if [ -d "$VENV_PATH" ]; then
               neore_echo "[INFO] Droping virtualenv '$VENV_PATH'"
               rm -rf "$VENV_PATH"
               check_result $? "Drop already existing virtualenv '$VENV_PATH'"
            fi
        fi
        neore_echo "[INFO] Creating/using virtualenv '$VENV_PATH' with '$PYTHON_BIN'"
        $VENV_BIN $VENV_PATH -p $PYTHON_BIN
    fi
}


## Activate virtualenv
function activate_venv {
    source "$VENV_PATH$VENV_ACTIVATE_SUFFIX"
}


## Deactivate virtualenv
function deactivate_venv {
    neore_echo "[INFO] Trying to deactivate current virtualenv" false
    $VALIDATE_CMD "$VENV_DEACTIVATE"
    if [ $? -eq 0 ]; then
        $VENV_DEACTIVATE
    else
        echo ""
    fi
}


## Check and initialise pip configuration settings
function init_reqs_conf {
    if [ -z "$PIP_CACHE_FOLDER" ]; then
        PIP_CACHE_FOLDER=$DEFAULT_PIP_CACHE_FOLDER
    fi
    if [ -z "$REQUIREMENTS_FILE" ]; then
        REQUIREMENTS_FILE=$DEFAULT_REQUIREMENTS_FILE
    fi
    if [ -z "$REQUIREMENTS_DEVEL_FILE" ]; then
        REQUIREMENTS_DEVEL_FILE=$DEFAULT_REQUIREMENTS_DEVEL_FILE
    fi
    if [ ! -d "$PIP_CACHE_FOLDER" ]; then
        mkdir -p "$PIP_CACHE_FOLDER"
        check_result $? "pip cache folder '$PIP_CACHE_FOLDER' creation"
    fi
}


## Install requirements.txt and requirements_dev.txt files
function install_reqs {
    neore_echo "[INFO] Installing Python requirements: $REQUIREMENTS_FILE"
    pip install --download-cache $PIP_CACHE_FOLDER -r $REQUIREMENTS_FILE
    check_result $? "Python requirements installation: $REQUIREMENTS_FILE"
    neore_echo "[INFO] Installing Python devel requirements: $REQUIREMENTS_DEVEL_FILE"
    pip install --download-cache $PIP_CACHE_FOLDER -r $REQUIREMENTS_DEVEL_FILE
    check_result $? "Python devel requirements installation: $REQUIREMENTS_DEVEL_FILE"
}

## Check and initialise pip configuration settings
function init_local_reqs_conf {
    if [ -z "$REQUIREMENTS_LOCAL_FILE" ]; then
        REQUIREMENTS_LOCAL_FILE=$DEFAULT_REQUIREMENTS_LOCAL_FILE
    fi
}


## Install requirements.txt and requirements_dev.txt files
function install_local_reqs {
    neore_echo "[INFO] Installing Python local requirements: $REQUIREMENTS_LOCAL_FILE"
    $SCRIPT_FOLDER/$INSTALL_LOCAL_REQS -r $REQUIREMENTS_LOCAL_FILE
    # TODO INSTALL REQS OF LOCAL REQS!?!
    check_result $? "Python local requirements installation: $REQUIREMENTS_LOCAL_FILE"
}


## Load unit tests config (command to launch)
function init_unit_tests_conf {
    if [ -z "$UNITTESTS_CMD" ]; then
        neore_echo "[ERROR] Component specific unit tests command not defined"
        exit 1
    fi
}

## Preprocess unit tests (create reports directory)
function unit_tests_preproc {
    neore_echo "[INFO] Preparing unit test environment"
    if [ -n "$PRE_UNITTESTS_CMD" ]; then
       local tempfile="$PWD/dp_tempfile.sh"
       echo $PRE_UNITTESTS_CMD >$tempfile
       chmod u+x $tempfile
       $tempfile
       rm -rf $tempfile
    fi 
}

## Run unit tests
function run_unit_tests {
    neore_echo "[INFO] Executing unit tests '$UNITTESTS_CMD'"
    $UNITTESTS_CMD
    check_result $? "Unit tests exit status: '$?'"
}


## Postprocess unit tests results (nosetests and coverage XMLs)
function unit_tests_postproc {
    neore_echo "[INFO] Right now we are not postprocessing unit tests XMLs"
}


###
# SCRIPT LOGIC
###

## Assert we are inside $PROJECT_ROOT/$COMPONENT_ROOT/$SOURCE_FOLDER
if [ "$(basename $CURR_PWD)" != "$SOURCE_FOLDER" ]; then
    if [ -d "$SOURCE_FOLDER" ]; then
        neore_echo "[INFO] Changing current working directory to '$SOURCE_FOLDER'"
        cd "$SOURCE_FOLDER"
    else
        neore_echo "[ERROR] This script must be launched from 'PROJECT_ROOT/COMPONENT_ROOT/$SOURCE_FOLDER' folder or its parent"
        exit 1
    fi
fi


## Locate and load (source) config
COMPONENT_ROOT=$(dirname $PWD)
PROJECT_ROOT=$(dirname $COMPONENT_ROOT)

PROJECT_CONFIG="$PROJECT_ROOT/$PROJECT_CONFIG_SUFFIX"
PROJECT_LOCAL_CONFIG="$PROJECT_ROOT/$PROJECT_LOCAL_CONFIG_SUFFIX"
COMPONENT_CONFIG="$COMPONENT_ROOT/$COMPONENT_CONFIG_SUFFIX"
COMPONENT_LOCAL_CONFIG="$COMPONENT_ROOT/$COMPONENT_LOCAL_CONFIG_SUFFIX"

if [ ! -f "$PROJECT_CONFIG" ]; then
    neore_echo "[ERROR] Project configuration file '$PROJECT_CONFIG' not found"
    exit 2
else
    source $PROJECT_CONFIG
fi

if [ ! -f "$PROJECT_LOCAL_CONFIG" ]; then
    neore_echo "[WARNING] Local project configuration file '$PROJECT_LOCAL_CONFIG' not found"
else
    source $PROJECT_LOCAL_CONFIG
fi

if [ ! -f "$COMPONENT_CONFIG" ]; then
    neore_echo "[ERROR] Component configuration file '$COMPONENT_CONFIG' not found"
    exit 2
else
    source $COMPONENT_CONFIG
fi

if [ ! -f "$COMPONENT_LOCAL_CONFIG" ]; then
    neore_echo "[WARNING] Local component configuration file '$COMPONENT_LOCAL_CONFIG' not found"
else
    source $COMPONENT_LOCAL_CONFIG
fi


## Initialise project and component basic settings 
init_component_conf


## Initialise stages boolean switches
init_stages


## Try to deactivate current virtualenv (if any)
deactivate_venv


## Install RPM dependencies
if $UNITTEST_INSTALL_RPMS ; then
    init_rpm_deps_conf
    install_rpm_reqs
fi


## Initialise virtualenv
if $UNITTEST_USE_VENV ; then
    init_venv_conf
    init_venv
    activate_venv
fi


## Install requirements
if $UNITTEST_INSTALL_REQS ; then
    init_reqs_conf
    install_reqs
fi


## Install local requirements
if $UNITTEST_INSTALL_LOCAL_REQS ; then
    init_local_reqs_conf
    install_local_reqs
fi


## Launch tests
init_unit_tests_conf
unit_tests_preproc
run_unit_tests
unit_tests_postproc


## Deactivate virtualenv
if $UNITTEST_USE_VENV ; then
    deactivate_venv
    # drop_venv # What happens if we already provided an existing venv???
fi


## Go back to initial PWD
cd $CURR_PWD

