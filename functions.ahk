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
   timeString := month . "/" . day . "/" . year . " " . hour . ":" . minute . ":" second . "." . A_MSec
   return (timeString)
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
      speak_async(intAngle)
   }
}

GoodSpawn(n)
{
  timeString := readableTime()
   xCoord := xCoords[n]
   zCoord := zCoords[n]
   writeString := "Instance " . n . ": Spawn: (" . xCoord . ", " . zCoord . "); Distance: "
   xDisplacement := xCoord - centerPointX
   zDisplacement := zCoord - centerPointZ
   distance := Sqrt((xDisplacement * xDisplacement) + (zDisplacement * zDisplacement))
   distances[n] := distance
   writeString := writeString . distance . "; Decision: "
   if (inList(xCoord, zCoord, "whitelist.txt"))
   {
      ;OutputDebug, [macro] in whitelist
      writeString := writeString . "GOOD spawn (in whitelist) `n"
      Logg(writeString)
      return True
   }
   if (inList(xCoord, zCoord, "blacklist.txt"))
   {
      ;OutputDebug, [macro] in blacklist
      writeString := writeString . "BAD spawn (in blacklist) `n"
      Logg(writeString)
      return False
   }
   if (distance <= radius)
  {
    writeString := writeString . "GOOD spawn (distance less than radius) `n"
      Logg(writeString)
      return True
    }
   else
  {
    writeString := writeString . "BAD spawn (distance more than radius) `n"
      Logg(writeString)
      return False
    }
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
    if (InStr(A_LoopReadLine, "logged in with entity id") || InStr(A_LoopReadLine, "Starting Preview"))
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
  timeSinceLastHotkey := A_TimeSincePriorHotkey
  if (timeSinceLastHotkey < hotkeyCooldown && timeSinceLastHotkey >= 0) {
    Logg("last hotkey was pressed " . timeSinceLastHotkey . " ms ago, which is less than the hotkey cooldown of " . hotkeyCooldown . ", so not gonna do anything")
    return
  }
  Logg("last hotkey was pressed " . timeSinceLastHotkey . " ms ago, which is more than the hotkey cooldown of " . hotkeyCooldown . ", so gonna do something")
	t := currInst
   xCoord := xCoords[t]
   zCoord := zCoords[t]
   theString := xCoord . "," . zCoord . ";" . xCoord . "," . zCoord
   if (!FileExist("blacklist.txt"))
      FileAppend, %theString%, blacklist.txt
   else
      FileAppend, `n%theString%, blacklist.txt
  speakString := "blacklisted instance " . t . "spawn of x " . xCoord . " z " . zCoord
  Logg(speakString)
  speak_async(speakString)
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
  Logg("could not find option " . option . " in options.txt of " . optionsFile)
  MsgBox, Could not find option in options.txt
  ExitApp
}

getKey(function)
{
   Logg("finding key for function " . function)
   rawKey := readLine(function, 1)
   for i, mcDir in SavesDirectories {
      if (rawKey != readLine(function, i)) {
         Logg("instance " . i . " has a bind of " . readLine(function, i) . ", but instance 1's is " . rawKey)
         MsgBox, Your bind for %function% is not the same in all your instances. Make sure it is, then restart the script.
         ExitApp
      }
   }
   mcKey := mc_key_to_ahk_key(rawKey)
   Logg("the key is " . rawKey . ", which is " . mcKey)
   return mcKey
}

getVersion()
{
   dataVersion := readLine("version", 1)
   if (dataVersion > 2600 && dataVersion < 2800)
      return (17)
   else
      return (16)
}

PauseOnLostFocus(idx) ;used on script startup
{
   optionLine := readLine("pauseOnLostFocus", idx)
   if (InStr(optionLine, "true"))
      return 1
   else
      return 0
}

inFullscreen(idx)
{
  fullscreenLine := readLine("fullscreen", idx)
   if (InStr(fullscreenLine, "true"))
      return 1
   else
      return 0
}

modExist(mod, idx)
{
  savesDirectory := SavesDirectories[idx]
  modsFolder := StrReplace(savesDirectory, "saves", "mods") . "mods"
  Logg("Checking mods in " . modsFolder)
   Loop, Files, %modsFolder%\*.*, F
   {
    ;Logg("checking mod " . A_LoopFileName)
      if(InStr(A_LoopFileName, mod) && (!(InStr(A_LoopFileName, "disabled"))))
      {
        Logg("found the mod " . mod)
         return true
      }
   }
   Logg("did not find the mod " . mod)
  return false
}

WaitForHost(savesDirectory)
{
   logFile := StrReplace(savesDirectory, "saves", "logs\latest.log") . "logs\latest.log"
   Logg("waiting for host in " . logFile)
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
         Logg("open to lan timed out")
         openedToLAN := True
      }
      Loop, Read, %logFile%
      {
         if ((A_TickCount - startTime) > 3000)
         {
            Logg("open to lan timed out")
            openedToLAN := True
         }
         if ((numLines - A_Index) < 2)
         {
            OutputDebug, %A_LoopReadLine%
            if (InStr(A_LoopReadLine, "[CHAT] Local game hosted on port"))
            {
               Logg("found the [CHAT] Local game hosted on port")
               openedToLAN := True
            }
         }
      }
   }
}

Perch()
{
  timeSinceLastHotkey := A_TimeSincePriorHotkey
  if (timeSinceLastHotkey < hotkeyCooldown && timeSinceLastHotkey >= 0) {
    Logg("last hotkey was pressed " . timeSinceLastHotkey . " ms ago, which is less than the hotkey cooldown of " . hotkeyCooldown . ", so not gonna do anything")
    return
  }
  Logg("last hotkey was pressed " . timeSinceLastHotkey . " ms ago, which is more than the hotkey cooldown of " . hotkeyCooldown . ", so gonna do something")
   OpenToLAN()
   Send, {%commandKey%}
   Sleep, 70
   SendInput, data merge entity @e[type=ender_dragon,limit=1] {{}DragonPhase:2{}}
   Send, {enter}
}

GiveSword()
{
  timeSinceLastHotkey := A_TimeSincePriorHotkey
  if (timeSinceLastHotkey < hotkeyCooldown && timeSinceLastHotkey >= 0) {
    Logg("last hotkey was pressed " . timeSinceLastHotkey . " ms ago, which is less than the hotkey cooldown of " . hotkeyCooldown . ", so not gonna do anything")
    return
  }
  Logg("last hotkey was pressed " . timeSinceLastHotkey . " ms ago, which is more than the hotkey cooldown of " . hotkeyCooldown . ", so gonna do something")
   OpenToLAN()
   Send, {%commandKey%}
   Sleep, 70
   SendInput, give @s minecraft:netherite_sword{{}Enchantments:[{{}id:"minecraft:sharpness",lvl:32727{}}]{}}
   Send, {enter}
}

Coop(idx)
{
  Logg("doing co-op stuff for instance " . idx)
  PausedOpenToLAN(idx)
  thePID := PIDs[idx]
  ControlSend, ahk_parent, {%commandKey%}, ahk_pid %thePID%
  Sleep, 70
  if WinActive("ahk_pid" thePID) {
    SendInput, time set 0
  } else {
    ControlSend, ahk_parent, time set 0, ahk_pid %thePID%
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

IsInGame(currTitle) { ; Checks game title against language in options
   return InStr(currTitle, "-")
}

OpenToLAN()
{
  idx := GetActiveInstanceNum()
  savesDirectory := SavesDirectories[idx]
  thePID := PIDs[idx]
   Send, {Esc} ; pause
   ShiftTab(thePID, 2)
   if (modExist("fast-reset", idx))
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

PausedOpenToLAN(idx)
{
  savesDirectory := SavesDirectories[idx]
  thePID := PIDs[idx]
   ShiftTab(thePID, 2)
   if (modExist("fast-reset", idx))
  {
    ShiftTab(thePID)
  }
   ControlSend, ahk_parent, {Blind}{enter}, ahk_pid %thePID% ; open to LAN
   if (version = 17)
   {
      ControlSend, ahk_parent, {Blind}{tab 2}{enter}, ahk_pid %thePID% ; cheats on
   }
   else
   {
      ShiftTab(thePID)
      ControlSend, ahk_parent, {Blind}{enter}, ahk_pid %thePID% ; cheats on
   }
   ControlSend, ahk_parent, {Blind}{tab}{enter}, ahk_pid %thePID% ; open to LAN
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

mc_key_to_ahk_key(mcKey) {
  keyArray := Object("key.keyboard.f1", "F1"
    ,"key.keyboard.f2", "F2"
    ,"key.keyboard.f3", "F3"
    ,"key.keyboard.f4", "F4"
    ,"key.keyboard.f5", "F5"
    ,"key.keyboard.f6", "F6"
    ,"key.keyboard.f7", "F7"
    ,"key.keyboard.f8", "F8"
    ,"key.keyboard.f9", "F9"
    ,"key.keyboard.f10", "F10"
    ,"key.keyboard.f11", "F11"
    ,"key.keyboard.f12", "F12"
    ,"key.keyboard.f13", "F13"
    ,"key.keyboard.f14", "F14"
    ,"key.keyboard.f15", "F15"
    ,"key.keyboard.f16", "F16"
    ,"key.keyboard.f17", "F17"
    ,"key.keyboard.f18", "F18"
    ,"key.keyboard.f19", "F19"
    ,"key.keyboard.f20", "F20"
    ,"key.keyboard.f21", "F21"
    ,"key.keyboard.f22", "F22"
    ,"key.keyboard.f23", "F23"
    ,"key.keyboard.f24", "F24"
    ,"key.keyboard.q", "q"
    ,"key.keyboard.w", "w"
    ,"key.keyboard.e", "e"
    ,"key.keyboard.r", "r"
    ,"key.keyboard.t", "t"
    ,"key.keyboard.y", "y"
    ,"key.keyboard.u", "u"
    ,"key.keyboard.i", "i"
    ,"key.keyboard.o", "o"
    ,"key.keyboard.p", "p"
    ,"key.keyboard.a", "a"
    ,"key.keyboard.s", "s"
    ,"key.keyboard.d", "d"
    ,"key.keyboard.f", "f"
    ,"key.keyboard.g", "g"
    ,"key.keyboard.h", "h"
    ,"key.keyboard.j", "j"
    ,"key.keyboard.k", "k"
    ,"key.keyboard.l", "l"
    ,"key.keyboard.z", "z"
    ,"key.keyboard.x", "x"
    ,"key.keyboard.c", "c"
    ,"key.keyboard.v", "v"
    ,"key.keyboard.b", "b"
    ,"key.keyboard.n", "n"
    ,"key.keyboard.m", "m"
    ,"key.keyboard.1", "1"
    ,"key.keyboard.2", "2"
    ,"key.keyboard.3", "3"
    ,"key.keyboard.4", "4"
    ,"key.keyboard.5", "5"
    ,"key.keyboard.6", "6"
    ,"key.keyboard.7", "7"
    ,"key.keyboard.8", "8"
    ,"key.keyboard.9", "9"
    ,"key.keyboard.0", "0"
    ,"key.keyboard.tab", "Tab"
    ,"key.keyboard.left.bracket", "["
    ,"key.keyboard.right.bracket", "]"
    ,"key.keyboard.backspace", "Backspace"
    ,"key.keyboard.equal", "="
    ,"key.keyboard.minus", "-"
    ,"key.keyboard.grave.accent", "`"
    ,"key.keyboard.slash", "/"
    ,"key.keyboard.space", "Space"
    ,"key.keyboard.left.alt", "LAlt"
    ,"key.keyboard.right.alt", "RAlt"
    ,"key.keyboard.print.screen", "PrintScreen"
    ,"key.keyboard.insert", "Insert"
    ,"key.keyboard.scroll.lock", "ScrollLock"
    ,"key.keyboard.pause", "Pause"
    ,"key.keyboard.right.control", "RControl"
    ,"key.keyboard.left.control", "LControl"
    ,"key.keyboard.right.shift", "RShift"
    ,"key.keyboard.left.shift", "LShift"
    ,"key.keyboard.comma", ","
    ,"key.keyboard.period", "."
    ,"key.keyboard.home", "Home"
    ,"key.keyboard.end", "End"
    ,"key.keyboard.page.up", "PgUp"
    ,"key.keyboard.page.down", "PgDn"
    ,"key.keyboard.delete", "Delete"
    ,"key.keyboard.left.win", "LWin"
    ,"key.keyboard.right.win", "RWin"
    ,"key.keyboard.menu", "AppsKey"
    ,"key.keyboard.backslash", "\"
    ,"key.keyboard.caps.lock", "CapsLock"
    ,"key.keyboard.semicolon", ";"
    ,"key.keyboard.apostrophe", "'"
    ,"key.keyboard.enter", "Enter"
    ,"key.keyboard.up", "Up"
    ,"key.keyboard.down", "Down"
    ,"key.keyboard.left", "Left"
    ,"key.keyboard.right", "Right"
    ,"key.keyboard.keypad.0", "Numpad0"
    ,"key.keyboard.keypad.1", "Numpad1"
    ,"key.keyboard.keypad.2", "Numpad2"
    ,"key.keyboard.keypad.3", "Numpad3"
    ,"key.keyboard.keypad.4", "Numpad4"
    ,"key.keyboard.keypad.5", "Numpad5"
    ,"key.keyboard.keypad.6", "Numpad6"
    ,"key.keyboard.keypad.7", "Numpad7"
    ,"key.keyboard.keypad.8", "Numpad8"
    ,"key.keyboard.keypad.9", "Numpad9"
    ,"key.keyboard.keypad.decimal", "NumpadDot"
    ,"key.keyboard.keypad.enter", "NumpadEnter"
    ,"key.keyboard.keypad.add", "NumpadAdd"
    ,"key.keyboard.keypad.subtract", "NumpadSub"
    ,"key.keyboard.keypad.multiply", "NumpadMult"
    ,"key.keyboard.keypad.divide", "NumpadDiv"
    ,"key.mouse.left", "LButton"
    ,"key.mouse.right", "RButton"
    ,"key.mouse.middle", "MButton"
    ,"key.mouse.4", "XButton1"
    ,"key.mouse.5", "XButton2")
   ahkKey := keyArray[mcKey]
   Logg("mc key of " . mcKey . " is ahkKey of " . ahkKey)
   if (ahkKey == "") {
      MsgBox, key %mcKey% not supported, exiting script
      ExitApp
   } else {
      return ahkKey
   }
}

