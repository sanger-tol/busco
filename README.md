<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/sanger-tol-busco_logo_dark.png">
    <img alt="sanger-tol/busco" src="docs/images/sanger-tol-busco_logo_light.png">
  </picture>
</h1>

[![Open in GitHub Codespaces](https://img.shields.io/badge/Open_In_GitHub_Codespaces-black?labelColor=grey&logo=github)](https://github.com/codespaces/new/sanger-tol/busco)
[![GitHub Actions CI Status](https://github.com/sanger-tol/busco/actions/workflows/nf-test.yml/badge.svg)](https://github.com/sanger-tol/busco/actions/workflows/nf-test.yml)
[![GitHub Actions Linting Status](https://github.com/sanger-tol/busco/actions/workflows/linting.yml/badge.svg)](https://github.com/sanger-tol/busco/actions/workflows/linting.yml)
[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.20275259-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.20275259)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/version-%E2%89%A525.04.0-green?style=flat&logo=nextflow&logoColor=white&color=%230DC09D&link=https%3A%2F%2Fnextflow.io)](https://www.nextflow.io/)
[![nf-core template version](https://img.shields.io/badge/nf--core_template-3.5.1-green?style=flat&logo=nfcore&logoColor=white&color=%2324B064&link=https%3A%2F%2Fnf-co.re)](https://github.com/nf-core/tools/releases/tag/3.5.1)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://cloud.seqera.io/launch?pipeline=https://github.com/sanger-tol/busco)

## Introduction

**sanger-tol/busco** runs [BUSCO](https://busco.ezlab.org/) on one or many genome assemblies.

The pipeline supports:

- Single-assembly input via `--fasta`
- Multi-assembly input via `--input` samplesheet
- Per-assembly lineage selection and/or automated lineage discovery from NCBI taxonomy (`taxid`)
- Multiple ODB versions in one run via `--odb_versions`

For each assembly, the pipeline:

1. Decompresses gzipped FASTA files if needed.
2. Selects BUSCO lineage datasets using `get_odbs.py` and mapping files.
3. Runs BUSCO for every selected lineage.
4. Restructures outputs into a lineage-first layout under `busco/`.
5. Produces a MultiQC report and standard Nextflow trace files.

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

Run with a samplesheet:

```bash
nextflow run sanger-tol/busco \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
  --odb_versions odb12 \
   --outdir <OUTDIR>
```

Run with a single FASTA:

```bash
nextflow run sanger-tol/busco \
  -profile <docker/singularity/.../institute> \
  --fasta assembly.fasta.gz \
  --taxid 988087 \
  --mode latest \
  --odb_versions odb12 \
  --outdir <OUTDIR>
```

Required arguments:

- Exactly one input mode: `--input` or `--fasta`
- `--odb_versions` (comma-separated list, e.g. `odb10,odb12,odb12.2`)
- At least one lineage selection mechanism per sample: `mode` and/or `lineage`

If using `ancestral` or `latest` mode, `taxid` is required (global `--taxid` or per-row samplesheet value).

You can optionally provide `--busco_db` to run BUSCO in offline mode using local lineage datasets.

For full run instructions, input format, and parameter behavior, see [docs/usage.md](docs/usage.md).

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

## Credits

sanger-tol/busco was originally written by Tyler Chafin during the
[Cambridge BioHackathon 2024](https://www.c2d3.cam.ac.uk/events/2024-biohackathon)
with the participation of:

- [Pete Dockrill **@PeteDockrill**](https://github.com/PeteDockrill)
- [Axel Rodriguez **@errepeAxel**](https://github.com/errepeAxel)

[Matthieu Muffato **@muffato**](https://github.com/muffato) then
updated the pipeline for release under the [sanger-tol](https://github.com/sanger-tol)
umbrella organisation.

The pipeline underwent a large reset in v0.2.0 to focus on automating
BUSCO runs.
Functionality to run the BUSCO steps has been removed but will be reintegrated later.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

If you use sanger-tol/busco for your analysis, please cite:

- [10.5281/zenodo.20275259](https://doi.org/10.5281/zenodo.20275259)

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
