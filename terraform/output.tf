output "manager_ip" {
  value = "${google_compute_instance_from_template.kube1-manager.network_interface.0.access_config.0.nat_ip}"
}

output "manager_private_ip" {
  value = google_compute_instance_from_template.kube1-manager.network_interface.0.network_ip
}

output "worker_ip" {
  value = "${google_compute_instance_from_template.kube1-worker.network_interface.0.access_config.0.nat_ip}"
}

output "worker_private_ip" {
  value = google_compute_instance_from_template.kube1-worker.network_interface.0.network_ip
}
