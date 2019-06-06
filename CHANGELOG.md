# Changelog
All notable changes to this project will be documented in this file.

## [v0.3.0]

### Changed

- Bump `kubecfg` to `v0.12.0`
- Removed minikube (using KinD)

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
