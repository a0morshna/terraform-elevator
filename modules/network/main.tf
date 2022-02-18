resource "google_compute_network" "autoscaler-network" {
    project                 = var.project_id
    name                    = var.network_name
    auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "autoscaler-subnet" {
    name          = var.subnet_name
    project       = var.project_id
    ip_cidr_range = "10.0.1.0/24"
    region        = var.region
    network       = google_compute_network.autoscaler-network.self_link
    depends_on    = [google_compute_network.autoscaler-network]
}
