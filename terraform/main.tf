provider "google" {
  project = "${var.project_name}"
  region  = "${var.region}"
  zone = "asia-southeast1-a"
}

resource "google_compute_network" "vpc_network" {
  name                    = "kube-vpc-network"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
  mtu                     = 1460
}

resource "google_compute_firewall" "allow-internal" {
  name    = "vpc-fw-allow-internal"
  network = "${google_compute_network.vpc_network.name}"
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  source_ranges = [
    "${var.kube1_subnet}",
    "${var.kube2_subnet}"
  ]
}

resource "google_compute_firewall" "allow-ssh-http" {
  name    = "vpc-fw-allow-ssh-http"
  network = "${google_compute_network.vpc_network.name}"
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
    allow {
    protocol = "tcp"
    ports    = ["443"]
  }
    allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  }

resource "google_compute_firewall" "callico-ipip" {
  name    = "vpc-fw-allow-ipip"
  network = "${google_compute_network.vpc_network.name}"
  allow {
    protocol = "ipip"
  }
  }

resource "google_compute_subnetwork" "public-subnetwork-1" {
name = "kube-subnetwork-1"
ip_cidr_range = "${var.kube1_subnet}"
network = google_compute_network.vpc_network.name
}

resource "google_compute_subnetwork" "public-subnetwork-2" {
name = "kube-subnetwork-2"
ip_cidr_range = "${var.kube2_subnet}"
network = google_compute_network.vpc_network.name
}


resource "google_compute_instance_template" "kube-node_template" {
  name        = "kube-node-template"
  description = "This template is used to create kubernetes node instances."

  tags = ["kubernetes"]

  labels = {
    environment = "testing"
  }

  instance_description = "instance created for kubernetes nodes for consul mesh testing"
  machine_type         = "e2-medium"
  can_ip_forward       = true
  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create a new boot disk from an image
  disk {
    source_image      = "ubuntu-1804-bionic-v20210720"
    auto_delete       = true
    boot              = true
    disk_size_gb        = 10
    disk_type         = "pd-balanced"
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.public-subnetwork-1.name
  }
  metadata = {
    ssh-keys = "${var.ssh_user}:${file("${var.ssh_public_key_path}")}"
  }
}

resource "google_compute_address" "static1" {
  name = "kube1-manager-ip"
  address_type = "EXTERNAL"
}

resource "google_compute_address" "static2" {
  name = "kube2-manager-ip"
  address_type = "EXTERNAL"
}

resource "google_compute_address" "static3" {
  name = "kube-worker-ip"
  address_type = "EXTERNAL"
}

resource "google_compute_instance_from_template" "kube1-manager" {
  name = "kube1-manager"

  source_instance_template = google_compute_instance_template.kube-node_template.id

  // Override fields from instance template
  labels = {
    cluster = "kube1",
    node = "manager"
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public-subnetwork-1.name
    access_config {
      nat_ip = google_compute_address.static1.address
    }

  }
}

resource "google_compute_instance_from_template" "kube1-worker" {
  name = "kube1-worker"

  source_instance_template = google_compute_instance_template.kube-node_template.id

  // Override fields from instance template
  labels = {
    cluster = "kube1"
    node = "worker"
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public-subnetwork-1.name
    access_config {
      nat_ip = google_compute_address.static3.address
    }

  }
}

 resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tmpl",
    {
     manager_ip = google_compute_instance_from_template.kube1-manager.network_interface.0.access_config.0.nat_ip,
     worker_ip = google_compute_instance_from_template.kube1-worker.network_interface.0.access_config.0.nat_ip
     ssh_private_key = "${var.ssh_private_key_path}"
     ssh_user = "${var.ssh_user}"
    }
  )
  filename = "../ansible/k8s-cluster1-inventory"
}