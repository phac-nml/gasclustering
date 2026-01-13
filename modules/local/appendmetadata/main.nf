process APPEND_METADATA {
    tag "append_metadata"
    label 'process_single'

    input:
    val clusters_path       // cluster data as a TSV path
                            // this needs to be "val", because "path"
                            // won't stage the file correctly for exec
    val metadata_rows       // metadata rows (no headers) to be appened, list of lists
    val metadata_headers    // headers to name the metadata columns

    output:
    path("clusters_and_metadata.tsv"), emit: clusters

    exec:
    def clusters_rows  // has a header row
    def clusters_rows_map = [:]
    def metadata_rows_map = [:]
    def merged = []

    clusters_path.withReader { reader ->
        clusters_rows = reader.readLines()*.split('\t')
    }

    // Create a map of the cluster rows:
    // Start on i = 1 because we don't want the headers.
    for(int i = 1; i < clusters_rows.size(); i++)
    {
        // "sample" -> ["sample", 1, 2, 3, ...]
        clusters_rows_map[clusters_rows[i][0]] = clusters_rows[i]
    }

    // Create a map of the metadata rows:
    // Start on i = 0 because there are no headers included.
    for(int i = 0; i < metadata_rows.size(); i++)
    {
        // "sample" -> ["sample", meta1, meta2, meta3, ...]
        metadata_rows_map[metadata_rows[i][0]] = metadata_rows[i]
    }

    // Merge the headers
    merged.add(clusters_rows[0] + metadata_headers)

    // Merge the remain rows in original order:
    // Start on i = 1 because we don't want the headers.
    for(int i = 1; i < clusters_rows.size(); i++)
    {
        def sample_key = clusters_rows[i][0]
        merged.add(clusters_rows_map[sample_key] + metadata_rows_map[sample_key][1..-1])
    }
    // Remove empty columns

    def transposed = merged.transpose()

    def merged_filtered = transposed.findAll { column ->
        def header = column.head()
        def dataOnly = column.tail()
        def isMetadata = (header ==~ /metadata_([1-9]|1[0-9]|2[0-4])/) //Checkif the metadata field was modified, if so keep even if empty [metadata_1 to metadata_24]
        return !isMetadata || dataOnly.any { it != '' } // Keep null values just remove columns with only empty rows
    }

    def merged_cleaned = merged_filtered.transpose()
    task.workDir.resolve("clusters_and_metadata.tsv").withWriter { writer ->
        merged_cleaned.each { writer.writeLine it.join("\t") }
    }

}
