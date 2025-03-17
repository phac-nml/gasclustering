// Denovo clustering module for GAS

process GAS_MCLUSTER {
    label "process_high"
    tag "Denovo Clustering"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/genomic_address_service%3A0.1.5--pyhdfd78af_1' :
        'biocontainers/genomic_address_service:0.1.5--pyhdfd78af_1' }"

    input:
    path(dist_matrix)

    output:
    path("${prefix}/distances.{text,parquet}"), emit: distances, optional: true
    path("${prefix}/thresholds.json"), emit: thresholds
    path("${prefix}/clusters.{text,parquet}"), emit: clusters
    path("${prefix}/tree.nwk"), emit: tree
    path("${prefix}/run.json"), emit: run
    path  "versions.yml", emit: versions

    script:
    def prefix = "clusters"
    """
    gas mcluster --matrix $dist_matrix \\
                --outdir $prefix \\
                --method '${params.gm_method}' \\
                --threshold ${params.gm_thresholds} \\
                --delimeter '${params.gm_delimiter}' \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        genomic_address_service: \$( gas mcluster -V | sed -e "s/gas//g" )
    END_VERSIONS
    """
}
