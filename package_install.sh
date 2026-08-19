#!/usr/bin/env bash

# ==============================================================================
# SINGLE-FILE DISTRIBUTION SHELL PACKAGE 
# 
# PROJECT     : Shell-Formatter-Package  
# ORIGIN URL  : https://github.com/AeonDigital/Shell-Mngm-Package  
# EXPORTED AT : 2026-08-20 23:20:31  
# LICENSE     : MIT [ https://github.com/AeonDigital/Shell-Mngm-Package/LICENSE ]  
# ==============================================================================



if [ -z "${codeNL+x}" ]; then
declare -gr codeNL=$'\n'
fi
declare -g SHELL_PACKAGE_CLEAN_ARG=""
declare -g SHELL_PACKAGE_FUNCTION_RETURN=""


_shell_package_tools_trim() {
local str="${1}"
str="${str#"${str%%[![:space:]]*}"}" # trim L
str="${str%"${str##*[![:space:]]}"}" # trim R
echo "${str}"
}
_shell_package_tools_trim_edges() {
local str=$(_shell_package_tools_trim "${1}")
str="${str%/}" # remove trailing slash
str="${str#/}" # remove leading slash
echo "${str}"
}
_shell_package_tools_resolve_relative_dir_path() {
local rel_path="${1:-.}"
if [ ! -d "${rel_path}" ]; then
return 1
fi
local abs_dir=$(cd "${rel_path}" && pwd)
echo "${abs_dir}"
return 0
}
_shell_package_tools_resolve_relative_file_path() {
local rel_filepath="${1}"
local parent_dir=""
local file_name=""
local abs_path=""
parent_dir=$(dirname "${rel_filepath}")
file_name=$(basename "${rel_filepath}")
if abs_path=$(cd "${parent_dir}" 2>/dev/null && pwd); then
echo "${abs_path}/${file_name}"
else
return 1
fi
}
_shell_package_tools_remove_traversal() {
local path="${1}"
path="${path#../}"
path="${path//\/..\//\/}"
path="${path%/../}"
path="${path%../}"
echo "${path}"
}
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
local IFS=$'\n'
while read -r str_line_raw || [ -n "${str_line_raw}" ]; do
str_line_clean=$(_shell_package_tools_trim "${str_line_raw}")
if [ "${str_line_clean}" != "" ] && [ "${str_line_clean:0:1}" != "#" ]; then
str_file_content_clean+="${str_line_clean}${codeNL}"
fi
done <<< "${str_file_content_raw}"
SHELL_PACKAGE_FUNCTION_RETURN="${str_file_content_clean}"
return 0
}
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
local expanded=""
if expanded=$(_shell_package_tools_resolve_relative_dir_path "${arg_val}"); then
arg_val="${expanded}"
else
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
shell_package_install() {
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
local local_package_dir_path="${XDG_BIN_HOME:-$HOME/.local/bin}/${package_pathname}"
local local_package_file_path="${local_package_dir_path}/${package_filename}"
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


if [ "${BASH_SOURCE}" = "${0}" ]; then
for arg in "$@"; do
if [[ "${arg}" == -* ]]; then
case ${arg} in
-h|--help)
shell_package_install_help
exit $?
;;
esac
fi
done
shell_package_install "$@"
fi
