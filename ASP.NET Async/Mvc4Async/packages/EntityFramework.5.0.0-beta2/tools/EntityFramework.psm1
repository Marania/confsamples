# Copyright (c) Microsoft Corporation.  All rights reserved.

$InitialDatabase = '0'

$knownExceptions = @(
    'System.Data.Entity.Migrations.Infrastructure.MigrationsException',
    'System.Data.Entity.Migrations.Infrastructure.AutomaticMigrationsDisabledException',
    'System.Data.Entity.Migrations.Infrastructure.AutomaticDataLossException',
    'System.Data.Entity.Migrations.MigrationsPendingException',
    'System.Data.Entity.Migrations.ProjectTypeNotSupportedException'
)

<#
.SYNOPSIS
    Enables Code First Migrations in a project.

.DESCRIPTION
    Enables Migrations by scaffolding a migrations configuration class in the project. If the
    target database was created by an initializer, an initial migration will be created (unless
    automatic migrations are enabled via the EnableAutomaticMigrations parameter).

.PARAMETER EnableAutomaticMigrations
    Specifies whether automatic migrations will be enabled in the scaffolded migrations configuration.
    If ommitted, automatic migrations will be disabled.

.PARAMETER ProjectName
    Specifies the project that the scaffolded migrations configuration class will
    be added to. If omitted, the default project selected in package manager
    console is used.

.PARAMETER StartUpProjectName
    Specifies the configuration file to use for named connection strings. If
    omitted, the specified project's configuration file is used.

.PARAMETER ConnectionStringName
    Specifies the name of a connection string to use from the application's
    configuration file.

.PARAMETER ConnectionString
    Specifies the the connection string to use. If omitted, the context's
    default connection will be used.

.PARAMETER ConnectionProviderName
    Specifies the provider invariant name of the connection string.

.PARAMETER Force
    Specifies that the migrations configuration be overwritten when running more
    than once for a given project.
#>
function Enable-Migrations
{
    [CmdletBinding(DefaultParameterSetName = 'ConnectionStringName')] 
    param (
        [alias('Auto')]
        [switch] $EnableAutomaticMigrations,
        [string] $ProjectName,
        [string] $StartUpProjectName,
        [parameter(ParameterSetName = 'ConnectionStringName')]
        [string] $ConnectionStringName,
        [parameter(ParameterSetName = 'ConnectionStringAndProviderName',
            Mandatory = $true)]
        [string] $ConnectionString,
        [parameter(ParameterSetName = 'ConnectionStringAndProviderName',
            Mandatory = $true)]
        [string] $ConnectionProviderName,
        [switch] $Force
    )

    $runner = New-MigrationsRunner $ProjectName $StartUpProjectName $null $ConnectionStringName $ConnectionString $ConnectionProviderName

    try
    {
        Invoke-RunnerCommand $runner System.Data.Entity.Migrations.EnableMigrationsCommand @( $EnableAutomaticMigrations.IsPresent, $Force.IsPresent)
        $error = Get-RunnerError $runner
        
        if ($error)
        {
            if ($knownExceptions -notcontains $error.TypeName)
            {
                Write-Host $error.StackTrace
            }

            throw $error.Message
        }
    }
    finally
    {
        Remove-Runner $runner
    }
}

<#
.SYNOPSIS
    Scaffolds a migration script for any pending model changes.

.DESCRIPTION
    Scaffolds a new migration script and adds it to the project.

.PARAMETER Name
    Specifies the name of the custom script.

.PARAMETER Force
    Specifies that the migration user code be overwritten when re-scaffolding an
    existing migration.

.PARAMETER ProjectName
    Specifies the project that contains the migration configuration type to be
    used. If ommitted, the default project selected in package manager console
    is used.

.PARAMETER StartUpProjectName
    Specifies the configuration file to use for named connection strings. If
    omitted, the specified project's configuration file is used.

.PARAMETER ConfigurationTypeName
    Specifies the migrations configuration to use. If omitted, migrations will
    attempt to locate a single migrations configuration type in the target
    project.

.PARAMETER ConnectionStringName
    Specifies the name of a connection string to use from the application's
    configuration file.

.PARAMETER ConnectionString
    Specifies the the connection string to use. If omitted, the context's
    default connection will be used.

.PARAMETER ConnectionProviderName
    Specifies the provider invariant name of the connection string.

