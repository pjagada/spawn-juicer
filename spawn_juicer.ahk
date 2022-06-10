; Multi and single instance AHK resetting script for set seed
; Original author Specnr, modified for set seed by Peej

; Instructions: https://github.com/pjagada/spawn-juicer#readme

; v1.9

#NoEnv
#SingleInstance Force
;#Warn

SetKeyDelay, 0
SetWinDelay, 1
SetTitleMatchMode, 2

; macro options:
global unpauseOnSwitch := False ; unpause when switched to instance with ready spawn
global fullscreen := False ; all resets will be windowed, this will automatically fullscreen the instance that's about to be played
global playSound := False ; will play a windows sound or the sound stored as spawnready.mp3 whenever a spawn is ready
global disableTTS := False ; this is the "ready" sound that plays when the macro is ready to go
global fullScreenDelay := 270 ; increase if fullscreening issues
global restartDelay := 200 ; increase if saying missing instanceNumber in .minecraft (and you ran setup)
global maxLoops := 20 ; increase if macro regularly locks
global f3showDuration = 100 ; how many milliseconds f3 is shown for at the start of a run (for verification purposes). Make this -1 if you don't want it to show f3. Remember that one frame at 60 fps is 17 milliseconds, and one frame at 30 fps is 33 milliseconds. You'll probably want to show this for 2 or 3 frames to be safe.
global f3showDelay = 100 ; how many milliseconds of delay before showing f3. If f3 isn't being shown, this is all probably happening during the joining world screen, so increase this number.
global logging = True ; turn this to True to generate logs in macro_logs.txt and DebugView; don't keep this on True because it'll slow things down
global kryptonChecker := True ; change this to False if you want to use Krypton (highly recommend not using Krypton as it will usually break the macro)
global coop := False ; will automatically open to LAN and prepare "/time set 0" (without sending command) when you join a world

; Autoresetter Options:
; The autoresetter will automatically reset if your spawn is greater than a certain number of blocks away from a certain point (ignoring y)
global centerPointX := 257.5 ; this is the x coordinate of that certain point (by default it's the x coordinate of being pushed up against the window of the blacksmith of -3294725893620991126)
global centerPointZ := 228.5 ; this is the z coordinate of that certain point (by default it's the z coordinate of being pushed up against the window of the blacksmith of -3294725893620991126)
global radius := 10 ; if this is 10 for example, the autoresetter will not reset if you are within 10 blocks of the point specified above. Set this smaller for better spawns but more resets
; if you would only like to reset the blacklisted spawns or don't want automatic resets, then just set this number really large (1000 should be good enough), and if you would only like to play out whitelisted spawns, then just make this number negative
global giveAngle := True ; Give the angle (TTS) that you need to travel at to get to your starting point

; Multi options (single-instance users ignore these)
global instanceFreezing := True ; you probably want to keep this on (true)
global freeMemory := False ; free memory of an instance when it suspends (keep this False unless you're low on RAM since it causes lag and slowness)
global affinity := True ;
global lowBitmaskMultiplier := 0.3 ; for affinity, find a happy medium, max=1.0; lower means more threads to the main instance and less to the background instances, higher means more threads to background instances and less to main instance
global obsDelay := 50 ; increase if not changing scenes in obs
global wallSwitch := True ; switch to an alternate scene (set OBS hotkey to F12) when all instances are resetting


; Don't configure these, scroll to the very bottom to configure hotkeys
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
global beforeFreezeDelay := 0 ; increase if doesnt join world
global playerState := 0 ; needs spawn
global highBitMask := (2 ** threadCount) - 1
global lowBitMask := (2 ** Ceil(threadCount * lowBitmaskMultiplier)) - 1

UnsuspendAll()
sleep, %restartDelay%
GetAllPIDs()
SetTitles()

tmptitle := ""
for eye, tmp_pid in PIDs{
  WinGetTitle, tmptitle, ahk_pid %tmp_pid%
  titles.Push(tmptitle)
  resetStates.push(2) ; need to exit
  resetTimes.push(0)
  xCoords.Push(0)
  zCoords.Push(0)
  distances.Push(0)
  startTimes.Push(A_TickCount)
  reachedSave.Push(false)
  WinSet, AlwaysOnTop, Off, ahk_pid %tmp_pid%
}
global version = getVersion()
global language := readLine("lang", 1)

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

if (affinity) {
  Logg("Setting high affinity for all instances since starting script")
  for jay, tmp_pid in PIDs {
    Logg("Setting high affinity for instance " . jay . " since starting script")
    SetAffinity(tmp_pid, highBitMask)
  }
}

if (!disableTTS)
  ComObjCreate("SAPI.SpVoice").Speak("Ready")
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
      if (state >= 8)
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
      resetStates[bestSpawn] := 0 ; running
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
  if (resetStates[idx] == 0) ; running
    return
  else if (resetStates[idx] == 1) ; needs to reset from play
  {
    theState := resetStates[idx]
    Logg("Instance " . idx . " in state " . theState)
    WinSet, AlwaysOnTop, Off, ahk_pid %pid%
    ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %pid%
  }
  else if (resetStates[idx] == 2) ; need to exit world from pause
  {
    theState := resetStates[idx]
    Logg("Instance " . idx . " in state " . theState)
    ControlSend, ahk_parent, {Blind}{Shift down}{Tab}{Shift up}{Enter}, ahk_pid %pid%
  }
  else if (resetStates[idx] == 3) ; waiting to enter time between worlds
  {
    theState := resetStates[idx]
    WinGetTitle, title, ahk_pid %pid%
    if (IsInGame(title))
    {
      return
    }
    Logg("Instance " . idx . " exited world so switching to state 4")
  }
  else if (resetStates[idx] == 4) { ; checking if loaded in
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
  else if (resetStates[idx] == 5) ; get spawn
  {
    theState := resetStates[idx]
    Logg("Instance " . idx . " in state " . theState)
    GetSpawn(idx)
  }
  else if (resetStates[idx] == 6) ; check spawn
  {
    theState := resetStates[idx]
    Logg("Instance " . idx . " in state " . theState)
    if (GoodSpawn(idx)) {
      Logg("Instance " . idx . " has a good spawn so switching to state 7")
      ControlSend, ahk_parent, {Blind}j, ahk_pid %pid%
      resetStates[idx] := 7 ; good spawn unfrozen
    }
    else
    {
      Logg("Instance " . idx . " has a bad spawn so switching to state 2")
      ControlSend, ahk_parent, {Blind}{Esc}, ahk_pid %pid%
      resetStates[idx] := 2 ; need to exit world
    }
    return
  }
  else if (resetStates[idx] == 7) ; good spawn waiting to reach final save
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
  else if (resetStates[idx] == 8) ; good spawn waiting for freeze delay to finish then freezing
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
    ControlSend, ahk_parent, {Blind}{F11}, ahk_pid %thePID%
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
      Reload
   return

   ^B:: ; Add a spawn (the one that the macro most recently gave you) to the blacklisted spawns.
		AddToBlacklist()
	return

  Delete:: ; kill villager
    GiveSword()
  return
}

^End:: ; Safely close the script
  ExitApp
return
