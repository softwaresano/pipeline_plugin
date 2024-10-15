#!/bin/bash
function validate() {
  file --mime-encoding "${file_name:?}"|grep -Eq ': binary$$' &&
		[ -s "${file_name:?}" ] &&
		file --mime-type "${file_name:?}" | grep -qv symlink &&
		dp_log.sh "[INFO] Binary files are not recommended to be stored in a code repository." && return 1
  return 0
}

