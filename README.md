[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A523.04.3-brightgreen.svg)](https://www.nextflow.io/)

# Genomic Address Service Clustering Workflow

This workflow takes provided JSON-formatted MLST profiles and converts them into a phylogenetic tree with associated flat cluster codes for use in [Irida Next](https://github.com/phac-nml/irida-next). The workflow also generates an interactive tree for visualization.

A brief overview of the usage of this pipeline is given below. Detailed documentation can be found in the [docs/](docs/) directory.

# Input

The input to the pipeline is a standard sample sheet (passed as `--input samplesheet.csv`) that looks like:

| sample  | mlst_alleles      | metadata_1 | metadata_2 | metadata_3 | metadata_4 | metadata_5 | metadata_6 | metadata_7 | metadata_8 |
| ------- | ----------------- | ---------- | ---------- | ---------- | ---------- | ---------- | ---------- | ---------- | ---------- |
| SampleA | sampleA.mlst.json | meta1      | meta2      | meta3      | meta4      | meta5      | meta6      | meta7      | meta8      |

The structure of this file is defined in [assets/schema_input.json](assets/schema_input.json). Validation of the sample sheet is performed by [nf-validation](https://nextflow-io.github.io/nf-validation/). Details on the columns can be found in the [Full samplesheet](docs/usage.md#full-samplesheet) documentation.

# Parameters

The main parameters are `--input` as defined above and `--output` for specifying the output results directory. You may wish to provide `-profile singularity` to specify the use of singularity containers and `-r [branch]` to specify which GitHub branch you would like to run.

## Metadata

In order to customize metadata headers, the parameters `--metadata_1_header` through `--metadata_8_header` may be specified. These parameters are used to re-name the headers in the final metadata table from the defaults (e.g., rename `metadata_1` to `country`).

## Profile dists

The following can be used to adjust parameters for the [profile_dists][] tool.

- `--pd_outfmt`: The output format for distances, either *matrix* or *pairwise*.
- `--pd_distm`: The distance method/unit, either *hamming* or *scaled*.
- `--pd_missing_threshold`: The maximum proportion of missing data per locus.
- `--pd_sample_quality_threshold`: The maximum proportion of missing data per sample.
- `--pd_match_threshold`: Threshold for matches. Should match unit used in pd_distm. Used only with `--pd_outfmt pairwise`.
- `--pd_file_type`: Output format file type. One of *text* or *parquet*.
- `--pd_mapping_file`: JSON formatted allele mapping file.
- `--pd_skip`: Skip QA/QC steps.
- `--pd_columns`: Single column file with one column name per line or list of columns comma separate.
- `--pd_count_missing`: Count missing as differences.

## GAS mcluster

The following can be used to adjust parameters for the [gas mcluster][] tool.

- `--gm_thresholds`: Thresholds delimited by `,`. Values should match units from '--pd_distm' (either *hamming* or *scaled*).
- `--gm_delimiter`: Delimiter desired for nomenclature code.

## Other

Other parameters (defaults from nf-core) are defined in [nextflow_schema.json](nextflow_schmea.json).

# Running

To run the pipeline, please do:

```bash
nextflow run phac-nml/gasclustering -profile singularity -r main -latest --input https://github.com/phac-nml/gasclustering/raw/dev/assets/samplesheet.csv --outdir results
```

Where the `samplesheet.csv` is structured as specified in the [Input](#input) section.

# Output

A JSON file for loading metadata into IRIDA Next is output by this pipeline. The format of this JSON file is specified in our [Pipeline Standards for the IRIDA Next JSON](https://github.com/phac-nml/pipeline-standards#32-irida-next-json). This JSON file is written directly within the `--outdir` provided to the pipeline with the name `iridanext.output.json.gz` (ex: `[outdir]/iridanext.output.json.gz`).

An example of the what the contents of the IRIDA Next JSON file looks like for this particular pipeline is as follows:

```
{
    "files": {
        "global": [
            {
                "path": "ArborView/clustered_data_arborview.html"
            },
            {
                "path": "clusters/run.json"
            },
            {
                "path": "clusters/tree.nwk"
            },
            {
                "path": "clusters/clusters.text"
            },
            {
                "path": "clusters/thresholds.json"
            },
            {
                "path": "distances/run.json"
            },
            {
                "path": "distances/results.text"
            },
            {
                "path": "distances/ref_profile.text"
            },
            {
                "path": "distances/query_profile.text"
            },
            {
                "path": "distances/allele_map.json"
            },
            {
                "path": "merged/profile.tsv"
            }
        ],
        "samples": {

        }
    },
    "metadata": {
        "samples": {

        }
    }
}
```

Within the `files` section of this JSON file, all of the output paths are relative to the `outdir`. Therefore, `"path": "ArborView/clustered_data_arborview.html"` refers to a file located within `outdir/ArborView/clustered_data_arborview.html`.

Details on the individual output files can be found in the [Output documentation](docs/output.md).

## Test profile

To run with the test profile, please do:

```bash
nextflow run phac-nml/gasclustering -profile docker,test -r main -latest --outdir results
```

# Legal

Copyright 2024 Government of Canada

Licensed under the MIT License (the "License"); you may not use
this work except in compliance with the License. You may obtain a copy of the
License at:

https://opensource.org/license/mit/

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.

[profile_dists]: https://github.com/phac-nml/profile_dists
[gas mcluster]: https://github.com/phac-nml/genomic_address_service
