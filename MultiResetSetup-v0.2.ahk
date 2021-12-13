#NoEnv
#SingleInstance Force

; Make sure all instances are unfrozen, and in order on the front of the taskbar
; Also have LiveSplit open :)

SetKeyDelay, 1
SetWinDelay, 1
SetTitleMatchMode, 2

global instances := 0
global PIDs := []
global SavesDirectories := []

RunHide(Command)
{
  dhw := A_DetectHiddenWindows
  DetectHiddenWindows, On
  Run, %ComSpec%,, Hide, cPid
  WinWait, ahk_pid %cPid%
  DetectHiddenWindows, %dhw%
  DllCall("AttachConsole", "uint", cPid)

  Shell := ComObjCreate("WScript.Shell")
  Exec := Shell.Exec(Command)
  Result := Exec.StdOut.ReadAll()

  DllCall("FreeConsole")
  Process, Close, %cPid%
  Return Result
}

GetSavesDir(pid)
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

GetInstanceTotal() {
  total := 0
  WinGet, all, list
  Loop, %all%
  {
    WinGet, pid, PID, % "ahk_id " all%A_Index%
    WinGetTitle, title, ahk_pid %pid%
    if (InStr(title, "Minecraft*"))
      total += 1
  }
  return total
}

GetAllPIDs()
{
  global SavesDirectories
  global PIDs
  global instances := GetInstanceTotal()
  WinActivate, LiveSplit
  Loop, %instances% {
    Send, {RWin Down}{%A_Index%}{RWin Up}
    sleep, 50
    WinGet, pid, PID, A
    PIDs[A_Index] := pid
  }
  ; Generate saves
  Loop, %instances% {
    SavesDirectories[A_Index] := GetSavesDir(PIDs[A_Index])
  }
}

GetAllPIDs()
Loop, %instances% { 
  numFile := SavesDirectories[A_Index] . "instanceNumber.txt"
  if (FileExist(numFile))
    FileDelete, %numFile%
  FileAppend, %A_Index%, %numFile%
}
ComObjCreate("SAPI.SpVoice").Speak("Done")

ExitApp