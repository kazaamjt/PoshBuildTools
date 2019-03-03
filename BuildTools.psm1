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

		# Sets the optimization level:
		# - Small or O1: favor smaller executables and libraries
		# - Fast or O2: favor faster code, with a possible larger footprint
		# - Disabled and Od: Disable optimizations
		[ValidateSet('Small', 'Fast', 'Disabled', 'O1', 'O2', 'Ox', 'Od')]
		$Optimization,

		# Wrapper for /Fe option or the linkers /OUT param if linker options are used.
		# The relative or absolute path and base file name,
		# or relative or absolute path to a directory,
		# or base file name to use for the generated executable.
		[string]$ExecutableName,

		# Changes the root where cl will output it's objects and binaries
		[string]$OutputDirectory,

		# Wrapper for /Fo option, setting a path or or naming the Objects
		[string]$ObjectName,

		# Wrapper for the /I parameter.
		[string[]]$Include,

		# Takes a list of .lib files.
		[string[]]$Libraries,

		# Wether or not debug objects should be created.
		[switch]$CreateDebugObjects,

		# Changes the target output platform
		[ValidateSet('ARM','EBC','X64','X86')]$TargetPlatform,

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
		[string[]]$LinkerArgs
	)

	begin {
		Enable-BuildToolsModule
	}

	process {
		# Check if all Source files are correct
		Write-Debug "Checking all source files"
		$Sources = @()
		foreach ($Source in $SourceFiles) {
			if (!(Test-Path $Source -ErrorAction SilentlyContinue)) {
				throw "No such file: $Source"
			} else {
				$Sources += (Resolve-Path $Source).Path
			}
		}
		# Check if linker arguments are superate
		if ($LinkerArgs) {
			$SeperateLinking = $true
			$LinkParams = @()
		}
		$Params = @($Sources, '/nologo')

		switch ($Optimization) {
			{$_ -in 'Small', 'O1'} { $Params += '/O1'; break; }
			{$_ -in 'Fast', 'O2'} { $Params += '/O2'; break; }
			{$_ -in 'Disabled', 'Od'} { $Params += '/Od'; break; }
			{$_ -eq 'Ox'} { $Params += '/Ox'; break; }
			Default {}
		}

		if ($ExecutableName) {
			if ($SeperateLinking) {
				$LinkParams += "/OUT:$ExecutableName"
			} else {
				$Params += "/Fe:$ExecutableName"
			}
		}

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
					throw "Could not include, no such directory: $Dir"
				}
			}
		}

		if ($ObjectName) {
			$Params += ("/Fo:$ObjectName")
		}

		if ($OutputDirectory) {
			if (!(Test-Path $OutputDirectory -ErrorAction SilentlyContinue)) {
				New-Item $OutputDirectory -ItemType Directory -Force | Out-Null
			}
			$CurrentDir = Get-Location
			Set-Location $OutputDirectory
		}
		cl.exe $Params
		if ($OutputDirectory) {
			Set-Location $CurrentDir
		}
	}
}
