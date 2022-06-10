#SingleInstance, Force
#include functions.ahk
SendMode Input
SetWorkingDir, %A_ScriptDir%

; Will move all New World/Speedrun # worlds from all open Minecrafts to oldWorldsFolder

global oldWorldsFolder := "C:\Users\prana\OneDrive\Desktop\Minecraft\oldWorlds\" ; Old Worlds folder, make it whatever you want

IfNotExist, %oldWorldsFolder%
  FileCreateDir %oldWorldsFolder%
; Dont edit
global McDirectories := []
global rawPIDs := []
global instances := 0
sleep, 500

TrackFlint(world)
{
   headers := "Time that run ended, Flint obtained, Gravel mined"
   if (!FileExist("SSGstats.csv"))
   {
      FileAppend, %headers%, SSGstats.csv
   }
   numbersArray := gravelDrops(world)
   flintDropped := numbersArray[1]
   gravelMined := numbersArray[2]
   theTime := readableTime()
   numbers := theTime . "," . flintDropped . "," . gravelMined
   debugOutput := theTime . ": flint dropped: " . flintDropped . ", gravel mined: " . gravelMined
   OutputDebug, [macro] %debugOutput%
   FileAppend, `n, SSGstats.csv
   FileAppend, %numbers%, SSGstats.csv
}

gravelDrops(lastWorld)
{
   currentWorld := lastWorld
   statsFolder := currentWorld . "\stats"
   Loop, Files, %statsFolder%\*.*, F
   {
      statsFile := A_LoopFileLongPath
   }
   FileReadLine, fileText, %statsFile%, 1
   
   minedLocation := InStr(fileText, "minecraft:mined")
   if (minedLocation)
   {
      gravelLocation := InStr(fileText, "minecraft:gravel", , minedLocation)
      if (gravelLocation)
      {
         postMined := SubStr(fileText, gravelLocation)
         gravelArray1 := StrSplit(postMined, ":")
         gravelSubString := gravelArray1[3]
         gravelArray2 := StrSplit(gravelSubString, "}")
         gravelSubString2 := gravelArray2[1]
         gravelArray3 := StrSplit(gravelSubString2, ",")
         gravelMined := gravelArray3[1]
      }
      else
         gravelMined := 0
   }
   else
      gravelMined := 0
   
   pickedupLocation := Instr(fileText, "minecraft:picked_up")
   if (pickedupLocation)
   {
      flintLocation := InStr(fileText, "minecraft:flint", , pickedupLocation)
      if (flintLocation)
      {
         postPickedup := SubStr(fileText, flintLocation)
         flintArray1 := StrSplit(postPickedup, ":")
         flintSubString := flintArray1[3]
         flintArray2 := StrSplit(flintSubString, "}")
         flintSubString2 := flintArray2[1]
         flintArray3 := StrSplit(flintSubString2, ",")
         flintCollected := flintArray3[1]
      }
      else
         flintCollected := 0
   }
   else
      flintCollected := 0
   
   return ([flintCollected, gravelMined])
}

UpdateStats()
{
   if (FileExist("SSGstats.csv"))
   {
      FileDelete, SSGstats.txt
      headerRead := false
      totalFlint := 0
      totalGravel := 0
      totalAttempts := 0
      todayFlint := 0
      todayGravel := 0
      todayAttempts := 0
      Loop, read, SSGstats.csv
      {
         if (headerRead)
         {
            theArray := StrSplit(A_LoopReadLine, ",")
            totalFlint += theArray[2]
            totalGravel += theArray[3]
            totalAttempts += 1
            currentDate := A_Now // 1000000
            readTime := theArray[1]
            dateTimeArray := StrSplit(readTime, " ")
            rowDate := dateTimeArray[1]
            dateArray := StrSplit(rowDate, "/")
            theMonth := dateArray[1]
            theDay := dateArray[2]
            theYear := dateArray[3]
            readDate := theYear . theMonth . theDay
            if (readDate = currentDate)
            {
               todayFlint += theArray[2]
               todayGravel += theArray[3]
               todayAttempts += 1
            }
         }
         headerRead := true
      }
      flintRate := 100 * totalFlint / totalGravel
      dailyFlintRate := 100 * todayFlint / todayGravel
      theString := totalAttempts . " attempts tracked" . "`n" . totalFlint . " flint drops out of " . totalGravel . " gravel mined for a rate of " flintRate . " percent" . "`n`n" . todayAttempts . " attempts tracked today" . "`n" . todayFlint . " flint drops out of " . todayGravel . " gravel mined for a rate of " dailyFlintRate . " percent"
      FileAppend, %theString%, SSGstats.txt
   }
}




GetInstanceTotal() {
  idx := 1
  global rawPIDs
  WinGet, all, list
  Loop, %all%
  {
    WinGet, pid, PID, % "ahk_id " all%A_Index%
    WinGetTitle, title, ahk_pid %pid%
    if (InStr(title, "Minecraft*")) {
      rawPIDs[idx] := pid
      idx += 1
    }
  }
  return rawPIDs.MaxIndex()
}

GetAllPIDs()
{
  global McDirectories
  global instances := GetInstanceTotal()
  ; Generate mcdir and order PIDs
  Loop, %instances% {
    mcdir := GetMcDir(rawPIDs[A_Index])
    McDirectories[A_Index] := mcdir
  }
}
GetAllPIDs()

inWorld(world)
{
  lockFile := world . "\session.lock"
  FileRead, sessionlockfile, %lockFile%
  if (ErrorLevel = 0)
  {
    ;OutputDebug, [macro] %world% not in world
    return false
  }
  ;OutputDebug, [macro] %world% in world
  return true
}

for i, mcdir in McDirectories {
  saves := mcdir . "saves\"
  OutputDebug, Starting instance %i%
  Loop, Files, %saves%*, D
  {
    If ((InStr(A_LoopFileName, "New World") || InStr(A_LoopFileName, "Speedrun #")) && (!(InStr(A_LoopFileName, "_")))) {
      if (!(inWorld(saves . A_LoopFileName))) {
        tmp := A_NowUTC
        TrackFlint(saves . A_LoopFileName)
        UpdateStats()
        FileMoveDir, %saves%%A_LoopFileName%, %saves%%A_LoopFileName%%tmp%Instance %i%, R
        FileMoveDir, %saves%%A_LoopFileName%%tmp%Instance %i%, %oldWorldsFolder%%A_LoopFileName%%tmp%Instance %i%
      }
    }
  }
}
ComObjCreate("SAPI.SpVoice").Speak("World moving done")
ExitApp