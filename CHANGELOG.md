# phac-nml/gasclustering: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2024-08-20

### Changed

- Upgraded `locidex/merge` to version `0.2.2` and updated `input_assure` and test data for compatibility with the new `mlst.json` allele file format.
  - [PR28](https://github.com/phac-nml/gasclustering/pull/28)
- Aligned container registry handling in configuration files and modules with `phac-nml/pipeline-standards`
  - [PR28](https://github.com/phac-nml/gasclustering/pull/28)

## [0.2.0] - 2024-06-26

### Added

- Support for mismatched IDs between the samplesheet ID and the ID listed in the corresponding allele file.

### Changed

- Updated ArborView to v0.0.7-rc1.

### Fixed

- The scaled distance thresholds provided when using `--pd_distm scaled` and `--gm_thresholds` are now correctly understood as percentages in the range [0.0, 100.0].

## [0.1.0] - 2024-05-28

Initial release of the Genomic Address Service Clustering pipeline to be used for distance-based clustering of cg/wgMLST data.

### `Added`

- Input of cg/wgMLST allele calls produced from [locidex](https://github.com/phac-nml/locidex).
- Output of a dendrogram, cluster codes, and visualization using [profile_dists](https://github.com/phac-nml/profile_dists), [gas mcluster](https://github.com/phac-nml/genomic_address_service), and ArborView.

[0.1.0]: https://github.com/phac-nml/gasclustering/releases/tag/0.1.0
[0.2.0]: https://github.com/phac-nml/gasclustering/releases/tag/0.2.0
