resource "aws_lb" "alb" {
  name = var.name
  internal = false
  load_balancer_type = "application"
  subnets = var.subnet_ids
  # access_logs {
  #   bucket = "${aws_s3_bucket.ingress_access_logs_s3_bucket.id}"
  #   prefix = "access-logs-lb"
  #   enabled = true
  # }

  

  security_groups = var.security_group_ids

}