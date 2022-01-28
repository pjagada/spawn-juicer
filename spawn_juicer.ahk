; Multi instance AHK resetting script for set seed
; Original author Specnr, modified for set seed by Peej

; Instructions: https://github.com/pjagada/spawn-juicer#readme

; v1.2

#NoEnv
#SingleInstance Force
;#Warn

SetKeyDelay, 0
SetWinDelay, 1
SetTitleMatchMode, 2

; macro options:
global instanceFreezing := True ; you probably want to keep this on (true)
global unpauseOnSwitch := False
global fullscreen := False ; all resets will be windowed, this will automatically fullscreen the instance that's about to be played
global playSound := False ; will play a windows sound or the sound stored as spawnready.mp3 whenever a spawn is ready
global disableTTS := False ; this is the "ready" sound that plays when the macro is ready to go
global fullScreenDelay := 270 ; increse if fullscreening issues
global obsDelay := 50 ; increase if not changing scenes in obs
global restartDelay := 200 ; increase if saying missing instanceNumber in .minecraft (and you ran setup)
global maxLoops := 20 ; increase if macro regularly locks
global f3showDuration = 100 ; how many milliseconds f3 is shown for at the start of a run (for verification purposes). Make this -1 if you don't want it to show f3. Remember that one frame at 60 fps is 17 milliseconds, and one frame at 30 fps is 33 milliseconds. You'll probably want to show this for 2 or 3 frames to be safe.
global f3showDelay = 100 ; how many milliseconds of delay before showing f3. If f3 isn't being shown, this is all probably happening during the joining world screen, so increase this number.

