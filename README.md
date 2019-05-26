# Htaccess

![htaccess](docs/images/htaccess.jpg)

## Summary

A helper script for htaccess files.

* Allows you to include .htaccess files in other .htaccess files.
* Work with smaller files then combine on build.
* Share common snippets across different .htaccess files.
* Merge in remote content on build (think Drupal web root .htaccess + custom .htaccess directives). 
* Manage banned IPs in a separate file or add them to the YAML configuration.
* Includes other shortcut tools to help with code generation.

**Visit <https://aklump.github.io/htaccess> for full documentation.**

## Quick Start

- Install in your repository root using `cloudy pm-install aklump/htaccess`
- Open _bin/config/htaccess.yml_ and modify as needed.
- Refer to _bin/config/htaccess.example.yml_ as a guide and optionally, delete when done.
- Once configured build your files using `./bin/htaccess build`

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

Optionally you may want to designate a source folder for your _.htaccess_ partial files to be pulled from on build.  For example:

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

## Usage

* To see all commands use `./bin/htaccess`

## Contributing

If you find this project useful... please consider [making a donation](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=4E5KZHDQCEUV8&item_name=Gratitude%20for%20aklump%2Fwebsite-htaccess).

## More Reading

* [THE Ultimate Htaccess](https://www.askapache.com/htaccess)
