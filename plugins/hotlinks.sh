#!/usr/bin/env bash

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
