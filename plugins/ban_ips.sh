#!/usr/bin/env bash

# Ban all ips in the config as "ban_ips"
#
# $1 - The path to the output_path file.
# $2 - The base configuration key, e.g. "files.prod_webroot"
#
# Returns 0 if successful, 1 otherwise.
function plugin_ban_ips() {
  local output_path="$1"
  local config_base="$2"

  [[ "$output_path" ]] || return 1

  eval $(get_config_as -a ips "$config_base.ban_ips")
  [ ${#ips[@]} -gt 0 ] && list_add_item "Using plugin: ban_ips"
  for ip in "${ips[@]}"; do
    echo "deny from $ip" >>"$output_path"
  done
}
