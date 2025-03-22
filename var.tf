variable "region" {
  default = "us-west-2"
}

variable "desired_count" {
  default = 2
}

variable "lounch_type" {
  default = "FARGATE"
}

variable "acm_certificate_arn" {
  default = "arn:aws:acm:us-west-2:582004017850:certificate/56cd5764-29cc-4829-871c-75e0de2ead3b"
}