speak_async(speakString)
{
   speakRate := TTS_speed
   Logg("saying " . speakString . " with rate of " . speakRate)
   Run, %A_ScriptDir%\speak.ahk "%speakString%" "%speakRate%", %A_ScriptDir%
}

check_fov(idx)
{
  Logg("is current FOV equal to " . FOV . "?")
  oFOV := (FOV - 70) / 40
  Logg("options file FOV would be " . oFOV)
  decimalFOV := readLine("fov", idx)
  Logg("current FOV is " . decimalFOV)
  return (decimalFOV != oFOV)
}

check_rd(idx) 
{
  Logg("is current RD equal to " . renderDistance . "?")
  currentRD := readLine("renderDistance", idx)
  Logg("current RD is " . currentRD)
  return (currentRD != renderDistance)
}

change_settings(fovChange, rdChange, idx)
{
  if (!(fovChange || rdChange)) {
    Logg("no change needed in fov/rd")
    return
  }
  thePID := PIDs[idx]
  if (!(on_title(idx))) {
   Logg("6 tabs for in game")
   ControlSend,, {Blind}{Tab 6}, ahk_pid %thePID%
  } else {
   Logg("5 tabs for title screen")
   ControlSend,, {Blind}{Tab 5}, ahk_pid %thePID%
  }
  ControlSend,, {enter}{Tab}, ahk_pid %thePID%
  if (fovChange) {
   Logg("doing fov change")
   FOVPresses := ceil((110-FOV)*1.7875)
   ControlSend,, {Blind}{Right 150}{Left %FOVPresses%}, ahk_pid %thePID%
  }
  if (rdChange) {
   Logg("doing rd change")
   if (on_title(idx)) {
      Logg("4 tabs for title screen")
      ControlSend,, {Blind}{Tab 4}{Enter}, ahk_pid %thePID%
   } else {
      Logg("5 tabs for in game")
      ControlSend,, {Blind}{Tab 5}{Enter}, ahk_pid %thePID%
   }
   ;Sleep, 1000
   Logg("right before shift p")
   SetKeyDelay, %shiftPDelay%
   ControlSend,, {Blind}{Shift down}p{Shift up}, ahk_pid %thePID%
   SetKeyDelay, 0
   Logg("right after shift p")
   ;Sleep, 1000
   RDPresses := ceil(4.7 * renderDistance) - 8
   Logg("rd presses: " . RDPresses)
   ControlSend,, {Blind}{Tab 4}{Enter}, ahk_pid %thePID%
   ControlSend,, {Blind}{Left 150}{Right %RDPresses%}, ahk_pid %thePID%
   ControlSend,, {Blind}{Esc}, ahk_pid %thePID%
  }
  ControlSend,, {Blind}{Esc 2}, ahk_pid %thePID%
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