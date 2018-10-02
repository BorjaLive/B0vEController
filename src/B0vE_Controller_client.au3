#include <GUIConstantsEx.au3>
#include <GUIConstants.au3>
#include <EditConstants.au3>
#include <Array.au3>
#include <Crypt.au3>
#include <String.au3>
#include <File.au3>
#Include <GuiEdit.au3>

#Region SetUp
Opt("GUIOnEventMode", 1)
;Opt("TCPTimeout", 1000)
TCPStartup()
Const $version = "0.9.1 LTE"
Const $shorts[20][2] = [["time","t"],["extended","X"],["force","f"],["location","l"],["name","n"],["clear","c"],["hello","H"],["default","d"],["failsafe","s"],["path","p"],["chunk","C"],["origin","O"],["destination","D"],["wait","w"],["parameters","P"],["key","k"],["text","T"],["autimatic","a"],["file","f"],["binary","b"]]
Const $regkeyPosFile = @AppDataDir&"\B0vEcontrollerRegKey.B0vE"
Global $program = ""
Global $regkey_file = FileRead($regkeyPosFile)
Global $socket = -1
Global $sent_comands[10]
Global $sent_current = -1
startup($regkey_file)
#EndRegion

#Region GUI
$GUI = GUICreate("B0vE Controller", 600, 650)
$GUI_log = GUICtrlCreateEdit("",10,10,580,590,BitOR($ES_READONLY,$ES_AUTOVSCROLL,$WS_VSCROLL))
$GUI_input = GUICtrlCreateInput("",10,610,580,30)
GUICtrlSetFont($GUI_log,12,0,0,"Courier")
GUICtrlSetFont($GUI_input,14,0,0,"Courier")
GUISetOnEvent($GUI_EVENT_CLOSE,"salir")
HotKeySet("{ENTER}","executeC")
HotKeySet("{UP}","_comandAv")
HotKeySet("{DOWN}","_comandRe")
GUISetState(@SW_SHOW)
#EndRegion
$i = 0
While True
   Sleep(100)
WEnd

#Region Functions
Func salir()
   TCPCloseSocket($socket)
   TCPShutdown()
   Exit
