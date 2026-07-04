# sanger-tol/busco: Usage

> _Documentation of pipeline parameters is generated automatically from the pipeline schema and can no longer be found in markdown files._

## Introduction

This pipeline runs BUSCO on one or many assemblies, with lineage selection driven by:

- `mode` (`basal`, `latest`, `ancestral`; can be comma-separated)
- `lineage` (explicit extra lineage(s), comma-separated)
- `taxid` (required for `latest` and `ancestral`)
- `odb_versions` (one or more ODB releases)

For each selected lineage and assembly, BUSCO is run in `genome` mode.

## Samplesheet input

You will need to create a samplesheet with information about the samples you would like to analyse before running the pipeline. Use this parameter to specify its location. It has to be a comma-separated file with 5 columns, and a header row as shown in the examples below.

```bash
--input '[path to samplesheet file]'
```

```csv title="samplesheet.csv"
fasta,taxid,mode,lineage,outdir
https://tolit.cog.sanger.ac.uk/test-data/Meles_meles/assembly/release/mMelMel3.1_paternal_haplotype/GCA_922984935.2.subset.phiXspike.fasta.gz,,,mammalia,Meles_meles.GCA_922984935.2.subset.phiXspike
https://tolit.cog.sanger.ac.uk/test-data/Laetiporus_sulphureus/assembly/release/gfLaeSulp1.1/insdc/GCA_927399515.1.fasta.gz,5630,ancestral,,Laetiporus_sulphureus.GCA_927399515.1
https://tolit.cog.sanger.ac.uk/test-data/Ceramica_pisi/assembly/release/ilCerPisi1.1/insdc/GCA_963859965.1.fasta.gz,988087,latest,,Ceramica_pisi.GCA_963859965.1
```

| Column    | Description                                                                                                                          |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `fasta`   | Required. Assembly FASTA path or URL (`.fa`/`.fasta`, optionally `.gz`).                                                             |
| `taxid`   | NCBI taxid for this assembly. Required when this row uses mode `latest` or `ancestral`. Defaults to global `--taxid` if empty.       |
| `mode`    | Lineage selection mode(s) for this assembly: `basal`, `latest`, `ancestral` (comma-separated). Defaults to global `--mode` if empty. |
| `lineage` | Additional explicit lineage name(s) to add (comma-separated). Defaults to global `--lineage` if empty.                               |
| `outdir`  | Output directory/subdirectory for this assembly. Relative values are created under global `--outdir`.                                |

An [example samplesheet](../assets/samplesheet.csv) has been provided with the pipeline.

## Params explanations

### mode

`params.mode` controls how the pipeline selects lineage ODBs for each sample.

By default this is `""` and the pipeline relies only on lineages specified via `lineage` (global `--lineage` or per-row samplesheet value).

- `basal` selects the basal lineage set (`eukaryota`, `bacteria`, `archaea` by default).
- `latest` selects the most specific mapped lineage in the taxonomic path for the provided taxid.
- `ancestral` selects all mapped ancestral lineages for the provided taxid.

> [!IMPORTANT]
> `latest` and `ancestral` cannot be used together for the same sample.

`taxid`, `mode`, and `lineage` can be set globally or per-row in the samplesheet. Per-row values take precedence.

### odb_versions

As of pipeline version `0.3.0`, the available ODB versions are `odb10`, `odb12`, and `odb12.2`.
Provide them as a CSV list (for example: `--odb_versions odb10,odb12`).

Selections are computed independently for each ODB version, so adding versions multiplies the number of BUSCO runs.

For example, the following command will run the pipeline with `odb10` and `odb12` versions in `basal` mode, resulting in (by default) 6 busco runs:
`--mode basal --odb_versions odb10,odb12`. \
Likewise, a taxid with 8 ancestral lineages using `--odb_versions odb10,odb12,odb12.2` will result in 24 busco runs.

### mapping_directory

Mapping files must follow the naming convention `<odb_version>_mapping.txt` (for example: `odb12_mapping.txt`) and be located in `--mapping_directory`.
A default mapping directory is provided in `modules/sanger-tol/apiscripts/getlineageodbs/resources/busco_mapping_files`.

