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

resource "aws_codebuild_project" "tf-apply" {
    name          = "tf-cicd-apply"
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

    name = "tf-cicd"
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
            output_artifacts = ["tf-code"]
            configuration = {
                FullRepositoryId = "nwlgz/aws-cicd-pipeline"
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
            input_artifacts = ["tf-code"]
            configuration = {
                ProjectName = "tf-cicd-apply"
            }
        }
    }

}