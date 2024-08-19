// Inline output tree into ArborView.html
// TODO include versions for python and arbor view when available



process ARBOR_VIEW {
    label "process_low"
    tag "Inlining Tree Data"
    stageInMode 'copy' // Need to copy in arbor view html

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    "docker.io/python:3.11.6" :
    task.ext.override_configured_container_registry != false ? 'docker.io/python:3.11.6' :
    'python:3.11.6' }"

    input:
    tuple path(tree), path(contextual_data)
    path(arbor_view) // need to make sure this is copied


    output:
    path(output_value), emit: html


    script:
    output_value = "clustered_data_arborview.html"
    """
    inline_arborview.py -d ${contextual_data} -n ${tree} -o ${output_value} -t ${arbor_view}
    """



}
