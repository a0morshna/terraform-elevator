resource "google_compute_firewall" "allow-http" {
    name       = var.firewall_name
    network    = "default"

    allow {
        protocol = var.protocol_name
        ports    = ["8080","22"]

    }
    source_ranges = ["0.0.0.0/0"]
}