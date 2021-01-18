variable "access_key" {
  type        = string
  default     = ""
  description = "This is the AWS access key. It must be provided, but it can also be sourced from the AWS_ACCESS_KEY_ID environment variable, or via a shared credentials file if profile is specified."
}

variable "access_key_status" {
  type        = string
  default     = "Active"
  description = "The access key status to apply. Defaults to Active."
}

variable "bucket" {
  type        = string
  default     = ""
  description = "The name of the bucket. If omitted, Terraform will assign a random, unique name."
}

variable "force_destroy" {
  default = false
  description = "Force destroying this user."
  type = bool
}

variable "groups" {
  default     = ""
  description = "The name of the group."
  type        = string
}

variable "password_length" {
  default = 20
  description = "The length of the generated password on resource creation. Only applies on resource creation."
}

variable "path" {
  default     = "/"
  description = "Path in which to create the group."
  type        = string
}

variable "pgp_key" {
  default = ""
  description = "Either a base-64 encoded PGP public key, or a keybase username in the form keybase:username. Only applies on resource creation."
  type = string
}

variable "policy_arn" {
  type        = string
  default     = ""
  description = "ARN of the IAM policy."
}

variable "region" {
  type        = string
  default     = ""
  description = "This is the AWS region. It must be provided, but it can also be sourced from the AWS_DEFAULT_REGION environment variables, or via a shared credentials file if profile is specified."
}

variable "permissions_boundary" {
  default = ""
  description = "The ARN of the policy that is used to set the permissions boundary for the user."
  type = string
}

variable "secret_key" {
  type        = string
  default     = ""
  description = "This is the AWS secret key. It must be provided, but it can also be sourced from the AWS_SECRET_ACCESS_KEY environment variable, or via a shared credentials file if profile is specified."
}

variable "tags" {
  default = {}
  description = "A mapping of tags to assign to the resource."
  type = map
}

variable "username" {
  type        = string
  default     = ""
  description = "The username."
}

