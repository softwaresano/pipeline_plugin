Python build scripts
====================

TDAF-pipeline scripts to build Python components. Given that there is no compilation, the scripts only install required RPMs, create a virtualenv, install Python requirements and local requirements and run the configured tests command.


# install_local_reqs

Python script which installs all local requirements. By local requirements we understand all other components of the project required by current component. To *install* them a `.pth` file is created linking other components `src` folder.

## Usage

```bash
$ ./install_local_reqs -h
usage: install_local_reqs [-h] [--version] [-r LOCAL_REQS] [-v] [--site-packages PATH]

Install local requirements (other folders) as a .pth file inside site-packages

optional arguments:
  -h, --help            show this help message and exit
  --version             Display program version and exit

Program options:
  -r LOCAL_REQS, --reqs LOCAL_REQS
                        Local requirements file, 'requirements_local.txt' by default
  -v, --verbose         Print debug traces

Advanced options:
  --site-packages PATH  Provide site-packages location
```

The script is designed to be run from the `src` folder of any component, so it takes the `requirements_local.txt` in the same folder and it automatically autodetects current Python's site-packages folder (where `.pth` file is placed). However, it can be run from any other folder.

## Configuration

The provided `requirements_local.txt` file must contain URIs with relative paths to the other components, one per line. The paths must be relative to the provided `requirements_local.txt` file, and they can be specified in two different ways:

```bash
$ cat sprayer-status-feeder/src/requirements_local.txt
file:../../sprayer-commons/src#egg=sprayer-commons
file://../../sprayer-dispatcher/src#egg=sprayer-dispatcher
```

## Examples

 * Empty `requirements_local.txt` file:

```bash
$ cat requirements_local.txt

$ install_local_reqs
[WARNING] 2013-06-12 15:13:44,801 | No requirements to install. Skipping
```

 * Autodetect `requirements_local.txt` and provide `-v` argument:

```bash
$ cat requirements_local.txt
file:../../sprayer-commons/src#egg=sprayer-commons

$ install_local_reqs
[INFO] 2013-06-12 15:15:50,939 | Successfully installed 1 local requirements of 'sprayer-api-rest' at '/Users/pev/venvs/sprayer/lib/python2.7/site-packages/sprayer-api-rest.reqs.local.pth'
[sprayer]pev@macPablo:~/wspace/sprayer/sprayer-api-rest/src (feature/neore)$ PATH=$PATH:/Users/pev/wspace/tdaf-pipeline/profiles/python/building install_local_reqs -v
[DEBUG] 2013-06-12 15:15:56,454 | Normalized 'file:../../sprayer-commons/src#egg=sprayer-commons' as '/Users/pev/wspace/sprayer/sprayer-commons/src'
[DEBUG] 2013-06-12 15:15:56,454 | Proceeding to install paths: [u'/Users/pev/wspace/sprayer/sprayer-commons/src']
[DEBUG] 2013-06-12 15:15:56,455 | Replacing '/Users/pev/venvs/sprayer/lib/python2.7/site-packages/sprayer-api-rest.reqs.local.pth' with 'sprayer-api-rest' requirements
[DEBUG] 2013-06-12 15:15:56,455 | Installed in '/Users/pev/venvs/sprayer/lib/python2.7/site-packages/sprayer-api-rest.reqs.local.pth' requirement '/Users/pev/wspace/sprayer/sprayer-commons/src'
[INFO] 2013-06-12 15:15:56,455 | Successfully installed 1 local requirements of 'sprayer-api-rest' at '/Users/pev/venvs/sprayer/lib/python2.7/site-packages/sprayer-api-rest.reqs.local.pth'
$ cat /Users/pev/venvs/sprayer/lib/python2.7/site-packages/sprayer-api-rest.reqs.local.pth
/Users/pev/wspace/sprayer/sprayer-commons/src
```

 * Provide a `requirements_local.txt` and `-v` argument:

