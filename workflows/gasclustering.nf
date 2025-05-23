/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap; fromSamplesheet  } from 'plugin/nf-validation'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

WorkflowGasclustering.initialise(params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { WRITE_METADATA  } from '../modules/local/write/main'
include { COPY_FILE       } from '../modules/local/copyFile/main'
include { LOCIDEX_MERGE   } from '../modules/local/locidex/merge/main'
include { LOCIDEX_CONCAT  } from '../modules/local/locidex/concat/main'
include { PROFILE_DISTS   } from '../modules/local/profile_dists/main'
include { GAS_MCLUSTER    } from '../modules/local/gas/mcluster/main'
include { APPEND_METADATA } from '../modules/local/appendmetadata/main'
include { ARBOR_VIEW      } from '../modules/local/arborview/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'
include { loadIridaSampleIds          } from 'plugin/nf-iridanext'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


def prepareFilePath(String filep){
    // Rerturns null if a file is not valid
    def return_path = null
    if(filep){
        file_in = file(filep)
        if(file_in.exists()){
            return_path = file_in
        }
    }else{
        return_path = []
    }

    return return_path // empty value if file argument is null
}

workflow GASCLUSTERING {
    SAMPLE_HEADER = "sample"
    ch_versions = Channel.empty()

    // Track processed IDs and MLST files
    def processedIDs = [] as Set
    def processedMLST = [] as Set

    // Create a new channel of metadata from a sample sheet
    // NB: `input` corresponds to `params.input` and associated sample sheet schema
    pre_input = Channel.fromSamplesheet("input")

    // and remove non-alphanumeric characters in sample_names (meta.id), whilst also correcting for duplicate sample_names (meta.id)
    .map { meta, mlst_file ->
            uniqueMLST = true
            if (!meta.id) {
                meta.id = meta.irida_id
            } else {
                // Non-alphanumeric characters (excluding _,-,.) will be replaced with "_"
                meta.id = meta.id.replaceAll(/[^A-Za-z0-9_.\-]/, '_')
            }
            // Ensure ID is unique by appending meta.irida_id if needed
            while (processedIDs.contains(meta.id)) {
                meta.id = "${meta.id}_${meta.irida_id}"
            }

           // Check if the MLST file is unique
            if (processedMLST.contains(mlst_file.baseName)) {
                uniqueMLST = false
            }

            // Add the ID to the set of processed IDs
            processedIDs << meta.id
            processedMLST << mlst_file.baseName

            tuple(meta, mlst_file, uniqueMLST)}.loadIridaSampleIds()

    // For the MLST files that are not unique, rename them
    pre_input
        .branch { meta, mlst_file, uniqueMLST ->
            keep: uniqueMLST == true // Keep the unique MLST files as is
            replace: uniqueMLST == false // Rename the non-unique MLST files to avoid collisions
        }.set {mlst_file_rename}
    renamed_input = COPY_FILE(mlst_file_rename.replace)
    unchanged_input = mlst_file_rename.keep
        .map { meta, mlst_file, uniqueMLST ->
            tuple(meta, mlst_file) }
    input = unchanged_input.mix(renamed_input)

    metadata_headers = Channel.of(
        tuple(
            SAMPLE_HEADER,
            params.metadata_1_header, params.metadata_2_header,
            params.metadata_3_header, params.metadata_4_header,
            params.metadata_5_header, params.metadata_6_header,
            params.metadata_7_header, params.metadata_8_header)
        )

    metadata_rows = input.map{
        meta, mlst_files -> tuple(meta.id, meta.irida_id,
        meta.metadata_1, meta.metadata_2, meta.metadata_3, meta.metadata_4,
        meta.metadata_5, meta.metadata_6, meta.metadata_7, meta.metadata_8)
    }.toList()

    // Prepare MLST files for LOCIDEX_MERGE

    merged_alleles = input
    .map { meta, mlst_file ->
        mlst_file
    }.collect()

    // Create channels to be used to create a MLST override file (below)
    SAMPLE_HEADER = "sample"
    MLST_HEADER   = "mlst_alleles"

    write_metadata_headers = Channel.of(
        tuple(
            SAMPLE_HEADER, MLST_HEADER)
        )
    write_metadata_rows = input.map{
        def meta = it[0]
        def mlst = it[1]
        tuple(meta.id,mlst)
    }.toList()

    merge_tsv = WRITE_METADATA (write_metadata_headers, write_metadata_rows).results.first() // MLST override file value channel

    // Merge MLST files into TSV

    // 1A) Divide up inputs into groups for LOCIDEX
    def batchCounter = 1
    grouped_ref_files = merged_alleles.flatten() //
        .buffer( size: params.batch_size, remainder: true )
                .map { batch ->
        def index = batchCounter++
        return tuple(index, batch)
    }
    // 1B) Run LOCIDEX
    merged = LOCIDEX_MERGE(grouped_ref_files, merge_tsv)
    ch_versions = ch_versions.mix(merged.versions)

    // LOCIDEX Step 2:
    // Combine outputs

    // LOCIDEX Concatenate

    combined_merged = LOCIDEX_CONCAT(merged.combined_profiles.collect(),
    merged.combined_error_report.collect(),
    merged.combined_profiles.collect().flatten().count())

    // optional files passed in
    mapping_file = prepareFilePath(params.pd_mapping_file)
    if(mapping_file == null){
        exit 1, "${params.pd_mapping_file}: Does not exist but was passed to the pipeline. Exiting now."
    }

    columns_file = prepareFilePath(params.pd_columns)
    if(columns_file == null){
        exit 1, "--pd_columns ${params.pd_columns}: Does not exist but was passed to the pipeline. Exiting now."
    }

    if(params.gm_thresholds == null || params.gm_thresholds == ""){
        exit 1, "--gm_thresholds ${params.gm_thresholds}: Cannot pass null or empty string"
    }

    gm_thresholds_list = params.gm_thresholds.toString().split(',')
    if (params.pd_distm == 'hamming') {
        if (gm_thresholds_list.any { it != null && it.contains('.') }) {
            exit 1, ("'--pd_distm ${params.pd_distm}' is set, but '--gm_thresholds ${params.gm_thresholds}' contains fractions."
                    + " Please either set '--pd_distm scaled' or remove fractions from distance thresholds.")
        }
    } else if (params.pd_distm == 'scaled') {
        if (gm_thresholds_list.any { it != null && (it as Float < 0.0 || it as Float > 100.0) }) {
            exit 1, ("'--pd_distm ${params.pd_distm}' is set, but '--gm_thresholds ${params.gm_thresholds}' contains thresholds outside of range [0, 100]."
                    + " Please either set '--pd_distm hamming' or adjust the threshold values.")
        }
    } else {
        exit 1, "'--pd_distm ${params.pd_distm}' is an invalid value. Please set to either 'hamming' or 'scaled'."
    }

    // Options related to profile dists
    mapping_format = Channel.value(params.pd_outfmt)

    distances = PROFILE_DISTS(combined_merged.combined_profiles, mapping_format, mapping_file, columns_file)
    ch_versions = ch_versions.mix(distances.versions)

    clustered_data = GAS_MCLUSTER(distances.results)
    ch_versions = ch_versions.mix(clustered_data.versions)

    data_and_metadata = APPEND_METADATA(clustered_data.clusters, metadata_rows, metadata_headers)
    tree_data = clustered_data.tree.merge(data_and_metadata) // mergeing as no key to join on

    tree_html = file("$projectDir/assets/ArborView.html")
    ARBOR_VIEW(tree_data, tree_html)

    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log)
    }
    NfcoreTemplate.dump_parameters(workflow, params)
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
