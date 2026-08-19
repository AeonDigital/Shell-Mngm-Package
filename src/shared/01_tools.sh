#!/usr/bin/env bash

# _shell_package_tools_trim — Strip leading and trailing whitespace characters from
# a string.
# 
# Arguments:
# - str: The raw input string to be trimmed.
# 
# Returns:
# - Outputs the trimmed string to stdout.
_shell_package_tools_trim() {
  local str="${1}"
  str="${str#"${str%%[![:space:]]*}"}" # trim L
  str="${str%"${str##*[![:space:]]}"}" # trim R
  echo "${str}"
}



# _shell_package_tools_trim_edges — Strip leading/trailing whitespaces, and remove
# leading/trailing slashes if present.
# 
# Arguments:
# - str: The raw input string or directory path to be processed.
# 
# Returns:
# - Outputs the trimmed string without leading or trailing slashes to stdout.
_shell_package_tools_trim_edges() {
  local str=$(_shell_package_tools_trim "${1}")

  str="${str%/}" # remove trailing slash
  str="${str#/}" # remove leading slash

  echo "${str}"
}



# _shell_package_tools_resolve_relative_dir_path — Resolve a relative directory path
# (like '.' or '..') into its absolute equivalent.
# 
# Arguments:
# - rel_path: The relative directory path string to be resolved.
# 
# Returns:
# - Outputs the absolute directory path string to stdout on success.
# 
# Return Codes:
# - 1: If the specified directory does not exist or cannot be accessed.
_shell_package_tools_resolve_relative_dir_path() {
  local rel_path="${1:-.}"

  if [ ! -d "${rel_path}" ]; then
    return 1
  fi

  local abs_dir=$(cd "${rel_path}" && pwd)
  echo "${abs_dir}"
  return 0
}



# _shell_package_tools_resolve_relative_file_path — Resolve a relative file path
# into its absolute equivalent.
# 
# Arguments:
# - rel_filepath: The relative file path string to be resolved.
# 
# Returns:
# - Outputs the absolute file path string to stdout on success.
# 
# Return Codes:
# - 1: If the parent directory of the file does not exist or cannot be accessed.
_shell_package_tools_resolve_relative_file_path() {
  local rel_filepath="${1}"
  local parent_dir=""
  local file_name=""
  local abs_path=""

  parent_dir=$(dirname "${rel_filepath}")
  file_name=$(basename "${rel_filepath}")

  # Resolves the parent directory inside a subshell
  if abs_path=$(cd "${parent_dir}" 2>/dev/null && pwd); then
    echo "${abs_path}/${file_name}"
  else
    return 1
  fi
}



# _shell_package_tools_remove_traversal — Strip all relative parent directory markers
# ('../' and '..') from a path string.
# 
# Arguments:
# - path: The raw path string to be sanitized.
# 
# Returns:
# - Outputs the sanitized path string to stdout.
_shell_package_tools_remove_traversal() {
  local path="${1}"

  # 1. Remove '../' when it appears at the very beginning
  path="${path#../}"

  # 2. Remove all occurrences of '/../' from the middle of the string
  path="${path//\/..\//\/}"

  # 3. Remove '../' if it appears at the very end of the string
  path="${path%/../}"
  path="${path%../}"

  echo "${path}"
}



# _shell_package_tools_minify_file_content — Read, minify, and strip comments from
# a target shell script file.
# 
# Arguments:
# - file_path: The absolute or relative path to the target script file.
# 
# Returns:
# - Outputs the cleaned file content without leading/trailing spaces or code comments
#   to SHELL_PACKAGE_FUNCTION_RETURN.
_shell_package_tools_minify_file_content() {
  SHELL_PACKAGE_FUNCTION_RETURN=""

  local str_file_content_raw=$(< "${1}")
  str_file_content_raw=$(_shell_package_tools_trim "${str_file_content_raw}")
  if [ "${str_file_content_raw}" = "" ]; then
    return 0
  fi

  local str_file_content_clean=""
  local str_line_raw=""
  local str_line_clean=""

  # Use local IFS to safely iterate over text lines
  local IFS=$'\n'
  while read -r str_line_raw || [ -n "${str_line_raw}" ]; do
    str_line_clean=$(_shell_package_tools_trim "${str_line_raw}")

    # Strip empty lines and lines starting with comment markers (#)
    if [ "${str_line_clean}" != "" ] && [ "${str_line_clean:0:1}" != "#" ]; then
      str_file_content_clean+="${str_line_clean}${codeNL}"
    fi
  done <<< "${str_file_content_raw}"

  SHELL_PACKAGE_FUNCTION_RETURN="${str_file_content_clean}"
  return 0
}



# _shell_package_tools_download — Download a file via curl, with strict HTTP failure
# and network error trapping.
# 
# Arguments:
# - download_full_url:        The full remote URL of the file to be downloaded.
# - download_save_full_path:  The absolute destination file path where the file will
#   be saved.
# 
# Returns:
# - None on success. Writes the file directly to disk.
# 
# Return Codes:
# - 1: If the curl command fails due to network/DNS issues or returns a non-2xx HTTP
#   status code.
_shell_package_tools_download() {
  local download_full_url="${1}"
  local download_save_full_path="${2}"


  local curl_output=$(curl -sSL -S -w "%{http_code}" "${target_url}" -o "${local_package_file_path}" 2>&1)


  local curl_status=$?
  if [ "${curl_status}" != 0 ]; then
    echo "[ERR] :: Download fail."
    echo "         Target : '${target_url}'"
    echo "         Network Error: ${curl_output%000}"

    rm -f "${local_package_file_path}"
    return 1
  fi


  local http_code="${curl_output: -3}"
  if [[ ! "${http_code}" =~ ^2[0-9]{2}$ ]]; then
    echo "[ERR] :: Download fail."
    echo "         Target : '${target_url}'"
    echo "         HTTP Status Code: ${http_code}"

    rm -f "${local_package_file_path}"
    return 1
  fi

  return 0
}
