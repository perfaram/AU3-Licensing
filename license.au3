#cs
	License

	coded by Jefrey S. Santos
		<jefreysobreira[at]gmail[dot]com>
	greatly enhanced by Perceval Faramaz, @perfaram
#ce
#include-once
#include <Crypt.au3>
#include <String.au3>
#include <Date.au3>
#include "Includes\TaskDialog.au3"
#include <Crypt.au3>

;~ Configure here
Global $appName = "My nice app" ; your app name
Global $companyName = "My awesome Company"
Global $myURL="http://niceapp.nicesite.tld/path/file.php?key="
Global $almost_ending = True ; will show "you have 10 days left" when license is going to expire?

Func setinfo($status)
	Global $almost_ending = $status
EndFunc

Func license_warning()
	Enum $ID_BTN1 = 1001, $ID_BTN2, $ID_BTN3
	Dim $pnButton, $pnRadioButton, $pfVerificationFlagChecked
	Dim $Buttons[3][2] = [[$ID_BTN1, "Buy "&$appname & @LF & "You will be redirected to "&$appname&" website"], _
			[$ID_BTN2, "Enter Serial" & @LF & "Enter the serial you received"], _
			[$ID_BTN3, "Close" & @LF & $appname&" will exit"]]
	$ret = _TaskDialogIndirectParams($pnButton, $pnRadioButton, $pfVerificationFlagChecked, 0, 0, $TDF_USE_COMMAND_LINKS, 0, $appname, 65529, _
			"Activation Error", "This software isn't licensed."&@CRLF&"Choose one of the following options to continue : ", _
			$Buttons, $ID_BTN1)
	Switch $pnButton
		Case 1001
			ShellExecute($myURL&machineID())
		Case 1002
			$isok=False
			Do
			$serial = InputBox($appName, "Paste the received key below:")
			If @error then
				Exit
			EndIf
			$status = register_serial($serial)
			If $status Then
				$data = serial_validate($serial)
				_TaskDialog(0, 0, $appname&" Activation", $appname&" has been activated.", "Thank you !", 1, 65528)
				$isok=true
			Else
				_TaskDialog(0, 0, $appname&" Activation", "Invalid serial", "Make sure you pasted the entire key !", 1, 65530)
			EndIf
			until $isok=true
		Case 1003
			Exit
	EndSwitch
EndFunc

Func license_registered()
	$serial = getlicense() ; get license file data
	If Not $serial Then Return False ; if there's no data, false
	$info = serial_validate($serial)
	If IsBool($info) Then Return False
	$date_valid = StringSplit($info[2], "/")

	If $almost_ending Then ; function parameter
		$dias = Abs(_DateDiff('D', $date_valid[1] & "/" & $date_valid[2] & "/" & $date_valid[3], _NowCalcDate())) ; how many days are missing to end the license?
		If $dias > 10 Then Return True ; if more than 10 days, already return true. Else...:
		Enum $ID_BTN1 = 1001, $ID_BTN2, $ID_BTN3
		Dim $pnButton, $pnRadioButton, $pfVerificationFlagChecked
		Dim $Buttons[2][2] = [[$ID_BTN1, "Buy a new license"&@LF& "You will be redirected to "&$appname&" website"], _
			[$ID_BTN2, "Enter Serial" & @LF & "Enter the serial you received"]]
		$registernow = _TaskDialogIndirectParams($pnButton, $pnRadioButton, $pfVerificationFlagChecked, 0, 0, $TDF_USE_COMMAND_LINKS, 0, $appname, 65530, _
			"Your license is almost ending !", "Your license for "&$appname&" will end in : "&$dias&" day(s) !"&@CRLF&"Choose one of the following options to continue : ", _
			$Buttons, $ID_BTN1)
		Switch $pnButton
			Case 1001
				ShellExecute($myURL&machineID())
			Case 1002
				$isok=False
				Do
					$serial = InputBox($appName, "Paste the received key below:")
					If @error then
						ExitLoop
					EndIf
						$status = register_serial($serial)
					If $status Then
						$data = serial_validate($serial)
						_TaskDialog(0, 0, $appname&" Activation", $appname&" has been activated.", "Thank you !", 1, 65528)
						$isok=true
					Else
						_TaskDialog(0, 0, $appname&" Activation", "Invalid serial", "Make sure you pasted the entire key !", 1, 65530)
					EndIf
				Until $isok=true
		EndSwitch
	EndIf
	Return True
EndFunc

Func register_serial($serial) ; validates and registers a new serial key
	$info = serial_validate($serial)
	If IsBool($info) Then Return False

	RegDelete("HKEY_CURRENT_USER\Software\"&$companyName&"\"&$appName, "KEY")
	RegWrite("HKEY_CURRENT_USER\Software\"&$companyName&"\"&$appName, "KEY", "REG_SZ", $serial)
	Return True
EndFunc

Func serial_validate($serial) ; validates the serial (returns false for invalid serial or an array (see below) if valid)
	If @OSArch='x86' Then
		$reg='HKEY_LOCAL_MACHINE'
	Else
		$reg='HKEY_LOCAL_MACHINE64'
	EndIf
	$id=RegRead($reg & '\SOFTWARE\Microsoft\Cryptography', 'MachineGuid')
	$id=StringTrimLeft(StringTrimRight($id, 1), 1)
	$decrypted=BinaryToString(_Crypt_DecryptData($serial, $id, $CALG_AES_192))
	$decrypted = StringSplit($decrypted, "\")
	If UBound($decrypted) <> 3 Then Return False
	If $decrypted[1] <> machineID() Then Return False
	$until = StringSplit($decrypted[2], "/")
	If UBound($until) <> 4 Then Return False
	$until = _DateToDayValue($until[1], $until[2], $until[3])
	$now = _DateToDayValue(@YEAR, @MON, @MDAY)
	If $now > $until Then Return False
	Dim $retorno[3]
	$retorno[1] = $decrypted[1] ; user id
	$retorno[2] = $decrypted[2] ; date
	Return $retorno
EndFunc

Func machineID()
	If @OSArch='x86' Then
		$reg='HKEY_LOCAL_MACHINE'
	Else
		$reg='HKEY_LOCAL_MACHINE64'
	EndIf
	$id=RegRead($reg & '\SOFTWARE\Microsoft\Cryptography', 'MachineGuid')
	Return StringTrimLeft(StringTrimRight($id, 1), 1)
EndFunc

Func getlicense() ; get license info from the file
	Return RegRead("HKEY_CURRENT_USER\Software\"&$companyName&"\"&$appName, "KEY")
EndFunc
