provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
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
  template = file("/home/omors/Documents/-study/gcp-terraform-cicd/scripts/startup-script-test.sh")
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
    network = var.network_name

    access_config {
      // Ephemeral IP
    }
    
  }
}


data "template_file" "script-prod" {
  template = file("/home/omors/Documents/-study/gcp-terraform-cicd/scripts/startup-script-prod.sh")
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

  metadata_startup_script = data.template_file.script-prod.rendered

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network = var.network_name

    access_config {
      // Ephemeral IP
    }
   
  }
}


module "firewall-rule"{
  source  = "../gcp-terraform-cicd/modules/firewall-rule"
}