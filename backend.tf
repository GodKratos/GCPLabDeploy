# Define Terraform backend using a Google Cloud Storage bucket for storing the Terraform state
terraform {
  backend "gcs" {
    bucket = "terraform-state-bucket"
    prefix = "terraform-state/baseDeploy.tfstate"
  }
}
