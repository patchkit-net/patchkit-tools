# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) 
and this project adheres to [Semantic Versioning](http://semver.org/).

## [3.5.0]
### Added
- Global locks support for content uploads, to prevent parallel uploads

### Changed
- New progress bar rendering

## [3.4.0]
### Added
- Android apps upload support by make-version

### Changed
- Use HTTPS protocol by default
- Improved messages on success and failure

## [3.3.0]
### Added
- `--latest-group-version` flag to `channel-make-version` to explictly create a version based on the latest version in the group.

### Changed
- channel-make-version will now raise an error if neither `--group-version` nor `--latest-group-version` is specified.

## [3.2.1]
### Fixed
- Retry on some 50X errors for get requests

## [3.2.0]
### Added
- make-version `-w` flag to wait for the version to be published before exiting

### Changed
- Update librsync on Windows and Linux to version 2.3.2

## [3.1.5]
### Changed
- S3 Uploader now tries to retry the upload on failure

### Fixed
- Windows: in some cases when the currently signed-in user name had more than 8 characters, the uploaded package was corrupted.

## [3.1.4]
### Added
- Multithreaded diff processing
- `--mode` parameter to `make-version`

### Changed
- Updated traveling ruby to 2.4.10

### Fixed
- `channel-make-version` should link published versions only

## [3.1.3]
### Fixed
- Downloading of signatures bigger than 512 megabytes
- Fallback to old signatures downloading method if needed

### Changed
- If cleaning up signatures fails, now there's a warning instead of an exception

## [3.1.2]
## Added
- New API connection errors handling algorithm

## [3.1.1]
### Fixed
- Signatures downloading exception
- create-version raising exception on -c param (fixes #1279)

## [3.1.0]
### Added
- Version uploading can now retry on failure
- StartTools.lnk for Windows

## [3.0.3]
### Added
- Signatures downloading can resume on network error

## [3.0.2]
### Fixed
- upload_version not working with new backend version
- content_version wrong variable name
- publish_version invalid list-versions usage

## [3.0.1]
### Fixed
- Progress bar rendering

## [3.0.0]
### Added
- channel-link-version command
- channel-make-version command

### Changed
- All `--apikey` parameters renamed to `--api-key`
- diff-version parameter `--diffsummary` renamed to `--out-diff-summary-file`
- list-versions parameter `--displaylimit` renamed to `--display-limit`
- list-versions parameter `--sortmode` renamed to `--sort-mode`
- update-version parameter `--sortmode` renamed to `--sort-mode`
- update-version parameter `--changelogfile` renamed to `--changelog-file`
- make-version parameter `--changelogfile` renamed to `--changelog-file`
- make-version parameters `-x` and `--override-draft` does not require second parameter
- make-version parameter `--publish` does not require second parameter
- upload-version parameter `--diffsummary` renamed to `--diff-summary-file`
- upload-version parameter `--waitforjob` renamed to `--wait-for-job`
- publish-version parameter `--wait-until-published` renamed to `--wait`
- Progress bar: Limited refresh frequency to 2 per second. Makes the stdout stream smaller (good for logging).
- list-version command renamed to list-versions
- list-versions generating yaml or json (depending on -f param)
- Refactoring of model abstraction layer
- patchkit_api http errors are now APIErrors (without stacktrace)

## [2.5.0]
### Added
- make-version --import-app-secret parameter
- make-version --import-version parameter
- make-version --import-copy-label parameter
- make-version --import-copy-changelog parameter

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
