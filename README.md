PowerShell-VSBuildTools  
=======================  
A Powershell-module that enables the use of cl.exe from the commandline,  
nicely wrapped in a couple of PowerShell-cmdlets.  
Currently works for and is tested on:  
	- Visual Studio 2017 (community, professional and enterprise)  
	- Visual studio 2017 Build Tools  
  
Includes:  
 - Integration VSWhere with PowerShell (Get-VisualStudio)  
 - Enabling of CMD tools for Visual Studio in PowerShell(Enable-BuildTools)  
 - Building  (New-Binary)  
 - Debugging (Debug-Binary, only in case of an actual Visual Studio install)  
  
It has been extended to be more portable and more user-friendly.  
I am open to suggestions for better command names and new features.  
  
How To Use  
----------  
The installer, found under releases, is just a self-extracting 7-Zip file.  
Install it under 'C:\Program Files\WindowsPowerShell\Modules'. (Or 'Program Files(x86) if you use Powershell in x86 mode)  
  
Then open a new PowerShell Session, it should automatically contain the new cmdlets!  
  
**NOTE:**  
Upon running *New-Binary* it will import and execute vcvarsall.bat.  
If this fails due to not finding your Visual Studio, or you are probably using a version of visual studio unsuported by VSWHERE,  
you can manualy enable the build tools by running:  
Enable-BuildTools -Path '/Path/To/VisualStudio'  

TO DO
-----
*Add support for older version of Visual Studio
*Complete the list of parameters for New-Binary to support all CL parameters
*Add support for Csharp compilation (Planned for V2)