```bash
$ cat src/requirements_local.txt
file:../../sprayer-commons/src#egg=sprayer-commons
file://../../sprayer-dispatcher/src#egg=sprayer-commons
$ PATH=$PATH:/Users/pev/wspace/tdaf-pipeline/profiles/python/building install_local_reqs -v -r src/requirements_local.txt
[DEBUG] 2013-06-12 15:32:01,938 | Normalized 'file:../../sprayer-commons/src#egg=sprayer-commons' as '/Users/pev/wspace/sprayer/sprayer-commons/src'
[DEBUG] 2013-06-12 15:32:01,939 | Normalized 'file://../../sprayer-dispatcher/src#egg=sprayer-commons' as '/Users/pev/wspace/sprayer/sprayer-dispatcher/src'
[DEBUG] 2013-06-12 15:32:01,939 | Proceeding to install paths: [u'/Users/pev/wspace/sprayer/sprayer-commons/src', u'/Users/pev/wspace/sprayer/sprayer-dispatcher/src']
[DEBUG] 2013-06-12 15:32:01,939 | Replacing '/Users/pev/venvs/sprayer/lib/python2.7/site-packages/sprayer-status-feeder.reqs.local.pth' with 'sprayer-status-feeder' requirements
[DEBUG] 2013-06-12 15:32:01,940 | Installed in '/Users/pev/venvs/sprayer/lib/python2.7/site-packages/sprayer-status-feeder.reqs.local.pth' requirement '/Users/pev/wspace/sprayer/sprayer-commons/src'
[DEBUG] 2013-06-12 15:32:01,940 | Installed in '/Users/pev/venvs/sprayer/lib/python2.7/site-packages/sprayer-status-feeder.reqs.local.pth' requirement '/Users/pev/wspace/sprayer/sprayer-dispatcher/src'
[INFO] 2013-06-12 15:32:01,940 | Successfully installed 2 local requirements of 'sprayer-status-feeder' at '/Users/pev/venvs/sprayer/lib/python2.7/site-packages/sprayer-status-feeder.reqs.local.pth'
$ cat /Users/pev/venvs/sprayer/lib/python2.7/site-packages/sprayer-status-feeder.reqs.local.pth
/Users/pev/wspace/sprayer/sprayer-commons/src
/Users/pev/wspace/sprayer/sprayer-dispatcher/src
```


# test.unit.sh

Bash script which installs all requirements (RPMs, Python and local components), creates a virtualenv and launches the unit tests.

## Usage

Just execute the script inside the `src` folder of a component.

## Configuration

Assuming this script is executed inside `PROJECT_ROOT/COMPONENT_ROOT/src` it will load (source) the project and component configuration files (in strict order):
 * **Project** configuration at `$PROJECT_ROOT/neore/config/project.cfg`, affecting all the components.
 * **Local project** configuration at `$PROJECT_ROOT/neore/config/project.local.cfg`, to let developers redefine some settings at project level (affecting all components).
 * **Component** configuration at `$PROJECT_ROOT/$COMPONENT_ROOT/neore/config/component.cfg` to redefine settings at component level. At least it should contain **UNITTESTS_CMD** (see below).
 * **Local component** configuration at `$PROJECT_ROOT/$COMPONENT_ROOT/neore/config/component.local.cfg`, to let developers redefine some settings at component level.

The available configurable options are:

 * Generic config:
   * **PROJECT_NAME**: Name of the project
   * **COMPONENT_NAME**: Name of the component (by default it takes the name of the parent folder where it is launched).
 * RPM dependencies settings:
   * **BUILD_RPM_DEPENDENCIES**: String with all the RPMs to be installed (to execute `dnf install -y $BUILD_RPM_DEPENDENCIES`). If empty, this step is skipped.
   * **BUILD_USE_SUDO_YUM**: Boolean specifying if `yum` must be used with `sudo` (true by default)
 * Virtualenv settings:
   * **VENVS_ROOT**: Path where the virtualenvs are created ("/tmp/build_venvs" by default).
   * **PYTHON_BIN**: Python binary to be used by the virtualenv ("python2.7" by default).
   * **VENV_PATH**: Existing virtualenv to be used. If not specified (default), a new virtualenv is created and installed for each component build.
 * pip settings:
   * **PIP_CACHE_FOLDER**: Folder to be used as pip cache to store and reuse downloaded packages ("/tmp/build_pip_cache" by default).
 * Requirements files settings:
   * **REQUIREMENTS_FILE**: Production Python requirements file ("requirements.txt" by default)
   * **REQUIREMENTS_DEVEL_FILE**: Development or testing Python requirements file ("requirements_dev.txt" by default)
   * **REQUIREMENTS_LOCAL_FILE**: Local (other components) Python requirements file ("requirements_local.txt" by default)
 * Unit tests settings:
   * **PRE_UNITTESTS_CMD**: Commands to be executed before running unit tests. If empty nothing is done.
   * **UNITTESTS_CMD**: Unit tests command. This field is mandatory.
 * Build / unit tests stages selection, to enable or disable them:
   * **UNITTEST_INSTALL_RPMS**: Install RPMs in unit tests stage (true by default)
   * **UNITTEST_USE_VENV**: Create or replace and enable virtualenv in unit tests stage (true by default)
   * **UNITTEST_INSTALL_REQS**: Install production and requirements (true by default)
   * **UNITTEST_INSTALL_LOCAL_REQS**: Install local (other components) requirements (true by default)
   

