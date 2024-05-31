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

# In addition to input variables, Terraform also allows you to define
# output variables. For example, instead of having to manually poke
# around the EC2 console to find the IP address of your server, you
# can provide the IP address as an output variable.
# You can also use the `terraform output' command to list all outputs
# without applying any changes. You can run `terraform output <OUTPUT_NAME>
# to see the value of a specific output called <OUTPUT_NAME>.
#
output "public_ip" {
  value = aws_instance.example.public_ip
  description = "The public IP address of the web server"
}
