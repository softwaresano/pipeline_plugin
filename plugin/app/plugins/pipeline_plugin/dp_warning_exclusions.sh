#!/bin/bash
reports_path=${REPORTS_PATH:-target/reports}
only_repo=($(git ls-tree --name-only HEAD| grep -v '^Makefile$'))
mkdir -p "${reports_path:?}"
grep -Ern '#( |\t)*nosec( |\t)*|/\*( |\t)*cppcheck-suppress|//( |\t)*cppcheck-suppress|^EXTRA_JSCPD_IGNORE=|#( |\t)*type:( |\t)* ignore|#( |\t)*pylint:( |\t)*skip-file|#( |\t)*pragma( |\t)no( |\t)cover|#( |\t)*shellcheck( |\t)*disable=( |\t)*|#( |\t)*rubocop:( |\t)*disable|#( |\t)*pylint:( |\t)*disable|#( |\t)*NOSONAR|sonar\.exclusions( |\t)*=|#( |\t)*lint:ignore|( |\t)*/\*( |\t)*NOSONAR( |\t)*\*/|//( |\t)*NOSONAR|( |\t)*/\*( |\t)*eslint-disable( |\t)*\*/|//( |\t)*eslint-disable' "${only_repo[@]}" | grep -Ev "^external/" >"${reports_path:?}/warning-exclusions.txt"
if git ls-files | grep -xq Makefile; then
  grep -Ern '^YAML_ERRORS_PATH=|^BANDIT_EXCLUSIONS=|^CODESPELL_EXCLUSIONS=|^NO_TESTING_RESOURCES_REGEX=|^CHECK_COVERAGE_PYTHON=' * |grep '^Makefile:'>>"${reports_path:?}/warning-exclusions.txt"
fi
exit 0
