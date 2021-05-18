terraform {
  backend "s3" 
    bucket               = "my-vibrant-and-nifty-app-infra"
    key                  = "tf-state.json"
    region               = "us-west-2"
    workspace_key_prefix = "environment"}
}


