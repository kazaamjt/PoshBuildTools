# Function to enable cl.exe in PowerShell
# Basicly turns all the environment variables from the CMD format to the PS "env:"-format.
function Get-BatchFile ($file) {
    $cmd = "`"$file`" & set"
    cmd /c $cmd | Foreach-Object {
        $p, $v = $_.split('=')
        if($p -and $v){
            Set-Item -path env:$p -value $v
        }
    }
}

<#
.Synopsis
   Compiles a C or visual C++ file using cl.exe.
#>
function New-Binary {
    param(
        [Alias("Build")]
        [cmdletbinding()]
        [parameter(mandatory=$true)] $Source,
        [parameter(mandatory=$false)] $OutputFolder,
        [parameter(mandatory=$false)] $Link,

        [parameter(mandatory=$false)]
        [ValidateSet('ARM','EBC','X64','X86')] $TargetPlatform,

        # Args should takes a string as argument, any cl parameter will work with this param. (Even multiple)
        # Example: "/CGTHREADS:4 /INTEGRITYCHECK"
        [parameter(mandatory=$false)] $Args,
        [switch] $CreateDebugObjects
    )

    process
    {
        $AbsolutePathSource = (Resolve-Path $Source).Path
        
        if ($OutputFolder -ne $null){
            $AbsolutePathOutput = Resolve-Path $OutputFolder
            Push-Location $AbsolutePathOutput
        }

        if ($TargetPlatform){
            $TargetPlatformParams = "/MACHINE:$TargetPlatform"
        }

        if ($CreateDebugObjects){
            $DebugParams = '-Zi'
        }
        # output created command
        Write-Verbose "Running the following command: cl $DebugParams $Source $Link $TargetPlatformParams"
        if ($OutputFolder -ne $null){
            Write-Verbose "Placing binaries in: $AbsolutePathOutput"
        }

        cl $DebugParams $AbsolutePathSource $Link $TargetPlatformParams $Args
        Pop-Location
    }
}

function Debug-Binary {
    param(
        [Alias("Debug")]
        [parameter(mandatory=$true)] $Path
    )

    process
    {
        devenv $Path
    }
}