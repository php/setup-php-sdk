param (
    [Parameter(Mandatory)] [String] $version,
    [Parameter(Mandatory)] [String] $revision,
    [Parameter(Mandatory)] [String] $baseurl,
    [Parameter(Mandatory)] [String] $arch,
    [Parameter(Mandatory)] [String] $ts,
    [Parameter(Mandatory)] [AllowEmptyCollection()] [Array] $deps
)

$ErrorActionPreference = "Stop"

$versions = @{
    "7.0" = "vc14"
    "7.1" = "vc14"
    "7.2" = "vc15"
    "7.3" = "vc15"
    "7.4" = "vc15"
    "8.0" = "vs16"
    "8.1" = "vs16"
    "8.2" = "vs16"
    "8.3" = "vs16"
    "8.4" = "vs17"
}
$vs = $versions.$version
if (-not $vs) {
    throw "unsupported version"
}

$toolsets = @{
    "vc14" = "14.0"
}
$dir = vswhere -latest -find "VC\Tools\MSVC"
foreach ($toolset in (Get-ChildItem $dir)) {
    $tsv = "$toolset".split(".")
    if ((14 -eq $tsv[0]) -and (9 -ge $tsv[1])) {
        $toolsets."vc14" = $toolset
    } elseif ((14 -eq $tsv[0]) -and (19 -ge $tsv[1])) {
        $toolsets."vc15" = $toolset
    } elseif ((14 -eq $tsv[0]) -and (29 -ge $tsv[1])) {
        $toolsets."vs16" = $toolset
    } elseif (14 -eq $tsv[0]) {
        $toolsets."vs17" = $toolset
    }
}
$toolset = $toolsets.$vs
if (-not $toolset) {
    throw "no suitable toolset available on this runner"
}

if (-not (Test-Path "php-sdk")) {
    Write-Output "Install PHP SDK ..."

    $temp = New-TemporaryFile | Rename-Item -NewName {$_.Name + ".zip"} -PassThru
    $url = "https://github.com/php/php-sdk-binary-tools/releases/download/php-sdk-2.3.0/php-sdk-binary-tools-php-sdk-2.3.0.zip"
    Invoke-WebRequest $url -OutFile $temp
    Expand-Archive $temp -DestinationPath "."
    Rename-Item "php-sdk-binary-tools-php-sdk-2.3.0" "php-sdk"
}

$tspart = if ($ts -eq "nts") {"nts-Win32"} else {"Win32"}

if (-not (Test-path "php-bin")) {
    Write-Output "Install PHP $revision ..."

    $temp = New-TemporaryFile | Rename-Item -NewName {$_.Name + ".zip"} -PassThru
    $fname = "php-$revision-$tspart-$vs-$arch.zip"
    $url = "$baseurl/$fname"
    Write-Output "Downloading $url ..."
    Invoke-WebRequest $url -OutFile $temp
    Expand-Archive $temp "php-bin"
}

if (-not (Test-Path "php-dev")) {
    Write-Output "Install development pack ..."

    $temp = New-TemporaryFile | Rename-Item -NewName {$_.Name + ".zip"} -PassThru
    $fname = "php-devel-pack-$revision-$tspart-$vs-$arch.zip"
    $url = "$baseurl/$fname"
    Write-Output "Downloading $url ..."
    Invoke-WebRequest $url -OutFile $temp
    Expand-Archive $temp "."
    Rename-Item "php-$revision-devel-$vs-$arch" "php-dev"
}

if ($deps.Count -gt 0) {
    $baseurl = "https://downloads.php.net/~windows/php-sdk/deps"
    $series = Invoke-WebRequest "$baseurl/series/packages-$version-$vs-$arch-staging.txt"
    $remainder = @()
    $installed = $false
    foreach ($dep in $deps) {
        foreach ($line in ($series.Content -Split "[\r\n]+")) {
            if ($line -match "^$dep") {
                Write-Output "Install $line ..."
                $temp = New-TemporaryFile | Rename-Item -NewName {$_.Name + ".zip"} -PassThru
                $url = "$baseurl/$vs/$arch/$line"
                Write-Output "Downloading $url ..."
                Invoke-WebRequest $url -OutFile $temp
                Expand-Archive $temp "../deps"
                $installed = $true
                break
            }
        }
        if (-not $installed) {
            $remainder += $dep
        }
    }
    if ($remainder.Count -gt 0) {
        foreach ($dep in $remainder) {
            Write-Output "$dep not available"
            exit 1
        }
    }
}

Add-Content $Env:GITHUB_PATH "$pwd\php-sdk\bin"
Add-Content $Env:GITHUB_PATH "$pwd\php-sdk\msys2\usr\bin"
Add-Content $Env:GITHUB_PATH "$pwd\php-bin"
Add-Content $Env:GITHUB_PATH "$pwd\php-dev"

Write-Output "toolset=$toolset" >> $Env:GITHUB_OUTPUT
Write-Output "prefix=$pwd\php-bin" >> $Env:GITHUB_OUTPUT
Write-Output "vs=$vs" >> $Env:GITHUB_OUTPUT
