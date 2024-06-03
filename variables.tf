# To use the value from an input variable in your Terraform code, you can
# use an expression called a variable reference, which has the following
# syntax:
#   var.<VARIABLE_NAME>
#
# To use a reference inside of a string literal, you need to use
# an expression called interpolation, which has the following syntax:
#   "${...}"
#
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type = number
  default = 8080
}

output "alb_dns_name" {
  value       = aws_lb.example.dns_name
  description = "The domain name of the load balancer"
}
