# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Todo

- When used with Drupal 9, the 4XX redirects do not seem to work in apache 2.4. I'm not sure why, whether it's apache 2.4 or Drupal. Could it be something in the virual host that is superceding .htaccess?

## [0.0.30] - 2024-05-09

### Added

- `default` option for www_prefix to do nothing.

### Fixed

- Fixed force_ssl to work in Lando containers per https://github.com/lando/lando/issues/2202#issuecomment-786645585

## [0.0.26] - 2023-03-14

### Changed

- Combined the output of www_prefix and force_ssl plugins to a single block.

## [0.0.20] - 2020-06-15

### Added

- `hotlinks` and `hotlinks.deny` configuration keys.

### Changed

- Moved hotlinking up one level so it's no longer part of the "httpauth" plugin. See _init/htaccess.example.yml_ for how to add this configuration.

## [0.0.19] - 2020-06-15

### Added

- Check against HTTP_HOST for hotlinking.

### Changed

- Hotlinking is not longer automatic for `http_auth`. You must configure it now. See _init/htaccess.example.yml_ for how to add this configuration.
