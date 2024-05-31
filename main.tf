provider "aws" {
  region = "eu-north-1"
}

resource "aws_instance" "example" {
  # AMI - Amazon Machine Image
  #
  ami = "ami-0705384c0b33c194c"
  instance_type = "t3.micro"

  # To access the ID of the security group resource, you are going to need
  # to use a resource attribute reference, which uses the following syntax
  #   <PROVIDER>_<TYPE>.<NAME>.<ATTRIBUTE>
  # where PROVIDER is the name of the provider (e.g., aws), TYPE is the type
  # of resource (e.g., security_group), NAME is the name of that resource
  # (e.g., the security group is named "instance"), and ATTRIBUTE is either
  # one of the arguments of that resource (e.g., name) or one of the
  # attributes exported by the resource (you can find the list of available
  # attributes in the documentation for each resource). The security group
  # exports an attribute called 'id', so the expression to reference it will
  # look like this:
  #   aws_security_group.instance.id
  #
  vpc_security_group_ids = [aws_security_group.instance.id]

  # The '<<-EOF' and 'EOF' are Terraform's heredoc syntax, which allows you
  # to create multiline strings without having to insert '\n' characters
  # all over the place.
  #
  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World!" > index.html
    nohup busybox httpd -f -p ${var.server_port} &
    EOF

  # This parameter is set to 'true' so when you change the 'user_data'
  # parameter and run 'apply', Terraform will terminate the original
  # instance and launch a totally new one. Terraform's default behaviour
  # is to update the original instance in place, but since User Data runs
  # only on the very first boot, and your original instance already went
  # through  that boot process, you need to force the creation of a new
  # instance to ensure your new User Data script actually gets executed.
  #
  user_data_replace_on_change = true

  tags = {
    Name = "terraform-example"
  }
}

# By default, AWS does not allow any incoming or outgoing traffic from
# an EC2 Instance. To allow the EC2 Instance to receive traffic on port
# 8080, you need to create a security group.
#
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
