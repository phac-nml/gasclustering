# phac-nml/gasclustering: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.7.0] - 2025-06-06

### Updated

- Updated `ArborView` to version [0.1.0](https://github.com/phac-nml/ArborView/releases/tag/v0.1.0). [PR #52](https://github.com/phac-nml/gasclustering/pull/52)
  - `assets/ArborView.html` replaced with [table.html](https://github.com/phac-nml/ArborView/blob/v0.1.0/html/table.html)
  - `bin/inline_arborview.py` replaced with [fillin_data.py](https://github.com/phac-nml/ArborView/blob/v0.1.0/scripts/fillin_data.py)
  - The `ARBOR_VIEW` process now outputs the version of ArborView (`0.1.0`) to `software_versions.yml`
- Updated nf-core module [custom_dumpsoftwareversions](https://nf-co.re/modules/custom_dumpsoftwareversions/) to latest version (commit `05954dab2ff481bcb999f24455da29a5828af08d`). [PR #52](https://github.com/phac-nml/gasclustering/pull/52)
- Updated nf-core linting and some of the nf-core GitHub actions to the latest versions. [PR #52](https://github.com/phac-nml/gasclustering/pull/52)

## [0.6.3] - 2025-05-26

### Fixed

- Add a Ubuntu container for `COPY_FILE` to run on Azure. [PR #50](https://github.com/phac-nml/gasclustering/pull/50)

## [0.6.2] - 2025-05-26

### Fixed

- Fixed issue with dupilcate MLST JSON file names as input. [PR #48](https://github.com/phac-nml/gasclustering/pull/48).

## [0.6.1] - 2025-05-16

### Fixed

- Patched issue with `LOCIDEX_MERGE` input channel (`path` instead of `val`) causing issues with filesystems. [PR #46](https://github.com/phac-nml/gasclustering/pull/46)

## [0.6.0] - 2025-05-14

### Updated

- Updated `genomic address service` to v.0.2.0 [PR #44](https://github.com/phac-nml/gasclustering/pull/44)
- Updated `profile_dists` to v.1.0.5 [PR #44](https://github.com/phac-nml/gasclustering/pull/44)
- Updated `ArborView`to v.0.0.8 using files from `arboratornf` [PR #33](https://github.com/phac-nml/arboratornf/pull/33). [PR #44](https://github.com/phac-nml/gasclustering/pull/44)

### Enhancement

- `locidex merge` in `0.3.0` now performs the functionality of `input_assure` (checking sample name against MLST profiles). This allows `gasclustering` to remove `input_assure` so that the MLST JSON file is read only once, and no longer needs to re-write with correction. [PR #44](https://github.com/phac-nml/gasclustering/pull/44)
- Added a pre-processing step to the input of `LOCIDEX_MERGE` that splits-up samples, into batches (default batch size: `100`), to allow for `LOCIDEX_MERGE` to be run in parallel. To modify the size of batches use the parameter `--batch_size n`. [PR #44](https://github.com/phac-nml/gasclustering/pull/44)

## [0.5.0] - 2025-04-04

### `Changed`

- Changed file extensions (`.text` -> `.tsv`) of output files from `GAS_MCLUSTER` and `PROFILE_DISTS` found in the `iridanext.output.json`. Output files are now compatiable with file preview feature in IRIDA Next. [PR #40](https://github.com/phac-nml/gasclustering/pull/40)

### Updated

- Update the `profile_dist` version to [1.0.4](https://github.com/phac-nml/profile_dists/releases/tag/1.0.4). [PR 41](https://github.com/phac-nml/gasclustering/pull/41)
- Update the `ArborView` version to [0.0.8](https://github.com/phac-nml/ArborView/releases/tag/v0.0.8) (i.e. replace `assets/ArborView.html` with `html/table.html`) [PR 42](https://github.com/phac-nml/gasclustering/pull/42)

## [0.4.3] - 2025-03-17

### Changed

- Updating the version of `GAS` container from 0.1.4 -> [0.1.5](https://github.com/phac-nml/genomic_address_service/releases/tag/0.1.5). See [PR #37](https://github.com/phac-nml/gasclustering/pull/37).
- Updating the version of `locidex` container from 0.2.3 -> [0.3.0](https://github.com/phac-nml/locidex/releases/tag/v0.3.0). See [PR #37](https://github.com/phac-nml/gasclustering/pull/37).
- Updating the version of `profile_dists` container from 1.0.2 -> [1.0.3](https://github.com/phac-nml/profile_dists/releases/tag/1.0.3). See [PR #37](https://github.com/phac-nml/gasclustering/pull/37).
- Fixed some nf-core linting warnings and moved arborview.nf module to subfolder. See [PR #37](https://github.com/phac-nml/gasclustering/pull/37).

## [0.4.2] - 2025-02-11

### Changed

- Updating the version of `GAS` container from 0.1.3 -> [0.1.4](https://github.com/phac-nml/genomic_address_service/releases/tag/0.1.4).

## [0.4.1] - 2024-12-23

### Changed

- Updating the version of `GAS` container from 0.1.1 -> [0.1.3](https://github.com/phac-nml/genomic_address_service/pull/18)

## [0.4.0] - 2024-11-07

- Added the ability to include a `sample_name` column in the input samplesheet.csv. Allows for compatibility with IRIDA-Next input configuration.

  - `sample_name` special characters (non-alphanumeric with exception of "_" and ".") will be replaced with `"_"`
  - If no `sample_name` is supplied in the column `sample` will be used
  - To avoid repeat values for `sample_name` all `sample_name` values will be suffixed with the unique `sample` value from the input file

  - Fixed linting issues in CI caused by nf-core 3.0.1

## [0.3.0] - 2024-09-10

### Changed

- Upgraded `profile_dist` container to version `1.0.2`
- Upgraded `locidex/merge` to version `0.2.3` and updated `input_assure` and test data for compatibility with the new `mlst.json` allele file format.
  - [PR28](https://github.com/phac-nml/gasclustering/pull/28)
- Aligned container registry handling in configuration files and modules with `phac-nml/pipeline-standards`
  - [PR28](https://github.com/phac-nml/gasclustering/pull/28)

This pipeline is now compatible only with output generated by [Locidex v0.2.3+](https://github.com/phac-nml/locidex) and [Mikrokondo v0.4.0+](https://github.com/phac-nml/mikrokondo/releases/tag/v0.4.0).

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
[0.3.0]: https://github.com/phac-nml/gasclustering/releases/tag/0.3.0
[0.4.0]: https://github.com/phac-nml/gasclustering/releases/tag/0.4.0
[0.4.1]: https://github.com/phac-nml/gasclustering/releases/tag/0.4.1
[0.4.2]: https://github.com/phac-nml/gasclustering/releases/tag/0.4.2
[0.4.3]: https://github.com/phac-nml/gasclustering/releases/tag/0.4.3
[0.5.0]: https://github.com/phac-nml/gasclustering/releases/tag/0.5.0
[0.6.0]: https://github.com/phac-nml/gasclustering/releases/tag/0.6.0
[0.6.1]: https://github.com/phac-nml/gasclustering/releases/tag/0.6.1
[0.6.2]: https://github.com/phac-nml/gasclustering/releases/tag/0.6.2
[0.6.3]: https://github.com/phac-nml/gasclustering/releases/tag/0.6.3
[0.7.0]: https://github.com/phac-nml/gasclustering/releases/tag/0.7.0
