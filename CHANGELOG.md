# sanger-tol/busco: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [[0.3.0](https://github.com/sanger-tol/busco/releases/tag/0.3.0)] – Lincolnshire – [2026-05-XX]

### Enhancements & fixes

- Lineage handling has been improved to support:
  - `ALL` - Which runs all lineages found in the lineage directory
  - `odb{int}` - Which runs all lineages with the suffix `odb{int}`
  - `{lineage}` - Without the `odb` suffix, will find the odbs with the prefix `{lineage}`
  - "{lineage}\_odb{int},{lineage}\_odb{int}" - Lists are still supported
  - All options, other than providing a list, require the `--busco_db` parameter to point at an existing download of the BUSCO lineages database.
  - Be aware that running `ALL`, can result in 691 jobs submitted.

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
