variable "codestar_connector_credentials" {
    type = string
}

variable "pipelines" {
    type = list(object({
        pipeline_name = string
        source_repo = string
    }))
}