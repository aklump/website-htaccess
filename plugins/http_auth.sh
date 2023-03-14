#!/usr/bin/env bash

# Add necessary http auth code.
#
# $1 - The path to the output_path file.
# $2 - The base configuration key, e.g. "files.prod_webroot"
#
# Returns 0 if successful, 1 otherwise.
valid_hosts__array=()
function plugin_http_auth() {
  local output_path="$1"
  local config_base="$2"

  [[ "$output_path" ]] || return 1

  list_add_item "Using plugin: http_auth"
  eval $(get_config_as title "$config_base.http_auth.title" "Restricted Area")
  eval $(get_config_as user_file "$config_base.http_auth.user_file")

  echo "AuthName \"$title\"" >>"$output_path"
  echo "AuthUserFile $user_file" >>"$output_path"
  echo "<IfModule mod_authz_groupfile.c>" >>"$output_path"
  echo "  AuthGroupFile /dev/null" >>"$output_path"
  echo "</IfModule>" >>"$output_path"
  echo "AuthType Basic" >>"$output_path"
  echo "Require valid-user" >>"$output_path"

  # If we whitelist some IPs then add this.
  eval $(get_config_as whitelist -a "$config_base.http_auth.whitelist")
  if [ ${#whitelist[@]} -gt 0 ]; then
    echo "Order deny,allow" >>"$output_path"
    echo "Deny from all" >>"$output_path"
    for i in "${whitelist[@]}"; do
      echo "Allow from $i" >>"$output_path"
    done
    echo "Satisfy any" >>"$output_path"
  fi
}
