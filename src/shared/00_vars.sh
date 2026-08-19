#!/usr/bin/env bash

# Global newline character helper used for string operations and formatting.
if [ -z "${codeNL+x}" ]; then
  declare -gr codeNL=$'\n'
fi

# Stores the sanitized and fully processed argument value after validation.
declare -g SHELL_PACKAGE_CLEAN_ARG=""

# Value obtained from the processing of a function.
declare -g SHELL_PACKAGE_FUNCTION_RETURN=""
