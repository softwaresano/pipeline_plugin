#!/bin/bash
function createrepo(){
    local directory=$1
    [[ "$1" == "" ]] && _log "[ERROR] directory parameter is mandatory" && exit 1
    eval "$REMOTE_COMMAND mkdir -p $directory" && \
       eval "$REMOTE_COMMAND /usr/bin/createrepo -s sha -d --update $directory" && \
       eval "$REMOTE_COMMAND /usr/bin/repoview $directory"
}