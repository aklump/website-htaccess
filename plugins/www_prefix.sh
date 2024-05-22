#!/usr/bin/env bash

# Add or remove the 'www.' prefix from the domain name.
#
# enum: [add, remove, default]
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

  local protossl

  [[ "$output_path" ]] || return 1
  [[ "$www_prefix" != 'add' ]] && [[ "$www_prefix" != 'remove' ]] && return 0;

  list_add_item "Using plugin: www_prefix"

  echo "<IfModule mod_rewrite.c>" >>"$output_path"
  echo "  RewriteEngine on" >>"$output_path"

  if [[ "$force_ssl" ]]; then
    protossl="s"
  else
    protossl="%{ENV:protossl}"
    # This captures the current SSL state in the variable "protossl" because the
    # runtime value has to be used since we're not forcing to SSL.  When forcing
    # to SSL we can hardcode the value as shown above and don't need these
    # lines to be added.
    echo "  RewriteRule ^ - [E=protossl]" >>"$output_path"
    echo "  # This line is required in some environments, e.g. Lando" >> "$output_path"
    echo "  RewriteCond %{ENV:HTTPS} on" >> "$output_path"
    echo "  # This line is more universal but doesn't always work." >> "$output_path"
    echo "  RewriteCond %{HTTPS} on" >> "$output_path"
    echo "  RewriteRule ^ - [E=protossl:s]" >>"$output_path"
  fi

  echo "  RewriteCond %{HTTP_HOST} ." >>"$output_path"

  if [[ "$www_prefix" == "add" ]]; then
    echo "  # Ensure the domain has the leading \"www.\" prefix" >>"$output_path"
    echo "  RewriteCond %{HTTP_HOST} !^www\. [NC]" >>"$output_path"
    echo "  RewriteRule ^ http${protossl}://www.%{HTTP_HOST}%{REQUEST_URI} [L,R=301]" >>"$output_path"

  elif [[ "$www_prefix" == "remove" ]]; then
    echo "  # Remove the leading \"www.\" prefix" >>"$output_path"
    echo "  RewriteCond %{HTTP_HOST} ^www\.(.+)$ [NC]" >>"$output_path"
    echo "  RewriteRule ^ http${protossl}://%1%{REQUEST_URI} [L,R=301]" >>"$output_path"
  fi

  if [[ "$force_ssl" == true ]]; then
    echo "  # This line is required in some environments, e.g. Lando" >> "$output_path"
    echo "  RewriteCond %{ENV:HTTPS} !^.*on" >> "$output_path"
    echo "  # This line is more universal but doesn't always work." >> "$output_path"
    echo "  RewriteCond %{HTTPS} !^.*on" >> "$output_path"
    echo "  RewriteRule ^(.*)$ http${protossl}://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]" >>"$output_path"
  fi

  echo "</IfModule>" >>"$output_path"
}
