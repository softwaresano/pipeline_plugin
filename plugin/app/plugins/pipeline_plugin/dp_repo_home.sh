#!/bin/bash
dp_artifacts_repo_home.sh $([ "$(dp_is_stable_build.sh)" == "true" ] && echo "false" || echo "true" )