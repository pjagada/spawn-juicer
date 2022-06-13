#NoEnv
#SingleInstance Force
#Include 2_options.ahk
#include functions.ahk
;#Warn

SetKeyDelay, 0
SetWinDelay, 1
SetTitleMatchMode, 2

; all instances must be on title screen or in pause menu.

EnvGet, threadCount, NUMBER_OF_PROCESSORS
global currInst := -1
global pauseAuto := False
global SavesDirectories := []
global instances := 0
global rawPIDs := []
global PIDs := []
global titles := []
global states := []
global startTimes := []
global reachedSave := []
global joinDelay := 2000 ; increase if doesnt join world

GetAllPIDs()
SetTitles()

tmptitle := ""
for i, tmppid in PIDs{
  WinGetTitle, tmptitle, ahk_pid %tmppid%
  titles.Push(tmptitle)
  startTimes.Push(A_TickCount)
  reachedSave.Push(false)
  WinSet, AlwaysOnTop, Off, ahk_pid %tmppid%
}

global TITLE_SCREEN := 0
global GENNING := 1
global PREVIEW_STARTED := 2
global WAITING_FINAL_SAVE := 3
global PAUSED := 4
global WAIT_FOR_DELAY := 5
global GO_TIME := 6
global DONE := -1

for k, saves_directory in SavesDirectories
{
    if (!(modExist("atum", k)))
    {
      MsgBox, Instance %k% does not have atum installed. Install atum in all your instances, restart them, then start the script again.
      ExitApp
    }
	if (PauseOnLostFocus(k))
	{
		MsgBox, Instance %k% has pause on lost focus enabled. Disable this feature by pressing F3 + P in-game, then start the script again.
		ExitApp
	}
    if (on_title(k))
    {
      states.push(TITLE_SCREEN)
      Logg("Instance " . k . " on title screen")
    }
    else if (in_world(k))
    {
      states.push(PAUSED)
      Logg("Instance " . k . " is paused")
    }
    else
    {
      MsgBox, Instance %k% is neither on the title screen nor in a world. Make sure all instances are either on the title screen or in the pause menu, then start the script again.
      ExitApp
    }
}

global sprintButton := getKey("key_key.sprint")
global freezePreviewKey := ""
if (modExist("worldpreview", 1)) {
  freezePreviewKey := getKey("key_Freeze Preview")
}

Loop, %instances%
{
  the_State := states[A_Index]
  Logg("Instance " . A_Index . " is in state " . the_State)
}

#Persistent
SetTimer, Repeat, 20
return

Repeat:
  Critical
  for i, pid in PIDs {
    HandleState(pid, i)
  }
  check_done()
return

check_done()
{
  is_done := true
  ;Logg("there are " . instances . " instances to check done")
  Loop, %instances%
  {
    theState := states[A_Index]
    ;Logg("Instance " . A_Index . " is in state " . theState . " for state checking purposes")
    if (theState != DONE)
    {
      ;Logg("Instance " . A_Index . " is not done")
      is_done := false
      return
    }
    ;Logg("Instance " . A_Index . " is done")
  }
  Logg(":1234567890:")
  if (is_done) {
    speak_async("Done")
    ExitApp
  }
}

toggle_sprint(idx, pid)
{
  shouldWe := readline("toggleSprint", idx)
  if (shouldWe == "false")
  {
    Logg("toggle sprint not used in instance " . idx)
    return
  }
  if (sprintButton == "CapsLock")
  {
    SetStoreCapsLockMode, Off
    ControlSend, ahk_parent, {%sprintButton%}, ahk_pid %pid%
    SetStoreCapsLockMode, On
  }
  else {
    ControlSend, ahk_parent, {%sprintButton%}, ahk_pid %pid%
  }
}