EndFunc
Func executeC()
   If GUICtrlRead($GUI_input) = "" Then Return
   $command = _paraseCommand(GUICtrlRead($GUI_input))
   _logAddText($program&">> "&GUICtrlRead($GUI_input))
   _recordComand(GUICtrlRead($GUI_input))
   $sent_current = -1
   GUICtrlSetData($GUI_input,"")
   Switch $program
	  Case "":
		 Switch _getParameter($command,"command")
			Case "version":
			   If _getParameter($command,"X") Then
				  _logAddText("Nombre: B0vE Controller Client"&@CRLF&"Versión actual: "&$version&@CRLF&"Compilado para: "&(@AutoItX64?"x86_64":"x86"))
			   Else
				  _logAddText("Versión actual: "&$version)
			   EndIf
			Case "clear":
			   _logSetText("")
			Case "regkey":
			   Global $old_terminal = GUICtrlRead($GUI_log)
			   _logSetText("--Memoria de registro--"&@CRLF)
			   $program = ">> regkey "
			Case "connet":
			   Global $old_terminal = GUICtrlRead($GUI_log)
			   _logSetText("--Conexión con el servidor--"&@CRLF)
			   $program = ">> connet "
			Case "stext":
			   Global $old_terminal = GUICtrlRead($GUI_log)
			   _logSetText("--SText, textos seguros--"&@CRLF)
			   $program = ">> stext "
			Case "rawcon":
			   Global $old_terminal = GUICtrlRead($GUI_log)
			   _logSetText("--RawCon, conexiones crudas--"&@CRLF)
			   $program = ">> rawcon "
			Case "tmp":
			   If _getParameter($command,"parameter") = "clear" Then
				  DirRemove($keyreg_tmp,1)
				  DirCreate($keyreg_tmp)
				  DirCreate($keyreg_tmp&"\SText")
				  _logAddText("Carpeta temporal vaciada.")
			   ElseIf _getParameter($command,"parameter") = "open" Then
				  Run("C:\WINDOWS\EXPLORER.EXE /n,/e," & $keyreg_tmp)
				  _logAddText("Abriendo carpeta temporal")
			   Else
				  _logAddText("No se reconoce el parametro.")
			   EndIf
			Case "clear":
			   _logSetText("")
			Case "md5":
			   If _getParameter($command,"parameter") Then
				  _logAddText(_Crypt_HashFile (_getParameter($command,"parameter"),$CALG_MD5))
			   Else
				  _logAddText("Falta el parametro.")
			   EndIf
			Case "exit":
			   salir()
			Case Else
			   _logAddText("Comando no reconocido.")
		 EndSwitch
	  Case ">> regkey ":
		 Switch _getParameter($command,"command")
			Case "locate":
			   If _getParameter($command,"X") Then
				  _logAddText("El archivo de registro principal se encuentra en:"&@CRLF&$regkey_file&@CRLF&"El puntero se encuentra en:"&@CRLF&$regkeyPosFile)
			   Else
				  _logAddText("El archivo de registro principal se encuentra en: "&@CRLF&$regkey_file)
			   EndIf
			Case "create":
			   If _getParameter($command,"l") Then
				  $regkey_file = _getParameter($command,"l")
				  If Not FileExists(StringTrimRight($regkey_file,StringLen($regkey_file)-StringInStr($regkey_file,"\",0,-1)+1)) Then
					 DirCreate(StringTrimRight($regkey_file,StringLen($regkey_file)-StringInStr($regkey_file,"\",0,-1)+1))
					 DirCreate($keyreg_tmp&"\SText")
				  EndIf
				  If _getParameter($command,"d") Then
					 Global $keyreg_server = "routerarlin.mooo.com"
					 Global $keyreg_port = "44144"
					 Global $keyreg_tmp = @AppDataDir&"\BovEController\tmp"
					 Global $keyreg_timeout = "5"
					 If Not FileExists($keyreg_tmp) Then
						DirCreate($keyreg_tmp)
						DirCreate($keyreg_tmp&"\SText")
					 EndIf
				  EndIf
				  FileWrite($regkey_file,"server:"&$keyreg_server&@CRLF&"port:"&$keyreg_port&@CRLF&"tmp:"&$keyreg_tmp&@CRLF&"timeout:"&$keyreg_timeout)
				  FileDelete($regkeyPosFile)
				  FileWrite($regkeyPosFile,$regkey_file)
				  _logAddText("El archivo de registro principal fue creado en la dirección proporcionada.")
			   Else
				  If Not FileExists(StringTrimRight($regkey_file,StringLen($regkey_file)-StringInStr($regkey_file,"\",0,-1)+1)) Then
					 DirCreate(StringTrimRight($regkey_file,StringLen($regkey_file)-StringInStr($regkey_file,"\",0,-1)+1))
					 DirCreate($keyreg_tmp&"\SText")
				  EndIf
				  If _getParameter($command,"d") Then
					 Global $keyreg_server = "routerarlin.mooo.com"
					 Global $keyreg_port = "44144"
					 Global $keyreg_tmp = @AppDataDir&"\BovEController\tmp"
					 Global $keyreg_timeout = "5"
					 If Not FileExists($keyreg_tmp) Then
						DirCreate($keyreg_tmp)
						DirCreate($keyreg_tmp&"\SText")
					 EndIf
				  EndIf
				  FileWrite($regkey_file,"server:"&$keyreg_server&@CRLF&"port:"&$keyreg_port&@CRLF&"tmp:"&$keyreg_tmp&@CRLF&"timeout:"&$keyreg_timeout)
				  _logAddText("El archivo de registro principal fue creado en la dirección guardada.")
			   EndIf
			Case "delete":
			   FileDelete($regkey_file)
			   _logAddText("El archivo de registro de la dirección guardada fue borrado.")
			Case "reload":
			   If _getParameter($command,"l") Then
				  $regkey_file = _getParameter($command,"l")
				  $values = FileRead($regkey_file)
				  Global $keyreg_server = _getValueRegKey($values,"server")
				  Global $keyreg_port = _getValueRegKey($values,"port")
				  Global $keyreg_tmp = _getValueRegKey($values,"tmp")
				  Global $keyreg_timeout = _getValueRegKey($values,"timeout")
				  FileDelete($regkeyPosFile)
				  FileWrite($regkeyPosFile,$regkey_file)
				  _logAddText("El registro fue cargado desde la dirección proporcionada.")
			   Else
				  $values = FileRead($regkey_file)
				  Global $keyreg_server = _getValueRegKey($values,"server")
				  Global $keyreg_port = _getValueRegKey($values,"port")
				  Global $keyreg_tmp = _getValueRegKey($values,"tmp")
				  Global $keyreg_timeout = _getValueRegKey($values,"timeout")
				  _logAddText("El registro fue cargado desde la dirección guardada.")
			   EndIf
			Case "change":
			   If _getParameter($command,"parameter") Then
				  $regkey_file = _getParameter($command,"parameter")
				  If Not FileExists(StringTrimRight($regkey_file,StringLen($regkey_file)-StringInStr($regkey_file,"\",0,-1)+1)) Then
					 DirCreate(StringTrimRight($regkey_file,StringLen($regkey_file)-StringInStr($regkey_file,"\",0,-1)+1))
					 DirCreate($keyreg_tmp&"\SText")
				  EndIf
				  If Not FileExists($regkey_file) Then FileWrite($regkey_file,"server:"&$keyreg_server&@CRLF&"port:"&$keyreg_port&@CRLF&"tmp:"&$keyreg_tmp&@CRLF&"timeout:"&$keyreg_timeout)
				  FileDelete($regkeyPosFile)
				  FileWrite($regkeyPosFile,$regkey_file)
			   Else
				  _logAddText("Faltan parámetros.")
			   EndIf
			Case "modify":
			   If _getParameter($command,"parameter") and _getParameter($command,"n") Then
				  Switch _getParameter($command,"n")
					 Case "server":
						$keyreg_server = _getParameter($command,"parameter")
					 Case "port":
						$keyreg_port = _getParameter($command,"parameter")
					 Case "tmp":
						$keyreg_tmp = _getParameter($command,"parameter")
					 Case "timeout":
						$keyreg_timeout = _getParameter($command,"parameter")
				  EndSwitch
				  If Not FileExists(StringTrimRight($regkey_file,StringLen($regkey_file)-StringInStr($regkey_file,"\",0,-1)+1)) Then
					 DirCreate(StringTrimRight($regkey_file,StringLen($regkey_file)-StringInStr($regkey_file,"\",0,-1)+1))
					 DirCreate($keyreg_tmp&"\SText")
				  EndIf
				  FileDelete($regkey_file)
				  FileWrite($regkey_file,"server:"&$keyreg_server&@CRLF&"port:"&$keyreg_port&@CRLF&"tmp:"&$keyreg_tmp&@CRLF&"timeout:"&$keyreg_timeout)
				  If Not FileExists($keyreg_tmp) Then DirCreate($keyreg_tmp)
				  _logAddText("El registro principal fue modificado correctamente.")
			   Else
				  _logAddText("Faltan parámetros.")
			   EndIf
			Case "check":
			   If FileExists($regkeyPosFile) Then
				  If FileExists($regkey_file) Then
					 $values = FileRead($regkey_file)
					 If _getValueRegKey($values,"server") and _getValueRegKey($values,"port") and _getValueRegKey($values,"tmp") and _getValueRegKey($values,"timeout") Then
						_logAddText("El registro está en perfecto estado.")
					 Else
						_logAddText("El registro principal está corrupto.")
					 EndIf
				  Else
					 _logAddText("El registro principal no existe.")
				  EndIf
			   Else
				  _logAddText("El archivo maestro del registro no existe.")
			   EndIf
			Case "read":
			   _logAddText("Leyendo el valor del registro.")
			   _logAddText("server (Nombre/IP del servidor): "&$keyreg_server)
			   _logAddText("port (Puerto de conexión): "&$keyreg_port)
			   _logAddText("tmp (Carpeta temporal): "&$keyreg_tmp)
			   _logAddText("timeout (Tiempo de espera maximo): "&$keyreg_timeout)
			Case "clear":
			   _logSetText("")
			Case "exit":
			   $program = ""
			   _logSetText($old_terminal)
			Case Else
				_logAddText("Comando de regkey no reconocido.")
		 EndSwitch
	  Case ">> connet ":
		 Switch _getParameter($command,"command")
			Case "status":
			   If _getParameter($command,"X") Then
				  If $socket = -1 Then
					 _logAddText("No conectado al servidor.")
				  Else
					 _TCPsend("PIN")
					 $time = TimerInit()
					 Do
						$data = TCPRecv($socket,4096)
					 Until $data <> ""
					 $time = TimerDiff($time)
					 If $data = "PON" Then
						_logAddText("Conectado y con un ping de "&Round($time)&" ms.")
					 Else
						_TCPsend("DIS")
						TCPCloseSocket($socket)
						$socket = -1
						_logAddText("Se perdió la conexión con el servidor.")
					 EndIf
				  EndIf
			   Else
				  If $socket = -1 Then
					 _logAddText("No conectado al servidor.")
				  Else
					 _logAddText("Conectado con el servidor.")
				  EndIf
			   EndIf
			Case "connect":
			   If _getParameter($command,"parameter") Then
				  $server = StringSplit(_getParameter($command,"parameter"),":")[1]
				  $port = StringSplit(_getParameter($command,"parameter"),":")[2]
			   Else
				  $server = $keyreg_server
				  $port = $keyreg_port
			   EndIf
			   If Not (StringMid($server,4,1) = "." and StringMid($server,8,1)) Then
				  $server = TCPNameToIP($server)
			   EndIf
			   If _getParameter($command,"t") Then
				  $timeout = _getParameter($command,"t")
			   Else
				  $timeout = $keyreg_timeout
			   EndIf
			   $try = 0
			   Do
				  $socket = TCPConnect($server,$port)
				  Sleep(1000)
				  $try+=1
			   Until $socket <> -1 or $try = $timeout
			   If $socket = -1 Then
				  _logAddText("No se pudo conectar con el servidor.")
			   Else
				  $response = _TCPrecive()
				  If $response = "HELLO" Then
					 _TCPsend("WORLD!")
					 $response = _TCPrecive()
					 _logAddText("Conexión correcta con el servidor: "&$response)
				  Else
					 _TCPsend("PIN")
					 $response = _TCPrecive()
					 If $response = "PON" Then
						_logAddText("El servidor no respondió correctamente al saludo, pero hizo PIN-PON: "&$response)
					 Else
						TCPCloseSocket($socket)
						$socket = -1
						_logAddText("El servidor no respondió correctamente: "&$response)
					 EndIf
				  EndIf
			   EndIf
			Case "clear":
			   _logSetText("")
			Case "ping":
			   _TCPsend("PIN")
			   $time = TimerInit()
			   Do
				  $data = TCPRecv($socket,4096)
			   Until $data <> ""
			   $time = TimerDiff($time)
			   If $data = "PON" Then
				  _logAddText("La respuesta tardó "&Round($time)&" ms en llegar.")
			   Else
				  _logAddText("Error en la prueba.")
			   EndIf
			Case "upload"
			   If Not _getParameter($command,"parameter") Then
				  _logAddText("Falta el parametro con la ubicación del archivo a subir.")
			   Else
				  $file = _getParameter($command,"parameter")
				  $size = FileGetSize($file)
				  If _getParameter($command,"n") Then
					 $name = _getParameter($command,"n")
				  Else
					 $name = StringTrimLeft($file,StringInStr($file,"\",0,-1))
				  EndIf
				  If _getParameter($command,"p") Then
					 $path = _getParameter($command,"p")
				  Else
					 $path = "\"
				  EndIf
				  If _getParameter($command,"C") Then
					 $chunk = _getParameter($command,"C")
				  Else
					 $chunk = 5
				  EndIf
				  If _getParameter($command,"t") Then
					 $time = _getParameter($command,"t")
				  Else
					 $time = 100
				  EndIf
				  If _getParameter($command,"s") Then
					 _TCPsend("UPL:"&$name&":"&$path&":"&$size&":"&$chunk)
					 $response = _TCPrecive()
					 If $response <> "BOK" Then
						_logAddText("Error al subir, el servidor no aceptó el archivo.")
					 Else
						$stream = FileOpen($file, 16)
						$total = 0
						$error = false
						$text = GUICtrlRead($GUI_log)
						Do
						   $data = FileRead($stream, $chunk * 1024)
						   $total += TCPSend($socket,$data)
						   If $data <> "" Then
							  $response = _TCPrecive()
							  If StringInStr($response,"BOK") == 0 Then
								 _logAddText("Error al subir, la conexión se ha interrumpido."&$response)
								 $error = True
								 ExitLoop
							  Else
								 $arrow = ""
								 $space = ""
								 For $i = 0 To ($total/$size)*40
									$arrow &= "-"
								 Next
								 For $i = 0 To 40-($total/$size)*40
									$space &= " "
								 Next
								 If $total = $size Then $space = ""
								 _logSetText($text&@CRLF&"Subiendo: "&_spaciatorThree(Round(($total/$size)*100,0))&"%"&" |"&$arrow&">"&$space&"|")
							  EndIf
						   EndIf
						   Sleep($time)
						Until $total = $size
						FileClose($stream)
						$response = _TCPrecive()
						If $response = "BOK" Then
						   $arrow = ""
						   $space = ""
						   For $i = 0 To 40
							  $arrow &= "-"
						   Next
						   If $total = $size Then
							  _logSetText($text&@CRLF&"Subiendo: "&_spaciatorThree(Round(($total/$size)*100,0))&"%"&" |"&$arrow&">"&$space&"|")
						   EndIf
						   _logAddText("Archivo enviado correctamente.")
						Else
						   _logAddText("Error inesperado al terminar la subida.")
						EndIf
					 EndIf
				  Else
					 _TCPsend("SND:"&$name&":"&$path&":"&$size&":"&$chunk)
					 $response = _TCPrecive()
					 If $response <> "BOK" Then
						_logAddText("Error al subir, el servidor no aceptó el archivo.")
					 Else
						$stream = FileOpen($file, 16)
						$total = 0
						$text = GUICtrlRead($GUI_log)
						$wait = TimerInit()
						Do
						   $data = FileRead($stream, $chunk * 1024)
						   $total += TCPSend($socket,$data)
						   If TimerDiff($wait) >= 100 Then
							  $wait = TimerInit()
							  $arrow = ""
							  $space = ""
							  For $i = 0 To ($total/$size)*40
								 $arrow &= "-"
							  Next
							  For $i = 0 To 40-($total/$size)*40
								 $space &= " "
							  Next
							  If $total = $size Then $space = ""
							  _logSetText($text&@CRLF&"Subiendo: "&_spaciatorThree(Round(($total/$size)*100,0))&"%"&" |"&$arrow&">"&$space&"|")
						   EndIf
						Until $data = ""
						FileClose($stream)
						$response = _TCPrecive()
						If $response <> "END" Then
						   _logAddText("Error al subir, el servidor no confirmó la subida."&$response)
						Else
						   $arrow = ""
						   $space = ""
						   For $i = 0 To 40
							  $arrow &= "-"
						   Next
						   If $total = $size Then
							  _logSetText($text&@CRLF&"Subiendo: "&_spaciatorThree(Round(($total/$size)*100,0))&"%"&" |"&$arrow&">"&$space&"|")
						   EndIf
						   _logAddText("Archivo enviado correctamente.")
						EndIf
					 EndIf
				  EndIf
			   EndIf
			Case "exit":
			   $program = ""
			   _logSetText($old_terminal)
			Case "dir"
			   If _getParameter($command,"parameter") = "create" Then
				  If _getParameter($command,"p") Then
					 _TCPsend("DCR:"&_getParameter($command,"p"))
					 If _TCPrecive() = "BOK" Then
						_logAddText("Carpeta creada con exito.")
					 Else
						_logAddText("El servidor no ha confirmado el exito de la operación.")
					 EndIf
				  Else
					 _logAddText("Falta parametro path.")
				  EndIf
			   ElseIf _getParameter($command,"parameter") = "delete" Then
				  If _getParameter($command,"p") Then
					 _TCPsend("DRM:"&_getParameter($command,"p"))
					 If _TCPrecive() = "BOK" Then
						_logAddText("Carpeta eliminada con exito.")
					 Else
						_logAddText("El servidor no ha confirmado el exito de la operación.")
					 EndIf
				  Else
					 _logAddText("Falta parametro -p.")
				  EndIf
			   ElseIf _getParameter($command,"parameter") = "show" Then
				  If _getParameter($command,"p") Then
					 $path = _getParameter($command,"p")
				  Else
					 $path = "\"
				  EndIf
				  _TCPsend("DLS:"&$path)
				  $response = _TCPrecive()
				  If $response = "" Then
					 _logAddText("Error al solicitar un listado de carpetas.")
				  Else
					 If $response = "EMPTY" Then
						_logAddText("La dirección "&$path&" está vacía.")
					 Else
						_logAddText("Contenido de: "&$path)
						$parts = StringSplit($response,"|")
						For $i = 1 To $parts[0]
						   _logAddText($parts[$i])
						Next
					 EndIf
				  EndIf
			   ElseIf _getParameter($command,"parameter")  = "move" Then
				  If _getParameter($command,"O") and _getParameter($command,"D") Then
					 _TCPsend("DMV:"&_getParameter($command,"O")&":"&_getParameter($command,"D"))
					 _logAddText("Esperando confirmación...")
					 $data = _TCPreciveNoLimit()
					 _logAddText("Confirmación de la operación: "&$data)
				  Else
					 _logAddText("Faltan los parametros origin y destination.")
				  EndIf
			   Else
				  _logAddText("Error en la sintaxis del comando.")
			   EndIf
			Case "7z":
			   If _getParameter($command,"p") Then
				  If _getParameter($command,"parameter") = "a" Then
					 _TCPsend("7ZA:"&_getParameter($command,"p"))
					 _logAddText("Esperando confirmación...")
					 $data = _TCPreciveNoLimit()
					 _logAddText("Confirmación de la operación: "&$data)
				  ElseIf _getParameter($command,"parameter") = "e" Then
					 _TCPsend("7ZE:"&_getParameter($command,"p"))
					 _logAddText("Esperando confirmación...")
					 $data = _TCPreciveNoLimit()
					 _logAddText("Confirmación de la operación: "&$data)
				  Else
					 _logAddText("No se ha especificado la acción.")
				  EndIf
			   Else
				  _logAddText("El parametro path es necesario.")
			   EndIf
			Case "file":
			   If _getParameter($command,"parameter") = "delete" Then
				  If _getParameter($command,"p") Then
					 _TCPsend("DEL:"&_getParameter($command,"p"))
					 _logAddText("Esperando confirmación...")
					 $data = _TCPreciveNoLimit()
					 _logAddText("Confirmación de la operación: "&$data)
				  Else
					 _logAddText("Falta el parametro path.")
				  EndIf
			   ElseIf _getParameter($command,"parameter") = "move" Then
				  If _getParameter($command,"O") and _getParameter($command,"D") Then
					 _TCPsend("MOV:"&_getParameter($command,"O")&":"&_getParameter($command,"D"))
					 _logAddText("Esperando confirmación...")
					 $data = _TCPreciveNoLimit()
					 _logAddText("Confirmación de la operación: "&$data)
				  Else
					 _logAddText("Falta los parametros origin y destination.")
				  EndIf
			   Else
				  _logAddText("Error en la sintaxis del comando.")
			   EndIf
			Case "download":
			   If _getParameter($command,"parameter") Then
				  If _getParameter($command,"C") Then
					 $chunk = _getParameter($command,"C")
				  Else
					 $chunk = 5
				  EndIf
				  If _getParameter($command,"s") Then
					 $safe = "S"
				  Else
					 $safe = "R"
				  EndIf
				  _TCPsend("DWN:"&$safe&":"&_getParameter($command,"parameter")&":"&$chunk)
				  $data = _TCPrecive()
				  If $data = "EMPTY" Then
					 _logAddText("Archivo no encontrado en el servidor.")
					 Return
				  EndIf
				  $name = StringSplit($data,"|")[1]
				  $size = StringSplit($data,"|")[2]
				  $file = $keyreg_tmp&"\"&$name
				  $total = 0
				  $wait = TimerInit()
				  $stream = FileOpen($file, 16 + 2 + 8)
				  $error = false
				  $text = GUICtrlRead($GUI_log)
				  _TCPsend("STR")
				  If _getParameter($command,"s") Then
					 Do
						$data = TCPRecv($socket, $chunk * 1024, 1)
						If TimerDiff($wait) >= 5000 Then
						   $error = true
						   ExitLoop
						EndIf
						If $data <> "" Then
						   $wait = TimerInit()
						   FileWrite($stream, $data)
						   $total += BinaryLen($data)
						   _TCPsend("BOK")

						   $arrow = ""
						   $space = ""
						   For $i = 0 To ($total/$size)*38
							  $arrow &= "-"
						   Next
						   For $i = 0 To 38-($total/$size)*38
							  $space &= " "
						   Next
						   If $total = $size Then $space = ""
							  _logSetText($text&@CRLF&"Descargando: "&_spaciatorThree(Round(($total/$size)*100,0))&"%"&" |"&$arrow&">"&$space&"|")
						   EndIf
					 Until $total = $size
				  Else
					 $wait = TimerInit()
					 Do
						$data = TCPRecv($socket, $chunk * 1024, 1)
						FileWrite($stream, $data)
						$total += BinaryLen($data)
						If TimerDiff($wait) >= 100 Then
						   $wait = TimerInit()
						   $arrow = ""
						   $space = ""
						   For $i = 0 To ($total/$size)*38
							  $arrow &= "-"
						   Next
						   For $i = 0 To 38-($total/$size)*38
							  $space &= " "
						   Next
						   If $total = $size Then $space = ""
							  _logSetText($text&@CRLF&"Descargando: "&_spaciatorThree(Round(($total/$size)*100,0))&"%"&" |"&$arrow&">"&$space&"|")
						   EndIf
					 Until $total = $size
				  EndIf
				  Sleep(500)
				  FileClose($stream)
				  If $error Then
					 FileDelete($file)
					 _logAddText("Error al confirmar la recepcion.")
				  Else
					 $arrow = ""
					 $space = ""
					 For $i = 0 To 38
						$arrow &= "-"
					 Next
					 If $total = $size Then
						_logSetText($text&@CRLF&"Descargando: "&_spaciatorThree(Round(($total/$size)*100,0))&"%"&" |"&$arrow&">"&$space&"|")
					 EndIf
					 _logAddText("Archvo recibido correctamente.")
				  EndIf
			   Else
				  _logAddText("Error en la sintaxis del comando.")
			   EndIf
			Case "execute":
			   If _getParameter($command,"p") Then
				  $path = _getParameter($command,"p")
			   Else
				  $path = "\"
			   EndIf
			   If _getParameter($command,"w") Then
				  $wait = "WAIT"
			   Else
				  $wait = "RUN"
			   EndIf
			   If _getParameter($command,"P") Then
				  $configP = _getParameter($command,"P")
			   Else
				  $configP = " "
			   EndIf
			   If _getParameter($command,"parameter") Then
				  _TCPsend("EXE:"&_getParameter($command,"parameter")&":"&$configP&":"&$path&":"&$wait)
				  _logAddText("Esperando confirmación...")
				  Do
					 $data = TCPRecv($socket,4096,1)
					 Sleep(100)
				  Until $data <> ""
				  _logAddText("Confirmación de la operación: "&$data)
			   Else
				  _logAddText("Eror en la sintaxis del comando.")
			   EndIf
			Case "cmd":
			   If _getParameter($command,"parameter") Then
				  _TCPsend("RUN:"&_getParameter($command,"parameter"))
				  _logAddText("Esperando confirmación...")
				  $data = _TCPreciveNoLimit()
				  _logAddText("Confirmación de la operación: "&$data)
			   Else
				  _logAddText("Error en la sintaxis del comando.")
			   EndIf
			Case "stext"
			   If _getParameter($command,"parameter") = "create" Then
				  If _getParameter($command,"k") and _getParameter($command,"T") and _getParameter($command,"n") Then
					 _TCPsend("STC:"&_getParameter($command,"k")&":"&_getParameter($command,"t")&":"&_getParameter($command,"n"))
					 $data = _TCPrecive()
					 If $data = "BOK" Then
						_logAddText("Entrada de SText creada correctamente.")
					 ElseIf $data = "NANAI" Then
						_logAddText("Ya existe una entrada en SText con ese nombre.")
					 Else
						_logAddText("El servidor no confirmó la operación.")
					 EndIf
				  Else
					 _logAddText("Faltan los parametros key, text y name.")
				  EndIf
			   ElseIf _getParameter($command,"parameter") = "delete" Then
				   If _getParameter($command,"k") and _getParameter($command,"n") Then
					 _TCPsend("STD:"&_getParameter($command,"k")&":"&_getParameter($command,"n"))
					 $data = _TCPrecive()
					 If $data = "BOK" Then
						_logAddText("Entrada de SText eliminada correctamente.")
					 ElseIf $data = "NANAI" Then
						_logAddText("La clave introducida no es correcta.")
					 Else
						_logAddText("El servidor no confirmó la operación.")
					 EndIf
				  Else
					 _logAddText("Faltan los parametros key y name.")
				  EndIf
			   ElseIf _getParameter($command,"parameter") = "retrive" Then
				   If _getParameter($command,"k") and _getParameter($command,"n") Then
					 _TCPsend("STR:"&_getParameter($command,"k")&":"&_getParameter($command,"n"))
					 $data = _TCPrecive()
					 If $data <> "" and $data <> "NANAI" and $data <> "EMPTY" Then
						_logAddText("Texto: "&$data)
					 ElseIf $data = "NANAI" Then
						_logAddText("La clave introducida no es correcta.")
					 ElseIf $data = "NANAI" Then
						_logAddText("No existe entradas de SText con ese nombre.")
					 Else
						_logAddText("El servidor no respondió satisfactoriamente.")
					 EndIf
				  Else
					 _logAddText("Faltan los parametros key y name.")
				  EndIf
			   ElseIf _getParameter($command,"parameter") = "show" Then
				  _TCPsend("STS")
				  $data = _TCPrecive()
				  If $data <> "" Then
					 If $data = "EMPTY" Then
						_logAddText("No hay entradas en SText.")
					 Else
						_logAddText("Lista de Stext almacenados: "&@CRLF&$data)
					 EndIf
				  Else
					 _logAddText("El servidor no respondió satisfactoriamente.")
				  EndIf
			   ElseIf _getParameter($command,"parameter") = "import" Then
				  If _getParameter($command,"n") Then
					 _TCPsend("STI:"&_getParameter($command,"n"))
					 $data = _TCPrecive()
					 If $data <> "" Then
						FileWrite($keyreg_tmp&"\SText\"&_getParameter($command,"n")&".B0vE",$data)
						_logAddText("Clave añadida correctamente.")
					 ElseIf $data = "NANAI" Then
						_logAddText("En el servidor no existe ninguna entrada SText con ese nombre.")
					 Else
						_logAddText("El servidor no ha respondido.")
					 EndIf
				  Else
					 _logAddText("Faltan los parametro name.")
				  EndIf
			   ElseIf _getParameter($command,"parameter") = "sync" Then
				  DirRemove($keyreg_tmp&"\SText",1)
				  DirCreate($keyreg_tmp&"\SText")
				  _TCPsend("STY")
				  Do
					 $data = _TCPrecive()
					 If $data = "EMPTY" Then
						_logAddText("No hay entradas en SText.")
						Return
					 EndIf
					 If StringInStr($data,"|") <> 0 Then
						FileWrite($keyreg_tmp&"\SText\"&StringSplit($data,"|")[1],StringSplit($data,"|")[2])
						_TCPsend("BOK")
					 EndIf
				  Until $data = "END"
				  _logAddText("Sincronización finalizada.")
			   Else
				  _logAddText("Error en la sintaxis del comando.")
			   EndIf
			Case "md5":
			   If _getParameter($command,"parameter") Then
				  _logAddText("Petición para calcular el MD5 enviada.")
				  _TCPsend("CRY:"&_getParameter($command,"parameter"))
				  _logAddText(_TCPrecive())
			   Else
				  _logAddText("Falta el parametro.")
			   EndIf
			Case "trash":
			   Do
				  $data = TCPRecv($socket,4096)
				  _logAddText("Trash Colector: "&$data)
			   Until $data = ""
			Case "disconnect":
			   _TCPsend("DIS")
			   TCPCloseSocket($socket)
			   $socket = -1
			   _logAddText("Desconectado del servidor.")
			Case Else
				_logAddText("Comando de connet no reconocido.")
		 EndSwitch
	  Case ">> stext ":
		 Switch _getParameter($command,"command")
			Case "create":
			   If _getParameter($command,"k") and _getParameter($command,"T") and _getParameter($command,"n") Then
				  If FileExists($keyreg_tmp&"\SText\"&_getParameter($command,"n")&".B0vE") Then
					 _logAddText("Ya existe una entrada en el SText local con ese nombre.")
				  Else
					 $cry = _Crypt_EncryptData(_getParameter($command,"T")&"B0vE",_getParameter($command,"k"),$CALG_AES_256)
					 FileWrite($keyreg_tmp&"\SText\"&_getParameter($command,"n")&".B0vE",$cry)
					 _logAddText("Entrada de SText local creada correctamente.")
				  EndIf
			   Else
				  _logAddText("Faltan los parametros key, text y name.")
			   EndIf
			Case "delete":
			   If _getParameter($command,"k") and _getParameter($command,"n") Then
				  $text = _HexToString(_Crypt_DecryptData(FileRead($keyreg_tmp&"\SText\"&_getParameter($command,"n")&".B0vE"),_getParameter($command,"k"),$CALG_AES_256))
				  If StringTrimLeft($text,StringLen($text)-4) = "B0vE" Then
					 FileDelete($keyreg_tmp&"\SText\"&_getParameter($command,"n")&".B0vE")
					 _logAddText("Entrada de SText local eliminada correctamente.")
				  Else
					 _logAddText("La clave no es correcta.")
				  EndIf
			   Else
				   _logAddText("Faltan los parametros key y name.")
			   EndIf
			Case "retrive":
			   If _getParameter($command,"k") and _getParameter($command,"n") Then
				  $text = _HexToString(_Crypt_DecryptData(FileRead($keyreg_tmp&"\SText\"&_getParameter($command,"n")&".B0vE"),_getParameter($command,"k"),$CALG_AES_256))
				  If StringTrimLeft($text,StringLen($text)-4) = "B0vE" Then
					 _logAddText("Texto: "&StringTrimRight($text,4))
				  Else
					 _logAddText("La clave no es correcta.")
				  EndIf
			   Else
				   _logAddText("Faltan los parametros key y name.")
			   EndIf
			Case "show":
			   $files = _FileListToArray($keyreg_tmp&"\SText","*.B0vE",1)
			   If $files = "" Then
				  _logAddText("No hay entradas en el SText local.")
			   Else
				  $all = ""
				  For $i = 1 To $files[0]
					 $all &= StringTrimRight($files[$i],5)&", "
				  Next
				  _logAddText(StringTrimRight($all,2))
			   EndIf
			Case "clear":
			   _logSetText("")
			Case "exit":
			   $program = ""
			   _logSetText($old_terminal)
			Case else
			   _logAddText("Comando de stext no reconocido.")
		 EndSwitch
	  Case ">> rawcon ":
		 Switch _getParameter($command,"command")
			Case "connect":
			   If _getParameter($command,"parameter") Then
				  $server = StringSplit(_getParameter($command,"parameter"),":")[1]
				  $port = StringSplit(_getParameter($command,"parameter"),":")[2]
			   Else
				  $server = $keyreg_server
				  $port = $keyreg_port
			   EndIf
			   If Not (StringMid($server,4,1) = "." and StringMid($server,8,1)) Then
				  $server = TCPNameToIP($server)
			   EndIf
			   $try = 0
			   Do
				  $socket = TCPConnect($server,$port)
				  Sleep(1000)
				  $try+=1
			   Until $socket <> -1 or $try = 5
			   If $socket = -1 Then
				  _logAddText("No se pudo conectar con el servidor.")
			   Else
				  If _getParameter($command,"a") Then
					 $response = _TCPrecive()
					 If $response = "HELLO" Then
						_TCPsend("WORLD!")
						$response = _TCPrecive()
						_logAddText("Conexión correcta con el servidor: "&$response)
					 Else
						TCPCloseSocket($socket)
						$socket = -1
						_logAddText("El servidor no respondió correctamente: "&$response)
					 EndIf
				  Else
					 _logAddText("Conexión correcta, el servidor está esperando respuesta.")
				  EndIf
			   EndIf
			Case "send"
			   If Not _getParameter($command,"f") Then
				  If _getParameter($command,"parameter") Then
					 _TCPsend(_getParameter($command,"parameter"))
					 _logAddText("Enviado.")
				  Else
					 _logAddText("Falta el parametro.")
				  EndIf
			   Else
				  If _getParameter($command,"parameter") Then
					 _TCPsend("SND:"&"tmp"&":"&"\"&":"&FileGetSize(_getParameter($command,"parameter"))&":"&"5")
					 $stream = FileOpen(_getParameter($command,"parameter"), 16)
					 _TCPrecive()
					 $total = 0
					 Do
						$data = FileRead($stream, 5 * 1024)
						$total += TCPSend($socket,$data)
					 Until $data = ""
					 FileClose($stream)
					 _logAddText("Enviado.")
				  Else
					 _logAddText("Falta el parametro.")
				  EndIf
			   EndIf
			Case "recive"
			   If _getParameter($command,"f") Then
				  $file = $keyreg_tmp&"\tmp"
				  $stream = FileOpen($file, 16 + 2 + 8)
				  $fin = false
				  $wait = TimerInit()
				  Do
					 $data = TCPRecv($socket, 5 * 1024, 1)
					 If TimerDiff($wait) >= 5000 Then
						$fin = true
						ExitLoop
					 EndIf
					 If $data <> "" Then
						$wait = TimerInit()
						FileWrite($stream, $data)
					 EndIf
				  Until $fin
				  FileClose($stream)
				  _logAddText("Recivido")
			   ElseIf _getParameter($command,"b") Then
				  $max = 50
				  Do
					 $data = TCPRecv($socket,4096,1)
					 Sleep(100)
					 $max-=1
				  Until $data <> "" or $max = 0
				  _logAddText($data&" ")
			   Else
				  $response = _TCPrecive()
				  _logAddText("Respuesta: "&$response)
			   EndIf
			Case "disconnect":
			   _TCPsend("DIS")
			   TCPCloseSocket($socket)
			   $socket = -1
			   _logAddText("Desconectado del servidor.")
			Case "clear":
			   _logSetText("")
			Case "exit":
			   $program = ""
			   _logSetText($old_terminal)
			Case Else
				_logAddText("Comando de rawcon no reconocido.")
		 EndSwitch
   EndSwitch
   ControlSend($GUI,"",$GUI_log,"{PGDN}")
   _logAddText("")
EndFunc
Func startup($file)
   For $i = 0 To 9
	  $sent_comands[$i] = ""
   Next
   If $file = "" Then
	  $regkey_file = @AppDataDir&"\BovEController\regkey.B0vE"
	  FileWrite($regkeyPosFile,$regkey_file)
	  $file = $regkey_file
   EndIf
   If FileExists($file) Then
	  $values = FileRead($file)
	  Global $keyreg_server = _getValueRegKey($values,"server")
	  Global $keyreg_port = _getValueRegKey($values,"port")
	  Global $keyreg_tmp = _getValueRegKey($values,"tmp")
	  Global $keyreg_timeout = _getValueRegKey($values,"timeout")
	  If Not FileExists($keyreg_tmp) Then
		 DirCreate($keyreg_tmp)
		 DirCreate($keyreg_tmp&"\SText")
	  EndIf
   Else
	  If Not FileExists(StringTrimRight($file,StringLen($file)-StringInStr($file,"\",0,-1)+1)) Then DirCreate(StringTrimRight($file,StringLen($file)-StringInStr($file,"\",0,-1)+1))
	  Global $keyreg_server = "routerarlin.mooo.com"
	  Global $keyreg_port = "44144"
	  Global $keyreg_tmp = @AppDataDir&"\BovEController\tmp"
	  Global $keyreg_timeout = "5"
	  If Not FileExists($keyreg_tmp) Then
		 DirCreate($keyreg_tmp)
		 DirCreate($keyreg_tmp&"\SText")
	  EndIf
	  FileWrite($file,"server:"&$keyreg_server&@CRLF&"port:"&$keyreg_port&@CRLF&"tmp:"&$keyreg_tmp&@CRLF&"timeout:"&$keyreg_timeout)
   EndIf
EndFunc

#EndRegion

#Region UDF
Func _logSetText($text)
   GUICtrlSetData($GUI_log,$text)
EndFunc
Func _logAddText($text)
   GUICtrlSetData($GUI_log,GUICtrlRead($GUI_log)&$text&@CRLF)
EndFunc
Func _paraseCommand($text)
   $text = StringReplace($text,"[Desktop]",@DesktopDir)
   $text = StringReplace($text,"[TMP]",$keyreg_tmp)
   $text = StringReplace($text,"[Downloads]",@UserProfileDir&"\Downloads")
   $text = StringReplace($text,"[Documents]",@UserProfileDir&"\Documents")

   Local $command[0][2]
   $start = 0
   $parameterLost = true
   For $i = 1 To StringLen($text)
	  If $start = 0 and StringMid($text,$i,1) <> " " Then
		 $start = $i
		 Do
			$i+=1
		 Until StringMid($text,$i,1) = " " or StringLen($text) <= $i
		 If StringLen($text) <= $i Then $i+=1
		 ReDim $command[UBound($command,1)+1][2]
		 $command[UBound($command,1)-1][0] = "command"
		 $command[UBound($command,1)-1][1] = StringMid($text,$start,$i-$start)
		 $start = $i
	  ElseIf $parameterLost and $start <> 0 and Not (StringMid($text,$i,1) = " " or StringMid($text,$i,1) = "-") and StringMid($text,$i-1,1) = " "  Then
		 If StringMid($text,$i,1) = '"'  Then
			 $start = $i+1
			 Do
			   $i+=1
			Until StringMid($text,$i,1) = '"' or StringLen($text) <= $i
		 Else
			  $start = $i
			Do
			   $i+=1
			Until StringMid($text,$i,1) = " " or StringLen($text) <= $i
			If StringLen($text) <= $i Then $i+=1
		 EndIf
		 ReDim $command[UBound($command,1)+1][2]
		 $command[UBound($command,1)-1][0] = "parameter"
		 $command[UBound($command,1)-1][1] = StringMid($text,$start,$i-$start)
	  ElseIf StringMid($text,$i,1) = "-" Then
		 If StringMid($text,$i+1,1) = "-" Then
			$i = $i+2
			$start = $i
			Do
			   $i+=1
			Until StringMid($text,$i,1) = " " or StringMid($text,$i,1) = ":" or StringLen($text) <= $i
			If StringLen($text) <= $i Then $i+=1
			ReDim $command[UBound($command,1)+1][2]
			$command[UBound($command,1)-1][0] = _getShort(StringMid($text,$start,$i-$start))
			If StringMid($text,$i,1) = ":" Then
			   $i+=1
			   $start = $i

			   If StringMid($text,$i,1) = '"'  Then
				   $start = $i+1
				   Do
					 $i+=1
				  Until StringMid($text,$i,1) = '"' or StringLen($text) <= $i
			   Else
				  $start = $i
				  Do
					 $i+=1
				  Until StringMid($text,$i,1) = " " or StringLen($text) <= $i
				  If StringLen($text) <= $i Then $i+=1
			   EndIf
			   $command[UBound($command,1)-1][1] = StringMid($text,$start,$i-$start)

			Else
			   $command[UBound($command,1)-1][1] = True
			EndIf
		 Else
			If StringMid($text,$i+2,1) = ":" Then
			   $name = StringMid($text,$i+1,1)
			   $start = $i+3
			   $i+=3
			   If StringMid($text,$i,1) = '"'  Then
				   $start = $i+1
				   Do
					 $i+=1
				  Until StringMid($text,$i,1) = '"' or StringLen($text) <= $i
			   Else
				  $start = $i
				  Do
					 $i+=1
				  Until StringMid($text,$i,1) = " " or StringLen($text) <= $i
				  If StringLen($text) <= $i Then $i+=1
			   EndIf
			   ReDim $command[UBound($command,1)+1][2]
			   $command[UBound($command,1)-1][0] = $name
			   $command[UBound($command,1)-1][1] = StringMid($text,$start,$i-$start)
			Else
			   ReDim $command[UBound($command,1)+1][2]
			   $command[UBound($command,1)-1][0] = StringMid($text,$i+1,1)
			   $command[UBound($command,1)-1][1] = True
			EndIf
		 EndIf
	  EndIf
   Next
   Return $command
EndFunc
Func _getParameter($command,$key)
   $parameter = false
   For $i = 0 To UBound($command)-1
	  If $command[$i][0] = $key Then
		 $parameter = $command[$i][1]
		 ExitLoop
	  EndIf
   Next
   Return $parameter
EndFunc
Func _getShort($long)
   For $i = 0 To UBound($shorts)-1
	  If $shorts[$i][0] == $long Then Return $shorts[$i][1]
   Next
EndFunc
Func _getValueRegKey($values,$name)
   $values = StringSplit($values,@CRLF)
   For $i = 1 To $values[0]
	  $partes = StringSplit($values[$i],":")
	  If $partes[1] = $name Then
		 If $name == "tmp" Then Return $partes[2]&":"&$partes[3]
		 Return $partes[2]
	  EndIf
   Next
   Return False
EndFunc
Func _TCPrecive()
   $max = 50
   Do
	  $data = TCPRecv($socket,4096)
	  Sleep(100)
	  $max-=1
   Until $data <> "" or $max = 0
   If $data = "CHK" Then
	  _TCPsend("BOK")
	  Return ""
   Else
	  Return $data
   EndIf
EndFunc
Func _TCPreciveNoLimit()
   Do
	  $data = TCPRecv($socket,4096)
	  Sleep(100)
   Until $data <> ""
   If $data = "CHK" Then
	  _TCPsend("BOK")
	  Return ""
   Else
	  Return $data
   EndIf
EndFunc
Func _TCPsend($text)
   TCPSend($socket,$text)
EndFunc
Func _spaciatorThree($n)
   If $n < 10 Then Return "  "&$n
   If $n < 100 Then Return " "&$n
   Return $n
EndFunc
Func _recordComand($comand)
   For $i = 9 To 1 Step -1
	  $sent_comands[$i] = $sent_comands[$i-1]
   Next
   $sent_comands[0] = $comand
EndFunc
Func _comandAv()
   If $sent_current < 9 Then
	  $sent_current += 1
   Else
	  GUICtrlSetData($GUI_input,$sent_comands[$sent_current])
   EndIf
EndFunc
Func _comandRe()
   If $sent_current <= 0 Then
	  $sent_current -= 1
	  GUICtrlSetData($GUI_input,"")
   Else
	  GUICtrlSetData($GUI_input,$sent_comands[$sent_current])
   EndIf
EndFunc
#EndRegion