terraform{
    backend "s3" {
        bucket = "lz-state-114437252108-pipeline"
        encrypt = true
        key = "tf-state/terraform.tfstate"
        region = "eu-west-1"
    }
}

provider "aws" {
    region = "eu-west-1"
}