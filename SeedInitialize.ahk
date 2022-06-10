#NoEnv
#SingleInstance Force
#include functions.ahk
;#Warn

; puts the seed in all open instances of minecraft with atum (make sure they're all on the title screen)
global SEED := "8398967436125155523"
global logging := false

SetKeyDelay, 0
SetWinDelay, 1
SetTitleMatchMode, 2

; Don't configure these, scroll to the very bottom to configure hotkeys
global currInst := -1
global pauseAuto := False
global SavesDirectories := []
global instances := 0
global rawPIDs := []
global PIDs := []
global titles := []

GetAllPIDs()
SetTitles()

tmptitle := ""
for i, tmppid in PIDs{
  WinGetTitle, tmptitle, ahk_pid %tmppid%
  titles.Push(tmptitle)
  WinSet, AlwaysOnTop, Off, ahk_pid %tmppid%
}

for k, saves_directory in SavesDirectories
{
	check_atum(k)
	if (seed_check(k))
	{
		check_title_screen(k)
		change_seed(k)
	}
}

Sleep, 100

for n, saves_directory in SavesDirectories
{
	check_atum(n)
	if (seed_check(n))
	{
		check_title_screen(n)
		change_seed(n)
	}
}

Sleep, 100

for m, saves_directory in SavesDirectories
{
  if (seed_check(m))
  {
    MsgBox, Seed still seems to be wrong in 1 or more instances so try running script again, doing it a few times can help until you hear "Success." If you run it a bunch and it's still not working, just do it manually.
    ExitApp
  }
}
ComObjCreate("SAPI.SpVoice").Speak("Success")

check_atum(idx)
{
	if (!(modExist("atum", idx)))
    {
      MsgBox, Instance %idx% does not have atum installed. Install atum in all your instances, restart them, then start the script again.
      ExitApp
    }
}

seed_check(idx)
{
	mcDir := SavesDirectories[idx]
	seedFile := mcDir . "seed.txt"
	Logg("seed file is " . seedFile)
	FileReadLine, readSeed, %seedFile%, 1
	if (ErrorLevel)
	{
		return true
	}
	Logg("seed read is " . readSeed)
	return (readSeed != SEED)
}

change_seed(idx)
{
	Logg("changing seed of instance " . idx)
	thePID := PIDs[idx]
	ShiftTab(thePID)
	ShiftEnter(thePID)
	CtrlA(thePID)
  Sleep, 10
	ControlSend, ahk_parent, {Backspace}, ahk_pid %thePID%
  Sleep, 10
	ControlSend, ahk_parent, %SEED%, ahk_pid %thePID%
	Sleep, 10
	ControlSend, ahk_parent, {Tab}{Tab}{Enter}, ahk_pid %thePID%
	ControlSend, ahk_parent, {Shift Up}{Ctrl Up}, ahk_pid %thePID%
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
  ; Generate saves and order PIDs
  Loop, %instances% {
    saves := GetMcDir(rawPIDs[A_Index])
    if (num := GetInstanceNumberFromSaves(saves)) == -1
      ExitApp
    PIDS[num] := rawPIDs[A_Index]
    SavesDirectories[num] := saves
  }
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

ShiftEnter(thePID, n := 1)
{
   if WinActive("ahk_pid" thePID)
   {
      Loop, %n%
      {
         Send, +{Enter}
      }
   }
   else
   {
      ControlSend, ahk_parent, {Blind}{Shift down}, ahk_pid %thePID%
      Loop, %n%
      {
         ControlSend, ahk_parent, {Blind}{Enter}, ahk_pid %thePID%
      }
      ControlSend, ahk_parent, {Blind}{Shift up}, ahk_pid %thePID%
   }
}

CtrlA(thePID, n := 1)
{
   if WinActive("ahk_pid" thePID)
   {
      Loop, %n%
      {
         Send, ^a
      }
   }
   else
   {
      ControlSend, ahk_parent, {Blind}{Ctrl down}, ahk_pid %thePID%
      Loop, %n%
      {
         ControlSend, ahk_parent, {Blind}a, ahk_pid %thePID%
      }
      ControlSend, ahk_parent, {Blind}{Ctrl up}, ahk_pid %thePID%
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

check_title_screen(idx)
{
	if (inWorld(idx))
	{
		MsgBox, Instance %idx% is not on the title screen. Put all instances on the title screen and restart the script.
		ExitApp
	}
}

inWorld(idx)
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
    return false
  }
  return true
}

