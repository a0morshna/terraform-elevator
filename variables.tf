variable "project_id" {
  description = "Google Cloud Platform (GCP) Project ID."
  type        = string
  default     = "sixth-zoo-337808"
}

variable "project_name" {
  description = "Google Cloud Platform (GCP) Project name."
  type        = string
  default     = "cicd-task"
}

variable "region" {
  description = "GCP region name."
  type        = string
  default     = "europe-central2"
}

variable "zone" {
  description = "GCP zone name."
  type        = string
  default     = "europe-central2-a"
}

/* 
variable "gcp_service_list" {
  description = "The list of apis necessary for the project"
  type        = list(string)
  default     = [
    "iam.googleapis.com", 
    "compute.googleapis.com"
  ]
} */

variable "name_test" {
  description = "Instance test name."
  type        = string
  default     = "jenkins-test"
}

variable "name_prod" {
  description = "Instance prod name."
  type        = string
  default     = "jenkins-prod"
}

variable "machine_type" {
  description = "GCP VM instance machine type."
  type        = string
  default     = "e2-standard-2"
}

variable "image" {
  description = "GCP VM instance image."
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-1804-lts"
}

variable "machine_type_autoscaler" {
  type        = string
  default     = "f1-micro"
}

variable "name_autoscaler" {
  type        = string
  default     = "autoscaler"
}

variable "region_autoscaler" {
  type        = string
  default     = "europe-central2"
}

variable "firewall_name" {
  type        = string
  default     = "allow-http"
}

variable "network_name" {
  type        = string
  default     = "default"
}

variable "protocol_name" {
  type        = string
  default     = "tcp"
}

variable "firewall_ports" {
  type    = list
  default = ["22","8080"]
}