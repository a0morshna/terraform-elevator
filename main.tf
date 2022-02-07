provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}


provider "google-beta" {
  region      = var.region
  zone        = var.zone
}

module "firewall-rule"{
  source  = "./modules/firewall-rule"
}


module "network"{
  source  = "./modules/network"
  project_id   = var.project_id
  network_name = "${var.name_autoscaler}-network"
  subnet_name  = "${var.name_autoscaler}-subnet"
  region       = var.region_autoscaler
}


/* resource "google_project_service" "gcp_services" {

  project   = var.project_id
  service   = "compute.googleapis.com"

  timeouts {
    create = "30m"
    update = "40m"
  }
} */


resource "random_password" "password" {
  length  = 12
  special = false
}


resource "random_id" "login"{
  byte_length = 6
}


data "template_file" "script-test" {
  template = file("./scripts/startup-script-test.sh")
  vars = {
    login             = random_id.login.id,
    password          = random_password.password.result
  }
}


resource "google_compute_instance" "jenkins-test" {
  zone         = var.zone
  name         = var.name_test
  machine_type = var.machine_type

  metadata_startup_script = data.template_file.script-test.rendered

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    subnetwork = module.network.subnetwork_name

    access_config {
      // Ephemeral IP
    }
  }
  depends_on = [module.network]
}


data "template_file" "script-prod" {
  template = file("./scripts/startup-script-prod.sh")
  vars = {
    login                   = random_id.login.id,
    password                = random_password.password.result
    jenkins-test_public_ip  = google_compute_instance.jenkins-test.network_interface.0.access_config.0.nat_ip
  }
}


resource "google_compute_instance" "jenkins-prod" {
  zone         = var.zone
  name         = var.name_prod
  machine_type = var.machine_type
  tags         = ["prod"]
  metadata_startup_script = data.template_file.script-prod.rendered

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    subnetwork = module.network.subnetwork_name
    access_config {}
  }

  depends_on = [module.network]
}


resource "google_compute_autoscaler" "autoscaler" {
  name   = var.name_autoscaler
  zone   = var.zone
  target = google_compute_instance_group_manager.autoscaler-igm.id

  autoscaling_policy {
    max_replicas    = 3
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
  depends_on = [module.network]
}

resource "google_compute_instance_template" "autoscaler-instance" {
  project        = var.project_id
  name           = "${var.name_autoscaler}-instance"
  machine_type   = var.machine_type_autoscaler
  region         = var.region_autoscaler
  can_ip_forward = false

  tags = ["prod"]

  disk {
    source_image = var.image
  }
  
  network_interface {
    subnetwork = module.network.subnetwork_name
    access_config {}
  }
  depends_on = [module.network]
}

resource "google_compute_instance_group_manager" "autoscaler-igm" {
  project            = var.project_id
  name               = "${var.name_autoscaler}-igm"
  base_instance_name = var.name_autoscaler

  version {
    instance_template = google_compute_instance_template.autoscaler-instance.id
    name              = "primary"
  }
  zone = var.zone
}
