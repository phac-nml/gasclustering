process APPEND_METADATA {
    tag "append_metadata"
    label 'process_low'

    input:
    val clusters_path  // cluster data as a TSV path
                        // this needs to be "val", because "path"
                        // won't stage the file correctly for exec
    val metadata  // metadata to be appended, list of lists

    output:
    path("clusters_and_metadata.tsv"), emit: clusters

    exec:
    def merged = []
    def rows

    clusters_path.withReader { reader ->
        rows = reader.readLines()*.split('\t')
    }

    for(int i = 0; i < rows.size(); i++)
    {
        merged.add(rows[i] + metadata[i])
    }

    task.workDir.resolve("clusters_and_metadata.tsv").withWriter { writer ->
        merged.each { writer.writeLine it.join("\t") }
    }

}
