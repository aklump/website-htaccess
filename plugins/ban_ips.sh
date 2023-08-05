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

  # Load the shared/not-shared redirects to see if we need to do anything.
  eval $(get_config_as include_shared "$config_base.ban_ips_inherit" true)
  if [[ "$include_shared" == true ]]; then
    eval $(get_config_as shared_ips -a "ban_ips")
  fi
  eval $(get_config_as ips -a "$config_base.ban_ips")
  if [[ ${#shared_ips[@]} -eq 0 ]] && [[ ${#ips[@]} -eq 0 ]]; then
    return
  fi

  list_add_item "Using plugin: ban_ips"
  for ip in "${shared_ips[@]}"; do
    echo "deny from $ip" >>"$output_path"
  done
  for ip in "${ips[@]}"; do
    echo "deny from $ip" >>"$output_path"
  done
}
