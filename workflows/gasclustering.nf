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
include { LOCIDEX_MERGE    } from '../modules/local/locidex/merge/main'
include { PROFILE_DISTS    } from '../modules/local/profile_dists/main'
include { GAS_MCLUSTER     } from '../modules/local/gas/mcluster/main'
include { APPEND_METADATA  } from '../modules/local/appendmetadata/main'
include { ARBOR_VIEW       } from '../modules/local/arborview.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'

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

    ch_versions = Channel.empty()

    // Create a new channel of metadata from a sample sheet
    // NB: `input` corresponds to `params.input` and associated sample sheet schema
    input = Channel.fromSamplesheet("input")

    merged_alleles = input.map{
        meta, mlst_files -> mlst_files
    }.collect()

    metadata_headers = Channel.of(
        tuple(
            params.metadata_1_header, params.metadata_2_header,
            params.metadata_3_header, params.metadata_4_header,
            params.metadata_5_header, params.metadata_6_header,
            params.metadata_7_header, params.metadata_8_header)
        )

    metadata_rows = input.map{
        meta, mlst_files -> tuple(meta.id,
        meta.metadata_1, meta.metadata_2, meta.metadata_3, meta.metadata_4,
        meta.metadata_5, meta.metadata_6, meta.metadata_7, meta.metadata_8)
    }.toList()

    merged = LOCIDEX_MERGE(merged_alleles)
    ch_versions = ch_versions.mix(merged.versions)

    // optional files passed in
    mapping_file = prepareFilePath(params.pd_mapping_file)
    if(mapping_file == null){
        exit 1, "${params.pd_mapping_file}: Does not exist but was passed to the pipeline. Exiting now."
    }

    columns_file = prepareFilePath(params.pd_columns)
    if(columns_file == null){
        exit 1, "--gm_thresholds ${params.pd_columns}: Does not exist but was passed to the pipeline. Exiting now."
    }

    if(params.gm_thresholds == null || params.gm_thresholds == ""){
        exit 1, "--gm_thresholds ${params.gm_thresholds}: Cannot pass null or empty string"
    }

    // Options related to profile dists
    mapping_format = Channel.value(params.pd_outfmt)

    distances = PROFILE_DISTS(merged.combined_profiles, mapping_format, mapping_file, columns_file)
    ch_versions = ch_versions.mix(distances.versions)

    clustered_data = GAS_MCLUSTER(distances.results)
    ch_versions = ch_versions.mix(clustered_data.versions)

    /* TODO contextual data is not meant to be the clusters.tsv file output by GAS_MCLUSTER but
    it is simply a place holder showing how the module is intended to be used for later re-factoring
    */

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
