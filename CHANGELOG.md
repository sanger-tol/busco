# sanger-tol/busco: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [[0.1.0](https://github.com/sanger-tol/busco/releases/tag/0.1.0)] – Cambridgeshire – [2026-05-18]

This version was developped during the
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