.PARAMETER IgnoreChanges
    Scaffolds an empty migration ignoring any pending changes detected in the current model.
    This can be used to create an initial, empty migration to enable Migrations for an existing
    database. N.B. Doing this assumes that the target database schema is compatible with the
    current model.

#>
function Add-Migration
{
    [CmdletBinding(DefaultParameterSetName = 'ConnectionStringName')]
    param (
        [parameter(Position = 0,
            Mandatory = $true)]
        [string] $Name,
        [switch] $Force,
        [string] $ProjectName,
        [string] $StartUpProjectName,
        [string] $ConfigurationTypeName,
        [parameter(ParameterSetName = 'ConnectionStringName')]
        [string] $ConnectionStringName,
        [parameter(ParameterSetName = 'ConnectionStringAndProviderName',
            Mandatory = $true)]
        [string] $ConnectionString,
        [parameter(ParameterSetName = 'ConnectionStringAndProviderName',
            Mandatory = $true)]
        [string] $ConnectionProviderName,
        [switch] $IgnoreChanges)

    $runner = New-MigrationsRunner $ProjectName $StartUpProjectName $ConfigurationTypeName $ConnectionStringName $ConnectionString $ConnectionProviderName

    try
    {
        Invoke-RunnerCommand $runner System.Data.Entity.Migrations.AddMigrationCommand @( $Name, $Force.IsPresent, $IgnoreChanges.IsPresent )
        $error = Get-RunnerError $runner
        
        if ($error)
        {
            if ($knownExceptions -notcontains $error.TypeName)
            {
                Write-Host $error.StackTrace
            }

            throw $error.Message
        }
    }
    finally
    {
        Remove-Runner $runner
    }
}

<#
.SYNOPSIS
    Applies any pending migrations to the database.

.DESCRIPTION
    Updates the database to the current model by applying pending migrations.

.PARAMETER SourceMigration
    Only valid with -Script. Specifies the name of a particular migration to use
    as the update's starting point. If ommitted, the last applied migration in
    the database will be used.

.PARAMETER TargetMigration
    Specifies the name of a particular migration to update the database to. If
    ommitted, the current model will be used.

.PARAMETER Script
    Generate a SQL script rather than executing the pending changes directly.

.PARAMETER Force
    Specifies that data loss is acceptable during automatic migration of the
    database.

.PARAMETER ProjectName
    Specifies the project that contains the migration configuration type to be
    used. If ommitted, the default project selected in package manager console
    is used.

.PARAMETER StartUpProjectName
    Specifies the configuration file to use for named connection strings. If
    omitted, the specified project's configuration file is used.

.PARAMETER ConfigurationTypeName
    Specifies the migrations configuration to use. If omitted, migrations will
    attempt to locate a single migrations configuration type in the target
    project.

.PARAMETER ConnectionStringName
    Specifies the name of a connection string to use from the application's
    configuration file.

.PARAMETER ConnectionString
    Specifies the the connection string to use. If omitted, the context's
    default connection will be used.

.PARAMETER ConnectionProviderName
    Specifies the provider invariant name of the connection string.
#>
function Update-Database
{
    [CmdletBinding(DefaultParameterSetName = 'ConnectionStringName')]
    param (
        [string] $SourceMigration,
        [string] $TargetMigration,
        [switch] $Script,
        [switch] $Force,
        [string] $ProjectName,
        [string] $StartUpProjectName,
        [string] $ConfigurationTypeName,
        [parameter(ParameterSetName = 'ConnectionStringName')]
        [string] $ConnectionStringName,
        [parameter(ParameterSetName = 'ConnectionStringAndProviderName',
            Mandatory = $true)]
        [string] $ConnectionString,
        [parameter(ParameterSetName = 'ConnectionStringAndProviderName',
            Mandatory = $true)]
        [string] $ConnectionProviderName)

    $runner = New-MigrationsRunner $ProjectName $StartUpProjectName $ConfigurationTypeName $ConnectionStringName $ConnectionString $ConnectionProviderName

    try
    {
        Invoke-RunnerCommand $runner System.Data.Entity.Migrations.UpdateDatabaseCommand @( $SourceMigration, $TargetMigration, $Script.IsPresent, $Force.IsPresent, $Verbose.IsPresent )
        $error = Get-RunnerError $runner
        
        if ($error)
        {
            if ($knownExceptions -notcontains $error.TypeName)
            {
                Write-Host $error.StackTrace
            }

            throw $error.Message
        }
    }
    finally
    {
        Remove-Runner $runner
    }
}

