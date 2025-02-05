#!/bin/bash
reports_path=${REPORTS_PATH:-target/reports}
only_repo=($(git ls-tree --name-only HEAD))
mkdir -p "${reports_path:?}"
grep -Ern '^BANDIT_EXCLUSIONS=|^CODESPELL_EXCLUSIONS=|^NO_TESTING_RESOURCES_REGEX=|/\*( |\t)*cppcheck-suppress|//( |\t)*cppcheck-suppress|^EXTRA_JSCPD_IGNORE=|#( |\t)*pylint:( |\t)*skip-file|#( |\t)*pragma( |\t)no( |\t)cover|#( |\t)*shellcheck( |\t)*disable=( |\t)*|#( |\t)*rubocop:( |\t)*disable|#( |\t)*pylint:( |\t)*disable|#( |\t)*NOSONAR|sonar\.exclusions( |\t)*=|#( |\t)*lint:ignore|( |\t)*/\*( |\t)*NOSONAR( |\t)*\*/|//( |\t)*NOSONAR|( |\t)*/\*( |\t)*eslint-disable( |\t)*\*/|//( |\t)*eslint-disable' "${only_repo[@]}" | grep -Ev "^external/" >"${reports_path:?}/warning-exclusions.txt"
exit 0
