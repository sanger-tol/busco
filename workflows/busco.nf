/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { GUNZIP                        } from '../modules/nf-core/gunzip/main'
include { ODBSEARCH_BUSCO_RESTRUCTURE   } from '../subworkflows/sanger-tol/odbsearch_busco_restructure/main'
include { MULTIQC                       } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap              } from 'plugin/nf-schema'
include { paramsSummaryMultiqc          } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML        } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText        } from '../subworkflows/local/utils_nfcore_busco_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow BUSCO {

    take:
    ch_fastas // channel: all fasta files to process


    multiqc_config
    multiqc_logo
    multiqc_methods_description
    outdir

    main:
    def ch_versions      = channel.empty()
    def ch_multiqc_files = channel.empty()


    //
    // LOGIC: Identify the compressed files
    //
    ch_genomes_for_gunzip = ch_fastas
        .map { fasta, taxid, mode, lineage, sample_outdir -> tuple(
            [
                id: fasta.baseName,
                taxid: taxid ?: params.taxid,
                mode: mode ?: params.mode,
                lineage: lineage ?: params.lineage ?: [],
                outdir: sample_outdir,
            ],
            fasta
        ) }
        .branch { _meta, fasta ->
            gunzip: fasta.name.endsWith( ".gz" )
            skip: true
        }


    //
    // MODULE: Decompress compressed FASTA files
    //
    GUNZIP ( ch_genomes_for_gunzip.gunzip )


    //
    // LOGIC: Extract the genome size for decision making downstream
    //
    ch_reference = GUNZIP.out.gunzip
        // To have the name without the .fa/.fasta extension
        .map { meta, fa -> [ meta + [id: fa.baseName], fa ] }
        // These are already named as expected
        .mix ( ch_genomes_for_gunzip.skip )
        .map { meta, fa -> [ meta + [genome_size: fa.size()], fa] }

    ch_mapping_dir = params.mapping_directory
        ? channel.value( file(params.mapping_directory, type: "dir") )
        : channel.value( [] )

    ch_busco_db = params.busco_db
        ? channel.value( file(params.busco_db, type: "dir") )
        : channel.value( [] )


    //
    // SUBWORKFLOW: SEARCH FOR BUSCO ODBS, RUN BUSCO AND RESTRUCTURE THE OUTPUT DIRECTORIES
    //
    ODBSEARCH_BUSCO_RESTRUCTURE (
        ch_reference,
        ch_busco_db,
        ch_mapping_dir,
        true,
    )

    ch_multiqc_files = ch_multiqc_files.mix( ODBSEARCH_BUSCO_RESTRUCTURE.out.short_summaries.map { _meta, file -> file } )

    //
    // Collate and save software versions
    //
    def topic_versions = channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
        }
        .groupTuple(by:0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    def ch_collated_versions = softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${outdir}/pipeline_info",
            name:  'busco_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        )

    //
    // MODULE: MultiQC
    //
    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    def ch_summary_params = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    def ch_workflow_summary = channel.value(paramsSummaryMultiqc(ch_summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    def ch_multiqc_custom_methods_description = multiqc_methods_description
        ? file(multiqc_methods_description, checkIfExists: true)
        : file("${projectDir}/assets/methods_description_template.yml", checkIfExists: true)
    def ch_methods_description = channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', sort: true))
    MULTIQC(
        ch_multiqc_files.flatten().collect().map { files ->
            [
                [id: 'busco'],
                files,
                multiqc_config
                    ? file(multiqc_config, checkIfExists: true)
                    : file("${projectDir}/assets/multiqc_config.yml", checkIfExists: true),
                multiqc_logo ? file(multiqc_logo, checkIfExists: true) : [],
                [],
                [],
            ]
        }
    )
    emit:multiqc_report = MULTIQC.out.report.map { _meta, report -> [report] }.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
