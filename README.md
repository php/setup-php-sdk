# Setup PHP-SDK Action

[Github Action](https://github.com/features/actions) to set up an environment
for building and testing PHP extensions on Windows.

## Example Usage

````.yml
- id: setup-php-sdk
  uses: php/setup-php-sdk@v0.12
  with:
    version: 8.0
    arch: x64
    ts: nts
- uses: ilammy/msvc-dev-cmd@v1
  with:
    arch: x64
    toolset: ${{steps.setup-php-sdk.outputs.toolset}}
- run: phpize
- run: configure --enable-dbase --with-prefix=${{steps.setup-php-sdk.outputs.prefix}}
- run: nmake
- run: nmake test TESTS=tests
````

## Inputs

- `version`: the PHP version to build for
  (`7.0`, `7.1`, `7.2`, `7.3`, `7.4`, `8.0`, `8.1`, `8.2`, `8.3`, `8.4`, or `8.5`)
- `arch`: the architecture to build for (`x64` or `x86`)
- `ts`: thread-safety (`nts` or `ts`)
- `deps`: dependency libraries to install; for now, only
  [core dependencies](https://windows.php.net/downloads/php-sdk/deps/) are available
- `cache`: whether to cache the PHP SDK, PHP and development pack

Note that for PHP versions 7.4 and below, `runs-on: windows-2022` will not work
as the correct toolset is not available. For these versions, you should use
`runs-on: windows-2019`. For example:

```yml
strategy:
  matrix:
    os: [ windows-2019, windows-2022 ]
    php: [ "8.1", "8.0", "7.4", "7.3", "7.2", "7.1" ]
    arch: [ x64, x86 ]
    ts: [ ts, nts ]
    exclude:
      - { os: windows-2019, php: "8.1" }
      - { os: windows-2019, php: "8.0" }
      - { os: windows-2022, php: "7.4" }
      - { os: windows-2022, php: "7.3" }
      - { os: windows-2022, php: "7.2" }
      - { os: windows-2022, php: "7.1" }
```

Currently, windows-2019 may be used for all PHP versions up to PHP 8.3.
PHP 8.4 requires a newer image such as windows-2022.
Note that windows-2025 currently is not supported by phpize; to work around
that, you need to force usage of the original JScript engine, by running
```
reg add "HKLM\Software\Policies\Microsoft\Internet Explorer\Main" /v JScriptReplacement /d 0 /f
```
prior to invoking `phpize`.

### Manually Installing Toolsets

It is possible to manually install older toolsets on `windows-2022` using an
approach suggested in [actions/runner-images#9701](https://github.com/actions/runner-images/issues/9701).
The following example installs VC15 by its
[Component ID](https://learn.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-build-tools?view=vs-2022)
to allow building PHP 7.2, 7.3, and 7.4 on a `windows-2022` image:

```yml
run:
  steps:
    - name: Install VC15 component
      if: ${{ matrix.php == '7.4' || matrix.php == '7.3' || matrix.php == '7.2' }}
      shell: pwsh
      run: |
              Set-Location "C:\Program Files (x86)\Microsoft Visual Studio\Installer\"
              $installPath = "C:\Program Files\Microsoft Visual Studio\2022\Enterprise"
              $component = "Microsoft.VisualStudio.Component.VC.v141.x86.x64"
              $args = ('/c', "vs_installer.exe", 'modify', '--installPath', "`"$installPath`"", '--add', $component, '--quiet', '--norestart', '--nocache')
              $process = Start-Process -FilePath cmd.exe -ArgumentList $args -Wait -PassThru -WindowStyle Hidden
```

This step should be executed _before_ invoking the `setup-php-sdk` action.

## Outputs

- `toolset`: the required toolset version;
  needs to be passed to the ilammy/msvc-dev-cmd action
- `prefix`: the prefix of the PHP installation;
  needs to be passed to configure
- `vs`: the Visual Studio version
