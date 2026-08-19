#!/usr/bin/env bash

# _shell_package_export_header — Generate the distribution package header.
# 
# Arguments:
# - project_url:          The main repository or project home URL.
# - project_name:         The name of the project.
# - project_license_type: The short name of the license (e.g., MIT, Apache-2.0).
# - project_license_url:  The relative path to the license file from the project
#   URL.
# 
# Returns:
# - Outputs the package header to 'SHELL_PACKAGE_FUNCTION_RETURN' on success.
# 
# Return Codes:
# - 1: If any of the required arguments are empty or consist only of whitespace.
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





# shell_package_export_help — Display the CLI manual and usage guide for the shell_package_export
# function.
# 
# Returns:
# - Outputs the formatted manual text to stdout.
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





# shell_package_export — Main orchestrator to validate project metadata, read source
# files, and export a unified shell package.
# 
# Arguments:
# - project_url:          The main repository or project home URL.
# - project_name:         The name of the project.
# - project_license_type: The short name of the license (e.g., MIT, Apache-2.0).
# - project_license_url:  The relative path to the license file from the project
#   URL.
# - project_root_path:    The absolute path to the project's root directory.
# - source_dir_path:      Optional. The relative path to the source scripts. Default:
#   'project_root_path'
# - assets_dir_path:      Optional. The relative path to the assets scripts.
# - export_file_path:     Optional. The relative path (from the project root) where
#   the unified destination file will be written. Default: 'project_name'_'package.sh'
#   (lower)
# - use_autoexec:         Optional. The relative path (from the project root) to
#   a '*_autoexec.sh' file containing the auto-execution rules for the generated
#   package.
# 
# Returns:
# - Writes the compiled shell script package directly to the specified export file
#   path.
# 
# Return Codes:
# - 0: On successful package compilation and export.
# - 1: On validation failures, missing directories, or file write errors.
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


  # Process Source Scripts Directory ($6)
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


  # Process Assets Scripts Directory ($7)
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


  # Process Export File Target ($8)
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


  # Process AutoExec File ($9)
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

  # Scan for eligible target assets shell scripts
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


  # Scan for eligible target shell scripts
  while IFS= read -r -d '' file; do
    has_files="1"
    array_export_tgt_files+=("${file}")
  done < <(find "${source_dir_path}" -type f -name "*.sh" ! -name "*_test.sh" ! -name "*_autoexec.sh" -print0 | LC_ALL=C sort -z)

  if [ "${has_files}" -eq 0 ]; then
    echo "[ ! ] No .sh target file found in '${source_dir_path}'."
    echo "[END] The package export was interrupted."
    return 0
  fi


  # Insert autoexec in last position
  if [ "${use_autoexec}" != "" ]; then
    array_export_tgt_files+=("${use_autoexec}")
  fi



  # Build the distribution package string
  _shell_package_export_header "${project_url}" "${project_name}" "${project_license_type}" "${project_license_url}"

  local str_file_package=""
  str_file_package+="#!/usr/bin/env bash${codeNL}${codeNL}"
  str_file_package+="${SHELL_PACKAGE_FUNCTION_RETURN}"
  str_file_package+="${codeNL}${codeNL}"

  # Concatenate minified script content
  for file in "${array_export_tgt_files[@]}"; do
    _shell_package_tools_minify_file_content "${file}"
    str_file_package+="${SHELL_PACKAGE_FUNCTION_RETURN}"
    str_file_package+="${codeNL}${codeNL}"
  done

  # Final sanitization and disk write
  str_file_package=$(_shell_package_tools_trim "${str_file_package}")
  echo "${str_file_package}" > "${export_file_path}"
  if [ $? != 0 ]; then
    echo "[ERR] Error on create '${export_file_path}' file."
    return 1
  fi

  # Give execute permissions
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
