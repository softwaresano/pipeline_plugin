#!/bin/bash
scm_type=$(dp_scm_type.sh)
[[ "$(dp_scm_type.sh)" != "git" ]] && dp_log.sh "[ERROR] Scm compliant is not implemented for $scm_type" && exit 1
source $DP_HOME/tools/scm/$scm_type/dp_scm_compliant.sh