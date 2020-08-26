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
    list_add_item "Using plugin: ban_wordpress"
    echo "<IfModule mod_rewrite.c>" >>"$output_path"
    echo "  RewriteEngine on" >>"$output_path"
    echo "  RewriteRule ^wp-login.php$ - [R=410,L]" >>"$output_path"
    echo "</IfModule>" >>"$output_path"
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
  [ ${#ips[@]} -gt 0 ] && list_add_item "Using plugin: ban_ips"
  for ip in "${ips[@]}"; do
    echo "deny from $ip" >>"$output_path"
  done
}

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
  echo "AuthGroupFile /dev/null" >>"$output_path"
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

# Add hotlink denial code.
#
# $1 - The path to the output_path file.
# $2 - The base configuration key, e.g. "files.prod_webroot"
#
# Returns 0 if successful, 1 otherwise.
valid_hosts__array=()
function plugin_hotlinks() {
  local output_path="$1"
  local config_base="$2"

  [[ "$output_path" ]] || return 1

  list_add_item "Using plugin: hotlinks"

  # Forbid linking to assets in the site, a.k.a. "hotlinking".
  eval $(get_config_as deny_extensions -a "$config_base.hotlinks.deny")
  deny_extensions=${deny_extensions[@]}
  if [[ "$deny_extensions" ]] && [[ "$deny_extensions" != null ]]; then
    echo "RewriteEngine on" >>"$output_path"
    echo "RewriteCond %{HTTP_REFERER} !^$" >>"$output_path"
    for host in "${valid_hosts__array[@]}"; do
      domain=$host
      domain=${domain//https:\/\//}
      domain=${domain//http:\/\//}
      domain=${domain%/}
      echo "RewriteCond %{HTTP_HOST} !^$domain\$ [NC]" >>"$output_path"
      echo "RewriteCond %{HTTP_REFERER} !^$host(?:$|/) [NC]" >>"$output_path"
    done

    deny_extensions=${deny_extensions// /|}
    echo "RewriteRule .(${deny_extensions})\$ - [F,NC]" >>"$output_path"
  fi
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

# Force the site to be served using https.

# $1 - The path to the output_path file.
# $2 - The base configuration key, e.g. "files.prod_webroot"
#
# Returns 0 if successful, 1 otherwise.
force_ssl=false
function plugin_force_ssl() {
  local output_path="$1"
  local config_base="$2"

  [[ "$output_path" ]] || return 1
  if [[ "$force_ssl" != true ]]; then
    return 0
  fi
  list_add_item "Using plugin: force_ssl"

  echo "<IfModule mod_rewrite.c>" >>"$output_path"
  echo "  RewriteEngine on" >>"$output_path"
  echo "  RewriteRule ^ - [E=protossl]" >>"$output_path"
  echo "  RewriteCond %{HTTPS} on" >>"$output_path"
  echo "  RewriteRule ^ - [E=protossl:s]" >>"$output_path"
  echo "  RewriteCond %{HTTPS} off" >>"$output_path"
  echo "  RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]" >>"$output_path"
  echo "</IfModule>" >>"$output_path"
}

# Add or remove the 'www.' prefix from the domain name.
#
# $1 - The path to the output_path file.
# $2 - The base configuration key, e.g. "files.prod_webroot"
#
# Returns 0 if successful, 1 otherwise.
www_prefix=null
force_ssl=false
function plugin_www_prefix() {
  local output_path="$1"
  local config_base="$2"

  [[ "$output_path" ]] || return 1
  list_add_item "Using plugin: www_prefix"

  echo "<IfModule mod_rewrite.c>" >>"$output_path"
  echo "  RewriteEngine on" >>"$output_path"

  if [[ "$force_ssl" != true ]]; then
    echo "  RewriteRule ^ - [E=protossl]" >>"$output_path"
  fi

  if [[ "$www_prefix" == "add" ]]; then
    echo "  # Ensure the domain has the leading \"www.\" prefix" >>"$output_path"
    echo "  RewriteCond %{HTTP_HOST} ." >>"$output_path"
    echo "  RewriteCond %{HTTP_HOST} !^www\. [NC]" >>"$output_path"
    echo "  RewriteRule ^ http%{ENV:protossl}://www.%{HTTP_HOST}%{REQUEST_URI} [L,R=301]" >>"$output_path"

  elif [[ "$www_prefix" == "remove" ]]; then
    echo "  # Remove the leading \"www.\" prefix" >>"$output_path"
    echo "  RewriteCond %{HTTP_HOST} ^www\.(.+)$ [NC]" >>"$output_path"
    echo "  RewriteRule ^ http%{ENV:protossl}://%1%{REQUEST_URI} [L,R=301]" >>"$output_path"
  fi

  echo "</IfModule>" >>"$output_path"
}

function plugin_redirects() {
  local output_path="$1"
  local config_base="$2"

  [[ "$output_path" ]] || return 1

  # This file may elect to ignore shared redirects
  eval $(get_config_as redirects "$config_base.redirects.inherit" true)
  [[ "$redirects" == false ]] && return 0

  list_add_item "Using plugin: redirects"

  # Handle shared redirects
  eval $(get_config_keys_as redirect_codes -a "redirects")
  for code in "${redirect_codes[@]}"; do
    eval $(get_config_as redirects -a "redirects.$code")
    for string_split__string in "${redirects[@]}"; do
      string_split ' '
      from=${string_split__array[0]}
      if [[ "${from:0:1}" != '/' ]]; then
        fail_because "All redirect from-paths must begin with forward slash; \"$from\" does not." && return 1
      fi
      if [[ "${from: -1}" == '/' ]]; then
        fail_because "Redirect from-paths must not end with a forward slash; remove the slash from \"$from\"." && return 1
      fi
      if [[ $code -gt 299 ]] && [[ $code -lt 400 ]] && [[ ! "${string_split__array[1]}" ]]; then
        fail_because "The redirect parameter cannot be empty for: $from" && return 1
      fi
      from="^${string_split__array[0]}/?\$"
      echo RedirectMatch $code $from ${string_split__array[1]} >>"$output_path"
    done
  done

  # Handle individual file redirects.
  eval $(get_config_keys_as redirect_codes -a "$config_base.redirects")
  for code in "${redirect_codes[@]}"; do
    eval $(get_config_as redirects -a "$config_base.redirects.$code")
    for string_split__string in "${redirects[@]}"; do
      string_split ' '
      from=${string_split__array[0]}
      if [[ "${from:0:1}" != '/' ]]; then
        fail_because "All redirect from-paths must begin with forward slash; \"$from\" does not." && return 1
      fi
      if [[ "${from: -1}" == '/' ]]; then
        fail_because "Redirect from-paths must not end with a forward slash; remove the slash from \"$from\"." && return 1
      fi
      from="^${string_split__array[0]%/}/?\$"
      if [[ $code -gt 299 ]] && [[ $code -lt 400 ]] && [[ ! "${string_split__array[1]}" ]]; then
        fail_because "The redirect parameter cannot be empty for: $from" && return 1
      fi
      echo RedirectMatch $code $from ${string_split__array[1]} >>"$output_path"
    done
  done
}
