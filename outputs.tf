output "aws_access_key_id" {
  description = "The access key ID."
  sensitive = true
  value = aws_iam_access_key.access_secrets.id
}

output "aws_secret_access_key" {
  description = "The secret access key."
  sensitive = true
  value = aws_iam_access_key.access_secrets.secret
}

output "encrypted_aws_secret_access_key" {
  description = "The encrypted secret, base64 encoded, if pgp_key was specified."
  value = aws_iam_access_key.access_secrets.encrypted_secret
}

output "pgp_encryption_key" {
  description = "The fingerprint of the PGP key used to encrypt the secret."
  sensitive = true
  value = aws_iam_access_key.access_secrets.key_fingerprint
}

output "ses_smtp_password_v4" {
  description = "The secret access key converted into an SES SMTP password by applying AWS's documented Sigv4 conversion algorithm."
  value = aws_iam_access_key.access_secrets.ses_smtp_password_v4
}

output "username" {
  description = "The IAM username."
  sensitive = true
  value = aws_iam_access_key.access_secrets.user
}
