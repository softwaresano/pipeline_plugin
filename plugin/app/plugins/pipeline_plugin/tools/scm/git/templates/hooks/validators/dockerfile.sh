function validate() {
  command -v hadolint >/dev/null || return 126
  hadolint "$file_name" 2>/dev/stdout
}