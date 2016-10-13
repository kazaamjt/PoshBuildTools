# This File is an Example of what your PowerShell profile could look like
# Place it in C:\Users\<Your Name>\Documents\WindowsPowerShell

$host.ui.rawui.WindowTitle = "Powershell Visual Studio CommandLine"

# Replace "C:\PowerShell-VSBuildTools\VSBuildTools.psm1" with the location you put the psm file in in.
Import-Module "C:\PowerShell-VSBuildTools\VSBuildTools.psm1" -WarningAction SilentlyContinue

# Replace "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" with the location of your vcvarsall.bat file. (the location below is it's default location.)
Get-BatchFile("C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat")