### Configuration example

```bash

######
# NeoRE PROJECT CONFIGURATION SCRIPT:
#
# All configuration variables must be defined as bash/shell variables
# All folders paths must be defined without slash '/' at the end
#
####

## Project generic setup 
# Name of the project used in traces
PROJECT_NAME="sprayer"

# Name of the project used in traces
# COMPONENT_NAME="sprayer-api-rest"


## RPM dependencies settings
# RPM dependencies to be installed in build (unit tests) stage
BUILD_RPM_DEPENDENCIES="python27-2.7.3-1.pdi python27-devel-2.7.3-1.pdi distribute-0.6.45-1 virtualenv-1.9.1-1 pip-1.3.1-1 openssl-devel sqlite-devel"

# Use sudo when installing RPM dependencies with Yum
BUILD_USE_SUDO_YUM=true


## Virtualenv settings
# Path where virtualenvs are created
VENVS_ROOT="/tmp/build_venvs"

# Python binary to use in venv creation
PYTHON_BIN="python2.7"

# Already existing Virtualenv to be used (skips virtualenv creation)
# VENV_PATH="$HOME/venvs/sprayer"


## pip settings
# Folder to be used as pip cache
PIP_CACHE_FOLDER="/tmp/build_pip_cache"


## Requirements files
# Component Python requirements file
REQUIREMENTS_FILE="requirements.txt"

# Component development Python requirements file
REQUIREMENTS_DEVEL_FILE="requirements_dev.txt"

# Component local Python requirements file
REQUIREMENTS_LOCAL_FILE="requirements_local.txt"


## Unit tests settings
# Directory of test reports
TEST_REPORT_DIR="./target"

# Unit test results
UNIT_TESTS_REPORT_FILE="$TEST_REPORT_DIR/surefire-reports/TEST-nosetests.xml"

# Coverage
COVERAGE_REPORT_FILE="$TEST_REPORT_DIR/site/cobertura/coverage.xml"

# Pre unit test command 
PRE_UNITTESTS_CMD="rm -Rf $TEST_REPORT_DIR && mkdir -p $(dirname $UNIT_TESTS_REPORT_FILE) $(dirname $COVERAGE_REPORT_FILE)"

# Unit tests command
# UNITTESTS_CMD="nosetests -v --with-cover --cover-package=sprayer_commons --cover-erase --cover-branches --cover-xml-file=$COVERAGE_REPORT_FILE --cover-xml --with-xunit --xunit-file=$UNIT_TESTS_REPORT_FILE --nocapture test"


## Stages to execute (boolean values, true by default)
# Install RPMs in unit tests stage (build)
UNITTEST_INSTALL_RPMS=true

# Create or replace and enable virtualenv in unit tests stage (build)
UNITTEST_USE_VENV=true

# Install requirements  in unit tests stage (build)
UNITTEST_INSTALL_REQS=true

# Install local requirements  in unit tests stage (build)
UNITTEST_INSTALL_LOCAL_REQS=true

```

## Example

