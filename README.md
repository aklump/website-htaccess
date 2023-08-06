# Htaccess

![htaccess](images/htaccess.jpg)

## Summary

A helper script for _.htaccess_ management.

* Allows you to include _.htaccess_ files in other _.htaccess_ files.
* Work with smaller files then combine using `./bin/htaccess build`
* Share common snippets across different _.htaccess_ files.
* Simplified URL redirection; remap old URLs to new without nasty syntax.
* Merge in remote _.htaccess_ source files on build (think Drupal web root _.htaccess_ + custom _.htaccess _directives).
* Manage banned IPs in a separate file or add them to the YAML configuration.
* Includes other shortcut tools to help with .htaccess management of your websites.

## Quick Start

- Install in your repository root using `cloudy pm-install aklump/htaccess`
- Open _bin/config/htaccess.yml_ and modify as needed.
- Refer to _bin/config/htaccess.example.yml_ as a guide and optionally, delete when done.
- Once configured, clear the cache `./bin/htaccess clear-cache`
- Lastly, build your files using `./bin/htaccess build`

## Requirements

You must have [Cloudy](https://github.com/aklump/cloudy) installed on your system to install this package.

## Installation

The installation script above will generate the following structure where `.` is your repository root.

    .
    ├── bin
    │   ├── htaccess -> ../opt/htaccess/htaccess.sh
    │   └── config
    │       └── htaccess.yml
    ├── opt
    │   ├── cloudy
    │   └── aklump
    │       └── htaccess
    └── {public web root}

Optionally you may want to designate a source folder for your _.htaccess_ partial files to be pulled from on build. For example:

    .
    ├── bin
    │   └── config
    │       └── htaccess.yml (configuration)
    ├── install
    │   └── apache
    │       ├── .htaccess.core (1 of 2 source files)
    │       └── .htaccess.custom (2 of 2 source files)
    └── web
        └── .htaccess (the compiled file)

### To Update

- Update to the latest version from your repo root: `cloudy pm-update aklump/htaccess`

## Configuration Files

| Filename | Description | VCS |
|----------|----------|---|
| _htaccess.yml_ | Configuration file | yes |

### Custom Configuration

* Open _bin/config/htaccess.example.yml_ and read it's inline documentation.
* That file is also located in _opt/aklump/htaccess/init/htaccess.example.yml_.

### Regarding `valid_hosts`, `force_ssl`, and `www_prefix` configuration

The first setting is required. You must list one or more hosts in `valid_hosts`, including their http or https protocol.

You may explicitly declare `force_ssl` or `www_prefix`, or you may let the `valid_hosts` be used to autodetect these settings.

The auto-detection will set `force_ssl` to `true` if all `valid_hosts` use the _https_ protocol.  `www_prefix` will be set to `add` if all `valid_hosts` have `www.` in their values, `remove` if all `valid_hosts` do not have `www.` in their values, and `null` if there is mixture.

## Usage

* To see all commands use `./bin/htaccess`

## Contributing

If you find this project useful... please consider [making a donation](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=4E5KZHDQCEUV8&item_name=Gratitude%20for%20aklump%2Fwebsite-htaccess).

## More Reading

* [THE Ultimate Htaccess](https://www.askapache.com/htaccess)
* [Mod_Rewrite Variables Cheatsheet](https://www.askapache.com/htaccess/mod_rewrite-variables-cheatsheet/)
* [Htaccess](https://www.askapache.com/category/htaccess/)

## Troubleshooting

### 4xx redirects are not working

I'm not sure why, but on some servers they do not work. Possible reasons:

1. Apache version?
2. VirtualHost config hijacking?
3. Drupal conflict?
