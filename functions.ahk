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
   timeString := month . "/" . day . "/" . year . " " . hour . ":" . minute . ":" second
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
      ComObjCreate("SAPI.SpVoice").Speak(intAngle)
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
  ComObjCreate("SAPI.SpVoice").Speak(speakString)
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
   Send, /
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
   Send, /
   Sleep, 70
   SendInput, give @s minecraft:netherite_sword{{}Enchantments:[{{}id:"minecraft:sharpness",lvl:32727{}}]{}}
   Send, {enter}
}

Coop(idx)
{
  Logg("doing co-op stuff for instance " . idx)
  PausedOpenToLAN(idx)
  thePID := PIDs[idx]
  ControlSend, ahk_parent, /, ahk_pid %thePID%
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

if(language == "ar_sa"){
  return InStr(currTitle, "اللعب الفردي") || InStr(currTitle, "متعدد اللاعبين") || InStr(currTitle, "Instance")
}

else if(language == "bs_ba"){
  return InStr(currTitle, "Samostalna igra") || InStr(currTitle, "Mrežna igra") || InStr(currTitle, "Instance")
}

else if(language == "de_ch" or language == "de_de"){
  return InStr(currTitle, "Einzelspieler") || InStr(currTitle, "Mehrspieler") || InStr(currTitle, "Instance")
}

else if(language == "el_gr"){
  return InStr(currTitle, "Παιχνίδι Ενός Παίκτη") || InStr(currTitle, "Παιχνίδι Πολλαπλών Παικτών") || InStr(currTitle, "Instance")
}

else if(language == "en_au" or language == "en_ca" or language == "en_gb" or language == "en_nz" or language == "en_us"){
  return InStr(currTitle, "Singleplayer") || InStr(currTitle, "Multiplayer") || InStr(currTitle, "Instance")
}

else if(language == "en_pt"){
  return InStr(currTitle, "Lonely voyage") || InStr(currTitle, "Playing with yer mates") || InStr(currTitle, "Instance")
}

else if(language == "en_ud"){
  return InStr(currTitle, "ɹǝʎɐꞁdǝꞁᵷuᴉS") || InStr(currTitle, "ɹǝʎɐꞁdᴉʇꞁnW") || InStr(currTitle, "Instance")
}

else if(language == "enp"){
  return InStr(currTitle, "Oneplayer") || InStr(currTitle, "Maniplayer") || InStr(currTitle, "Instance")
}

else if(language == "enws"){
  return InStr(currTitle, "Soliloquy") || InStr(currTitle, "Multiplay'r") || InStr(currTitle, "Instance")
}

else if(language == "eo_uy"){
  return InStr(currTitle, "Unu ludanto") || InStr(currTitle, "Pluraj ludantoj") || InStr(currTitle, "Instance")
}

else if(language == "es_cl" or language == "es_ec" or language == "es_es" or language == "es_mx" or language == "es_uy" or language == "es_ve" or language == "es_ar"){
  return InStr(currTitle, "Un jugador") || InStr(currTitle, "Multijugador") || InStr(currTitle, "Instance")
}

else if(language == "fi_fi"){
  return InStr(currTitle, "Yksinpeli") || InStr(currTitle, "Moninpeli") || InStr(currTitle, "Instance")
}

else if(language == "fil_ph"){
  return InStr(currTitle, "Pang-isahang Laro") || InStr(currTitle, "Pang-maramihang Laro") || InStr(currTitle, "Instance")
}

else if(language == "fr_ca" or language == "fr_fr"){
  return InStr(currTitle, "Solo") || InStr(currTitle, "Multijoueur") || InStr(currTitle, "Instance")
}

else if(language == "fy_nl"){
  return InStr(currTitle, "Allinnich spylje") || InStr(currTitle, "Tegearre spylje") || InStr(currTitle, "Instance")
}

else if(language == "haw_us"){
  return InStr(currTitle, "Paʻani wale") || InStr(currTitle, "Multiplayer") || InStr(currTitle, "Instance")
}

else if(language == "he_il"){
  return InStr(currTitle, "שחקן יחיד") || InStr(currTitle, "רב-משתתפים") || InStr(currTitle, "Instance")
}

else if(language == "hi_in"){
  return InStr(currTitle, "बहुखिलाड़ी") || InStr(currTitle, "एकलखिलाड़ी") || InStr(currTitle, "Instance")
}

else if(language == "id_id"){
  return InStr(currTitle, "Bermain Sendiri") || InStr(currTitle, "Bermain Bersama") || InStr(currTitle, "Instance")
}

else if(language == "is_is"){
  return InStr(currTitle, "Spila einn") || InStr(currTitle, "Netspilun") || InStr(currTitle, "Instance")
}

else if(language == "it_it"){
  return InStr(currTitle, "Giocatore singolo") || InStr(currTitle, "Multigiocatore") || InStr(currTitle, "Instance")
}

else if(language == "ja_jp"){
  return InStr(currTitle, "シングルプレイ") || InStr(currTitle, "マルチプレイ") || InStr(currTitle, "Instance")
}

else if(language == "ko_kr"){
  return InStr(currTitle, "싱글플레이") || InStr(currTitle, "멀티플레이") || InStr(currTitle, "Instance")
}

else if(language == "la_la"){
  return InStr(currTitle, "Ludus unius") || InStr(currTitle, "Ludus multorum") || InStr(currTitle, "Instance")
}

else if(language == "lol_us"){
  return InStr(currTitle, "Loneleh Kitteh") || InStr(currTitle, "Multiplayr") || InStr(currTitle, "Instance")
}
; is different in non-lan multiplayer

else if(language == "lzh"){
  return InStr(currTitle, "獨戲") || InStr(currTitle, "衆戲") || InStr(currTitle, "Instance")
}

else if(language == "nl_nl"){
  return InStr(currTitle, "Alleen spelen") || InStr(currTitle, "Samen spelen") || InStr(currTitle, "Instance")
}

else if(language == "nn_no"){
  return InStr(currTitle, "Einspelar") || InStr(currTitle, "Fleirspelar") || InStr(currTitle, "Instance")
}

else if(language == "pl_pl"){
  return InStr(currTitle, "Tryb jednoosobowy") || InStr(currTitle, "Gra wieloosobowa") || InStr(currTitle, "Instance")
}

else if(language == "pt_br" or language == "pt_pt"){
  return InStr(currTitle, "Um jogador") || InStr(currTitle, "Multijogador") || InStr(currTitle, "Instance")
}

else if(language == "sl_si"){
  return InStr(currTitle, "Enoigralski način") || InStr(currTitle, "Večigralski način") || InStr(currTitle, "Instance")
}

else if(language == "sv_se"){
  return InStr(currTitle, "Enspelarläge") || InStr(currTitle, "Flerspelarläge") || InStr(currTitle, "Instance")
}

else if(language == "tl_ph"){
  return InStr(currTitle, "Pang-isahang Laro") || InStr(currTitle, "Pang-maramihang Laro") || InStr(currTitle, "Instance")
}

else if(language == "tok"){
  return InStr(currTitle, "musi pi jan wan") || InStr(currTitle, "ma kulupu pi jan poka") || InStr(currTitle, "Instance")
}

else if(language == "uk_ua"){
  return InStr(currTitle, "Гра наодинці") || InStr(currTitle, "Гра в мережі") || InStr(currTitle, "Instance")
}

else if(language == "zh_cn"){
  return InStr(currTitle, "单人游戏") || InStr(currTitle, "多人游戏") || InStr(currTitle, "Instance")
}

else if(language == "zh_hk"){
  return InStr(currTitle, "單人遊戲") || InStr(currTitle, "多人遊戲") || InStr(currTitle, "Instance")
}

else if(language == "zh_tw"){
  return InStr(currTitle, "單人遊戲") || InStr(currTitle, "多人遊戲") || InStr(currTitle, "Instance")
}

else {
  MsgBox, Language not supported yet, please change it and restart script.
  ExitApp
}

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


