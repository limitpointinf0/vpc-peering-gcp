// Configure the Google Cloud provider
provider "google" {
    credentials = file(var.creds_path)
    project     = var.project
    region      = var.region
}

resource "random_id" "instance_id" {
    byte_length = 8
}

//Create Subnets
resource "google_compute_subnetwork" "vpc_subnet_a" {
    name          = "a-subnet"
    ip_cidr_range = "10.0.0.0/24"
    region        = var.region
    network       = google_compute_network.vpc_network.id
}

//Create Networks
resource "google_compute_network" "vpc_network" {
    name = "a-network"
    auto_create_subnetworks = false
    routing_mode = "REGIONAL"
    mtu = 1500
}

// Add Firewall Rule
resource "google_compute_firewall" "vpc_firewall" {
    name    = "allow-ssh"
    network = google_compute_network.vpc_network.name

    allow {
        protocol = "icmp"
    }

    allow {
        protocol = "tcp"
        ports    = ["22"]
    }
}

// Add Peering
resource "google_compute_network_peering" "vpc_peering" {
  name         = "peer-skynet"
  network      = google_compute_network.vpc_network.id
  peer_network = var.project_b
}

// VM 1
resource "google_compute_instance" "vm_a" {
    name         = "vma-${random_id.instance_id.hex}"
    machine_type = var.size
    zone         = var.zone_ase

    boot_disk {
        initialize_params {
            image = var.image
        }
    }

    metadata = {
        ssh-keys = "chris:${file("~/.ssh/id_rsa.pub")}"
    }

    network_interface {
        network = google_compute_network.vpc_network.name
        subnetwork = google_compute_subnetwork.vpc_subnet_a.name
        access_config {}
    }
}

// External IP outputs
output "vma-ip" {
    value = google_compute_instance.vm_a.network_interface.0.access_config.0.nat_ip
}