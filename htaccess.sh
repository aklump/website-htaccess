#!/usr/bin/env bash

#
# @file
# Script to generate .htaccess files.
#

# Define the configuration file relative to this script.
CONFIG="htaccess.core.yml"

COMPOSER_VENDOR=""

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
  echo "" >>"$output_path"
  echo "#" >>"$output_path"
  echo "#" >>"$output_path"
  for line in "${write_file_header_array[@]}"; do
    echo "# $line" >>"$output_path"
  done
  echo "#" >>"$output_path"
}

# Echo auto-detected force_ssl setting based on $valid_hosts__array.
#
# Will echo either 'true' or 'false'.
#
# Returns nothing.
valid_hosts__array=()
function detect_force_ssl() {
  local has_http
  local has_https
  for host in "${valid_hosts__array[@]}"; do
    [[ "$host" == http:* ]] && has_http=true
    [[ "$host" == https:* ]] && has_https=true
  done
  [[ $has_http == true ]] && [[ $has_https == true ]] && echo false
  [[ $has_https ]] && echo true
  echo false
}

# Echo auto-detected www_prefix setting based on $valid_hosts__array.
#
# Will echo either 'add', 'remove', or null.
#
# Returns nothing.
valid_hosts__array=()
function detect_www_prefix() {
  local has_www=0
  for host in "${valid_hosts__array[@]}"; do
    [[ "$host" == *www.* ]] && ((++has_www))
  done
  [ $has_www -eq ${#valid_hosts__array[@]} ] && echo 'add'
  [ $has_www -eq 0 ] && echo 'remove'
  echo null
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
  eval $(get_config_keys_as "shared_redirects" "redirects")

  for id in ${files[@]}; do
    list_clear
    eval $(get_config_as title "files.$id.title" ".htaccess file")
    echo_heading "$title"

    eval $(get_config_path_as output_paths -a "files.$id.output")
    for output_path in "${output_paths[@]}"; do

      # Truncate the output file.
      echo -n "" >"$output_path" || fail_because "Cannot create output file at $output_path"

      eval $(get_config_keys_as array_has_value__array "files.$id")

      # Determine the settings based on the url: force_ssl and www_prefix
      eval $(get_config_as -a valid_hosts__array "files.$id.valid_hosts")
      [ ${#valid_hosts__array[@]} -eq 0 ] && fail_because "files.$id.valid_hosts is missing."

      ! has_failed && for ((host_id = 0; host_id < ${#valid_hosts__array[@]}; ++host_id)); do
        host=${valid_hosts__array[host_id]}
        [[ "$host" == http* ]] || fail_because "files.$id.valid_hosts.$host_id must begin with \"http\" or \"https\"."
      done

      eval $(get_config_as force_ssl "files.$id.force_ssl" $(detect_force_ssl))
      if [[ $force_ssl == true ]]; then
        array_has_value__array=("${array_has_value__array[@]}" "force_ssl")
      fi

      eval $(get_config_as www_prefix "files.$id.www_prefix" $(detect_www_prefix))
      if [[ $www_prefix == "add" ]] || [[ $www_prefix == "remove" ]]; then
        array_has_value__array=("${array_has_value__array[@]}" "www_prefix")
      fi

      has_failed && exit_with_failure

      # The order these are defined will determine their execution order.
      registered_plugin_names=("redirects" "ban_ips" "http_auth" "hotlinks" "force_ssl" "www_prefix" "ban_wordpress" "source")

      for plugin_name in "${registered_plugin_names[@]}"; do

        # Note: the redirects plugin can take config from top-level or from file-level, it's different from the rest.
        if array_has_value "$plugin_name" || [[ "$plugin_name" == "redirects" && "${#shared_redirects[@]}" -gt 0 ]]; then
          callback="plugin_${plugin_name}"
          write_file_header_array=("Begin plugin \"$plugin_name\" output.")
          write_file_header "$output_path"
          eval $callback "$output_path" "files.$id" || exit_with_failure "Plugin \"$plugin_name\" has failed."
          echo "#" >>"$output_path"
          echo "# End output from \"$plugin_name\"" >>"$output_path"
        fi
      done

      # Remove comments if asked to.
      eval $(get_config_as "remove_comments" "files.$id.remove_comments")
      if [[ "$remove_comments" == true ]]; then
        sed -i "" -e '/^[ \t]*#/d' "$output_path" || fail_because "Couldn't remove comments"
        list_add_item "All comments removed."
      fi

      # Add the file header, which should not be stripped
      mv "$output_path" "$output_path.tmp"
      write_file_header_array=("$title" "" "$(string_upper "$output_header")" "(built on: $(date8601))" "@see $(realpath $SCRIPT)")
      write_file_header "$output_path"
      cat "$output_path.tmp" >>"$output_path"
      echo "" >>"$output_path"
      rm "$output_path.tmp"

      echo_green_list
      succeed_because "Created $output_path"
    done
  done
  has_failed && exit_with_failure
  exit_with_success
  ;;

esac

throw "Unhandled command \"$command\"."
