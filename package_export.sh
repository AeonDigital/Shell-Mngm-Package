#!/usr/bin/env bash

# ==============================================================================
# SINGLE-FILE DISTRIBUTION SHELL PACKAGE 
# 
# PROJECT     : Shell-Formatter-Package  
# ORIGIN URL  : https://github.com/AeonDigital/Shell-Mngm-Package  
# EXPORTED AT : 2026-08-22 22:39:51  
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
local curl_output=$(curl -sSL -S -w "%{http_code}" "${download_full_url}" -o "${download_save_full_path}" 2>&1)
local curl_status=$?
if [ "${curl_status}" != 0 ]; then
echo "[ERR] :: Download fail."
echo "         Target : '${download_full_url}'"
echo "         Network Error: ${curl_output%000}"
rm -f "${download_save_full_path}"
return 1
fi
local http_code="${curl_output: -3}"
if [[ ! "${http_code}" =~ ^2[0-9]{2}$ ]]; then
echo "[ERR] :: Download fail."
echo "         Target : '${download_full_url}'"
echo "         HTTP Status Code: ${http_code}"
rm -f "${download_save_full_path}"
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


_shell_package_export_header() {
SHELL_PACKAGE_FUNCTION_RETURN=""
local project_url=$(_shell_package_tools_trim "${1}")
local project_name=$(_shell_package_tools_trim "${2}")
local project_license_type=$(_shell_package_tools_trim "${3}")
local project_license_url=$(_shell_package_tools_trim "${4}")
if  [ "${project_name}" = "" ] ||
[ "${project_url}" = "" ] ||
[ "${project_license_type}" = "" ] ||
[ "${project_license_url}" = "" ]; then
return 1
fi
local current_date=$(date +"%Y-%m-%d %H:%M:%S")
local header=""
header+="# ==============================================================================${codeNL}"
header+="# SINGLE-FILE DISTRIBUTION SHELL PACKAGE ${codeNL}"
header+="# ${codeNL}"
header+="# PROJECT     : ${project_name}  ${codeNL}"
header+="# ORIGIN URL  : ${project_url}  ${codeNL}"
header+="# EXPORTED AT : ${current_date}  ${codeNL}"
header+="# LICENSE     : ${project_license_type} [ ${project_url}/${project_license_url} ]  ${codeNL}"
header+="# ==============================================================================${codeNL}${codeNL}"
SHELL_PACKAGE_FUNCTION_RETURN="${header}"
return 0
}
shell_package_export_help() {
local msg=""
msg+="NAME${codeNL}"
msg+="  shell_package_export - Single-file shell script distribution packager${codeNL}${codeNL}"
msg+="SUMMARY${codeNL}"
msg+="  shell_package_export <project_url> <project_name> <license_type> <license_url>${codeNL}"
msg+="                       <project_root_path> [source_dir_path] [assets_dir_path]${codeNL}"
msg+="                       <export_file_path>${codeNL}${codeNL}"
msg+="DESCRIPTION${codeNL}"
msg+="  Validates project metadata, safely expands relative paths, reads individual source${codeNL}"
msg+="  and asset shell scripts, minifies their content by stripping comments/whitespace,${codeNL}"
msg+="  and compiles them sequentially into a single unified distribution executable.${codeNL}${codeNL}"
msg+="ARGUMENTS${codeNL}"
msg+="  \$1  project_url          The repository or home URL of the project (e.g., github URL).${codeNL}"
msg+="                            * Required.${codeNL}${codeNL}"
msg+="  \$2  project_name         The descriptive name of the project.${codeNL}"
msg+="                            * Required.${codeNL}${codeNL}"
msg+="  \$3  license_type         The short identifier of the license (e.g., MIT, Apache-2.0).${codeNL}"
msg+="                            * Required.${codeNL}${codeNL}"
msg+="  \$4  license_url          The relative path to the license file starting from the project_url.${codeNL}"
msg+="                            * Required.${codeNL}${codeNL}"
msg+="  \$5  project_root_path    The absolute path to the project root directory. Must exist.${codeNL}"
msg+="                            * Required.${codeNL}${codeNL}"
msg+="  \$6  source_dir_path      Relative path from 'project_root_path' containing core scripts.${codeNL}"
msg+="                            * Optional. Defaults to 'project_root_path' if empty.${codeNL}${codeNL}"
msg+="  \$7  assets_dir_path      Relative path from 'project_root_path' containing asset dependency scripts.${codeNL}"
msg+="                            * Optional. Processed before core scripts if provided.${codeNL}${codeNL}"
msg+="  \$8  export_file_path     The relative path from 'project_root_path' where the single bundled file${codeNL}"
msg+="                            will be compiled and created (automatically enforces '.sh' extension).${codeNL}"
msg+="                            * Required.${codeNL}${codeNL}"
msg+="RETURN CODES${codeNL}"
msg+="  0   Success              The single-file distribution package was successfully exported.${codeNL}"
msg+="  1   Failure              Validation failed, target directories missing, write permission error${codeNL}"
msg+="                           or download fail.${codeNL}${codeNL}"
msg+="EXAMPLES${codeNL}"
msg+="  Standard usage with basic core scripts folder:${codeNL}"
msg+="    shell_package_export \"https://github.com\" \"MyApp\" \"MIT\" \"main/LICENSE\" \\${codeNL}"
msg+="                         \"/home/user/projects/myapp\" \"src/scripts\" \"\" \"dist/bundle\"${codeNL}${codeNL}"
msg+="  Advanced bundle combining assets and core source code folders:${codeNL}"
msg+="    shell_package_export \"https://github.com\" \"MyApp\" \"MIT\" \"main/LICENSE\" \\${codeNL}"
msg+="                         \"/home/user/projects/myapp\" \"src/core\" \"src/assets\" \"build/release.sh\"${codeNL}"
echo -e "${msg}"
}
shell_package_export() {
local tmp_tip=""
local file=""
_shell_package_validate_arg "${1}" "1" "trim_edges" "Enter project url" "" "required"
if [ $? -ne 0 ]; then return 1; fi
local project_url="${SHELL_PACKAGE_CLEAN_ARG}"
_shell_package_validate_arg "${2}" "2" "trim_edges" "Enter project name" "" "required"
if [ $? -ne 0 ]; then return 1; fi
local project_name="${SHELL_PACKAGE_CLEAN_ARG}"
_shell_package_validate_arg "${3}" "3" "trim_edges" "Enter licence type" "" "required"
if [ $? -ne 0 ]; then return 1; fi
local project_license_type="${SHELL_PACKAGE_CLEAN_ARG}"
_shell_package_validate_arg "${4}" "4" "trim_edges" "Enter licence url" "Expected relative path starting in project url." "required"
if [ $? -ne 0 ]; then return 1; fi
local project_license_url="${SHELL_PACKAGE_CLEAN_ARG}"
_shell_package_validate_arg "${5}" "5" "trim_edges" "Enter project absolute root dir path" "" "required"
if [ $? -ne 0 ]; then return 1; fi
local project_root_path="${SHELL_PACKAGE_CLEAN_ARG}"
if [ "${5:0:1}" = "/" ]; then project_root_path="/${project_root_path}"; fi
_shell_package_validate_arg "${project_root_path}" "5" "expand_dir" "Enter existent project absolute root path" "" "exist_dir"
if [ $? -ne 0 ]; then return 1; fi
local project_root_path="${SHELL_PACKAGE_CLEAN_ARG}"
local source_dir_path=$(_shell_package_tools_trim_edges "${6}")
if [ "${source_dir_path}" = "" ]; then
source_dir_path="${project_root_path}"
else
source_dir_path=$(_shell_package_tools_remove_traversal "${source_dir_path}")
source_dir_path="${project_root_path}/${source_dir_path}"
tmp_tip=""
tmp_tip+="Expected to be empty or the relative path (starting from root_path)"${codeNL}
tmp_tip+="to the source directory of scripts to be exported."
_shell_package_validate_arg "${source_dir_path}" "6" "" "Enter a valid source dir path" "${tmp_tip}" "exist_dir"
if [ $? -ne 0 ]; then return 1; fi
source_dir_path="${SHELL_PACKAGE_CLEAN_ARG}"
fi
local assets_dir_path=$(_shell_package_tools_trim_edges "${7}")
if [ "${assets_dir_path}" != "" ]; then
assets_dir_path=$(_shell_package_tools_remove_traversal "${assets_dir_path}")
assets_dir_path="${project_root_path}/${assets_dir_path}"
tmp_tip=""
tmp_tip+="Expected to be empty or the relative path (starting from root_path)"${codeNL}
tmp_tip+="to the assets directory of scripts to be exported."
_shell_package_validate_arg "${assets_dir_path}" "7" "" "Enter a valid assets dir path" "${tmp_tip}" "exist_dir"
if [ $? -ne 0 ]; then return 1; fi
assets_dir_path="${SHELL_PACKAGE_CLEAN_ARG}"
fi
local export_file_path=$(_shell_package_tools_trim_edges "${8}")
if [ "${export_file_path}" = "" ]; then
export_file_path="${project_name,,}_package.sh"
export_file_path="${export_file_path//-/_}"
else
tmp_tip=""
tmp_tip+="Expected relative file path starting in project root directory."
_shell_package_validate_arg "${8}" "8" "trim_edges" "Enter export file path" "${tmp_tip}" "required"
if [ $? -ne 0 ]; then return 1; fi
local export_file_path="${SHELL_PACKAGE_CLEAN_ARG}"
export_file_path=$(_shell_package_tools_remove_traversal "${export_file_path}")
export_file_path="${project_root_path}/${export_file_path}"
if [[ "${export_file_path}" != *.sh ]]; then
export_file_path="${export_file_path}.sh"
fi
fi
local use_autoexec=$(_shell_package_tools_trim_edges "${9}")
if [ "${use_autoexec}" != "" ]; then
tmp_tip=""
tmp_tip+="Expected relative file path starting in project root directory."
use_autoexec=$(_shell_package_tools_remove_traversal "${use_autoexec}")
use_autoexec="${project_root_path}/${use_autoexec}"
_shell_package_validate_arg "${use_autoexec}" "9" "remove_traversal" "Enter autoexec file (optional)" "${tmp_tip}" "exist_file"
if [ $? -ne 0 ]; then return 1; fi
use_autoexec="${SHELL_PACKAGE_CLEAN_ARG}"
fi
local -a array_export_tgt_files=()
local has_files="0"
if [ "${assets_dir_path}" != "" ]; then
while IFS= read -r -d '' file; do
has_files="1"
array_export_tgt_files+=("${file}")
done < <(find "${assets_dir_path}" -type f -name "*.sh" ! -name "*_test.sh" ! -name "*_autoexec.sh" -print0 | LC_ALL=C sort -z)
if [ "${has_files}" -eq 0 ]; then
echo "[ ! ] No .sh asset file found in '${assets_dir_path}'."
echo "[END] The package export was interrupted."
return 0
fi
has_files="0"
fi
while IFS= read -r -d '' file; do
has_files="1"
array_export_tgt_files+=("${file}")
done < <(find "${source_dir_path}" -type f -name "*.sh" ! -name "*_test.sh" ! -name "*_autoexec.sh" -print0 | LC_ALL=C sort -z)
if [ "${has_files}" -eq 0 ]; then
echo "[ ! ] No .sh target file found in '${source_dir_path}'."
echo "[END] The package export was interrupted."
return 0
fi
if [ "${use_autoexec}" != "" ]; then
array_export_tgt_files+=("${use_autoexec}")
fi
_shell_package_export_header "${project_url}" "${project_name}" "${project_license_type}" "${project_license_url}"
local str_file_package=""
str_file_package+="#!/usr/bin/env bash${codeNL}${codeNL}"
str_file_package+="${SHELL_PACKAGE_FUNCTION_RETURN}"
str_file_package+="${codeNL}${codeNL}"
for file in "${array_export_tgt_files[@]}"; do
_shell_package_tools_minify_file_content "${file}"
str_file_package+="${SHELL_PACKAGE_FUNCTION_RETURN}"
str_file_package+="${codeNL}${codeNL}"
done
str_file_package=$(_shell_package_tools_trim "${str_file_package}")
echo "${str_file_package}" > "${export_file_path}"
if [ $? != 0 ]; then
echo "[ERR] Error on create '${export_file_path}' file."
return 1
fi
chmod +x "${export_file_path}"
if [ $? -ne 0 ]; then
echo "[ x ] :: Could not grant execution (+x) permission for the exported package file."
echo "         Check the permissions and try running:"
echo "         > chmod +x '${export_file_path}'"
echo "[END] :: Packaging completed with partial success.."
return 1
fi
echo "[OKK] :: File '${export_file_path}' created."
echo "         To run this package use:"
echo "         > ${export_file_path}"
return 0
}


if [ "${BASH_SOURCE}" = "${0}" ]; then
for arg in "$@"; do
if [[ "${arg}" == -* ]]; then
case ${arg} in
-h|--help)
shell_package_export_help
exit $?
;;
esac
fi
done
shell_package_export "$@"
fi
