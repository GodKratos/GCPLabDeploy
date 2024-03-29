
param
(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $Domain,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $LocalUsername,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $LocalPassword,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $DomainUsername,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $DomainPassword
)

[DSCLocalConfigurationManager()]
configuration LCMConfig
{
    Node localhost
    {
        Settings
        {
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyOnly'            
            RebootNodeIfNeeded = $true            
        }
    }
}

Configuration ConfigureServer_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Domain,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $LocalCredential,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SafeModePassword,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $DomainCredential
    )

    Import-DscResource -ModuleName PsDscResources
    Import-DscResource -ModuleName ActiveDirectoryDsc
    Import-DscResource -Module NetworkingDsc

    node 'localhost'
    {
        DnsServerAddress DnsServerAddress
        {
            Address        = '10.30.1.11','10.30.1.1'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
        }
        
        WindowsFeature DNS
        {
            Ensure = 'Present'
            Name   = 'DNS'
        }
        WindowsFeature DNSTools
        {
            Ensure = 'Present'
            Name   = 'RSAT-DNS-Server'
        }
        WindowsFeature DHCP
        {
            Ensure = 'Present'
            Name   = 'DHCP'
        }
        WindowsFeature DHCPTools
        {
            Ensure = 'Present'
            Name   = 'RSAT-DHCP'
        }
        WindowsFeature 'ADDS'
        {
            Name   = 'AD-Domain-Services'
            Ensure = 'Present'
        }
        WindowsFeature 'ADDSTools'
        {
            Name                 = 'RSAT-AD-Tools'
            Ensure               = 'Present'
            IncludeAllSubFeature = $true
        }

        ADDomain 'DCLab'
        {
            DomainName                    = $Domain
            Credential                    = $LocalCredential
            SafemodeAdministratorPassword = $SafeModePassword
            ForestMode                    = 'WinThreshold'
            DependsOn                     = '[WindowsFeature]ADDS'
        }

        WaitForADDomain 'DomainWait'
        {
            DomainName  = $Domain
            WaitTimeout = 1800
            DependsOn   = '[ADDomain]DCLab'
        } 

        ADUser 'DCAdmin'
        {
            Ensure                = 'Present'
            UserName              = $DomainCredential.UserName
            Password              = $DomainCredential
            DomainName            = $Domain
            UserPrincipalName     = "$($DomainCredential.UserName)@$($Domain)"
            PasswordNeverResets   = $true
            PasswordNeverExpires  = $true
            ChangePasswordAtLogon = $false
            DependsOn             = '[WaitForADDomain]DomainWait'
        }

        ADGroup 'DCAdminGroup'
        {
            GroupName        = 'Domain Admins'
            MembersToInclude = $DomainCredential.UserName
            DependsOn        = '[ADUser]DCAdmin'
        }

        ADGroup 'DCEnterpriseGroup'
        {
            GroupName        = 'Enterprise Admins'
            MembersToInclude = $DomainCredential.UserName
            DependsOn        = '[ADUser]DCAdmin'
        }
    }
}

$ConfigData= @{
    AllNodes = @(
        @{
            # The name of the node we are describing
            NodeName = "localhost"
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true
        };
    );
}

# Set local Administrator password which becomes domain administrator account
net user Administrator $LocalPassword

# Create credential object for authenticating user
$password = $LocalPassword | ConvertTo-SecureString -AsPlainText -Force
$username = $LocalUsername
$cred = New-Object System.Management.Automation.PSCredential($username,$password)

# Create credential object for new domain user
$password = $DomainPassword | ConvertTo-SecureString -AsPlainText -Force
$username = $DomainUsername
$domainCred = New-Object System.Management.Automation.PSCredential($username,$password)

# Create Dsc Configurations
LCMConfig
ConfigureServer_Config -Domain $Domain -LocalCredential $cred -SafeModePassword $cred -DomainCredential $domainCred -ConfigurationData $ConfigData

# Configure LCM
Set-DscLocalConfigurationManager -path .\LCMConfig -verbose -force

# Initiate Dsc Configuration
Start-DscConfiguration -path .\ConfigureServer_Config -verbose -force -wait
