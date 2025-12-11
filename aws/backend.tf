terraform {
  backend "s3" {
    bucket       = "cloud-resume-challenge-terraform-state-75jasd7"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
    # dynamodb_table = "terraform-locks"
  }
}

// Notes:
// - Ensure the S3 bucket exists and the executing AWS identity has read/write access.
//   It is recommended to have versioning enabled for state file history.
// - The `dynamodb_table` is optional but recommended for state locking.
//   Create it with a primary key named `LockID` (string).
// - Do NOT commit sensitive backend override files. Use environment variables
//   or `-backend-config` to override values when necessary.