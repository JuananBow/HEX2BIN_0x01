#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=_res\1_icon.ico
#AutoIt3Wrapper_Outfile=0x01.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Comment=Converts Intel HEX files to BIN
#AutoIt3Wrapper_Res_Description=Converts Intel HEX files to BIN
#AutoIt3Wrapper_Res_Fileversion=0.5.3.16
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=p
#AutoIt3Wrapper_Res_CompanyName=JuananBow
#AutoIt3Wrapper_Res_LegalCopyright=JuananBow
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <Array.au3>
#include <File.au3>
#include <MsgBoxConstants.au3>
#include <String.au3>

;Debug (Comment this area before compiling)
;~ Global $CmdLine = [ 0 , "tl_main1.hex", "-signed" ]
;~ _ArrayDisplay ($CmdLine)


Global $CmdLineParam = UBound ($CmdLine) - 1 ; -1 to match the CmdLine array indexes
Global $iCmdLineParamOffset = _ArraySearch($CmdLine, "-offset", 0,0,0,3)
Global $iCmdLineParamSigned = _ArraySearch($CmdLine, "-signed", 0,0,0,3)
ConsoleWrite ( "0x01 by JuananBow" & " (v" & FileGetVersion ( @ScriptFullPath ) & ")" & @CRLF)
ConsoleWrite ( "Converts Intel .HEX files to .BIN" & @CRLF & @CRLF )

If $CmdLineParam < 1 Then
	ConsoleWrite ( "Usage: " & @ScriptName & " <Input file>.hex [-offset<hex>] [-signed]" & @CRLF )
	Exit
EndIf

;File Operations
Local $hFileSource = FileOpen($CmdLine[1], 0)
If $hFileSource = -1 Then
    ConsoleWrite($CmdLine[1] & ": Unable to open file.")
    Exit
EndIf

Local $sFileSourceLName = FileGetLongName ( $CmdLine[1] ) 															; Source file full path
Local $sFileOutLName = ( StringLeft ( $CmdLine[1], (( StringInStr ( $CmdLine[1], "." , 0 , -1 ))-1)) & ".bin" )		; Destination file .bin
;MsgBox ( 0, "", $sFileOutLName )
Local $iFileSourceLength = _FileCountLines ( $hFileSource )
ConsoleWrite ( "Source file: " & $sFileSourceLName & " ; " & $iFileSourceLength & " lines" & @CRLF )

Local $hFileOut = FileOpen($sFileOutLName , 17)
If $hFileOut = -1 Then
    ConsoleWrite($sFileOutLName & ": Unable to open file.")
    Exit
EndIf

;Offsets
If $iCmdLineParamOffset > 1 Then
	Switch StringMid ( $CmdLine[$iCmdLineParamOffset], 8, 1 )
		Case "-"
			Local $dSourceDataAddressOffset = - dec (StringMid ( $CmdLine[$iCmdLineParamOffset], 9))
			ConsoleWrite ( "Offset: -0x" & hex ("0x" & StringMid ( $CmdLine[$iCmdLineParamOffset], 9)) & @CRLF )
		Case "+"
			Local $dSourceDataAddressOffset = + dec (StringMid ( $CmdLine[$iCmdLineParamOffset], 9))
			ConsoleWrite ( "Offset: +0x" & hex ("0x" & StringMid ( $CmdLine[$iCmdLineParamOffset], 9)) & @CRLF )
		Case Else
			Local $dSourceDataAddressOffset = + dec (StringMid ( $CmdLine[$iCmdLineParamOffset], 8))
			ConsoleWrite ( "Offset: +0x" & hex ("0x" & StringMid ( $CmdLine[$iCmdLineParamOffset], 8)) & @CRLF )
	EndSwitch
Else
	Local $dSourceDataAddressOffset = dec (0)
EndIf

