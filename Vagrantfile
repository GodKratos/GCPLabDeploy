
# -*- mode: ruby -*-
# vi: set ft=ruby :

$nodes_count = 3

if ENV['NODES'].to_i > 0 && ENV['NODES']
  $nodes_count = ENV['NODES'].to_i
end

Vagrant.configure('2') do |config|
  config.vm.box = "google/gce"

  (1..$nodes_count).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.provider :google do |google, override|
        google.google_project_id = "datacom-operations-two"
        google.google_json_key_location = "/Data/Terraform/datacom-operations-two-93d0cce91cba.json"
    
        # Make sure to set this to trigger the zone_config
        google.zone = "us-central1-c"
    
        override.ssh.username = "adminuser"
        override.ssh.private_key_path = "/Data/Terraform/adminuser_rsakey"
    
        google.zone_config "us-central1-c" do |zone1c|
          zone1c.name = "vagrant-linux-#{i}"
          zone1c.image_family = "centos-7"
          zone1c.machine_type = "g1-small"
          zone1c.zone = "us-central1-c"
          zone1c.metadata = {'custom' => 'metadata', 'testing' => 'foobarbaz'}
          zone1c.scopes = ['bigquery', 'monitoring', 'https://www.googleapis.com/auth/compute']
          zone1c.tags = ['web', 'app1']
        end
      end
    end
  end

  # config.vm.define :windows do |windows|
  #   windows.vm.communicator = "winrm"
  #   windows.winrm.username = "localadmin"
  #   windows.winrm.password = "Ttp2u33x0QnWyu"
  #   windows.winrm.port = 21002
  #   windows.winrm.transport = :ssl
  #   windows.winrm.retry_limit = 20
  #   windows.winrm.retry_delay = 30
  #   windows.winrm.ssl_peer_verification = false
  #   windows.vm.provider :google do |google|
  #     google.google_project_id = "datacom-operations-two"
  #     google.google_json_key_location = "/Data/Terraform/datacom-operations-two-93d0cce91cba.json"

  #     # Make sure to set this to trigger the zone_config
  #     google.zone = "us-central1-c"

  #     google.zone_config "us-central1-c" do |zone1c|
  #       zone1c.name = "vagrant-win"
  #       zone1c.image_family = "windows-2019"
  #       zone1c.machine_type = "g1-small"
  #       zone1c.zone = "us-central1-c"
  #       zone1c.disk_size = "50"
  #       zone1c.metadata = {'custom' => 'metadata', 'testing' => 'foobarbaz', 'windows-startup-script-cmd' => "PowerShell -NoProfile -ExecutionPolicy Bypass -Command \"Invoke-Command -ScriptBlock ([scriptblock]::Create(((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/GodKratos/GCPLabDeploy/master/scripts/bootstrap_win.ps1')))) -ArgumentList localadmin,Ttp2u33x0QnWyu,21002\""}
  #       zone1c.scopes = ['bigquery', 'monitoring', 'https://www.googleapis.com/auth/compute']
  #       zone1c.tags = ['web', 'app1']
  #     end
  #   end
  # end
end
