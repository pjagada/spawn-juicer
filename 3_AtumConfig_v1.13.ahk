#NoEnv
#SingleInstance Force
#Include 2_options.ahk
#include functions.ahk
;#Warn

MsgBox, this script doesn't work anymore because atum buttons changed
ExitApp

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
global difficulties = []
global bonusChests = []
global structureses = []
global generatorTypes = []

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
	if (config_check(k))
	{
		check_title_screen(k)
		change_seed(k)
	}
}

Sleep, 100

for m, saves_directory in SavesDirectories
{
  if (config_check(m))
  {
    MsgBox, Atum configurations still seem to be wrong in 1 or more instances so try running script again, doing it a few times can help until you hear "Success." If you run it a bunch and it's still not working, just do it manually.
    ExitApp
  }
}
speak_async("Success")

check_atum(idx)
{
	if (!(modExist("atum-1.1", idx)))
    {
      MsgBox, Instance %idx% does not have atum 1.1+ installed. Install atum 1.1+ in all your instances, restart them, then start the script again.
      ExitApp
    }
}

config_check(idx)
{
	mcDir := SavesDirectories[idx]
  configFile := mcDir . "config\atum\atum.properties"
	Logg("config file is " . configFile)
  good = true
  if (FileExist(configFile) == "") {
    MsgBox, %configFile% does not exist, exiting script.
    ExitApp
  }
  Loop, read, %configFile%
  {
    if (InStr(A_LoopReadLine), "difficulty=") {
      Logg("found line of " . A_LoopReadLine)
      arr := StrSplit(A_LoopReadLine, "=")
      value := arr[2]
      difficulties.Push(value)
      if (value != difficulty) {
        good = false
      }
    } else if (InStr(A_LoopReadLine), "bonusChest=") {
      Logg("found line of " . A_LoopReadLine)
      arr := StrSplit(A_LoopReadLine, "=")
      value := arr[2]
      value := str_to_bool(value)
      bonusChests.Push(value)
      if (value != bonusChest) {
        good = false
      }
    } else if (InStr(A_LoopReadLine), "structures=") {
      Logg("found line of " . A_LoopReadLine)
      arr := StrSplit(A_LoopReadLine, "=")
      value := arr[2]
      value := str_to_bool(value)
      structureses.Push(value)
      if (value != structures) {
        good = false
      }
    } else if (InStr(A_LoopReadLine), "generatorType=" {
      Logg("found line of " . A_LoopReadLine)
      arr := StrSplit(A_LoopReadLine, "=")
      value := arr[2]
      generatorTypes.Push(value)
      if (value != generatorType) {
        good = false
      }
    } else if (InStr(A_LoopReadLine), "seed=" {
      Logg("found line of " . A_LoopReadLine)
      arr := StrSplit(A_LoopReadLine, "=")
      value := arr[2]
      if (value != SEED) {
        good = false
      }
    }
  }

  return good
}

str_to_bool(str) {
  if (InStr(str, "true")) {
    return true
  } else if (InStr(str, "false")) {
    return false
  } else {
    MsgBox, unknown boolean value for %str%, exiting script
    ExitApp
  }
}

change_seed(thePID)
{
	
	CtrlA(thePID)
  Sleep, 10
	ControlSend, ahk_parent, {Backspace}, ahk_pid %thePID%
  Sleep, 10
	ControlSend, ahk_parent, %SEED%, ahk_pid %thePID%
	Sleep, 10
}

change_config(idx) {
  thePID := PIDs[idx]
  navigate_to_seed_box(thePID)
  change_seed(thePID)
  ControlSend, ahk_parent, {Tab}, ahk_pid %thePID%
  fix_generatorType(idx)
  ControlSend, ahk_parent, {Tab}, ahk_pid %thePID%
  fix_difficulty(idx)
  ControlSend, ahk_parent, {Tab}, ahk_pid %thePID%
  fix_structures(idx)
  ControlSend, ahk_parent, {Tab}, ahk_pid %thePID%
  fix_bonusChest(idx)
  ControlSend, ahk_parent, {Tab}{Enter}, ahk_pid %thePID%
}

fix_generatorType(idx) {
  curr := generatorTypes[idx]
  presses := generatorType - curr
  if (presses < 0) {
    presses += 7
  }
  thePID := PIDs[idx]
  ControlSend, ahk_parent, {Enter %presses%}, ahk_pid %thePID%
}

fix_difficulty(idx) {
  curr := difficulties[idx]
  presses := difficulty - curr
  if (presses < 0) {
    presses += 5
  }
  thePID := PIDs[idx]
  ControlSend, ahk_parent, {Enter %presses%}, ahk_pid %thePID%
}

fix_structures(idx) {
  curr := structureses[idx]
  thePID := PIDs[idx]
  if (curr != structures) {
    ControlSend, ahk_parent, {Enter}, ahk_pid %thePID%
  }
}

fix_bonusChest(idx) {
  curr := bonusChests[idx]
  thePID := PIDs[idx]
  if (curr != bonusChest) {
    ControlSend, ahk_parent, {Enter}, ahk_pid %thePID%
  }
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
	if (!(on_title(idx)))
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

