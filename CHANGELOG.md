# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) 
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Added
- make-version --import-app-secret parameter
- make-version --import-version parameter
- make-version --import-copy-label parameter
- make-version --import-copy-changelog parameter

### Changed
- Refactoring of model abstraction layer

## [2.4.0]
### Added
- Upload speed calculator next to the progress bar

### Changed
- Upload-version tool is now using S3 upload method
- Improved rsync library search method

### Fixed
- Use `*.zi_` instead of `*.zip` extensions to fool AV software

## [2.3.0]
### Added
- Ability to use draft version in publish_version (--draft parameter)
- Ability to wait until version is published (--wait-until-published)

### Fixed
- Dot files (.\*) were not included in diff summary causing processing to fail
- Fix for displaying progress bar on narrow console windows

## [2.2.0]
### Added
- Ability to automatically overwrite draft version in make-version tool

## [2.1.0]
### Fixed
- Dot files (.\*) were not included in diff summary causing processing to 

### Changed
- Use Dir.mktmpdir for tools temporary files

## [2.0.0]
### Fixed
- Fix OS architecture detection

### Changed
- Change the way of deploying tools to packaging (with usage of *Traveling Ruby*)
- Get rid of rest-client dependency

## [1.3.0]
### Added
- Version checking at the beginning of each patchkit-tools calls
- Unit tests

## [1.2.0]
### Added
- Creating diff operation now displays progress information

### Fixed
- Processing progress is now refreshed at constant 1 second interval
- Downloading progress printing is now more stable
- If signature download fails, it tries again after 30 seconds

## [1.1.0]
### Added
- Chunks upload validation

### Fixed
- Chunk re-upload on error

## [1.0.2]
### Fixed
- Windows: dlls no longer dependent of VC Redistributable.

## [1.0.1]
### Added
- Add command help command line to main help message
- Support for internal tools by PK_TOOLS_INTERNAL environment variable.
- Add more information and possible solution when selecting wrong application directory
- Allow to override backend --host using parameter
- Display processing errors at the end

### Fixed
- Fixed problems with uploading 
- Improved uploading stability (in case of network failure the data is resent)
- Improved displaying job status stability (in case of network failure the status is refetched)
- Setting changelog when creating new version with make-version tool
- make-version will stop execution if empty directory has been passed
- Fixed problem with freezing tools at start on Windows
- Fixed problem with starting tools when PK_TOOLS_INTERNAL environment variable wasn't set
- Fixed problems with freezing tools after issues with version processing
- Fix make-version path slashes for make-version

### Changed
- Version publishing flag is set before processing

## [0.9.2]
### Added
- Patchkit tools online documentation url in main help message

### Changed
- Config file is now optional
- New main help format

### Fixed
- Diff summary missing slashes on empty dirs
