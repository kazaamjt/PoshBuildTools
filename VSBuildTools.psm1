# Function to enable cl.exe in PowerShell
# Basicly turns all the environment variables from the CMD format to the PS "env:"-format.
function Invoke-BatchFile ($file) {
    $cmd = "`"$file`" & set"
    cmd /c $cmd | Foreach-Object {
        $p, $v = $_.split('=')
        if($p -and $v){
            Set-Item -path env:$p -value $v
        }
    }
}

# Use VSWHERE to find VSVersion and return it's output as a PS object
function Get-VisualStudio {
    $VS = New-Object -TypeName PSObject

    $VSWHERE = . "$PSScriptRoot\VSWHERE.exe"
    $VSWHERE[0] = ''
    $VSWHERE[1] = ''

    foreach ($Line in $VSWHERE){
        if ($Line) {
            $SplitLine = $Line.split(':')
            if ($SplitLine[0] -eq 'installationPath'){
                $SplitLine[1] += ':'
                $SplitLine[1] += $SplitLine[2]
            }
            $VS | Add-Member -Name ($SplitLine[0].trim()) -MemberType Noteproperty -Value ($SplitLine[1].trim())
        }
    }

    return $VS
}

function Enable-VSBuildTools{
    param(
        [parameter(mandatory=$false)]
        [ValidateSet('x86', 'amd64', 'arm', 'arm64')]
        $OutputArchitecture,

        [parameter(mandatory=$false)]
        [ValidateSet('x86', 'amd64')]
        $Compiler
    )

    process
    {
        $VS = Get-VisualStudio
        $VCPath = $VS.installationPath + '\VC\Auxiliary\Build\'
        switch ($OutputArchitecture){
            'x86'{
                if ($Compiler -eq 'amd64'){
                    $Bat = "vcvarsamd64_x86.bat"
                }  else {
                    $Bat = "vcvars32.bat"
                }
                break
            }
            'amd64'{
                if ($Compiler -eq 'amd64'){
                    $Bat = "vcvars64.bat"
                }  else {
                    $Bat = "vcvarsx86_amd64.bat"
                }
                break
            }
            'arm'{
                if ($Compiler -eq 'amd64'){
                    $Bat = "vcvarsamd64_arm.bat"
                }  else {
                    $Bat = "vcvarsx86_arm.bat"
                }
                break
            }
            'arm64'{
                if ($Compiler -eq 'amd64'){
                    $Bat = "vcvarsamd64_arm64.bat"
                }  else {
                    $Bat = "vcvarsx86_arm64.bat"
                }
                break
            }
            default {
                switch ($Compiler){
                    "x86" { }
                    "amd64" { }
                    default { $Bat = "vcvarsall.bat"; break }
                }
                break
            }
        }

        Invoke-BatchFile -file ($VCPath + $Bat)
    }
}

<#
.Synopsis
   Compiles a C or visual C++ file using cl.exe.
#>
function New-Binary {
    param(
        [cmdletbinding()]
        [parameter(mandatory=$true)] $Source,
        [parameter(mandatory=$false)] $OutputFolder,
        [parameter(mandatory=$false)] $Link,
        [parameter(mandatory=$false)] $Include,

        [parameter(mandatory=$false)]
        [ValidateSet('ARM','EBC','X64','X86')] $TargetPlatform,

        # Args should takes a string as argument, any cl parameter will work with this param. (Even multiple)
        # Example: "/CGTHREADS:4 /INTEGRITYCHECK"
        [parameter(mandatory=$false)] $Args,
        [switch] $CreateDebugObjects
    )

    process
    {
        if (!(Test-Path $Source -ErrorAction SilentlyContinue)) {throw "No such file."}
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

        if ($Include) {
            foreach ($Dir in $Include) {
                $IncludeParams += "/I $Dir "
            }
        }
        # output created command
        Write-Verbose "Running the following command: cl $DebugParams $Source $Link $TargetPlatformParams"
        if ($OutputFolder -ne $null){
            Write-Verbose "Placing binaries in: $AbsolutePathOutput"
        }

        cl $DebugParams $AbsolutePathSource $Link $TargetPlatformParams $IncludeParams $Args
        Pop-Location
    }
}

function Debug-Binary {
    param(
        [parameter(mandatory=$true)] $Path
    )

    process
    {
        devenv $Path
    }
}

# Only export usefull functions
Export-ModuleMember Get-VisualStudio
Export-ModuleMember Enable-VSBuildTools
Export-ModuleMember New-Binary
Export-ModuleMember Debug-Binary
