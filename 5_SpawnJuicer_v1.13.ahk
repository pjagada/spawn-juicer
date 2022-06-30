; Multi and single instance AHK resetting script for set seed
; Original author Specnr, modified for set seed by Peej

; Instructions: https://github.com/pjagada/spawn-juicer#readme
; Don't edit anything in this script

; v1.11

#NoEnv
#SingleInstance Force
#include functions.ahk
;#Warn

SetKeyDelay, 0
SetWinDelay, 1
SetTitleMatchMode, 2

#Include 2_options.ahk

startup_log()

EnvGet, threadCount, NUMBER_OF_PROCESSORS
global currInst := -1
global currScene := -1
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
global leftInstance := []
global beforeFreezeDelay := 0 ; increase if doesnt join world
global playerState := 0 ; needs spawn
global highBitMask := (2 ** threadCount) - 1
global lowBitMask := (2 ** Ceil(threadCount * lowBitmaskMultiplier)) - 1

global RUNNING := 0
global NEEDS_TO_RESET := 1
global CHECK_SETTINGS := 2
global EXIT_WORLD := 3
global TIME_BETWEEN_WORLDS := 4
global LOADING := 5
global GET_SPAWN := 6
global CHECK_SPAWN := 7
global GOOD_SPAWN := 8
global WAITING_FOR_FREEZE := 9
global FROZEN := 10

if (resetSettings) {
  if (!(FOV >= 30) && (FOV <= 110)) {
    Logg("FOV is " . FOV . ", so exiting script")
    MsgBox, FOV must be between 30 and 110. Change global FOV or global resetSettings, then start the script again.
    ExitApp
  }
  if (!(renderDistance >= 2 && renderDistance <= 32)) {
    Logg("RD is " . renderDistance . ", so exiting script")
    MsgBox, renderDistance must be between 2 and 32. Change global renderDistance or global resetSettings, then start the script again.
    ExitApp
  }
}

UnsuspendAll()
sleep, %restartDelay%
GetAllPIDs()
SetTitles()
Logg(instances . " instances open")
if (instances < 1) {
  MsgBox, no instances are open, start your instances then start the script again
  ExitApp
}

tmptitle := ""
for eye, tmp_pid in PIDs{
  WinGetTitle, tmptitle, ahk_pid %tmp_pid%
  titles.Push(tmptitle)
  resetStates.push(CHECK_SETTINGS)
  resetTimes.push(0)
  xCoords.Push(0)
  zCoords.Push(0)
  distances.Push(0)
  startTimes.Push(A_TickCount)
  reachedSave.Push(false)
  WinSet, AlwaysOnTop, Off, ahk_pid %tmp_pid%
  leftInstance.Push(0)
}
global version = getVersion()

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
  if (kryptonChecker) {
    if ((modExist("krypton", k)))
    {
      MsgBox, Instance %k% has krypton installed. Remove krypton from all your instances, restart them, then start the script again.
      ExitApp
    }
  }
}

show_all_mods()

global freezePreviewKey := ""
global leavePreviewKey := ""
if (modExist("worldpreview", 1)) {
  freezePreviewKey := getKey("key_Freeze Preview")
  leavePreviewKey := getKey("key_Leave Preview")
}
global fullscreenKey := getKey("key_key.fullscreen")
global commandKey := getKey("key_key.command")

if (affinity) {
  Logg("Setting high affinity for all instances since starting script")
  for jay, tmp_pid in PIDs {
    Logg("Setting high affinity for instance " . jay . " since starting script")
    SetAffinity(tmp_pid, highBitMask)
  }
}

if (!disableTTS)
  speak_async("Ready")
MsgBox, resetting will start when you close this box

#Persistent
OnExit("ExitFunc")
SetTimer, Repeat, 20
return

Repeat:
  Critical
  for kay, pid in PIDs {
    HandleResetState(pid, kay)
  }
  HandlePlayerState()
return

ExitFunc(ExitReason, ExitCode)
{
  Logg("ExitReason is " . ExitReason)
  Logg("ExitCode is " . ExitCode)
  UnsuspendAll()
  if (affinity) {
    Logg("Setting high affinity for all instances since ending script")
    for el, tmp_pid in PIDs {
      Logg("Setting high affinity for instance " . el . " since ending script")
      SetAffinity(tmp_pid, highBitMask)
    }
  }
  return 0
}

