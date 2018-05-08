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

    $VSWHERE = &"$PSScriptRoot\VSWHERE.exe" -products *
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
   Linking functionality now included!
#>
function New-Binary {
    param(
        [cmdletbinding()]
        [parameter(mandatory=$true, position=0)] [string[]]$SourceFiles,

        # Wrapper for /Fe option or the linkers /OUT param if linker option are use.
        # Accepts either a path or a name.
        [parameter(mandatory=$false)] [string]$BinaryName,

        # Wrapper for /Fo option, setting a path or naming the Objects.
        [parameter(mandatory=$false)] [string]$ObjectName,

        # Takes a list of strings as input. Wrapper for the /I cl-parameter.
        [parameter(mandatory=$false)] [string[]]$Include,

        # Takes a list of .lib files.
        [parameter(mandatory=$false)] [string[]]$Libraries,
        [switch] $CreateDebugObjects,

        [parameter(mandatory=$false)]
        [ValidateSet('ARM','EBC','X64','X86')] $TargetPlatform,

        # Makes a DLL instead of an exe.
        [parameter(mandatory=$false)]
        [switch]$DLL,

        # Args takes a string as argument, any cl parameter will work with this param. (Even multiple)
        # These arguments will be Added BEFORE the /LINK block. (If /LINK is used at all)
        # Example: "/CGTHREADS:4 /INTEGRITYCHECK"
        [parameter(mandatory=$false)] [string]$CompilerArgs,
        
        # Works in the same way as $CompilerArgs.
        # These parameters will be passed after the /LINK parameter.
        [parameter(mandatory=$false)] [string]$LinkerArgs
    )

    process
    {
        $CMD = "cl"

        foreach ($Source in $SourceFiles) {
            if (!(Test-Path $Source -ErrorAction SilentlyContinue)) {throw "No such file: $Source"}
            $AbsolutePathSource = (Resolve-Path $Source).Path
            $CMD +=  " `'$AbsolutePathSource`'"
        }

        if ($LinkerArgs) {
            $SeperateLink = $true
        }

        if ($Libraries) {
            foreach ($lib in $Libraries) {
                $CMD += " `"$lib`""
            }
        }

        if ($TargetPlatform) {
            $CMD += " /MACHINE:$TargetPlatform"
        }

        if ($CreateDebugObjects) {
            $CMD += ' /Zi'
        }

        if ($Include) {
            foreach ($Dir in $Include) {
                $CMD += " /I `"$Dir\`""
            }
        }

        if ($ObjectName) {
            $CMD += " /Fo `'$ObjectName`'"
        }

        if ($SeperateLink) {
            $CMD += " /LINK"

            if ($BinaryName) {
                $CMD += " /OUT:`'$BinaryName`'"
            }

            if ($DLL) {
                $CMD += " /DLL"
            }

        } else {

            if ($BinaryName) {
                $CMD += " /Fe `'$BinaryName`'"
            }

            if ($DLL) {
                $CMD += " /LD"
            }
        }

        if ($LinkerArgs) {
            $CMD += " " + $LinkerArgs
        }

        # output created command
        Write-Verbose "Running the following command: `n$CMD"
        Invoke-Expression $CMD
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
