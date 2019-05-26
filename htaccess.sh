#!/usr/bin/env bash

#
# @file
# Script to generate .htaccess files.
#

# Define the configuration file relative to this script.
CONFIG="htaccess.core.yml";

# Uncomment this line to enable file logging.
#LOGFILE="htaccess.core.log"

# TODO: Event handlers and other functions go here or source another file.
function on_pre_config() {
  [[ "$(get_command)" == "init" ]] && exit_with_init
}

# Adds a header to the generated file using $write_file_header_array.
#
# @code
#   write_file_header_array=("line1" "line2")
#   write_file_header "$output_path"
# @endcode
#
# $1 - string Path to the output file.
#
# Returns nothing.
write_file_header_array=()
function write_file_header() {
  local output_path="$1"
  local header="$2"

  [[ "$output_path" ]] || return 1
  echo "" >> "$output_path"
  echo "#" >> "$output_path"
  echo "#" >> "$output_path"
  for line in "${write_file_header_array[@]}"; do
    echo "# $line" >> "$output_path"
  done
  echo "#" >> "$output_path"
}

# Begin Cloudy Bootstrap
s="${BASH_SOURCE[0]}";while [ -h "$s" ];do dir="$(cd -P "$(dirname "$s")" && pwd)";s="$(readlink "$s")";[[ $s != /* ]] && s="$dir/$s";done;r="$(cd -P "$(dirname "$s")" && pwd)";source "$r/../../cloudy/cloudy/cloudy.sh";[[ "$ROOT" != "$r" ]] && echo "$(tput setaf 7)$(tput setab 1)Bootstrap failure, cannot load cloudy.sh$(tput sgr0)" && exit 1
# End Cloudy Bootstrap

# Input validation.
validate_input || exit_with_failure "Input validation failed."

implement_cloudy_basic

# Handle other commands.
command=$(get_command)
case $command in

    "build")
      echo_title "Building .htaccess Files"
      eval $(get_config_as "output_header" "header")
      eval $(get_config_keys "files")
      for id in ${files[@]} ; do
          list_clear
          eval $(get_config_as title "files.$id.title" ".htaccess file")
          echo_heading "$title"
          eval $(get_config_path_as output_path "files.$id.output")

          # Truncate the output file.
          echo -n "" > "$output_path" || fail_because "Cannot create output file at $output_path"
          write_file_header_array=("$title" "" "$(string_upper "$output_header")" "(built on: $(date8601))" "@see $(realpath $SCRIPT)" )
          write_file_header "$output_path"
          echo "" >> "$output_path"

          # The order these are defined will determine their execution order.
          registered_plugin_names=("ban_ips" "http_auth" "ban_wordpress" "source")

          eval $(get_config_keys_as array_has_value__array "files.$id")
          for plugin_name in "${registered_plugin_names[@]}"; do
            if array_has_value "$plugin_name"; then
              list_add_item "Using plugin: $plugin_name"
              callback="plugin_${plugin_name}"
              write_file_header_array=("Begin plugin \"$plugin_name\" output.")
              write_file_header "$output_path"
              eval $callback "$output_path" "files.$id.$plugin_name" || fail_because "$plugin_name failed."
              echo "#" >> "$output_path"
              echo "# End output from \"$plugin_name\"" >> "$output_path"
            fi
          done

          echo_green_list
          succeed_because "Created $output_path"
      done
      has_failed && exit_with_failure
      exit_with_success
    ;;

esac

throw "Unhandled command \"$command\"."
