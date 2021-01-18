terraform {
  required_version = ">= 0.14"
}

provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

resource "aws_iam_user" "user" {
  force_destroy = var.force_destroy
  name = var.username
  path = var.path
  permissions_boundary = var.permissions_boundary
  tags = var.tags
}

resource "aws_iam_user_login_profile" "user_profile" {
  password_length = var.password_length
  password_reset_required = false
  pgp_key = var.pgp_key
  user = aws_iam_user.user.name
}

resource "aws_iam_user_group_membership" "groups" {
  groups = var.groups
  user = aws_iam_user.user.name
}

resource "aws_iam_access_key" "access_secrets" {
  pgp_key = aws_iam_user_login_profile.user_profile.pgp_key
  status = var.access_key_status
  user = aws_iam_user_group_membership.groups.user
}