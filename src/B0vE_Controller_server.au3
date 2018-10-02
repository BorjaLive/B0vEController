#include <File.au3>
#include <Constants.au3>
#include <Crypt.au3>
#include <String.au3>

TCPStartup()
Global $socket = -1
Global $socketAUX = -1
Global $listen = TCPListen("192.168.1.6", "44144",100)
Global $files_dir = @WorkingDir&"\UPLOADS"
Global $stext_dir = @WorkingDir&"\SText"


While True
   If $socket = -1 Then
	  Do
		 $socket = TCPAccept($listen)
	  Until $socket <> -1
	  _TCPsend("HELLO")
	  If _TCPrecive() = "WORLD!" Then
		 _TCPsend("BOKEY")
	  Else
		 _TCPsend("ERROR")
		 TCPCloseSocket($socket)
		 $socket = -1
	  EndIf
   Else
	  $socketAUX = TCPAccept($listen)
	  If $socketAUX <> -1 Then
		 _TCPsend("DISSCONECT")
		 $socket = $socketAUX
		 $socketAUX = -1
		 _TCPsend("HELLO")
		 If _TCPrecive() = "WORLD!" Then
			_TCPsend("BOKEY")
		 EndIf
	  EndIf

	  $order = TCPRecv($socket,4096)
	  Switch StringMid($order,1,3)
		 Case "PIN":
			_TCPsend("PON")
		 Case "UPL":
			$info = StringSplit($order, ":")
			$file = $files_dir&$info[3]&$info[2]
			If Not FileExists($files_dir&$info[3]) Then DirCreate($files_dir&$info[3])
			$size = $info[4]
			$chunck = $info[5]
			$total = 0
			$stream = FileOpen($file, 16 + 2 + 8)
			_TCPsend("BOK")
			$wait = TimerInit()
			$error = false
			Do
			   $data = TCPRecv($socket, $chunck * 1024, 1)
			   If TimerDiff($wait) >= 5000 Then
				  $error = true
				  ExitLoop
			   EndIf
			   If $data <> "" Then
				  $wait = TimerInit()
				  FileWrite($stream, $data)
				  $total += BinaryLen($data)
				  _TCPsend("BOK")
			   EndIf
			Until $total = $size
			Sleep(1000)
			FileClose($stream)
			If $error Then FileDelete($file)
		 Case "SND":
			$info = StringSplit($order, ":")
			$file = $files_dir&$info[3]&$info[2]
			If Not FileExists($files_dir&$info[3]) Then DirCreate($files_dir&$info[3])
			$size = $info[4]
			$chunck = $info[5]
			$total = 0
			$stream = FileOpen($file, 16 + 2 + 8)
			_TCPsend("BOK")
			Do
			   $data = TCPRecv($socket, $chunck * 1024, 1)
			   FileWrite($stream, $data)
			   $total += BinaryLen($data)
			Until $total = $size
			FileClose($stream)
			_TCPsend("END")
		 Case "DCR":
			DirCreate($files_dir&StringTrimLeft($order,4))
			_TCPsend("BOK")
		 Case "DRM":
			DirRemove($files_dir&StringTrimLeft($order,4),1)
			_TCPsend("BOK")
		 Case "DLS":
			$folders = _FileListToArray($files_dir&StringTrimLeft($order,4),"*")
			If $folders = "" Then
			   _TCPsend("EMPTY")
			Else
			   $list = ""
			   For $i = 1 To $folders[0]
				  $list &= $folders[$i]&"|"
			   Next
			   _TCPsend(StringTrimRight($list,1))
			EndIf
		 Case "7ZA":
			$folder = $files_dir&StringTrimLeft($order,4)
			$name = StringTrimLeft($folder,StringInStr($folder,"\",0,-1))
			RunWait('7Za a '&$name&'.zip "'&$folder&'\"',$files_dir)
			_TCPsend("BOK")
		 Case "7ZE":
			$folder = $files_dir&StringTrimLeft($order,4)
			$path = StringTrimRight($folder,StringLen($folder)-StringInStr($folder,"\",0,-1))
			$name = $files_dir&StringTrimLeft($order,4)
			RunWait('7Za x -aoa -o"'&$path&'" "'&$name&'"')
			_TCPsend("BOK")
		 Case "DMV":
			DirMove($files_dir&StringSplit($order,":")[2],$files_dir&StringSplit($order,":")[3])
			_TCPsend("BOK")
		 Case "MOV":
			FileMove($files_dir&StringSplit($order,":")[2],$files_dir&StringSplit($order,":")[3])
			_TCPsend("BOK")
		 Case "DEL":
			FileDelete($files_dir&StringSplit($order,":")[2])
			_TCPsend("BOK")
		 Case "EXE":
			If StringSplit($order,":")[5] = "WAIT" Then
			   $pid = ShellExecuteWait($files_dir&StringSplit($order,":")[2],$files_dir&StringSplit($order,":")[3],$files_dir&StringSplit($order,":")[4])
			Else
			   $pid = ShellExecute($files_dir&StringSplit($order,":")[2],$files_dir&StringSplit($order,":")[3],$files_dir&StringSplit($order,":")[4])
			EndIf
			_TCPsend($pid)
		 Case "RUN":
			$cmd = Run(@ComSpec & " /c "&StringSplit($order,":")[2], "", @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
			ProcessWaitClose($cmd)
			$msg = StdoutRead($cmd)
			_TCPsend($msg)
		 Case "DWN":
			$file = $files_dir&StringSplit($order,":")[3]
			If Not FileExists($file) Then
			   _TCPsend("EMPTY")
			Else
			   $name = StringTrimLeft($file,StringInStr($file,"\",0,-1))
			   $size = FileGetSize($file)&" "
			   $chunk = StringSplit($order,":")[4]
			   _TCPsend($name&"|"&$size)
			   $stream = FileOpen($file, 16)
			   $total = 0
			   _TCPrecive()
			   If StringSplit($order,":")[2] = "S" Then
				  Do
					 $data = FileRead($stream, $chunk * 1024)
					 $total += TCPSend($socket,$data)
					 If $data <> "" Then
						$response = _TCPrecive()
						If StringInStr($response,"BOK") == 0 Then
						   $error = True
						   ExitLoop
						EndIf
					 EndIf
					 Sleep(5)
				  Until $data = ""
			   Else
				   Do
					 $data = FileRead($stream, $chunk * 1024)
					 $total += TCPSend($socket,$data)
				  Until $data = ""
			   EndIf
			   FileClose($stream)
			EndIf
		 Case "CRY":
			_TCPsend(_Crypt_HashFile ($files_dir&StringSplit($order,":")[2],$CALG_MD5)&" ")
		 Case "STC":
			$key = StringSplit($order,":")[2]
			$text = StringSplit($order,":")[3]&"B0vE"
			$name = StringSplit($order,":")[4]
			$cry = _Crypt_EncryptData($text,$key,$CALG_AES_256)
			If FileExists($stext_dir&"\"&$name&".B0vE") Then
			   _TCPsend("NANAI")
			Else
			   FileWrite($stext_dir&"\"&$name&".B0vE",$cry)
			   _TCPsend("BOK")
			EndIf
		 Case "STD":
			$key = StringSplit($order,":")[2]
			$name = StringSplit($order,":")[3]
			$text = _HexToString(_Crypt_DecryptData(FileRead($stext_dir&"\"&$name&".B0vE"),$key,$CALG_AES_256))
			If StringTrimLeft($text,StringLen($text)-4) = "B0vE" Then
			   FileDelete($stext_dir&"\"&$name&".B0vE")
			   _TCPsend("BOK")
			Else
			   _TCPsend("NANAI")
			EndIf
		 Case "STR":
			$key = StringSplit($order,":")[2]
			$name = StringSplit($order,":")[3]
			$text = _HexToString(_Crypt_DecryptData(FileRead($stext_dir&"\"&$name&".B0vE"),$key,$CALG_AES_256))
			If FileExists($stext_dir&"\"&$name&".B0vE") Then
			   If StringTrimLeft($text,StringLen($text)-4) = "B0vE" Then
				  _TCPsend(StringTrimRight($text,4))
			   Else
				  _TCPsend("NANAI")
			   EndIf
			Else
			   _TCPsend("EMPTY")
			EndIf
		 Case "STS":
			$files = _FileListToArray($stext_dir,"*.B0vE",1)
			If $files = "" Then
			   _TCPsend("EMPTY")
			Else
			   $all = ""
			   For $i = 1 To $files[0]
				  $all &= StringTrimRight($files[$i],5)&", "
			   Next
			   _TCPsend(StringTrimRight($all,2))
			EndIf
		 Case "STI":
			$name = StringSplit($order,":")[2]
			If FileExists($stext_dir&"\"&$name&".B0vE") Then
			   _TCPsend(FileRead($stext_dir&"\"&$name&".B0vE"))
			Else
			   _TCPsend("NANAI")
			EndIf
		 Case "STY":
			$files = _FileListToArray($stext_dir,"*.B0vE",1)
			If $files = "" Then
			   _TCPsend("EMPTY")
			Else
			   For $i = 1 To $files[0]
				  _TCPsend($files[$i]&"|"&FileRead($stext_dir&"\"&$files[$i]))
				  _TCPrecive()
			   Next
			   _TCPsend("END")
			EndIf
		 Case "DIS":
			TCPCloseSocket($socket)
			$socket = -1
	  EndSwitch
   EndIf
WEnd


Func _TCPrecive()
   Do
	  $data = TCPRecv($socket,4096)
	  Sleep(100)
   Until $data <> ""
   Return $data
EndFunc
Func _TCPsend($text)
   TCPSend($socket,$text)
EndFunc