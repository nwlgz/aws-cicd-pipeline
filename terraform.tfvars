codestar_connector_credentials = "arn:aws:codestar-connections:eu-west-1:114437252108:connection/37f9908c-3a68-4a17-b6f3-14785db2ffdc"

pipelines = [
    {
        pipeline_name = "tf-repo-1"
        source_repo = "nwlgz/repo-1"
    },
    {
        pipeline_name = "tf-repo-2"
        source_repo = "nwlgz/repo-2"
    },

] 