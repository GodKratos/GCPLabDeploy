
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
    Import-DscResource -Module ComputerManagementDsc
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
        
        WaitForADDomain 'DomainWait'
        {
            DomainName  = $Domain
            Credential  = $DomainCredential
            WaitTimeout = 3600
        }

        Computer 'JoinDomain'
        {
            Name       = $env:COMPUTERNAME
            DomainName = $Domain
            Credential = $DomainCredential
            DependsOn  = '[WaitForADDomain]DomainWait'
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

# Create credential object for authenticating user
$password = $LocalPassword | ConvertTo-SecureString -AsPlainText -Force
$username = $LocalUsername
$cred = New-Object System.Management.Automation.PSCredential($username,$password)

# Create credential object for new domain user
$password = $DomainPassword | ConvertTo-SecureString -AsPlainText -Force
$username = "$($DomainUsername)@$($Domain)"
$domainCred = New-Object System.Management.Automation.PSCredential($username,$password)

# Create Dsc Configurations
LCMConfig
ConfigureServer_Config -Domain $Domain -LocalCredential $cred -SafeModePassword $cred -DomainCredential $domainCred -ConfigurationData $ConfigData

# Configure LCM
Set-DscLocalConfigurationManager -path .\LCMConfig -verbose -force

# Initiate Dsc Configuration
Start-DscConfiguration -path .\ConfigureServer_Config -verbose -force -wait
