#!/usr/bin/env bash

# shell_package_install_help — Display the CLI manual and usage guide for the shell_package_install
# function.
# 
# Returns:
# - Outputs the formatted manual text to stdout.
shell_package_install_help() {
  local msg=""

  msg+="NAME${codeNL}"
  msg+="  shell_package_install - Automated local single-file package installer${codeNL}${codeNL}"

  msg+="SUMMARYY${codeNL}"
  msg+="  shell_package_install <package_full_url> <package_name> [package_filename]${codeNL}${codeNL}"

  msg+="DESCRIPTION${codeNL}"
  msg+="  Safely prepares the local environment by creating a dedicated subfolder within the${codeNL}"
  msg+="  user's local binary repository (\$XDG_BIN_HOME or ~/.local/bin). It streams the remote${codeNL}"
  msg+="  shell package, validates the network transmission, ensures the correct '.sh' extension,${codeNL}"
  msg+="  and automatically unlocks system execution permissions (+x) on the resulting binary.${codeNL}${codeNL}"

  msg+="ARGUMENTS${codeNL}"
  msg+="  \$1  package_full_url   The complete remote URL pointing directly to the compiled script${codeNL}"
  msg+="                          distribution file (e.g., raw github user content link).${codeNL}"
  msg+="                          * Required.${codeNL}${codeNL}"
  msg+="  \$2  package_name       The unique token identifier for your tool. A container directory${codeNL}"
  msg+="                          will be provisioned with this name under the local bin path.${codeNL}"
  msg+="                          * Required.${codeNL}${codeNL}"
  msg+="  \$3  package_filename   Optional. Custom filename for the saved script. If empty or omitted,${codeNL}"
  msg+="                          it falls back to 'package.sh'. Automatically enforces '.sh'.${codeNL}${codeNL}"

  msg+="RETURN CODES${codeNL}"
  msg+="  0   Success             The distribution package was successfully deployed, unblocked, and verified.${codeNL}"
  msg+="  1   Failure             Deployment aborted due to directory lockouts, transmission crashes, or chmod failures.${codeNL}${codeNL}"

  msg+="EXAMPLES${codeNL}"
  msg+="  Standard remote installation enforcing the default script container filename:${codeNL}"
  msg+="      shell_package_install \"https://githubusercontent.com\" \"md_readi\"${codeNL}${codeNL}"
  msg+="  Custom deployment specifying an explicit destination binary name:${codeNL}"
  msg+="      shell_package_install \"https://seu-site.com\" \"md_readi\" \"run-formatter\"${codeNL}"

  echo -e "${msg}"
}





# shell_package_install — Main installer that sets up local directories, downloads
# the target package, and configures execution permissions.
# 
# Arguments:
# - package_full_url: The full remote URL pointing to the shell script package to
#   download.
# - package_name:     The clean name of the package (used to create the local container
#   directory).
# - package_filename: Optional. The desired name for the downloaded file. Defaults
#   to 'package.sh'.
# 
# Returns:
# - Downloads, moves, and unlocks the script executable inside the local user binary
#   path.
# 
# Return Codes:
# - 0: On successful installation and permission grant.
# - 1: On directory creation failures, download crashes, or permission assignment
#   errors.
shell_package_install() {
  # Changes context to home directory to maintain deployment consistency
  cd "${HOME}"


  _shell_package_validate_arg "${1}" "1" "trim_edges" "Enter package full url" "" "required"
  if [ $? -ne 0 ]; then return 1; fi
  local package_full_url="${SHELL_PACKAGE_CLEAN_ARG}"

  _shell_package_validate_arg "${2}" "2" "trim_edges" "Enter package name" "" "required"
  if [ $? -ne 0 ]; then return 1; fi
  local package_name="${SHELL_PACKAGE_CLEAN_ARG}"
  local package_pathname="${package_name,,}"
  package_pathname="${package_pathname//-/_}"

  local package_filename=$(_shell_package_tools_trim_edges "${3}")
  if [ "${package_filename}" = "" ]; then
    package_filename="package.sh"
  fi
  if [[ "${package_filename}" != *.sh ]]; then
    package_filename="${package_filename}.sh"
  fi


  # Build target paths safely
  local local_package_dir_path="${XDG_BIN_HOME:-$HOME/.local/bin}/${package_pathname}"
  local local_package_file_path="${local_package_dir_path}/${package_filename}"


  # Ensure the container directory exists
  mkdir -p "${local_package_dir_path}"
  if [ $? -ne 0 ]; then
    echo "[ERR] :: Cannot create '${local_package_dir_path}' directory"
    echo "         Check permissions and try again."
    return 1
  fi


  _shell_package_tools_download "${package_full_url}" "${local_package_file_path}"
  if [ $? -ne 0 ]; then
    echo "[ERR] :: Cannot download file from '${package_full_url}'"
    return 1
  fi


  echo "[ v ] :: Package '${package_name}' successfully downloaded to"
  echo "         '${local_package_file_path}'"


  chmod +x "${local_package_file_path}"
  if [ $? -ne 0 ]; then
    echo "[ x ] :: Could not grant execution (+x) permission for the downloaded package."
    echo "         Check the permissions and try running:"
    echo "         > chmod +x '${local_package_file_path}'"
    echo "[END] :: Installation completed with partial success."
    return 1
  fi

  echo "[OKK] :: Installation completed successfully."
  echo "         To run this package use:"
  echo "         > ${local_package_file_path}"
}
