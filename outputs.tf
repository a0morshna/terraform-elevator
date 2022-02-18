output "jenkins-test_public_ip" {
  description   = "Public IP address of the Jenkins-Test Server."
  value         = "${google_compute_instance.jenkins-test.network_interface.0.access_config.0.nat_ip}"
}

output "jenkins-prod_public_ip" {
  description   = "Public IP address of the Jenkins-Prod Server."
  value         = "${google_compute_instance.jenkins-prod.network_interface.0.access_config.0.nat_ip}"
}
