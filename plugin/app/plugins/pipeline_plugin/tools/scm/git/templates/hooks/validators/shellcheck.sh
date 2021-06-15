function validate() {
  shellcheck -x -s bash "$file_name" 2>/dev/stdout
}