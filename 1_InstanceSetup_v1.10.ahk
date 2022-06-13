#NoEnv
#SingleInstance Force
#include functions.ahk

; Make sure all instances are unfrozen, and in order on the front of the taskbar
; Also have LiveSplit open :)

SetKeyDelay, 1
SetWinDelay, 1
SetTitleMatchMode, 2

global instances := 0
global PIDs := []
global SavesDirectories := []



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
    SavesDirectories[A_Index] := GetMcDir(PIDs[A_Index])
  }
}

GetAllPIDs()
Loop, %instances% { 
  numFile := SavesDirectories[A_Index] . "instanceNumber.txt"
  if (FileExist(numFile))
    FileDelete, %numFile%
  FileAppend, %A_Index%, %numFile%
}

speak_async("Done")

ExitApp