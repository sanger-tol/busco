//
// FUNCTION: get_value
//           Returns the value from the samplesheet or parameter,
//           or an empty list if neither is provided. This stops the pipeline
//           from stopping if no value is available.
//
def get_value(samplesheet_value, param_value) {
    if (samplesheet_value) {
        return samplesheet_value
    } else if (param_value) {
        return param_value
    } else {
        return []
    }
}
