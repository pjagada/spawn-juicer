#NoEnv
#SingleInstance Force
;#Warn

SetKeyDelay, 0
SetWinDelay, 1
SetTitleMatchMode, 2

; all instances must be on title screen or in pause menu.
global toggleSprint := True ; will not do anything if hold sprint is used, otherwise it will toggle your sprint
global sprintButton := "CapsLock" ; list of keys here: https://www.autohotkey.com/docs/KeyList.htm
global hitboxes := True ; will toggle hitboxes
global logging = False ; turn this to True to generate logs in macro_logs.txt and DebugView; don't keep this on True because it'll slow things down

; Don't configure these, scroll to the very bottom to configure hotkeys
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
    ComObjCreate("SAPI.SpVoice").Speak("Done")
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
    ControlSend, ahk_parent, {Blind}j, ahk_pid %pid%
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
    saves := GetSavesDir(rawPIDs[A_Index])
    if (num := GetInstanceNumberFromSaves(saves)) == -1
      ExitApp
    PIDS[num] := rawPIDs[A_Index]
    SavesDirectories[num] := saves
    ;OutputDebug, [macro] saves: %saves% index: %A_Index%
  }
}

DebugHead(n)
{
  writeString := "[macro] " . readableTime() . ": Instance " . n . ": "
  return writeString
}

GetActiveInstanceNum() {
  WinGet, thePID, PID, A
  WinGetTitle, title, ahk_pid %thePID%
  if (IsInGame(title)) {
    for r, temppid in PIDs {
      if (temppid == thePID)
        return r
    }
  }
return -1
}

IsInGame(currTitle) { ; If using another language, change Singleplayer and Multiplayer to match game title
return InStr(currTitle, "Singleplayer") || InStr(currTitle, "Multiplayer") || InStr(currTitle, "Instance")
}

in_world(idx) { ; If using another language, change Singleplayer and Multiplayer to match game title
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

ShiftTab(thePID, n := 1)
{
   if WinActive("ahk_pid" thePID)
   {
      Loop, %n%
      {
         Send, +`t
      }
   }
   else
   {
      ControlSend, ahk_parent, {Blind}{Shift down}, ahk_pid %thePID%
      Loop, %n%
      {
         ControlSend, ahk_parent, {Blind}{Tab}, ahk_pid %thePID%
      }
      ControlSend, ahk_parent, {Blind}{Shift up}, ahk_pid %thePID%
   }
}

modExist(mod, idx)
{
  savesDirectory := SavesDirectories[idx]
  modsFolder := StrReplace(savesDirectory, "saves", "mods") . "mods"
  Logg("Checking mods in " . modsFolder)
   Loop, Files, %modsFolder%\*.*, F
   {
    Logg("checking mod " . A_LoopFileName)
      if(InStr(A_LoopFileName, mod) && (!(InStr(A_LoopFileName, "disabled"))))
      {
        Logg("found the mod " . mod)
         return true
      }
   }
   Logg("did not find the mod " . mod)
  return false
}

readLine(option, idx)
{
  savesDirectory := SavesDirectories[idx]
  optionsFile := StrReplace(savesDirectory, "saves", "options.txt") . "options.txt"
  Logg("Looking for option " . option . " in " . optionsFile)
  Loop, read, %optionsFile%
  {
    if InStr(A_LoopReadLine, option)
    {
      Logg("found line of " . A_LoopReadLine)
      arr := StrSplit(A_LoopReadLine, ":")
      value := arr[2]
      Logg("value is " . value)
      return value
    }
  }
  MsgBox, Could not find option in options.txt
  ExitApp
}

PauseOnLostFocus(idx) ;used on script startup
{
   optionLine := readLine("pauseOnLostFocus", idx)
   if (InStr(optionLine, "true"))
      return 1
   else
      return 0
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

getMostRecentFile(mcDirectory)
{
  savesDirectory := mcDirectory . "saves"
  ;MsgBox, %savesDirectory%
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
