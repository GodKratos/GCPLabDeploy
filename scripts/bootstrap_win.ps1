
param
(
    [string] $AdminUsername = "localadmin",
    [string] $AdminPassword = "L0calP@ssw0rd",
    [int] $winrmHttpsPort = 5986,
    [int] $winrmHttpPort = 5985,
    [string] $HostName = $env:COMPUTERNAME
)

# First, make sure WinRM can't be connected to
netsh advfirewall firewall delete rule name="Windows Remote Management (HTTP-In)"
netsh advfirewall firewall delete rule name="Windows Remote Management (HTTPS-In)"

# Set administrator password
net user $AdminUsername $AdminPassword /add
net localgroup administrators $AdminUsername /add
wmic useraccount where "name='$AdminUsername'" set PasswordExpires=FALSE

# Delete any existing WinRM listeners
winrm delete winrm/config/listener?Address=*+Transport=HTTP  2>$Null
winrm delete winrm/config/listener?Address=*+Transport=HTTPS 2>$Null

# Create a certificate to use with the HTTPS listener
$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName $HostName

# Create WinRM listeners
winrm create winrm/config/Listener?Address=*+Transport=HTTP "@{Hostname=`"$($HostName)`";Port=`"$($winrmHttpPort)`"}"
winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname=`"$($HostName)`";CertificateThumbprint=`"$($Cert.thumbprint)`";Port=`"$($winrmHttpsPort)`"}"
# Set WinRM options
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="0"}'
winrm set winrm/config '@{MaxTimeoutms="7200000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service '@{MaxConcurrentOperationsPerUser="12000"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/client/auth '@{Basic="true"}'

# Configure UAC to allow privilege elevation in remote shells
$Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
$Setting = 'LocalAccountTokenFilterPolicy'
Set-ItemProperty -Path $Key -Name $Setting -Value 1 -Force

# Stop and configure the WinRM Service
Stop-Service -Name WinRM
Set-Service -Name WinRM -StartupType Automatic

# Recreate the firewall rules for the ports specified
netsh advfirewall firewall add rule name="Windows Remote Management (HTTP-In)" dir=in action=allow protocol=TCP localport=$winrmHttpPort
netsh advfirewall firewall add rule name="Windows Remote Management (HTTPS-In)" dir=in action=allow protocol=TCP localport=$winrmHttpsPort

# Start the WinRM service
Start-Service -Name WinRM

# Install DSC modules required
Install-PackageProvider -Name NuGet -Force
Install-Module -Name ActiveDirectoryDsc -Force
Install-Module -Name PsDscResources -Force
