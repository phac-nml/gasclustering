// Denovo clustering module for GAS

process GAS_MCLUSTER{
    label "process_high"
    tag "Denovo Clustering"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'biocontainers/genomic_address_service:0.2.0--pyhdfd78af_0' :
        'biocontainers/genomic_address_service:0.2.0--pyhdfd78af_0' }"

    input:
    path(dist_matrix)

    output:
    path("${prefix}/distances.{text,parquet}"), emit: distances, optional: true
    path("${prefix}/thresholds.json"), emit: thresholds
    path("${prefix}/clusters.{tsv,parquet}"), emit: clusters
    path("${prefix}/tree.nwk"), emit: tree
    path("${prefix}/run.json"), emit: run
    path  "versions.yml", emit: versions

    script:
    prefix = "clusters"
    """
    gas mcluster --matrix $dist_matrix \\
                --outdir $prefix \\
                --method '${params.gm_method}' \\
                --threshold ${params.gm_thresholds} \\
                --delimiter '${params.gm_delimiter}'

    # Change the file extension of gas mcluster outputs for the clusters.text file

    mv clusters/clusters.text clusters/clusters.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        genomic_address_service: \$( gas mcluster -V | sed -e "s/gas//g" )
    END_VERSIONS
    """
}
