resource "google_compute_network" "network" {
  name                    = "${var.var_prefix}-${terraform.workspace}-vpc"
  auto_create_subnetworks = "false"
  #routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.var_prefix}-${terraform.workspace}-${var.var_region}-net"
  ip_cidr_range = "${var.var_network_subnet}"
  network       = "${google_compute_network.network.self_link}"
}

resource "google_compute_firewall" "allow-icmp" {
  name    = "${var.var_prefix}-${terraform.workspace}-fw-allow-icmp"
  network = "${google_compute_network.network.self_link}"
  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "allow-local" {
  name    = "${var.var_prefix}-${terraform.workspace}-fw-allow-local"
  network = "${google_compute_network.network.self_link}"
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  source_tags = ["${terraform.workspace}-net"]
}

resource "google_compute_firewall" "allow-http" {
  name    = "${var.var_prefix}-${terraform.workspace}-fw-allow-http"
  network = "${google_compute_network.network.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = ["http"]
}


resource "google_compute_firewall" "allow-ssh" {
  name    = "${var.var_prefix}-${terraform.workspace}-fw-allow-ssh"
  network = "${google_compute_network.network.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["ssh"]
}

resource "google_compute_firewall" "allow-https" {
  name    = "${var.var_prefix}-${terraform.workspace}-fw-allow-https"
  network = "${google_compute_network.network.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  target_tags = ["https"]
}

resource "google_compute_firewall" "allow-rdp" {
  name    = "${var.var_prefix}-${terraform.workspace}-fw-allow-rdp"
  network = "${google_compute_network.network.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  target_tags = ["rdp"]
}

resource "google_compute_firewall" "allow-winrm" {
  name    = "${var.var_prefix}-${terraform.workspace}-fw-allow-winrm"
  network = "${google_compute_network.network.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["${var.var_ports["winrmhttps"]}"] # HTTP disabled
    #ports    = ["${var.var_ports["winrmhttps"]}", "${var.var_ports["winrmhttp"]}"] 
  }

  target_tags = ["winrm"]
}
