#!/usr/bin/env bash

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

  [[ "$force_ssl" == false ]] && return 0;

  # Note: SSL is handled by the www_prefix plugin.
  [[ "$www_prefix" == 'add' ]] || [[ "$www_prefix" == 'remove' ]] && return 0;

  list_add_item "Using plugin: force_ssl"

  echo "<IfModule mod_rewrite.c>" >> "$output_path"
  echo "  RewriteEngine on" >> "$output_path"
  echo "  # This line is required in some environments, e.g. Lando" >> "$output_path"
  echo "  RewriteCond %{ENV:HTTPS} !^.*on" >> "$output_path"
  echo "  # This line is more universal but doesn't always work." >> "$output_path"
  echo "  RewriteCond %{HTTPS} !^.*on" >> "$output_path"
  echo "  RewriteRule .* https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]" >> "$output_path"
  echo "</IfModule>" >> "$output_path"
}
