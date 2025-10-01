# Change log for PSResourceGet.Bootstrap

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Bump Stale action to v10.
- Bump Checkout action to v5.

## [0.2.0] - 2024-02-18

### Added

- DSC class-based resource `BootstrapPSResourceGet'.

### Fixed

- Reverted resolve dependency logic so that GitHub actions works.
- Link to `Start-PSResourceGetBootstrap` in Home.md now works ([issue #13](https://github.com/viscalyx/PSResourceGet.Bootstrap/issues/13)).
- Wiki now has correct header for the resources.

## [0.1.2] - 2024-02-03

### Fixed

- Fix bootstrap script parameter block.

## [0.1.1] - 2024-02-02

### Fixed

- Status badges updated.
- Update integration tests for the bootstrap script.
- Fix missing commands in bootstrap script.

### Changed

- Update azure-pipelines.yml.

## [0.1.0] - 2024-02-01

### Added

- Added command `Start-PSResourceGetBootstrap`.
- Added bootstrap script as a release asset.
