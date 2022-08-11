output "server_public" {
  value = aws_eip.eip.associate_with_private_ip

}

output "server_private_ip" {
  value = aws_instance.web_server.private_ip

}

output "server_id" {
  value = aws_instance.web_server.id

}