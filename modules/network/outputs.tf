output "network_name"{
  value = google_compute_network.autoscaler-network.name 
}

output "subnetwork_name" {
  value = google_compute_subnetwork.autoscaler-subnet.name
}
