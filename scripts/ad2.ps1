
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
        WindowsFeature DHCP
        {
            Ensure = 'Present'
            Name   = 'DHCP'
        }
        WindowsFeature 'ADDS'
        {
            Name   = 'AD-Domain-Services'
            Ensure = 'Present'
        }
        WindowsFeature 'RSAT'
        {
            Name                 = 'RSAT-AD-Tools'
            Ensure               = 'Present'
            IncludeAllSubFeature = $true
        }

        WaitForADDomain 'DomainWait'
        {
            DomainName  = $Domain
            Credential  = $DomainCredential
            WaitTimeout = 3600
            DependsOn   = '[WindowsFeature]ADDS'
        }

        ADDomainController 'DCLab'
        {
            DomainName                    = $Domain
            Credential                    = $DomainCredential
            SafeModeAdministratorPassword = $SafeModePassword
            IsGlobalCatalog               = $true
            DependsOn                     = '[WaitForADDomain]DomainWait'
        }
    }
}

$ConfigData= @{
    AllNodes = @(
        @{
            # The name of the node we are describing
            NodeName = "localhost"
            PSDscAllowPlainTextPassword = $true
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
Start-DscConfiguration -path .\ConfigureServer_Config -wait -verbose -force