```
$ PATH=$PATH:$HOME/wspace/tdaf-pipeline/profiles/python/building test.unit.sh
[test.unit.sh] [WARNING] Local project configuration file '/Users/pev/wspace/sprayer/neore/config/project.local.cfg' not found

    ############################################
    ##  NeoRE BUILDING / UNIT TESTING PROCESS ##
    ############################################
     > PROJECT NAME:    sprayer
     > COMPONENT NAME:  sprayer-api-rest
     > BUILD SCRIPT:    /Users/pev/wspace/tdaf-pipeline/profiles/python/building/test.unit.sh

[test.unit.sh][sprayer-api-rest] [INFO] Trying to deactivate current virtualenv
[test.unit.sh][sprayer-api-rest] [INFO] Validating Python binary 'python2.7' /Users/pev/venvs/sprayer/bin/python2.7
[test.unit.sh][sprayer-api-rest] [INFO] Creating virtualenv '/tmp/build_venvs/sprayer-api-rest_20130612_185853' with 'python2.7'
Running virtualenv with interpreter /Users/pev/venvs/sprayer/bin/python2.7
Using real prefix '/System/Library/Frameworks/Python.framework/Versions/2.7'
New python executable in /tmp/build_venvs/sprayer-api-rest_20130612_185853/bin/python2.7
Also creating executable in /tmp/build_venvs/sprayer-api-rest_20130612_185853/bin/python
Installing setuptools............done.
Installing pip...............done.
[test.unit.sh][sprayer-api-rest] [INFO] Installing Python requirements: requirements.txt
Downloading/unpacking https://github.com/downloads/surfly/gevent/gevent-1.0rc2.tar.gz (from -r requirements.txt (line 6))
  Using download cache from /tmp/build_pip_cache/https%3A%2F%2Fgithub.com%2Fdownloads%2Fsurfly%2Fgevent%2Fgevent-1.0rc2.tar.gz
  Running setup.py egg_info for package from https://github.com/downloads/surfly/gevent/gevent-1.0rc2.tar.gz

Downloading/unpacking ujson (from -r requirements.txt (line 3))
  Using download cache from /tmp/build_pip_cache/http%3A%2F%2Fpypi.python.org%2Fpackages%2Fsource%2Fu%2Fujson%2Fujson-1.33.zip
  Running setup.py egg_info for package ujson

...

Successfully installed ujson configparser greenlet gevent-socketio gevent-websocket pyopenssl apns-client kombu mock redis beaker pyzmq circus circus-web Django djangorestframework gevent anyjson amqp iowait psutil Mako MarkupSafe bottle
Cleaning up...
[test.unit.sh][sprayer-api-rest] [INFO] Installing Python devel requirements: requirements_dev.txt
Downloading/unpacking fabric (from -r requirements_dev.txt (line 1))
  Using download cache from /tmp/build_pip_cache/http%3A%2F%2Fpypi.python.org%2Fpackages%2Fsource%2FF%2FFabric%2FFabric-1.6.1.tar.gz

...

Successfully installed fabric coverage nose pysqlite nosexcover django-nose paramiko pycrypto
Cleaning up...
[test.unit.sh][sprayer-api-rest] [INFO] Installing Python local requirements: requirements_local.txt
[INFO] 2013-06-12 19:03:16,543 | Successfully installed 1 local requirements of 'sprayer-api-rest' at '/tmp/build_venvs/sprayer-api-rest_20130612_185853/lib/python2.7/site-packages/sprayer-api-rest.reqs.local.pth'
[test.unit.sh][sprayer-api-rest] [INFO] Preparing unit test environment
[test.unit.sh][sprayer-api-rest] [INFO] Executing unit tests 'python sprayer_api_rest/manage.py test --settings api.settings_tests admin accepter api'
nosetests --verbosity 1 admin accepter api -s -v --cover-erase --cover-branches --with-cov --cover-xml --cover-package=sprayer_api_rest --cover-xml-file=target/site/cobertura/coverage.xml --with-xunit --xunit-file=target/surefire-reports/TEST-nosetests.xml
[23993][INFO] 2013-06-12 19:03:18,279 | __init__ | Initializing backend as "redis://127.0.0.1:18888/?db=0"
Creating test database for alias 'default'...
Test endpoint unregister ... [23993][INFO] 2013-06-12 19:03:18,691 | config | Loaded 'accepter' config from files ['/Users/pev/wspace/sprayer/sprayer-commons/src/sprayer_commons/../../config/sprayer.accepter.ini']
[23993][DEBUG] 2013-06-12 19:03:18,692 | config | changing debug config: 20

...

Ran 85 tests in 0.864s

OK
Destroying test database for alias 'default'...
[test.unit.sh][sprayer-api-rest] [INFO] Right now we are not postprocessing unit tests XMLs
[test.unit.sh][sprayer-api-rest] [INFO] Trying to deactivate current virtualenv deactivate
$ echo $?
0
```
