# Script variables ############################################################
$script:ENABLED = $false

###############################################################################
<#
.Synopsis
	Sets up the environment for the use of the MS VS build tools (like vcvars*.bat)

.DESCRIPTION
	Sets up the environment for the use of the VisualStudio build tools
	(in a similar way to the vcvars*.bat scripts)
	You should only run this if you want to target different compiler or output targets

.EXAMPLE
	Enable-BuildToolsModule -OutputArchitecture amd64

.NOTES
	All cmdlets in this module will execute this cmdlet automatically if they require it
	Will only set up the environment once, unless -Force is used

.COMPONENT
	POSH-BuildTools
#>
function Enable-BuildToolsModule {
	[CmdletBinding()]
	param (
		# Sets the default compiler output architexture to the indicated value
		[ValidateSet('x86', 'amd64', 'arm', 'arm64')]
		[string]$OutputArchitecture,

		# Sets the compiler version to the indicated value
		[ValidateSet('x86', 'amd64')]
		[string]$Compiler,

		# Path to your local installation (if omitted, VSWhere is invoked to find it)
		[string]$VSPath,

		# Forces a refresh of the PoshBuildTools
		[switch]$Force
	)

	if (!$script:ENABLED -or $Force) {
		if ($Path) {
			$VCPath = $VSPath + '\VC\Auxiliary\Build\'
		} else {
			$VS = &"$PSScriptRoot\VSWHERE.exe" -products * -format json | ConvertFrom-Json
			$VCPath = $VS.installationPath + '\VC\Auxiliary\Build\'
		}

		if (!$Compiler) {
			$Compiler = $env:PROCESSOR_ARCHITECTURE
		}

		if (!$OutputArchitecture) {
			if($Compiler) { $OutputArchitecture = $Compiler }
		}

		switch ($OutputArchitecture){
			'x86' {
				if ($Compiler -eq 'amd64'){
					$Bat = "vcvarsamd64_x86.bat"
				} else {
					$Bat = "vcvars32.bat"
				}
				break
			}

			'amd64' {
				if ($Compiler -eq 'amd64'){
					$Bat = "vcvars64.bat"
				} else {
					$Bat = "vcvarsx86_amd64.bat"
				}
				break
			}

			'arm' {
				if ($Compiler -eq 'amd64'){
					$Bat = "vcvarsamd64_arm.bat"
				} else {
					$Bat = "vcvarsx86_arm.bat"
				}
				break
			}

			'arm64' {
				if ($Compiler -eq 'amd64'){
					$Bat = "vcvarsamd64_arm64.bat"
				} else {
					$Bat = "vcvarsx86_arm64.bat"
				}
				break
			}
		}

		InvokeVCvarsFile -file ($VCPath + $Bat)
		$script:BT_ENABLED = $true
	}
}

# Executes a VCvarsScript
function InvokeVCvarsFile($file) {
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
	Short description
.DESCRIPTION
	Long description
.EXAMPLE
	Example of how to use this cmdlet
.EXAMPLE
	Another example of how to use this cmdlet
.INPUTS
	Inputs to this cmdlet (if any)
.OUTPUTS
	Output from this cmdlet (if any)
.NOTES
	General notes
.COMPONENT
	The component this cmdlet belongs to
.ROLE
	The role this cmdlet belongs to
.FUNCTIONALITY
	The functionality that best describes this cmdlet
#>
function Invoke-VCCompiler {
	[cmdletbinding()]
	param(
		[parameter(mandatory=$true, position=0)] [string[]]$SourceFiles,

		# Wrapper for /Fe option or the linkers /OUT param if linker options are used.
		# Accepts either a path or a name.
		[string]$Output,

		# Wrapper for /Fo option, setting a path or naming the Objects.
		[string]$ObjectName,

		# Takes a list of strings as input. Wrapper for the /I parameter.
		[string[]]$Include,

		# Takes a list of .lib files.
		[string[]]$Libraries,

		[switch]$CreateDebugObjects,

		# Changes the target output platform
		[ValidateSet('ARM','EBC','X64','X86')] $TargetPlatform,

		# Creates a DLL instead of an exe.
		[switch]$DLL,

		# Currently not supportng compiler versions.
		[ValidateSet('Disabled','0','1','2','3','4','All')]
		$WarningLevel,

		# Args takes a list of strings as argument, any cl parameter *should* work with this param.
		# These arguments will be Added BEFORE the /LINK block. (If /LINK is used at all)
		# Example: "/CGTHREADS:4", "/INTEGRITYCHECK"
		[string[]]$CompilerArgs,

		# Works in the same way as $CompilerArgs.
		# These parameters will be passed after the /LINK parameter.
		[parameter(mandatory=$false)] [string[]]$LinkerArgs
	)

	begin {
		Enable-BuildToolsModule
	}

	process {
		foreach ($Source in $SourceFiles) {
			if (!(Test-Path $Source -ErrorAction SilentlyContinue)) {
				throw "No such file: $Source"
			}
		}

		$Params = @($SourceFiles, '/nologo')
		if ($TargetPlatform) {
			$Params += ("/MACHINE:$TargetPlatform")
		}

		if ($CreateDebugObjects) {
			$Params += ('/Zi')
		}

		if ($Include) {
			foreach ($Dir in $Include) {
				if ((Get-Item $Dir) -is [System.IO.DirectoryInfo]) {
					if ($Dir.endswith('\\')) {}
					elseif ($Dir.endswith('\')) { $Dir += '\' }
					else { $Dir += '\\' }
					$Params += ("/I $Dir")
				} else {
					throw "Could not include: $Dir (invalid path)"
				}
			}
		}

		if ($ObjectName) {
			$Params += ("/Fo `'$ObjectName`'")
		}
		cl.exe $Params
	}
}
