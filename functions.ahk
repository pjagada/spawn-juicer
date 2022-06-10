RunHide(Command)
{
  dhw := A_DetectHiddenWindows
  DetectHiddenWindows, On
  Run, %ComSpec%,, Hide, cPid
  WinWait, ahk_pid %cPid%
  DetectHiddenWindows, %dhw%
  DllCall("AttachConsole", "uint", cPid)

  Shell := ComObjCreate("WScript.Shell")
  try
  {
    Exec := Shell.Exec(Command)
  }
  catch e
  {
    MsgBox, Error running command
    ExitApp
  }
  Result := Exec.StdOut.ReadAll()

  DllCall("FreeConsole")
  Process, Close, %cPid%
Return Result
}

GetMcDir(pid)
{
  command := Format("powershell.exe $x = Get-WmiObject Win32_Process -Filter \""ProcessId = {1}\""; $x.CommandLine", pid)
  rawOut := RunHide(command)
  if (InStr(rawOut, "--gameDir")) {
    strStart := RegExMatch(rawOut, "P)--gameDir (?:""(.+?)""|([^\s]+))", strLen, 1)
    return SubStr(rawOut, strStart+10, strLen-10) . "\"
  } else {
    strStart := RegExMatch(rawOut, "P)(?:-Djava\.library\.path=(.+?) )|(?:\""-Djava\.library.path=(.+?)\"")", strLen, 1)
    if (SubStr(rawOut, strStart+20, 1) == "=") {
      strLen -= 1
      strStart += 1
    }
    return StrReplace(SubStr(rawOut, strStart+20, strLen-28) . ".minecraft\", "/", "\")
  }
}


getMostRecentFile(mcDirectory)
{
  savesDirectory := mcDirectory . "saves"
	counter := 0
	Loop, Files, %savesDirectory%\*.*, D
	{
		if (A_LoopFileShortName == "speedrunigt")
			continue
		counter += 1
		if (counter = 1)
		{
			maxTime := A_LoopFileTimeModified
			mostRecentFile := A_LoopFileLongPath
		}
		if (A_LoopFileTimeModified >= maxTime)
		{
			maxTime := A_LoopFileTimeModified
			mostRecentFile := A_LoopFileLongPath
		}
	}
   recentFile := mostRecentFile
   return (recentFile)
}

Logg(inString)
{
  if (logging)
  {
    theTime := readableTime()
    writeString := "[macro] " . theTime . ": " . inString
    OutputDebug, %writeString%
    writeString := theTime . ": " . inString . "`n"
    FileAppend, %writeString%, macro_logs.txt
  }
}

readableTime()
{
   theTime := A_Now
   year := theTime // 10000000000
   month := mod(theTime, 10000000000)
   month := month // 100000000
   day := mod(theTime, 100000000)
   day := day // 1000000
   hour := mod(theTime, 1000000)
   hour := hour // 10000
   minute := mod(theTime, 10000)
   minute := minute // 100
   second := mod(theTime, 100)
   if (second < 10)
      second := "0" . second
   if (minute < 10)
      minute := "0" . minute
   if (hour < 10)
      hour := "0" . hour
   if (day < 10)
      day := "0" . day
   if (month < 10)
      month := "0" . month
   timeString := month . "/" . day . "/" . year . " " . hour . ":" . minute . ":" second
   return (timeString)
}

