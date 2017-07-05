# Function to link CL to PS
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
   Compiles a C or C++ file
#>
function Start-CompilingFromSource{
    param(
        [Alias("Build")]
        [cmdletbinding()]
        [parameter(mandatory=$true)] $Source,
        [parameter(mandatory=$false)] $OutputFolder,
        [parameter(mandatory=$false)] $Link,

        [parameter(mandatory=$false)]
        [ValidateSet('ARM','EBC','X64','X86')] $TargetPlatform,

        # Args shoudl takes a string as argument, any cl paraemeter will work in this.
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

function Debug-Binary{
    param(
        [Alias("Debug")]
        [parameter(mandatory=$true)] $Path
    )

    process
    {
        devenv $Path
    }
}