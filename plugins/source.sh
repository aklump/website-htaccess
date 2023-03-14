#!/usr/bin/env bash

# Merge in partials from files or URLs.
#
# $1 - The path to the output_path file.
# $2 - The base configuration key, e.g. "files.prod_webroot"
#
# Returns 0 if successful, 1 otherwise.
function plugin_source() {
  local output_path="$1"
  local config_base="$2"

  [[ "$output_path" ]] || return 1
  list_add_item "Using plugin: source"
  eval $(get_config_as source -a "$config_base.source")
  for partial in "${source[@]}"; do
    if [[ "$partial" == http* ]]; then
      write_file_header_array=("Downloaded from $partial")
      write_file_header "$output_path"
      list_add_item "Downloading $partial"
      wget -q "$partial" -O - >>"$output_path"
    elif [ -f "$partial" ]; then
      write_file_header_array=("Copied from $partial")
      write_file_header "$output_path"
      list_add_item "Importing $partial"
      cat "$partial" >>"$output_path"
    else
      exit_with_failure "$partial cannot be located as configured.  Is this a file? Does it exist? Is the URL correct?"
    fi
    echo "" >>"$output_path"
  done
}
