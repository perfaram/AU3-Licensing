#cs ----------------------------------------------------------------------------

 Author:         Jefrey S. Santos

 Script Function:
	Example 1: If license is going to expire, it will show "you have X days left". If it's expired, it will ask for serial and won't allow the application to run. Else, won't do anything.

#ce ----------------------------------------------------------------------------

#include "license.au3"
setinfo(True) ; show "you have 10 days left" when the license is gonna expire?

If Not license_registered() Then
   license_warning()
EndIf
