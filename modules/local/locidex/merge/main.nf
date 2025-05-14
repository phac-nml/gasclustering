// Merge missing loci

process LOCIDEX_MERGE {
    tag 'Merge Profiles'
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/locidex%3A0.3.0--pyhdfd78af_0' :
        'biocontainers/locidex:0.3.0--pyhdfd78af_0' }"

    input:
    tuple val(batch_index), path(input_values) // [file(sample1), file(sample2), file(sample3), etc...]
    val  merge_tsv

    output:
    path("${combined_dir}/profile_${batch_index}.tsv"),           emit: combined_profiles
    path("${combined_dir}/MLST_error_report_${batch_index}.csv"), emit: combined_error_report
    path "versions.yml",                                          emit: versions

    script:
    combined_dir = "merged"
    """
    locidex merge -i ${input_values.join(' ')} -o ${combined_dir} -p ${merge_tsv}
    mv ${combined_dir}/MLST_error_report.csv ${combined_dir}/MLST_error_report_${batch_index}.csv
    mv ${combined_dir}/profile.tsv ${combined_dir}/profile_${batch_index}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        locidex merge: \$(echo \$(locidex search -V 2>&1) | sed 's/^.*locidex //' )
    END_VERSIONS
    """
}
