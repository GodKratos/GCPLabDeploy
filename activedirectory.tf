# Create a Google Compute instance
resource "google_compute_instance" "ad_server" {
  for_each = {
    ad1 = "${var.var_network_ip["ad1"]}"
    ad2 = "${var.var_network_ip["ad2"]}"
  }

  name         = "${var.var_prefix}-${terraform.workspace}-${each.key}"
  hostname     = "${each.key}.${var.ad_server_domain}"
  machine_type = "n1-standard-1"

  boot_disk {
    initialize_params {
      image = "windows-2019"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet.self_link}"
    network_ip = "${each.value}"

    access_config {
      network_tier = "STANDARD"
    }
  }

  tags   = ["rdp", "winrm", "${terraform.workspace}-net"]
  labels = { env = "${terraform.workspace}", role = "activedirectory", shutdown = "enabled" }

  metadata = {
    windows-startup-script-cmd = "PowerShell -NoProfile -ExecutionPolicy Bypass -Command \"Invoke-Command -ScriptBlock ([scriptblock]::Create(((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/GodKratos/GCPLabDeploy/master/scripts/bootstrap_win.ps1')))) -ArgumentList ${var.local_admin_user},${var.local_admin_password},${var.var_ports["winrmhttps"]}\""
  }

  # validate build has completed and server is up before continuing
  provisioner "remote-exec" {
    connection {
      type     = "winrm"
      port     = "${var.var_ports["winrmhttps"]}"
      host     = "${self.network_interface.0.access_config.0.nat_ip}"
      use_ntlm = "true"
      user     = "${var.local_admin_user}"
      password = "${var.local_admin_password}"
      https    = "true"
      insecure = "true"
      timeout  = "10m"
    }

    inline = [
      # Run a powershell script based on the server name ${each.key}
      "PowerShell -NoProfile -ExecutionPolicy Bypass -Command \"Invoke-Command -ScriptBlock ([scriptblock]::Create(((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/GodKratos/GCPLabDeploy/master/scripts/${each.key}.ps1')))) -ArgumentList ${var.ad_server_domain},${var.local_admin_user},${var.local_admin_password},${var.ad_server_user},${var.ad_server_password}\""
    ]

    # continue if winrm fails to connect
    on_failure = "continue"
  }
}

output "adserver_nat_ip" {
  value = {
    for instance in google_compute_instance.ad_server :
    instance.name => instance.network_interface.0.access_config.0.nat_ip
  }
}