The pipeline ships mapping files made by concatenating the eukaryota, bacteria, and archaea,
ODB mapping files provided by the [BUSCO](https://busco.ezlab.org/) project at the `busco-data.ezlab.org` data repository. \
For instance, to make the `odb10` merged mapping file, the below files were merged into `odb10_mapping.txt`:

- https://busco-data.s3.amazonaws.com/placement_files/mapping_taxids-busco_dataset_name.archaea_odb10.2019-12-16.txt.tar.gz"
- https://busco-data.s3.amazonaws.com/placement_files/mapping_taxids-busco_dataset_name.bacteria_odb10.2019-12-16.txt.tar.gz"
- https://busco-data.s3.amazonaws.com/placement_files/mapping_taxids-busco_dataset_name.eukaryota_odb10.2019-12-16.txt.tar.gz"

However, it should be noted that the end user can use any mapping file they wish, as long as they are aware this can change the results of the odb search performed in the pipeline.

## Running the pipeline

This pipeline has been designed to work via the cli or via samplesheet. The typical command for running the pipeline is as follows:

```bash
nextflow run sanger-tol/busco --input ./samplesheet.csv --odb_versions odb12 --outdir ./results  -profile docker
```

or

```bash
nextflow run sanger-tol/busco --fasta {FASTA} --mode {ancestral,latest,basal} --lineage {extra lineages} --taxid {NCBI taxid} --odb_versions odb10 --outdir ./results -profile docker
```

This will launch the pipeline with the `docker` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

> [!WARNING]
> Do not use `-c <file>` to specify parameters as this will result in errors. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources), other infrastructural tweaks (such as output directories), or module arguments (args).

The above pipeline run specified with a params file in yaml format:

```bash
nextflow run sanger-tol/busco -profile docker -params-file params.yaml
```

with:

```yaml title="params.yaml"
input: "./samplesheet.csv"
odb_versions: "odb12"
outdir: "./results/"
```

or

```yaml title="params.yaml"
fasta: "assembly.fasta.gz"
taxid: 10101
lineage: "diptera"
mode: "ancestral"
odb_versions: "odb12.2"
outdir: "./results/"
```

You can also generate such `YAML`/`JSON` files via [nf-core/launch](https://nf-co.re/launch).

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull sanger-tol/busco
```

### Reproducibility

It is a good idea to specify the pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [sanger-tol/busco releases page](https://github.com/sanger-tol/busco/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future. For example, at the bottom of the MultiQC reports.

To further assist in reproducibility, you can use share and reuse [parameter files](#running-the-pipeline) to repeat pipeline runs with the same settings without having to write out a command with every single parameter.

> [!TIP]
> If you wish to share such profile (such as upload as supplementary material for academic publications), make sure to NOT include cluster specific paths to files, nor institutional specific profiles.

## Core Nextflow arguments

> [!NOTE]
> These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen)

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Apptainer, Conda) - see below.

> [!IMPORTANT]
> We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to check if your system is supported, please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer environment.

- `test`
  - A profile with a complete configuration for automated testing
  - Includes links to test data so needs no other parameters
- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `podman`
  - A generic configuration profile to be used with [Podman](https://podman.io/)
- `shifter`
  - A generic configuration profile to be used with [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
- `charliecloud`
  - A generic configuration profile to be used with [Charliecloud](https://charliecloud.io/)
- `apptainer`
  - A generic configuration profile to be used with [Apptainer](https://apptainer.org/)
- `wave`
  - A generic configuration profile to enable [Wave](https://seqera.io/wave/) containers. Use together with one of the above (requires Nextflow ` 24.03.0-edge` or later).
- `conda`
  - A generic configuration profile to be used with [Conda](https://conda.io/docs/). Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker, Singularity, Podman, Shifter, Charliecloud, or Apptainer.

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the pipeline steps, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher resources request (2 x original, then 3 x original). If it still fails after the third attempt then the pipeline execution is stopped.

To change the resource requests, please see the [max resources](https://nf-co.re/docs/usage/configuration#max-resources) and [tuning workflow resources](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) section of the nf-core website.

### Custom Containers

In some cases, you may wish to change the container or conda environment used by a pipeline steps for a particular tool. By default, nf-core pipelines use containers and software from the [biocontainers](https://biocontainers.pro/) or [bioconda](https://bioconda.github.io/) projects. However, in some cases the pipeline specified version maybe out of date.

To use a different container from the default container or conda environment specified in a pipeline, please see the [updating tool versions](https://nf-co.re/docs/usage/configuration#updating-tool-versions) section of the nf-core website.

### Custom Tool Arguments

A pipeline might not always support every possible argument or option of a particular tool used in pipeline. Fortunately, nf-core pipelines provide some freedom to users to insert additional parameters that the pipeline does not include by default.

To learn how to provide additional arguments to a particular tool of the pipeline, please see the [customising tool arguments](https://nf-co.re/docs/usage/configuration#customising-tool-arguments) section of the nf-core website.

### nf-core/configs

In most cases, you will only need to create a custom config as a one-off but if you and others within your organisation are likely to be running nf-core pipelines regularly and need to use the same settings regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter. You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information about creating your own configuration files.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs).

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
