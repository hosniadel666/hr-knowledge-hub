terraform {
  backend "s3" {
    bucket         = "hr-knowledge-hub-tf-state-905418180379"
    key            = "hr-knowledge-hub/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "hr-knowledge-hub-tf-lock"
    encrypt        = true
  }
}
