#!/bin/bash
function createrepo(){
    local directory=$1
    [[ "$1" == "" ]] && _log "[ERROR] directory parameter is mandatory" && exit 1
    eval "$REMOTE_COMMAND mkdir -p $directory" && \
      eval "$REMOTE_COMMAND /usr/bin/createrepo -s sha -d --update $directory"
    [[ $? != 0 ]] && return 1
    if which repoview 2>/dev/null; then
      eval "$REMOTE_COMMAND 'rm -rf $directory/repoview;/usr/bin/repoview $directory'"
    fi
}