#!/usr/bin/env bash

# _shell_package_validate_arg_required — Validate that a mandatory argument is not
# empty.
# 
# Arguments:
# - arg_val:     The fully processed value of the argument to test.
# - arg_idx:     The original index position of the argument (e.g., 1 for $1).
# - arg_err_msg: The custom error descriptive message to print.
# - arg_err_tip: An optional contextual troubleshooting tip for the user.
# 
# Return Codes:
# - 1: If the argument value is empty.
_shell_package_validate_arg_required() {
  local arg_val="${1}"
  local arg_idx="${2}"
  local arg_err_msg="${3}"
  local arg_err_tip=$(_shell_package_tools_trim "${4}")

  if [ "${arg_val}" = "" ]; then
    local indent="      "

    echo "[ERR] [ \$${arg_idx} ][ required ] ${arg_err_msg}."
    if [ "${arg_err_tip}" != "" ]; then
      echo "${indent}${arg_err_tip//$codeNL/$codeNL$indent}"
    fi
    return 1
  fi
}



# _shell_package_validate_arg_exist_dir — Assert that the evaluated argument maps
# to an existing system directory.
# 
# Arguments:
# - arg_raw:     The raw unexpanded string originally provided by the user.
# - arg_val:     The post-processed/expanded absolute directory path.
# - arg_idx:     The original index position of the argument (e.g., 2 for $2).
# - arg_err_msg: The custom error descriptive message to print.
# - arg_err_tip: An optional contextual troubleshooting tip for the user.
# 
# Return Codes:
# - 1: If the directory target does not exist or is not a directory.
_shell_package_validate_arg_exist_dir() {
  local arg_raw="${1}"
  local arg_val="${2}"
  local arg_idx="${3}"
  local arg_err_msg="${4}"
  local arg_err_tip=$(_shell_package_tools_trim "${5}")
  local indent="      "

  if [ ! -d "${arg_val}" ]; then
    echo "[ERR] [ \$${arg_idx} ][ non-existent directory ] ${arg_err_msg}."
    if [ "${arg_err_tip}" != "" ]; then
      echo "${indent}${arg_err_tip//$codeNL/$codeNL$indent}"
    fi

    echo "${indent}Given: '${arg_raw}'"
    if [ "${arg_val}" != "" ] && [ "${arg_raw}" != "${arg_val}" ]; then
      echo "${indent}Expanded to: '${arg_val}'"
    fi
    return 1
  fi
}



# _shell_package_validate_arg_exist_filer — Assert that the evaluated argument maps
# to an existing file.
# 
# Arguments:
# - arg_raw:     The raw unexpanded string originally provided by the user.
# - arg_val:     The post-processed/expanded absolute file path.
# - arg_idx:     The original index position of the argument (e.g., 2 for $2).
# - arg_err_msg: The custom error descriptive message to print.
# - arg_err_tip: An optional contextual troubleshooting tip for the user.
# 
# Return Codes:
# - 1: If the file target does not exist or is not a file.
_shell_package_validate_arg_exist_file() {
  local arg_raw="${1}"
  local arg_val="${2}"
  local arg_idx="${3}"
  local arg_err_msg="${4}"
  local arg_err_tip=$(_shell_package_tools_trim "${5}")
  local indent="      "

  if [ ! -f "${arg_val}" ]; then
    echo "[ERR] [ \$${arg_idx} ][ non-existent file ] ${arg_err_msg}."
    if [ "${arg_err_tip}" != "" ]; then
      echo "${indent}${arg_err_tip//$codeNL/$codeNL$indent}"
    fi

    echo "${indent}Given: '${arg_raw}'"
    if [ "${arg_val}" != "" ] && [ "${arg_raw}" != "${arg_val}" ]; then
      echo "${indent}Expanded to: '${arg_val}'"
    fi
    return 1
  fi
}



# _shell_package_validate_arg — Orchestrate argument pre-processing pipelines and
# validation rules.
# 
# Arguments:
# - arg_val:           The raw initial argument value to test.
# - arg_idx:           The index pointer representing the parameter position.
# - arg_pre_proc:      The pipeline operation to run first ("trim", "trim_edges",
#   "expand_dir", "remove_traversal").
# - arg_err_msg:       The core failure message to output on validation error.
# - arg_err_tip:       The multi-line technical tip to show users during a failure
#   crash.
# - arg_validate_type: The type check rule to execute ("required", "exist_dir").
# 
# Returns:
# - Mutates the global SHELL_PACKAGE_CLEAN_ARG variable with the fully processed
#   string.
# 
# Return Codes:
# - 1: If an unsupported pipeline parameter is supplied or if validation filters
#   crash.
_shell_package_validate_arg() {
  SHELL_PACKAGE_CLEAN_ARG=""

  local arg_val="${1}"
  local arg_idx="${2}"
  local arg_pre_proc=$(_shell_package_tools_trim "${3}")

  local arg_err_msg="${4}"
  local arg_err_tip="${5}"

  local arg_validate_type=$(_shell_package_tools_trim "${6}")

  if [ "${arg_pre_proc}" != "" ]; then
    case "${arg_pre_proc}" in
      "trim")
        arg_val=$(_shell_package_tools_trim "${arg_val}")
        ;;

      "trim_edges")
        arg_val=$(_shell_package_tools_trim_edges "${arg_val}")
        ;;

      "expand_dir")
        # Catch subshell return failures from invalid paths
        local expanded=""
        if expanded=$(_shell_package_tools_resolve_relative_dir_path "${arg_val}"); then
          arg_val="${expanded}"
        else
          # Trigger existence error if folder expansion fails during pre-processing
          _shell_package_validate_arg_exist_dir "${1}" "${arg_val}" "${arg_idx}" "${arg_err_msg}" "${arg_err_tip}"
          if [ $? -ne 0 ]; then return 1; fi
        fi
        ;;

      "remove_traversal")
        arg_val=$(_shell_package_tools_remove_traversal "${arg_val}")
        ;;

      *)
        echo "[ERR] [ _shell_package_validate_arg ][ \$3 ] Invalid pre-proc argument."
        echo "      Given: '${arg_pre_proc}'"
        return 1
        ;;
    esac
  fi

  if [ "${arg_validate_type}" != "" ]; then
    case "${arg_validate_type}" in
      "required")
        _shell_package_validate_arg_required "${arg_val}" "${arg_idx}" "${arg_err_msg}" "${arg_err_tip}"
        if [ $? -ne 0 ]; then return 1; fi
        ;;

      "exist_dir")
        _shell_package_validate_arg_exist_dir "${1}" "${arg_val}" "${arg_idx}" "${arg_err_msg}" "${arg_err_tip}"
        if [ $? -ne 0 ]; then return 1; fi
        ;;

      "exist_file")
        _shell_package_validate_arg_exist_file "${1}" "${arg_val}" "${arg_idx}" "${arg_err_msg}" "${arg_err_tip}"
        if [ $? -ne 0 ]; then return 1; fi
        ;;

      *)
        echo "[ERR] [ _shell_package_validate_arg ][ \$6 ] Invalid validate-type argument."
        echo "      Given: '${arg_validate_type}'"
        return 1
        ;;
    esac
  fi

  SHELL_PACKAGE_CLEAN_ARG="${arg_val}"
}
