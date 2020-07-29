# Changelog
All notable changes to this project will be documented in this file.

## v0.14.0 (2020-07-24)
### Added
- Added GitHub actions for linting Dockerfile and bash scripts
- Added `fluxctl`
- Added `stern`

### Changed
- Bump `jsonnet` to `v0.15.0`
- Bump `kubectl_v1.15` to `v1.15.12`
- Bump `terraform` to `v0.12.29` in preparation for 0.13 release
- Bump `terragrunt` to `0.23.31`
- Change default `kubectl` to `v1.15.12`
- Cleanup Dockerfile and bash scripts with linter recommendations
- Reduce docker image size and number of layers

## v0.13.1 (2020-07-16)
### Changed
- Bump `opa` to `0.21.1`
- Bump `conftest` to `0.19.0`

## v0.13.0 (2020-03-12)
### Changed
- Bump `kustomize` to `v3.5.3`

## v0.12.0 (2020-03-10)
### Changed
- Bump `terraform` to `v0.12.23`
- Bump `terragrunt` to `v0.23.2`

## [v0.11.0]

### Changed
- Update kubectl default and alt versions

## [v0.10.1]

### Added
- Added `KIND_OPTS` env-var (passed into `kind create cluster`)

## [v0.10.0]

### Added
- Download multiple kubectl versions for automated testing (alongside default for manual use)

### Changed
- Make Kind CNI replacement optional
- Change Kind CNI replacement from Flannel to Weave Net
- Bump `kind` to `v0.7.0`
- Bump `kubecfg` to `v0.14.0`

## [v0.9.2]

### Changed
- Added SSSS

## [v0.9.1]

### Changed
- Added pwgen

## [v0.9.0]

### Changed

- Bump `kustomize` to `v3.2.1`

## [v0.8.0]

### Changed

- Bump `kind` to `v0.5.1`
- Bump `kubectl` to `v1.13.11`
- Bump default kubernetes to `v1.13.10`
- Bump `kubecfg` to `v0.13.0`
- Bump `conftest` to `v0.11.0`

## [v0.2.0]

### Changed

- Rename repo to `satoshi-gitops-ci`
- Bump `kind` to `v0.3.0`
- Use `flannel` to get around issues with default CNI in kind when running `dind` (i.e via CI)
- Remove` atlantis` (not used)
- Pin `k8s-yaml-splitter`

## [v0.1.0]

### Added

- initial release
