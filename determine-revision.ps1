param (
    [Parameter(Mandatory)] [String] $version
)

$ErrorActionPreference = "Stop"

# Ensure TLS 1.2/1.3 on older .NET / Windows PowerShell
[Net.ServicePointManager]::SecurityProtocol = `
    [Net.SecurityProtocolType]::Tls12 -bor `
    [Net.SecurityProtocolType]::Tls13

function Get-ReleasesJson([string] $url) {
    return Invoke-RestMethod -Uri $url -UseBasicParsing
}

$baseurl = "https://downloads.php.net/~windows/releases/archives"
$releases = @{
    "7.0" = "7.0.33"
    "7.1" = "7.1.33"
    "7.2" = "7.2.34"
    "7.3" = "7.3.33"
    "7.4" = "7.4.33"
    "8.0" = "8.0.30"
}

$phpversion = $releases.$version
if (-not $phpversion) {
    $baseurl = "https://downloads.php.net/~windows/releases"
    $url = "$baseurl/releases.json"

    $releases = Get-ReleasesJson $url
    $phpversion = $releases.$version.version

    if (-not $phpversion) {
        $baseurl = "https://downloads.php.net/~windows/qa"
        $url = "$baseurl/releases.json"

        $releases = Get-ReleasesJson $url
        $phpversion = $releases.$version.version

        if (-not $phpversion) {
            throw "unknown version"
        }
    }
}

Write-Output "version=$phpversion" >> $Env:GITHUB_OUTPUT
Write-Output "baseurl=$baseurl" >> $Env:GITHUB_OUTPUT
