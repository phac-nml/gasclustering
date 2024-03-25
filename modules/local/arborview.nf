// Inline output tree into ArborView.html
// TODO include versions for python and arbor view when available



process ARBOR_VIEW {
    label "process_low"
    tag "${meta.id}"
    stageInMode 'copy' // Need to copy in arbor view html

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    "docker.io/python:3.11.6" :
    "docker.io/python:3.11.6" }"

    input:
    tuple val(meta), path(tree), path(contextual_data)
    path(arbor_view) // need to make sure this is copied


    output:
    tuple val(meta), path(output_value), emit: html


    script:
    output_value = "${meta.id}_arborview.html"
    """
    inline_arborview.py -d ${contextual_data} -n ${tree} -o ${output_value} -t ${arbor_view}
    """



}