HandleState(pid, idx) {
  if (states[idx] == DONE)
  {
    return
  }
  else if (states[idx] == TITLE_SCREEN)
  {
    theState := states[idx]
    Logg("Instance " . idx . " on title screen")
    ControlSend, ahk_parent, {Blind}{Shift down}{Tab}{Shift up}{Enter}, ahk_pid %pid%
  }
  else if (states[idx] == GENNING) {
    theState := states[idx]
    WinGetTitle, title, ahk_pid %pid%
    if (IsInGame(title) || HasPreviewStarted(idx))
    {
      Logg("Instance " . idx . " loaded in or preview has started")
    }
    else
    {
      return
    }
  }
  else if (states[idx] == PREVIEW_STARTED)
  {
    theState := states[idx]
    Logg("Instance " . idx . " has started preview")
    ControlSend, ahk_parent, {Blind}{%freezePreviewKey%}, ahk_pid %pid%
  }
  else if (states[idx] == WAITING_FINAL_SAVE)
  {
    theState := states[idx]
    WinGetTitle, title, ahk_pid %pid%
    if (!(IsInGame(title))) ; wait until preview is done
    {
      return
    }
    if (!(HasGameSaved(idx)))
    {
      return
    }
    Logg("Instance " . idx . " has reached the final save so pausing")
    ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %pid%

  }
  else if (states[idx] == PAUSED)
  {
    theState := states[idx]
    Logg("Instance " . idx . " is paused")
    startTimes[idx] := A_TickCount
  }
  else if (states[idx] == WAIT_FOR_DELAY)
  {
    theState := states[idx]
    if ((A_TickCount - startTimes[idx] < joinDelay))
    {
      return
    }
    Logg("Instance " . idx . " has waited long enough")
  }
  else if (states[idx] == GO_TIME) ; frozen good spawn waiting to be used
  {
    Logg("Instance " . idx . " is unpausing")
    ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %pid%
    Sleep, 50
    if (hitboxes) {
      ControlSend, ahk_parent, {Blind}{F3 Down}{B}{F3 Up}, ahk_pid %pid%
      Logg("Instance " . idx . " is toggling hitboxes")
    }
    Sleep, 50
    if (toggleSprint)
    {
      toggle_sprint(idx, pid)
    }
    ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %pid%
    states[idx] := DONE
    theState := states[idx]
    Logg("state of instance " . idx . " is now " . theState . ", should be " . DONE)
    return
  }
  else {
    theState := states[idx]
    MsgBox, instance %idx% ended up at unknown state of %theState%, exiting script
    ExitApp
  }
  states[idx] += 1 ; Progress State
}

HasPreviewStarted(idx) {
  logFile := SavesDirectories[idx] . "logs\latest.log"
  numLines := 0
  Loop, Read, %logFile%
  {
    numLines += 1
  }
  started := False
  Loop, Read, %logFile%
  {
    if ((numLines - A_Index) < 5)
    {
      if (InStr(A_LoopReadLine, "Starting Preview at")) {
        started := True
        break
      }
    }
  }
  return started
}

HasGameSaved(idx) {
  logFile := SavesDirectories[idx] . "logs\latest.log"
  numLines := 0
  Loop, Read, %logFile%
  {
    numLines += 1
  }
  saved := False
  startTime := A_TickCount
  Loop, Read, %logFile%
  {
    if ((numLines - A_Index) < 5)
    {
      if (InStr(A_LoopReadLine, "Loaded 0") || (InStr(A_LoopReadLine, "Saving chunks for level 'ServerLevel") && InStr(A_LoopReadLine, "minecraft:the_end"))) {
        saved := True
        break
      }
    }
  }
return saved
}

GetInstanceTotal() {
  idx := 1
  global rawPIDs
  WinGet, all, list
  Loop, %all%
  {
    WinGet, thePID, PID, % "ahk_id " all%A_Index%
    WinGetTitle, title, ahk_pid %thePID%
    if (InStr(title, "Minecraft*")) {
      rawPIDs[idx] := thePID
      ;OutputDebug, [macro] idx: %idx%, title: %title%, pid: %pid%
      idx += 1
    }
  }
return rawPIDs.MaxIndex()
}

GetInstanceNumberFromSaves(saves) {
  numFile := saves . "instanceNumber.txt"
  num := -1
  if (saves == "" || saves == ".minecraft" || saves == ".minecraft\" || saves == ".minecraft/") ; Misread something
    Reload
  if (!FileExist(numFile))
    MsgBox, Missing instanceNumber.txt in %saves%. Run the setup script (see instructions)
  else
    FileRead, num, %numFile%
return num
}

GetAllPIDs()
{
  global SavesDirectories
  global PIDs
  global instances := GetInstanceTotal()
  ;OutputDebug, [macro] %instances% instances
  ; Generate saves and order PIDs
  Loop, %instances% {
    saves := GetMcDir(rawPIDs[A_Index])
    if (num := GetInstanceNumberFromSaves(saves)) == -1
      ExitApp
    PIDS[num] := rawPIDs[A_Index]
    SavesDirectories[num] := saves
    ;OutputDebug, [macro] saves: %saves% index: %A_Index%
  }
}

in_world(idx) {
  thePID := PIDs[idx]
  WinGetTitle, title, ahk_pid %thePID%
  return IsInGame(title)
}

on_title(idx)
{
  mcDirectory := SavesDirectories[idx]
  Logg("checking if in world, mcDirectory is " . mcDirectory)
  lastWorld := getMostRecentFile(mcDirectory)
  Logg("last world is " . lastWorld)
  lockFile := lastWorld . "\session.lock"
  Logg("checking lockFile " . lockFile)
  FileRead, sessionlockfile, %lockFile%
  if (ErrorLevel = 0)
  {
    return true
  }
  return false
}

SetTitles() {
  for g, thePID in PIDs {
    WinSetTitle, ahk_pid %thePID%, , Minecraft* - Instance %g%
  }
}
