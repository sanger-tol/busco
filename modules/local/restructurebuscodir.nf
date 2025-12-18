process RESTRUCTUREBUSCODIR {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'nf-core/ubuntu:20.04' }"

    input:
    tuple val(meta), path(busco_dir)
    val lineage

    output:
    tuple val(meta), path("${lineage}/*"), emit: files
    path "versions.yml"                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """

    mkdir -p ${lineage}
    for i in busco_sequences/fragmented_busco_sequences busco_sequences/multi_copy_busco_sequences busco_sequences/single_copy_busco_sequences hmmer_output miniprot_output
    do
        if [[ -d ${busco_dir}/\$i ]]
        then
            tar czf ${lineage}/\$(basename \${i}).tar.gz --exclude=.checkpoint -C ${busco_dir}/\$i .
        fi
    done
    for i in ${busco_dir}/*
    do
        ln -s ../\$i ${lineage}/
    done
    rm -f ${lineage}/*_output

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tar: \$(tar --version| awk 'NR==1 {print \$4}' )
    END_VERSIONS
    """
}
