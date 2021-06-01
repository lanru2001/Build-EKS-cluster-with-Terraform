terraform {
  backend "s3" {
    bucket               = "k8s-eks-bucket"
    key                  = "tf-state.json"
    region               = "us-east-2"
    
  }
}

