terraform {
  backend "s3" {
    bucket         = "fullstack-template-tfstate-891377117245"
    key            = "fullstack-template/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}