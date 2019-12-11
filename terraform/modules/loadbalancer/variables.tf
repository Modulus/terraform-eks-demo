variable "name" {
    type = string
    default = ""
}

variable "subnet_ids" {
    type = list(string)
    default = []
}
  # access_logs {
  #   bucket = "${aws_s3_bucket.ingress_access_logs_s3_bucket.id}"
  #   prefix = "access-logs-lb"
  #   enabled = true
  # }

variable "security_group_ids" {
    type = list(string)
    default = []
}