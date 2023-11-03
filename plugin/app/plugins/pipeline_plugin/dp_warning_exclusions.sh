#!/bin/bash
reports_path=${REPORTS_PATH:-target/reports}
mkdir -p "${reports_path:?}"
grep -Ern '^EXTRA_JSCPD_IGNORE=|#( |\t)*pylint:( |\t)*skip-file|#( |\t)*pragma( |\t)no( |\t)cover|#( |\t)*shellcheck( |\t)*disable=( |\t)*|#( |\t)*rubocop:( |\t)*disable|#( |\t)*pylint:( |\t)*disable|#( |\t)*NOSONAR|sonar\.exclusions( |\t)*=|#( |\t)*lint:ignore|( |\t)*/\*( |\t)*NOSONAR( |\t)*\*/|//( |\t)*NOSONAR|( |\t)*/\*( |\t)*eslint-disable( |\t)*\*/|//( |\t)*eslint-disable' -- * | grep -Ev "${reports_path:?}/|target/.dp_rpm/|sonar-project.properties|pylint.txt" >"${reports_path:?}/warning-exclusions.txt"
exit 0
