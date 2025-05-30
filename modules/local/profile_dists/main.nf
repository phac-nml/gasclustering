process PROFILE_DISTS{
    label "process_high"
    tag "Pairwise Distance Generation"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/profile_dists%3A1.0.5--pyhdfd78af_0' :
        'biocontainers/profile_dists:1.0.5--pyhdfd78af_0' }"

    input:
    path query
    val mapping_format
    path mapping_file
    path columns


    output:
    path("${prefix}_${mapping_format}/allele_map.json"), emit: allele_map
    path("${prefix}_${mapping_format}/query_profile.{tsv,parquet}"), emit: query_profile
    path("${prefix}_${mapping_format}/ref_profile.{tsv,parquet}"), emit: ref_profile
    path("${prefix}_${mapping_format}/results.{tsv,parquet}"), emit: results
    path("${prefix}_${mapping_format}/run.json"), emit: run
    path  "versions.yml", emit: versions


    script:
    def args = ""

    if(mapping_file){
        args = args + "--mapping_file $mapping_file"
    }
    if(columns){
        args = args + " --columns $columns"
    }
    if(params.pd_skip){
        args = args + " --skip"
    }
    if(params.pd_count_missing){
        args = args + " --count_missing"
    }
    prefix = "distances"
    """
    profile_dists --query $query --ref $query $args --outfmt $mapping_format \\
                --force \\
                --distm $params.pd_distm \\
                --file_type $params.pd_file_type \\
                --missing_thresh $params.pd_missing_threshold \\
                --sample_qual_thresh $params.pd_sample_quality_threshold \\
                --max_mem ${task.memory.toGiga()} \\
                --cpus ${task.cpus} \\
                -o ${prefix}_${mapping_format}

    # Rename all *.text to *.tsv
    for file in ${prefix}_${mapping_format}/*.text; do
        mv -- "\$file" "\${file%.text}.tsv"
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        profile_dists: \$( profile_dists -V | sed -e "s/profile_dists//g" )
    END_VERSIONS
    """

}
