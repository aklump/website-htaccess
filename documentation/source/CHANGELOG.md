# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.20] - 2020-06-15

### Added
- `hotlinks` and `hotlinks.deny` configuration keys.
  
### Changed
- Moved hotlinking up one level so it's no longer part of the "httpauth" plugin.  See _init/htaccess.example.yml_ for how to add this configuration.
  
## [0.0.19] - 2020-06-15
### Added
- Check against HTTP_HOST for hotlinking.
  
### Changed
- Hotlinking is not longer automatic for `http_auth`.  You must configure it now.  See _init/htaccess.example.yml_ for how to add this configuration.
