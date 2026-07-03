# sanger-tol/busco: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [[0.3.1](https://github.com/sanger-tol/busco/releases/tag/0.3.1)] – Lincolnshire (patch 1) – [2026-07-06]

### Enhancements & fixes

## [[0.3.0](https://github.com/sanger-tol/busco/releases/tag/0.3.0)] – Lincolnshire – [2026-07-03]

> [!WARNING]
> This pipeline is still in development. Documentation is still missing.

### Enhancements & fixes

- Reorganised the outputs to match the [Genome After-Party convention](https://pipelines.tol.sanger.ac.uk/docs/usage/gap_conventions)
- Move from local/busco workflow to sanger-tol/busco subworkflow.
- Adopt the `sanger-tol/api_search/get_odb_lineages` module, which uses taxid's to fetch lineage information about the sample. These are used to inform ODB selection.
- Adopt the `sanger-tol/busco/busco` module which is patched for prodigal use.
- Addition of the params `taxid`, `mode`, `odb_versions` and `mapping_directory`.
- Update the samplesheet to include `taxid` and trim the lineage to remove the odb version prefex.
- Minor updates to `usage.md` to explain the new parameters.

### Parameters

| Old Version | New Versions        |
| ----------- | ------------------- |
| NA          | --taxid             |
| NA          | --mode              |
| NA          | --odb_versions      |
| NA          | --mapping_directory |

### Software Dependencies

Note, since the pipeline is using Nextflow DSL2, each process will be run with its own Biocontainer. This means that on occasion it is entirely possible for the pipeline to be using different versions of the same tool. However, the overall software dependency changes compared to the last release have been listed below for reference.

| Module                         | Old Version | New Versions |
| ------------------------------ | ----------- | ------------ |
| `BUSCO_BUSCO`                  | 6.0.0       | 6.1.0        |
| `API_SCRIPTS_GET_LINEAGE_ODBS` | NA          | 2.0          |

## [[0.2.0](https://github.com/sanger-tol/busco/releases/tag/0.2.0)] – Bedfordshire – [2026-05-19]

Pipeline reset. In this new form, **sanger-tol/busco** is there to help running BUSCO
across _many_ genomes and _many_ lineages.
Functionality to run the BUSCO steps has been removed but will be reintegrated later.

> [!WARNING]
> This pipeline is still in development. Documentation is still missing.
> To run the pipeline, refer to the test profile and adjust to your own data.

## [[0.2.0-psyche](https://github.com/sanger-tol/busco/releases/tag/0.2.0-psyche)] – Bedfordshire (Psyche pre-release) – [2026-01-14]

Development version of the above v0.2.0. Used to generate BUSCO outputs for the
[Psyche project](https://www.projectpsyche.org/).

## [[0.1.0](https://github.com/sanger-tol/busco/releases/tag/0.1.0)] – Cambridgeshire – [2026-05-18]

This version was developed during the
[Cambridge BioHackathon 2024](https://www.c2d3.cam.ac.uk/events/2024-biohackathon).

### Enhancements & fixes

**sanger-tol/busco** is a bioinformatics pipeline that runs the BUSCO pipeline as individual tasks in Nextflow.
Its purpose is to distribute those tasks across compute nodes on a HPC and scale better to large genomes
than the monolithic BUSCO.

1. Identify the most relevant BUSCO lineage for the taxon of interest
2. Run BBTools
3. Run Miniprot
4. Run HMMER

> [!WARNING]
> This pipeline is still in development. Documentation is still missing.
> To run the pipeline, refer to the test profile and adjust to your own data.
