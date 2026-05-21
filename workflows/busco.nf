/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
// Module imports
include { GUNZIP                 } from '../modules/nf-core/gunzip/main'
include { BUSCO_BUSCO            } from '../modules/nf-core/busco/busco/main'
include { RESTRUCTUREBUSCODIR    } from '../modules/sanger-tol/restructurebuscodir/main'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'

// Sanger-ToL custom functions
include { normaliseLineage       } from '../functions/local/utils.nf'

// NF-Core default imports
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_busco_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow BUSCO {

    take:
    ch_fastas // channel: all fasta files to process
    main:

    ch_versions = channel.empty()
    ch_multiqc_files = channel.empty()

    //
    // LOGIC: Identify the compressed files
    //
    ch_genomes_for_gunzip = ch_fastas
        .map { fasta, lineage, outdir ->
            def lineage_path = params.busco_db ?: []
            def new_lineage = params.lineage ? [params.lineage] : normaliseLineage(lineage, lineage_path, fasta.baseName)

            tuple(
                [id: fasta.baseName, lineage_input: lineage ?: params.lineage, lineage: new_lineage, outdir: outdir],
                fasta
            )
        }
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
    ch_genomes_for_gunzip.skip
        .mix( GUNZIP.out.gunzip )
        .map { meta, fa -> [ meta + [genome_size: fa.size()], fa] }
        .flatMap { meta, fa ->
            def lineages = meta.lineage
            lineages.collect { lin -> [ meta + [lineage: lin], fa ] }
        }
        .set { ch_genome }

    ch_genome.view{"BUSCO_INPUT: $it"}

    //
    // MODULE: Run BUSCO search
    //
    BUSCO_BUSCO(
        ch_genome,
        'genome',
        ch_genome.map { meta, _fasta -> meta.lineage },
        params.busco_db ?: [],
        [],
        []
    )


    //
    // MODULE: Tidy up the BUSCO output directories before publication
    //

    busco_out_to_restructure = BUSCO_BUSCO.out.batch_summary
        .join(BUSCO_BUSCO.out.short_summaries_txt, remainder: true)
        .join(BUSCO_BUSCO.out.short_summaries_json, remainder: true)
        .join(BUSCO_BUSCO.out.full_table, remainder: true)
        .join(BUSCO_BUSCO.out.missing_busco_list, remainder: true)
        .join(BUSCO_BUSCO.out.seq_dir)
        .map { meta, batch_summary, short_summaries_txt, short_summaries_json, full_table, missing_busco_list, busco_dir ->
            [meta, meta.lineage, batch_summary, short_summaries_txt ?: [], short_summaries_json ?: [], full_table ?: [], missing_busco_list ?: [], busco_dir]
        }

    RESTRUCTUREBUSCODIR(
        busco_out_to_restructure,
    )

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

    softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name:  'busco_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        channel.fromPath(params.multiqc_config, checkIfExists: true) :
        channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
