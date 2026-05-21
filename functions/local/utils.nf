def normaliseLineage(lineage, lineage_path, sample_id) {
    // A comma-separated string of fully-qualified lineage names (e.g. "fungi_odb10,eukaryota_odb10")
    if (lineage.contains(',')) {
        def lineage_list = lineage.tokenize(',')*.trim()
        def invalid = lineage_list.findAll { !(it =~ /^.+_odb\d+$/) }
        if (invalid) {
            error "normaliseLineage: ${sample_id} - Items in list don't follow the {name}_odb{int} pattern: ${invalid}"
        }
        log.info "BUSCO [normaliseLineage]: ${sample_id} - Provided list – returning ${lineage_list.size()}"
        return lineage_list
    }

    // A fully-qualified lineage (e.g. lepidoptera_odb10) is returned as-is
    if (lineage =~ /^.+_odb\d+$/) {
        return [lineage]
    }

    // Partial lineage queries require a lineage path to resolve against
    // -- All fully-qualified lineages (e.g. lepidoptera_odb10) are checked by this point.
    // -- We can't simply return all lineages unless we have the mapping file like in sanger-tol/blobtoolkit
    if (!lineage_path) {
        error "Cannot resolve lineage '${lineage}': please provide --busco_db pointing to a BUSCO download directory"
    }

    // BUSCO stores individual lineage datasets under <download_path>/lineages/
    def lineages_dir = new File("${lineage_path}/lineages")
    if (!lineages_dir.isDirectory()) {
        error "Lineages directory not found: ${lineages_dir.absolutePath}"
    }

    // Collect all valid lineage directory names (pattern: {lineage}_odb{int})
    def all_lineages = lineages_dir.list()
        ?.findAll { it =~ /^.+_odb\d+$/ }
        ?.sort() ?: []

    if (lineage == 'ALL') {
        // Return every lineage available in the path
        log.info "BUSCO [normaliseLineage]: ${sample_id} - '${lineage}' == returns ${all_lineages.size()} odb files"
        return all_lineages
    } else if (lineage =~ /^odb\d+$/) {
        // e.g. "odb10" or "odb12" – return all lineages with that version suffix
        def all_found_lineages = all_lineages.findAll { it.endsWith("_${lineage}") }
        log.info "BUSCO [normaliseLineage]: ${sample_id} - '${lineage}' == returns ${all_found_lineages.size()} odb files"

        if (!all_found_lineages) {
            error "No lineages found for odb version: ${lineage}\n-Check ${lineages_dir}"
        }

        return all_found_lineages
    } else {
        // Partial taxon name, e.g. "lepidoptera" – return all lineages with that prefix
        def taxon_lineages = all_lineages.findAll { it.startsWith("${lineage}_") }
        log.info "BUSCO [normaliseLineage]: ${sample_id} - '${lineage}' == returns ${taxon_lineages.size()} odb files"

        if (!taxon_lineages) {
            error "No lineages found for odb version: ${lineage}\n-Check ${lineages_dir}"
        }

        return taxon_lineages
    }
}
