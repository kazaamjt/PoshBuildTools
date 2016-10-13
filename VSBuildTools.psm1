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
function Compile-SourceFile{
    param(
        [cmdletbinding()]
        [parameter(mandatory=$true)] $Source,
        [parameter(mandatory=$false)] $OutputFolder,
        [parameter(mandatory=$false)] $Link,
        [switch] $CreateDebugObjects
    )

    process
    {
        $AbsolutePathSource = (Resolve-Path $Source).Path
        
        if ($OutputFolder -ne $null){
            $AbsolutePathOutput = Resolve-Path $OutputFolder
            Push-Location $AbsolutePathOutput
        }

        if ($CreateDebugObjects){
            $DebugParams = '-Zi'
        }
        # output created command
        Write-Verbose "Running the following command: cl $DebugParams $Source $Link"
        if ($OutputFolder -ne $null){
            Write-Verbose "Placing binaries in: $AbsolutePathOutput"
        }

        cl $DebugParams $AbsolutePathSource $Link
        Pop-Location
    }
}

function Debug-Binary{
    param(
        [parameter(mandatory=$true)] $Path
    )

    process
    {
        devenv $Path
    }
}