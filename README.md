PowerShell-VSBuildTools
=======================
This PowerShell module imports and enables compiling with the visual studio CMD in PowerShell.  
    (This didn't exist for whatever reason, I looked long and hard. Maybe not hard enough. Sue me.)

Includes:
 - Integrating VSWhere with PowerShell (Get-VisualStudio)
 - Enabling of CMD tools for Visual Studio in PowerShell(Enable-VSBuildTools)
 - Building  (New-Binary)
 - Debugging (Debug-Binary)

Based on some code originally found here:
https://filebox.ece.vt.edu/~ece1574/spring15/devenvinstall.html

It has been extended to be more portable and more friendly.  
I am open to suggestions for better command names.

How To Use
----------
Import the module (in your PS profile or in a session)  
Then run Enable-VSBuildTools.
You need to run this first before any other functions will work.
	
You can now use the Visual Studio Commands yourself or use the commands provided by the module.