HandlePlayerState()
{
  if (playerState == 0) ; needs spawn
  {
    instancesWithGoodSpawns := []
    for r, state in resetStates
    {
      if (state >= WAITING_FOR_FREEZE)
      {
        instancesWithGoodSpawns.Push(r)
        Logg("Instance " . r . " has a good spawn so adding it to instancesWithGoodSpawns")
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
      writeString := "player given spawn of distance " . minDist . "`n"
      Logg(writeString)
      resetStates[bestSpawn] := RUNNING ; running
      SwitchInstance(bestSpawn)
      AlertUser(bestSpawn)
      playerState := 1 ; running
      ;if (stopResetsWhilePlaying)
      ;  playerState := 2 ; running and stop background resetting
    }
    else
    {
      if ((currScene != 0) && wallSwitch) {
        Logg("switching to wall scene since current scene is " . currScene)
        ControlSend,, {F12}, ahk_exe obs64.exe
        send {F12 down}
        sleep, %obsDelay%
        send {F12 up}
        currScene := 0
      }
    }
  }
}

HandleResetState(pid, idx) {
  if (resetStates[idx] == RUNNING) ; running
    return
  else if (resetStates[idx] == NEEDS_TO_RESET) ; needs to reset from play
  {
    theState := resetStates[idx]
    Logg("Instance " . idx . " in state " . theState)
    WinSet, AlwaysOnTop, Off, ahk_pid %pid%
    ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %pid%
  }
  else if (resetStates[idx] == CHECK_SETTINGS) {
    if (!(resetSettings)) {
      Logg("not resetting settings so going to exit world in instance " . idx)
      resetStates[idx] := EXIT_WORLD
      return
    }
    theState := resetStates[idx]
    Logg("Instance " . idx . " in state " . theState)
    fovChange := check_fov(idx)
    rdChange := check_rd(idx)
    Logg("Instance " . idx . ": we need to change fov? " . fovChange . ", we need to change rd?" . rdChange)
    change_settings(fovChange, rdChange, idx)
  }
  else if (resetStates[idx] == EXIT_WORLD) ; need to exit world from pause
  {
    theState := resetStates[idx]
    Logg("Instance " . idx . " in state " . theState)
    ControlSend, ahk_parent, {Blind}{Shift down}{Tab}{Shift up}{Enter}, ahk_pid %pid%
    leftInstance[idx] := A_TickCount
    leftInstanceTime := leftInstance[idx]
    Logg("set instance " . idx . " left instance time to " . leftInstanceTime)
  }
  else if (resetStates[idx] == TIME_BETWEEN_WORLDS) ; waiting to enter time between worlds
  {
    theState := resetStates[idx]
    WinGetTitle, title, ahk_pid %pid%
    if (IsInGame(title))
    {
      Logg("Instance " . idx . " stuck in the TIME_BETWEEN_WORLDS state")
      timeSinceLeftInstance := A_TickCount - leftInstance[idx]
      Logg("time since left instance " . idx . " is " . timeSinceLeftInstance)
      if (timeSinceLeftInstance > 150) ; instance is likely stuck in an unpause state
      {
        Logg("that time is greater than 150 ms so switching to NEEDS_TO_RESET state")
        resetStates[idx] := NEEDS_TO_RESET
      }
      return
    }
    Logg("Instance " . idx . " exited world so switching to state 4")
  }
  else if (resetStates[idx] == LOADING) { ; checking if loaded in
    theState := resetStates[idx]
    ;OutputDebug, [macro] Instance %idx% in state %theState%
    WinGetTitle, title, ahk_pid %pid%
    if (IsInGame(title) || HasPreviewStarted(idx))
    {
      Logg("Instance " . idx . " loaded in so switching to state 5")
    }
    else
    {
      return
    }
  }
  else if (resetStates[idx] == GET_SPAWN) ; get spawn
  {
    theState := resetStates[idx]
    Logg("Instance " . idx . " in state " . theState)
    GetSpawn(idx)
  }
  else if (resetStates[idx] == CHECK_SPAWN) ; check spawn
  {
    theState := resetStates[idx]
    Logg("Instance " . idx . " in state " . theState)
    if (GoodSpawn(idx)) {
      Logg("Instance " . idx . " has a good spawn so switching to state 7")
      ControlSend, ahk_parent, {Blind}{%freezePreviewKey%}, ahk_pid %pid%
      resetStates[idx] := GOOD_SPAWN ; good spawn unfrozen
    }
    else
    {
      Logg("Instance " . idx . " has a bad spawn so switching to state 2")
      if (modExist("worldpreview", idx)) {
        ControlSend, ahk_parent, {Blind}{%leavePreviewKey%}, ahk_pid %pid%
        resetStates[idx] := LOADING
      } else {
        ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %pid%
        resetStates[idx] := EXIT_WORLD ; need to exit world
      }
    }
    return
  }
  else if (resetStates[idx] == GOOD_SPAWN) ; good spawn waiting to reach final save
  {
    theState := resetStates[idx]
    ;OutputDebug, [macro] Instance %idx% in state %theState%
    WinGetTitle, title, ahk_pid %pid%
    if (!(IsInGame(title))) ; wait until preview is done
    {
      return
    }
    if (!(HasGameSaved(idx)))
    {
      return
    }
    ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %pid%
    startTimes[idx] := A_TickCount
  }
  else if (resetStates[idx] == WAITING_FOR_FREEZE) ; good spawn waiting for freeze delay to finish then freezing
  {
    theState := resetStates[idx]
    if (playerState == 0) ; needs spawn so this instance about to be used
    {
      return
    }
    if ((A_TickCount - startTimes[idx] < beforeFreezeDelay))
    {
      return
    }
    Logg("Instance " . idx . " has a good spawn so switching to state 9 and suspending")
    SuspendInstance(pid)
  }
  else if (resetStates[idx] == FROZEN) ; frozen good spawn waiting to be used
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

SetAffinity(pid, mask) {
  hProc := DllCall("OpenProcess", "UInt", 0x0200, "Int", false, "UInt", pid, "Ptr")
  DllCall("SetProcessAffinityMask", "Ptr", hProc, "Ptr", mask)
  DllCall("CloseHandle", "Ptr", hProc)
  Logg("Set affinity with mask " . mask . " for pid " . pid)
}

FreeMemory(pid)
{
  h:=DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", 0, "Int", pid)
  DllCall("SetProcessWorkingSetSize", "UInt", h, "Int", -1, "Int", -1)
  DllCall("CloseHandle", "Int", h)
  Logg("freed memory for pid " . pid)
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
  Logg("Suspended instance with pid " . pid)
  if (freeMemory == True)
  {
    FreeMemory(pid)
  }
  else
  {
    Logg("Did not free memory of instance with pid " . pid)
  }

}

ResumeInstance(pid) {
  hProcess := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", 0, "Int", pid)
  If (hProcess) {
    DllCall("ntdll.dll\NtResumeProcess", "Int", hProcess)
    DllCall("CloseHandle", "Int", hProcess)
  }
  Logg("Resumed instance with pid " . pid)
}

IsProcessSuspended(pid) {
  WinGetTitle, title, ahk_pid %pid%
return InStr(title, "Not Responding")
}

SwitchInstance(idx)
{
  Logg("Switching to instance " . idx)
  currInst := idx
  thePID := PIDs[idx]
  if (affinity) {
    Logg("Setting low affinity for all instances except instance " . idx . " since we're switching to that one")
    for i, tmppid in PIDs {
      if (tmppid != thePID){
        Logg("Setting low affinity for instance " . i)
        SetAffinity(tmppid, lowBitMask)
      }
    }
  }
  if (instanceFreezing)
  {
    Logg("Resuming instance " . idx)
    ResumeInstance(thePID)
  }
  if (affinity)
  {
    Logg("Setting high affinity for instance " . idx . " since we're switching to it")
    SetAffinity(thePID, highBitMask)
  }
  WinSet, AlwaysOnTop, On, ahk_pid %thePID%
  WinSet, AlwaysOnTop, Off, ahk_pid %thePID%
  if (instances > 1)
  {
    Logg("More than 1 instance so switching OBS scenes")
    ControlSend,, {Numpad%idx%}, ahk_exe obs64.exe
    send {Numpad%idx% down}
    sleep, %obsDelay%
    send {Numpad%idx% up}
    currScene := idx
  }
  if (fullscreen) {
    ControlSend, ahk_parent, {Blind}{%fullscreenKey%}, ahk_pid %thePID%
    sleep, %fullScreenDelay%
  }
  ShowF3()
  if (coop) {
    Coop(idx)
  }
  else if (unpauseOnSwitch)
  {
    ControlSend, ahk_parent, {Esc}, ahk_pid %thePID%
    Send, {LButton} ; Make sure the window is activated
  }
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



Reset(state := 0)
{
  timeSinceLastHotkey := A_TimeSincePriorHotkey
  if (timeSinceLastHotkey < hotkeyCooldown && timeSinceLastHotkey >= 0) {
    Logg("last hotkey was pressed " . timeSinceLastHotkey . " ms ago, which is less than the hotkey cooldown of " . hotkeyCooldown . ", so not gonna do anything")
    return
  }
  Logg("last hotkey was pressed " . timeSinceLastHotkey . " ms ago, which is more than the hotkey cooldown of " . hotkeyCooldown . ", so gonna do something")
  Logg("reset hotkey pressed")
  idx := GetActiveInstanceNum()
  Logg("active instance is " . idx)
  Logg("current instance is " . currInst)
  if (idx < 0) {
    idx := currInst
  }
  if (idx < 0) {
    Logg("no spawn yet to reset")
    return
  }
  if (inFullscreen(idx)) {
    send, {%fullscreenKey%}
    sleep, %fullScreenDelay%
  }
  playerState := state ; needs spawn or keep resetting
  if (resetStates[idx] == RUNNING) ; instance is being played
  {
    resetStates[idx] := NEEDS_TO_RESET ; needs to exit from play
  }
  if (affinity) {
    Logg("Setting high affinity for all instances since all instances are resetting now")
    for i, tmppid in PIDs {
      Logg("Setting high affinity for instance " . i . " since all instances are resetting now")
      SetAffinity(tmppid, highBitMask)
    }
  }

}

SetTitles() {
  for g, thePID in PIDs {
    WinSetTitle, ahk_pid %thePID%, , Minecraft* - Instance %g%
  }
}


#Include 5_hotkeys.ahk