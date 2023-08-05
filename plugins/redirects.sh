#!/usr/bin/env bash

function plugin_redirects() {
  local output_path="$1"
  local config_base="$2"

  [[ "$output_path" ]] || return 1

  # Load the shared/not-shared redirects to see if we need to do anything.
  eval $(get_config_as include_shared "$config_base.redirects.inherit" true)
  if [[ "$include_shared" == true ]]; then
    eval $(get_config_keys_as shared_redirect_codes -a "redirects")
  fi
  eval $(get_config_keys_as redirect_codes -a "$config_base.redirects")
  if [[ ${#shared_redirect_codes[@]} -eq 0 ]] && [[ ${#redirect_codes[@]} -eq 0 ]]; then
    return
  fi

  list_add_item "Using plugin: redirects"

  # This file may elect to ignore shared redirects
  if [[ "$include_shared" == true ]]; then
    # Handle shared redirects
    for code in "${shared_redirect_codes[@]}"; do
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

        from=$(_handle_special_chars "^${string_split__array[0]}/?\$")
        if [[ "${string_split__array[1]}" ]]; then
          to=$(_handle_special_chars "${string_split__array[1]}")
          echo RedirectMatch $code $from $to >>"$output_path"
        else
          echo RedirectMatch $code $from >>"$output_path"
        fi
      done
    done
  fi

  # Handle individual file redirects.
  for code in "${redirect_codes[@]}"; do
    [[ "$code" == "inherit" ]] && continue
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

# Wrap URL with quotes, replace url-encoded, etc.
#
# $1 - The RedirectMatch path (from or to)
#
# Urls with spaces must be double-quoted.
# @link https://stackoverflow.com/a/14164198/3177610
# @link https://stackoverflow.com/a/1474094/3177610
function _handle_special_chars() {
  local path="$1"

  must_quote_pattern=" |%20"
  if [[ "$path" ]] && [[ $path =~ $must_quote_pattern ]]; then
    path="\"${path//%20/ }\""
  fi
  echo "$path"
}
