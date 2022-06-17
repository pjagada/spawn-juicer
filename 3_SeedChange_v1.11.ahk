#NoEnv
#SingleInstance Force
#Include 2_options.ahk
#include functions.ahk
;#Warn

SetKeyDelay, 0
SetWinDelay, 1
SetTitleMatchMode, 2

startup_log()

; Don't configure these, scroll to the very bottom to configure hotkeys
global currInst := -1
global pauseAuto := False
global SavesDirectories := []
global instances := 0
global rawPIDs := []
global PIDs := []
global titles := []

GetAllPIDs()

tmptitle := ""
for i, tmppid in PIDs{
  WinGetTitle, tmptitle, ahk_pid %tmppid%
  titles.Push(tmptitle)
  WinSet, AlwaysOnTop, Off, ahk_pid %tmppid%
}

show_all_mods()

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
speak_async("Success")

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

SetTitles() {
  for g, thePID in PIDs {
    WinSetTitle, ahk_pid %thePID%, , Minecraft* - Instance %g%
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

