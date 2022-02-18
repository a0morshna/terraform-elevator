resource "google_compute_firewall" "allow-http" {
    name         = var.firewall_name
    network      = var.network_name

    allow {
        protocol = var.protocol_name
        ports    = var.firewall_ports

    }
    source_ranges = ["0.0.0.0/0"]
}