<#
.SYNOPSIS
    Displays the migrations that have been applied to the target database.

.DESCRIPTION
    Displays the migrations that have been applied to the target database.

.PARAMETER ProjectName
    Specifies the project that contains the migration configuration type to be
    used. If ommitted, the default project selected in package manager console
    is used.

.PARAMETER StartUpProjectName
    Specifies the configuration file to use for named connection strings. If
    omitted, the specified project's configuration file is used.

.PARAMETER ConfigurationTypeName
    Specifies the migrations configuration to use. If omitted, migrations will
    attempt to locate a single migrations configuration type in the target
    project.

.PARAMETER ConnectionStringName
    Specifies the name of a connection string to use from the application's
    configuration file.

.PARAMETER ConnectionString
    Specifies the the connection string to use. If omitted, the context's
    default connection will be used.

.PARAMETER ConnectionProviderName
    Specifies the provider invariant name of the connection string.
#>
function Get-Migrations
{
    [CmdletBinding(DefaultParameterSetName = 'ConnectionStringName')]
    param (
        [string] $ProjectName,
        [string] $StartUpProjectName,
        [string] $ConfigurationTypeName,
        [parameter(ParameterSetName = 'ConnectionStringName')]
        [string] $ConnectionStringName,
        [parameter(ParameterSetName = 'ConnectionStringAndProviderName',
            Mandatory = $true)]
        [string] $ConnectionString,
        [parameter(ParameterSetName = 'ConnectionStringAndProviderName',
            Mandatory = $true)]
        [string] $ConnectionProviderName)

    $runner = New-MigrationsRunner $ProjectName $StartUpProjectName $ConfigurationTypeName $ConnectionStringName $ConnectionString $ConnectionProviderName

    try
    {
        Invoke-RunnerCommand $runner System.Data.Entity.Migrations.GetMigrationsCommand
        $error = Get-RunnerError $runner
        
        if ($error)
        {
            if ($knownExceptions -notcontains $error.TypeName)
            {
                Write-Host $error.StackTrace
            }

            throw $error.Message
        }
    }
    finally
    {
        Remove-Runner $runner
    }
}

