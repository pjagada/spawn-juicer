#NoEnv
#SingleInstance Force
#include functions.ahk
#Include 2_options.ahk
;#Warn

SetKeyDelay, 0
SetWinDelay, 1
SetTitleMatchMode, 2

MsgBox, This is not an error message. After you exit this box, make sure you are in a world and unpaused with gamerule doImmediateRespawn as True and cheats on. Press Home to start the loop, and hold End to end the loop.

DisplaySpawns()
{
    ; Get command key
    WinGet, thePID, PID, A
    mcDir := GetMcDir(thePID)
    optionsFile := mcDir . "options.txt"
    Logg("Looking for option " . "key_key.command" . " in " . optionsFile)
    Loop, read, %optionsFile%
    {
        if InStr(A_LoopReadLine, "key_key.command") {
            Logg("found line of " . A_LoopReadLine)
            arr := StrSplit(A_LoopReadLine, ":")
            value := arr[2]
            Logg("value is " . value)
            break
        } else {
            value := "NO_OPTION"
        }
    }
    if (value == "NO_OPTION") {
        MsgBox, Could not find option in options.txt
        ExitApp
    }
    rawKey := value
    if (rawKey == "key.keyboard.grave.accent") {
      Logg("grave accent key used for " . function)
      MsgBox, Your control for %function% is the grave accent key which doesn't work with macros, so you will need to change it and restart the script.
      ExitApp
   }
   mcKey := mc_key_to_ahk_key(rawKey)
   Logg("the key is " . rawKey . ", which is " . mcKey)
   commandKey := mcKey

    Loop, 2000
    {
        Logg("main loop iteration")
        ; Respawn
        Send, {%commandKey%}
        Sleep, 60
        Send, kill
        Send, {Enter}
        Sleep, 200

        ; Get spawn
        oldClipboard := Clipboard
        Send, {F3 Down}c{F3 Up}
        startTime := A_TickCount
        Logg("start time is " . startTime)
        Loop
        {
            currentTime := A_TickCount
            elapsedTime := currentTime - startTime
            Logg("currentTime is " . currentTime . " and elapsedTime is " . elapsedTime)
            if ((elapsedTime) > 1000) {
                Logg("timed out")
                break
            }
            Logg("current clipboard is " . Clipboard)
            Logg("old clipboard is " . oldClipboard)
            if (Clipboard != oldClipboard) {
                Logg("they different")
                break
            }
            Sleep, 10
            Logg("waiting for clipboard")
            if GetKeyState("End", "P") {
                Logg("ending")
                break
            }
        }

        ; Prepare to lay block
        Send, {%commandKey%}
        Sleep, 60
        
        ; Process spawn
        array1 := StrSplit(Clipboard, " ")
        Logg(Clipboard)
        xCoord := array1[7]
        zCoord := array1[9]
        Logg("xCoord: " . xCoord . ", zCoord: " . zCoord)
        if (inList(xCoord, zCoord, "whitelist.txt")) {
            ; whitelisted
            Logg("whitelist")
            SendInput, setblock ~ ~-1 ~ minecraft:white_concrete
        } else if (inList(xCoord, zCoord, "blacklist.txt")) {
            ; blacklisted
            Logg("blacklist")
            SendInput, setblock ~ ~-1 ~ minecraft:black_concrete
        } else {
            xDisplacement := xCoord - centerPointX
            zDisplacement := zCoord - centerPointZ
            distance := Sqrt((xDisplacement * xDisplacement) + (zDisplacement * zDisplacement))
            if (distance <= radius) {
                ; in radius
                Logg("in radius")
                SendInput, setblock ~ ~-1 ~ minecraft:lime_concrete
            } else {
                ; out of radius
                Logg("out of radius")
                SendInput, setblock ~ ~-1 ~ minecraft:red_concrete
            }
        }

        
        Sleep, 60
        Send, {Enter}
        Sleep, 60
        if GetKeyState("End", "P") {
            Logg("ending")
            break
        }
    }
}

#IfWinActive, Minecraft
{
Home::
    DisplaySpawns()
return

F5::
    Reload
return

}
