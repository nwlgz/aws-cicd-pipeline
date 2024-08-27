# resource "aws_codebuild_project" "tf-plan" {
#   name          = "tf-cicd-plan2"
#   description   = "Plan stage for terraform"
#   service_role  = aws_iam_role.tf-codebuild-role.arn

#   artifacts {
#     type = "CODEPIPELINE"
#   }

#   environment {
#     compute_type                = "BUILD_GENERAL1_SMALL"
#     image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
#     type                        = "LINUX_CONTAINER"
#     image_pull_credentials_type = "CODEBUILD"
#     # image_pull_credentials_type = "SERVICE_ROLE"
#     # registry_credential{
#     #     credential = var.dockerhub_credentials
#     #     credential_provider = "SECRETS_MANAGER"
#     # }
#  }
#  source {
#      type   = "CODEPIPELINE"
#      buildspec = file("buildspec/plan-buildspec.yml")
#  }
# }

output "pipelines" {
    value = var.pipelines
}

locals {
  list_pipelines = { for p in var.pipelines : p.pipeline_name => p }
}

output "list_pipelines" {
    value = local.list_pipelines
}

resource "aws_codebuild_project" "tf-apply" {
    for_each = local.list_pipelines
    name          = "tf-cicd-apply-${each.key}"
    description   = "Apply stage for terraform"
    service_role  = aws_iam_role.tf-codebuild-role.arn

    artifacts {
        type = "CODEPIPELINE"
    }

    environment {
        compute_type                = "BUILD_GENERAL1_SMALL"
        image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
        type                        = "LINUX_CONTAINER"
        image_pull_credentials_type = "CODEBUILD"
    }
    source {
        type   = "CODEPIPELINE"
        buildspec = file("buildspec/buildspec.yaml")
    }
}


resource "aws_codepipeline" "cicd_pipeline" {
    for_each = local.list_pipelines
    name = "tf-cicd-${each.key}"
    role_arn = aws_iam_role.tf-codepipeline-role.arn

    artifact_store {
        type="S3"
        location = aws_s3_bucket.codepipeline_artifacts.id
    }

    stage {
        name = "Source"
        action{
            name = "Source"
            category = "Source"
            owner = "AWS"
            provider = "CodeStarSourceConnection"
            version = "1"
            output_artifacts = ["tf-code-${each.key}"]
            configuration = {
                #FullRepositoryId = "nwlgz/aws-cicd-pipeline"
                FullRepositoryId = "nwlgz/${each.value.source_repo}"
                BranchName   = "master"
                ConnectionArn = var.codestar_connector_credentials
                OutputArtifactFormat = "CODE_ZIP"
            }
        }
    }

    # stage {
    #     name ="Plan"
    #     action{
    #         name = "Build"
    #         category = "Build"
    #         provider = "CodeBuild"
    #         version = "1"
    #         owner = "AWS"
    #         input_artifacts = ["tf-code"]
    #         configuration = {
    #             ProjectName = "tf-cicd-plan"
    #         }
    #     }
    # }

    stage {
        name ="Deploy"
        action{
            name = "Deploy"
            category = "Build"
            provider = "CodeBuild"
            version = "1"
            owner = "AWS"
            input_artifacts = ["tf-code-${each.key}"]
            configuration = {
                ProjectName = "tf-cicd-apply-${each.key}"
            }
        }
    }

}