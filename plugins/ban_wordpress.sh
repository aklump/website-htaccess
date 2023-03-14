#!/usr/bin/env bash

# Add necessary .htaccess code to ban common WordPress paths.
#
# $1 - The path to the output_path file.
# $2 - The base configuration key, e.g. "files.prod_webroot"
#
# Returns 0 if successful, 1 otherwise.
function plugin_ban_wordpress() {
  local output_path="$1"
  local config_base="$2"

  [[ "$output_path" ]] || return 1

  eval $(get_config_as ban "$config_base.ban_wordpress")
  if [[ "$ban" == true ]]; then
    list_add_item "Using plugin: ban_wordpress"
    echo "<IfModule mod_rewrite.c>" >>"$output_path"
    echo "  RewriteEngine on" >>"$output_path"
    echo "  RewriteRule ^wp-login.php$ - [R=410,L]" >>"$output_path"
    echo "</IfModule>" >>"$output_path"
  fi
}
