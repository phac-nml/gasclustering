process REPORT_PROBLEMS {
    tag "Reporting Problems"
    label 'process_single'

    input:
    val problems  // list of problems (first entry in each must be "meta")

    output:
    path("problematic_samples.csv"), emit: problems_report

    exec:
    task.workDir.resolve("problematic_samples.csv").withWriter { writer ->

        writer.writeLine("sample")  // header

        // Problems:
        if (problems.size() > 0) {
            problems.each { writer.writeLine "${it[0].id}" }
        }
    }
}
