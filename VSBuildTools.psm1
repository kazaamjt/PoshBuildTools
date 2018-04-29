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
   Linking functionality now included!
#>
function New-Binary {
    param(
        [cmdletbinding()]
        [parameter(mandatory=$true, position=0)] [string]$Source,

        # Make sure this includes '.exe'.
        # Defaults to using the same name the source file has.
        [parameter(mandatory=$false)] [string]$BinaryName,

        # The folder where the bin and obj folders will be created.
        # Defaults to using the folder of the source file.
        [parameter(mandatory=$false)] [string]$OutputFolder,

        # Folder where the binaries will be placed. Is created if it does not exist.
        # It's full path is $OutputFolder\$BinarydFolderName.
        [parameter(mandatory=$false)] [string]$BinaryFolderName="bin",

        # Folder where the objects will be placed. Is created if it does not exist.
        # It's full path is $OutputFolder\$ObjectFolderName.
        [parameter(mandatory=$false)] [string]$ObjectFolderName="obj",
        [parameter(mandatory=$false)] [string]$Include,
        [parameter(mandatory=$false)] [string]$Libraries,
        [switch] $CreateDebugObjects,

        [parameter(mandatory=$false)]
        [ValidateSet('ARM','EBC','X64','X86')] $TargetPlatform,

        # Args should takes a string as argument, any cl parameter will work with this param. (Even multiple)
        # These arguments will be Added BEFORE the /LINK block. (If /LINK is used at all)
        # Example: "/CGTHREADS:4 /INTEGRITYCHECK"
        [parameter(mandatory=$false)] [string]$CompilerArgs,

        # Works in the same way as $CompilerArgs.
        # These parameters will be passed after the /LINK parameter.
        [parameter(mandatory=$false)] [string]$LinkerArgs
    )

    process
    {
        if (!(Test-Path $Source -ErrorAction SilentlyContinue)) {throw "No such file: $Source"}
        $AbsolutePathSource = (Resolve-Path $Source).Path
        $SourceName = Split-Path $AbsolutePathSource -Leaf
        $SourceDir = Split-Path $AbsolutePathSource -Parent

        $CMD = "cl $SourceName"

        if ($Libraries) {
            foreach ($lib in $Libraries) {
                $CMD += " $lib"
            }
        }

        if ($TargetPlatform) {
            $CMD += " /MACHINE:$TargetPlatform"
        }

        if ($CreateDebugObjects) {
            $CMD += ' -Zi'
        }

        if ($Include) {
            foreach ($Dir in $Include) {
                $CMD += " /I $Dir"
            }
        }

        if (!$OutputFolder) {
            $OutputFolder = $SourceDir
        }

        if (!(Test-Path $OutputFolder)) {
            New-Item $OutputFolder -ItemType Directory -Force
        }

        $AbsoluteOutputPath = (Resolve-Path $OutputFolder).Path
        $AbsoluteObjOutputPath = $AbsoluteOutputPath + "\" + ($ObjectFolderName.Replace("\","")) + "\"
        $AbsoluteBinOutputPath = $AbsoluteOutputPath + "\" + ($BinaryFolderName.Replace("\","")) + "\"

        if (!(Test-Path $AbsoluteObjOutputPath)) {
            New-Item $AbsoluteObjOutputPath -ItemType Directory -Force
        }

        $CMD += " /Fo`"$AbsoluteObjOutputPath\`""

        if ($CompilerArgs) {
            $CMD += " $CompilerArgs"
        }

        # Linker args
        $CMD += " /link"

        if (!(Test-Path $AbsoluteBinOutputPath)) {
            New-Item $AbsoluteBinOutputPath -ItemType Directory -Force
        }

        if (!$BinaryName) {
            $BinaryName = [io.path]::GetFileNameWithoutExtension($SourceName) + ".exe"
        }

        $CMD += " /OUT:`"$AbsoluteBinOutputPath$BinaryName\`""

        if ($LinkerArgs) {
            $CMD += " " + $LinkerArgs
        }

        # output created command
        Push-Location -Path $SourceDir
        Write-Verbose "Running the following command: $CMD"
        Invoke-Expression $CMD
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
