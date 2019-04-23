$packageName = $env:chocolateyPackageName
$packageVersionParts = ($env:ChocolateyPackageVersion).Split(".")

$folderVersion = "jdk1.{0}.{1}_{2}" -f $packageVersionParts[0], $packageVersionParts[1], $packageVersionParts[2] 

$tarGzFile = "\\sv-hq-nas01\installers\O\Oracle\server-jre-8u212-windows-x64.tar.gz" 
$tarGzItem = Get-Item $tarGzFile

$arguments = @{}

# Now we can use the $env:chocolateyPackageParameters inside the Chocolatey package
$packageParameters = $env:chocolateyPackageParameters

# Default value
$InstallationPath = Join-Path (Get-ToolsLocation) "Java/server-jre"
$ForceEnvVars = $false
$EnvVariableType = "Machine"

# Now parse the packageParameters using good old regular expression
if ($packageParameters) {
    $match_pattern = "\/(?<option>([a-zA-Z0-9]+)):(?<value>([`"'])?([a-zA-Z0-9- \(\)\s_\\:\.]+)([`"'])?)|\/(?<option>([a-zA-Z]+))"
    $option_name = 'option'
    $value_name = 'value'

    if ($packageParameters -match $match_pattern ){
        $results = $packageParameters | Select-String $match_pattern -AllMatches
        $results.matches | % {
        $arguments.Add(
            $_.Groups[$option_name].Value.Trim(),
            $_.Groups[$value_name].Value.Trim())
        }
    }
    else
    {
        Throw "Package Parameters were found but were invalid (REGEX Failure)"
    }

    if ($arguments.ContainsKey("InstallationPath")) {
        Write-Host "InstallationPath Argument Found"
        $InstallationPath = $arguments["InstallationPath"]
    }
    if ($arguments.ContainsKey("Force")) {
        Write-Host "Force Argument Found"
        $ForceEnvVars = $true
    }
    if ($arguments.ContainsKey("User")) {
        Write-Host "User Argument Found"
        $EnvVariableType = "User"
    }

} else {
    Write-Debug "No Package Parameters Passed in"
}

Write-Debug "Installing to $InstallationPath, Params: ForceEnvVars=$ForceEnvVars, EnvVariableType=$EnvVariableType"

#Create Temp Folder
$chocTempDir = Join-Path $env:TEMP "chocolatey"
$tempDir = Join-Path $chocTempDir "$packageName"
if ($env:packageVersion -ne $null) {$tempDir = Join-Path $tempDir "$env:packageVersion"; }
if (!(Test-Path $tempDir)) {
	New-Item -ItemType Directory $tempDir
}


$tarFile = $tempDir + "\" + $tarGzItem.BaseName

#Extract gz to .tar File
Get-ChocolateyUnzip $tarGzFile $tempDir
#Extract tar to destination
Get-ChocolateyUnzip $tarFile $InstallationPath

$newJavaHome = Join-Path $InstallationPath $folderVersion
$oldJavaHome = Get-EnvironmentVariable "JAVA_HOME" $EnvVariableType

if(($oldJavaHome -eq "") -or $ForceEnvVars) {
   Write-Host "Setting JAVA_HOME to $newJavaHome"
   Install-ChocolateyEnvironmentVariable -variableName "JAVA_HOME" -variableValue $newJavaHome -variableType $EnvVariableType
}
else {
   Write-Debug "JAVA_HOME already set to $oldJavaHome."
}

# Need to do an existance check to see if the variable version is already in PATH
Install-ChocolateyPath '%JAVA_HOME%\bin' $EnvVariableType
Get-EnvironmentVariable -Name 'PATH' -Scope $EnvVariableType -PreserveVariables