;Signed Addresses
If $iCmdLineParamSigned > 1 Then
	Local $dSourceDataExtAddressOffset = 8
	Local $dSourceDataLinAddressOffset = 32768
	ConsoleWrite ( "Signed Addresses: YES" & @CRLF )
Else
	Local $dSourceDataExtAddressOffset = 16
	Local $dSourceDataLinAddressOffset = 65536
EndIf

;HEX2BIN
Local $hTimer = TimerInit()
Local $iFileSourceReadLoop = 1
Local $dSourceDataExtAddress = 0
Local $dSourceDataLinAddress = 0
While $iFileSourceReadLoop <= $iFileSourceLength

	Local $sSourceLine 			= FileReadLine ( $hFileSource , $iFileSourceReadLoop )
	Local $iLengthSourceLine 	= StringLen ( $sSourceLine )
	Local $dSourceDataBytes 	= Dec (StringMid ( $sSourceLine, 2 , 2 ))
	Local $dSourceDataLength 	= $dSourceDataBytes * 2
	Local $dSourceDataAddress 	= Dec( StringMid ( $sSourceLine, 4 , 4 )) + ( $dSourceDataExtAddress) + ( $dSourceDataLinAddress) + ($dSourceDataAddressOffset)
	Local $sSourceData 			= StringMid ( $sSourceLine, 10 , $dSourceDataLength )
	Local $dSourceExtended 		= StringMid ( $sSourceLine, 8 , 2 )

	Switch $dSourceExtended
		Case 00 ;Normal write
			FileSetPos($hFileOut, $dSourceDataAddress, 0)
			FileWrite($hFileOut, ("0x" & $sSourceData) )
			ConsoleWrite ( "Line: " & $iFileSourceReadLoop & " / " & $iFileSourceLength & "   Data: " & $dSourceDataBytes & "bytes @ 0x" & hex( $dSourceDataAddress) & "  =  " & $sSourceData & @CRLF )
		Case 01 ;EOF
			ConsoleWrite ( "Line: " & $iFileSourceReadLoop & " / " & $iFileSourceLength & "   Data: EOF (:00000001FF)" & @CRLF)
			ExitLoop
		Case 02 ;Extended Segment Address
			Local $dSourceDataExtAddress = dec ($sSourceData) * $dSourceDataExtAddressOffset
			ConsoleWrite ( "Line: " & $iFileSourceReadLoop & " / " & $iFileSourceLength & "   Data: (" & $dSourceExtended & ") Extended Segment Address   New address offset: " & "0x" & hex( $dSourceDataExtAddress) & @CRLF )
		Case 04 ;Extended Linear Address
			Local $dSourceDataLinAddress = dec ($sSourceData) * $dSourceDataLinAddressOffset
			ConsoleWrite ( "Line: " & $iFileSourceReadLoop & " / " & $iFileSourceLength & "   Data: (" & $dSourceExtended & ") Extended Linear Address   New address offset: " & "0x" & hex( $dSourceDataExtAddress) & @CRLF )
	EndSwitch

;~ 	MSGBOX (0, "", ( "0x" & hex(dec( StringMid ( $sSourceLine, 4 , 4 ))) & " + " & "0x" & hex( $dSourceDataExtAddress) & " + " & "0x" & hex( $dSourceDataAddressOffset) & @CRLF & "0x" & hex( $dSourceDataAddress) ))

	$iFileSourceReadLoop = $iFileSourceReadLoop + 1
WEnd
Local $fTimerDiff = TimerDiff($hTimer)

FileFlush ( $hFileOut )
Local $iFileOutSize = FileGetSize ( $sFileOutLName )
ConsoleWrite ( @CRLF & @CRLF & @CRLF)
ConsoleWrite ( "File result: " & $sFileOutLName & @CRLF )
ConsoleWrite ( "Size: " & $iFileOutSize & " bytes" & @CRLF )
ConsoleWrite ( "Time: " & ($fTimerDiff / 1000) & " s" & @CRLF )

FileClose($hFileSource)
FileClose($hFileOut)