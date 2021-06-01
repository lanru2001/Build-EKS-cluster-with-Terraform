terraform {
  required_version = ">= 0.12"
}

# ----------------------------------------------------------------------------------------------------------------------
# Module Standard Variables
# ----------------------------------------------------------------------------------------------------------------------

variable "aws_region" {
  type        = string
  default     = ""
  description = "The AWS region to deploy module into"
}

variable "create" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources"
}

variable "namespace" {
  type        = string
  default     = ""
  description = "Namespace, which could be your organization abbreviation, client name, etc. (e.g. Gravicore 'grv', HashiCorp 'hc')"
}

variable "environment" {
  type        = string
  default     = ""
  description = "The isolated environment the module is associated with (e.g. Shared Services `shared`, Application `app`)"
}

variable "stage" {
  type        = string
  default     = ""
  description = "The development stage (i.e. `dev`, `stg`, `prd`)"
}

variable "account_id" {
  type        = string
  default     = ""
  description = "The AWS Account ID that contains the calling entity"
}

#variable "tags" {
#  type        = map(string)
#  default     = ""
#  description = "Additional map of tags (e.g. business_unit, cost_center)"
#}

variable "desc_prefix" {
  type        = string
  default     = ""
  description = "The prefix to add to any descriptions attached to resources"
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `namespace`, `environment`, `stage`, `name`"
}

variable "s3_bucket_versioning" {
  type        = bool
  description = "S3 bucket versioning enabled"
  default     = true
}

variable "sse_algorithm" {
  type        = string
  default     = "AES256"
  description = "The server-side encryption algorithm to use. Valid values are `AES256` and `aws:kms`"
}

variable "kms_master_key_arn" {
  type        = string
  default     = ""
  description = "The AWS KMS master key ARN used for the `SSE-KMS` encryption. This can only be used when you set the value of `sse_algorithm` as `aws:kms`. The default aws/s3 AWS KMS master key is used if this element is absent while the `sse_algorithm` is `aws:kms`"
}

variable "name" {
  type        = string
  default     = ""
  description = "The name of the module"
}

variable "vpc_cidr" {
  type = string
  default = ""
}

variable "vpc_id" {
  type = string
  default = ""
}

variable "ec2_count" {
  type = number 
  default = 1
}

variable "azs" {
  type = list(string)
  default = [ "" ]
}

variable "public_subnets_cidr" {
  type = list(string)
  default =  [ "" ]
}

variable "private_subnets_cidr" {
   type = list(string)
   default =  [ "" ]
}

variable "cloudwatch_log_group_name" {
  description = "CloudWatch log group name required to enabled logDriver in container definitions for ecs task."
  type        = string
  default     = ""
}

variable "cloudwatch_log_stream" {
  description = "CloudWatch log stream name"
  type        = string
  default     = ""
}

variable "app_image" {
  description = "Docker image of the application"
  default     = ""
}

variable "fargate_cpu" {
  type        = number 
  description = "The cpu for the fargate container"
  default     = 64
}

variable "fargate_memory" {
  type        = number 
  description = "The memory for the fargate container"
  default     = 128
}

variable "container_port" {
  type        = number 
  description = "container port for the application"
  default     = 3000
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `namespace`, `environment`, `stage`, `name`"
}

variable "bucket_name" {
  description = "Number of ALB log bucket"
  default     = ""
}

variable "cluster_name" {
  type        = string
  default     = ""
  description = "The name of the ecs cluster"
}

variable "enabled" {
  type        = bool
  description = "Whether to create the resources. Set to `false` to prevent the module from creating any resources"
  default     = true
}

variable "name_prefix" {
  description = "A prefix used for naming resources."
  type        = string
}

variable "task_container_command" {
  description = "The command that is passed to the container."
  default     = []
  type        = list(string)
}

variable "task_container_working_directory" {
  description = "The working directory to run commands inside the container."
  default     = ""
  type        = string
}

variable "placement_constraints" {
  type        = list
  description = "(Optional) A set of placement constraints rules that are taken into consideration during task placement. Maximum number of placement_constraints is 10. This is a list of maps, where each map should contain \"type\" and \"expression\""
  default     = []
}

variable "proxy_configuration" {
  type        = list
  description = "(Optional) The proxy configuration details for the App Mesh proxy. This is a list of maps, where each map should contain \"container_name\", \"properties\" and \"type\""
  default     = []
}

variable "volume" {
  description = "(Optional) A set of volume blocks that containers in your task may use. This is a list of maps, where each map should contain \"name\", \"host_path\", \"docker_volume_configuration\" and \"efs_volume_configuration\". Full set of options can be found at https://www.terraform.io/docs/providers/aws/r/ecs_task_definition.html"
  default     = []
}

variable "task_start_timeout" {
  type        = number
  description = "Time duration (in seconds) to wait before giving up on resolving dependencies for a container. If this parameter is not specified, the default value of 3 minutes is used (fargate)."
  default     = null
}

variable "task_stop_timeout" {
  type        = number
  description = "Time duration (in seconds) to wait before the container is forcefully killed if it doesn't exit normally on its own. The max stop timeout value is 120 seconds and if the parameter is not specified, the default value of 30 seconds is used."
  default     = null
}

variable "task_mount_points" {
  description = "The mount points for data volumes in your container. Each object inside the list requires \"sourceVolume\", \"containerPath\" and \"readOnly\". For more information see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html "
  type        = list(object({ sourceVolume = string, containerPath = string, readOnly = bool }))
  default     = null
}

variable "prevent_destroy" {
  type        = bool
  description = "S3 bucket lifecycle prevent destroy"
  default     = true
}

variable "bucket_prefix" {
  type        = string
  description = "S3 bucket prefix"
  default     = "db-treat"
}

variable "s3_bucket_versioning" {
  type        = bool
  description = "S3 bucket versioning enabled?"
  default     = true
}

variable "environment" {
  type        = string
  description = "The isolated environment the module is associated with (e.g. Shared Services `shared`, Application `app`)"
  default     = ""
}

variable "namespace" {
  type        = string
  description = "Namespace, which could be your organization abbreviation, client name, etc. (e.g. uclib)"
  default     = ""
}

variable "stage" {
  type        = string
  default     = ""
  description = "The development stage (i.e. `dev`, `stg`, `prd`)"
}

variable "health_check_path" {
  type        = string
  description = "Path to check if the service is healthy , e.g \"/status\""
  default     = "/health"
}

variable "ami_id" {
  type        = string
  default     = ""
  description = "The Amazon machine image to use "
}

variable "PATH_TO_PRIVATE_KEY" {
  type    = string
  default = ""
}

variable "PATH_TO_PUBLIC_KEY" {
  type    = string
  default = ""
}

variable "instance_type" {
  type    = string
  default = ""
}

locals {
 
  environment_prefix = join(var.delimiter, compact([var.namespace, var.environment]))
  stage_prefix       = join(var.delimiter, compact([local.environment_prefix, var.stage]))
  module_prefix      = join(var.delimiter, compact([local.stage_prefix, var.name]))
  #tags              = merge( var.namespace ,var.environment ,var.stage)
}