function New-MigrationsRunner($ProjectName, $StartUpProjectName, $ConfigurationTypeName, $ConnectionStringName, $ConnectionString, $ConnectionProviderName)
{
    $startUpProject = Get-MigrationsStartUpProject $StartUpProjectName $ProjectName
    Build-Project $startUpProject

    $project = Get-MigrationsProject $ProjectName
    Build-Project $project

    $installPath = Get-EntityFrameworkInstallPath $project
    $toolsPath = Join-Path $installPath tools

    $info = New-Object System.AppDomainSetup -Property @{
            ShadowCopyFiles = 'true';
            ApplicationBase = $installPath;
            PrivateBinPath = 'tools'
        }
    
    $targetFrameworkVersion = (New-Object System.Runtime.Versioning.FrameworkName ($project.Properties.Item('TargetFrameworkMoniker').Value)).Version

    if ($targetFrameworkVersion -lt (New-Object Version @( 4, 5 )))
    {
        $info.PrivateBinPath += ';lib\net40'
        $info.ConfigurationFile = Join-Path $toolsPath 'Redirect.config'
    }
    else
    {
        $info.PrivateBinPath += ';lib\net45'
    }

    $domain = [AppDomain]::CreateDomain('Migrations', $null, $info)
    $domain.SetData('project', $project)
    $domain.SetData('startUpProject', $startUpProject)
    $domain.SetData('configurationTypeName', $ConfigurationTypeName)
    $domain.SetData('connectionStringName', $ConnectionStringName)
    $domain.SetData('connectionString', $ConnectionString)
    $domain.SetData('connectionProviderName', $ConnectionProviderName)
    
    [AppDomain]::CurrentDomain.SetShadowCopyFiles()
    $utilityAssembly = [System.Reflection.Assembly]::LoadFrom((Join-Path $toolsPath EntityFramework.PowerShell.Utility.dll))
    $dispatcher = $utilityAssembly.CreateInstance(
        'System.Data.Entity.Migrations.Utilities.DomainDispatcher',
        $false,
        [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::Public,
        $null,
        $PSCmdlet,
        $null,
        $null)        
    $domain.SetData('efDispatcher', $dispatcher)

    return @{
        Domain = $domain;
        ToolsPath = $toolsPath
    }
}

function Remove-Runner($runner)
{
    [AppDomain]::Unload($runner.Domain)
}

function Invoke-RunnerCommand($runner, $command, $parameters)
{
    $domain = $runner.Domain
    $domain.CreateInstanceFrom(
        (Join-Path $runner.ToolsPath EntityFramework.PowerShell.dll),
        $command,
        $false,
        0,
        $null,
        $parameters,
        $null,
        $null) | Out-Null
}

function Get-RunnerError($runner)
{
    $domain = $runner.Domain

    if (!$domain.GetData('wasError'))
    {
        return $null
    }

    return @{
            Message = $domain.GetData('error.Message');
            TypeName = $domain.GetData('error.TypeName');
            StackTrace = $domain.GetData('error.StackTrace')
    }
}

function Get-MigrationsProject($name, $hideMessage)
{
    if ($name)
    {
        return Get-SingleProject $name
    }

    $project = Get-Project
    $projectName = $project.Name

    if (!$hideMessage)
    {
        Write-Verbose "Using NuGet project '$projectName'."
    }

    return $project
}

function Get-MigrationsStartUpProject($name, $fallbackName)
{    
    $startUpProject = $null

    if ($name)
    {
        $startUpProject = Get-SingleProject $name
    }
    else
    {
        $startupProjectPaths = $DTE.Solution.SolutionBuild.StartupProjects

        if ($startupProjectPaths)
        {
            if ($startupProjectPaths.Length -eq 1)
            {
                $startupProjectPath = $startupProjectPaths[0]

                if (!(Split-Path -IsAbsolute $startupProjectPath))
                {
                    $solutionPath = Split-Path $DTE.Solution.Properties.Item('Path').Value
                    $startupProjectPath = Join-Path $solutionPath $startupProjectPath -Resolve
                }

                $startupProject = (Get-SolutionProjects) | ?{
                    $fullName = $_.FullName

                    if ($fullName -and $fullName.EndsWith('\'))
                    {
                        $fullName = $fullName.Substring(0, $fullName.Length - 1)
                    }

                    return $fullName -eq $startupProjectPath
                }
            }
            else
            {
                Write-Verbose 'More than one start-up project found.'
            }
        }
        else
        {
            Write-Verbose 'No start-up project found.'
        }
    }

    if (!($startUpProject -and (Test-StartUpProject $startUpProject)))
    {
        $startUpProject = Get-MigrationsProject $fallbackName $true
        $startUpProjectName = $startUpProject.Name

        Write-Warning "Cannot determine a valid start-up project. Using project '$startUpProjectName' instead. Your configuration file and working directory may not be set as expected. Use the -StartUpProjectName parameter to set one explicitly. Use the -Verbose switch for more information."
    }
    else
    {
        $startUpProjectName = $startUpProject.Name

        Write-Verbose "Using StartUp project '$startUpProjectName'."
    }

    return $startUpProject
}

function Get-SolutionProjects()
{
    $projects = New-Object System.Collections.Stack
    
    $DTE.Solution.Projects | %{
        $projects.Push($_)
    }
    
    while ($projects.Count -ne 0)
    {
        $project = $projects.Pop();
        
        # NOTE: This line is similar to doing a "yield return" in C#
        $project

        if ($project.ProjectItems)
        {
            $project.ProjectItems | ?{ $_.SubProject } | %{
                $projects.Push($_.SubProject)
            }
        }
    }
}

function Get-SingleProject($name)
{
    $project = Get-Project $name

    if ($project -is [array])
    {
        throw "More than one project '$name' was found. Specify the full name of the one to use."
    }

    return $project
}

function Test-StartUpProject($project)
{    
    if ($project.Kind -eq '{cc5fd16d-436d-48ad-a40c-5a424c6e3e79}')
    {
        $projectName = $project.Name
        Write-Verbose "Cannot use start-up project '$projectName'. The Windows Azure Project type isn't supported."
        
        return $false
    }
    
    return $true
}

function Build-Project($project)
{
    $configuration = $DTE.Solution.SolutionBuild.ActiveConfiguration.Name

    $DTE.Solution.SolutionBuild.BuildProject($configuration, $project.UniqueName, $true)

    if ($DTE.Solution.SolutionBuild.LastBuildInfo)
    {
        $projectName = $project.Name

        throw "The project '$projectName' failed to build."
    }
}

function Get-EntityFrameworkInstallPath($project)
{
    $package = Get-Package -ProjectName $project.FullName | ?{ $_.Id -eq 'EntityFramework' }

    if (!$package)
    {
        $projectName = $project.Name

        throw "The EntityFramework package is not installed on project '$projectName'."
    }
    
    return Get-PackageInstallPath $package
}
    
function Get-PackageInstallPath($package)
    {
    $componentModel = Get-VsComponentModel
    $packageInstallerServices = $componentModel.GetService([NuGet.VisualStudio.IVsPackageInstallerServices])

    $vsPackage = $packageInstallerServices.GetInstalledPackages() | ?{ $_.Id -eq $package.Id -and $_.Version -eq $package.Version }
    
    return $vsPackage.InstallPath
}

Export-ModuleMember @( 'Enable-Migrations', 'Add-Migration', 'Update-Database', 'Get-Migrations' ) -Variable InitialDatabase

# SIG # Begin signature block
# MIIaRgYJKoZIhvcNAQcCoIIaNzCCGjMCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUB+cJ7FxiUAv+RhfLMLNUqkuz
# WkCgghUtMIIEoDCCA4igAwIBAgIKYRnMkwABAAAAZjANBgkqhkiG9w0BAQUFADB5
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
# bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSMwIQYDVQQDExpN
# aWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQTAeFw0xMTEwMTAyMDMyMjVaFw0xMzAx
# MTAyMDMyMjVaMIGDMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
# MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MQ0wCwYDVQQLEwRNT1BSMR4wHAYDVQQDExVNaWNyb3NvZnQgQ29ycG9yYXRpb24w
# ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDuW759ESTjhgbgZv9ItRe9
# AuS0DDLwcj59LofXTqGxp0Mv92WeMeEyMUWu18EkhCHXLrWEfvo101Mc17ZRHk/O
# ZrnrtwwC/SlcraiH9soitNW/CHX1inCPY9fvih7pj0MkZFrTh32QbTusds1XNn3o
# vBBWrJjwiV0uZMavJgleHmMV8T2/Fo+ZiALDMLfBC2AfD3LM1reoNRKGm6ELCuaT
# W476VJzB8xlfQo0Snx0/kLcnE4MZMoId89mH1CGyPKK2B0/XJKrujfWz2fr5OU+n
# 6fKvWVL03EGbLxFwY93q3qrxbSEEEFMzu7JPxeFTskFlR2439rzpmxZBkWsuWzDD
# AgMBAAGjggEdMIIBGTATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQUG1IO
# 8xEqt8CJwxGBPdSWWLmjU24wDgYDVR0PAQH/BAQDAgeAMB8GA1UdIwQYMBaAFMsR
# 6MrStBZYAck3LjMWFrlMmgofMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwu
# bWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY0NvZFNpZ1BDQV8wOC0z
# MS0yMDEwLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljQ29kU2lnUENBXzA4LTMxLTIw
# MTAuY3J0MA0GCSqGSIb3DQEBBQUAA4IBAQClWzZsrU6baRLjb4oCm2l3w2xkciiI
# 2T1FbSwYe9QoLxPiWWobwgs0t4r96rmU7Acx5mr0dQTTp9peOgaeEP2pDb2cUUNv
# /2eUnOHPfPAksDXMg13u2sBvNknAWgpX9nPhnvPjCEw7Pi/M0s3uTyJw9wQfAqZL
# m7iPXIgONpRsMwe4qa1RoNDC3I4iEr3D34LXVqH33fClIFcQEJ3urIZ0bHGbwfDy
# wnBep9ttTTdYmU15QNA0XVolrmfrG05GBrCMKR+jEI+lM58j1fi1Rn3g7mOYkEs+
# BagvsBizWaSvQVOOCAUQLSrJOgZMHC6pMVFWZKyazKyXmCmKl5CH6p22MIIEujCC
# A6KgAwIBAgIKYQUTNgAAAAAAGjANBgkqhkiG9w0BAQUFADB3MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEwHwYDVQQDExhNaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBQQ0EwHhcNMTEwNzI1MjA0MjE3WhcNMTIxMDI1MjA0MjE3WjCBszEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjENMAsGA1UECxMETU9Q
# UjEnMCUGA1UECxMebkNpcGhlciBEU0UgRVNOOjE1OUMtQTNGNy0yNTcwMSUwIwYD
# VQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEAnDSYGckJKWOZAhZ1qIhXfaG7qUES/GSRpdYFeL93
# 3OzmrrhQTsDjGr3tt/34IIpxOapyknKfignlE++RQe1hJWtRre6oQ7VhQiyd8h2x
# 0vy39Xujc3YTsyuj25RhgFWhD23d2OwW/4V/lp6IfwAujnokumidj8bK9JB5euGb
# 7wZdfvguw2oVnDwUL+fVlMgiG1HLqVWGIbda80ESOZ/wValOqiUrY/uRcjwPfMCW
# ctzBo8EIyt7FybXACl+lnAuqcgpdCkB9LpjQq7KIj4aA6H3RvlVr4FgsyDY/+eYR
# w/BDBYV4AxflLKcpfNPilRcAbNvcrTwZOgLgfWLUzvYdPQIDAQABo4IBCTCCAQUw
# HQYDVR0OBBYEFPaDiyCHEe6Dy9vehaLSaIY3YXSQMB8GA1UdIwQYMBaAFCM0+NlS
# RnAK7UD7dvuzK7DDNbMPMFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly9jcmwubWlj
# cm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY3Jvc29mdFRpbWVTdGFtcFBD
# QS5jcmwwWAYIKwYBBQUHAQEETDBKMEgGCCsGAQUFBzAChjxodHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY3Jvc29mdFRpbWVTdGFtcFBDQS5jcnQw
# EwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcNAQEFBQADggEBAGL0BQ1P5xtr
# gudSDN95jKhVgTOX06TKyf6vSNt72m96KE/H0LeJ2NGmmcyRVgA7OOi3Mi/u+c9r
# 2Zje1gL1QlhSa47aQNwWoLPUvyYVy0hCzNP9tPrkRIlmD0IOXvcEnyNIW7SJQcTa
# bPg29D/CHhXfmEwAxLLs3l8BAUOcuELWIsiTmp7JpRhn/EeEHpFdm/J297GOch2A
# djw2EUbKfjpI86/jSfYXM427AGOCnFejVqfDbpCjPpW3/GTRXRjCCwFQY6f889GA
# noTjMjTdV5VAo21+2usuWgi0EAZeMskJ6TKCcRan+savZpiJ+dmetV8QI6N3gPJN
# 1igAclCFvOUwggW8MIIDpKADAgECAgphMyYaAAAAAAAxMA0GCSqGSIb3DQEBBQUA
# MF8xEzARBgoJkiaJk/IsZAEZFgNjb20xGTAXBgoJkiaJk/IsZAEZFgltaWNyb3Nv
# ZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhvcml0
# eTAeFw0xMDA4MzEyMjE5MzJaFw0yMDA4MzEyMjI5MzJaMHkxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xIzAhBgNVBAMTGk1pY3Jvc29mdCBDb2Rl
# IFNpZ25pbmcgUENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsnJZ
# XBkwZL8dmmAgIEKZdlNsPhvWb8zL8epr/pcWEODfOnSDGrcvoDLs/97CQk4j1XIA
# 2zVXConKriBJ9PBorE1LjaW9eUtxm0cH2v0l3511iM+qc0R/14Hb873yNqTJXEXc
# r6094CholxqnpXJzVvEXlOT9NZRyoNZ2Xx53RYOFOBbQc1sFumdSjaWyaS/aGQv+
# knQp4nYvVN0UMFn40o1i/cvJX0YxULknE+RAMM9yKRAoIsc3Tj2gMj2QzaE4BoVc
# TlaCKCoFMrdL109j59ItYvFFPeesCAD2RqGe0VuMJlPoeqpK8kbPNzw4nrR3XKUX
# no3LEY9WPMGsCV8D0wIDAQABo4IBXjCCAVowDwYDVR0TAQH/BAUwAwEB/zAdBgNV
# HQ4EFgQUyxHoytK0FlgByTcuMxYWuUyaCh8wCwYDVR0PBAQDAgGGMBIGCSsGAQQB
# gjcVAQQFAgMBAAEwIwYJKwYBBAGCNxUCBBYEFP3RMU7TJoqV4ZhgO6gxb6Y8vNgt
# MBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMB8GA1UdIwQYMBaAFA6sgmBAVieX
# 5SUT/CrhClOVWeSkMFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9jcmwubWljcm9z
# b2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL21pY3Jvc29mdHJvb3RjZXJ0LmNybDBU
# BggrBgEFBQcBAQRIMEYwRAYIKwYBBQUHMAKGOGh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2kvY2VydHMvTWljcm9zb2Z0Um9vdENlcnQuY3J0MA0GCSqGSIb3DQEB
# BQUAA4ICAQBZOT5/Jkav629AsTK1ausOL26oSffrX3XtTDst10OtC/7L6S0xoyPM
# fFCYgCFdrD0vTLqiqFac43C7uLT4ebVJcvc+6kF/yuEMF2nLpZwgLfoLUMRWzS3j
# StK8cOeoDaIDpVbguIpLV/KVQpzx8+/u44YfNDy4VprwUyOFKqSCHJPilAcd8uJO
# +IyhyugTpZFOyBvSj3KVKnFtmxr4HPBT1mfMIv9cHc2ijL0nsnljVkSiUc356aNY
# Vt2bAkVEL1/02q7UgjJu/KSVE+Traeepoiy+yCsQDmWOmdv1ovoSJgllOJTxeh9K
# u9HhVujQeJYYXMk1Fl/dkx1Jji2+rTREHO4QFRoAXd01WyHOmMcJ7oUOjE9tDhNO
# PXwpSJxy0fNsysHscKNXkld9lI2gG0gDWvfPo2cKdKU27S0vF8jmcjcS9G+xPGeC
# +VKyjTMWZR4Oit0Q3mT0b85G1NMX6XnEBLTT+yzfH4qerAr7EydAreT54al/RrsH
# YEdlYEBOsELsTu2zdnnYCjQJbRyAMR/iDlTd5aH75UcQrWSY/1AWLny/BSF64pVB
# J2nDk4+VyY3YmyGuDVyc8KKuhmiDDGotu3ZrAB2WrfIWe/YWgyS5iM9qqEcxL5rc
# 43E91wB+YkfRzojJuBj6DnKNwaM9rwJAav9pm5biEKgQtDdQCNbDPTCCBgcwggPv
# oAMCAQICCmEWaDQAAAAAABwwDQYJKoZIhvcNAQEFBQAwXzETMBEGCgmSJomT8ixk
# ARkWA2NvbTEZMBcGCgmSJomT8ixkARkWCW1pY3Jvc29mdDEtMCsGA1UEAxMkTWlj
# cm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5MB4XDTA3MDQwMzEyNTMw
# OVoXDTIxMDQwMzEzMDMwOVowdzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEhMB8GA1UEAxMYTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBMIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAn6Fssd/bSJIqfGsuGeG94uPFmVEj
# UK3O3RhOJA/u0afRTK10MCAR6wfVVJUVSZQbQpKumFwwJtoAa+h7veyJBw/3DgSY
# 8InMH8szJIed8vRnHCz8e+eIHernTqOhwSNTyo36Rc8J0F6v0LBCBKL5pmyTZ9co
# 3EZTsIbQ5ShGLieshk9VUgzkAyz7apCQMG6H81kwnfp+1pez6CGXfvjSE/MIt1Nt
# UrRFkJ9IAEpHZhEnKWaol+TTBoFKovmEpxFHFAmCn4TtVXj+AZodUAiFABAwRu23
# 3iNGu8QtVJ+vHnhBMXfMm987g5OhYQK1HQ2x/PebsgHOIktU//kFw8IgCwIDAQAB
# o4IBqzCCAacwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUIzT42VJGcArtQPt2
# +7MrsMM1sw8wCwYDVR0PBAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEAMIGYBgNVHSME
# gZAwgY2AFA6sgmBAVieX5SUT/CrhClOVWeSkoWOkYTBfMRMwEQYKCZImiZPyLGQB
# GRYDY29tMRkwFwYKCZImiZPyLGQBGRYJbWljcm9zb2Z0MS0wKwYDVQQDEyRNaWNy
# b3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHmCEHmtFqFKoKWtTHNY9AcT
# LmUwUAYDVR0fBEkwRzBFoEOgQYY/aHR0cDovL2NybC5taWNyb3NvZnQuY29tL3Br
# aS9jcmwvcHJvZHVjdHMvbWljcm9zb2Z0cm9vdGNlcnQuY3JsMFQGCCsGAQUFBwEB
# BEgwRjBEBggrBgEFBQcwAoY4aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9j
# ZXJ0cy9NaWNyb3NvZnRSb290Q2VydC5jcnQwEwYDVR0lBAwwCgYIKwYBBQUHAwgw
# DQYJKoZIhvcNAQEFBQADggIBABCXisNcA0Q23em0rXfbznlRTQGxLnRxW20ME6vO
# vnuPuC7UEqKMbWK4VwLLTiATUJndekDiV7uvWJoc4R0Bhqy7ePKL0Ow7Ae7ivo8K
# BciNSOLwUxXdT6uS5OeNatWAweaU8gYvhQPpkSokInD79vzkeJkuDfcH4nC8GE6d
# jmsKcpW4oTmcZy3FUQ7qYlw/FpiLID/iBxoy+cwxSnYxPStyC8jqcD3/hQoT38IK
# YY7w17gX606Lf8U1K16jv+u8fQtCe9RTciHuMMq7eGVcWwEXChQO0toUmPU8uWZY
# sy0v5/mFhsxRVuidcJRsrDlM1PZ5v6oYemIp76KbKTQGdxpiyT0ebR+C8AvHLLvP
# Q7Pl+ex9teOkqHQ1uE7FcSMSJnYLPFKMcVpGQxS8s7OwTWfIn0L/gHkhgJ4VMGbo
# QhJeGsieIiHQQ+kr6bv0SMws1NgygEwmKkgkX1rqVu+m3pmdyjpvvYEndAYR7nYh
# v5uCwSdUtrFqPYmhdmG0bqETpr+qR/ASb/2KMmyy/t9RyIwjyWa9nR2HEmQCPS2v
# WY+45CHltbDKY7R4VAXUQS5QrJSwpXirs6CWdRrZkocTdSIvMqgIbqBbjCW/oO+E
# yiHW6x5PyZruSeD3AWVviQt9yGnI5m7qp5fOMSn/DsVbXNhNG6HY+i+ePy5VFmvJ
# E6P9MYIEgzCCBH8CAQEwgYcweTELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEjMCEGA1UEAxMaTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQQ0ECCmEZ
# zJMAAQAAAGYwCQYFKw4DAhoFAKCBsDAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIB
# BDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU
# VghjFCiFj7s0jIcGqguA8uUeq00wUAYKKwYBBAGCNwIBDDFCMECgIoAgAEUAbgB0
# AGkAdAB5ACAARgByAGEAbQBlAHcAbwByAGuhGoAYaHR0cDovL21zZG4uY29tL2Rh
# dGEvZWYvMA0GCSqGSIb3DQEBAQUABIIBALn0PqDNgK3O2C47peMOidbXe10gpi7V
# bOxCJB0QrM80wS0bGWmS4tDfec9RnWbkD1u24yvZS12gZsVPXMbUU0aek1ay7JzW
# lcZ4Nx5mU8O91eJmBINYKsCctH0bupT+EqyERBr4VRlHbHHSxXWOA/EGcNO7AyRd
# CUfBXLG98hIul2vuqzGYnD8bDqSdvOt3Q0PtrUHp4HiXFC+eKZfQdlXqlMZqFvdR
# xHhll6qMUcGRCHs81/zngIGZ/fxtymvTwRj2INwcPXwWAK78Sg6ymRCq/baBSEfu
# ZuOpgadL9tANld/QtXesXTPA7I83zbL+sBo4veueQ8MuVkSxGv0iaAOhggIdMIIC
# GQYJKoZIhvcNAQkGMYICCjCCAgYCAQEwgYUwdzELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEhMB8GA1UEAxMYTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# UENBAgphBRM2AAAAAAAaMAcGBSsOAwIaoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3
# DQEHATAcBgkqhkiG9w0BCQUxDxcNMTIwNDA0MTk0MzU3WjAjBgkqhkiG9w0BCQQx
# FgQU8iER9YgiHyI0bgcbIbAOMnDYsScwDQYJKoZIhvcNAQEFBQAEggEAT+a8bdFe
# LNfWODUy+viyTLyTCNtoevdRontgf9e7pns5hB+ZwoS+h9gkgCGyUrborlRUFw2B
# LTqB7GBwZB9kwS/TTvRvOSXBLS9BVFP6jnQ60IrN21A0HV3uSmJ4pN4mXHj9ItnI
# 0uK1JVxpDi4sfQRqK0t99wlNesAAJYIgOqBy7RuZ9mYT4IV8+37Myn4coS15NPtp
# H7eWUbgxgxZ/Tfj0TJ+LGkyGUjPSwDKJSGKS43U0g/OET6j+oSNiabnDhQ/oXjNK
# SzqHbbWn7X4rctX56Zh/qpUl5fpfikgYqu8bAi24KaYoWMYNuXyw0J28iHczepyA
# Zn13kB+uw/imwA==
# SIG # End signature block