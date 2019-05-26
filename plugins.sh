#!/usr/bin/env bash

#
# @file
# Defines the plugin functions for the script.
#

# Add necessary .htaccess code to ban common WordPress paths.
#
# $1 - The path to the output_path file.
# $2 - The key to use to access configuration.
#
# Returns 0 if successful, 1 otherwise.
function plugin_ban_wordpress() {
  local output_path="$1"
  local config_key="$2"

  [[ "$output_path" ]] || return 1

  eval $(get_config_as ban "$config_key")
  debug "$ban;\$ban"
  if [[ "$ban" == true ]]; then
    echo "<IfModule mod_rewrite.c>" >> "$output_path"
    echo "  RewriteEngine on" >> "$output_path"
    echo "  RewriteRule ^wp-login.php$ - [R=404]" >> "$output_path"
    echo "</IfModule>" >> "$output_path"
  fi
}

# Ban all ips in the config as "ban_ips"
#
# $1 - The path to the output_path file.
# $2 - The key to use to access configuration.
#
# Returns 0 if successful, 1 otherwise.
function plugin_ban_ips() {
  local output_path="$1"
  local config_key="$2"

  [[ "$output_path" ]] || return 1

  eval $(get_config_as -a ips "$config_key")
  for ip in "${ips[@]}"; do
     echo "deny from $ip" >> "$output_path"
  done
}

# Add necessary .htaccess code to ban common WordPress paths.
#
# $1 - The path to the output_path file.
# $2 - The key to use to access configuration.
#
# Returns 0 if successful, 1 otherwise.
function plugin_http_auth() {
  local output_path="$1"
  local config_key="$2"

  [[ "$output_path" ]] || return 1

  eval $(get_config_as title "$config_key.title" "Restricted Area")
  eval $(get_config_as user_file "$config_key.user_file")

  echo "AuthName \"$title\"" >> "$output_path"
  echo "AuthUserFile $user_file" >> "$output_path"
  echo "AuthGroupFile /dev/null" >> "$output_path"
  echo "AuthType Basic" >> "$output_path"
  echo "Require valid-user" >> "$output_path"
  echo "Order deny,allow" >> "$output_path"

  eval $(get_config_as array_join__array -a "$config_key.whitelist")
  if [ ${#array_join__array[@]} -gt 0 ]; then
    echo "Allow from $(array_join ",")" >> "$output_path"
  fi

  echo "Satisfy Any" >> "$output_path"
}

function plugin_source() {
  local output_path="$1"
  local config_key="$2"

  [[ "$output_path" ]] || return 1

  eval $(get_config_as source -a "$config_key")
  for partial in "${source[@]}"; do
    if [[ "$partial" = http* ]]; then
      write_file_header_array=("Downloaded from $partial")
      write_file_header "$output_path"
      list_add_item "Downloading $partial"
#      curl -q "$partial" >> "$output_path"
      wget -q "$partial" -O - >> "$output_path"
    elif [ -f "$partial" ]; then
      write_file_header_array=("Copied from $partial")
      write_file_header "$output_path"
      list_add_item "Importing $partial"
      cat "$partial" >> "$output_path"
    fi
    echo "" >> "$output_path"
  done
}
