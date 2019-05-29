#!/usr/bin/env bash

#
# @file
# Defines the plugin functions for the script.
#

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
    echo "<IfModule mod_rewrite.c>" >> "$output_path"
    echo "  RewriteEngine on" >> "$output_path"
    echo "  RewriteRule ^wp-login.php$ - [R=410,L]" >> "$output_path"
    echo "</IfModule>" >> "$output_path"
  fi
}

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
  for ip in "${ips[@]}"; do
     echo "deny from $ip" >> "$output_path"
  done
}

# Add necessary .htaccess code to ban common WordPress paths.
#
# $1 - The path to the output_path file.
# $2 - The base configuration key, e.g. "files.prod_webroot"
#
# Returns 0 if successful, 1 otherwise.
function plugin_http_auth() {
  local output_path="$1"
  local config_base="$2"

  [[ "$output_path" ]] || return 1

  eval $(get_config_as title "$config_base.http_auth.title" "Restricted Area")
  eval $(get_config_as user_file "$config_base.http_auth.user_file")

  echo "AuthName \"$title\"" >> "$output_path"
  echo "AuthUserFile $user_file" >> "$output_path"
  echo "AuthGroupFile /dev/null" >> "$output_path"
  echo "AuthType Basic" >> "$output_path"
  echo "Require valid-user" >> "$output_path"

  # If we whitelist some IPs then add this.
  eval $(get_config_as array_join__array -a "$config_base.http_auth.whitelist")
  if [ ${#array_join__array[@]} -gt 0 ]; then
    echo "Order deny,allow" >> "$output_path"
    echo "Deny from all" >> "$output_path"
    echo "Allow from $(array_join ",")" >> "$output_path"
    echo "Satisfy any" >> "$output_path"
  fi

  # Forbid linking to assets in the site.
  echo "RewriteEngine on" >> "$output_path"
  echo "RewriteCond %{HTTP_REFERER} !^$" >> "$output_path"
  echo "RewriteCond %{HTTP_REFERER} !^https?://(?:www.)?%{SERVER_NAME}(?:$|/) [NC]" >> "$output_path"
  echo "RewriteRule .(gif|jpg|jpeg|png|mp3|mpg|avi|mov)$ - [F,NC]" >> "$output_path"
}

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
  eval $(get_config_as source -a "$config_base.source")
  for partial in "${source[@]}"; do
    if [[ "$partial" = http* ]]; then
      write_file_header_array=("Downloaded from $partial")
      write_file_header "$output_path"
      list_add_item "Downloading $partial"
      wget -q "$partial" -O - >> "$output_path"
    elif [ -f "$partial" ]; then
      write_file_header_array=("Copied from $partial")
      write_file_header "$output_path"
      list_add_item "Importing $partial"
      cat "$partial" >> "$output_path"
    else
      exit_with_failure "$partial cannot be located as configured.  Is this a file? Does it exist? Is the URL correct?"
    fi
    echo "" >> "$output_path"
  done
}

# Force the site to be served using https.

# $1 - The path to the output_path file.
# $2 - The base configuration key, e.g. "files.prod_webroot"
#
# Returns 0 if successful, 1 otherwise.
function plugin_force_ssl() {
  local output_path="$1"
  local config_base="$2"

  [[ "$output_path" ]] || return 1

  eval $(get_config_as force_ssl "$config_base.force_ssl")
  eval $(get_config_as www_prefix "$config_base.www_prefix")

  if [[ "$force_ssl" != true ]]; then
    return 0
  fi

  echo "<IfModule mod_rewrite.c>" >> "$output_path"
  echo "  RewriteEngine on" >> "$output_path"
  echo "  RewriteRule ^ - [E=protossl]" >> "$output_path"
  echo "  RewriteCond %{HTTPS} on" >> "$output_path"
  echo "  RewriteRule ^ - [E=protossl:s]" >> "$output_path"
  echo "  RewriteCond %{HTTPS} off" >> "$output_path"
  echo "  RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]" >> "$output_path"
  echo "</IfModule>" >> "$output_path"
}

# Add or remove the 'www.' prefix from the domain name.
#
# $1 - The path to the output_path file.
# $2 - The base configuration key, e.g. "files.prod_webroot"
#
# Returns 0 if successful, 1 otherwise.
function plugin_www_prefix() {
  local output_path="$1"
  local config_base="$2"

  [[ "$output_path" ]] || return 1

  eval $(get_config_as force_ssl "$config_base.force_ssl")
  eval $(get_config_as www_prefix "$config_base.www_prefix")

  echo "<IfModule mod_rewrite.c>" >> "$output_path"
  echo "  RewriteEngine on" >> "$output_path"

  if [[ "$force_ssl" != true ]]; then
    echo "  RewriteRule ^ - [E=protossl]" >> "$output_path"
  fi

  if [[ "$www_prefix" == "add" ]]; then
    echo "  # Ensure the domain has the leading \"www.\" prefix" >> "$output_path"
    echo "  RewriteCond %{HTTP_HOST} ." >> "$output_path"
    echo "  RewriteCond %{HTTP_HOST} !^www\. [NC]" >> "$output_path"
    echo "  RewriteRule ^ http%{ENV:protossl}://www.%{HTTP_HOST}%{REQUEST_URI} [L,R=301]" >> "$output_path"

  elif [[ "$www_prefix" == "remove" ]]; then
    echo "  # Remove the leading \"www.\" prefix" >> "$output_path"
    echo "  RewriteCond %{HTTP_HOST} ^www\.(.+)$ [NC]" >> "$output_path"
    echo "  RewriteRule ^ http%{ENV:protossl}://%1%{REQUEST_URI} [L,R=301]" >> "$output_path"
  fi

  echo "</IfModule>" >> "$output_path"
}
