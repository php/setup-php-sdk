param (
    [Parameter(Mandatory)] [String] $version
)

$ErrorActionPreference = "Stop"

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
    $releases = Invoke-WebRequest $url | ConvertFrom-Json
    $phpversion = $releases.$version.version
    if (-not $phpversion) {
        $baseurl = "https://downloads.php.net/~windows/qa"
        $url = "$baseurl/releases.json"
        $releases = Invoke-WebRequest $url | ConvertFrom-Json
        $phpversion = $releases.$version.version
        if (-not $phpversion) {
            throw "unknown version"
        }
    }
}

Write-Output "version=$phpversion" >> $Env:GITHUB_OUTPUT
Write-Output "baseurl=$baseurl" >> $Env:GITHUB_OUTPUT