; Autoresetter Options:
; The autoresetter will automatically reset if your spawn is greater than a certain number of blocks away from a certain point (ignoring y)
global centerPointX := 162.7 ; this is the x coordinate of that certain point (by default it's the x coordinate of being pushed up against the window of the blacksmith of -3294725893620991126)
global centerPointZ := 194.5 ; this is the z coordinate of that certain point (by default it's the z coordinate of being pushed up against the window of the blacksmith of -3294725893620991126)
global radius := 13 ; if this is 10 for example, the autoresetter will not reset if you are within 10 blocks of the point specified above. Set this smaller for better spawns but more resets
; if you would only like to reset the blacklisted spawns or don't want automatic resets, then just set this number really large (1000 should be good enough), and if you would only like to play out whitelisted spawns, then just make this number negative
global giveAngle := False ; Give the angle (TTS) that you need to travel at to get to your starting point




; Don't configure these, scroll to the very bottom to configure hotkeys
EnvGet, threadCount, NUMBER_OF_PROCESSORS
global currInst := -1
global pauseAuto := False
global SavesDirectories := []
global instances := 0
global rawPIDs := []
global PIDs := []
global titles := []
global resetStates := []
global resetTimes := []
global startTimes := []
global reachedSave := []
global xCoords := []
global zCoords := []
global distances := []
global beforeFreezeDelay := 0 ; increase if doesnt join world
global playerState := 0 ; needs spawn
global highBitMask := (2 ** threadCount) - 1
global lowBitMask := (2 ** Ceil(threadCount * 0.5)) - 1

if (instanceFreezing) {
  UnsuspendAll()
  sleep, %restartDelay%
}
GetAllPIDs()
SetTitles()

tmptitle := ""
for i, tmppid in PIDs{
  WinGetTitle, tmptitle, ahk_pid %tmppid%
  titles.Push(tmptitle)
  resetStates.push(2) ; need to exit
  resetTimes.push(0)
  xCoords.Push(0)
  zCoords.Push(0)
  distances.Push(0)
  startTimes.Push(A_TickCount)
  reachedSave.Push(false)
  WinSet, AlwaysOnTop, Off, ahk_pid %tmppid%
}
global version = getVersion()

for k, saves_directory in SavesDirectories
{
    ;OutputDebug, [macro] k is %k% saves_directory is %saves_directory%
	if (PauseOnLostFocus(saves_directory))
	{
		MsgBox, Instance %k% has pause on lost focus enabled. Disable this feature by pressing F3 + P in-game, then start the script again.
		ExitApp
	}
}

for i, tmppid in PIDs {
    SetAffinity(tmppid, highBitMask)
}

if (!disableTTS)
  ComObjCreate("SAPI.SpVoice").Speak("Ready")
MsgBox, resetting will start when you close this box

#Persistent
SetTimer, Repeat, 20
return

Repeat:
  Critical
  for i, pid in PIDs {
    HandleResetState(pid, i)
  }
  HandlePlayerState()
return

HandlePlayerState()
{
  if (playerState == 0) ; needs spawn
  {
    instancesWithGoodSpawns := []
    for r, state in resetStates
    {
      if (state >= 7)
      {
        instancesWithGoodSpawns.Push(r)
      }
    }
    bestSpawn := -1
    counter = 0
    for p, q in instancesWithGoodSpawns
    {
      counter += 1
      if (counter = 1)
      {
        minDist := distances[q]
        bestSpawn := q
      }
      theDistance := distances[q]
      if (theDistance <= minDist)
      {
        minDist := distances[q]
		bestSpawn := q
      }
	}
	if (counter > 0)
	{
      writeString := readableTime() . ": player given spawn of distance " . minDist
      OutputDebug, [macro] %writeString%
      FileAppend, %writeString%, macro_logs.txt
      resetStates[bestSpawn] := 0 ; running
      SwitchInstance(bestSpawn)
      AlertUser(bestSpawn)
      playerState := 1 ; running
      ;if (stopResetsWhilePlaying)
      ;  playerState := 2 ; running and stop background resetting
    }
  }
}

HandleResetState(pid, idx) {
  if (resetStates[idx] == 0) ; running
    return
  else if (resetStates[idx] == 1) ; needs to reset from play
  {
    theState := resetStates[idx]
    OutputDebug, [macro] Instance %idx% in state %theState%
    WinSet, AlwaysOnTop, Off, ahk_pid %pid%
    ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %pid%
  }
  else if (resetStates[idx] == 2) ; need to exit world from pause
  {
    theState := resetStates[idx]
    OutputDebug, [macro] Instance %idx% in state %theState%
    ControlSend, ahk_parent, {Blind}{Shift down}{Tab}{Shift up}{Enter}, ahk_pid %pid%
  }
  else if (resetStates[idx] == 3) ; waiting to enter time between worlds
  {
    theState := resetStates[idx]
    OutputDebug, [macro] Instance %idx% in state %theState%
    WinGetTitle, title, ahk_pid %pid%
    if (IsInGame(title))
    {
      return
    }
  }
  else if (resetStates[idx] == 4) { ; checking if loaded in
    theState := resetStates[idx]
    ;OutputDebug, [macro] Instance %idx% in state %theState%
    WinGetTitle, title, ahk_pid %pid%
    if (IsInGame(title))
    {
      ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %pid%
    }
    else
    {
      return
    }
  }
  else if (resetStates[idx] == 5) ; get spawn
  {
    theState := resetStates[idx]
    OutputDebug, [macro] Instance %idx% in state %theState%
    GetSpawn(idx)
  }
  else if (resetStates[idx] == 6) ; check spawn
  {
    theState := resetStates[idx]
    OutputDebug, [macro] Instance %idx% in state %theState%
    if (GoodSpawn(idx)) {
      resetStates[idx] := 7 ; good spawn unfrozen
    }
    else
    {
      resetStates[idx] := 2 ; need to exit world
    }
    return
  }
  else if (resetStates[idx] == 7) ; good spawn waiting to reach final save
  {
    theState := resetStates[idx]
    ;OutputDebug, [macro] Instance %idx% in state %theState%
    if (playerState == 0) ; needs spawn so this instance about to be used
    {
      return
    }
    if (!(HasGameSaved(idx)))
    {
      return
    }
    startTimes[idx] := A_TickCount
  }
  else if (resetStates[idx] == 8) ; good spawn waiting for freeze delay to finish then freezing
  {
    theState := resetStates[idx]
    OutputDebug, [macro] Instance %idx% in state %theState%
    if ((A_TickCount - startTimes[idx] < beforeFreezeDelay))
    {
      return
    }
    SuspendInstance(pid)
  }
  else if (resetStates[idx] == 9) ; frozen good spawn waiting to be used
  {
    return
  }
  else {
    theState := resetStates[idx]
    MsgBox, instance %idx% ended up at unknown reset state of %theState%, exiting script
    ExitApp
  }
  resetStates[idx] += 1 ; Progress State
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
    UnsuspendAll()
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

FreeMemory(pid)
{
  h:=DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", 0, "Int", pid)
  DllCall("SetProcessWorkingSetSize", "UInt", h, "Int", -1, "Int", -1)
  DllCall("CloseHandle", "Int", h)
}

UnsuspendAll() {
  currInst := -1
  WinGet, all, list
  Loop, %all%
  {
    WinGet, thePID, PID, % "ahk_id " all%A_Index%
    WinGetTitle, title, ahk_pid %thePID%
    if (InStr(title, "Minecraft*"))
      ResumeInstance(thePID)
  }
}

SuspendInstance(pid) {
  hProcess := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", 0, "Int", pid)
  If (hProcess) {
    DllCall("ntdll.dll\NtSuspendProcess", "Int", hProcess)
    DllCall("CloseHandle", "Int", hProcess)
  }
  FreeMemory(pid)
}

ResumeInstance(pid) {
  hProcess := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", 0, "Int", pid)
  If (hProcess) {
    DllCall("ntdll.dll\NtResumeProcess", "Int", hProcess)
    DllCall("CloseHandle", "Int", hProcess)
  }
}

IsProcessSuspended(pid) {
  WinGetTitle, title, ahk_pid %pid%
return InStr(title, "Not Responding")
}

SwitchInstance(idx)
{
  currInst := idx
  thePID := PIDs[idx]
  if (instanceFreezing)
    ResumeInstance(thePID)
  for i, tmppid in PIDs {
    if (tmppid != thePID) {
      SetAffinity(tmppid, lowBitMask)
    }
  }
  SetAffinity(thePID, highBitMask)
  WinSet, AlwaysOnTop, On, ahk_pid %thePID%
  WinSet, AlwaysOnTop, Off, ahk_pid %thePID%
  ControlSend,, {Numpad%idx%}, ahk_exe obs64.exe
  send {Numpad%idx% down}
  sleep, %obsDelay%
  send {Numpad%idx% up}
  if (fullscreen) {
    ControlSend, ahk_parent, {Blind}{F11}, ahk_pid %thePID%
    sleep, %fullScreenDelay%
  }
  if (unpauseOnSwitch)
  {
    ControlSend, ahk_parent, {Esc}, ahk_pid %thePID%
    Send, {LButton} ; Make sure the window is activated
  }
  ShowF3()
}

ShowF3()
{
   if (f3showDuration < 0)
   {
      return
   }
   Sleep, f3showDelay
   ControlSend, ahk_parent, {Esc}, ahk_exe javaw.exe
   ControlSend, ahk_parent, {F3}, ahk_exe javaw.exe
   Sleep, %f3showDuration%
   ControlSend, ahk_parent, {F3}, ahk_exe javaw.exe
   ControlSend, ahk_parent, {Esc}, ahk_exe javaw.exe
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

Reset(state := 0)
{
  idx := GetActiveInstanceNum()
  if (inFullscreen(idx)) {
    send, {F11}
    sleep, %fullScreenDelay%
  }
  playerState := state ; needs spawn or keep resetting
  if (resetStates[idx] == 0) ; instance is being played
  {
    resetStates[idx] := 1 ; needs to exit from play
  }
  
}

SetTitles() {
  for g, thePID in PIDs {
    WinSetTitle, ahk_pid %thePID%, , Minecraft* - Instance %g%
  }
}

Perch()
{
   OpenToLAN()
   Send, /
   Sleep, 70
   SendInput, data merge entity @e[type=ender_dragon,limit=1] {{}DragonPhase:2{}}
   Send, {enter}
}

GiveSword()
{
   OpenToLAN()
   Send, /
   Sleep, 70
   SendInput, give @s minecraft:netherite_sword{{}Enchantments:[{{}id:"minecraft:sharpness",lvl:32727{}}]{}}
   Send, {enter}
}

OpenToLAN()
{
  savesDirectory := SavesDirectories[GetActiveInstanceNum()]
  thePID := PIDs[GetActiveInstanceNum()]
   Send, {Esc} ; pause
   ShiftTab(thePID, 2)
   if (fastResetModExist(savesDirectory))
  {
    ShiftTab(thePID)
  }
   Send, {enter} ; open to LAN
   if (version = 17)
   {
      Send, {tab}{tab}{enter} ; cheats on
   }
   else
   {
      ShiftTab(thePID)
      Send, {enter} ; cheats on
   }
   Send, `t
   Send, {enter} ; open to LAN
   WaitForHost(savesDirectory)
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

fastResetModExist(savesDirectory)
{
   modsFolder := StrReplace(savesDirectory, "saves", "mods") . "mods"
   ;MsgBox, %modsFolder%
   Loop, Files, %modsFolder%\*.*, F
   {
    ;MsgBox, %A_LoopFileName%
      if(InStr(A_LoopFileName, "fast-reset"))
      {
         return True
      }
   }
}

WaitForHost(savesDirectory)
{
   logFile := StrReplace(savesDirectory, "saves", "logs\latest.log") . "logs\latest.log"
   numLines := 0
   Loop, Read, %logFile%
   {
      numLines += 1
   }
   openedToLAN := False
   startTime := A_TickCount
   while (!openedToLAN)
   {
      OutputDebug, reading log file
      if ((A_TickCount - startTime) > 3000)
      {
         OutputDebug, open to lan timed out
         openedToLAN := True
      }
      Loop, Read, %logFile%
      {
         if ((A_TickCount - startTime) > 3000)
         {
            OutputDebug, open to lan timed out
            openedToLAN := True
         }
         if ((numLines - A_Index) < 2)
         {
            OutputDebug, %A_LoopReadLine%
            if (InStr(A_LoopReadLine, "[CHAT] Local game hosted on port"))
            {
               OutputDebug, found the [CHAT] Local game hosted on port
               openedToLAN := True
            }
         }
      }
   }
}

inWorld(idx)
{
  mcDirectory := SavesDirectories[idx]
  lastWorld := getMostRecentFile(mcDirectory)
  lockFile := lastWorld . "\session.lock"
  FileRead, sessionlockfile, %lockFile%
  if (ErrorLevel = 0)
  {
    return false
  }
  return true
}

getMostRecentFile(mcDirectory)
{
  savesDirectory := mcDirectory . "saves"
  ;MsgBox, %savesDirectory%
	counter := 0
	Loop, Files, %savesDirectory%\*.*, D
	{
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

Test()
{
  two := inWorld(1)
  MsgBox, %two%
}


getVersion()
{
  savesDirectory := SavesDirectories[1]
   optionsFile := StrReplace(savesDirectory, "saves", "options.txt") . "options.txt"
   FileReadLine, versionLine, %optionsFile%, 1
   arr := StrSplit(versionLine, ":")
   dataVersion := arr[2]
   if (dataVersion > 2600)
      return (17)
   else
      return (16)
}

PauseOnLostFocus(savesDirectory) ;used on script startup
{
   optionsFile := StrReplace(savesDirectory, "saves", "options.txt") . "options.txt"
   if (version = 16)
      FileReadLine, optionLine, %optionsFile%, 45
   else
      FileReadLine, optionLine, %optionsFile%, 48
   if (InStr(optionLine, "true"))
      return 1
   else
      return 0
}

inFullscreen(idx)
{
  savesDirectory := SavesDirectories[idx]
   optionsFile := StrReplace(savesDirectory, "saves", "options.txt") . "options.txt"
   FileReadLine, fullscreenLine, %optionsFile%, 17
   if (InStr(fullscreenLine, "true"))
      return 1
   else
      return 0
}

GiveAngle(n)
{
   if (giveAngle == True)
   {
      xDiff := xCoords[n] - centerPointX
      currentX := xCoords[n]
      zDiff := centerPointZ - zCoords[n]
      currentZ := zCoords[n]
      angle := ATan(xDiff / zDiff) * 180 / 3.14159265358979
      if (zDiff < 0)
      {
         angle := angle - 180
      }
      if (zDiff = 0)
      {
         if (xDiff < 0)
         {
            angle := -90.0
         }
         else if (xDiff > 0)
         {
            angle := 90.0
         }
      }
      angleList := StrSplit(angle, ".")
      intAngle := angleList[1]
      ComObjCreate("SAPI.SpVoice").Speak(intAngle)
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

GoodSpawn(n)
{
  timeString := readableTime()
   xCoord := xCoords[n]
   zCoord := zCoords[n]
   writeString := timeString . ": Instance " . n . ": Spawn: (" . xCoord . ", " . zCoord . "); Distance: "
   xDisplacement := xCoord - centerPointX
   zDisplacement := zCoord - centerPointZ
   distance := Sqrt((xDisplacement * xDisplacement) + (zDisplacement * zDisplacement))
   distances[n] := distance
   writeString := writeString . distance . "; Decision: "
   if (inList(xCoord, zCoord, "whitelist.txt"))
   {
      ;OutputDebug, [macro] in whitelist
      writeString := writeString . "GOOD spawn (in whitelist) `n"
      FileAppend, %writeString%, macro_logs.txt
      OutputDebug, [macro] %writeString%
      return True
   }
   if (inList(xCoord, zCoord, "blacklist.txt"))
   {
      ;OutputDebug, [macro] in blacklist
      writeString := writeString . "BAD spawn (in blacklist) `n"
      FileAppend, %writeString%, macro_logs.txt
      OutputDebug, [macro] %writeString%
      return False
   }
   if (distance <= radius)
  {
    writeString := writeString . "GOOD spawn (distance less than radius) `n"
      FileAppend, %writeString%, macro_logs.txt
      OutputDebug, [macro] %writeString%
      return True
    }
   else
  {
    writeString := writeString . "BAD spawn (distance more than radius) `n"
      FileAppend, %writeString%, macro_logs.txt
      OutputDebug, [macro] %writeString%
      return False
    }
}

Logg(inString)
{
  theTime := readableTime()
  writeString := "[macro] " . theTime . ": " . inString
  OutputDebug, %writeString%
  writeString := theTime . ": " . inString . "`n"
  FileAppend, %writeString%, macro_logs.txt
}

inList(xCoord, zCoord, fileName)
{
   if (FileExist(fileName))
   {
      Loop, read, %fileName%
      {
         arr0 := StrSplit(A_LoopReadLine, ";")
         corner1 := arr0[1]
         corner2 := arr0[2]
         arr1 := StrSplit(corner1, ",")
         arr2 := StrSplit(corner2, ",")
         X1 := arr1[1]
         Z1 := arr1[2]
         X2 := arr2[1]
         Z2 := arr2[2]
         if ((((xCoord <= X1) && (xCoord >= X2)) or ((xCoord >= X1) && (xCoord <= X2))) and (((zCoord <= Z1) && (zCoord >= Z2)) or ((zCoord >= Z1) && (zCoord <= Z2))))
            return True
      }
   }
   return False
}

GetSpawn(i)
{
  logFile := StrReplace(savesDirectories[i], "saves", "logs\latest.log") . "logs\latest.log"
  Loop, Read, %logFile%
  {
    if (InStr(A_LoopReadLine, "logged in with entity id"))
    {
      spawnLine := A_LoopReadLine
    }
  }
  array1 := StrSplit(spawnLine, " at (")
  xyz := array1[2]
  array2 := StrSplit(xyz, ", ")
  xCoord := array2[1]
  zCooord := array2[3]
  array3 := StrSplit(zCooord, ")")
  zCoord := array3[1]
  xCoords[i] := xCoord
  zCoords[i] := zCoord
}

AlertUser(n)
{
   thePID := PIDs[n]
	if (playSound)
	{
		if (FileExist("spawnready.mp3"))
			SoundPlay, spawnready.mp3
		else
			SoundPlay *16
	}
    GiveAngle(n)
}

AddToBlacklist()
{
	t := GetActiveInstanceNum()
   xCoord := xCoords[t]
   zCoord := zCoords[t]
   OutputDebug, [macro] blacklisting %xCoord%, %zCoord%
   theString := xCoord . "," . zCoord . ";" . xCoord . "," . zCoord
   if (!FileExist("blacklist.txt"))
      FileAppend, %theString%, blacklist.txt
   else
      FileAppend, `n%theString%, blacklist.txt
}


#IfWinActive, Minecraft
{
  RAlt::  ; Pause all macros
    Suspend
  return
  
    PgDn:: ; Reset and give spawn
      Reset(0)
    return
    
    End:: ; Perch
		Perch()
	return

    F5:: ; Reload if macro locks up
      UnsuspendAll()
      Reload
   return 
   
   ^B:: ; Add a spawn to the blacklisted spawns.
		AddToBlacklist()
	return
   
  Delete:: ; kill villager
    GiveSword()
  return
}

^End:: ; Safely close the script
  UnsuspendAll()
  ExitApp
return