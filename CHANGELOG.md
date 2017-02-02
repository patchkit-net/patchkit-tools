# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) 
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Added
- Patchkit tools online documentation url in main help message
- Add command help command line to main help message
- Add more information and possible solution when selecting wrong application directory

### Changed
- Config file is now optional
- New main help format

### Fixed
- Diff summary missing slashes on empty dirs
- Fixed problems with uploading 
- Improved uploading stability (in case of network failure the data is resent)
- Improved displaying job status stability (in case of network failure the status is refetched)
- Setting changelog when creating new version with make-version tool
