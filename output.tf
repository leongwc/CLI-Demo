output "lb_dns_name" {
  description = "ELB FQDN"
  value       = aws_lb.external_elb.dns_name
}

output "webserver1" {
  description = "Webserver1 Public IP"
  value       = aws_instance.webserver1.public_ip
}

output "webserver2" {
  description = "Webserver2 Public IP"
  value       = aws_instance.webserver2.public_ip
}
